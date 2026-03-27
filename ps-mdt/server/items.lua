local resourceName = GetCurrentResourceName()

local function getCitationItemName()
    return (Config.CitationItem and Config.CitationItem.Name) or 'mdtcitation'
end

function MdtHasItem(src, itemName, amount)
    if GetResourceState('ox_inventory') ~= 'started' then return true end
    amount = amount or 1
    local ok, count = pcall(function()
        return exports.ox_inventory:Search(src, 'count', itemName)
    end)
    if not ok then
        count = exports.ox_inventory:GetItemCount(src, itemName)
    end
    return (tonumber(count) or 0) >= amount
end

function MdtConsumeItem(src, itemName, amount)
    if GetResourceState('ox_inventory') ~= 'started' then return true end
    return exports.ox_inventory:RemoveItem(src, itemName, amount or 1) and true or false
end

function ValidateCitationIssueItem(src)
    local cfg = Config.CitationItem or {}
    local itemName = getCitationItemName()
    local requireItem = cfg.RequireToIssue ~= false
    local consume = cfg.ConsumeOnIssue ~= false
    local amount = tonumber(cfg.ConsumeAmount) or 1

    if not requireItem then
        return { success = true, itemName = itemName, consumed = false }
    end

    if not MdtHasItem(src, itemName, amount) then
        return {
            success = false,
            error = ('Item obrigatório ausente para emitir citação: %s'):format(itemName),
            itemName = itemName,
        }
    end

    if consume and not MdtConsumeItem(src, itemName, amount) then
        return {
            success = false,
            error = ('Falha ao consumir item de citação: %s'):format(itemName),
            itemName = itemName,
        }
    end

    return { success = true, itemName = itemName, consumed = consume }
end

ps.registerCallback(resourceName .. ':server:validateCitationIssue', function(source)
    if not CheckAuth(source) then
        return { success = false, error = 'Não autorizado' }
    end
    return ValidateCitationIssueItem(source)
end)

