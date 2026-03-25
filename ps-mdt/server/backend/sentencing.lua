local resourceName = tostring(GetCurrentResourceName())

local function getCoreObject()
    local okQbx, qbx = pcall(function() return exports['qbx_core']:GetCoreObject() end)
    if okQbx and qbx then return qbx end

    local okQb, qb = pcall(function() return exports['qb-core']:GetCoreObject() end)
    if okQb and qb then return qb end

    return nil
end

local QBCore = getCoreObject()

ps.registerCallback(resourceName .. ':server:sendToJail', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end

    payload = payload or {}
    local citizenId = payload.citizenId
    local sentence = tonumber(payload.sentence)
    local fine = tonumber(payload.fine) or 0
    local charges = payload.charges or {}

    if not citizenId or not sentence or sentence <= 0 then
        return { success = false, message = 'Faltando ID do cidadão ou sentença inválida' }
    end

    -- Cap sentence to prevent abuse
    local maxSentence = 9999
    if sentence > maxSentence then
        sentence = maxSentence
    end

    local targetPlayer = ps.getPlayerByIdentifier(citizenId)
    if not targetPlayer then
        return { success = false, message = 'O jogador precisa estar online para ser enviado à prisão' }
    end

    local targetSource = targetPlayer.source or targetPlayer.PlayerData.source

    -- Trigger mugshot before jailing
    if Config.UseCQCMugshot then
        TriggerClientEvent(resourceName .. ':client:triggerMugshot', targetSource)
        Wait(5000)
    end

    local prisonResource = 'pickle_prisons'
    if GetResourceState(prisonResource) ~= 'started' then
        return { success = false, message = 'pickle_prisons não está iniciado' }
    end

    local okJail, jailError = pcall(function()
        exports[prisonResource]:JailPlayer(targetSource, sentence, 'default')
    end)

    if not okJail then
        return { success = false, message = ('Falha ao enviar para o pickle_prisons: %s'):format(tostring(jailError)) }
    end

    -- Process fine if applicable
    if fine > 0 and QBCore then
        local Player = QBCore.Functions.GetPlayerByCitizenId(citizenId)
        if Player then
            Player.Functions.RemoveMoney('bank', fine, 'mdt-fine-' .. (payload.reportId or 'unknown'))
            ps.debug('Processed fine of $' .. fine .. ' for citizen: ' .. citizenId)
        end
    end

    if ps.auditLog then
        ps.auditLog(src, 'sent_to_jail', 'citizen', citizenId, {
            sentence = sentence,
            fine = fine,
            charges = #charges,
        })
    end

    return { success = true, message = 'Enviado para a prisão por ' .. sentence .. ' meses' .. (fine > 0 and ' | Multa: $' .. fine or '') }
end)

-- Give Citation Item (QBox compatible with ox_inventory)
local function giveCitationItem(src, citizenId, fine, reportId)
    if not QBCore then return false end
    local Player = QBCore.Functions.GetPlayerByCitizenId(citizenId)
    if not Player then return false end

    local Officer = QBCore.Functions.GetPlayer(src)
    if not Officer then return false end

    local PlayerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    local OfficerFullName = '(' .. (Officer.PlayerData.metadata.callsign or '000') .. ') ' .. Officer.PlayerData.charinfo.firstname .. ' ' .. Officer.PlayerData.charinfo.lastname
    local date = os.date('%d/%m/%Y %H:%M')

    local info = {
        citizenId = citizenId,
        fine = '$' .. fine,
        date = date,
        incidentId = '#' .. (reportId or 'N/A'),
        officer = OfficerFullName,
    }

    -- Try ox_inventory first (QBox default), then fallback to qb-inventory
    local success = false

    if GetResourceState('ox_inventory') == 'started' then
        success = pcall(function()
            exports['ox_inventory']:AddItem(Player.PlayerData.source, 'mdtcitation', 1, info)
        end)
    end

    if not success then
        success = pcall(function()
            Player.Functions.AddItem('mdtcitation', 1, false, info)
        end)

        if success then
            TriggerClientEvent('inventory:client:ItemBox', Player.PlayerData.source, QBCore.Shared.Items['mdtcitation'], 'add')
        end
    end

    if success then
        ps.notify(src, PlayerName .. ' (' .. citizenId .. ') recebeu uma citação!', 'success')
    end

    return success
end

ps.registerCallback(resourceName .. ':server:giveCitation', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end

    payload = payload or {}
    local citizenId = payload.citizenId
    local fine = tonumber(payload.fine) or 0
    local reportId = payload.reportId

    if not citizenId then
        return { success = false, message = 'Faltando ID do cidadão' }
    end

    local result = giveCitationItem(src, citizenId, fine, reportId)
    return { success = result, message = result and 'Citação aplicada com sucesso' or 'Falha ao aplicar citação' }
end)
