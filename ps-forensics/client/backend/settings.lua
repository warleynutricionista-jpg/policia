-- ============================================================
-- PS-FORENSICS - Settings (Configurações do Painel)
-- Aba Configurações: acesso restrito a administracao (nível 3)
-- ============================================================

local resourceName = GetCurrentResourceName()

RegisterNUICallback('getForensicPanelSettings', function(_, cb)
    local result = lib.callback.await(resourceName .. ':server:getForensicPanelSettings', false)
    cb(result or { success = false })
end)

RegisterNUICallback('saveTabSettings', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:saveTabSettings', false, data)
    cb(result or { success = false })
end)

RegisterNUICallback('getForensicRolePermissions', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:getForensicRolePermissions', false, data)
    cb(result or { success = false, roles = {} })
end)

RegisterNUICallback('updateForensicRolePermission', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:updateForensicRolePermission', false, data)
    cb(result or { success = false })
end)

RegisterNUICallback('resetForensicSettings', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:resetForensicSettings', false, data)
    cb(result or { success = false })
end)
