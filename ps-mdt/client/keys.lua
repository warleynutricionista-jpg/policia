MDTOpen = false -- Track MDT state
local resourceName = tostring(GetCurrentResourceName())
local ps = RequirePs('client/keys.lua')

-- Control management
local controlsDisabled = false
local controlCheckInterval = 0

-- Cache globals for performance
local DisableControlAction = DisableControlAction
local Wait = Wait
local CreateThread = CreateThread
local IsPedSwimming = IsPedSwimming
local IsPedInAnyVehicle = IsPedInAnyVehicle
local GetVehicleDashboardSpeed = GetVehicleDashboardSpeed
local GetVehiclePedIsIn = GetVehiclePedIsIn
local SetNuiFocus = SetNuiFocus
local SetNuiFocusKeepInput = SetNuiFocusKeepInput
local SendNUI = SendNUI
local RegisterNUICallback = RegisterNUICallback

-- Permissions check ------------------------------------------

-- Check Job Authorization
function CheckAuth()
    return ps.callback(resourceName..':server:checkAuth')
end

-- Controls --------------------------------------------------

-- Controls to disable
local restrictedControls = {
    -- Camera controls
    {0, 0},   -- Next Camera
    {0, 1},   -- Look Left/Right
    {0, 2},   -- Look Up/Down
    {0, 26},  -- Look Behind

    -- Weapon controls
    {0, 16},  -- Next Weapon
    {0, 17},  -- Previous Weapon
    {0, 24},  -- Attack
    {0, 25},  -- Aim
    {0, 37},  -- Weapon Wheel
    {0, 140}, -- Melee Attack

    -- Movement controls
    {0, 21},  -- Sprint
    {0, 22},  -- Jump
    {0, 36},  -- Duck/Sneak
    {0, 44},  -- Cover
    {0, 55},  -- Dive

    -- Vehicle controls
    {0, 75},  -- Exit Vehicle
    {0, 76},  -- Handbrake
    {0, 81},  -- Next Radio
    {0, 82},  -- Previous Radio
    {0, 85},  -- Radio Wheel
    {0, 86},  -- Horn
    {0, 91},  -- Passenger Aim
    {0, 92},  -- Passenger Attack
    {0, 99},  -- Vehicle Weapon Select
    {0, 106}, -- Vehicle Override
    {0, 120}, -- Vehicle Duck

    -- Aircraft controls
    {0, 114}, -- Aircraft Attack
    {0, 115}, -- Aircraft Weapon
    {0, 121}, -- Aircraft Camera
    {0, 122}, -- Aircraft Override
    {0, 135}, -- Submarine Override

    -- UI controls
    {0, 47},  -- Detonate
    {0, 200}, -- Pause Menu
    {0, 245}, -- Chat
}

-- Control disabling loop
CreateThread(function()
    while true do
        if controlsDisabled then
            controlCheckInterval = 0
            for i = 1, #restrictedControls do
                local control = restrictedControls[i]
                DisableControlAction(control[1], control[2], true)
            end
        else
            controlCheckInterval = 150
        end
        Wait(controlCheckInterval)
    end
end)

-- Control state management
local function toggleControls(state)
    controlsDisabled = state
end

-- Realism checks ------------------------------------------

-- Check if player is in a moving vehicle (can't use MDT while driving fast)
local function isVehicleMovingFast()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return false end
    local vehicle = GetVehiclePedIsIn(ped, false)
    local speed = GetEntitySpeed(vehicle) * 3.6 -- Convert to km/h
    return speed > 80 -- Can't open MDT above 80 km/h
end

-- Check if player is the driver (passengers can use MDT freely)
local function isDriver()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return false end
    local vehicle = GetVehiclePedIsIn(ped, false)
    return GetPedInVehicleSeat(vehicle, -1) == ped
end

-- MDT Display ------------------------------------------------

-- Open MDT
function OpenMDT()
    -- Check auth
    if not CheckAuth() then return end

    -- Don't allow if player is dead
    if ps.isDead() then
        ps.notify('Você não pode abrir o MDT agora', 'error')
        return
    end

    -- Don't allow if swimming
    local ped = PlayerPedId()
    if IsPedSwimming(ped) then
        ps.notify('Você não pode abrir o MDT agora', 'error')
        return
    end

    -- Don't allow if armed
    if IsPedArmed(ped, 1) or IsPedArmed(ped, 2) or IsPedArmed(ped, 4) then
        ps.notify('Guarde sua arma primeiro', 'error')
        return
    end

    -- Don't allow if falling
    if IsPedFalling(ped) then
        ps.notify('Você não pode abrir o MDT agora', 'error')
        return
    end

    -- Don't allow if vehicle is moving too fast (realism - driver only)
    if isDriver() and isVehicleMovingFast() then
        ps.notify('Reduza a velocidade antes de usar o MDT', 'error')
        return
    end

    -- Don't allow if viewing a camera
    if exports[resourceName]:isViewingCamera() then
        ps.notify('Você não pode abrir o MDT enquanto visualiza uma câmera', 'error')
        return
    end

    -- Check if MDT is already open (toggle behavior)
    if MDTOpen then
        StopTabletAnimation()
        SendNUI('setVisible', { visible = false })
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        toggleControls(false)
        MDTOpen = false
        return
    end

    MDTOpen = true

    SendNUI('setVisible', { visible = true, debugMode = Config.Debug })

    PlayMDTSound('open')
    PlayTabletAnimation()

    -- Send NUI data
    NUIUpdateAuth()

    TriggerServerEvent('ps-mdt:server:trackLogin')

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    toggleControls(true)
end

-- Close MDT
local closeControlsPending = false

function CloseMDT()
    if MDTOpen then
        MDTOpen = false

        StopTabletAnimation()

        SendNUI('setVisible', { visible = false })
        SetNuiFocus(false, false)

        -- Prevent ESC pause menu conflict - only spawn one delayed thread at a time
        if not closeControlsPending then
            closeControlsPending = true
            CreateThread(function()
                Wait(100)
                toggleControls(false)
                closeControlsPending = false
            end)
        end

        ps.debug('MDT closed via CloseMDT function')
        TriggerServerEvent('ps-mdt:server:trackLogout')
    end
end

-- Auto-close MDT if player exits vehicle while MDT is open (realism)
CreateThread(function()
    local wasInVehicle = false
    while true do
        if MDTOpen then
            local ped = PlayerPedId()
            local inVehicle = IsPedInAnyVehicle(ped, false)

            if wasInVehicle and not inVehicle then
                -- Player exited vehicle while MDT was open
                CloseMDT()
                ps.notify('MDT desconectado - você saiu do veículo', 'error')
            end

            wasInVehicle = inVehicle
            Wait(500)
        else
            wasInVehicle = IsPedInAnyVehicle(PlayerPedId(), false)
            Wait(1000)
        end
    end
end)

-- Nui ------------------------------------------------------

RegisterNUICallback('setTopBarHover', function(_, cb)
    cb({})
end)

-- Copy text to clipboard (FiveM NUI blocks the browser Clipboard API)
RegisterNUICallback('copyToClipboard', function(data, cb)
    if data and data.text then
        lib.setClipboard(tostring(data.text))
    end
    cb({})
end)

-- Keybinds -------------------------------------------------

-- Key to open MDT
if not Config.Keys.OpenMDT.enabled then
    ps.debug('MDT Open Keybind Disabled')
else
    ps.debug('MDT Open Keybind Enabled: ' .. Config.Keys.OpenMDT.key)
    ps.addKeybind({
        name = ('%s_open_mdt'):format(resourceName:gsub('[^%w_]+', '_'):lower()),
        description = 'Abrir ou fechar o MDT',
        defaultKey = Config.Keys.OpenMDT.key,
        onPressed = function()
            OpenMDT()
        end,
    })
end
