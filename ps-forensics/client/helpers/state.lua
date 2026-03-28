-- ============================================================
-- PS-FORENSICS — Estado do Jogador em Campo
-- client/helpers/state.lua
--
-- Rastreia estados temporários que afetam o fluxo de coleta:
--   • luvas calçadas (necessário para coletas biológicas)
--   • estágio da digital (nenhum → pó_aplicado → pronto_para_levantar)
--   • ferramenta equipada (câmera, lanterna)
--   • evidência alvo fixada
-- ============================================================

ForensicState = {}

-- ============================================================
-- ESTADO DAS LUVAS
-- ============================================================
local _glovesEquipped = false
local _glovesExpireAt = 0     -- GetGameTimer() + duração (0 = sem expiração)
local GLOVES_DURATION = 15 * 60 * 1000  -- 15 minutos

function ForensicState.setGloves(equipped)
    _glovesEquipped = equipped
    _glovesExpireAt = equipped and (GetGameTimer() + GLOVES_DURATION) or 0
end

function ForensicState.hasGloves()
    if not _glovesEquipped then return false end
    if _glovesExpireAt > 0 and GetGameTimer() > _glovesExpireAt then
        _glovesEquipped = false
        return false
    end
    return true
end

function ForensicState.glovesSecondsLeft()
    if not _glovesEquipped or _glovesExpireAt == 0 then return 0 end
    local ms = _glovesExpireAt - GetGameTimer()
    return ms > 0 and math.ceil(ms / 1000) or 0
end

-- ============================================================
-- ESTÁGIO DA IMPRESSÃO DIGITAL
-- Fluxo:    nil → 'powder_applied' → 'ready_to_lift'
-- Evidência: guardamos o ID do vestígio alvo para garantir
--            que o jogador está trabalhando no mesmo ponto.
-- ============================================================
local _fpStage     = nil   -- nil | 'powder_applied' | 'ready_to_lift'
local _fpTargetId  = nil   -- ID da evidência no mundo

function ForensicState.getFingerprintStage()
    return _fpStage, _fpTargetId
end

function ForensicState.advanceFingerprintStage(evidenceId)
    if _fpStage == nil then
        _fpStage    = 'powder_applied'
        _fpTargetId = evidenceId
    elseif _fpStage == 'powder_applied' then
        -- só avança se for a mesma evidência
        if _fpTargetId == evidenceId or evidenceId == nil then
            _fpStage = 'ready_to_lift'
        end
    end
    return _fpStage
end

function ForensicState.resetFingerprintStage()
    _fpStage    = nil
    _fpTargetId = nil
end

function ForensicState.fingerprintStageLabel()
    if _fpStage == nil then
        return 'Pó ainda não aplicado'
    elseif _fpStage == 'powder_applied' then
        return 'Pó aplicado — use a fita para levantar'
    elseif _fpStage == 'ready_to_lift' then
        return 'Pronto para registro'
    end
    return ''
end

-- ============================================================
-- FERRAMENTA EQUIPADA NA MÃO
-- ============================================================
local _equippedTool = { itemName = nil, entity = nil }

function ForensicState.getEquippedTool()
    return _equippedTool
end

function ForensicState.setEquippedTool(itemName, entity)
    _equippedTool.itemName = itemName
    _equippedTool.entity   = entity
end

function ForensicState.clearEquippedTool()
    if _equippedTool.entity and DoesEntityExist(_equippedTool.entity) then
        DeleteEntity(_equippedTool.entity)
    end
    _equippedTool.itemName = nil
    _equippedTool.entity   = nil
end

-- ============================================================
-- MARCADORES DE CENA SPAWADOS
-- ============================================================
local _spawnedMarkers = {}  -- lista de entities criadas

function ForensicState.addMarker(entity)
    _spawnedMarkers[#_spawnedMarkers + 1] = entity
end

function ForensicState.clearAllMarkers()
    for _, ent in ipairs(_spawnedMarkers) do
        if DoesEntityExist(ent) then DeleteEntity(ent) end
    end
    _spawnedMarkers = {}
end

function ForensicState.markerCount()
    return #_spawnedMarkers
end

-- ============================================================
-- CLEANUP ao parar o recurso
-- ============================================================
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    ForensicState.clearEquippedTool()
    ForensicState.clearAllMarkers()
    ForensicState.resetFingerprintStage()
    ForensicState.setGloves(false)
end)
