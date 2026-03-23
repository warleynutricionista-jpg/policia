-- @pickle_prisons/modules/stores/client.lua

local StorePeds    = {}
local StoreTargets = {}
local Threads      = {}

-- Proteção se o config ainda não carregou
Config = Config or {}

local UsingTarget = (Config.UseTarget == true)

-- Detecta qual target usar (mesma lógica do seu config)
local Target = Config.Target or (
    (GetResourceState and (GetResourceState('ox_target') == 'started' and 'ox_target'
    or GetResourceState('qb-target') == 'started' and 'qb-target'
    or GetResourceState('qtarget')    == 'started' and 'qtarget')) or 'ox_target'
)

-- Controle de reentrância / idempotência
local SpawnBusy = false
local CurrentPrisonForStores = nil
local SpawnedOnce = false

-- ========= utils =========
local function requestModel(hash)
    if type(hash) == "string" then hash = joaat(hash) end
    RequestModel(hash)
    local timeout = GetGameTimer() + 30000
    while not HasModelLoaded(hash) do
        Wait(0)
        if GetGameTimer() > timeout then
            error(("Falha ao carregar modelo '%s'"):format(hash))
        end
    end
    return hash
end

-- Busca Z “seguro” sem jogar o ped pra debaixo da terra
local function computeSafeZ(x, y, zHint, zOffset)
    local z = zHint + (zOffset or 0.0)

    local ok, groundZ = GetGroundZFor_3dCoord(x, y, z + 2.0, false)
    if ok then
        local gz = groundZ + (zOffset or 0.0)
        if math.abs(gz - z) <= 2.0 then
            return gz
        end
    end

    local handle = StartShapeTestRay(x, y, z + 10.0, x, y, z - 10.0, 1, -1, 7)
    local _, hit, _, endCoords = GetShapeTestResult(handle)
    if hit == 1 then
        local rz = endCoords.z + (zOffset or 0.0)
        if math.abs(rz - z) <= 2.0 then
            return rz
        end
    end

    return z
end

local function makePedInvincible(ped)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanBeTargetted(ped, false)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 5, false)
    FreezeEntityPosition(ped, true)
end

local function destroyStoreTarget(idx)
    local t = StoreTargets[idx]
    if not t then return end
    if Target == 'ox_target' and t.ox then
        exports.ox_target:removeLocalEntity(t.oxEntity)
    end
    StoreTargets[idx] = nil
end

local function deleteStorePed(idx)
    local ped = StorePeds[idx]
    if ped and DoesEntityExist(ped) then
        DeleteEntity(ped)
    end
    StorePeds[idx] = nil
end

local function cleanupThread(idx)
    if Threads[idx] then
        TerminateThread(Threads[idx])
        Threads[idx] = nil
    end
end

-- ========= labels / UI =========
local function GetItemLabelFromBase(itemName)
    if exports.ox_inventory and exports.ox_inventory.Items then
        local itm = exports.ox_inventory:Items(itemName)
        if itm and itm.label then return itm.label end
    end
    if QBCore and QBCore.Shared and QBCore.Shared.Items and QBCore.Shared.Items[itemName] then
        return QBCore.Shared.Items[itemName].label
    end
    return itemName
end

local function BuildReqText(store, item)
    local parts, cash = {}, 0
    if item.required then
        for _, req in ipairs(item.required) do
            if req.type == "item" and req.name then
                local lbl = GetItemLabelFromBase(req.name)
                parts[#parts+1] = (("%s x%d"):format(lbl, req.amount or 1))
            elseif req.type == "cash" then
                cash = cash + (req.amount or 0)
            end
        end
    end

    local lines = {}
    if store.ui and store.ui.showCashAsValue and cash > 0 then
        lines[#lines+1] = ("Valor: $%d"):format(cash)
    end
    if #parts > 0 then
        lines[#lines+1] = "Requisitos: " .. table.concat(parts, " + ")
    end
    return table.concat(lines, "\n")
end

local function DisplayStore(prisonIndex, storeIndex)
    local prison = Config.Prisons[prisonIndex]
    if not prison or not prison.stores or not prison.stores[storeIndex] then return end
    local store = prison.stores[storeIndex]

    local options = {}
    if store.catalog and #store.catalog > 0 then
        for i, item in ipairs(store.catalog) do
            local titleLabel = item.label or GetItemLabelFromBase(item.name)
            local title      = ("%s x%d"):format(titleLabel, item.amount or 1)
            local desc       = item.description or ""
            local reqText    = BuildReqText(store, item)
            if reqText ~= "" then
                desc = (desc ~= "" and (desc .. "\n" .. reqText)) or reqText
            end

            options[#options+1] = {
                title       = title,
                description = desc,
                icon        = "fa-solid fa-cart-shopping",
                onSelect    = function()
                    TriggerServerEvent("pickle_prisons:buyStoreItem", prisonIndex, storeIndex, i)
                end
            }
        end
    else
        options[#options+1] = { title = "Sem itens", disabled = true }
    end

    lib.registerContext({
        id = ("prison_store_%s_%s"):format(prisonIndex, storeIndex),
        title = store.label or "Loja",
        options = options
    })
    lib.showContext(("prison_store_%s_%s"):format(prisonIndex, storeIndex))
end

-- ========= alvo/tecla =========
local function addTargetForPed(idx, ped, prisonIndex, storeIndex)
    destroyStoreTarget(idx)

    if not UsingTarget then
        Threads[idx] = CreateThread(function()
            local store = Config.Prisons[prisonIndex].stores[storeIndex]
            local label = store.label or "Loja"
            while DoesEntityExist(ped) do
                local p = PlayerPedId()
                local pcoords = GetEntityCoords(p)
                local pedc = GetEntityCoords(ped)
                local dist = #(pcoords - pedc)
                if dist < (Config.InteractDistance or 2.0) then
                    SetTextCentre(true)
                    SetTextScale(0.0, 0.28)
                    SetTextEntry("STRING")
                    AddTextComponentString(("~y~E~s~ - %s"):format(label))
                    DrawText(0.5, 0.88)
                    if IsControlJustPressed(0, 38) then
                        DisplayStore(prisonIndex, storeIndex)
                    end
                end
                Wait(0)
            end
        end)
        return
    end

    if Target == 'ox_target' then
        exports.ox_target:addLocalEntity(ped, {
            {
                icon = 'fa-solid fa-cart-shopping',
                label = (Config.Language == 'pt-br') and 'Abrir loja' or 'Open Store',
                distance = Config.InteractDistance or 2.0,
                onSelect = function() DisplayStore(prisonIndex, storeIndex) end
            }
        })
        StoreTargets[idx] = { ox = true, oxEntity = ped }
    elseif Target == 'qb-target' or Target == 'qtarget' then
        exports[Target]:AddTargetEntity(ped, {
            options = {
                { icon = 'fa-solid fa-cart-shopping',
                  label = (Config.Language == 'pt-br') and 'Abrir loja' or 'Open Store',
                  action = function() DisplayStore(prisonIndex, storeIndex) end }
            },
            distance = Config.InteractDistance or 2.0
        })
        StoreTargets[idx] = { qb = true, qbEntity = ped }
    end
end

-- ========= spawn/despawn =========
local function spawnStorePed(prisonIndex, storeIndex)
    local prison = Config.Prisons[prisonIndex]
    if not prison or not prison.stores then return end
    local store = prison.stores[storeIndex]
    if not store or not store.model or not store.model.hash then return end

    -- Se já existe ped registrado, não duplica
    if StorePeds[storeIndex] and DoesEntityExist(StorePeds[storeIndex]) then
        return
    end

    local hash  = requestModel(store.model.hash)
    local x,y,z = store.coords.x, store.coords.y, store.coords.z
    local zOff  = store.zOffset or 0.0
    local safeZ = computeSafeZ(x, y, z, zOff)

    local ped = CreatePed(4, hash, x, y, safeZ, store.heading or 0.0, false, true)
    makePedInvincible(ped)
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)

    StorePeds[storeIndex] = ped
    addTargetForPed(storeIndex, ped, prisonIndex, storeIndex)
end

local function despawnAllStores()
    for i, _ in pairs(StorePeds) do
        destroyStoreTarget(i)
        cleanupThread(i)
        deleteStorePed(i)
    end
    StorePeds = {}
end

-- ========= eventos =========
RegisterNetEvent("pickle_prisons:enterPrison", function()
    local index  = (Prison and Prison.index) or "default"
    local prison = Config.Prisons[index]
    if not prison or not prison.stores then return end

    -- evita reentrância / chamadas múltiplas
    if SpawnBusy then return end
    SpawnBusy = true

    -- se já estamos no mesmo presídio e já spawnou, não refazer
    if SpawnedOnce and CurrentPrisonForStores == index then
        SpawnBusy = false
        return
    end

    despawnAllStores()
    for i = 1, #prison.stores do
        spawnStorePed(index, i)
    end

    CurrentPrisonForStores = index
    SpawnedOnce = true
    SpawnBusy = false
end)

RegisterNetEvent("pickle_prisons:leavePrison", function()
    despawnAllStores()
    CurrentPrisonForStores = nil
    SpawnedOnce = false
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    despawnAllStores()
end)

-- Removida a thread que forçava spawn automático para evitar duplicação.
