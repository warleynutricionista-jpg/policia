local resourceName = tostring(GetCurrentResourceName())

local schemaState = {
    initialized = false,
    running = false,
    tableCache = {},
    columnCache = {},
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
    schemaDebug(('Added missing column %s.%s'):format(tableName, columnName))
    return true
end

local function ensureIndex(tableName, indexName, ddl)
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

    MySQL.query.await(('ALTER TABLE `%s` ADD %s'):format(tableName, ddl))
    schemaDebug(('Added missing index %s on %s'):format(indexName, tableName))
    return true
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

        ensureColumn('mdt_bolos', 'subject_name', { definition = '`subject_name` VARCHAR(100) NULL', after = 'subject_id' })
        ensureColumn('mdt_bolos', 'reportId', { definition = '`reportId` INT(11) UNSIGNED NULL', after = 'subject_name' })
        ensureColumn('mdt_bolos', 'notes', { definition = '`notes` TEXT NULL', after = 'reportId' })
        ensureColumn('mdt_bolos', 'status', { definition = "`status` ENUM('active','inactive','resolved') NOT NULL DEFAULT 'active'", after = 'notes' })
        ensureIndex('mdt_bolos', 'status', "INDEX `status` (`status`)")
        ensureIndex('mdt_bolos', 'reportId', "INDEX `reportId` (`reportId`)")
        ensureIndex('mdt_bolos', 'idx_mdt_bolos_type_status_subject', "INDEX `idx_mdt_bolos_type_status_subject` (`type`, `status`, `subject_id`)")

        ensureColumn('mdt_reports_restrictions', 'type', { definition = '`type` VARCHAR(32) NULL', after = 'reportid' })
        ensureColumn('mdt_reports_restrictions', 'identifier', { definition = '`identifier` VARCHAR(64) NULL', after = 'type' })
        ensureIndex('mdt_reports_restrictions', 'idx_mdt_reports_restrictions_type_identifier', "INDEX `idx_mdt_reports_restrictions_type_identifier` (`type`, `identifier`)")

        ensureColumn('mdt_tags', 'job_type', { definition = "`job_type` ENUM('leo','ems','all') NOT NULL DEFAULT 'all'", after = 'color' })
        ensureIndex('mdt_tags', 'idx_mdt_tags_job_type', "INDEX `idx_mdt_tags_job_type` (`job_type`)")

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
            ensureIndex('mdt_report_templates', 'idx_mdt_report_templates_job_type', "INDEX `idx_mdt_report_templates_job_type` (`job_type`)")
            ensureIndex('mdt_report_templates', 'idx_mdt_report_templates_type_name', "INDEX `idx_mdt_report_templates_type_name` (`type`, `name`)")
        end

        ensureColumn('player_vehicles', 'mdt_vehicle_information', { definition = '`mdt_vehicle_information` TEXT NULL', after = 'vehicle' })
        ensureColumn('player_vehicles', 'mdt_vehicle_points', { definition = '`mdt_vehicle_points` INT(11) NOT NULL DEFAULT 0', after = 'mdt_vehicle_information' })
        ensureColumn('player_vehicles', 'mdt_vehicle_status', { definition = "`mdt_vehicle_status` ENUM('valid','suspended','expired','impounded') NOT NULL DEFAULT 'valid'", after = 'mdt_vehicle_points' })
        ensureColumn('player_vehicles', 'mdt_vehicle_stolen', { definition = '`mdt_vehicle_stolen` TINYINT(1) NOT NULL DEFAULT 0', after = 'mdt_vehicle_status' })
        ensureColumn('player_vehicles', 'mdt_vehicle_boloactive', { definition = '`mdt_vehicle_boloactive` TINYINT(1) NOT NULL DEFAULT 0', after = 'mdt_vehicle_stolen' })
        ensureColumn('player_vehicles', 'mdt_vehicle_image', { definition = '`mdt_vehicle_image` VARCHAR(255) NULL', after = 'mdt_vehicle_boloactive' })
        ensureIndex('player_vehicles', 'idx_player_vehicles_citizenid_plate', "INDEX `idx_player_vehicles_citizenid_plate` (`citizenid`, `plate`)")

        ensureIndex('mdt_evidence_items', 'idx_mdt_evidence_items_case_created', "INDEX `idx_mdt_evidence_items_case_created` (`case_id`, `created_at`)")
        ensureIndex('mdt_evidence_items', 'idx_mdt_evidence_items_report_created', "INDEX `idx_mdt_evidence_items_report_created` (`report_id`, `created_at`)")
        ensureIndex('mdt_evidence_items', 'idx_mdt_evidence_items_type_stored', "INDEX `idx_mdt_evidence_items_type_stored` (`type`, `stored`)")

        ensureIndex('mdt_reports_involved', 'idx_mdt_reports_involved_citizenid', "INDEX `idx_mdt_reports_involved_citizenid` (`citizenid`)")
        ensureIndex('mdt_reports_charges', 'idx_mdt_reports_charges_citizenid', "INDEX `idx_mdt_reports_charges_citizenid` (`citizenid`)")
        ensureIndex('mdt_arrests', 'idx_mdt_arrests_citizenid', "INDEX `idx_mdt_arrests_citizenid` (`citizenid`)")

        if tableExists('mdt_bolos') and columnExists('mdt_bolos', 'status') then
            MySQL.update.await("UPDATE mdt_bolos SET status = 'active' WHERE status IS NULL OR status = ''")
        end

        if tableExists('mdt_reports') and columnExists('mdt_reports', 'contentplaintext') then
            MySQL.update.await("UPDATE mdt_reports SET contentplaintext = COALESCE(contentplaintext, '') WHERE contentplaintext IS NULL")
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
