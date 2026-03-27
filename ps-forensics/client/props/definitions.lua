-- ============================================================
-- PS-FORENSICS — Definições de Props 3D (client/props/definitions.lua)
--
-- Este módulo centraliza os modelos de props usados para
-- representar vestígios e ferramentas forenses no mundo do jogo.
--
-- Inspirado na arquitetura do lsn-evidence (noobsystems/evidences):
--   • props visuais de vestígios no chão (cápsulas, manchas)
--   • props de ferramentas anexados ao ped (scanner, swab, bag)
--   • decals de sangue como alternativa a DrawMarker tipo 0
--
-- Como usar (futuramente em evidence_world.lua):
--   local Props = require 'client.props.definitions'
--   local model = Props.Evidence['capsula']
--   -- CreateObject, AttachEntityToEntity, etc.
--
-- NOTA: Os props abaixo são modelos nativos do GTA V.
--       Substitua por modelos custom caso o servidor os possua.
-- ============================================================

local Props = {}

-- ============================================================
-- Props de VESTÍGIOS no mundo (visualização 3D)
-- Estes substituem/complementam os DrawMarker quando a lanterna
-- forense está ativa ou quando a evidência é de alta prioridade.
-- ============================================================
Props.Evidence = {
    -- Balística
    capsula          = `prop_cs_coke_block_01`,  -- placeholder: trocar por modelo de cápsula custom
    projetil         = `prop_cs_coke_block_01`,  -- placeholder

    -- Biológica
    -- sangue usa decal nativo (AddDecal) em vez de prop 3D
    -- ver Props.Decals abaixo

    -- Digital / Impressão
    -- impressão digital não tem prop 3D, usa apenas ox_target zone

    -- Drogas / Química
    droga_embalagem  = `prop_cs_coke_block_01`,  -- placeholder: embalagem de droga
    seringa          = `prop_cs_coke_block_01`,  -- placeholder

    -- Vestimenta / Objetos
    tecido           = `prop_cs_coke_block_01`,  -- placeholder: fragmento de tecido
    faca             = `weapon_knife`,            -- placeholder
}

-- ============================================================
-- Props de FERRAMENTAS (anexados ao ped durante coleta)
-- Inspirado em scanner.lua do lsn-evidence:
--   CreateObject → AttachEntityToEntity → bone index
-- ============================================================
Props.Tools = {
    -- Kit forense (luvas + swab) ao coletar DNA/digital
    forensic_kit     = `prop_cs_coke_block_01`,  -- placeholder: trocar por bag custom

    -- Bolsa de evidência ao finalizar coleta
    evidence_bag     = `prop_cs_coke_block_01`,  -- placeholder

    -- Scanner de digital (como p_cs_cam_phone no lsn-evidence)
    fingerprint_scanner = `p_cs_cam_phone`,

    -- Lanterna forense UV (ao ativar ToggleForensicFlashlight)
    uv_flashlight    = `prop_cs_coke_block_01`,  -- placeholder: trocar por lanterna custom
}

-- ============================================================
-- Configuração de DECALS de sangue (AddDecal)
-- Replicando o sistema do lsn-evidence/common/evidence_types.lua
-- para uso em future evidence_world.lua quando sangue spawnar.
-- ============================================================
Props.Decals = {
    sangue = {
        typeId  = 1010,        -- ID de decal de sangue nativo GTA V
        width   = 0.65,
        height  = 0.65,
        r = 0.2, g = 0.0, b = 0.0, a = 1.0,
        timeout = -1,          -- -1 = não expira automaticamente
        isLongRange = true,
    }
}

-- ============================================================
-- Parâmetros de ATTACHMENT para ferramentas ao ped
-- Bone index 28422 = mão direita (como usado no lsn-evidence)
-- ============================================================
Props.AttachParams = {
    fingerprint_scanner = {
        boneIndex = 28422,
        offset    = vec3(0.02, 0.025, -0.025),
        rotation  = vec3(-85.0, 180.0, 20.0),
    },
    evidence_bag = {
        boneIndex = 28422,
        offset    = vec3(0.0, 0.0, -0.05),
        rotation  = vec3(0.0, 0.0, 0.0),
    },
}

return Props
