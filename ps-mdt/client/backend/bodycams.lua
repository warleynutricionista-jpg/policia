local resourceName = tostring(GetCurrentResourceName())

-- Events
RegisterNUICallback('viewBodycam', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    ps.debug('viewBodycam', data)

    local bodycamId = data
    if type(data) == 'table' then
        bodycamId = data.id or data.bodycamId or data
    end

    if not bodycamId then
        cb({ success = false, message = 'ID da bodycam inválido' })
        return
    end

    local result = ps.callback(resourceName .. ':server:viewBodycam', bodycamId)

    if result and result.success then
        CloseMDT()
        cb({ success = true })
    else
        cb({ success = false, message = result and result.error or 'Falha ao visualizar a bodycam' })
    end

end)

RegisterNUICallback('getBodycams', function(_, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto', data = {} })
        return
    end

    local bodycams = ps.callback(resourceName .. ':server:getBodycams')

    if bodycams then
        cb({ success = true, data = bodycams })
    else
        cb({ success = false, message = 'Falha ao buscar bodycams', data = {} })
    end
end)
