-- @pickle_prisons/modules/stores/server.lua

local hasOxInv   = (GetResourceState('ox_inventory') == 'started')
local hasQBCore  = (GetResourceState('qb-core') == 'started')
local QBCore     = hasQBCore and exports['qb-core']:GetCoreObject() or nil

-- Fallback caso config ainda não tenha carregado (ordem dos scripts)
Config = Config or {}
Config.Prisons = Config.Prisons or {}

-- ---------- utils ----------
local function notify(src, ntype, msg)
    if GetResourceState('ox_lib') == 'started' then
        TriggerClientEvent('ox_lib:notify', src, { type = ntype or 'inform', description = msg })
    else
        TriggerClientEvent('chat:addMessage', src, { args = { '^2Loja', msg } })
    end
end

local function getItemCount(src, name)
    if hasOxInv then
        return exports.ox_inventory:GetItemCount(src, name) or 0
    elseif hasQBCore then
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return 0 end
        local it = Player.Functions.GetItemByName(name)
        if not it then return 0 end
        -- QBCore pode retornar tabela ou array, padronizamos:
        return it.amount or it.count or 0
    end
    return 0
end

local function canCarry(src, name, amount)
    amount = amount or 1
    if hasOxInv then
        return exports.ox_inventory:CanCarryItem(src, name, amount)
    end
    -- QBCore geralmente não tem “can carry” nativo; confia no add
    return true
end

local function removeRequirements(src, reqs)
    reqs = reqs or {}
    local Player = hasQBCore and QBCore.Functions.GetPlayer(src) or nil

    -- 1) valida saldo/quantidades antes de remover
    local needCash = 0
    for _, r in ipairs(reqs) do
        if r.type == 'item' then
            local have = getItemCount(src, r.name)
            local need = r.amount or 1
            if have < need then
                return false, ('Faltam %s x%d'):format(r.name, need)
            end
        elseif r.type == 'cash' then
            needCash = needCash + (r.amount or 0)
        end
    end
    if needCash > 0 and hasQBCore and Player then
        if (Player.Functions.GetMoney('cash') or 0) < needCash then
            return false, 'Dinheiro insuficiente.'
        end
    elseif needCash > 0 and hasOxInv then
        if (exports.ox_inventory:GetItemCount(src, 'money') or 0) < needCash then
            return false, 'Dinheiro insuficiente.'
        end
    end

    -- 2) remove requisitos
    for _, r in ipairs(reqs) do
        if r.type == 'item' then
            local ok
            if hasOxInv then
                ok = exports.ox_inventory:RemoveItem(src, r.name, r.amount or 1)
            elseif hasQBCore and Player then
                ok = Player.Functions.RemoveItem(r.name, r.amount or 1)
            end
            if not ok then return false, ('Falha ao remover %s.'):format(r.name) end
        end
    end
    if needCash > 0 then
        if hasOxInv then
            local ok = exports.ox_inventory:RemoveItem(src, 'money', needCash)
            if not ok then return false, 'Falha ao cobrar dinheiro.' end
        elseif hasQBCore and Player then
            local ok = Player.Functions.RemoveMoney('cash', needCash, 'prison-store')
            if not ok then return false, 'Falha ao cobrar dinheiro.' end
        end
    end

    return true
end

local function giveItem(src, name, amount)
    amount = amount or 1
    if not canCarry(src, name, amount) then
        return false, 'Sem espaço no inventário.'
    end

    if hasOxInv then
        local ok = exports.ox_inventory:AddItem(src, name, amount)
        if not ok then return false, 'Falha ao entregar item.' end
        return true
    elseif hasQBCore then
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return false, 'Jogador inválido.' end
        local ok = Player.Functions.AddItem(name, amount)
        if not ok then return false, 'Falha ao entregar item.' end
        -- (Opcional) animação de caixa do inventário do QB
        if QBCore.Shared and QBCore.Shared.Items and QBCore.Shared.Items[name] then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[name], 'add', amount)
        end
        return true
    end

    return false, 'Framework de inventário não detectado.'
end

-- ---------- compra ----------
RegisterNetEvent('pickle_prisons:buyStoreItem', function(prisonIndex, storeIndex, itemIndex)
    local src = source
    local prison = Config.Prisons[prisonIndex]
    if not prison then return notify(src, 'error', 'Prisão inválida.') end

    local store  = prison.stores and prison.stores[storeIndex]
    if not store then return notify(src, 'error', 'Loja inválida.') end

    local item   = store.catalog and store.catalog[itemIndex]
    if not item then return notify(src, 'error', 'Item inválido.') end

    local amount = item.amount or 1
    local ok, err = removeRequirements(src, item.required)
    if not ok then
        return notify(src, 'error', err or 'Requisitos não atendidos.')
    end

    local ok2, err2 = giveItem(src, item.name, amount)
    if not ok2 then
        -- Ideal: reembolsar aqui se quiser (não fazemos rollback automático)
        return notify(src, 'error', err2 or 'Falha ao entregar item.')
    end

    notify(src, 'success', 'Compra concluída!')
end)
