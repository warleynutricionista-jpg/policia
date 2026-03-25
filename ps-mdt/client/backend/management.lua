local resourceName = tostring(GetCurrentResourceName())

RegisterNUICallback('getPermissionRoles', function(_, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    local result = ps.callback(resourceName .. ':server:getPermissionRoles')
    ps.debug('[getPermissionRoles] Result:', result)
    cb(result or { success = false, message = 'Falha ao buscar funções' })
end)

RegisterNUICallback('updatePermissionRole', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    local result = ps.callback(resourceName .. ':server:updatePermissionRole', data or {})
    cb(result or { success = false, message = 'Falha ao atualizar a função' })
end)

-- SETTINGS: Activity Tracking -------------------------------------------

RegisterNUICallback('getAuditTrackingConfig', function(_, cb)
    if not MDTOpen then
        cb({})
        return
    end

    local result = ps.callback(resourceName .. ':server:getAuditTrackingConfig')
    -- Server returns JSON string to preserve boolean false values through msgpack
    if type(result) == 'string' then
        local ok, decoded = pcall(json.decode, result)
        if ok then
            cb(decoded)
            return
        end
    end
    cb(result or {})
end)

RegisterNUICallback('saveAuditTrackingConfig', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    -- Encode as JSON string to preserve boolean false values through msgpack serialization
    local result = ps.callback(resourceName .. ':server:saveAuditTrackingConfig', json.encode(data or {}))
    cb(result or { success = false, message = 'Falha ao salvar as configurações' })
end)

-- SETTINGS: Jail / Fines -------------------------------------------

RegisterNUICallback('getJailFinesConfig', function(_, cb)
    if not MDTOpen then
        cb({})
        return
    end

    local result = ps.callback(resourceName .. ':server:getJailFinesConfig')
    cb(result or {})
end)

RegisterNUICallback('saveJailFinesConfig', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    local result = ps.callback(resourceName .. ':server:saveJailFinesConfig', data or {})
    cb(result or { success = false, message = 'Falha ao salvar as configurações' })
end)

-- SETTINGS: Report Templates -------------------------------------------

RegisterNUICallback('getReportTemplates', function(data, cb)
    if not MDTOpen then
        cb({})
        return
    end

    local jobType = (type(data) == 'table' and data.jobType) or nil
    local result = ps.callback(resourceName .. ':server:getReportTemplates', { jobType = jobType })
    cb(result or {})
end)

RegisterNUICallback('saveReportTemplate', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    local result = ps.callback(resourceName .. ':server:saveReportTemplate', data or {})
    cb(result or { success = false, message = 'Falha ao salvar o modelo' })
end)

RegisterNUICallback('deleteReportTemplate', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    local result = ps.callback(resourceName .. ':server:deleteReportTemplate', data or {})
    cb(result or { success = false, message = 'Falha ao excluir o modelo' })
end)

-- TAG MANAGEMENT -------------------------------------------

RegisterNUICallback('getTags', function(data, cb)
    if not MDTOpen then
        cb({})
        return
    end
    local jobType = (type(data) == 'table' and data.jobType) or nil
    local result = ps.callback(resourceName .. ':server:getTags', { jobType = jobType })
    cb(result or {})
end)

RegisterNUICallback('createTag', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end
    local result = ps.callback(resourceName .. ':server:createTag', data or {})
    cb(result or { success = false, message = 'Falha ao criar a tag' })
end)

RegisterNUICallback('updateTag', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end
    local result = ps.callback(resourceName .. ':server:updateTag', data or {})
    cb(result or { success = false, message = 'Falha ao atualizar a tag' })
end)

RegisterNUICallback('deleteTag', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end
    local result = ps.callback(resourceName .. ':server:deleteTag', data or {})
    cb(result or { success = false, message = 'Falha ao excluir a tag' })
end)

-- SETTINGS: Awards -------------------------------------------

RegisterNUICallback('getAwardConfigs', function(_, cb)
    if not MDTOpen then
        cb({})
        return
    end
    local result = ps.callback(resourceName .. ':server:getAwardConfigs')
    cb(result or {})
end)

RegisterNUICallback('saveAward', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end
    local result = ps.callback(resourceName .. ':server:saveAward', data or {})
    cb(result or { success = false, message = 'Falha ao salvar a premiação' })
end)

RegisterNUICallback('deleteAward', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end
    local result = ps.callback(resourceName .. ':server:deleteAward', data or {})
    cb(result or { success = false, message = 'Falha ao excluir a premiação' })
end)

-- AWARDS PAGE: Get awards data (stats + progress + leaderboard) ---

RegisterNUICallback('getAwardsData', function(data, cb)
    if not MDTOpen then
        cb({
            success = false,
            stats = { totalMeses = 0, totalMultado = 0, totalMonths = 0, totalFined = 0 },
            awards = {},
            officer = nil,
            leaderboard = {}
        })
        return
    end
    local result = ps.callback(resourceName .. ':server:getAwardsData', data or {})
    cb(result or {
        success = false,
        stats = { totalMeses = 0, totalMultado = 0, totalMonths = 0, totalFined = 0 },
        awards = {},
        officer = nil,
        leaderboard = {}
    })
end)

-- SETTINGS: Custom Licenses -------------------------------------------

RegisterNUICallback('getCustomLicenses', function(_, cb)
    if not MDTOpen then
        cb({})
        return
    end
    local result = ps.callback(resourceName .. ':server:getCustomLicenses')
    cb(result or {})
end)

RegisterNUICallback('saveCustomLicense', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end
    local result = ps.callback(resourceName .. ':server:saveCustomLicense', data or {})
    cb(result or { success = false, message = 'Falha ao salvar a licença' })
end)

RegisterNUICallback('deleteCustomLicense', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end
    local result = ps.callback(resourceName .. ':server:deleteCustomLicense', data or {})
    cb(result or { success = false, message = 'Falha ao excluir a licença' })
end)
