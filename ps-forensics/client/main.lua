-- ============================================================
-- PS-FORENSICS - Client Principal
-- ============================================================

local resourceName = GetCurrentResourceName()
local isForensicsOpen = false
local activeScenes = {}
local sceneBlips = {}

local function hasForensicsAccess()
    if ForensicsAccess and ForensicsAccess.hasAccess then
        return ForensicsAccess.hasAccess()
    end

    return type(hasAccess) == 'function' and hasAccess() or false
end

local function resolvePlayerJob()
    if ForensicsAccess and ForensicsAccess.getPlayerJob then
        return ForensicsAccess.getPlayerJob()
    end

    if type(getPlayerJob) == 'function' then
        return getPlayerJob()
    end

    return '', 0, ''
end


function IsWithinActiveCrimeScene(coords)
    local targetCoords = coords
    if not targetCoords then
        local ped = PlayerPedId()
        if ped and ped > 0 then
            targetCoords = GetEntityCoords(ped)
        end
    end

    if not targetCoords then return false end

    for _, scene in pairs(activeScenes) do
        if scene and scene.x and scene.y and scene.z then
            local radius = tonumber(scene.perimeter_radius) or 50.0
            local distance = #(vec3(scene.x, scene.y, scene.z) - vec3(targetCoords.x, targetCoords.y, targetCoords.z))
            if distance <= radius then
                return true, scene.id
            end
        end
    end

    return false
end

-- ============================================================
-- ABRIR INTERFACE FORENSE (NUI)
-- ============================================================
function OpenForensicsUI(tab)
    if not hasForensicsAccess() then
        lib.notify({
            title = L('ui.system_name'),
            description = L('ui.access_denied'),
            type = 'error',
        })
        return
    end

    local itemCheck = lib.callback.await(resourceName .. ':server:validateActionItems', false, 'open_tablet')
    if not itemCheck or not itemCheck.success then
        lib.notify({
            title = L('ui.system_name'),
            description = itemCheck and itemCheck.error or 'Tablet forense obrigatório para abrir o painel.',
            type = 'error',
        })
        return
    end

    local jobName, grade, gradeName = resolvePlayerJob()
    local roleName, roleConfig = ForensicUtils.GetPlayerRole(jobName, grade, gradeName)

    local permLevelName = Config.PermissionMatrix.byJob[jobName] or 'operacional'
    local permLevel = Config.PermissionMatrix.levels[permLevelName] or 1

    local availableTabs = {}
    for _, tabDef in ipairs(Config.PanelTabs) do
        local hasLevel = permLevel >= tabDef.minLevel
        local hasJob = true

        if tabDef.jobs then
            hasJob = false
            for _, j in ipairs(tabDef.jobs) do
                if j == jobName then
                    hasJob = true
                    break
                end
            end
        end

        if hasLevel and hasJob then
            availableTabs[#availableTabs + 1] = tabDef.id
        end
    end

    local openTab = tab or availableTabs[1] or 'dashboard'
    local tabAllowed = false
    for _, t in ipairs(availableTabs) do
        if t == openTab then
            tabAllowed = true
            break
        end
    end

    if not tabAllowed then
        openTab = availableTabs[1] or 'dashboard'
    end

    local pd = ForensicsAccess and ForensicsAccess.getPlayerData and ForensicsAccess.getPlayerData() or {}
    local charinfo = pd and pd.charinfo or {}
    local playerName = (charinfo.firstname and charinfo.lastname)
        and (charinfo.firstname .. ' ' .. charinfo.lastname)
        or L('ui.officer_fallback_name')

    pcall(function()
        if GetResourceState('ox_inventory') == 'started' and exports.ox_inventory then
            exports.ox_inventory:closeInventory()
        end
    end)

    SetNuiFocus(true, true)
    isForensicsOpen = true

    SendNUIMessage({
        action = 'open',
        tab = openTab,
        role = roleName,
        permissions = roleConfig,
        availableTabs = availableTabs,
        playerName = playerName,
        playerJob = jobName,
        playerGrade = grade,
    })
end

function CloseForensicsUI()
    SetNuiFocus(false, false)
    isForensicsOpen = false
    SendNUIMessage({ action = 'close' })
end

-- ============================================================
-- BLIPS DE CENAS ATIVAS
-- ============================================================
RegisterNetEvent(resourceName .. ':client:sceneCreated', function(scene)
    if not hasForensicsAccess() then return end

    activeScenes[scene.id] = scene

    local blip = AddBlipForCoord(scene.x, scene.y, scene.z)
    SetBlipSprite(blip, Config.SceneBlip.sprite)
    SetBlipColour(blip, Config.SceneBlip.color)
    SetBlipScale(blip, Config.SceneBlip.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(('%s - %s'):format(Config.SceneBlip.label, scene.sceneNumber))
    EndTextCommandSetBlipName(blip)

    sceneBlips[scene.id] = blip

    lib.notify({
        title = L('scene.title'),
        description = L('scene.new_scene', scene.sceneNumber, scene.createdBy),
        type = 'inform',
        duration = 8000,
    })
end)

RegisterNetEvent(resourceName .. ':client:sceneUpdated', function(sceneId, data)
    if not sceneId then return end

    if data and data.status == 'finalizada' then
        if sceneBlips[sceneId] then
            RemoveBlip(sceneBlips[sceneId])
            sceneBlips[sceneId] = nil
        end
        activeScenes[sceneId] = nil
        return
    end

    if activeScenes[sceneId] and data then
        for k, v in pairs(data) do
            activeScenes[sceneId][k] = v
        end
    end
end)

CreateThread(function()
    Wait(1500)
    local scenes = lib.callback.await(resourceName .. ':server:getActiveScenePerimeters', false)
    if type(scenes) == 'table' then
        for _, scene in ipairs(scenes) do
            activeScenes[scene.id] = {
                id = scene.id,
                sceneNumber = scene.scene_number,
                status = scene.status,
                x = scene.location_x,
                y = scene.location_y,
                z = scene.location_z,
                perimeter_radius = scene.perimeter_radius,
            }
        end
    end
end)

-- ============================================================
-- TARGETS (ox_target) - Laboratório e IML
-- ============================================================
CreateThread(function()
    Wait(2000)

    if Config.Locations.Lab then
        local lab = Config.Locations.Lab
        exports.ox_target:addSphereZone({
            coords = lab.coords,
            radius = lab.radius,
            options = {
                {
                    name = 'open_forensic_lab',
                    icon = 'fa-solid fa-microscope',
                    label = L('target.open_lab'),
                    onSelect = function() OpenForensicsUI('analises') end,
                    canInteract = function() return hasForensicsAccess() end,
                }
            }
        })

        if lab.blip then
            local blip = AddBlipForCoord(lab.coords.x, lab.coords.y, lab.coords.z)
            SetBlipSprite(blip, lab.blip.sprite)
            SetBlipColour(blip, lab.blip.color)
            SetBlipScale(blip, lab.blip.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(lab.blip.label)
            EndTextCommandSetBlipName(blip)
        end
    end

    if Config.Locations.Morgue then
        local morgue = Config.Locations.Morgue
        exports.ox_target:addSphereZone({
            coords = morgue.coords,
            radius = morgue.radius,
            options = {
                {
                    name = 'open_forensic_morgue',
                    icon = 'fa-solid fa-skull',
                    label = L('target.open_morgue'),
                    onSelect = function() OpenForensicsUI('analises') end,
                    canInteract = function() return hasForensicsAccess() end,
                }
            }
        })

        if morgue.blip then
            local blip = AddBlipForCoord(morgue.coords.x, morgue.coords.y, morgue.coords.z)
            SetBlipSprite(blip, morgue.blip.sprite)
            SetBlipColour(blip, morgue.blip.color)
            SetBlipScale(blip, morgue.blip.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(morgue.blip.label)
            EndTextCommandSetBlipName(blip)
        end
    end

    if Config.Locations.EvidenceStorage then
        local storage = Config.Locations.EvidenceStorage
        exports.ox_target:addSphereZone({
            coords = storage.coords,
            radius = storage.radius,
            options = {
                {
                    name = 'open_evidence_storage',
                    icon = 'fa-solid fa-box-archive',
                    label = L('target.open_storage'),
                    onSelect = function() OpenForensicsUI('evidence') end,
                    canInteract = function() return hasForensicsAccess() end,
                }
            }
        })
    end

    if Config.ForensicShop and Config.ForensicShop.enabled then
        local shop = Config.ForensicShop
        exports.ox_target:addSphereZone({
            coords = shop.coords,
            radius = shop.radius or 2.0,
            options = {
                {
                    name = 'open_forensic_shop',
                    icon = shop.targetIcon or 'fa-solid fa-cart-shopping',
                    label = shop.targetLabel or 'Abrir loja forense',
                    onSelect = function()
                        local shopId = shop.id or 'forensics_supply_shop'
                        exports.ox_inventory:openInventory('shop', { type = shopId })
                    end,
                    canInteract = function() return hasForensicsAccess() end,
                }
            }
        })

        if shop.blip and shop.blip.enabled then
            local blip = AddBlipForCoord(shop.coords.x, shop.coords.y, shop.coords.z)
            SetBlipSprite(blip, shop.blip.sprite or 59)
            SetBlipColour(blip, shop.blip.color or 38)
            SetBlipScale(blip, shop.blip.scale or 0.75)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(shop.blip.label or 'Loja Forense')
            EndTextCommandSetBlipName(blip)
        end
    end
end)

CreateThread(function()
    while true do
        if isForensicsOpen then
            Wait(0)
            DisableControlAction(0, 200, true)
            if IsDisabledControlJustReleased(0, 200) then
                CloseForensicsUI()
            end
        else
            Wait(500)
        end
    end
end)
