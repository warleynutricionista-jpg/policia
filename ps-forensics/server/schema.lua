-- ============================================================
-- PS-FORENSICS - Auto-migration de Schema
-- Cria tabelas automaticamente ao iniciar o recurso
-- ============================================================

local resourceName = GetCurrentResourceName()

CreateThread(function()
    -- Verificar se as tabelas forenses existem
    local tableCheck = MySQL.scalar.await([[
        SELECT COUNT(*) FROM information_schema.tables
        WHERE table_schema = DATABASE()
        AND table_name = 'forensic_crime_scenes'
    ]])

    if tableCheck and tableCheck > 0 then
        print(('[%s] Tabelas forenses já existem - pulando migration'):format(resourceName))
        return
    end

    print(('[%s] Criando tabelas forenses...'):format(resourceName))

    -- Carregar e executar o SQL
    local sqlFile = LoadResourceFile(resourceName, 'sql/forensics.sql')
    if not sqlFile then
        print(('[%s] ^1ERRO: Arquivo sql/forensics.sql não encontrado!^0'):format(resourceName))
        return
    end

    -- Separar statements por ponto-e-vírgula
    local statements = {}
    for stmt in sqlFile:gmatch('([^;]+)') do
        stmt = stmt:match('^%s*(.-)%s*$')
        if stmt and stmt ~= '' and not stmt:match('^%s*%-%-') then
            statements[#statements + 1] = stmt
        end
    end

    local success = 0
    local failed = 0

    for _, stmt in ipairs(statements) do
        if stmt:match('%S') then
            local ok, err = pcall(function()
                MySQL.query.await(stmt)
            end)
            if ok then
                success = success + 1
            else
                failed = failed + 1
                print(('[%s] ^1Erro na migration: %s^0'):format(resourceName, tostring(err)))
            end
        end
    end

    print(('[%s] ^2Migration concluída: %d statements executados, %d erros^0'):format(resourceName, success, failed))
end)
