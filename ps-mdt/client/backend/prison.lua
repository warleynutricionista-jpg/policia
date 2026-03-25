local resourceName = tostring(GetCurrentResourceName())

RegisterNUICallback('getPrisonTargets', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto', data = {} })
        return
    end

    local query = type(data) == 'table' and data.query or ''
    cb(ps.callback(resourceName .. ':server:getPrisonTargets', query) or { success = false, message = 'Falha ao buscar jogadores', data = {} })
end)

RegisterNUICallback('getPrisonTargetStatus', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    local targetSource = type(data) == 'table' and data.source or nil
    cb(ps.callback(resourceName .. ':server:getPrisonTargetStatus', targetSource) or { success = false, message = 'Falha ao consultar status' })
end)

RegisterNUICallback('getPrisonStatusByCitizen', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    local citizenid = type(data) == 'table' and data.citizenid or nil
    cb(ps.callback(resourceName .. ':server:getPrisonStatusByCitizen', citizenid) or { success = false, message = 'Falha ao consultar o preso' })
end)

RegisterNUICallback('prisonTabJail', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    cb(ps.callback(resourceName .. ':server:prisonTabJail', data or {}) or { success = false, message = 'Falha ao prender o alvo' })
end)

RegisterNUICallback('prisonTabUnjail', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    cb(ps.callback(resourceName .. ':server:prisonTabUnjail', data or {}) or { success = false, message = 'Falha ao soltar o alvo' })
end)

RegisterNUICallback('prisonFromReport', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    cb(ps.callback(resourceName .. ':server:prisonFromReport', data or {}) or { success = false, message = 'Falha ao prender via relatório' })
end)

RegisterNUICallback('prisonFromWarrant', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    cb(ps.callback(resourceName .. ':server:prisonFromWarrant', data or {}) or { success = false, message = 'Falha ao prender via mandado' })
end)
