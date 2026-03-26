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
            grade = pd.job and pd.job.grade and pd.job.grade.level or 0,
            jobLabel = pd.job and pd.job.label or '',
            gradeLabel = pd.job and pd.job.grade and pd.job.grade.name or '',
        }
    end

    return nil
end

-- Verificar se tem acesso ao sistema forense
function CheckForensicAuth(src)
    local data = GetPlayerData(src)
    if not data then return false end

    if not ForensicUtils.IsAuthorizedForensicsJob(data.job) then
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

    return ForensicUtils.HasPermission(data.job, data.grade, permission)
end

-- Obter role do jogador
function GetPlayerRole(src)
    local data = GetPlayerData(src)
    if not data then return nil, nil end
    return ForensicUtils.GetPlayerRole(data.job, data.grade)
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
