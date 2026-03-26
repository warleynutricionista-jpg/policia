-- ============================================================
-- PS-FORENSICS - Autenticação e Autorização
-- ============================================================

local resourceName = GetCurrentResourceName()

-- Cache de QBX core
local QBX = nil

CreateThread(function()
    local ok, core = pcall(function()
        return exports['qbx_core']:GetCoreObject()
    end)
    if ok and core then
        QBX = core
    end
end)

-- Obter dados do jogador
function GetPlayerData(src)
    if not src then return nil end

    if QBX then
        local player = QBX.Functions.GetPlayer(src)
        if player then
            return {
                citizenid = player.PlayerData.citizenid,
                name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
                job = player.PlayerData.job.name,
                grade = player.PlayerData.job.grade.level,
                jobLabel = player.PlayerData.job.label,
                gradeLabel = player.PlayerData.job.grade.name,
                isAdmin = false,
            }
        end
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
    data.isAdmin = isAdminGroup(src)
    return ForensicUtils.HasPermission(data.job, data.grade, permission, data.isAdmin)
end

-- Obter role do jogador
function GetPlayerRole(src)
    local data = GetPlayerData(src)
    if not data then return nil, nil end
    data.isAdmin = isAdminGroup(src)
    if data.isAdmin then
        return 'administracao', {
            canCreateScene = true,
            canCollectEvidence = true,
            canRunBasicTests = true,
            canRunLabTests = true,
            canEmitReport = true,
            canPerformAutopsy = true,
            canModifyCustody = true,
            canFinalizeReport = true,
            canAdminForensics = true,
        }
    end
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
