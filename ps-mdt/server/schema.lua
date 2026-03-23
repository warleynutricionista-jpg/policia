local resourceName = tostring(GetCurrentResourceName())

local schemaState = {
    initialized = false,
    running = false,
    tableCache = {},
    columnCache = {},
    tableColumns = {},
}

local function schemaDebug(...)
    if ps and ps.debug then
        ps.debug(...)
    elseif Config and Config.Debug then
        print(('[%s][schema] %s'):format(resourceName, table.concat({ ... }, ' ')))
    end
end

local function tableExists(tableName)
    if schemaState.tableCache[tableName] ~= nil then
        return schemaState.tableCache[tableName]
    end

    local exists = tonumber(MySQL.scalar.await([[
        SELECT COUNT(*)
        FROM information_schema.tables
        WHERE table_schema = DATABASE()
          AND table_name = ?
    ]], { tableName })) or 0

    schemaState.tableCache[tableName] = exists > 0
    return schemaState.tableCache[tableName]
end

local function columnExists(tableName, columnName)
    local cacheKey = tableName .. ':' .. columnName
    if schemaState.columnCache[cacheKey] ~= nil then
        return schemaState.columnCache[cacheKey]
    end

    local exists = tonumber(MySQL.scalar.await([[
        SELECT COUNT(*)
        FROM information_schema.columns
        WHERE table_schema = DATABASE()
          AND table_name = ?
          AND column_name = ?
    ]], { tableName, columnName })) or 0

    schemaState.columnCache[cacheKey] = exists > 0
    return schemaState.columnCache[cacheKey]
end

local function invalidateTableColumns(tableName)
    schemaState.tableColumns[tableName] = nil
end

local function getTableColumns(tableName, forceRefresh)
    if not forceRefresh and schemaState.tableColumns[tableName] then
        return schemaState.tableColumns[tableName]
    end

    if not tableExists(tableName) then
        schemaState.tableColumns[tableName] = {}
        return schemaState.tableColumns[tableName]
    end

    local rows = MySQL.query.await([[
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = DATABASE()
          AND table_name = ?
    ]], { tableName }) or {}

    local columns = {}
    for i = 1, #rows do
        local row = rows[i]
        if row and row.column_name then
            columns[row.column_name] = true
            schemaState.columnCache[tableName .. ':' .. row.column_name] = true
        end
    end

    schemaState.tableColumns[tableName] = columns
    return columns
end

local function ensureColumn(tableName, columnName, definition)
    if not tableExists(tableName) then
        schemaDebug(('Skipping column ensure for missing table %s'):format(tableName))
        return false
    end

    if columnExists(tableName, columnName) then
        return false
    end

    local finalDefinition = definition
    if type(definition) == 'table' then
        finalDefinition = definition.definition
        if definition.after and columnExists(tableName, definition.after) then
            finalDefinition = ('%s AFTER `%s`'):format(finalDefinition, definition.after)
        end
    end

    local query = ('ALTER TABLE `%s` ADD COLUMN %s'):format(tableName, finalDefinition)
    MySQL.query.await(query)
    schemaState.columnCache[tableName .. ':' .. columnName] = true
    invalidateTableColumns(tableName)
    schemaDebug(('Added missing column %s.%s'):format(tableName, columnName))
    return true
end

local function ensureIndex(tableName, indexName, ddl, requiredColumns)
    if not tableExists(tableName) then
        return false
    end

    local exists = tonumber(MySQL.scalar.await([[
        SELECT COUNT(*)
        FROM information_schema.statistics
        WHERE table_schema = DATABASE()
          AND table_name = ?
          AND index_name = ?
    ]], { tableName, indexName })) or 0

    if exists > 0 then
        return false
    end

    if requiredColumns and #requiredColumns > 0 then
        local columns = getTableColumns(tableName)
        for i = 1, #requiredColumns do
            if not columns[requiredColumns[i]] then
                schemaDebug(('Skipping index %s on %s because column %s is missing'):format(indexName, tableName, requiredColumns[i]))
                return false
            end
        end
    end

    MySQL.query.await(('ALTER TABLE `%s` ADD %s'):format(tableName, ddl))
    schemaDebug(('Added missing index %s on %s'):format(indexName, tableName))
    return true
end

local function collectExistingColumns(tableName, candidates)
    local columns = getTableColumns(tableName)
    local result = {}

    for i = 1, #candidates do
        local columnName = candidates[i]
        if columns[columnName] then
            result[#result + 1] = columnName
        end
    end

    return result
end

local function quotedNonEmptyColumns(columns)
    local expressions = {}

    for i = 1, #columns do
        expressions[#expressions + 1] = ("NULLIF(TRIM(CAST(`%s` AS CHAR)), '')"):format(columns[i])
    end

    return expressions
end

local function ensureBolosSchema()
    local tableName = 'mdt_bolos'
    if not tableExists(tableName) then
        return
    end

    ensureColumn(tableName, 'type', { definition = "`type` ENUM('citizen','vehicle','weapon','property','other') NOT NULL DEFAULT 'citizen'", after = 'id' })
    ensureColumn(tableName, 'subject_id', { definition = '`subject_id` VARCHAR(50) NULL', after = 'type' })
    ensureColumn(tableName, 'subject_name', { definition = '`subject_name` VARCHAR(100) NULL', after = 'subject_id' })
    ensureColumn(tableName, 'reportId', { definition = '`reportId` INT(11) UNSIGNED NULL', after = 'subject_name' })
    ensureColumn(tableName, 'notes', { definition = '`notes` TEXT NULL', after = 'reportId' })
    ensureColumn(tableName, 'status', { definition = "`status` ENUM('active','inactive','resolved') NOT NULL DEFAULT 'active'", after = 'notes' })

    local typeSourceColumns = collectExistingColumns(tableName, { 'bolo_type', 'category', 'target_type' })
    local subjectIdSourceColumns = collectExistingColumns(tableName, { 'citizenid', 'cid', 'identifier', 'owner', 'plate', 'serial', 'subject' })
    local subjectNameSourceColumns = collectExistingColumns(tableName, { 'name', 'fullname', 'full_name', 'label', 'title', 'owner_name' })
    local reportIdSourceColumns = collectExistingColumns(tableName, { 'reportid', 'report_id', 'linkedreport' })
    local notesSourceColumns = collectExistingColumns(tableName, { 'note', 'reason', 'description', 'details' })
    local hasActiveColumn = columnExists(tableName, 'active')

    local setClauses = {}

    if #typeSourceColumns > 0 or #subjectIdSourceColumns > 0 then
        local typeCases = {
            "CASE",
            "WHEN NULLIF(TRIM(CAST(`type` AS CHAR)), '') IS NOT NULL THEN LOWER(CAST(`type` AS CHAR))"
        }

        for i = 1, #typeSourceColumns do
            local source = typeSourceColumns[i]
            typeCases[#typeCases + 1] = ("WHEN NULLIF(TRIM(CAST(`%s` AS CHAR)), '') IS NOT NULL THEN LOWER(CAST(`%s` AS CHAR))"):format(source, source)
        end

        if columnExists(tableName, 'plate') then
            typeCases[#typeCases + 1] = "WHEN NULLIF(TRIM(CAST(`plate` AS CHAR)), '') IS NOT NULL THEN 'vehicle'"
        end

        if columnExists(tableName, 'serial') then
            typeCases[#typeCases + 1] = "WHEN NULLIF(TRIM(CAST(`serial` AS CHAR)), '') IS NOT NULL THEN 'weapon'"
        end

        if columnExists(tableName, 'citizenid') or columnExists(tableName, 'cid') then
            local citizenIdChecks = {}
            if columnExists(tableName, 'citizenid') then
                citizenIdChecks[#citizenIdChecks + 1] = "NULLIF(TRIM(CAST(`citizenid` AS CHAR)), '') IS NOT NULL"
            end
            if columnExists(tableName, 'cid') then
                citizenIdChecks[#citizenIdChecks + 1] = "NULLIF(TRIM(CAST(`cid` AS CHAR)), '') IS NOT NULL"
            end
            typeCases[#typeCases + 1] = ("WHEN %s THEN 'citizen'"):format(table.concat(citizenIdChecks, ' OR '))
        end

        typeCases[#typeCases + 1] = "ELSE `type` END"
        local typeExpression = table.concat(typeCases, ' ')
        setClauses[#setClauses + 1] = ('`type` = %s'):format(typeExpression)
    end

    local subjectIdExpressions = quotedNonEmptyColumns(subjectIdSourceColumns)
    if #subjectIdExpressions > 0 then
        setClauses[#setClauses + 1] = ('`subject_id` = COALESCE(NULLIF(TRIM(CAST(`subject_id` AS CHAR)), \'\'), %s)'):format(table.concat(subjectIdExpressions, ', '))
    end

    local subjectNameExpressions = quotedNonEmptyColumns(subjectNameSourceColumns)
    if #subjectNameExpressions > 0 then
        setClauses[#setClauses + 1] = ('`subject_name` = COALESCE(NULLIF(TRIM(CAST(`subject_name` AS CHAR)), \'\'), %s)'):format(table.concat(subjectNameExpressions, ', '))
    end

    local reportIdExpressions = {}
    for i = 1, #reportIdSourceColumns do
        reportIdExpressions[#reportIdExpressions + 1] = ('NULLIF(CAST(`%s` AS UNSIGNED), 0)'):format(reportIdSourceColumns[i])
    end
    if #reportIdExpressions > 0 then
        setClauses[#setClauses + 1] = ('`reportId` = COALESCE(`reportId`, %s)'):format(table.concat(reportIdExpressions, ', '))
    end

    local notesExpressions = quotedNonEmptyColumns(notesSourceColumns)
    if #notesExpressions > 0 then
        setClauses[#setClauses + 1] = ('`notes` = COALESCE(NULLIF(TRIM(CAST(`notes` AS CHAR)), \'\'), %s)'):format(table.concat(notesExpressions, ', '))
    end

    if hasActiveColumn then
        setClauses[#setClauses + 1] = [[
            `status` = CASE
                WHEN NULLIF(TRIM(CAST(`status` AS CHAR)), '') IS NOT NULL THEN LOWER(CAST(`status` AS CHAR))
                WHEN `active` = 1 THEN 'active'
                WHEN `active` = 0 THEN 'inactive'
                ELSE `status`
            END
        ]]
    end

    if #setClauses > 0 then
        MySQL.query.await(('UPDATE `%s` SET %s'):format(tableName, table.concat(setClauses, ', ')))
    end

    MySQL.update.await([[
        UPDATE `mdt_bolos`
        SET `type` = CASE
            WHEN `type` IN ('citizen', 'vehicle', 'weapon', 'property', 'other') THEN `type`
            ELSE 'citizen'
        END,
        `status` = CASE
            WHEN `status` IN ('active', 'inactive', 'resolved') THEN `status`
            ELSE 'active'
        END
    ]])

    invalidateTableColumns(tableName)
    ensureIndex(tableName, 'type', "INDEX `type` (`type`)", { 'type' })
    ensureIndex(tableName, 'status', "INDEX `status` (`status`)", { 'status' })
    ensureIndex(tableName, 'reportId', "INDEX `reportId` (`reportId`)", { 'reportId' })
    ensureIndex(tableName, 'idx_mdt_bolos_type_status_subject', "INDEX `idx_mdt_bolos_type_status_subject` (`type`, `status`, `subject_id`)", { 'type', 'status', 'subject_id' })
end

function EnsureMdtSchema(force)
    if schemaState.initialized and not force then
        return true
    end

    if schemaState.running then
        return false
    end

    schemaState.running = true

    local ok, err = pcall(function()
        ensureColumn('mdt_reports', 'contentplaintext', { definition = '`contentplaintext` TEXT NULL', after = 'contentyjs' })
        ensureColumn('mdt_reports', 'authorplaintext', { definition = '`authorplaintext` VARCHAR(100) NULL', after = 'author' })
        ensureColumn('mdt_reports', 'dateupdated', { definition = '`dateupdated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP', after = 'datecreated' })
        ensureIndex('mdt_reports', 'idx_mdt_reports_datecreated', "INDEX `idx_mdt_reports_datecreated` (`datecreated`)")
        ensureIndex('mdt_reports', 'idx_mdt_reports_author', "INDEX `idx_mdt_reports_author` (`author`)")

        ensureBolosSchema()

        ensureColumn('mdt_reports_restrictions', 'type', { definition = '`type` VARCHAR(32) NULL', after = 'reportid' })
        ensureColumn('mdt_reports_restrictions', 'identifier', { definition = '`identifier` VARCHAR(64) NULL', after = 'type' })
        ensureIndex('mdt_reports_restrictions', 'idx_mdt_reports_restrictions_type_identifier', "INDEX `idx_mdt_reports_restrictions_type_identifier` (`type`, `identifier`)", { 'type', 'identifier' })

        ensureColumn('mdt_tags', 'job_type', { definition = "`job_type` ENUM('leo','ems','all') NOT NULL DEFAULT 'all'", after = 'color' })
        ensureIndex('mdt_tags', 'idx_mdt_tags_job_type', "INDEX `idx_mdt_tags_job_type` (`job_type`)", { 'job_type' })

        if not tableExists('mdt_report_templates') then
            MySQL.query.await([[
                CREATE TABLE IF NOT EXISTS `mdt_report_templates` (
                    `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
                    `name` VARCHAR(100) NOT NULL,
                    `type` VARCHAR(50) NOT NULL,
                    `content` LONGTEXT NOT NULL,
                    `job_type` ENUM('leo','ems','all') NOT NULL DEFAULT 'all',
                    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                    PRIMARY KEY (`id`),
                    KEY `idx_mdt_report_templates_job_type` (`job_type`),
                    KEY `idx_mdt_report_templates_type_name` (`type`, `name`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
            ]])
            schemaState.tableCache['mdt_report_templates'] = true
        else
            ensureColumn('mdt_report_templates', 'job_type', { definition = "`job_type` ENUM('leo','ems','all') NOT NULL DEFAULT 'all'", after = 'content' })
            ensureIndex('mdt_report_templates', 'idx_mdt_report_templates_job_type', "INDEX `idx_mdt_report_templates_job_type` (`job_type`)", { 'job_type' })
            ensureIndex('mdt_report_templates', 'idx_mdt_report_templates_type_name', "INDEX `idx_mdt_report_templates_type_name` (`type`, `name`)", { 'type', 'name' })
        end

        ensureColumn('player_vehicles', 'mdt_vehicle_information', { definition = '`mdt_vehicle_information` TEXT NULL', after = 'vehicle' })
        ensureColumn('player_vehicles', 'mdt_vehicle_points', { definition = '`mdt_vehicle_points` INT(11) NOT NULL DEFAULT 0', after = 'mdt_vehicle_information' })
        ensureColumn('player_vehicles', 'mdt_vehicle_status', { definition = "`mdt_vehicle_status` ENUM('valid','suspended','expired','impounded') NOT NULL DEFAULT 'valid'", after = 'mdt_vehicle_points' })
        ensureColumn('player_vehicles', 'mdt_vehicle_stolen', { definition = '`mdt_vehicle_stolen` TINYINT(1) NOT NULL DEFAULT 0', after = 'mdt_vehicle_status' })
        ensureColumn('player_vehicles', 'mdt_vehicle_boloactive', { definition = '`mdt_vehicle_boloactive` TINYINT(1) NOT NULL DEFAULT 0', after = 'mdt_vehicle_stolen' })
        ensureColumn('player_vehicles', 'mdt_vehicle_image', { definition = '`mdt_vehicle_image` VARCHAR(255) NULL', after = 'mdt_vehicle_boloactive' })
        ensureIndex('player_vehicles', 'idx_player_vehicles_citizenid_plate', "INDEX `idx_player_vehicles_citizenid_plate` (`citizenid`, `plate`)", { 'citizenid', 'plate' })

        ensureIndex('mdt_evidence_items', 'idx_mdt_evidence_items_case_created', "INDEX `idx_mdt_evidence_items_case_created` (`case_id`, `created_at`)", { 'case_id', 'created_at' })
        ensureIndex('mdt_evidence_items', 'idx_mdt_evidence_items_report_created', "INDEX `idx_mdt_evidence_items_report_created` (`report_id`, `created_at`)", { 'report_id', 'created_at' })
        ensureIndex('mdt_evidence_items', 'idx_mdt_evidence_items_type_stored', "INDEX `idx_mdt_evidence_items_type_stored` (`type`, `stored`)", { 'type', 'stored' })

        ensureIndex('mdt_reports_involved', 'idx_mdt_reports_involved_citizenid', "INDEX `idx_mdt_reports_involved_citizenid` (`citizenid`)", { 'citizenid' })
        ensureIndex('mdt_reports_charges', 'idx_mdt_reports_charges_citizenid', "INDEX `idx_mdt_reports_charges_citizenid` (`citizenid`)", { 'citizenid' })
        ensureIndex('mdt_arrests', 'idx_mdt_arrests_citizenid', "INDEX `idx_mdt_arrests_citizenid` (`citizenid`)", { 'citizenid' })

        if tableExists('mdt_bolos') and columnExists('mdt_bolos', 'status') then
            MySQL.update.await("UPDATE mdt_bolos SET status = 'active' WHERE status IS NULL OR status = ''")
        end

        if tableExists('mdt_reports') and columnExists('mdt_reports', 'contentplaintext') then
            MySQL.update.await("UPDATE mdt_reports SET contentplaintext = COALESCE(contentplaintext, '') WHERE contentplaintext IS NULL")
        end

        if tableExists('mdt_profiles') and columnExists('mdt_profiles', 'callsign') then
            MySQL.update.await([[
                UPDATE mdt_profiles
                SET callsign = NULL
                WHERE callsign IS NOT NULL
                  AND UPPER(TRIM(callsign)) IN ('SEM CALLSIGN', 'SEM INDICATIVO', 'NO CALLSIGN', 'N/A', 'NULL', 'NONE')
            ]])
        end

        if tableExists('mdt_profiles') and columnExists('mdt_profiles', 'badge_number') then
            MySQL.update.await([[
                UPDATE mdt_profiles
                SET badge_number = NULL
                WHERE badge_number IS NOT NULL
                  AND UPPER(TRIM(badge_number)) IN ('SEM CALLSIGN', 'SEM INDICATIVO', 'NO CALLSIGN', 'N/A', 'NULL', 'NONE')
            ]])
        end
    end)

    schemaState.running = false

    if not ok then
        if ps and ps.warn then
            ps.warn(('Schema compatibility update failed: %s'):format(tostring(err)))
        else
            print(('[%s][schema] compatibility update failed: %s'):format(resourceName, tostring(err)))
        end
        return false
    end

    schemaState.initialized = true
    return true
end

function GetMdtSchemaState()
    return schemaState
end

function MdtTableExists(tableName)
    return tableExists(tableName)
end

function MdtColumnExists(tableName, columnName)
    return columnExists(tableName, columnName)
end

CreateThread(function()
    Wait(0)
    EnsureMdtSchema()
end)
