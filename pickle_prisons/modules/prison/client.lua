-- modules/prison/client.lua

Prison = nil

PrisonInteractions = {}
PrisonSirens = {}

local CheckBreakout = true
local BreakoutIxs = {}        -- interações da sequência de fuga (start/enter/leave/finish)
local BreakoutActive = false  -- flag: fuga ativa (para não limpar interações do túnel ao sair da prisão)

-- ========= Helpers =========

local function TeleportPedSafe(ped, coords, heading)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end

    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    if heading then SetEntityHeading(ped, heading + 0.0) end

    local timeout = GetGameTimer() + 3000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < timeout do
        Wait(0)
    end

    DoScreenFadeIn(500)
end

local function DeleteBreakoutInteractions()
    for k, id in pairs(BreakoutIxs) do
        if id then DeleteInteraction(id) end
        BreakoutIxs[k] = nil
    end
end

-- ========= Inicialização / Blips =========

function InitializeScript()
    for k, v in pairs(Config.Prisons) do
        PrisonInteractions[k] = {}
        if v.blip then
            CreateBlip(v.blip)
        end
    end
end

-- ========= Hospital =========

function TeleportHospital()
    if not Prison then return end
    CheckBreakout = false
    Wait(2000)
    local ped = PlayerPedId()
    local data = Config.Prisons[Prison.index].hospital
    TeleportPedSafe(ped, data.coords, data.heading)
    Wait(500)
    CheckBreakout = true
end

-- ========= Fuga (modo inativo → apenas START) =========

function ResetBreakout(index)
    local prison = Config.Prisons[index]
    if not prison or not prison.breakout or not prison.breakout.start then return end

    BreakoutActive = false               -- garantimos que não estamos em sequência ativa
    DeleteBreakoutInteractions()         -- limpa restos da sequência ativa anterior

    if PrisonInteractions[index].breakout then
        DeleteInteraction(PrisonInteractions[index].breakout)
        PrisonInteractions[index].breakout = nil
    end

    PrisonInteractions[index].breakout = CreateInteraction({
        label   = _L("interact_breakout"),
        coords  = prison.breakout.start.coords,
        heading = prison.breakout.start.heading
    }, function()
        ServerCallback("pickle_prisons:canBreakout", function(ok)
            if not ok then return end

            if Config.Breakout and type(Config.Breakout.process) == "function"
                and Config.Breakout.process(prison.breakout.start) then
                ShowNotification(_L("breakout_success"))
                TriggerServerEvent("pickle_prisons:startBreakout", index)

                -- >>> Fallback local: já arma ENTER/LEAVE/FINISH mesmo sem esperar o servidor
                BreakoutActive = true
                if PrisonInteractions[index].breakout then
                    DeleteInteraction(PrisonInteractions[index].breakout)
                    PrisonInteractions[index].breakout = nil
                end
                SetupBreakoutActive(index)
                -- <<<

            else
                ShowNotification(_L("breakout_fail"))
            end
        end, index)
    end)
end

-- ========= Fuga (modo ativo → START/ENTER/LEAVE/FINISH) =========

function SetupBreakoutActive(index)
    local prison = Config.Prisons[index]
    if not prison or not prison.breakout then return end
    local B = prison.breakout

    DeleteBreakoutInteractions()

    -- START (apenas visual para marcar o buraco aberto)
    if B.start then
        BreakoutIxs.start = CreateInteraction({
            label   = _L("interact_active_breakout"),
            coords  = B.start.coords,
            heading = B.start.heading,
            model   = Config.Breakout and Config.Breakout.model or nil
        }, function() end)
    end

    -- ENTER → teleporta para dentro do túnel (enter.teleportTo)
    if B.enter then
        BreakoutIxs.enter = CreateInteraction({
            label   = B.enter.label or _L("interact_enter_breakout") or "Entrar no Túnel",
            coords  = B.enter.coords,
            heading = B.enter.heading,
            model   = Config.Breakout and Config.Breakout.model or nil
        }, function()
            ServerCallback("pickle_prisons:enterBreakoutPoint", function(ok)
                if not ok then return end

                local tp = B.enter.teleportTo
                if not tp or not tp.coords then
                    ShowNotification("Destino do túnel não configurado (breakout.enter.teleportTo).")
                    return
                end

                -- marca breakout ativo e sai do estado de preso (mas NÃO limpar interações do túnel!)
                TriggerServerEvent("pickle_prisons:breakout")
                TriggerEvent("pickle_prisons:leavePrison")

                TeleportPedSafe(PlayerPedId(), tp.coords, tp.heading)
            end, index, "enter")
        end)
    end

    -- LEAVE → teleporta para fora (leave.teleportTo)
    if B.leave then
        BreakoutIxs.leave = CreateInteraction({
            label   = B.leave.label or _L("interact_exit_breakout") or "Sair do Túnel",
            coords  = B.leave.coords,
            heading = B.leave.heading,
            model   = Config.Breakout and Config.Breakout.model or nil
        }, function()
            ServerCallback("pickle_prisons:enterBreakoutPoint", function(ok)
                if not ok then return end

                local tp = B.leave.teleportTo or B.finish
                if not tp or not tp.coords then
                    ShowNotification("Saída não configurada (breakout.leave.teleportTo/breakout.finish).")
                    return
                end

                TeleportPedSafe(PlayerPedId(), tp.coords, tp.heading)
            end, index, "finish")
        end)
    end

    -- FINISH → ponto final (feedback)
    if B.finish then
        BreakoutIxs.finish = CreateInteraction({
            label   = B.finish.label or "Fugir",
            coords  = B.finish.coords,
            heading = B.finish.heading,
            model   = Config.Breakout and Config.Breakout.model or nil
        }, function()
            ShowNotification("Você escapou da prisão!")
            BreakoutActive = false
            -- opcional: TriggerServerEvent("pickle_prisons:escapedPrison", index)
        end)
    end
end

-- ========= Utilidades =========

function GetClosestPrison()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local closest
    for k, v in pairs(Config.Prisons) do
        local dist = #(coords - v.coords)
        if (not closest or dist < closest.dist) then
            closest = { index = k, dist = dist }
        end
    end
    return closest and closest.index or nil
end

-- ========= Diálogo de Prender =========

function JailDialog()
    local players = GetPlayersInArea()
    local players_list, prisons = {}, {}

    for i = 1, #players do
        local id = GetPlayerServerId(players[i])
        players_list[#players_list + 1] = {
            label = _L("jail_dialog_player", GetPlayerName(players[i]), id),
            value = id
        }
    end
    for k, v in pairs(Config.Prisons) do
        prisons[#prisons + 1] = { label = v.label, value = k }
    end
    if #prisons < 1 or #players_list < 1 then return end

    local input = lib.inputDialog(_L("jail_dialog_title"), {
        { type = 'select', label = _L("jail_dialog_prisoner"), default = players_list[1].value, required = true, options = players_list },
        { type = 'select', label = _L("jail_dialog_prison"),   default = "default",            required = true, options = prisons },
        { type = 'number', label = _L("jail_dialog_sentence"), default = 1,                    required = true, min = 1 },
    })
    if not input then return end

    TriggerServerEvent("pickle_prisons:jailPlayer", input[1], input[3], input[2])
end

RegisterNetEvent("pickle_prisons:jailDialog", JailDialog)

-- ========= Eventos de Fuga =========

RegisterNetEvent("pickle_prisons:startBreakout", function(index)
    -- servidor confirmando → também arma os pontos
    BreakoutActive = true
    if PrisonInteractions[index] and PrisonInteractions[index].breakout then
        DeleteInteraction(PrisonInteractions[index].breakout)
        PrisonInteractions[index].breakout = nil
    end
    SetupBreakoutActive(index)
end)

RegisterNetEvent("pickle_prisons:stopBreakout", function(index)
    BreakoutActive = false
    DeleteBreakoutInteractions()
    ResetBreakout(index)
end)

-- ========= Eventos de Cadeia =========

RegisterNetEvent("pickle_prisons:jailPlayer", function(data)
    Prison = data
    local prison = Config.Prisons[data.index]
    local cell = prison.cells[math.random(1, #prison.cells)]
    local coords, heading = cell.coords, cell.heading

    WarpPlayer(coords, heading, function()
        ToggleOutfit(true)
    end)

    TriggerEvent("pickle_prisons:enterPrison")

    Wait(2000)
    CreateThread(function()
        local pcenter = prison.coords
        while Prison and Prison.index == data.index do
            if CheckBreakout then
                local pcoords = GetEntityCoords(PlayerPedId())
                if Config.EnableSneakout then
                    if #(pcenter - pcoords) > prison.radius then
                        TriggerServerEvent("pickle_prisons:breakout")
                        TriggerEvent("pickle_prisons:leavePrison")
                        break
                    end
                else
                    if #(pcenter - pcoords) > prison.radius then
                        local c = prison.cells[math.random(1, #prison.cells)]
                        ShowNotification(_L("cant_sneakout"))
                        WarpPlayer(c.coords, c.heading, function()
                            ToggleOutfit(true)
                        end)
                    end
                end
            end
            Wait(1500)
        end
    end)
end)

RegisterNetEvent("pickle_prisons:unjailPlayer", function(data)
    TriggerEvent("pickle_prisons:leavePrison")
    local prison = Config.Prisons[data.index]
    local coords, heading = prison.release.coords, prison.release.heading
    WarpPlayer(coords, heading, function()
        ToggleOutfit(false)
    end)
end)

RegisterNetEvent("pickle_prisons:enterPrison", function()
    if not Prison or not Prison.index then return end
    local index = Prison.index
    ResetBreakout(index) -- cria apenas o START
end)

RegisterNetEvent("pickle_prisons:leavePrison", function()
    Prison = nil
    -- NÃO limpar interações se a fuga estiver ativa (para o ENTER/LEAVE/FINISH do túnel)
    if not BreakoutActive then
        DeleteBreakoutInteractions()
    end
end)

-- ========= Sirenes =========

RegisterNetEvent("pickle_prisons:startSiren", function(index)
    if PrisonSirens[index] then return end
    PrisonSirens[index] = true

    local prison = Config.Prisons[index]
    SendNUIMessage({ type = "startSiren" })

    CreateThread(function()
        local maxDist = prison.radius * 2
        while PrisonSirens[index] do
            if GetClosestPrison() == index then
                local pcoords = GetEntityCoords(PlayerPedId())
                local dist = #(prison.coords - pcoords)
                local factor = 1.0 - (dist / maxDist)
                if factor < 0 then factor = 0 end
                SendNUIMessage({ type = "setVolume", value = factor })
            end
            Wait(1500)
        end
        SendNUIMessage({ type = "endSiren" })
    end)
end)

RegisterNetEvent("pickle_prisons:stopSiren", function(index)
    PrisonSirens[index] = nil
end)

RegisterNetEvent("pickle_prisons:alert", function(index, disabled)
    Config.Alerts(index, disabled)
end)

-- ========= Resource lifecycle =========

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    Wait(1000)
    TriggerServerEvent("pickle_prisons:initializePlayer")
end)

CreateThread(function()
    InitializeScript()
    -- se o recurso recarregar enquanto já está preso, reconstrói o START
    Wait(1000)
    if Prison and Prison.index then
        ResetBreakout(Prison.index)
    end
end)
