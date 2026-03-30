-- ============================================================
-- PS-FORENSICS - Loja Forense (ox_inventory)
-- ============================================================

local resourceName = GetCurrentResourceName()

local function buildShopInventory(shopConfig)
    local items = {}

    for _, itemName in pairs(Config.Items or {}) do
        if itemName ~= 'forensic_photo' and itemName ~= 'mdtcitation' then
            local price = (shopConfig.prices and shopConfig.prices[itemName]) or 100
            items[#items + 1] = {
                name = itemName,
                price = price,
            }
        end
    end

    table.sort(items, function(a, b)
        return a.name < b.name
    end)

    return items
end

CreateThread(function()
    if GetResourceState('ox_inventory') ~= 'started' then
        print(('[%s] Loja forense não registrada: ox_inventory não iniciado.'):format(resourceName))
        return
    end

    local shopConfig = Config.ForensicShop
    if not shopConfig or not shopConfig.enabled then
        return
    end

    local shopId = shopConfig.id or 'forensics_supply_shop'
    local shopName = shopConfig.label or 'Loja de Materiais Forenses'
    local inventory = buildShopInventory(shopConfig)

    exports.ox_inventory:RegisterShop(shopId, {
        name = shopName,
        inventory = inventory,
    })

    print(('[%s] Loja forense registrada: %s (%d itens).'):format(resourceName, shopId, #inventory))
end)
