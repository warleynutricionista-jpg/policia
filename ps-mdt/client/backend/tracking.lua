local resourceName = tostring(GetCurrentResourceName())

RegisterNUICallback('getTracking', function(_, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto', data = {} })
        return
    end

    local tracking = ps.callback(resourceName .. ':server:getTracking')
    if tracking then
        cb({ success = true, data = tracking })
    else
        cb({ success = false, message = 'Falha ao buscar dados de rastreamento', data = {} })
    end
end)
