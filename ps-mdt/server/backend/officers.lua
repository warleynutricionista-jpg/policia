local resourceName = tostring(GetCurrentResourceName())
-- QBox-first core object resolution
local QBCore = nil
do
    local okQbx, qbx = pcall(function() return exports['qbx_core']:GetCoreObject() end)
    if okQbx and qbx then
        QBCore = qbx
    else
        local okQb, qb = pcall(function() return exports['qb-core']:GetCoreObject() end)
        if okQb and qb then QBCore = qb end
    end
end

-- Get player source ID by citizenId
ps.registerCallback(resourceName .. ':server:GetPlayerSourceId', function(source, targetCitizenId)
    if not targetCitizenId then return nil end
    local targetPlayer = ps.getPlayerByIdentifier(targetCitizenId)
    if not targetPlayer then
        ps.notify(source, 'O cidadão parece ausente / desconectado', 'error')
        return nil
    end
    return targetPlayer.source or targetPlayer.PlayerData.source
end)

-- Set Callsign
ps.registerCallback(resourceName .. ':server:setCallsign', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end

    payload = payload or {}
    local cid = payload.citizenid or payload.cid
    local newCallsign = payload.callsign or payload.newcallsign

    if not cid or not newCallsign then
        return { success = false, message = 'Faltando ID do cidadão ou indicativo' }
    end

    if not QBCore then return { success = false, message = 'Framework principal indisponível' } end
    local Player = QBCore.Functions.GetPlayerByCitizenId(cid)
    if Player then
        Player.Functions.SetMetaData('callsign', newCallsign)
        TriggerClientEvent(resourceName .. ':client:updateCallsign', Player.PlayerData.source, newCallsign)

        MySQL.update.await('UPDATE mdt_profiles SET callsign = ? WHERE citizenid = ?', { newCallsign, cid })
        Cache.invalidate('reports:officers:directory')

        if ps.auditLog then
            ps.auditLog(src, 'callsign_changed', 'officer', cid, { callsign = newCallsign })
        end

        return { success = true, message = 'Indicativo atualizado para ' .. newCallsign }
    end

    return { success = false, message = 'O jogador precisa estar online para atualizar o indicativo' }
end)

-- Set Radio Frequency
ps.registerCallback(resourceName .. ':server:setRadio', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end

    payload = payload or {}
    local cid = payload.citizenid or payload.cid
    local newRadio = payload.radio or payload.newradio

    if not cid or not newRadio then
        return { success = false, message = 'Faltando ID do cidadão ou frequência do rádio' }
    end

    if not QBCore then return { success = false, message = 'Framework principal indisponível' } end
    local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(cid)
    if not targetPlayer then
        return { success = false, message = 'O oficial precisa estar online' }
    end

    local targetSource = targetPlayer.PlayerData.source

    local radio = targetPlayer.Functions.GetItemByName('radio')
    if not radio then
        return { success = false, message = targetPlayer.PlayerData.charinfo.firstname .. ' does not have a radio!' }
    end

    TriggerClientEvent(resourceName .. ':client:setRadio', targetSource, newRadio)
    return { success = true, message = 'Rádio definido para ' .. newRadio }
end)

-- Get Unit Location (GPS to officer)
ps.registerCallback(resourceName .. ':server:getUnitLocation', function(source, cid)
    if not CheckAuth(source) then return {} end
    if not cid then return {} end

    if not QBCore then return {} end
    local Player = QBCore.Functions.GetPlayerByCitizenId(cid)
    if Player then
        local coords = GetEntityCoords(GetPlayerPed(Player.PlayerData.source))
        return { x = coords.x, y = coords.y, z = coords.z }
    end

    return {}
end)
