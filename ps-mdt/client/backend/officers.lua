local resourceName = tostring(GetCurrentResourceName())

-- Set Callsign
RegisterNUICallback('setCallsign', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    if type(data) ~= 'table' or (not data.cid and not data.citizenid) or (not data.newcallsign and not data.callsign) then
        cb({ success = false, message = 'Faltando ID do cidadão ou indicativo' })
        return
    end

    local result = ps.callback(resourceName .. ':server:setCallsign', {
        citizenid = data.cid or data.citizenid,
        callsign = data.newcallsign or data.callsign,
    })
    cb(result or { success = false, message = 'Falha ao definir o indicativo' })
end)

-- Set Radio Frequency
RegisterNUICallback('setRadio', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    if type(data) ~= 'table' or (not data.cid and not data.citizenid) or (not data.newradio and not data.radio) then
        cb({ success = false, message = 'Faltando ID do cidadão ou frequência do rádio' })
        return
    end

    local result = ps.callback(resourceName .. ':server:setRadio', {
        citizenid = data.cid or data.citizenid,
        radio = data.newradio or data.radio,
    })
    cb(result or { success = false, message = 'Falha ao definir o rádio' })
end)

-- Radio set event from server
RegisterNetEvent(resourceName .. ':client:setRadio')
AddEventHandler(resourceName .. ':client:setRadio', function(radio)
    if type(tonumber(radio)) == 'number' then
        local success = pcall(function()
            exports['pma-voice']:setVoiceProperty('radioEnabled', true)
            exports['pma-voice']:setRadioChannel(tonumber(radio))
        end)
        if success then
            ps.notify('Frequência do rádio definida para ' .. radio, 'success')
        else
            ps.notify('Falha ao definir o rádio - pma-voice indisponível', 'error')
        end
    else
        ps.notify('Frequência de rádio inválida', 'error')
    end
end)

-- Set Waypoint to Unit (GPS to another officer)
RegisterNUICallback('setWaypointU', function(data, cb)
    if not MDTOpen then cb('ok') return end
    local coords = ps.callback(resourceName .. ':server:getUnitLocation', data.cid)
    if coords then
        SetNewWaypoint(coords.x, coords.y)
        ps.notify('GPS definido para a localização do oficial', 'success')
    else
        ps.notify('Oficial não encontrado ou offline', 'error')
    end
    cb('ok')
end)

-- House Waypoint (Set GPS to property)
RegisterNUICallback('SetHouseLocation', function(data, cb)
    if not MDTOpen then cb('ok') return end
    if data.coord and data.coord[1] then
        local coords = {}
        for word in data.coord[1]:gmatch('[^,%s]+') do
            coords[#coords + 1] = tonumber(word)
        end
        if coords[1] and coords[2] then
            SetNewWaypoint(coords[1], coords[2])
            ps.notify('GPS definido para a localização da propriedade', 'success')
        end
    elseif data.x and data.y then
        SetNewWaypoint(data.x, data.y)
        ps.notify('GPS definido para a localização da propriedade', 'success')
    end
    cb('ok')
end)
