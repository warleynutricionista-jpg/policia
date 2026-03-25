-- ============================================================
-- PS-FORENSICS - Client Principal
-- ============================================================

local resourceName = GetCurrentResourceName()
local isForensicsOpen = false
local activeScenes = {}
local sceneBlips = {}

-- ============================================================
-- VERIFICAR SE JOGADOR TEM ACESSO
-- ============================================================
local function hasAccess()
    local playerData = QBX and QBX.Functions.GetPlayerData() or nil
    if not playerData then return false end
    local job = playerData.job and playerData.job.name or ''
    return ForensicUtils.IsPoliceJob(job) or ForensicUtils.IsMedicalJob(job)
end

local function getPlayerJob()
    local playerData = QBX and QBX.Functions.GetPlayerData() or nil
    if not playerData then return '', 0 end
    return playerData.job.name, playerData.job.grade.level
end

-- ============================================================
-- FRAMEWORK INIT
-- ============================================================
QBX = nil

CreateThread(function()
    local ok, core = pcall(function()
        return exports['qbx_core']:GetCoreObject()
    end)
    if ok and core then
        QBX = core
    end
end)

-- ============================================================
-- ABRIR INTERFACE FORENSE (NUI)
-- ============================================================
function OpenForensicsUI(tab)
    if not hasAccess() then
        lib.notify({
            title = L('ui.system_name'),
            description = L('ui.access_denied'),
            type = 'error',
        })
        return
    end

    local jobName, grade = getPlayerJob()
    local roleName, roleConfig = ForensicUtils.GetPlayerRole(jobName, grade)

    SetNuiFocus(true, true)
    isForensicsOpen = true

    SendNUIMessage({
        action = 'open',
        tab = tab or 'scenes',
        role = roleName,
        permissions = roleConfig,
        playerName = QBX and QBX.Functions.GetPlayerData().charinfo.firstname .. ' ' .. QBX.Functions.GetPlayerData().charinfo.lastname or L('ui.officer_fallback_name'),
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
-- COMANDOS
-- ============================================================
RegisterCommand(Config.Commands.OpenForensics, function()
    OpenForensicsUI()
end, false)

RegisterCommand(Config.Commands.CreateScene, function()
    if not hasAccess() then return end
    OpenCreateSceneMenu()
end, false)

RegisterCommand(Config.Commands.CollectEvidence, function()
    if not hasAccess() then return end
    OpenCollectEvidenceMenu()
end, false)

RegisterCommand(Config.Commands.RunTest, function()
    if not hasAccess() then return end
    OpenRunTestMenu()
end, false)

-- ============================================================
-- KEYBIND
-- ============================================================
RegisterKeyMapping(Config.Commands.OpenForensics, L('commands.open_forensics'), 'keyboard', 'F10')

-- ============================================================
-- NUI CALLBACKS
-- ============================================================
RegisterNUICallback('close', function(_, cb)
    CloseForensicsUI()
    cb('ok')
end)

RegisterNUICallback('getScenes', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:getScenes', false, data)
    cb(result)
end)

RegisterNUICallback('getScene', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:getScene', false, data.id)
    cb(result)
end)

RegisterNUICallback('createScene', function(data, cb)
    local coords = GetEntityCoords(PlayerPedId())
    data.x = coords.x
    data.y = coords.y
    data.z = coords.z

    local streetHash, _ = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    data.location_name = data.location_name or GetStreetNameFromHashKey(streetHash) or L('scene.unknown_location')

    local result = lib.callback.await(resourceName .. ':server:createScene', false, data)
    cb(result)
end)

RegisterNUICallback('updateScene', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:updateScene', false, data.id, data)
    cb(result)
end)

RegisterNUICallback('getEvidenceList', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:getEvidenceList', false, data)
    cb(result)
end)

RegisterNUICallback('getEvidence', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:getEvidence', false, data.id)
    cb(result)
end)

RegisterNUICallback('collectEvidence', function(data, cb)
    local coords = GetEntityCoords(PlayerPedId())
    data.x = coords.x
    data.y = coords.y
    data.z = coords.z

    local streetHash, _ = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    data.location_name = data.location_name or GetStreetNameFromHashKey(streetHash) or ''

    -- Animação de coleta
    lib.requestAnimDict('anim@gangops@facility@servers@bodysearch@')
    TaskPlayAnim(PlayerPedId(), 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, -8.0, 5000, 49, 0, false, false, false)

    local processingTime = Config.TestProcessingTimes['coleta_digital'] or 10
    if lib.progressBar({
        duration = processingTime * 1000,
        label = L('evidence.collecting'),
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = {
            dict = 'anim@gangops@facility@servers@bodysearch@',
            clip = 'player_search',
        },
    }) then
        local result = lib.callback.await(resourceName .. ':server:collectEvidence', false, data)
        cb(result)
    else
        ClearPedTasks(PlayerPedId())
        cb({ success = false, error = L('evidence.collect_cancelled') })
    end
end)

RegisterNUICallback('updateEvidence', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:updateEvidence', false, data.id, data)
    cb(result)
end)

RegisterNUICallback('transferEvidence', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:transferEvidence', false, data.evidenceId, data.toCitizenId, data.toName, data.notes)
    cb(result)
end)

RegisterNUICallback('getCustodyChain', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:getCustodyChain', false, data.evidenceId)
    cb(result)
end)

-- Digitais
RegisterNUICallback('collectFingerprint', function(data, cb)
    if lib.progressBar({
        duration = (Config.TestProcessingTimes['coleta_digital'] or 12) * 1000,
        label = L('test.collecting_fingerprint'),
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a' },
    }) then
        local result = lib.callback.await(resourceName .. ':server:collectFingerprint', false, data)
        cb(result)
    else
        cb({ success = false, error = L('test.canceled') })
    end
end)

RegisterNUICallback('analyzeFingerprint', function(data, cb)
    if lib.progressBar({
        duration = (Config.TestProcessingTimes['comparacao_digital'] or 40) * 1000,
        label = L('test.processing_fingerprint'),
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
    }) then
        local result = lib.callback.await(resourceName .. ':server:analyzeFingerprint', false, data.id)
        cb(result)
    else
        cb({ success = false, error = L('test.canceled') })
    end
end)

RegisterNUICallback('registerFingerprint', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:registerFingerprint', false, data.citizenid, data.name)
    cb(result)
end)

-- DNA
RegisterNUICallback('collectDNA', function(data, cb)
    if lib.progressBar({
        duration = (Config.TestProcessingTimes['coleta_dna'] or 15) * 1000,
        label = L('test.collecting_dna'),
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = { dict = 'anim@gangops@facility@servers@bodysearch@', clip = 'player_search' },
    }) then
        local result = lib.callback.await(resourceName .. ':server:collectDNASample', false, data)
        cb(result)
    else
        cb({ success = false, error = L('test.canceled') })
    end
end)

RegisterNUICallback('analyzeDNA', function(data, cb)
    if lib.progressBar({
        duration = (Config.TestProcessingTimes['comparacao_dna'] or 60) * 1000,
        label = L('test.processing_dna'),
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
    }) then
        local result = lib.callback.await(resourceName .. ':server:analyzeDNA', false, data.id)
        cb(result)
    else
        cb({ success = false, error = L('test.canceled') })
    end
end)

RegisterNUICallback('registerDNA', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:registerDNAProfile', false, data.citizenid, data.name, data.bloodType)
    cb(result)
end)

RegisterNUICallback('searchFingerprintsByCitizen', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:searchFingerprintsByCitizen', false, data.citizenid)
    cb(result or {})
end)

RegisterNUICallback('searchDNAByCitizen', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:searchDNAByCitizen', false, data.citizenid)
    cb(result or {})
end)

-- Balística
RegisterNUICallback('registerBallistic', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:registerBallistic', false, data)
    cb(result)
end)

RegisterNUICallback('getWeaponBallisticHistory', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:getWeaponBallisticHistory', false, data.serial)
    cb(result or {})
end)

RegisterNUICallback('ballisticComparison', function(data, cb)
    if lib.progressBar({
        duration = (Config.TestProcessingTimes['confronto_balistico'] or 45) * 1000,
        label = L('test.running_ballistics'),
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
    }) then
        local result = lib.callback.await(resourceName .. ':server:ballisticComparison', false, data.ballisticId, data.weaponSerial)
        cb(result)
    else
        cb({ success = false, error = L('test.canceled') })
    end
end)

-- Testes laboratoriais
RegisterNUICallback('requestLabTest', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:requestLabTest', false, data)
    cb(result)
end)

RegisterNUICallback('performLabTest', function(data, cb)
    local testType = data.test_type or 'outro'
    local duration = Config.TestProcessingTimes[testType] or 20

    if lib.progressBar({
        duration = duration * 1000,
        label = L('test.running'),
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
    }) then
        local result = lib.callback.await(resourceName .. ':server:performLabTest', false, data.id)
        cb(result)
    else
        cb({ success = false, error = L('test.canceled') })
    end
end)

RegisterNUICallback('getLabTests', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:getLabTests', false, data)
    cb(result)
end)

-- Drogas
RegisterNUICallback('registerDrugAnalysis', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:registerDrugAnalysis', false, data)
    cb(result)
end)

RegisterNUICallback('confirmDrug', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:confirmDrugSubstance', false, data.id, data.substance, data.purity, data.result)
    cb(result)
end)

RegisterNUICallback('getDrugAnalyses', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:getDrugAnalyses', false, data)
    cb(result)
end)

-- Necropsia
RegisterNUICallback('createAutopsy', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:createAutopsy', false, data)
    cb(result)
end)

RegisterNUICallback('updateAutopsy', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:updateAutopsy', false, data.id, data)
    cb(result)
end)

RegisterNUICallback('getAutopsy', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:getAutopsy', false, data.id)
    cb(result)
end)

RegisterNUICallback('getAutopsies', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:getAutopsies', false, data)
    cb(result)
end)

RegisterNUICallback('performToxicology', function(data, cb)
    if lib.progressBar({
        duration = (Config.TestProcessingTimes['toxicologico'] or 50) * 1000,
        label = L('test.running_toxicology'),
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
    }) then
        local result = lib.callback.await(resourceName .. ':server:performToxicology', false, data.id)
        cb(result)
    else
        cb({ success = false, error = L('test.canceled') })
    end
end)

-- Laudos
RegisterNUICallback('createReport', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:createForensicReport', false, data)
    cb(result)
end)

RegisterNUICallback('updateReport', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:updateForensicReport', false, data.id, data)
    cb(result)
end)

RegisterNUICallback('finalizeReport', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:finalizeForensicReport', false, data.id)
    cb(result)
end)

RegisterNUICallback('attachReportToMDT', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:attachReportToMDT', false, data.id)
    cb(result)
end)

RegisterNUICallback('getReports', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:getForensicReports', false, data)
    cb(result)
end)

RegisterNUICallback('getReport', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:getForensicReport', false, data.id)
    cb(result)
end)

-- Cruzamento de dados
RegisterNUICallback('getCrossRefByCitizen', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:getCrossRefByCitizen', false, data.citizenid)
    cb(result)
end)

RegisterNUICallback('getCrossRefByWeapon', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:getCrossRefByWeapon', false, data.serial)
    cb(result)
end)

RegisterNUICallback('getCrossRefByVehicle', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:getCrossRefByVehicle', false, data.plate)
    cb(result)
end)

RegisterNUICallback('getInvestigationDashboard', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:getInvestigationDashboard', false, data.citizenid)
    cb(result)
end)

-- Integração MDT / sistema policial
RegisterNUICallback('getForensicDataByCase', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:getForensicDataByCase', false, data.caseId)
    cb(result)
end)

RegisterNUICallback('getForensicDataByReport', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:getForensicDataByReport', false, data.reportId)
    cb(result)
end)

RegisterNUICallback('getForensicDataByCitizen', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:getForensicDataByCitizen', false, data.citizenid)
    cb(result)
end)

RegisterNUICallback('getForensicDataByWeapon', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:getForensicDataByWeapon', false, data.serial)
    cb(result)
end)

RegisterNUICallback('getForensicDataByVehicle', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:getForensicDataByVehicle', false, data.plate)
    cb(result)
end)

RegisterNUICallback('getForensicDataByEvidence', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:getForensicDataByEvidence', false, data.evidenceId)
    cb(result)
end)

RegisterNUICallback('searchForensicGlobal', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:searchForensicGlobal', false, data)
    cb(result)
end)

RegisterNUICallback('getMDTIntegrationBundle', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:getMDTIntegrationBundle', false, data)
    cb(result)
end)

RegisterNUICallback('getForensicStats', function(data, cb)
    local result = lib.callback.await(resourceName .. ':server:getForensicStats', false)
    cb(result)
end)

-- ============================================================
-- BLIPS DE CENAS ATIVAS
-- ============================================================
RegisterNetEvent(resourceName .. ':client:sceneCreated', function(scene)
    if not hasAccess() then return end

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

    -- Laboratório Forense
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
                    onSelect = function()
                        OpenForensicsUI('lab')
                    end,
                    canInteract = function()
                        return hasAccess()
                    end,
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

    -- IML
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
                    onSelect = function()
                        OpenForensicsUI('autopsy')
                    end,
                    canInteract = function()
                        return hasAccess()
                    end,
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

    -- Depósito de evidências
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
                    onSelect = function()
                        OpenForensicsUI('evidence')
                    end,
                    canInteract = function()
                        return hasAccess()
                    end,
                }
            }
        })
    end
end)

-- ============================================================
-- ESC para fechar
-- ============================================================
CreateThread(function()
    while true do
        Wait(0)
        if isForensicsOpen then
            DisableControlAction(0, 200, true) -- ESC
            if IsDisabledControlJustReleased(0, 200) then
                CloseForensicsUI()
            end
        else
            Wait(500)
        end
    end
end)
