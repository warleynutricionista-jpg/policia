-- ============================================================
-- PS-FORENSICS — Biblioteca de Animações Contextuais
-- client/helpers/animations.lua
--
-- Cada item forense tem uma animação adequada ao seu uso real.
-- Em vez de usar sempre mini@repair/fixing_a_ped, agora cada
-- categoria de ação tem postura, prop e label contextual.
-- ============================================================

ForensicAnims = {}

-- ============================================================
-- CATÁLOGO DE ANIMAÇÕES POR CATEGORIA
-- ============================================================
-- field_crouch: trabalho agachado no chão (coleta de vestígios)
-- standing_tool: trabalho em pé com ferramenta na mão
-- spray_apply: aplicação de spray/reagente
-- camera_use: uso de câmera fotográfica
-- clipboard: clipboard/documento (citação, etiqueta, marcador)
-- medical_kneel: exame médico-legal ajoelhado
-- tablet_use: uso de tablet
-- flashlight_hold: segurar lanterna
-- kit_open: abrir maleta/kit
-- bag_seal: ensacar/lacrar evidência
-- ============================================================

local AnimCatalog = {
    field_crouch = {
        dict = 'anim@amb@drug_field_01@actor_a@idle_b',
        clip = 'idle_b',
        flag = 1,
        blendIn = 4.0,
        blendOut = 2.0,
        label = 'Coletando vestígio...',
        propBone = 60309,
        propOffset = vec3(0.0, 0.0, 0.02),
        propRot = vec3(0.0, 0.0, 0.0),
    },
    spray_apply = {
        dict = 'amb@world_human_drinking@coffee@male@base',
        clip = 'base',
        flag = 1,
        blendIn = 4.0,
        blendOut = 2.0,
        label = 'Aplicando reagente...',
        propBone = 57005,
        propOffset = vec3(0.0, 0.02, 0.0),
        propRot = vec3(-90.0, 0.0, 0.0),
    },
    camera_use = {
        dict = 'amb@world_human_paparazzi@male@base',
        clip = 'base',
        flag = 1,
        blendIn = 4.0,
        blendOut = 2.0,
        label = 'Fotografando evidência...',
        propBone = 57005,
        propOffset = vec3(0.12, 0.02, -0.02),
        propRot = vec3(-85.0, 0.0, 5.0),
    },
    clipboard = {
        dict = 'amb@world_human_clipboard@male@base',
        clip = 'base',
        flag = 1,
        blendIn = 4.0,
        blendOut = 2.0,
        label = 'Preenchendo documento...',
        propBone = 60309,
        propOffset = vec3(0.03, 0.03, 0.02),
        propRot = vec3(30.0, 10.0, 140.0),
    },
    medical_kneel = {
        dict = 'missambulance@doctor@kneeling@idle_a',
        clip = 'idle_a',
        flag = 1,
        blendIn = 4.0,
        blendOut = 2.0,
        label = 'Realizando exame...',
        propBone = 60309,
        propOffset = vec3(0.0, 0.05, 0.03),
        propRot = vec3(10.0, 0.0, 0.0),
    },
    kit_open = {
        dict = 'anim@heist@ornate_bank@vault_enter',
        clip = 'vault_enter',
        flag = 1,
        blendIn = 4.0,
        blendOut = 2.0,
        label = 'Preparando kit...',
        propBone = 60309,
        propOffset = vec3(0.0, 0.05, 0.02),
        propRot = vec3(20.0, 0.0, 10.0),
    },
    bag_seal = {
        dict = 'mini@repair',
        clip = 'fixing_a_ped',
        flag = 1,
        blendIn = 4.0,
        blendOut = 2.0,
        label = 'Acondicionando evidência...',
        propBone = 60309,
        propOffset = vec3(0.03, 0.03, 0.02),
        propRot = vec3(30.0, 10.0, 140.0),
    },
    standing_tool = {
        dict = 'mini@repair',
        clip = 'fixing_a_ped',
        flag = 1,
        blendIn = 4.0,
        blendOut = 2.0,
        label = 'Utilizando ferramenta...',
        propBone = 60309,
        propOffset = vec3(0.03, 0.03, 0.02),
        propRot = vec3(30.0, 10.0, 140.0),
    },
}

-- Fallback universal
local FallbackAnim = AnimCatalog.standing_tool

-- ============================================================
-- MAPEAMENTO ITEM → CATEGORIA DE ANIMAÇÃO
-- ============================================================
local ItemAnimCategory = {
    forensic_kit        = 'kit_open',
    forensic_tablet     = 'tablet_use',    -- tratado separado
    forensic_camera     = 'camera_use',
    forensic_flashlight = 'standing_tool', -- equip rápido
    forensic_tweezers   = 'field_crouch',
    disposable_gloves   = 'standing_tool',
    dna_swab            = 'field_crouch',
    blood_reagent       = 'spray_apply',
    fingerprint_kit     = 'kit_open',
    fingerprint_powder  = 'spray_apply',
    fingerprint_tape    = 'field_crouch',
    ballistic_kit       = 'kit_open',
    gsr_kit             = 'standing_tool',
    drug_test_kit       = 'standing_tool',
    evidence_bag        = 'bag_seal',
    evidence_seal       = 'bag_seal',
    evidence_tag        = 'clipboard',
    evidence_marker     = 'clipboard',
    medical_exam_case   = 'medical_kneel',
    body_bag            = 'medical_kneel',
}

-- ============================================================
-- LABELS CONTEXTUAIS POR ITEM
-- ============================================================
local ItemProgressLabel = {
    forensic_kit        = 'Preparando kit pericial...',
    forensic_camera     = 'Fotografando evidência...',
    forensic_flashlight = 'Equipando lanterna...',
    forensic_tweezers   = 'Coletando vestígio com pinça...',
    disposable_gloves   = 'Calçando luvas...',
    dna_swab            = 'Coletando amostra biológica...',
    blood_reagent       = 'Aplicando reagente...',
    fingerprint_kit     = 'Preparando kit de digitais...',
    fingerprint_powder  = 'Aplicando pó revelador...',
    fingerprint_tape    = 'Levantando impressão digital...',
    ballistic_kit       = 'Analisando evidência balística...',
    gsr_kit             = 'Testando resíduo de pólvora...',
    drug_test_kit       = 'Realizando narcoteste...',
    evidence_bag        = 'Ensacando evidência...',
    evidence_seal       = 'Lacrando evidência...',
    evidence_tag        = 'Etiquetando evidência...',
    evidence_marker     = 'Posicionando marcador...',
    medical_exam_case   = 'Realizando exame pericial...',
    body_bag            = 'Acondicionando corpo...',
}

-- ============================================================
-- FUNÇÃO PÚBLICA: getAnimForItem
-- Retorna a config de animação para um item.
-- ============================================================
function ForensicAnims.getAnimForItem(itemName)
    local cat = ItemAnimCategory[itemName]
    if not cat then return FallbackAnim end
    return AnimCatalog[cat] or FallbackAnim
end

-- ============================================================
-- FUNÇÃO PÚBLICA: getProgressLabel
-- Retorna o label contextual para a progressbar.
-- ============================================================
function ForensicAnims.getProgressLabel(itemName)
    return ItemProgressLabel[itemName] or 'Utilizando item...'
end

-- ============================================================
-- FUNÇÃO PÚBLICA: playItemAnimation
-- Executa a progressbar com animação e prop corretos para
-- o item. Retorna true se concluído, false se cancelado.
-- ============================================================
function ForensicAnims.playItemAnimation(itemName, propModel, duration)
    local animCfg = ForensicAnims.getAnimForItem(itemName)
    local label   = ForensicAnims.getProgressLabel(itemName)

    -- Carrega o dict antes de iniciar a progressbar
    lib.requestAnimDict(animCfg.dict)

    local progress = {
        duration   = duration or 2500,
        label      = label,
        useWhileDead = false,
        canCancel  = true,
        disable    = { move = true, car = true, combat = true },
        anim       = { dict = animCfg.dict, clip = animCfg.clip, flag = animCfg.flag },
    }

    if propModel then
        local modelHash = joaat(propModel)
        if IsModelInCdimage(modelHash) then
            progress.prop = {
                model  = propModel,
                bone   = animCfg.propBone or 60309,
                pos    = animCfg.propOffset or vec3(0.03, 0.03, 0.02),
                rot    = animCfg.propRot    or vec3(30.0, 10.0, 140.0),
            }
        end
    end

    return lib.progressBar(progress)
end
