local isOpen = false

local function openPanel()
    local bootstrap = lib.callback.await('ps-judiciary:server:getBootstrap', false)
    if not bootstrap or not bootstrap.success then
        lib.notify({
            title = 'Tribunal',
            description = bootstrap and bootstrap.error or 'Falha ao abrir painel jurídico.',
            type = 'error'
        })
        return
    end

    SetNuiFocus(true, true)
    isOpen = true
    SendNUIMessage({
        action = 'open',
        payload = bootstrap,
    })
end

local function closePanel()
    SetNuiFocus(false, false)
    isOpen = false
    SendNUIMessage({ action = 'close' })
end

if Config.EnableCommandOpen then
    RegisterCommand(Config.Command or 'tribunal', function()
        if isOpen then
            closePanel()
        else
            openPanel()
        end
    end, false)

    if Config.OpenKeybind then
        RegisterKeyMapping(Config.Command or 'tribunal', 'Abrir Painel Jurídico', 'keyboard', Config.OpenKeybind)
    end
end

RegisterNetEvent('ps-judiciary:client:openFromTablet', function()
    openPanel()
end)

exports('useJudiciaryTablet', function()
    openPanel()
end)

RegisterNUICallback('close', function(_, cb)
    closePanel()
    cb({ ok = true })
end)

RegisterNUICallback('refresh', function(_, cb)
    local bootstrap = lib.callback.await('ps-judiciary:server:getBootstrap', false)
    cb(bootstrap or { success = false, error = 'refresh_failed' })
end)

RegisterNUICallback('updateSettings', function(data, cb)
    local result = lib.callback.await('ps-judiciary:server:updateSettings', false, data)
    cb(result or { success = false, error = 'update_failed' })
end)

RegisterNUICallback('createProcess', function(data, cb)
    local result = lib.callback.await('ps-judiciary:server:createProcess', false, data)
    cb(result or { success = false, error = 'create_failed' })
end)

RegisterNUICallback('getProcess', function(data, cb)
    local result = lib.callback.await('ps-judiciary:server:getProcess', false, data and data.processId)
    cb(result or { success = false, error = 'get_failed' })
end)

RegisterNUICallback('addEvent', function(data, cb)
    local result = lib.callback.await('ps-judiciary:server:addEvent', false, data)
    cb(result or { success = false, error = 'event_failed' })
end)

RegisterNUICallback('addDefenseNote', function(data, cb)
    local result = lib.callback.await('ps-judiciary:server:addDefenseNote', false, data)
    cb(result or { success = false, error = 'defense_failed' })
end)

RegisterNUICallback('reviewIntake', function(data, cb)
    local result = lib.callback.await('ps-judiciary:server:reviewIntake', false, data)
    cb(result or { success = false, error = 'review_failed' })
end)

RegisterNUICallback('finalizeJudgment', function(data, cb)
    local result = lib.callback.await('ps-judiciary:server:finalizeJudgment', false, data)
    cb(result or { success = false, error = 'judgment_failed' })
end)

RegisterNUICallback('scheduleDirectPrison', function(data, cb)
    local result = lib.callback.await('ps-judiciary:server:scheduleDirectPrison', false, data)
    cb(result or { success = false, error = 'direct_prison_failed' })
end)
