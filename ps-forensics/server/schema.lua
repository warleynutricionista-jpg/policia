-- ============================================================
-- PS-FORENSICS - Auto-migration de Schema
-- Executa schema base idempotente + migrations versionadas
-- ============================================================

local resourceName = GetCurrentResourceName()

local function isIgnorableSqlError(err)
    local message = tostring(err or ''):lower()
    return message:find('duplicate column name', 1, true) ~= nil
        or message:find('1060', 1, true) ~= nil
        or message:find('already exists', 1, true) ~= nil
end

local function executeSqlStatements(sqlBlob, sourceLabel)
    local statements = {}

    for stmt in sqlBlob:gmatch('([^;]+)') do
        stmt = stmt:match('^%s*(.-)%s*$')
        if stmt and stmt ~= '' and not stmt:match('^%s*%-%-') then
            statements[#statements + 1] = stmt
        end
    end

    local success, failed = 0, 0

    for _, stmt in ipairs(statements) do
        if stmt:match('%S') then
            local ok, err = pcall(function()
                MySQL.query.await(stmt)
            end)

            if ok then
                success = success + 1
            else
                if isIgnorableSqlError(err) then
                    success = success + 1
                    print(('[%s] Aviso SQL ignorado (%s): %s'):format(resourceName, sourceLabel, tostring(err)))
                else
                    failed = failed + 1
                    print(('[%s] ^1Erro SQL (%s): %s^0'):format(resourceName, sourceLabel, tostring(err)))
                end
            end
        end
    end

    return success, failed
end

local function ensureMigrationsTable()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS forensic_schema_migrations (
            id INT UNSIGNED NOT NULL AUTO_INCREMENT,
            migration VARCHAR(150) NOT NULL,
            applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            UNIQUE KEY uk_forensic_schema_migration (migration)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
end

local function applyBaseSchema()
    local sqlFile = LoadResourceFile(resourceName, 'sql/forensics.sql')
    if not sqlFile then
        print(('[%s] ^1ERRO: Arquivo sql/forensics.sql não encontrado!^0'):format(resourceName))
        return false
    end

    local okCount, failCount = executeSqlStatements(sqlFile, 'base')
    print(('[%s] Schema base aplicado: %d statements, %d erros'):format(resourceName, okCount, failCount))
    return true
end

local function getMigrationList()
    local indexRaw = LoadResourceFile(resourceName, 'sql/migrations/index.lua')
    if not indexRaw then
        return {}
    end

    local chunk, err = load(indexRaw, '@@sql/migrations/index.lua', 't', {})
    if not chunk then
        print(('[%s] ^1Erro ao carregar índice de migrations: %s^0'):format(resourceName, tostring(err)))
        return {}
    end

    local ok, files = pcall(chunk)
    if not ok or type(files) ~= 'table' then
        print(('[%s] ^1Índice de migrations inválido.^0'):format(resourceName))
        return {}
    end

    table.sort(files)
    return files
end

local function applyMigrations()
    local files = getMigrationList()
    if #files == 0 then
        print(('[%s] Nenhuma migration versionada para aplicar.'):format(resourceName))
        return
    end

    for _, fileName in ipairs(files) do
        local alreadyApplied = MySQL.scalar.await(
            'SELECT COUNT(*) FROM forensic_schema_migrations WHERE migration = ?',
            { fileName }
        )

        if alreadyApplied and alreadyApplied > 0 then
            goto continue
        end

        local path = ('sql/migrations/%s'):format(fileName)
        local migrationSql = LoadResourceFile(resourceName, path)
        if not migrationSql then
            print(('[%s] ^1Migration não encontrada: %s^0'):format(resourceName, path))
            goto continue
        end

        local okCount, failCount = executeSqlStatements(migrationSql, fileName)
        if failCount == 0 then
            MySQL.insert.await(
                'INSERT INTO forensic_schema_migrations (migration) VALUES (?)',
                { fileName }
            )
            print(('[%s] Migration aplicada: %s (%d statements)'):format(resourceName, fileName, okCount))
        else
            print(('[%s] ^1Migration com erros: %s (%d ok / %d erro)^0'):format(resourceName, fileName, okCount, failCount))
        end

        ::continue::
    end
end

CreateThread(function()
    ensureMigrationsTable()
    if applyBaseSchema() then
        applyMigrations()
    end
end)
