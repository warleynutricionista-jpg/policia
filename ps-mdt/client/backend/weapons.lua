local resourceName = tostring(GetCurrentResourceName())

RegisterNUICallback('getWeapons', function(data, cb)
    if not MDTOpen then cb({}) return end
    local weaponList = ps.callback('ps-mdt:server:getWeapons')
    ps.debug('getWeapons', weaponList)
    cb(weaponList)
end)

RegisterNUICallback('getWeaponBolos', function(data, cb)
    if not MDTOpen then cb({}) return end
    local result = ps.callback(resourceName..':server:getBOLO', 'weapon')
    ps.debug('[getWeaponBolos] Fetched weapon BOLOs:', result)
    cb(result)
end)

RegisterNUICallback('getWeaponOwnershipHistory', function(data, cb)
    if not MDTOpen then cb({}) return end
    if not data or not data.serial then
        cb({})
        return
    end

    local result = ps.callback(resourceName .. ':server:getWeaponOwnershipHistory', data.serial)
    cb(result or {})
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
