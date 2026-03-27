-- ============================================================
-- PS-FORENSICS <> PS-MDT - Otimização e Ponte Operacional
-- ============================================================

local resourceName = GetCurrentResourceName()

local function runDDL(sql)
    local ok, err = pcall(function()
        MySQL.query.await(sql)
    end)

    if not ok and Config and Config.Debug then
        print(('[Police-Bridge] Falha ao aplicar DDL: %s | Erro: %s'):format(sql, err))
    end

    return ok
end

local function optimizeDatabase()
    print('^2[PS-OPTIMIZE] Iniciando otimização das tabelas policiais...^7')

    -- Índices de performance (busca MDT e vínculo forense)
    runDDL('ALTER TABLE `mdt_evidence_items` ADD INDEX IF NOT EXISTS `idx_mdt_evidence_case` (`case_id`)')
    runDDL('ALTER TABLE `mdt_evidence_items` ADD INDEX IF NOT EXISTS `idx_mdt_evidence_serial` (`serial`)')
    runDDL('ALTER TABLE `forensic_evidence` ADD INDEX IF NOT EXISTS `idx_forensic_seal` (`seal_number`)')
    runDDL('ALTER TABLE `mdt_profiles` ADD INDEX IF NOT EXISTS `idx_mdt_profiles_fullname_citizenid` (`fullname`, `citizenid`)')
    runDDL('ALTER TABLE `forensic_evidence` ADD INDEX IF NOT EXISTS `idx_forensic_evidence_created_at` (`created_at`)')

    -- Garantia de tabela de custódia do MDT (fallback em servidores legados)
    runDDL([[
        CREATE TABLE IF NOT EXISTS `mdt_evidence_custody` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `evidence_id` INT UNSIGNED NOT NULL,
            `from_citizenid` VARCHAR(50) DEFAULT NULL,
            `to_citizenid` VARCHAR(50) DEFAULT NULL,
            `action` ENUM('collected','transferred','stored','released','updated','viewed') NOT NULL DEFAULT 'collected',
            `notes` TEXT,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `evidence_id` (`evidence_id`),
            CONSTRAINT `FK_mdt_evidence_custody_items` FOREIGN KEY (`evidence_id`) REFERENCES `mdt_evidence_items` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    print('^2[PS-OPTIMIZE] Banco de Dados otimizado com sucesso!^7')
end

RegisterCommand('checkpolice', function(source)
    local src = source

    if src ~= 0 and not IsPlayerAceAllowed(src, 'command.checkpolice') then
        print(('^1[PS-INTEGRITY] Player %s sem permissão para /checkpolice.^7'):format(src))
        return
    end

    print('^3[PS-INTEGRITY] Checando comunicação entre Forensics e MDT...^7')
    local forensicsState = GetResourceState('ps-forensics')
    local mdtState = GetResourceState('ps-mdt')

    if forensicsState == 'started' and mdtState == 'started' then
        print('^2[OK] Ambos os sistemas estão comunicando.^7')
    else
        print('^1[ERRO] Verifique se ps-forensics e ps-mdt estão iniciados no server.cfg.^7')
    end
end, true)

local DB = {}

function DB.CreateEvidenceLink(evidenceData)
    if type(evidenceData) ~= 'table' then return nil end

    local query = [[
        INSERT INTO mdt_evidence_items (case_id, report_id, title, type, serial, notes, location, stored, last_holder, created_by)
        VALUES (?, ?, ?, ?, ?, ?, ?, 0, ?, ?)
    ]]

    return MySQL.insert.await(query, {
        tonumber(evidenceData.caseId) or nil,
        tonumber(evidenceData.reportId) or nil,
        evidenceData.title or ('[FORENSE] %s'):format(evidenceData.type or 'evidence'),
        evidenceData.type or 'outros',
        evidenceData.identifier or nil,
        evidenceData.notes or 'Coletado automaticamente via perícia',
        evidenceData.location or nil,
        evidenceData.holderCitizenId or nil,
        evidenceData.createdBy or evidenceData.holderCitizenId or nil,
    })
end

local function notifyDNAMatch(evidenceId, result)
    if type(result) ~= 'table' then return end
    if result.type ~= 'dna' and result.type ~= 'fingerprint' then return end
    if not result.hash or result.hash == '' then return end

    local row = MySQL.single.await([[
        SELECT mp.fullname, mp.citizenid
        FROM mdt_profiles mp
        LEFT JOIN players p ON p.citizenid = mp.citizenid
        WHERE mp.citizenid = ?
           OR JSON_UNQUOTE(JSON_EXTRACT(p.metadata, '$.fingerprint')) = ?
           OR JSON_UNQUOTE(JSON_EXTRACT(p.metadata, '$.dna')) = ?
        LIMIT 1
    ]], { result.hash, result.hash, result.hash })

    if not row then return end

    TriggerClientEvent('ox_lib:notify', -1, {
        title = 'Match Criminal Encontrado',
        description = ('Evidência #%s coincide com %s'):format(tostring(evidenceId or 'N/A'), row.fullname or row.citizenid),
        type = 'warning',
        icon = 'dna',
    })
end

RegisterNetEvent('ps-forensics:server:LabTestComplete', function(evidenceId, result)
    notifyDNAMatch(evidenceId, result)
end)

local function cleanupOldScenes()
    local affectedRows = MySQL.update.await('DELETE FROM forensic_evidence WHERE created_at < NOW() - INTERVAL 48 HOUR') or 0

    if affectedRows > 0 then
        print(('^3[Police-Bridge] Limpeza de %d evidências antigas concluída.^7'):format(affectedRows))
    end
end

lib.callback.register('ps-mdt:server:getNearbyEvidence', function(_, coords)
    local _ = coords -- reservado para filtro geográfico futuro

    return MySQL.query.await([[
        SELECT id, type, evidence_number, collection_x, collection_y, collection_z, created_at
        FROM forensic_evidence
        WHERE created_at > NOW() - INTERVAL 30 MINUTE
        ORDER BY created_at DESC
        LIMIT 200
    ]]) or {}
end)

RegisterNetEvent('ps-forensics:server:onEvidenceCollect', function(data)
    local src = source
    local payload = type(data) == 'table' and data or {}

    if payload.mdtEvidenceId then
        return
    end

    local playerData = src and src > 0 and GetPlayerData(src) or nil
    payload.createdBy = payload.createdBy or (playerData and playerData.citizenid or nil)
    payload.holderCitizenId = payload.holderCitizenId or payload.createdBy

    if not payload.type then return end

    local evidenceType = tostring(payload.type)
    local autoId = string.upper(('%s-%d%04d'):format(evidenceType:sub(1, 3), os.time(), math.random(1000, 9999)))

    local mdtId = DB.CreateEvidenceLink({
        caseId = payload.caseId,
        reportId = payload.reportId,
        title = payload.title or ('[AUTO] %s'):format(evidenceType),
        type = evidenceType,
        identifier = payload.identifier or autoId,
        notes = payload.notes or ('Coletado automaticamente por: %s'):format(GetPlayerName(src) or 'Sistema'),
        location = payload.location,
        holderCitizenId = payload.holderCitizenId,
        createdBy = payload.createdBy,
    })

    if mdtId then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Evidência Registrada',
            description = ('ID Gerado: %s anexado ao MDT.'):format(autoId),
            type = 'success',
        })
    end
end)

MySQL.ready(function()
    if GetResourceState('ps-mdt') ~= 'started' then
        print('^3[PS-OPTIMIZE] ps-mdt não iniciado; aplicando somente otimizações locais.^7')
    end

    optimizeDatabase()

    if lib and lib.cron and lib.cron.add then
        lib.cron.add('0 * * * *', cleanupOldScenes)
    end
end)
