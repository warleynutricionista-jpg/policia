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

RegisterNUICallback('prisonTabJail', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    if GetResourceState('pickle_prisons') ~= 'started' then
        cb({ success = false, message = 'pickle_prisons não está em execução' })
        return
    end

    local targetSource = type(data) == 'table' and tonumber(data.source) or nil
    local sentence = type(data) == 'table' and tonumber(data.sentence) or nil

    if not targetSource or not sentence or sentence <= 0 then
        cb({ success = false, message = 'Selecione um alvo e informe um tempo válido' })
        return
    end

    TriggerServerEvent('pickle_prisons:jailPlayer', targetSource, sentence, 'default')
    cb({ success = true, message = 'Ação de prisão enviada ao pickle_prisons' })
end)

RegisterNUICallback('prisonTabUnjail', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    if GetResourceState('pickle_prisons') ~= 'started' then
        cb({ success = false, message = 'pickle_prisons não está em execução' })
        return
    end

    local targetSource = type(data) == 'table' and tonumber(data.source) or nil
    if not targetSource then
        cb({ success = false, message = 'Selecione um preso válido' })
        return
    end

    TriggerServerEvent('pickle_prisons:unjailPlayer', targetSource)
    cb({ success = true, message = 'Ação de soltura enviada ao pickle_prisons' })
end)
