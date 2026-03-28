local resourceName = GetCurrentResourceName()
local itemUseCooldown = {}

local function getActionConfig(action)
    local defaults = ForensicItemActions and ForensicItemActions[action] or nil
    local override = Config.ItemActions and Config.ItemActions[action] or nil
    if not defaults and not override then return nil end

    local merged = {
        required = {},
        consume = {},
        optionalConsume = {},
    }

    if defaults then
        merged.required = defaults.required or {}
        merged.consume = defaults.consume or {}
        merged.optionalConsume = defaults.optionalConsume or {}
    end

    if override then
        merged.required = override.required or merged.required
        merged.consume = override.consume or merged.consume
        merged.optionalConsume = override.optionalConsume or merged.optionalConsume
    end

    return merged
end

local function getItemCount(src, itemName)
    if GetResourceState('ox_inventory') ~= 'started' then return 999 end
    local ok, count = pcall(function()
        return exports.ox_inventory:Search(src, 'count', itemName)
    end)
    if ok and count then return tonumber(count) or 0 end
    return exports.ox_inventory:GetItemCount(src, itemName) or 0
end

local function hasItem(src, itemName, amount)
    return getItemCount(src, itemName) >= (amount or 1)
end

local function removeItem(src, itemName, amount)
    if GetResourceState('ox_inventory') ~= 'started' then return true end
    amount = tonumber(amount) or 1
    if amount <= 0 then return true end
    return exports.ox_inventory:RemoveItem(src, itemName, amount) and true or false
end

function ValidateAndConsumeForensicAction(src, action, opts)
    opts = opts or {}
    local actionCfg = getActionConfig(action)
    if not actionCfg then
        return { success = true, usedItems = {} }
    end

    local missing = {}
    for _, item in ipairs(actionCfg.required or {}) do
        if not hasItem(src, item, 1) then
            missing[#missing + 1] = item
        end
    end

    if #missing > 0 then
        return {
            success = false,
            error = ('Itens obrigatórios ausentes: %s'):format(table.concat(missing, ', ')),
            missing = missing,
        }
    end

    local consumed = {}
    local dryRun = opts.dryRun == true
    local consumeCfg = actionCfg.consume or {}
    for item, amount in pairs(consumeCfg) do
        local shouldConsume = true
        if Config.ItemConsumption and Config.ItemConsumption[action] and Config.ItemConsumption[action][item] == false then
            shouldConsume = false
        end
        if shouldConsume and not dryRun then
            if not removeItem(src, item, amount) then
                return { success = false, error = ('Falha ao consumir item: %s'):format(item) }
            end
        end
        if shouldConsume then consumed[#consumed + 1] = { item = item, amount = amount } end
    end

    for item, amount in pairs(actionCfg.optionalConsume or {}) do
        if hasItem(src, item, amount) then
            local enabled = Config.OptionalItemConsumption and Config.OptionalItemConsumption[action]
            if enabled == true and (dryRun or removeItem(src, item, amount)) then
                consumed[#consumed + 1] = { item = item, amount = amount }
            end
        end
    end

    return { success = true, usedItems = consumed }
end

lib.callback.register(resourceName .. ':server:validateActionItems', function(source, action)
    if not CheckForensicAuth(source) then
        return { success = false, error = L('scene.errors.not_authorized') }
    end
    return ValidateAndConsumeForensicAction(source, action, { dryRun = true })
end)

RegisterNetEvent(resourceName .. ':server:itemUsed', function(itemName, slot)
    local src = source
    if not src or not itemName then return end

    ForensicAuditLog(src, 'forensic_item_used', 'item', 0, {
        item = itemName,
        slot = slot,
    })
end)

lib.callback.register(resourceName .. ':server:executeItemUse', function(source, payload)
    local src = source
    if not CheckForensicAuth(src) then
        return { success = false, error = L('scene.errors.not_authorized') }
    end
    if type(payload) ~= 'table' then
        return { success = false, error = 'Payload inválido' }
    end

    local now = GetGameTimer()
    if itemUseCooldown[src] and (now - itemUseCooldown[src]) < 700 then
        return { success = false, error = 'Aguarde um instante para reutilizar item forense.' }
    end
    itemUseCooldown[src] = now

    local itemName = tostring(payload.itemName or '')
    local usageCfg = ForensicItemUsageMap and ForensicItemUsageMap[itemName] or nil
    if not usageCfg then
        return { success = false, error = 'Item sem ação forense configurada.' }
    end

    local action = payload.action or usageCfg.action
    local validation = ValidateAndConsumeForensicAction(src, action)
    if not validation.success then
        return { success = false, error = validation.error }
    end

    local evId = payload.evidenceId and tostring(payload.evidenceId) or nil
    local evData = evId and type(GetWorldEvidenceById) == 'function' and GetWorldEvidenceById(evId) or nil
    if usageCfg.requiresTarget and not evData then
        return { success = false, error = 'Nenhuma evidência válida próxima.' }
    end
    if usageCfg.allowedTypes and evData and not usageCfg.allowedTypes[evData.type] then
        return { success = false, error = ('%s não é compatível com este vestígio.'):format(itemName) }
    end

    local markerCreated = false
    if usageCfg.effect == 'reveal' and evId and type(UpdateWorldEvidenceById) == 'function' then
        UpdateWorldEvidenceById(evId, { revealed = true, revealedBy = src, revealedAt = os.time() })
    elseif usageCfg.effect == 'place_marker' and type(SpawnManualWorldEvidence) == 'function' then
        local playerPed = GetPlayerPed(src)
        if not playerPed or playerPed == 0 or not DoesEntityExist(playerPed) then
            return { success = false, error = 'Ped do jogador não está disponível para posicionar marcador.' }
        end
        local pcoords = GetEntityCoords(playerPed)
        SpawnManualWorldEvidence(src, {
            type = 'marcador_cena',
            category = 'outros',
            coords = { x = pcoords.x, y = pcoords.y, z = pcoords.z - 1.0 },
            location = '',
            source_type = 'manual_marker',
            revealed = true,
        })
        markerCreated = true
    end

    ForensicAuditLog(src, 'forensic_item_action_executed', 'item', 0, {
        item = itemName,
        action = action,
        effect = usageCfg.effect or 'none',
        evidence = evId,
    })

    return { success = true, markerCreated = markerCreated, usedItems = validation.usedItems }
end)
