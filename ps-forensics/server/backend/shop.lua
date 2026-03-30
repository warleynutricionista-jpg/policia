-- ============================================================
-- PS-FORENSICS - Loja Forense (ox_inventory + painel)
-- ============================================================

local resourceName = GetCurrentResourceName()
local shopConfigFile = 'data/forensic_shop.json'

local function toVec3(value)
    if type(value) ~= 'table' then return nil end
    local x = tonumber(value.x)
    local y = tonumber(value.y)
    local z = tonumber(value.z)
    if not x or not y or not z then return nil end
    return vector3(x, y, z)
end

local function serializeCoords(value)
    if type(value) ~= 'vector3' and type(value) ~= 'table' then return nil end
    return {
        x = tonumber(value.x) or 0.0,
        y = tonumber(value.y) or 0.0,
        z = tonumber(value.z) or 0.0,
    }
end

local function normalizeShopForClient(shop)
    if type(shop) ~= 'table' then return nil end
    local out = {}
    for k, v in pairs(shop) do
        out[k] = v
    end

    out.coords = serializeCoords(shop.coords)
    out.radius = tonumber(shop.radius) or 2.0
    out.enabled = shop.enabled ~= false
    return out
end

local function normalizeShopForRuntime(shop)
    if type(shop) ~= 'table' then return nil end
    local out = {}
    for k, v in pairs(shop) do
        out[k] = v
    end

    out.enabled = shop.enabled ~= false
    out.radius = tonumber(shop.radius) or 2.0

    local coords = toVec3(shop.coords)
    if coords then
        out.coords = coords
    end

    return out
end

local function loadPersistedShopConfig()
    local raw = LoadResourceFile(resourceName, shopConfigFile)
    if not raw or raw == '' then return nil end

    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= 'table' then
        print(('[%s] AVISO: arquivo %s inválido, ignorando persistência da loja.'):format(resourceName, shopConfigFile))
        return nil
    end

    return normalizeShopForRuntime(decoded)
end

local function savePersistedShopConfig(shop)
    local serializable = normalizeShopForClient(shop)
    if not serializable then return false end

    local payload = json.encode(serializable)
    return SaveResourceFile(resourceName, shopConfigFile, payload, #payload)
end

local function canManageShop(src)
    if not CheckForensicAuth(src) then return false end
    return CheckForensicPermission(src, 'canFinalizeReport')
end

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

local function registerForensicShop()
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
end

local function applyPersistedShopConfig()
    local persisted = loadPersistedShopConfig()
    if not persisted then return end

    Config.ForensicShop = Config.ForensicShop or {}
    for key, value in pairs(persisted) do
        Config.ForensicShop[key] = value
    end
end

lib.callback.register(resourceName .. ':server:getForensicShopConfig', function(source)
    if not CheckForensicAuth(source) then
        return { success = false, error = L('scene.errors.not_authorized') }
    end

    return {
        success = true,
        data = normalizeShopForClient(Config.ForensicShop or {}),
    }
end)

lib.callback.register(resourceName .. ':server:saveForensicShopPosition', function(source, payload)
    if not canManageShop(source) then
        return { success = false, error = 'Sem permissão para configurar a loja forense.' }
    end

    payload = type(payload) == 'table' and payload or {}
    local coords = toVec3(payload)
    if not coords then
        return { success = false, error = 'Coordenadas inválidas para loja forense.' }
    end

    Config.ForensicShop = Config.ForensicShop or {}
    Config.ForensicShop.enabled = true
    Config.ForensicShop.coords = coords
    Config.ForensicShop.radius = tonumber(Config.ForensicShop.radius) or 2.0

    local persisted = savePersistedShopConfig(Config.ForensicShop)
    if not persisted then
        return { success = false, error = 'Falha ao persistir configuração da loja forense.' }
    end

    local shopData = normalizeShopForClient(Config.ForensicShop)
    TriggerClientEvent(resourceName .. ':client:updateForensicShop', -1, shopData)

    ForensicAuditLog(source, 'forensic_shop_position_updated', 'config', 0, {
        mode = payload.mode or 'move',
        coords = shopData.coords,
    })

    return {
        success = true,
        coords = shopData.coords,
    }
end)

CreateThread(function()
    applyPersistedShopConfig()
    registerForensicShop()
end)
