local resourceName = GetCurrentResourceName()

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
