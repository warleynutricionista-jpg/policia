-- ============================================================
-- PS-FORENSICS - Autenticação e Autorização
-- ============================================================

local resourceName = GetCurrentResourceName()

-- Cache de QBX core com inicialização lazy (evita race condition)
local QBX = nil

local function ensureCore()
    if QBX then return QBX end

    -- Tentar QBox (qbx_core)
    local ok, core = pcall(function()
        return exports['qbx_core']:GetCoreObject()
    end)
    if ok and core then
        QBX = core
        return QBX
    end

    -- Fallback: QBCore legado
    local ok2, core2 = pcall(function()
        return exports['qb-core']:GetCoreObject()
    end)
    if ok2 and core2 then
        QBX = core2
        return QBX
    end

    return nil
end

-- Inicialização eagerly em thread (para ter pronto o mais rápido possível)
CreateThread(function()
    ensureCore()
end)

-- Obter dados do jogador
function GetPlayerData(src)
    if not src then return nil end

    local core = ensureCore()
    if not core then
        print(('[%s] AVISO: Framework core não disponível ao verificar jogador %s'):format(resourceName, tostring(src)))
        return nil
    end

    local ok, player = pcall(function()
        return core.Functions.GetPlayer(src)
    end)

    if ok and player and player.PlayerData then
        local pd = player.PlayerData
        return {
            citizenid = pd.citizenid,
            name = (pd.charinfo and pd.charinfo.firstname or '') .. ' ' .. (pd.charinfo and pd.charinfo.lastname or ''),
            job = pd.job and pd.job.name or '',
            jobType = pd.job and pd.job.type or '',
            grade = pd.job and pd.job.grade and pd.job.grade.level or 0,
            jobLabel = pd.job and pd.job.label or '',
            gradeLabel = pd.job and pd.job.grade and pd.job.grade.name or '',
        }
    end

    return nil
end

local function isAdminGroup(src)
    if not src then return false end

    for _, group in ipairs(Config.AdminGroups or {}) do
        local ok = false
        if QBX and QBX.Functions and QBX.Functions.HasPermission then
            local hasGroup = QBX.Functions.HasPermission(src, group)
            if hasGroup then
                ok = true
            end
        end

        if (not ok) and IsPlayerAceAllowed and IsPlayerAceAllowed(src, ('group.%s'):format(group)) then
            ok = true
        end

        if ok then
            return true
        end
    end

    return false
end

-- Verificar se tem acesso ao sistema forense
function CheckForensicAuth(src)
    local data = GetPlayerData(src)
    if not data then return false end
    data.isAdmin = isAdminGroup(src)

    if not data.isAdmin and not ForensicUtils.IsAuthorizedForensicsJob(data.job) then
        lib.notify(src, {
            title = L('ui.system_name'),
            description = L('ui.access_denied_authorized_only'),
            type = 'error',
            position = Config.Notifications.position,
        })
        return false
    end

    return true
end

-- Verificar permissão específica forense
function CheckForensicPermission(src, permission)
    local data = GetPlayerData(src)
    if not data then return false end

    return ForensicUtils.HasPermission(data.job, data.grade, permission, data.gradeLabel)
end

-- Obter role do jogador
function GetPlayerRole(src)
    local data = GetPlayerData(src)
    if not data then return nil, nil end
    return ForensicUtils.GetPlayerRole(data.job, data.grade, data.gradeLabel)
end

-- Log de auditoria forense
function ForensicAuditLog(src, action, entityType, entityId, details)
    local data = GetPlayerData(src)
    local citizenid = data and data.citizenid or 'system'
    local name = data and data.name or 'Sistema'

    MySQL.insert('INSERT INTO forensic_audit_log (actor_citizenid, actor_name, action, entity_type, entity_id, details) VALUES (?, ?, ?, ?, ?, ?)', {
        citizenid, name, action, entityType, entityId, json.encode(details or {})
    })

    if Config.Debug then
        print(('[ps-forensics] AUDIT: %s | %s | %s | %s | ID:%s'):format(
            citizenid, name, action, entityType, tostring(entityId)
        ))
    end
end

local function trimToString(value)
    if value == nil then return nil end
    local v = tostring(value):gsub('^%s*(.-)%s*$', '%1')
    if v == '' then return nil end
    return v
end

function EnsureInvestigativeSubject(citizenid, reason, sourceType, sourceId, actorCitizenId)
    citizenid = trimToString(citizenid)
    if not citizenid then return false end

    MySQL.insert.await([[
        INSERT INTO forensic_investigative_subjects
        (citizenid, reason, source_type, source_id, status, added_by)
        VALUES (?, ?, ?, ?, 'active', ?)
        ON DUPLICATE KEY UPDATE
            status = 'active',
            reason = VALUES(reason),
            source_type = VALUES(source_type),
            source_id = VALUES(source_id),
            updated_at = CURRENT_TIMESTAMP,
            added_by = COALESCE(VALUES(added_by), added_by)
    ]], {
        citizenid,
        trimToString(reason) or 'Entrada automática na base investigativa',
        trimToString(sourceType) or 'manual',
        trimToString(sourceId),
        trimToString(actorCitizenId) or 'system',
    })

    return true
end

-- Obter dados básicos de outro jogador (para targets forenses)
lib.callback.register(GetCurrentResourceName() .. ':server:getTargetPlayerInfo', function(source, targetServerId)
    local src = source
    if not CheckForensicAuth(src) then return nil end

    targetServerId = tonumber(targetServerId)
    if not targetServerId then return nil end

    local targetData = GetPlayerData(targetServerId)
    if not targetData then return nil end

    return {
        citizenid = targetData.citizenid,
        name = targetData.name,
        job = targetData.job,
    }
end)

function IsCitizenInInvestigativeBase(citizenid)
    citizenid = trimToString(citizenid)
    if not citizenid then return false end

    local enrolled = tonumber(MySQL.scalar.await(
        "SELECT COUNT(*) FROM forensic_investigative_subjects WHERE citizenid = ? AND status = 'active'",
        { citizenid }
    )) or 0
    if enrolled > 0 then return true end

    local hasArrest = tonumber(MySQL.scalar.await('SELECT COUNT(*) FROM mdt_arrests WHERE citizenid = ?', { citizenid })) or 0
    if hasArrest > 0 then
        EnsureInvestigativeSubject(citizenid, 'Elegível por histórico de prisão', 'mdt_arrest', nil, 'system')
        return true
    end

    local hasWarrant = tonumber(MySQL.scalar.await(
        'SELECT COUNT(*) FROM mdt_reports_warrants WHERE citizenid = ? AND expirydate >= NOW()',
        { citizenid }
    )) or 0
    if hasWarrant > 0 then
        EnsureInvestigativeSubject(citizenid, 'Elegível por mandado ativo', 'mdt_warrant', nil, 'system')
        return true
    end

    local hasForensicLink = tonumber(MySQL.scalar.await([[
        SELECT COUNT(*) FROM forensic_evidence
        WHERE linked_citizenid = ?
    ]], { citizenid })) or 0

    if hasForensicLink > 0 then
        EnsureInvestigativeSubject(citizenid, 'Elegível por vínculo forense prévio', 'forensic_evidence', nil, 'system')
        return true
    end

    return false
end
