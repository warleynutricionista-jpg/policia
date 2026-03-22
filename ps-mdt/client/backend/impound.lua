-- Impound NUI callbacks - bridge between Svelte UI and server

local resourceName = tostring(GetCurrentResourceName())

RegisterNUICallback('impoundVehicle', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    if type(data) ~= 'table' or not data.plate then
        cb({ success = false, message = 'Faltando número da placa' })
        return
    end

    local result = ps.callback(resourceName .. ':server:impoundVehicle', data)
    cb(result or { success = false, message = 'Falha ao apreender o veículo' })
end)

RegisterNUICallback('releaseImpound', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    if type(data) ~= 'table' or not data.plate then
        cb({ success = false, message = 'Faltando número da placa' })
        return
    end

    local result = ps.callback(resourceName .. ':server:releaseImpound', data)
    cb(result or { success = false, message = 'Falha ao liberar o veículo' })
end)

RegisterNUICallback('getImpoundStatus', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    if type(data) ~= 'table' or not data.plate then
        cb({ success = false, message = 'Faltando número da placa' })
        return
    end

    local result = ps.callback(resourceName .. ':server:getImpoundStatus', data)
    cb(result or { success = false })
end)
