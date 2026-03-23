-- modules/activities/client.lua
-- Correção: todos os NPCs aparecem acima do piso (offset manual) + flip 180° nos NPCs de início.
-- Base original preservada (mesmas funções públicas).

local ActivityStatus
local ActivityInteraction
local ActivityStartInteractions = {}
local ActivityEntities = {}

----------------------------------------------------------------
-- Ajustes globais
----------------------------------------------------------------
-- Altura padrão pra levantar o ped acima do Z configurado (ajuste conforme o MLO)
local LOCAL_Z_OFFSET = 0.60  -- 0.60 ~ 0.80 costuma resolver

local function _dbg(...)
    if Config and Config.Debug then
        print("^3[pickle_prisons:activities]^7", ...)
    end
end

-- retorna offset local respeitando override em activity/section
local function ResolveZOffset(sectionOrActivity)
    if sectionOrActivity and sectionOrActivity.zOffset then
        return tonumber(sectionOrActivity.zOffset) or LOCAL_Z_OFFSET
    end
    return LOCAL_Z_OFFSET
end

local function FlipHeading(h)
    h = (h or 0.0) + 180.0
    while h >= 360.0 do h = h - 360.0 end
    while h < 0.0  do h = h + 360.0 end
    return h
end

-- Acha ped pelo modelo perto das coords
local function FindClosestPedOfModel(modelHash, at, maxDist)
    if not modelHash or not at then return nil end
    maxDist = maxDist or 6.0
    local handle, ped = FindFirstPed()
    local success
    local best, bestDist
    repeat
        if DoesEntityExist(ped) and not IsPedAPlayer(ped) then
            if GetEntityModel(ped) == modelHash then
                local d = #(GetEntityCoords(ped, false) - at)
                if d <= maxDist and (not best or d < bestDist) then
                    best, bestDist = ped, d
                end
            end
        end
        success, ped = FindNextPed(handle)
    until not success
    EndFindPed(handle)
    return best
end

-- Reposiciona com offset e (opcional) vira 180°
local function RepositionPedWithOffset(ped, coords, heading, zOff, doFlip)
    if not ped or not DoesEntityExist(ped) or not coords then return end

    local newHeading = heading or GetEntityHeading(ped)
    if doFlip then newHeading = FlipHeading(newHeading) end

    -- aplicamos por alguns frames pra vencer cenários que “puxam” o ped
    for i = 1, 20 do
        FreezeEntityPosition(ped, false)
        SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z + zOff, false, false, true)
        SetEntityHeading(ped, newHeading)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetEntityInvincible(ped, true)
        FreezeEntityPosition(ped, true)
        Wait(0)
    end
end

-- Tenta localizar o ped recém criado pelo CreateInteraction e aplicar as correções
-- flip = true para NPCs de INÍCIO (queremos que olhem o lado oposto)
local function FixInteractionPed(modelField, coords, heading, zOff, flip)
    if not modelField or not (modelField.hash) or not coords then return end
    local mhash = modelField.hash
    CreateThread(function()
        -- dá um tempinho pro CreateInteraction spawnar
        local ped
        local t = GetGameTimer() + 2500
        while GetGameTimer() < t do
            ped = FindClosestPedOfModel(mhash, coords, 6.0)
            if ped and DoesEntityExist(ped) then break end
            Wait(100)
        end
        if not ped or not DoesEntityExist(ped) then
            _dbg("Não consegui achar o ped da interação (modelo:", mhash, ")")
            return
        end

        RepositionPedWithOffset(ped, coords, heading, zOff, flip)
    end)
end

----------------------------------------------------------------
-- API pública original
----------------------------------------------------------------
function CleanupActivity()
    if (ActivityInteraction) then 
        DeleteInteraction(ActivityInteraction)
    end
    ActivityInteraction = nil
    for k,v in pairs(ActivityEntities) do
        DeleteActivityEntity(k)
    end
end

function AddActivityEntity(name, object)
    if GetActivityEntity(name) then 
        DeleteActivityEntity(name)
    end
    ActivityEntities[name] = object
end

function GetActivityEntity(name)
    return ActivityEntities[name] 
end

function DeleteActivityEntity(name)
    if ActivityEntities[name] then
        DeleteEntity(ActivityEntities[name])
    end
    ActivityEntities[name] = nil
end

function StartSection(activityIndex, sectionIndex)
    CleanupActivity()
    Wait(250)
    ActivityStatus = { activityIndex = activityIndex, sectionIndex = sectionIndex }

    local index     = Prison.index
    local prison    = Config.Prisons[index]
    local activity  = prison.activities[activityIndex]
    local activityCfg = Config.Activities[activity.name]
    local section   = activity.sections[sectionIndex]
    local sectionCfg= activityCfg.sections[section.name]

    -- Botão "Parar <Atividade>"
    UpdateInteraction(ActivityStartInteractions[activityIndex], {
        label = _L("stop") .. " " .. activityCfg.label,
        options = {}
    }, function()
        TriggerServerEvent("pickle_prisons:stopActivity", index, activityIndex)
    end)

    -- Ponto da seção
    local interact2 = CreateInteraction({
        label   = sectionCfg.label,
        model   = sectionCfg.model,
        coords  = section.coords,
        heading = section.heading
    }, function()
        EnableInteraction = false
        if (sectionCfg.process(section)) then
            ShowNotification(_L("section_success"))
            ServerCallback("pickle_prisons:startNextSection", function(result)
                if (result) then 
                    StartSection(result.activityIndex, result.section)
                end
            end)
        else
            ShowNotification(_L("section_failure"))
        end
        EnableInteraction = true
    end)

    ActivityInteraction = interact2

    -- Correção de altura para o ped da SEÇÃO (sem flip aqui):
    if sectionCfg.model and sectionCfg.model.hash and section.coords then
        local zOff = ResolveZOffset(section)  -- permite zOffset por section
        FixInteractionPed(sectionCfg.model, section.coords, section.heading, zOff, false)
    end

    if Config.NavigationDisplay then
        CreateThread(function()
            while ActivityInteraction == interact2 do 
                local pcoords = GetEntityCoords(PlayerPedId())
                local dist = #(section.coords - pcoords)
                local meters = math.ceil(dist * 1)
                if EnableInteraction then
                    DrawDestination(section.coords, "Activity", meters)
                end
                Wait(0)
            end
        end)
    end
end

function InteractActivity(activityIndex)
    local index    = Prison.index
    local prison   = Config.Prisons[index]
    local activity = prison.activities[activityIndex]
    local activityCfg = Config.Activities[activity.name]
    ServerCallback("pickle_prisons:startActivity", function(result, needStop)
        if not result then return end
        if needStop then 
            CleanupActivity()
            Wait(250)
        end
        StartSection(activityIndex, result.section)
    end, index, activityIndex)
end

RegisterNetEvent("pickle_prisons:stopActivity", function(status)
    ActivityStatus = nil
    CleanupActivity()
    if status then 
        local activity = Config.Prisons[status.index].activities[status.activityIndex]
        local activityCfg = Config.Activities[activity.name]
        if activityCfg then
            UpdateInteraction(ActivityStartInteractions[status.activityIndex], {
                label = _L("start") .. " " .. activityCfg.label,
                options = {}
            }, function()
                InteractActivity(status.activityIndex)
            end)

            -- Volta ped de INÍCIO pra posição correta e 180°
            if activity.model and activity.model.hash and activity.coords then
                local zOff = ResolveZOffset(activity) -- permite zOffset por activity
                FixInteractionPed(activity.model, activity.coords, activity.heading, zOff, true)
            end
        end
    end
end)

RegisterNetEvent("pickle_prisons:enterPrison", function()
    local prison = Config.Prisons[Prison.index]
    CleanupActivity()

    for i=1, #prison.activities do 
        local activity = prison.activities[i]
        local activityCfg = Config.Activities[activity.name]
        if activityCfg then
            ActivityStartInteractions[i] = CreateInteraction({
                label   = _L("start") .. " " .. activityCfg.label,
                model   = activity.model,
                coords  = activity.coords,
                heading = activity.heading
            }, function()
                InteractActivity(i)
            end)

            -- Correção: levanta e gira 180° os NPCs de INÍCIO
            if activity.model and activity.model.hash and activity.coords then
                local zOff = ResolveZOffset(activity)
                FixInteractionPed(activity.model, activity.coords, activity.heading, zOff, true)
            end
        end
    end
end)

RegisterNetEvent("pickle_prisons:leavePrison", function()
    for k,v in pairs(ActivityStartInteractions) do 
        DeleteInteraction(v)
    end
    ActivityStartInteractions = {}
    CleanupActivity()
end)

function DrawDestination(coords, label, meters)
    local _, screenX, screenY = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
    RequestStreamedTextureDict("basejumping", false)
    DrawSprite("basejumping", "arrow_pointer", screenX, screenY - 0.015, 0.015, 0.025, 180.0, 255, 255, 0, 255)
    SetTextCentre(true)
    SetTextScale(0.0, 0.25)
    SetTextEntry("STRING")
    AddTextComponentString(label .. "\n".. meters .. "m")
    DrawText(screenX, screenY)
end
