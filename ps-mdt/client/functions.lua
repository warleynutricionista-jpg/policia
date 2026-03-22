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

local function ensureProfileExists()
    ps.callback('ps-mdt:hasProfile')
end

if (Config.Framework or 'qbx'):lower() == 'qbx' then
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', ensureProfileExists)
else
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', ensureProfileExists)
end
