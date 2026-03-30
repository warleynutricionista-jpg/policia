local RESOURCE = GetCurrentResourceName()

local function debugLog(...)
    if Config.Debug then
        print(('[%s] %s'):format(RESOURCE, table.concat({ ... }, ' ')))
    end
end

local function trim(v)
    if v == nil then return nil end
    local s = tostring(v):gsub('^%s+', ''):gsub('%s+$', '')
    if s == '' then return nil end
    return s
end

local function getJobName(src)
    if GetResourceState('qbx_core') == 'started' then
        local ok, player = pcall(exports.qbx_core.GetPlayer, exports.qbx_core, src)
        if ok and player and player.PlayerData and player.PlayerData.job then
            return player.PlayerData.job.name
        end
    end

    if GetResourceState('qb-core') == 'started' then
        local ok, core = pcall(function() return exports['qb-core']:GetCoreObject() end)
        if ok and core then
            local player = core.Functions.GetPlayer(src)
            if player and player.PlayerData and player.PlayerData.job then
                return player.PlayerData.job.name
            end
        end
    end

    if GetResourceState('es_extended') == 'started' then
        local ok, xPlayer = pcall(function() return exports.es_extended:getPlayerFromId(src) end)
        if ok and xPlayer and xPlayer.job then
            return xPlayer.job.name
        end
    end

    return nil
end

local function getPlayerSourceByCitizenId(citizenid)
    if not citizenid then return nil end

    if GetResourceState('qbx_core') == 'started' then
        local ok, player = pcall(function()
            return exports.qbx_core:GetPlayerByCitizenId(citizenid)
        end)
        if ok and player then
            return player.PlayerData and player.PlayerData.source or player.source
        end
    end

    if GetResourceState('qb-core') == 'started' then
        local ok, core = pcall(function() return exports['qb-core']:GetCoreObject() end)
        if ok and core then
            local player = core.Functions.GetPlayerByCitizenId(citizenid)
            if player and player.PlayerData then
                return player.PlayerData.source
            end
        end
    end

    return nil
end

local function resolveRole(src)
    for roleName, roleData in pairs(Config.Roles or {}) do
        for _, ace in ipairs(roleData.aces or {}) do
            if IsPlayerAceAllowed(src, ace) then
                return roleName, roleData
            end
        end
    end

    local jobName = trim(getJobName(src))
    if jobName and Config.RoleByJob[jobName] then
        local roleName = Config.RoleByJob[jobName]
        return roleName, Config.Roles[roleName]
    end

    return nil, nil
end

local function ensureSchema()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS judiciary_settings (
            setting_key VARCHAR(64) NOT NULL,
            setting_value VARCHAR(255) NOT NULL,
            updated_by VARCHAR(64) NULL,
            updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (setting_key)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS judiciary_processes (
            id INT UNSIGNED NOT NULL AUTO_INCREMENT,
            process_number VARCHAR(32) NOT NULL,
            citizenid VARCHAR(64) NOT NULL,
            defendant_name VARCHAR(120) NULL,
            plaintiff_citizenid VARCHAR(64) NULL,
            plaintiff_name VARCHAR(120) NULL,
            case_area ENUM('familia','trabalhista','geral','criminal') NOT NULL DEFAULT 'geral',
            claim_type VARCHAR(120) NULL,
            linked_case_ids LONGTEXT NULL,
            status ENUM('aguardando_aceite','rejeitado_entrada','triagem','audiencia_marcada','em_julgamento','sentenciado','arquivado') NOT NULL DEFAULT 'aguardando_aceite',
            origin_type ENUM('criminal','civil','administrativo') NOT NULL DEFAULT 'criminal',
            summary TEXT NULL,
            sentence_text LONGTEXT NULL,
            loser_party ENUM('autor','reu','nenhum') NOT NULL DEFAULT 'nenhum',
            court_costs INT UNSIGNED NOT NULL DEFAULT 200000,
            created_by VARCHAR(64) NOT NULL,
            created_by_name VARCHAR(120) NOT NULL,
            updated_by VARCHAR(64) NULL,
            updated_by_name VARCHAR(120) NULL,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            UNIQUE KEY uk_judiciary_process_number (process_number),
            KEY idx_judiciary_process_citizen (citizenid, status),
            KEY idx_judiciary_process_status (status, updated_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    MySQL.query.await("ALTER TABLE judiciary_processes MODIFY COLUMN status ENUM('aguardando_aceite','rejeitado_entrada','triagem','audiencia_marcada','em_julgamento','sentenciado','arquivado') NOT NULL DEFAULT 'aguardando_aceite'")
    MySQL.query.await("ALTER TABLE judiciary_processes MODIFY COLUMN case_area ENUM('familia','trabalhista','geral','criminal') NOT NULL DEFAULT 'geral'")
    MySQL.query.await('ALTER TABLE judiciary_processes ADD COLUMN IF NOT EXISTS plaintiff_citizenid VARCHAR(64) NULL AFTER defendant_name')
    MySQL.query.await('ALTER TABLE judiciary_processes ADD COLUMN IF NOT EXISTS plaintiff_name VARCHAR(120) NULL AFTER plaintiff_citizenid')
    MySQL.query.await("ALTER TABLE judiciary_processes ADD COLUMN IF NOT EXISTS case_area ENUM('familia','trabalhista','geral','criminal') NOT NULL DEFAULT 'geral' AFTER plaintiff_name")
    MySQL.query.await('ALTER TABLE judiciary_processes ADD COLUMN IF NOT EXISTS claim_type VARCHAR(120) NULL AFTER case_area')
    MySQL.query.await("ALTER TABLE judiciary_processes ADD COLUMN IF NOT EXISTS loser_party ENUM('autor','reu','nenhum') NOT NULL DEFAULT 'nenhum' AFTER sentence_text")
    MySQL.query.await('ALTER TABLE judiciary_processes ADD COLUMN IF NOT EXISTS court_costs INT UNSIGNED NOT NULL DEFAULT 200000 AFTER loser_party')

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS judiciary_process_events (
            id INT UNSIGNED NOT NULL AUTO_INCREMENT,
            process_id INT UNSIGNED NOT NULL,
            event_type VARCHAR(50) NOT NULL,
            title VARCHAR(120) NOT NULL,
            description LONGTEXT NULL,
            created_by VARCHAR(64) NOT NULL,
            created_by_name VARCHAR(120) NOT NULL,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            KEY idx_judiciary_events_process (process_id, created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    MySQL.insert.await([[
        INSERT IGNORE INTO judiciary_settings (setting_key, setting_value)
        VALUES ('required_criminal_cases', ?)
    ]], { tostring(Config.CaseTrigger.defaultRequiredCases or 3) })

    MySQL.insert.await([[
        INSERT IGNORE INTO judiciary_settings (setting_key, setting_value)
        VALUES ('court_costs_loser', ?)
    ]], { tostring((Config.CourtCosts and Config.CourtCosts.loserPays) or 200000) })
end

local function getSettingNumber(key, fallback)
    local value = MySQL.scalar.await('SELECT setting_value FROM judiciary_settings WHERE setting_key = ? LIMIT 1', { key })
    local num = tonumber(value)
    if not num then return fallback end
    return num
end

local function setSettingNumber(key, value, updatedBy)
    MySQL.insert.await([[
        INSERT INTO judiciary_settings (setting_key, setting_value, updated_by)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value), updated_by = VALUES(updated_by)
    ]], { key, tostring(value), updatedBy })
end

local function buildProcessNumber(id)
    return ('PROC-%s-%05d'):format(os.date('%Y'), id)
end

local function getEligibleDefendants(requiredCases)
    local rows = MySQL.query.await([[
        SELECT
            ri.citizenid,
            COUNT(DISTINCT cr.case_id) AS total_cases,
            MAX(mr.datecreated) AS last_report_date,
            mp.fullname,
            mp.birthdate,
            mp.callsign,
            (
                SELECT COUNT(*)
                FROM mdt_arrests ma
                WHERE ma.citizenid = ri.citizenid
            ) AS arrest_count,
            (
                SELECT COUNT(*)
                FROM mdt_reports_warrants rw
                WHERE rw.citizenid = ri.citizenid
            ) AS warrant_count,
            (
                SELECT COUNT(*)
                FROM forensic_investigative_subjects fis
                WHERE fis.citizenid = ri.citizenid
                  AND fis.status = 'active'
            ) AS forensic_watch_count,
            (
                SELECT COUNT(DISTINCT fcs.id)
                FROM forensic_evidence fe
                LEFT JOIN forensic_crime_scenes fcs ON fcs.id = fe.scene_id
                WHERE fe.linked_citizenid = ri.citizenid
            ) AS suspected_scene_count,
            GROUP_CONCAT(DISTINCT cr.case_id ORDER BY cr.case_id DESC SEPARATOR ',') AS linked_cases
        FROM mdt_reports_involved ri
        LEFT JOIN mdt_case_reports cr ON cr.report_id = ri.reportid
        LEFT JOIN mdt_reports mr ON mr.id = ri.reportid
        LEFT JOIN mdt_profiles mp ON mp.citizenid COLLATE utf8mb4_general_ci = ri.citizenid COLLATE utf8mb4_general_ci
        WHERE cr.case_id IS NOT NULL
          AND LOWER(COALESCE(ri.type, '')) IN ('suspect','accused','culpado','acusado')
        GROUP BY ri.citizenid
        HAVING total_cases >= ?
        ORDER BY total_cases DESC, last_report_date DESC
        LIMIT 250
    ]], { requiredCases }) or {}

    local formatted = {}
    for i = 1, #rows do
        local row = rows[i]
        local caseIds = {}
        if row.linked_cases and row.linked_cases ~= '' then
            for value in tostring(row.linked_cases):gmatch('[^,]+') do
                caseIds[#caseIds + 1] = tonumber(value)
            end
        end

        formatted[#formatted + 1] = {
            citizenid = row.citizenid,
            fullname = row.fullname or row.citizenid,
            birthdate = row.birthdate,
            totalCases = tonumber(row.total_cases) or 0,
            lastReportDate = row.last_report_date,
            arrests = tonumber(row.arrest_count) or 0,
            warrants = tonumber(row.warrant_count) or 0,
            forensicWatch = tonumber(row.forensic_watch_count) or 0,
            suspectedScenes = tonumber(row.suspected_scene_count) or 0,
            linkedCases = caseIds,
        }
    end

    return formatted
end

local function getProcessList()
    local rows = MySQL.query.await([[
        SELECT id, process_number, citizenid, defendant_name, linked_case_ids, status,
               plaintiff_citizenid, plaintiff_name, case_area, claim_type, origin_type,
               summary, sentence_text, loser_party, court_costs, created_by_name, updated_by_name,
               created_at, updated_at
        FROM judiciary_processes
        ORDER BY updated_at DESC
        LIMIT 200
    ]]) or {}

    for _, row in ipairs(rows) do
        local ok, decoded = pcall(json.decode, row.linked_case_ids or '[]')
        row.linked_case_ids = ok and decoded or {}
    end

    return rows
end

local function getProcessById(processId)
    local row = MySQL.single.await([[
        SELECT id, process_number, citizenid, defendant_name, linked_case_ids, status,
               plaintiff_citizenid, plaintiff_name, case_area, claim_type, origin_type,
               summary, sentence_text, loser_party, court_costs, created_by_name, updated_by_name,
               created_at, updated_at
        FROM judiciary_processes
        WHERE id = ?
    ]], { processId })

    if not row then return nil end

    local ok, decoded = pcall(json.decode, row.linked_case_ids or '[]')
    row.linked_case_ids = ok and decoded or {}

    row.events = MySQL.query.await([[
        SELECT id, event_type, title, description, created_by_name, created_at
        FROM judiciary_process_events
        WHERE process_id = ?
        ORDER BY created_at DESC
    ]], { processId }) or {}

    return row
end

local function getActorName(src)
    return GetPlayerName(src) or ('ID ' .. tostring(src))
end

local function ensureAccess(src, perm)
    local roleName, roleData = resolveRole(src)
    if not roleName or not roleData then
        return nil, 'Sem acesso ao painel jurídico.'
    end

    if perm and not (roleData.can and roleData.can[perm]) then
        return nil, 'Seu perfil não possui permissão para esta ação.'
    end

    return {
        name = roleName,
        label = roleData.label,
        can = roleData.can,
    }, nil
end

lib.callback.register('ps-judiciary:server:getBootstrap', function(source)
    local access, err = ensureAccess(source, 'view')
    if not access then
        return { success = false, error = err }
    end

    local requiredCases = math.floor(getSettingNumber('required_criminal_cases', Config.CaseTrigger.defaultRequiredCases or 3))
    requiredCases = math.max(Config.CaseTrigger.min or 1, math.min(requiredCases, Config.CaseTrigger.max or 10))

    return {
        success = true,
        role = access,
        settings = {
            requiredCriminalCases = requiredCases,
            minRequiredCases = Config.CaseTrigger.min or 1,
            maxRequiredCases = Config.CaseTrigger.max or 10,
        },
        candidates = getEligibleDefendants(requiredCases),
        processes = getProcessList(),
    }
end)

lib.callback.register('ps-judiciary:server:getProcess', function(source, processId)
    local access, err = ensureAccess(source, 'view')
    if not access then return { success = false, error = err } end

    processId = tonumber(processId)
    if not processId then
        return { success = false, error = 'Processo inválido.' }
    end

    local process = getProcessById(processId)
    if not process then
        return { success = false, error = 'Processo não encontrado.' }
    end

    return { success = true, process = process }
end)

lib.callback.register('ps-judiciary:server:updateSettings', function(source, payload)
    local access, err = ensureAccess(source, 'settings')
    if not access then return { success = false, error = err } end

    payload = payload or {}
    local value = tonumber(payload.requiredCriminalCases)
    if not value then
        return { success = false, error = 'Valor inválido.' }
    end

    value = math.floor(value)
    value = math.max(Config.CaseTrigger.min or 1, math.min(value, Config.CaseTrigger.max or 10))

    setSettingNumber('required_criminal_cases', value, tostring(source))

    return {
        success = true,
        requiredCriminalCases = value,
        candidates = getEligibleDefendants(value),
    }
end)

lib.callback.register('ps-judiciary:server:createProcess', function(source, payload)
    local access, err = ensureAccess(source, 'create')
    if not access then return { success = false, error = err } end

    payload = payload or {}
    local citizenid = trim(payload.citizenid)
    if not citizenid then
        return { success = false, error = 'CitizenID é obrigatório.' }
    end

    local caseArea = trim(payload.caseArea) or 'criminal'
    if caseArea ~= 'criminal' and caseArea ~= 'familia' and caseArea ~= 'trabalhista' and caseArea ~= 'geral' then
        caseArea = 'geral'
    end

    local existing = MySQL.single.await('SELECT id, process_number FROM judiciary_processes WHERE citizenid = ? AND status <> ? LIMIT 1', {
        citizenid, 'arquivado'
    })
    if existing then
        return {
            success = false,
            error = ('Já existe processo ativo para este acusado: %s'):format(existing.process_number)
        }
    end

    local linkedCases = {}
    if type(payload.linkedCases) == 'table' then
        for _, id in ipairs(payload.linkedCases) do
            id = tonumber(id)
            if id then
                linkedCases[#linkedCases + 1] = id
            end
        end
    end

    if #linkedCases == 0 then
        local requiredCases = getSettingNumber('required_criminal_cases', Config.CaseTrigger.defaultRequiredCases or 3)
        local candidates = getEligibleDefendants(requiredCases)
        for _, candidate in ipairs(candidates) do
            if candidate.citizenid == citizenid then
                linkedCases = candidate.linkedCases or {}
                break
            end
        end
    end

    local actorName = getActorName(source)
    local profile = MySQL.single.await('SELECT fullname FROM mdt_profiles WHERE citizenid = ? LIMIT 1', { citizenid })
    local plaintiffCitizenId = trim(payload.plaintiffCitizenid)
    local plaintiffName = trim(payload.plaintiffName)
    local loserCosts = getSettingNumber('court_costs_loser', (Config.CourtCosts and Config.CourtCosts.loserPays) or 200000)

    local processId = MySQL.insert.await([[
        INSERT INTO judiciary_processes
            (process_number, citizenid, defendant_name, plaintiff_citizenid, plaintiff_name, case_area, claim_type, linked_case_ids, status, origin_type, summary, loser_party, court_costs, created_by, created_by_name)
        VALUES
            ('', ?, ?, ?, ?, ?, ?, ?, 'aguardando_aceite', ?, ?, 'nenhum', ?, ?, ?)
    ]], {
        citizenid,
        profile and profile.fullname or citizenid,
        plaintiffCitizenId,
        plaintiffName,
        caseArea,
        trim(payload.claimType) or 'Causa geral',
        json.encode(linkedCases),
        trim(payload.originType) or 'criminal',
        trim(payload.summary) or 'Processo criado automaticamente a partir do critério configurado.',
        loserCosts,
        tostring(source),
        actorName,
    })

    local processNumber = buildProcessNumber(processId)
    MySQL.update.await('UPDATE judiciary_processes SET process_number = ? WHERE id = ?', { processNumber, processId })

    MySQL.insert.await([[
        INSERT INTO judiciary_process_events (process_id, event_type, title, description, created_by, created_by_name)
        VALUES (?, 'criacao', 'Processo distribuído', ?, ?, ?)
    ]], {
        processId,
        ('Processo %s aberto para %s (%s). Aguardando aceite do juiz.'):format(processNumber, profile and profile.fullname or citizenid, caseArea),
        tostring(source),
        actorName,
    })

    return {
        success = true,
        process = getProcessById(processId),
    }
end)

lib.callback.register('ps-judiciary:server:reviewIntake', function(source, payload)
    local access, err = ensureAccess(source, 'verdict')
    if not access then return { success = false, error = err } end

    payload = payload or {}
    local processId = tonumber(payload.processId)
    if not processId then return { success = false, error = 'Processo inválido.' } end

    local accepted = payload.accepted == true
    local reason = trim(payload.reason) or 'Sem justificativa.'
    local actorName = getActorName(source)
    local newStatus = accepted and 'triagem' or 'rejeitado_entrada'
    local eventTitle = accepted and 'Entrada documental aceita' or 'Entrada documental rejeitada'

    MySQL.insert.await([[
        INSERT INTO judiciary_process_events (process_id, event_type, title, description, created_by, created_by_name)
        VALUES (?, 'triagem_documental', ?, ?, ?, ?)
    ]], {
        processId,
        eventTitle,
        reason,
        tostring(source),
        actorName,
    })

    MySQL.update.await([[
        UPDATE judiciary_processes
        SET status = ?, updated_by = ?, updated_by_name = ?
        WHERE id = ?
    ]], { newStatus, tostring(source), actorName, processId })

    return { success = true, process = getProcessById(processId) }
end)

lib.callback.register('ps-judiciary:server:finalizeJudgment', function(source, payload)
    local access, err = ensureAccess(source, 'verdict')
    if not access then return { success = false, error = err } end

    payload = payload or {}
    local processId = tonumber(payload.processId)
    if not processId then return { success = false, error = 'Processo inválido.' } end

    local loserParty = trim(payload.loserParty) or 'nenhum'
    if loserParty ~= 'autor' and loserParty ~= 'reu' and loserParty ~= 'nenhum' then
        loserParty = 'nenhum'
    end

    local baseSentence = trim(payload.sentenceText) or 'Sem detalhamento de sentença.'
    local costs = getSettingNumber('court_costs_loser', (Config.CourtCosts and Config.CourtCosts.loserPays) or 200000)
    local sentence = baseSentence
    if loserParty ~= 'nenhum' then
        sentence = sentence .. ('\\n\\nCustas judiciais: R$ %s (parte perdedora: %s).'):format(costs, loserParty)
    end

    local actorName = getActorName(source)
    MySQL.update.await([[
        UPDATE judiciary_processes
        SET status = 'sentenciado',
            loser_party = ?,
            sentence_text = ?,
            court_costs = ?,
            updated_by = ?,
            updated_by_name = ?
        WHERE id = ?
    ]], { loserParty, sentence, costs, tostring(source), actorName, processId })

    MySQL.insert.await([[
        INSERT INTO judiciary_process_events (process_id, event_type, title, description, created_by, created_by_name)
        VALUES (?, 'sentenca_final', 'Sentença final publicada', ?, ?, ?)
    ]], {
        processId,
        sentence,
        tostring(source),
        actorName,
    })

    return { success = true, process = getProcessById(processId) }
end)

lib.callback.register('ps-judiciary:server:scheduleDirectPrison', function(source, payload)
    local access, err = ensureAccess(source, 'verdict')
    if not access then return { success = false, error = err } end

    payload = payload or {}
    local processId = tonumber(payload.processId)
    local sentence = tonumber(payload.sentence) or 0
    if not processId then return { success = false, error = 'Processo inválido.' } end
    if sentence <= 0 then return { success = false, error = 'Tempo de prisão inválido.' } end

    local process = MySQL.single.await('SELECT id, citizenid, defendant_name FROM judiciary_processes WHERE id = ? LIMIT 1', { processId })
    if not process then
        return { success = false, error = 'Processo não encontrado.' }
    end

    local actorName = getActorName(source)
    local reason = trim(payload.reason) or 'Execução de ordem judicial de prisão.'
    local delayMs = 5 * 60 * 1000

    MySQL.insert.await([[
        INSERT INTO judiciary_process_events (process_id, event_type, title, description, created_by, created_by_name)
        VALUES (?, 'prisao_agendada', 'Prisão direta agendada (5 minutos)', ?, ?, ?)
    ]], {
        processId,
        ('Ordem de prisão registrada. Execução automática em 5 minutos para permitir condução até cela/sala. Motivo: %s'):format(reason),
        tostring(source),
        actorName,
    })

    SetTimeout(delayMs, function()
        local targetSource = getPlayerSourceByCitizenId(process.citizenid)
        local executionNote = ''

        if not targetSource then
            executionNote = 'Execução automática não concluída: réu offline no momento da ordem.'
        elseif GetResourceState('pickle_prisons') ~= 'started' then
            executionNote = 'Execução automática não concluída: pickle_prisons não iniciado.'
        else
            local ok, jailErr = pcall(function()
                exports['pickle_prisons']:JailPlayer(targetSource, sentence, 'default')
            end)

            if ok then
                executionNote = ('Réu enviado diretamente para prisão após delay de 5 minutos. Tempo aplicado: %s.'):format(sentence)
            else
                executionNote = ('Falha ao executar prisão automática: %s'):format(tostring(jailErr))
            end
        end

        MySQL.insert.await([[
            INSERT INTO judiciary_process_events (process_id, event_type, title, description, created_by, created_by_name)
            VALUES (?, 'prisao_execucao', 'Resultado da ordem de prisão direta', ?, ?, ?)
        ]], {
            processId,
            executionNote,
            tostring(source),
            actorName,
        })
    end)

    return { success = true, message = 'Prisão direta agendada para execução em 5 minutos.' }
end)

lib.callback.register('ps-judiciary:server:addEvent', function(source, payload)
    local access, err = ensureAccess(source, 'schedule')
    if not access then return { success = false, error = err } end

    payload = payload or {}
    local processId = tonumber(payload.processId)
    if not processId then return { success = false, error = 'Processo inválido.' } end

    local title = trim(payload.title)
    if not title then
        return { success = false, error = 'Título do andamento é obrigatório.' }
    end

    local eventType = trim(payload.eventType) or 'andamento'
    local status = trim(payload.status)
    local actorName = getActorName(source)

    MySQL.insert.await([[
        INSERT INTO judiciary_process_events (process_id, event_type, title, description, created_by, created_by_name)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        processId,
        eventType,
        title,
        trim(payload.description),
        tostring(source),
        actorName,
    })

    local updates = {
        'updated_by = ?',
        'updated_by_name = ?',
    }
    local values = { tostring(source), actorName }

    if status and (status == 'aguardando_aceite' or status == 'rejeitado_entrada' or status == 'triagem' or status == 'audiencia_marcada' or status == 'em_julgamento' or status == 'sentenciado' or status == 'arquivado') then
        updates[#updates + 1] = 'status = ?'
        values[#values + 1] = status
    end

    if payload.sentenceText and access.can.verdict then
        updates[#updates + 1] = 'sentence_text = ?'
        values[#values + 1] = trim(payload.sentenceText)
    end

    values[#values + 1] = processId
    MySQL.update.await(('UPDATE judiciary_processes SET %s WHERE id = ?'):format(table.concat(updates, ', ')), values)

    return {
        success = true,
        process = getProcessById(processId),
    }
end)

lib.callback.register('ps-judiciary:server:addDefenseNote', function(source, payload)
    local access, err = ensureAccess(source, 'defenseNotes')
    if not access then return { success = false, error = err } end

    payload = payload or {}
    local processId = tonumber(payload.processId)
    if not processId then return { success = false, error = 'Processo inválido.' } end

    local note = trim(payload.note)
    if not note then return { success = false, error = 'Nota obrigatória.' } end

    local actorName = getActorName(source)

    MySQL.insert.await([[
        INSERT INTO judiciary_process_events (process_id, event_type, title, description, created_by, created_by_name)
        VALUES (?, 'defesa', 'Manifestação da defesa', ?, ?, ?)
    ]], {
        processId,
        note,
        tostring(source),
        actorName,
    })

    MySQL.update.await('UPDATE judiciary_processes SET updated_by = ?, updated_by_name = ? WHERE id = ?', {
        tostring(source), actorName, processId
    })

    return {
        success = true,
        process = getProcessById(processId),
    }
end)

CreateThread(function()
    ensureSchema()
    debugLog('schema ensured')
end)
