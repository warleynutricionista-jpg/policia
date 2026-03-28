-- ============================================================
-- PS-FORENSICS — Efeitos de Partículas e Feedback Visual
-- client/helpers/particles.lua
--
-- Efeitos visuais breves e profissionais para ações forenses:
--   • reagente de sangue: brilho vermelho sutil
--   • pó de impressão digital: nuvem fina de pó escuro
--   • flash de câmera: clarão branco momentâneo
--   • confirmação de coleta: brilho verde sutil
-- ============================================================

ForensicParticles = {}

-- ============================================================
-- HELPER INTERNO — spawn de looped ptfx no mundo
-- ============================================================
local function spawnWorldPtfx(asset, effect, coords, scale, duration)
    if not RequestNamedPtfxAsset then return end
    RequestNamedPtfxAsset(asset)
    local timeout = GetGameTimer() + 3000
    while not HasNamedPtfxAssetLoaded(asset) do
        Wait(10)
        if GetGameTimer() > timeout then return end
    end

    UseParticleFxAssetNextCall(asset)
    local handle = StartParticleFxLoopedAtCoord(
        effect,
        coords.x, coords.y, coords.z,
        0.0, 0.0, 0.0,
        scale,
        false, false, false, false
    )

    if duration and duration > 0 then
        SetTimeout(duration, function()
            if DoesParticleFxLoopedExist(handle) then
                StopParticleFxLooped(handle, false)
            end
        end)
    end

    RemoveNamedPtfxAsset(asset)
    return handle
end

-- ============================================================
-- HELPER INTERNO — ptfx não-looped (one-shot)
-- ============================================================
local function burstPtfx(asset, effect, coords, scale)
    if not RequestNamedPtfxAsset then return end
    RequestNamedPtfxAsset(asset)
    local timeout = GetGameTimer() + 3000
    while not HasNamedPtfxAssetLoaded(asset) do
        Wait(10)
        if GetGameTimer() > timeout then return end
    end

    UseParticleFxAssetNextCall(asset)
    StartParticleFxNonLoopedAtCoord(
        effect,
        coords.x, coords.y, coords.z,
        0.0, 0.0, 0.0,
        scale,
        false, false, false
    )

    RemoveNamedPtfxAsset(asset)
end

-- ============================================================
-- EFEITO: Revelação de reagente de sangue
-- Brilho vermelho pulsante breve no local da evidência
-- ============================================================
function ForensicParticles.bloodReagentReveal(coords)
    CreateThread(function()
        burstPtfx('core', 'blood_drip_artery', coords, 0.3)
        Wait(200)
        burstPtfx('core', 'blood_drip_artery', coords, 0.2)
    end)
end

-- ============================================================
-- EFEITO: Aplicação de pó revelador de digital
-- Pequena nuvem cinza/negra sobre a superfície
-- ============================================================
function ForensicParticles.fingerprintPowder(coords)
    CreateThread(function()
        burstPtfx('core', 'exp_grd_smoke', coords, 0.15)
    end)
end

-- ============================================================
-- EFEITO: Flash de câmera forense
-- Usa scaleform para simular clarão de câmera
-- ============================================================
function ForensicParticles.cameraFlash()
    CreateThread(function()
        local scaleform = RequestScaleformMovie('FLASH')
        local t = GetGameTimer() + 2000
        while not HasScaleformMovieLoaded(scaleform) do
            Wait(10)
            if GetGameTimer() > t then return end
        end

        BeginScaleformMovieMethod(scaleform, 'PLAY_SEQUENCE')
        ScaleformMovieMethodAddParamInt(0)
        EndScaleformMovieMethod()
        DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 200, 0)
        Wait(100)
        DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 0, 0)
        SetScaleformMovieAsNoLongerNeeded(scaleform)
    end)
end

-- ============================================================
-- EFEITO: Confirmação de coleta bem-sucedida
-- Pequeno brilho dourado/branco no ponto de coleta
-- ============================================================
function ForensicParticles.collectSuccess(coords)
    CreateThread(function()
        burstPtfx('core', 'sparkle_trail', coords, 0.25)
    end)
end

-- ============================================================
-- EFEITO: GSR — nuvem fina de teste de pólvora
-- ============================================================
function ForensicParticles.gsrTest(coords)
    CreateThread(function()
        burstPtfx('core', 'exp_grd_bzgas_cloud', coords, 0.08)
    end)
end
