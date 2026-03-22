local resourceName = tostring(GetCurrentResourceName())

RegisterNUICallback('deleteICU', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    if type(data) ~= 'table' or not data.id then
        cb({ success = false, message = 'Faltando ID do registro de UTI' })
        return
    end

    local result = ps.callback(resourceName .. ':server:deleteICU', data)
    cb(result or { success = false, message = 'Falha ao excluir o registro de UTI' })
end)
