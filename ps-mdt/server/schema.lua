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

        ensureColumn('mdt_bolos', 'subject_name', { definition = '`subject_name` VARCHAR(100) NULL', after = 'subject_id' })
        ensureColumn('mdt_bolos', 'reportId', { definition = '`reportId` INT(11) UNSIGNED NULL', after = 'subject_name' })
        ensureColumn('mdt_bolos', 'notes', { definition = '`notes` TEXT NULL', after = 'reportId' })
        ensureColumn('mdt_bolos', 'status', { definition = "`status` ENUM('active','inactive','resolved') NOT NULL DEFAULT 'active'", after = 'notes' })
        ensureIndex('mdt_bolos', 'status', "INDEX `status` (`status`)")
        ensureIndex('mdt_bolos', 'reportId', "INDEX `reportId` (`reportId`)")

        ensureColumn('mdt_reports_restrictions', 'type', { definition = '`type` VARCHAR(32) NULL', after = 'reportid' })
        ensureColumn('mdt_reports_restrictions', 'identifier', { definition = '`identifier` VARCHAR(64) NULL', after = 'type' })

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

CreateThread(function()
    Wait(0)
    EnsureMdtSchema()
end)
