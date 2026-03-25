local resourceName = tostring(GetCurrentResourceName())
local weaponSearchState = {
    lastQuery = '',
    lastAt = 0,
    lastResult = { weapons = {}, bolos = {}, page = 1, limit = 25, total = 0, hasMore = false }
}
local WEAPON_SEARCH_DEBOUNCE_MS = 250

local function handleGetWeapons(data, cb)
    if not MDTOpen then cb({}) return end
    data = data or {}
    local weaponList = ps.callback('ps-mdt:server:getWeapons', { page = data.page or 1, limit = data.limit })
    ps.debug('getWeapons', weaponList)
    cb(weaponList or { weapons = {}, bolos = {}, page = data.page or 1, limit = data.limit or 25, total = 0, hasMore = false })
end

local function handleGetWeaponHistory(data, cb)
    if not MDTOpen then cb({}) return end
    if not data or not data.serial then
        cb({})
        return
    end

    local result = ps.callback(resourceName .. ':server:getWeaponOwnershipHistory', data.serial)
    cb(result or {})
end

RegisterNUICallback('getWeapons', function(data, cb)
    handleGetWeapons(data, cb)
end)

RegisterNUICallback('getArmas', function(data, cb)
    handleGetWeapons(data, cb)
end)

RegisterNUICallback('getWeaponBolos', function(data, cb)
    if not MDTOpen then cb({}) return end
    local result = ps.callback(resourceName..':server:getBOLO', 'weapon')
    ps.debug('[getWeaponBolos] Fetched weapon BOLOs:', result)
    cb(result)
end)

RegisterNUICallback('getWeaponOwnershipHistory', function(data, cb)
    handleGetWeaponHistory(data, cb)
end)

RegisterNUICallback('getArmaProprietárioshipHistory', function(data, cb)
    handleGetWeaponHistory(data, cb)
end)

RegisterNUICallback('getArma', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    local serial = data and (data.serial or data.id)
    if not serial then
        cb({ success = false, message = 'Faltando número de série' })
        return
    end

    local result = ps.callback(resourceName .. ':server:getWeapon', serial)
    cb(result or { success = false, message = 'Arma não encontrada' })
end)

-- Save/Edit Weapon Info
RegisterNUICallback('saveWeaponInfo', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    if type(data) ~= 'table' or not data.serial then
        cb({ success = false, message = 'Faltando número de série' })
        return
    end

    local result = ps.callback(resourceName .. ':server:saveWeaponInfo', data)
    cb(result or { success = false, message = 'Falha ao salvar as informações da arma' })
end)

RegisterNUICallback('updateArma', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    local serial = data and (data.serial or data.id)
    if not serial then
        cb({ success = false, message = 'Faltando número de série' })
        return
    end

    local payload = data or {}
    payload.serial = payload.serial or serial
    local result = ps.callback(resourceName .. ':server:saveWeaponInfo', payload)
    cb(result or { success = false, message = 'Falha ao salvar as informações da arma' })
end)

RegisterNUICallback('searchArmas', function(data, cb)
    if not MDTOpen then
        cb({ weapons = {}, bolos = {} })
        return
    end

    local query = data and data.query or ''
    if query == '' then
        cb({ weapons = {}, bolos = {}, page = 1, limit = data and data.limit or 25, total = 0, hasMore = false })
        return
    end

    local now = GetGameTimer()
    if weaponSearchState.lastQuery == query and (now - weaponSearchState.lastAt) < WEAPON_SEARCH_DEBOUNCE_MS then
        cb(weaponSearchState.lastResult)
        return
    end

    local result = ps.callback(resourceName .. ':server:searchWeapons', {
        query = query,
        page = data and data.page or 1,
        limit = data and data.limit or nil
    })
    weaponSearchState.lastQuery = query
    weaponSearchState.lastAt = now
    weaponSearchState.lastResult = result or { weapons = {}, bolos = {}, page = data and data.page or 1, limit = data and data.limit or 25, total = 0, hasMore = false }
    cb(weaponSearchState.lastResult)
end)

-- Delete Weapon Record
RegisterNUICallback('deleteWeapon', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    if type(data) ~= 'table' or (not data.id and not data.serial) then
        cb({ success = false, message = 'Faltando ID da arma ou série' })
        return
    end

    local result = ps.callback(resourceName .. ':server:deleteWeapon', data)
    cb(result or { success = false, message = 'Falha ao excluir a arma' })
end)

-- Weapon Self-Register (3rd Eye integration)
RegisterNetEvent(resourceName .. ':client:selfregister')
AddEventHandler(resourceName .. ':client:selfregister', function()
    local weaponInfos = ps.callback(resourceName .. ':server:getWeaponInfo')
    if weaponInfos and #weaponInfos > 0 then
        for _, weaponInfo in ipairs(weaponInfos) do
            TriggerServerEvent(resourceName .. ':server:selfRegisterWeapon',
                weaponInfo.serialnumber,
                weaponInfo.weaponurl,
                weaponInfo.notes,
                nil,
                weaponInfo.weapClass,
                weaponInfo.weaponmodel
            )
        end
    else
        ps.notify('Nenhuma arma encontrada para registrar', 'error')
    end
end)
