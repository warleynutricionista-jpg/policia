local resourceName = tostring(GetCurrentResourceName())

RegisterNUICallback('getCharges', function(data, cb)
    if not MDTOpen then cb({}) return end
    local callbacks = ps.callback('ps-mdt:getChargeList', false)
    cb(callbacks)
end)

RegisterNUICallback('processFine', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    if type(data) ~= 'table' or not data.citizenid or not data.fine then
        cb({ success = false, message = 'Faltando ID do cidadão ou valor da multa' })
        return
    end

    local result = ps.callback(resourceName .. ':server:processFine', data)
    cb(result or { success = false, message = 'Falha ao processar a multa' })
end)

RegisterNUICallback('updateCharge', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    if type(data) ~= 'table' or not data.code then
        cb({ success = false, message = 'Faltando código da acusação' })
        return
    end

    local result = ps.callback(resourceName .. ':server:updateCharge', data)
    cb(result or { success = false, message = 'Falha ao atualizar a acusação' })
end)

RegisterNUICallback('addCharge', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    local result = ps.callback(resourceName .. ':server:addCharge', data or {})
    cb(result or { success = false, message = 'Falha ao criar a infração' })
end)

RegisterNUICallback('deleteCharge', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    local result = ps.callback(resourceName .. ':server:deleteCharge', data or {})
    cb(result or { success = false, message = 'Falha ao excluir a infração' })
end)
