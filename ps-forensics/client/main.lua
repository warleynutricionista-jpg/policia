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
    if data.status == 'finalizada' and sceneBlips[sceneId] then
        RemoveBlip(sceneBlips[sceneId])
        sceneBlips[sceneId] = nil
        activeScenes[sceneId] = nil
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
