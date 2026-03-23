local resourceName = tostring(GetCurrentResourceName())

RegisterNUICallback('getPrisonConfig', function(_, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    local result = ps.callback(resourceName .. ':server:getPrisonConfig')
    cb(result or { success = false, message = 'Falha ao carregar a configuração da prisão' })
end)

RegisterNUICallback('searchPrisonRecords', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto', data = {} })
        return
    end

    local query = type(data) == 'table' and data.query or ''
    local result = ps.callback(resourceName .. ':server:searchPrisonRecords', query)
    cb(result or { success = false, message = 'Falha ao buscar registros', data = {} })
end)

RegisterNUICallback('getPrisonStatus', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    local result = ps.callback(resourceName .. ':server:getPrisonStatus', data or {})
    cb(result or { success = false, message = 'Falha ao consultar situação da prisão' })
end)

RegisterNUICallback('submitPrisonAction', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    local result = ps.callback(resourceName .. ':server:submitPrisonAction', data or {})
    cb(result or { success = false, message = 'Falha ao executar a ação de prisão' })
end)
