local resourceName = GetCurrentResourceName()

local ItemActions = {
    forensic_kit = { prop = 'prop_ld_case_01', duration = 2500, notifyKey = 'items.use.forensic_kit' },
    disposable_gloves = { prop = 'prop_cs_cardbox_01', duration = 1800, notifyKey = 'items.use.disposable_gloves' },
    evidence_bag = { prop = 'xm3_prop_xm3_evidence_case_01a', duration = 2200, notifyKey = 'items.use.evidence_bag' },
    evidence_seal = { prop = 'prop_notepad_01', duration = 1500, notifyKey = 'items.use.evidence_seal' },
    dna_swab = { prop = 'prop_cs_mop_s', duration = 2200, notifyKey = 'items.use.dna_swab' },
    fingerprint_kit = { prop = 'prop_cs_fingerprint', duration = 3000, notifyKey = 'items.use.fingerprint_kit' },
    fingerprint_powder = { prop = 'bkr_prop_coke_bakingsoda_o', duration = 2100, notifyKey = 'items.use.fingerprint_powder' },
    fingerprint_tape = { prop = 'prop_tapeplayer_01', duration = 1700, notifyKey = 'items.use.fingerprint_tape' },
    blood_reagent = { prop = 'prop_cs_spray_can', duration = 2200, notifyKey = 'items.use.blood_reagent' },
    gsr_kit = { prop = 'prop_cs_box_clothes', duration = 2500, notifyKey = 'items.use.gsr_kit' },
    drug_test_kit = { prop = 'prop_mp_drug_pack_blue', duration = 2500, notifyKey = 'items.use.drug_test_kit' },
    forensic_tweezers = { prop = 'prop_pencil_01', duration = 1700, notifyKey = 'items.use.forensic_tweezers' },
    forensic_camera = { prop = 'prop_pap_camera_01', duration = 1800, notifyKey = 'items.use.forensic_camera' },
    evidence_marker = { prop = 'prop_mp_num_6', duration = 1400, notifyKey = 'items.use.evidence_marker' },
    evidence_tag = { prop = 'prop_notepad_01', duration = 1400, notifyKey = 'items.use.evidence_tag' },
    medical_exam_case = { prop = 'xm_prop_smug_crate_s_medical', duration = 2800, notifyKey = 'items.use.medical_exam_case' },
    body_bag = { prop = 'xm_prop_body_bag', duration = 2600, notifyKey = 'items.use.body_bag' },
    forensic_flashlight = { prop = 'prop_cs_polaroid', duration = 1000, notifyKey = 'items.use.forensic_flashlight' },
    ballistic_kit = { prop = 'prop_idol_case_01', duration = 2600, notifyKey = 'items.use.ballistic_kit' },
    forensic_tablet = { prop = 'prop_cs_tablet', duration = 1500, notifyKey = 'items.use.forensic_tablet', openUi = true },
}

local spawnedMarker = nil
local equippedTool = {
    itemName = nil,
    entity = nil,
}

local ToolAttach = {
    forensic_camera = {
        bone = 57005,
        pos = vec3(0.12, 0.02, -0.02),
        rot = vec3(-85.0, 0.0, 5.0),
    },
    forensic_flashlight = {
        bone = 57005,
        pos = vec3(0.1, 0.02, -0.02),
        rot = vec3(-90.0, 0.0, 0.0),
    },
}

local function setForensicFlashlightState(state)
    SetFlashLightKeepOnWhileMoving(state)

    if type(ToggleForensicFlashlight) == 'function' then
        ToggleForensicFlashlight(state)
    end
end

local function clearEquippedTool()
    if equippedTool.entity and DoesEntityExist(equippedTool.entity) then
        DeleteEntity(equippedTool.entity)
    end

    if equippedTool.itemName == 'forensic_flashlight' then
        setForensicFlashlightState(false)
    end

    equippedTool.entity = nil
    equippedTool.itemName = nil
end

local function equipTool(itemName, modelName)
    clearEquippedTool()

    local attach = ToolAttach[itemName]
    local modelHash = joaat(modelName)

    if not attach or not IsModelInCdimage(modelHash) then
        return false
    end

    lib.requestModel(modelName)

    local ped = PlayerPedId()
    local entity = CreateObject(modelHash, 0.0, 0.0, 0.0, true, true, false)
    if not entity or not DoesEntityExist(entity) then
        return false
    end

    AttachEntityToEntity(
        entity,
        ped,
        GetPedBoneIndex(ped, attach.bone),
        attach.pos.x, attach.pos.y, attach.pos.z,
        attach.rot.x, attach.rot.y, attach.rot.z,
        true, true, false, true, 1, true
    )

    equippedTool.itemName = itemName
    equippedTool.entity = entity

    if itemName == 'forensic_flashlight' then
        setForensicFlashlightState(true)
    end

    return true
end

local function playItemAnimation(config)
    lib.requestAnimDict('mini@repair')

    local progress = {
        duration = config.duration or 2000,
        label = L('items.use_progress'),
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'mini@repair', clip = 'fixing_a_ped' },
    }

    if config.prop then
        local modelHash = joaat(config.prop)
        if IsModelInCdimage(modelHash) then
        progress.prop = {
            model = config.prop,
            pos = vec3(0.03, 0.03, 0.02),
            rot = vec3(30.0, 10.0, 140.0),
            bone = 60309,
        }
        end
    end

    return lib.progressBar(progress)
end

local function placeEvidenceMarker()
    local ped = PlayerPedId()
    local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.7, -1.0)

    if spawnedMarker and DoesEntityExist(spawnedMarker) then
        DeleteEntity(spawnedMarker)
        spawnedMarker = nil
    end

    local model = joaat('prop_mp_num_6')
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end

    spawnedMarker = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
    PlaceObjectOnGroundProperly(spawnedMarker)
    SetModelAsNoLongerNeeded(model)

    CreateThread(function()
        Wait(600000)
        if spawnedMarker and DoesEntityExist(spawnedMarker) then
            DeleteEntity(spawnedMarker)
            spawnedMarker = nil
        end
    end)
end

exports('useForensicItem', function(data, slot)
    local itemName = data and data.name
    local config = itemName and ItemActions[itemName]
    if not config then
        return
    end

    local usageCfg = ForensicItemUsageMap and ForensicItemUsageMap[itemName] or nil
    local preAction = usageCfg and usageCfg.action or nil

    if preAction and usageCfg and usageCfg.serverValidate then
        local check = lib.callback.await(resourceName .. ':server:validateActionItems', false, preAction)
        if not check or not check.success then
            lib.notify({
                title = L('ui.system_name'),
                description = check and check.error or 'Item obrigatório não encontrado.',
                type = 'error',
            })
            return
        end
    end

    if not playItemAnimation(config) then
        return
    end

    local nearbyEvidence = type(GetClosestWorldEvidence) == 'function' and GetClosestWorldEvidence(3.5, itemName) or nil
    local itemExecution = nil

    if usageCfg and usageCfg.serverValidate then
        itemExecution = lib.callback.await(resourceName .. ':server:executeItemUse', false, {
            itemName = itemName,
            action = preAction,
            slot = slot,
            evidenceId = nearbyEvidence and nearbyEvidence.id or nil,
            coords = GetEntityCoords(PlayerPedId()),
        })

        if not itemExecution or not itemExecution.success then
            lib.notify({
                title = L('ui.system_name'),
                description = itemExecution and itemExecution.error or 'Ação forense inválida.',
                type = 'error',
            })
            return
        end
    end

    if itemName == 'forensic_tablet' or config.openUi then
        clearEquippedTool()
        OpenForensicsUI('scenes')
    elseif itemName == 'forensic_camera' or itemName == 'forensic_flashlight' then
        local isSameTool = equippedTool.itemName == itemName and equippedTool.entity and DoesEntityExist(equippedTool.entity)

        if isSameTool then
            clearEquippedTool()

            lib.notify({
                title = L('ui.system_name'),
                description = itemName == 'forensic_camera'
                    and 'Câmera forense guardada.'
                    or 'Lanterna forense guardada.',
                type = 'warning',
            })
            return
        end

        local propModel = config.prop
        if itemName == 'forensic_flashlight' then
            propModel = 'w_am_digiflashlight'
        end

        local equipped = equipTool(itemName, propModel)
        lib.notify({
            title = L('ui.system_name'),
            description = equipped
                and (itemName == 'forensic_camera' and 'Câmera forense equipada.' or 'Lanterna forense equipada — vestígios próximos serão destacados.')
                or 'Não foi possível equipar o item na mão.',
            type = equipped and 'inform' or 'error',
            duration = 3000,
        })

        if not equipped then
            return
        end

        TriggerServerEvent(resourceName .. ':server:itemUsed', itemName, slot)
        return
    elseif itemName == 'evidence_marker' and (not itemExecution or not itemExecution.markerCreated) then
        clearEquippedTool()
        placeEvidenceMarker()
    else
        clearEquippedTool()
    end

    lib.notify({
        title = L('ui.system_name'),
        description = L(config.notifyKey),
        type = 'success',
    })

    TriggerServerEvent(resourceName .. ':server:itemUsed', itemName, slot)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= resourceName then return end
    clearEquippedTool()
end)
