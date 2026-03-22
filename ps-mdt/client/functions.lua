-- Dispatch Functions --
local ps = RequirePs('client/functions.lua')

-- Get Recent Dispatch Calls
function GetRecentDispatch()
    local resourceName = tostring(GetCurrentResourceName())
    local ok, result = pcall(function()
        return ps.callback(resourceName .. ':server:getRecentDispatches')
    end)
    if ok and result then
        return result
    end
    return {}
end

-- QBCore / QBox player loaded event
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    local check = ps.callback('ps-mdt:hasProfile')
end)

-- QBox-specific player loaded event
AddEventHandler('qbx_core:client:playerLoaded', function()
    local check = ps.callback('ps-mdt:hasProfile')
end)
