local resourceName = tostring(GetCurrentResourceName())

-- Send to Jail
RegisterNUICallback('sendToJail', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    if type(data) ~= 'table' or not data.citizenId or not data.sentence then
        cb({ success = false, message = 'Faltando ID do cidadão ou sentença' })
        return
    end

    local result = ps.callback(resourceName .. ':server:sendToJail', data)
    cb(result or { success = false, message = 'Falha ao enviar para a prisão' })
end)

-- Give Citation
RegisterNUICallback('giveCitation', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    if type(data) ~= 'table' or not data.citizenId then
        cb({ success = false, message = 'Faltando ID do cidadão' })
        return
    end

    local result = ps.callback(resourceName .. ':server:giveCitation', data)
    cb(result or { success = false, message = 'Falha ao aplicar a citação' })
end)
