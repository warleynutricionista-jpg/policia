-- ============================================================
-- PS-FORENSICS — Uso de Itens Forenses (Client)
-- client/items.lua
--
-- Fluxo por item:
--   1. Validação de contexto (job, luvas, estágio)
--   2. Animação contextual com prop correto
--   3. Validação / consumo server-side
--   4. Efeito visual (partícula, flash, highlight)
--   5. Feedback contextual
--   6. Cleanup de estado
-- ============================================================

local resourceName = GetCurrentResourceName()
local forensicCameraMode = {
    active = false,
    cam = nil,
    photosTaken = 0,
}
local forensicFlashlight = {
    auxLight = false,
}

local glovesVisualState = {
    applied = false,
    componentId = nil,
    drawable = nil,
    texture = nil,
}

local function getGloveOutfitConfig(ped)
    local cfg = Config.DisposableGlovesOutfit or {}
    if cfg.Enabled == false then return nil end

    local model = GetEntityModel(ped)
    local variant = cfg.Female
    if model == `mp_m_freemode_01` then
        variant = cfg.Male
    elseif model == `mp_f_freemode_01` then
        variant = cfg.Female
    end

    if not variant or variant.drawable == nil then return nil end

    return {
        componentId = tonumber(cfg.ComponentId) or 3,
        drawable = tonumber(variant.drawable),
        texture = tonumber(variant.texture) or 0,
    }
end

local function applyDisposableGlovesVisual()
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return end

    local outfit = getGloveOutfitConfig(ped)
    if not outfit then return end

    glovesVisualState.componentId = outfit.componentId
    glovesVisualState.drawable = GetPedDrawableVariation(ped, outfit.componentId)
    glovesVisualState.texture = GetPedTextureVariation(ped, outfit.componentId)

    SetPedComponentVariation(ped, outfit.componentId, outfit.drawable, outfit.texture, 0)
    glovesVisualState.applied = true
end

local function clearDisposableGlovesVisual()
    if not glovesVisualState.applied then return end

    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return end

    if glovesVisualState.componentId ~= nil and glovesVisualState.drawable ~= nil and glovesVisualState.texture ~= nil then
        SetPedComponentVariation(ped, glovesVisualState.componentId, glovesVisualState.drawable, glovesVisualState.texture, 0)
    end

    glovesVisualState.applied = false
    glovesVisualState.componentId = nil
    glovesVisualState.drawable = nil
    glovesVisualState.texture = nil
end

-- ============================================================
-- MAPA DE PROPS POR ITEM (modelos nativos GTA V confiáveis)
-- ============================================================
local ItemProps = {
    forensic_kit        = 'prop_ld_case_01',
    disposable_gloves   = 'prop_cs_gloves_01',
    evidence_bag        = 'prop_evidence_bag_01',       -- fallback: xm3_prop_xm3_evidence_case_01a
    evidence_seal       = 'prop_notepad_01',
    evidence_tag        = 'prop_notepad_01',
    dna_swab            = 'prop_cs_mop_s',
    fingerprint_kit     = 'prop_cs_fingerprint',
    fingerprint_powder  = 'bkr_prop_coke_bakingsoda_o',
    fingerprint_tape    = 'prop_tapeplayer_01',
    blood_reagent       = 'prop_cs_spray_can',
    gsr_kit             = 'prop_cs_box_clothes',
    drug_test_kit       = 'prop_mp_drug_pack_blue',
    forensic_tweezers   = 'prop_pencil_01',
    forensic_camera     = 'prop_pap_camera_01',
    evidence_marker     = 'prop_mp_num_6',
    medical_exam_case   = 'prop_ld_case_01',
    body_bag            = 'prop_ld_case_01',
    forensic_flashlight = 'prop_cs_police_torch',
    ballistic_kit       = 'prop_idol_case_01',
    forensic_tablet     = 'prop_cs_tablet',
}

-- Props com fallback (tenta o principal, usa fallback se não existir no cdimage)
local ItemPropFallback = {
    evidence_bag        = 'xm3_prop_xm3_evidence_case_01a',
    medical_exam_case   = 'xm_prop_smug_crate_s_medical',
    forensic_flashlight = 'w_me_flashlight',
    forensic_camera     = 'prop_pap_camera_01',
}

local function resolveItemProp(itemName)
    local main = ItemProps[itemName]
    if main then
        if IsModelInCdimage(joaat(main)) then return main end
        local fallback = ItemPropFallback[itemName]
        if fallback and IsModelInCdimage(joaat(fallback)) then return fallback end
    end
    return nil
end

-- ============================================================
-- DURATIONS POR ITEM (ms)
-- ============================================================
local ItemDuration = {
    forensic_kit        = 2500,
    disposable_gloves   = 1800,
    evidence_bag        = 2200,
    evidence_seal       = 1500,
    evidence_tag        = 1400,
    dna_swab            = 2800,
    fingerprint_kit     = 3000,
    fingerprint_powder  = 2500,
    fingerprint_tape    = 2000,
    blood_reagent       = 2500,
    gsr_kit             = 2800,
    drug_test_kit       = 2600,
    forensic_tweezers   = 2000,
    forensic_camera     = 1500,
    evidence_marker     = 1600,
    medical_exam_case   = 3500,
    body_bag            = 3000,
    forensic_flashlight = 800,
    ballistic_kit       = 2800,
    forensic_tablet     = 1500,
}

-- ============================================================
-- ITENS QUE PRECISAM DE LUVAS EQUIPADAS
-- ============================================================
local RequiresGloves = {
    dna_swab            = true,
    blood_reagent       = true,
    fingerprint_powder  = true,
    fingerprint_tape    = true,
    forensic_tweezers   = true,
    gsr_kit             = true,
    drug_test_kit       = true,
    evidence_bag        = true,
    evidence_seal       = true,
    evidence_tag        = true,
    medical_exam_case   = true,
    body_bag            = true,
}

-- ============================================================
-- NOTIFICAÇÕES CONTEXTUAIS
-- ============================================================
local SuccessMessages = {
    disposable_gloves   = { title = 'Luvas Calçadas', desc = 'Proteção ativa. Pronto para coleta.', icon = '🧤' },
    forensic_kit        = { title = 'Kit Pericial', desc = 'Kit aberto. Procedimentos habilitados.', icon = '🧳' },
    dna_swab            = { title = 'DNA Coletado', desc = 'Amostra biológica armazenada com segurança.', icon = '🧬' },
    blood_reagent       = { title = 'Vestígio Revelado', desc = 'Reagente positivo. Sangue detectado na área.', icon = '🩸' },
    fingerprint_powder  = { title = 'Pó Aplicado', desc = 'Impressão revelada. Use a fita para levantar.', icon = '🖐' },
    fingerprint_tape    = { title = 'Digital Levantada', desc = 'Impressão coletada e registrada.', icon = '🖐' },
    fingerprint_kit     = { title = 'Kit de Digitais', desc = 'Kit preparado. Aplique o pó revelador.', icon = '🔍' },
    ballistic_kit       = { title = 'Análise Balística', desc = 'Vestígio balístico documentado.', icon = '🔫' },
    gsr_kit             = { title = 'Teste GSR', desc = 'Análise de resíduo concluída.', icon = '💨' },
    drug_test_kit       = { title = 'Narcoteste', desc = 'Resultado registrado para análise laboratorial.', icon = '🧪' },
    forensic_tweezers   = { title = 'Vestígio Coletado', desc = 'Material coletado com pinça e armazenado.', icon = '🔬' },
    forensic_camera     = { title = 'Câmera Equipada', desc = 'Câmera forense pronta para registro fotográfico.', icon = '📷' },
    evidence_bag        = { title = 'Evidência Ensacada', desc = 'Material acondicionado em saco de evidência.', icon = '🗂' },
    evidence_seal       = { title = 'Evidência Lacrada', desc = 'Cadeia de custódia mantida. Lacre aplicado.', icon = '🔒' },
    evidence_tag        = { title = 'Etiqueta Aplicada', desc = 'Evidência identificada e rastreável.', icon = '🏷' },
    evidence_marker     = { title = 'Marcador Posicionado', desc = 'Vestígio sinalizado para documentação fotográfica.', icon = '📍' },
    medical_exam_case   = { title = 'Exame Iniciado', desc = 'Procedimento médico-legal em andamento.', icon = '🩺' },
    body_bag            = { title = 'Corpo Acondicionado', desc = 'Remoção registrada e corpo preservado.', icon = '📦' },
    forensic_flashlight = { title = 'Lanterna Equipada', desc = 'Modo de inspeção ativo.', icon = '🔦' },
    forensic_tablet     = { title = 'Tablet', desc = 'Sistema forense aberto.', icon = '💻' },
}

local function notifySuccess(itemName, override)
    local msg = override or SuccessMessages[itemName]
    if not msg then
        lib.notify({ title = 'Sistema Forense', description = 'Ação concluída.', type = 'success' })
        return
    end
    lib.notify({
        title       = msg.title,
        description = msg.desc,
        type        = 'success',
        duration    = 4000,
    })
end

local function notifyError(desc, title)
    lib.notify({
        title       = title or 'Sistema Forense',
        description = desc,
        type        = 'error',
        duration    = 4000,
    })
end

local function notifyInfo(desc, title)
    lib.notify({
        title       = title or 'Sistema Forense',
        description = desc,
        type        = 'inform',
        duration    = 4000,
    })
end

local function stopForensicCameraMode(silent)
    if forensicCameraMode.cam and DoesCamExist(forensicCameraMode.cam) then
        RenderScriptCams(false, true, 200, true, true)
        DestroyCam(forensicCameraMode.cam, false)
    end

    forensicCameraMode.active = false
    forensicCameraMode.cam = nil

    if not silent then
        notifyInfo('Modo de documentação finalizado.', 'Câmera Forense')
    end
end

local function captureForensicPhoto()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    forensicCameraMode.photosTaken = forensicCameraMode.photosTaken + 1

    if ForensicParticles and ForensicParticles.cameraFlash then
        ForensicParticles.cameraFlash()
    end

    local function getCaptureTimestamp()
        if type(os) == 'table' and type(os.time) == 'function' then
            return os.time()
        end

        local cloudTime = GetCloudTimeAsInt()
        if cloudTime and cloudTime > 0 then
            return cloudTime
        end

        return nil
    end

    local capturedAt = getCaptureTimestamp()

    if GetResourceState('screenshot-basic') == 'started' then
        exports['screenshot-basic']:requestScreenshot(function(imageData)
            TriggerServerEvent(resourceName .. ':server:forensicPhotoCaptured', {
                photoNumber = forensicCameraMode.photosTaken,
                via = 'screenshot-basic',
                imageData = imageData,
                coords = { x = coords.x, y = coords.y, z = coords.z },
                heading = heading,
                capturedAt = capturedAt,
            })
        end)
    else
        TriggerServerEvent(resourceName .. ':server:forensicPhotoCaptured', {
            photoNumber = forensicCameraMode.photosTaken,
            via = 'camera-mode',
            coords = { x = coords.x, y = coords.y, z = coords.z },
            heading = heading,
            capturedAt = capturedAt,
        })
    end

    lib.notify({
        title = 'Foto Pericial Registrada',
        description = ('Registro #%d capturado.'):format(forensicCameraMode.photosTaken),
        type = 'success',
        duration = 3000,
    })
end

local function startForensicCameraMode()
    if forensicCameraMode.active then return end

    local ped = PlayerPedId()
    forensicCameraMode.cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    AttachCamToEntity(forensicCameraMode.cam, ped, 0.0, 0.55, 0.7, true)
    SetCamRot(forensicCameraMode.cam, GetGameplayCamRot(2), 2)
    SetCamFov(forensicCameraMode.cam, 45.0)
    RenderScriptCams(true, true, 250, true, true)

    forensicCameraMode.active = true

    CreateThread(function()
        while forensicCameraMode.active do
            Wait(0)
            HideHudAndRadarThisFrame()
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 44, true)
            DisablePlayerFiring(PlayerPedId(), true)

            local gameplayRot = GetGameplayCamRot(2)
            SetCamRot(forensicCameraMode.cam, gameplayRot.x, gameplayRot.y, gameplayRot.z, 2)

            lib.showTextUI('[E] Capturar foto  •  [BACKSPACE] Sair', {
                position = 'right-center',
                icon = 'camera',
            })

            if IsDisabledControlJustPressed(0, 38) then
                captureForensicPhoto()
            elseif IsControlJustPressed(0, 177) then
                lib.hideTextUI()
                stopForensicCameraMode()
                break
            end
        end

        lib.hideTextUI()
    end)
end

local function setForensicAuxLightEnabled(state)
    forensicFlashlight.auxLight = state == true
end

CreateThread(function()
    while true do
        if forensicFlashlight.auxLight and IsForensicFlashlightActive and IsForensicFlashlightActive() then
            Wait(0)
            local ped = PlayerPedId()
            if not DoesEntityExist(ped) then goto continue end

            local origin = GetEntityCoords(ped)
            local forward = GetEntityForwardVector(ped)
            local target = origin + (forward * 12.0)

            DrawSpotLight(
                origin.x, origin.y, origin.z + 0.65,
                forward.x, forward.y, forward.z,
                190, 210, 255,
                25.0, 6.0, 0.0, 22.0, 28.0
            )

            DrawLightWithRangeAndShadow(
                target.x, target.y, target.z,
                160, 185, 255,
                5.0,
                8.0,
                1.0
            )
            ::continue::
        else
            Wait(350)
        end
    end
end)

-- ============================================================
-- HELPERS LOCAIS DE FERRAMENTA EQUIPADA
-- (delegam para ForensicState)
-- ============================================================
local function equipTool(itemName, propModel)
    ForensicState.clearEquippedTool()

    local attach = {
        forensic_camera     = { bone = 57005, pos = vec3(0.12, 0.02, -0.02),  rot = vec3(-85.0, 0.0, 5.0)  },
        forensic_flashlight = { bone = 57005, pos = vec3(0.1, 0.02, -0.02),   rot = vec3(-90.0, 0.0, 0.0)  },
    }

    local cfg = attach[itemName]
    if not cfg then return false end

    local modelHash = joaat(propModel)
    if not IsModelInCdimage(modelHash) then return false end

    lib.requestModel(propModel)
    local ped    = PlayerPedId()
    local entity = CreateObject(modelHash, 0.0, 0.0, 0.0, true, true, false)
    if not entity or not DoesEntityExist(entity) then return false end

    AttachEntityToEntity(
        entity, ped,
        GetPedBoneIndex(ped, cfg.bone),
        cfg.pos.x, cfg.pos.y, cfg.pos.z,
        cfg.rot.x, cfg.rot.y, cfg.rot.z,
        true, true, false, true, 1, true
    )

    ForensicState.setEquippedTool(itemName, entity)

    if itemName == 'forensic_flashlight' then
        SetFlashLightKeepOnWhileMoving(true)
        if type(ToggleForensicFlashlight) == 'function' then
            ToggleForensicFlashlight(true)
        end
    end

    return true
end

-- ============================================================
-- COLOCAR MARCADOR FÍSICO NO CHÃO
-- Suporta múltiplos marcadores por cena (sem apagar os anteriores)
-- ============================================================
local function placeEvidenceMarker()
    local ped    = PlayerPedId()
    local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.7, -1.0)
    local model  = joaat('prop_mp_num_6')

    RequestModel(model)
    local t = GetGameTimer() + 3000
    while not HasModelLoaded(model) do
        Wait(10)
        if GetGameTimer() > t then return end
    end

    local marker = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
    PlaceObjectOnGroundProperly(marker)
    SetModelAsNoLongerNeeded(model)

    ForensicState.addMarker(marker)

    -- Remove marcador após 10 minutos
    local markerRef = marker
    SetTimeout(600000, function()
        if DoesEntityExist(markerRef) then DeleteEntity(markerRef) end
    end)
end

-- ============================================================
-- EXPORTAÇÃO PRINCIPAL: useForensicItem
-- ============================================================
local function handleForensicItemUse(data, slot)
    local itemName = data and data.name
    if not itemName then return end

    local usageCfg = ForensicItemUsageMap and ForensicItemUsageMap[itemName]
    local action   = usageCfg and usageCfg.action

    -- ── 1. Luvas obrigatórias ─────────────────────────────────
    if RequiresGloves[itemName] and not ForensicState.hasGloves() then
        notifyError(
            'Calce as luvas descartáveis antes de coletar evidências.',
            'Proteção Necessária'
        )
        return
    end

    -- ── 2. Validação prévia server (dry-run) ──────────────────
    if usageCfg and usageCfg.serverValidate then
        local check = lib.callback.await(resourceName .. ':server:validateActionItems', false, action)
        if not check or not check.success then
            notifyError(check and check.error or 'Item obrigatório não encontrado.')
            return
        end
    end

    -- ── 3. Fluxo especial: tablet ─────────────────────────────
    if itemName == 'forensic_tablet' then
        ForensicState.clearEquippedTool()
        if ForensicAnims.playItemAnimation(itemName, resolveItemProp(itemName), ItemDuration[itemName]) then
            OpenForensicsUI('scenes')
        end
        return
    end

    -- ── 4. Fluxo especial: câmera / lanterna (toggle) ─────────
    if itemName == 'forensic_camera' or itemName == 'forensic_flashlight' then
        local tool = ForensicState.getEquippedTool()
        if tool.itemName == itemName and tool.entity and DoesEntityExist(tool.entity) then
            -- Já equipado → guarda
            ForensicState.clearEquippedTool()
            if itemName == 'forensic_flashlight' then
                SetFlashLightKeepOnWhileMoving(false)
                if type(ToggleForensicFlashlight) == 'function' then ToggleForensicFlashlight(false) end
                setForensicAuxLightEnabled(false)
            else
                stopForensicCameraMode(true)
            end
            notifyInfo(
                itemName == 'forensic_camera' and 'Câmera guardada.' or 'Lanterna guardada.',
                'Ferramenta'
            )
            return
        end

        -- Animação rápida de equipar
        if not ForensicAnims.playItemAnimation(itemName, resolveItemProp(itemName), ItemDuration[itemName]) then
            return
        end

        local ok = equipTool(itemName, resolveItemProp(itemName) or ItemProps[itemName])
        if itemName == 'forensic_camera' and ok then
            startForensicCameraMode()
            TriggerEvent(resourceName .. ':client:forensicCameraMode', true)
        elseif itemName == 'forensic_flashlight' and ok then
            setForensicAuxLightEnabled(true)
            TriggerEvent(resourceName .. ':client:forensicFlashlightMode', true)
        end

        lib.notify({
            title       = ok and (itemName == 'forensic_camera' and 'Câmera Equipada' or 'Lanterna Equipada') or 'Falha',
            description = ok
                and (itemName == 'forensic_camera'
                    and 'Câmera forense pronta. Documente os vestígios.'
                    or 'Lanterna forense ativa. Vestígios próximos serão destacados.')
                or 'Não foi possível equipar o item.',
            type        = ok and 'success' or 'error',
            duration    = 3500,
        })

        if ok then TriggerServerEvent(resourceName .. ':server:itemUsed', itemName, slot) end
        return
    end

    -- ── 5. Fluxo especial: luvas ──────────────────────────────
    if itemName == 'disposable_gloves' then
        if ForensicState.hasGloves() then
            local secs = ForensicState.glovesSecondsLeft()
            notifyInfo(
                ('Luvas já calçadas. Tempo restante: ~%d min.'):format(math.ceil(secs / 60)),
                'Luvas'
            )
            return
        end

        if not ForensicAnims.playItemAnimation(itemName, resolveItemProp(itemName), ItemDuration[itemName]) then
            return
        end

        local exec = lib.callback.await(resourceName .. ':server:executeItemUse', false, {
            itemName = itemName,
            action   = action,
            slot     = slot,
            coords   = GetEntityCoords(PlayerPedId()),
        })
        if not exec or not exec.success then
            notifyError(exec and exec.error or 'Falha ao usar luvas.')
            return
        end

        ForensicState.setGloves(true)
        applyDisposableGlovesVisual()
        notifySuccess('disposable_gloves')
        TriggerServerEvent(resourceName .. ':server:itemUsed', itemName, slot)
        return
    end

    -- ── 6. Fluxo especial: pó revelador (digital) ─────────────
    if itemName == 'fingerprint_powder' then
        local stage, targetId = ForensicState.getFingerprintStage()
        if stage == 'powder_applied' or stage == 'ready_to_lift' then
            notifyInfo('Pó já foi aplicado. Use a fita de levantamento.', 'Digitais')
            return
        end

        local nearbyEvidence = type(GetClosestWorldEvidence) == 'function'
            and GetClosestWorldEvidence(3.5, itemName) or nil

        if not nearbyEvidence then
            notifyError('Nenhuma impressão digital detectada nas proximidades.', 'Sem Alvo')
            return
        end

        if not ForensicAnims.playItemAnimation(itemName, resolveItemProp(itemName), ItemDuration[itemName]) then
            return
        end

        local exec = lib.callback.await(resourceName .. ':server:executeItemUse', false, {
            itemName   = itemName,
            action     = action,
            slot       = slot,
            evidenceId = nearbyEvidence.id,
            coords     = GetEntityCoords(PlayerPedId()),
        })
        if not exec or not exec.success then
            notifyError(exec and exec.error or 'Falha ao aplicar pó.')
            return
        end

        -- Efeito visual de pó
        ForensicParticles.fingerprintPowder(GetEntityCoords(PlayerPedId()))
        ForensicState.advanceFingerprintStage(nearbyEvidence.id)

        lib.notify({
            title       = 'Pó Revelador Aplicado',
            description = 'Impressão digital visível. Aplique a fita de levantamento para coletar.',
            type        = 'success',
            duration    = 5000,
        })
        TriggerServerEvent(resourceName .. ':server:itemUsed', itemName, slot)
        return
    end

    -- ── 7. Fluxo especial: fita de levantamento ───────────────
    if itemName == 'fingerprint_tape' then
        local stage, targetId = ForensicState.getFingerprintStage()
        if stage ~= 'powder_applied' and stage ~= 'ready_to_lift' then
            notifyError('Aplique o pó revelador primeiro.', 'Etapa Incorreta')
            return
        end

        local nearbyEvidence = type(GetClosestWorldEvidence) == 'function'
            and GetClosestWorldEvidence(3.5, itemName) or nil

        if not nearbyEvidence then
            notifyError('Nenhuma evidência próxima para levantar.', 'Sem Alvo')
            return
        end

        if not ForensicAnims.playItemAnimation(itemName, resolveItemProp(itemName), ItemDuration[itemName]) then
            return
        end

        local exec = lib.callback.await(resourceName .. ':server:executeItemUse', false, {
            itemName   = itemName,
            action     = action,
            slot       = slot,
            evidenceId = nearbyEvidence.id,
            coords     = GetEntityCoords(PlayerPedId()),
        })
        if not exec or not exec.success then
            notifyError(exec and exec.error or 'Falha ao levantar digital.')
            return
        end

        ForensicParticles.collectSuccess(GetEntityCoords(PlayerPedId()))
        ForensicState.resetFingerprintStage()

        lib.notify({
            title       = 'Digital Levantada',
            description = 'Impressão coletada e adicionada ao sistema forense.',
            type        = 'success',
            duration    = 5000,
        })
        TriggerServerEvent(resourceName .. ':server:itemUsed', itemName, slot)
        return
    end

    -- ── 8. Fluxo especial: reagente de sangue ─────────────────
    if itemName == 'blood_reagent' then
        local nearbyEvidence = type(GetClosestWorldEvidence) == 'function'
            and GetClosestWorldEvidence(3.5, itemName) or nil

        if not nearbyEvidence then
            notifyError('Nenhuma área suspeita para aplicar reagente.', 'Sem Alvo')
            return
        end

        if not ForensicAnims.playItemAnimation(itemName, resolveItemProp(itemName), ItemDuration[itemName]) then
            return
        end

        local exec = lib.callback.await(resourceName .. ':server:executeItemUse', false, {
            itemName   = itemName,
            action     = action,
            slot       = slot,
            evidenceId = nearbyEvidence.id,
            coords     = GetEntityCoords(PlayerPedId()),
        })
        if not exec or not exec.success then
            notifyError(exec and exec.error or 'Reagente sem resultado.')
            return
        end

        ForensicParticles.bloodReagentReveal(GetEntityCoords(PlayerPedId()))

        lib.notify({
            title       = 'Sangue Detectado',
            description = 'Reagente positivo. Vestígio biológico confirmado e revelado.',
            type        = 'success',
            duration    = 5500,
        })
        TriggerServerEvent(resourceName .. ':server:itemUsed', itemName, slot)
        return
    end

    -- ── 9. Fluxo especial: marcador de evidência ──────────────
    if itemName == 'evidence_marker' then
        if not ForensicAnims.playItemAnimation(itemName, resolveItemProp(itemName), ItemDuration[itemName]) then
            return
        end

        local exec = lib.callback.await(resourceName .. ':server:executeItemUse', false, {
            itemName = itemName,
            action   = action,
            slot     = slot,
            coords   = GetEntityCoords(PlayerPedId()),
        })
        if not exec or not exec.success then
            notifyError(exec and exec.error or 'Falha ao posicionar marcador.')
            return
        end

        placeEvidenceMarker()
        local count = ForensicState.markerCount()

        lib.notify({
            title       = 'Marcador #' .. count .. ' Posicionado',
            description = 'Vestígio sinalizado para documentação fotográfica.',
            type        = 'success',
            duration    = 4000,
        })
        TriggerServerEvent(resourceName .. ':server:itemUsed', itemName, slot)
        return
    end

    -- ── 10. Fluxo especial: GSR ───────────────────────────────
    if itemName == 'gsr_kit' then
        if not ForensicAnims.playItemAnimation(itemName, resolveItemProp(itemName), ItemDuration[itemName]) then
            return
        end

        local exec = lib.callback.await(resourceName .. ':server:executeItemUse', false, {
            itemName   = itemName,
            action     = action,
            slot       = slot,
            evidenceId = (type(GetClosestWorldEvidence) == 'function' and GetClosestWorldEvidence(3.5, itemName) or {}).id,
            coords     = GetEntityCoords(PlayerPedId()),
        })
        if not exec or not exec.success then
            notifyError(exec and exec.error or 'Teste GSR inconclusivo.')
            return
        end

        ForensicParticles.gsrTest(GetEntityCoords(PlayerPedId()))
        notifySuccess('gsr_kit')
        TriggerServerEvent(resourceName .. ':server:itemUsed', itemName, slot)
        return
    end

    -- ── 11. Fluxo GENÉRICO (todos os demais) ──────────────────
    local nearbyEvidence = nil
    if usageCfg and usageCfg.requiresTarget then
        nearbyEvidence = type(GetClosestWorldEvidence) == 'function'
            and GetClosestWorldEvidence(3.5, itemName) or nil

        if not nearbyEvidence then
            notifyError('Nenhuma evidência compatível nas proximidades.', 'Sem Alvo')
            return
        end
    end

    if not ForensicAnims.playItemAnimation(itemName, resolveItemProp(itemName), ItemDuration[itemName]) then
        return
    end

    if usageCfg and usageCfg.serverValidate then
        local exec = lib.callback.await(resourceName .. ':server:executeItemUse', false, {
            itemName   = itemName,
            action     = action,
            slot       = slot,
            evidenceId = nearbyEvidence and nearbyEvidence.id or nil,
            coords     = GetEntityCoords(PlayerPedId()),
        })
        if not exec or not exec.success then
            notifyError(exec and exec.error or 'Ação forense inválida.')
            return
        end

        -- Efeito de coleta bem-sucedida para itens coletores
        if usageCfg.effect == 'collect' then
            ForensicParticles.collectSuccess(GetEntityCoords(PlayerPedId()))
        end
    end

    ForensicState.clearEquippedTool()
    notifySuccess(itemName)
    TriggerServerEvent(resourceName .. ':server:itemUsed', itemName, slot)
end

exports('useForensicItem', function(data, slot)
    return handleForensicItemUse(data, slot)
end)

-- Compatibilidade com configurações antigas de itens ox_inventory
exports('useDisposableGloves', function(data, slot)
    if not data or not data.name then
        data = data or {}
        data.name = 'disposable_gloves'
    end

    return handleForensicItemUse(data, slot)
end)

RegisterNetEvent(resourceName .. ':client:forensicCameraMode', function(enable)
    if enable then
        startForensicCameraMode()
    else
        stopForensicCameraMode(true)
    end
end)

RegisterNetEvent(resourceName .. ':client:forensicFlashlightMode', function(enable)
    local state = enable == true
    setForensicAuxLightEnabled(state)
    if type(ToggleForensicFlashlight) == 'function' then
        ToggleForensicFlashlight(state)
    end
end)

exports('toggleForensicFlashlight', function(enable)
    TriggerEvent(resourceName .. ':client:forensicFlashlightMode', enable == true)
end)

exports('openForensicCameraMode', function()
    TriggerEvent(resourceName .. ':client:forensicCameraMode', true)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= resourceName then return end
    setForensicAuxLightEnabled(false)
    stopForensicCameraMode(true)
end)

-- ============================================================
-- CLEANUP AO PARAR O RECURSO
-- ============================================================
AddEventHandler('onResourceStop', function(resource)
    if resource ~= resourceName then return end
    ForensicState.clearEquippedTool()
    ForensicState.clearAllMarkers()
end)


CreateThread(function()
    local wasUsingGloves = false
    while true do
        Wait(1000)
        local has = ForensicState.hasGloves()
        if has then
            wasUsingGloves = true
        elseif wasUsingGloves then
            clearDisposableGlovesVisual()
            wasUsingGloves = false
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceNameStopped)
    if resourceNameStopped ~= resourceName then return end
    clearDisposableGlovesVisual()
end)
