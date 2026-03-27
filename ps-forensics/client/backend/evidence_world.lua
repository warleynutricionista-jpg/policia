-- ============================================================
-- PS-FORENSICS - Evidências de Mundo (Client)
-- Coleta automática de vestígios por eventos de jogo.
--
-- Inspirado na arquitetura do 'evidences' (noobsystems):
--   • StateBag para sincronização entre clientes
--   • Hooks de game events (dano, entrada veículo, disparo)
--   • Verificação de luvas antes de registrar digital
--   • Sistema de chance configurável (padrão renzu_evidence)
--   • Lanterna forense com highlight visual de evidências próximas
--
-- Fluxo:
--   1. Evento de jogo detectado (dano/disparo/veículo)
--   2. Verifica chance de spawn
--   3. Notifica servidor via TriggerServerEvent
--   4. Servidor registra na memória e faz broadcast para todos
--   5. Clientes recebem evento e criam zona ox_target
--   6. Policial coleta → servidor registra em forensic_evidence
-- ============================================================

local resourceName = GetCurrentResourceName()

-- ============================================================
-- ESTADO LOCAL
-- ============================================================
local worldEvidenceCache = {}    -- id -> evidenceData
local evidenceZones      = {}    -- id -> ox_target zone handle
local flashlightActive   = false -- lanterna forense ligada?
local isWorldEvidenceReady = false

-- Cooldowns por tipo (evitar spam de eventos)
local lastSpawnByType = {}

-- ============================================================
-- HELPERS: ACESSO E JOB
-- ============================================================
-- hasAccess() e getPlayerJob() definidos em client/main.lua
-- São globais dentro do mesmo resource

local function canCollect()
    -- Qualquer policial com acesso forense pode coletar
    return type(hasAccess) == 'function' and hasAccess()
end

-- ============================================================
-- HELPER: ARMA BLACKLISTADA
-- Inspirado em lsn-evidence: WhitelistedWeapons
-- Armas da lista não geram evidências balísticas
-- ============================================================
local function isWeaponBlacklisted(weapon)
    local blacklist = Config.WorldEvidence and Config.WorldEvidence.BlacklistedWeapons or {}
    for _, w in ipairs(blacklist) do
        if w == weapon then return true end
    end
    return false
end

-- ============================================================
-- HELPER: PÉ DESCALÇO
-- Inspirado em lsn-evidence: IsWearingWhitelistedShoes
-- Componente 6 = sapatos. Drawables de pé descalço não geram pegada.
-- ============================================================
local function isPlayerBarefoot(ped)
    local shoeDrawable = GetPedDrawableVariation(ped, 6)
    local model        = GetEntityModel(ped)
    local bareList     = (model == GetHashKey('mp_m_freemode_01'))
        and (Config.WorldEvidence and Config.WorldEvidence.BarehandsMaleShoes  or { 33, 34 })
        or  (Config.WorldEvidence and Config.WorldEvidence.BarefootFemaleShoes or { 34, 35 })
    for _, s in ipairs(bareList) do
        if s == shoeDrawable then return true end
    end
    return false
end

-- ============================================================
-- HELPER: LUVAS
-- Verifica se o ped local usa luvas verificando o componente 5
-- Componente 5 drawable 0 = mãos nuas = deixa digital
-- ============================================================
local function hasGloves()
    if not Config.WorldEvidence or not Config.WorldEvidence.GloveDetection then
        return false
    end
    local component     = Config.WorldEvidence.GloveComponent or 5
    local bareDrawable  = Config.WorldEvidence.BareHandsDrawable or 0
    return GetPedDrawableVariation(PlayerPedId(), component) ~= bareDrawable
end

-- ============================================================
-- HELPER: CHANCE DE SPAWN
-- ============================================================
local function rollChance(evidenceType)
    if not Config.WorldEvidence or not Config.WorldEvidence.Enabled then
        return false
    end
    local chances = Config.WorldEvidence.Chances or {}
    local chance  = chances[evidenceType] or 50
    return math.random(100) <= chance
end

-- ============================================================
-- HELPER: COOLDOWN por tipo
-- ============================================================
local function checkAndSetCooldown(evidenceType)
    local now = GetGameTimer()
    local cooldowns = (Config.WorldEvidence and Config.WorldEvidence.Cooldowns) or {}
    local cooldown  = cooldowns[evidenceType] or 2000

    if lastSpawnByType[evidenceType] and (now - lastSpawnByType[evidenceType]) < cooldown then
        return false -- ainda no cooldown
    end

    lastSpawnByType[evidenceType] = now
    return true
end

-- ============================================================
-- HELPER: NOME DA RUA
-- ============================================================
local function getStreetName(coords)
    local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    return GetStreetNameFromHashKey(streetHash) or ''
end

-- ============================================================
-- CRIAR ZONA OX_TARGET para uma evidência de mundo
-- ============================================================
local function createEvidenceZone(evData)
    if not evData or not evData.id or not evData.coords then return end

    -- Remover zona anterior se já existia (re-sync)
    if evidenceZones[evData.id] then
        pcall(function()
            exports.ox_target:removeZone(evidenceZones[evData.id])
        end)
        evidenceZones[evData.id] = nil
    end

    -- Ícone por categoria
    local iconMap = {
        biologica          = 'fa-solid fa-droplet',
        balistica          = 'fa-solid fa-gun',
        digital_impressao  = 'fa-solid fa-fingerprint',
        quimica            = 'fa-solid fa-flask',
        veiculo            = 'fa-solid fa-car',
        vestimenta         = 'fa-solid fa-shirt',
    }
    local icon  = iconMap[evData.category] or 'fa-solid fa-circle-dot'
    local label = ('[Vestígio] %s'):format(evData.type or 'Evidência')

    local ok, zoneId = pcall(function()
        return exports.ox_target:addSphereZone({
            coords  = vec3(evData.coords.x, evData.coords.y, evData.coords.z),
            radius  = 1.0,
            options = {
                {
                    name        = ('psf_wev_%s'):format(evData.id),
                    icon        = icon,
                    label       = label,
                    distance    = 2.5,
                    onSelect    = function()
                        collectWorldEvidence(evData.id)
                    end,
                    canInteract = function()
                        return canCollect()
                    end,
                },
            },
        })
    end)

    if ok and zoneId then
        evidenceZones[evData.id] = zoneId
    end
end

-- ============================================================
-- REMOVER ZONA OX_TARGET de uma evidência
-- ============================================================
local function removeEvidenceZone(evId)
    if evidenceZones[evId] then
        pcall(function()
            exports.ox_target:removeZone(evidenceZones[evId])
        end)
        evidenceZones[evId] = nil
    end
    worldEvidenceCache[evId] = nil
end

-- ============================================================
-- REGISTRAR EVIDÊNCIA LOCALMENTE
-- ============================================================
local function registerLocalEvidence(evData)
    if not evData or not evData.id then return end
    worldEvidenceCache[evData.id] = evData
    if evData.coords then
        createEvidenceZone(evData)
    end
end

-- ============================================================
-- COLETAR EVIDÊNCIA DE MUNDO (com progressBar e animação)
-- ============================================================
function collectWorldEvidence(evId)
    local evData = worldEvidenceCache[evId]
    if not evData then
        lib.notify({ title = L('ui.system_name'), description = 'Vestígio não encontrado', type = 'error' })
        return
    end

    -- Tempo de coleta baseado no tipo
    local processingKey = ({
        sangue            = 'coleta_dna',
        impressao_digital = 'coleta_digital',
        capsula           = 'analise_capsula',
        residuo_polvora   = 'residuo_polvora_maos',
    })[evData.type] or 'coleta_digital'

    local duration = ((Config.TestProcessingTimes and Config.TestProcessingTimes[processingKey]) or 8) * 1000

    -- Animação de coleta
    local animDict = 'anim@gangops@facility@servers@bodysearch@'
    lib.requestAnimDict(animDict)
    TaskPlayAnim(PlayerPedId(), animDict, 'player_search', 8.0, -8.0, duration, 49, 0, false, false, false)

    local collected = lib.progressBar({
        duration     = duration,
        label        = L('evidence.collecting'),
        useWhileDead = false,
        canCancel    = true,
        disable      = { car = true, move = true, combat = true },
        anim         = { dict = animDict, clip = 'player_search' },
    })

    ClearPedTasks(PlayerPedId())

    if not collected then
        return
    end

    local result = lib.callback.await(resourceName .. ':server:collectWorldEvidence', false, evId)

    if result and result.success then
        removeEvidenceZone(evId)
        lib.notify({
            title       = L('ui.system_name'),
            description = ('Evidência registrada: %s | Nº %s | Lacre: %s'):format(
                evData.type or '?',
                result.evidenceNumber or '?',
                result.sealNumber or '?'
            ),
            type     = 'success',
            duration = 8000,
        })
    elseif result then
        lib.notify({ title = L('ui.system_name'), description = result.error or 'Erro na coleta', type = 'error' })
    end
end

-- ============================================================
-- SINCRONIZAÇÃO: Late-joiner solicita evidências ativas
-- ============================================================
AddEventHandler('onClientResourceStart', function(res)
    if res ~= resourceName then return end
    Wait(1000) -- aguardar framework inicializar
    TriggerServerEvent(resourceName .. ':world:requestSync')
    isWorldEvidenceReady = true
end)

-- Receber sync completo (late-joiner)
RegisterNetEvent(resourceName .. ':world:syncAll', function(allEvidence)
    if type(allEvidence) ~= 'table' then return end
    for _, evData in pairs(allEvidence) do
        registerLocalEvidence(evData)
    end
    if Config.Debug then
        print(('[%s] WorldEvidence: %d evidência(s) sincronizada(s)'):format(resourceName, #allEvidence))
    end
end)

-- Nova evidência criada
RegisterNetEvent(resourceName .. ':world:evidenceSpawned', function(evData)
    if not evData then return end
    registerLocalEvidence(evData)

    -- Notificar apenas policiais na área
    if canCollect() and evData.coords then
        local playerCoords = GetEntityCoords(PlayerPedId())
        local evCoords     = vec3(evData.coords.x, evData.coords.y, evData.coords.z)
        local dist         = #(playerCoords - evCoords)

        if dist <= 200.0 then
            lib.notify({
                title       = 'Vestígio Detectado',
                description = ('Indício de %s identificado nas proximidades'):format(evData.type or 'evidência'),
                type        = 'inform',
                duration    = 5000,
                position    = 'bottom-right',
            })
        end
    end
end)

-- Evidência removida (coletada ou expirada)
RegisterNetEvent(resourceName .. ':world:evidenceRemoved', function(evId)
    removeEvidenceZone(evId)
end)

-- ============================================================
-- GAME EVENT: SANGUE (player local recebe dano)
-- Baseado no padrão do evidences: CEventNetworkEntityDamage
-- ============================================================
local lastBloodTime = 0

AddEventHandler('CEventNetworkEntityDamage', function(victim, attacker, weaponHash, isFatal)
    if not Config.WorldEvidence or not Config.WorldEvidence.Enabled then return end
    if victim ~= PlayerPedId() then return end
    if IsPedDead(PlayerPedId()) then return end
    if IsPedSwimming(PlayerPedId()) then return end

    -- Cooldown global para sangue
    local now = GetGameTimer()
    if (now - lastBloodTime) < ((Config.WorldEvidence.Cooldowns and Config.WorldEvidence.Cooldowns.sangue) or 4000) then
        return
    end

    -- Verificar chance
    if not rollChance('sangue') then return end

    lastBloodTime = now

    local coords = GetEntityCoords(PlayerPedId())
    TriggerServerEvent(resourceName .. ':world:spawnEvidence', {
        type        = 'sangue',
        category    = 'biologica',
        coords      = { x = coords.x, y = coords.y, z = coords.z },
        location    = getStreetName(coords),
        weapon_hash = weaponHash,
        source_type = 'damage_event',
    })
end)

-- ============================================================
-- GAME EVENT: IMPRESSÃO DIGITAL EM VEÍCULO
-- Disparado quando player entra em veículo sem luvas
-- ============================================================
local lastVehicleEntryTime = 0

AddEventHandler('baseevents:enteredVehicle', function(vehicle, seat, _modelName)
    if not Config.WorldEvidence or not Config.WorldEvidence.Enabled then return end

    -- Verificar luvas
    if hasGloves() then return end

    -- Cooldown
    local now = GetGameTimer()
    if (now - lastVehicleEntryTime) <
        ((Config.WorldEvidence.Cooldowns and Config.WorldEvidence.Cooldowns.impressao_digital) or 2500) then
        return
    end

    -- Verificar chance
    if not rollChance('impressao_digital') then return end

    lastVehicleEntryTime = now

    -- Obter dados do veículo
    if not DoesEntityExist(vehicle) then return end
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if not netId or netId == 0 then return end

    local plate  = GetVehicleNumberPlateText(vehicle) or ''
    local coords = GetEntityCoords(PlayerPedId())

    TriggerServerEvent(resourceName .. ':world:spawnEvidence', {
        type                 = 'impressao_digital',
        category             = 'digital_impressao',
        coords               = { x = coords.x, y = coords.y, z = coords.z },
        entity_type          = 'vehicle',
        entity_net_id        = netId,
        linked_vehicle_plate = plate ~= '' and plate or nil,
        location             = getStreetName(coords),
        source_type          = 'vehicle_entry',
    })
end)

-- ============================================================
-- GAME EVENT: CÁPSULA EJETA (disparo detectado por ammo decrease)
-- Baseado no padrão do evidences/client/evidences/registry/magazine.lua
-- ============================================================
local lastAmmoCount  = -1
local lastCasingTime = 0

CreateThread(function()
    Wait(5000) -- aguardar estabilização do framework

    while true do
        Wait(150) -- 150ms de polling (leve)

        if not Config.WorldEvidence or not Config.WorldEvidence.Enabled then
            Wait(5000)
            goto continue
        end

        local ped = PlayerPedId()
        if IsPedDead(ped) or IsPedSwimming(ped) then
            lastAmmoCount = -1
            goto continue
        end

        local _, weapon = GetCurrentPedWeapon(ped, true)

        if weapon == 0 or isWeaponBlacklisted(weapon) then
            lastAmmoCount = -1
            goto continue
        end

        local ammo = GetAmmoInClip(ped, weapon)

        -- Detectar disparo: ammo diminuiu (não recarga, que aumenta)
        if lastAmmoCount ~= -1 and ammo < lastAmmoCount then
            local now = GetGameTimer()
            local cooldown = (Config.WorldEvidence.Cooldowns and Config.WorldEvidence.Cooldowns.capsula) or 500

            if (now - lastCasingTime) >= cooldown then
                lastCasingTime = now

                if rollChance('capsula') then
                    local coords = GetEntityCoords(ped)
                    TriggerServerEvent(resourceName .. ':world:spawnEvidence', {
                        type        = 'capsula',
                        category    = 'balistica',
                        coords      = { x = coords.x, y = coords.y, z = coords.z },
                        location    = getStreetName(coords),
                        weapon_hash = weapon,
                        source_type = 'weapon_fired',
                    })
                end
            end
        end

        lastAmmoCount = ammo

        ::continue::
    end
end)

-- ============================================================
-- GAME EVENT: DISPARO (CEventGunShot)
-- Inspirado em lsn-evidence: CEventGunShot + lib.raycast.cam + SendBulletHole
--
-- Usa raycast da câmera para detectar onde a bala impactou:
--   • Superfície sólida → buraco_de_bala (categoria balistica)
--   • Veículo          → fragmento_veiculo com cor RGB do veículo
-- Ambos armazenam shooter_coords + shooter_heading para reconstrução
-- da trajetória na lanterna forense (ShowShootersLine).
-- ============================================================
local lastGunShotTime = 0

AddEventHandler('CEventGunShot', function(witnesses, ped)
    if not Config.WorldEvidence or not Config.WorldEvidence.Enabled then return end
    if not Config.WorldEvidence.AllowBulletHoles then return end
    if ped ~= PlayerPedId() then return end
    if IsPedSwimming(ped) then return end
    if IsPedDead(ped) then return end

    local weapon = GetSelectedPedWeapon(ped)
    if isWeaponBlacklisted(weapon) then return end

    local now      = GetGameTimer()
    local cooldown = (Config.WorldEvidence.Cooldowns and Config.WorldEvidence.Cooldowns.buraco_de_bala) or 300
    if (now - lastGunShotTime) < cooldown then return end

    lastGunShotTime = now

    local pedCoords   = GetEntityCoords(ped)
    local heading     = GetEntityHeading(ped)
    local shooterData = { x = pedCoords.x, y = pedCoords.y, z = pedCoords.z }

    -- Raycast da câmera para detectar impacto (igual ao lsn-evidence)
    local hit, entityHit, endCoords = lib.raycast.cam(511, 4, 1000)
    if not hit or not endCoords then return end

    local impactCoords = { x = endCoords.x, y = endCoords.y, z = endCoords.z }
    local entityType   = DoesEntityExist(entityHit) and GetEntityType(entityHit) or 0

    if entityType == 2 then
        -- Veículo atingido → fragmento com cor da lataria
        if not rollChance('fragmento_veiculo') then return end
        if not checkAndSetCooldown('fragmento_veiculo') then return end

        local r, g, b = GetVehicleColor(entityHit)
        local plate   = GetVehicleNumberPlateText(entityHit) or ''

        TriggerServerEvent(resourceName .. ':world:spawnEvidence', {
            type                 = 'fragmento_veiculo',
            category             = 'balistica',
            coords               = impactCoords,
            location             = getStreetName(endCoords),
            weapon_hash          = weapon,
            shooter_coords       = shooterData,
            shooter_heading      = heading,
            vehicle_color_r      = r,
            vehicle_color_g      = g,
            vehicle_color_b      = b,
            linked_vehicle_plate = plate ~= '' and plate or nil,
            source_type          = 'gun_shot',
        })
    else
        -- Superfície sólida → buraco de bala
        if not rollChance('buraco_de_bala') then return end

        TriggerServerEvent(resourceName .. ':world:spawnEvidence', {
            type            = 'buraco_de_bala',
            category        = 'balistica',
            coords          = impactCoords,
            location        = getStreetName(endCoords),
            weapon_hash     = weapon,
            shooter_coords  = shooterData,
            shooter_heading = heading,
            source_type     = 'gun_shot',
        })
    end
end)

-- ============================================================
-- GAME EVENT: PASSOS (CEventFootStepHeard)
-- Inspirado em lsn-evidence: CEventFootStepHeard + IsWearingWhitelistedShoes
--
-- Gera evidência 'pegada' quando o jogador está correndo.
-- Armazena shoe_model (drawable do componente 6) para comparação
-- posterior com suspeito identificado.
-- Ignorado se jogador estiver descalço (barefoot drawables).
-- ============================================================
local lastFootstepTime = 0

AddEventHandler('CEventFootStepHeard', function(witnesses, ped)
    if not Config.WorldEvidence or not Config.WorldEvidence.Enabled then return end
    if not Config.WorldEvidence.AllowFootprints then return end
    if ped ~= PlayerPedId() then return end
    if IsPedSwimming(ped) or IsPedDead(ped) then return end

    -- Apenas quando correndo (velocidade mínima configurável)
    local minSpeed = Config.WorldEvidence.FootprintMinSpeed or 6.5
    if GetEntitySpeed(ped) <= minSpeed then return end

    -- Pé descalço não deixa pegada de sapato
    if isPlayerBarefoot(ped) then return end

    local now      = GetGameTimer()
    local cooldown = (Config.WorldEvidence.Cooldowns and Config.WorldEvidence.Cooldowns.pegada) or 2500
    if (now - lastFootstepTime) < cooldown then return end
    if not rollChance('pegada') then return end

    lastFootstepTime = now

    local coords    = GetEntityCoords(ped)
    local shoeModel = GetPedDrawableVariation(ped, 6)

    TriggerServerEvent(resourceName .. ':world:spawnEvidence', {
        type        = 'pegada',
        category    = 'digital_impressao',
        coords      = { x = coords.x, y = coords.y, z = coords.z },
        location    = getStreetName(coords),
        shoe_model  = shoeModel,
        source_type = 'footstep',
    })
end)

-- ============================================================
-- LANTERNA FORENSE - Destacar evidências próximas
-- Ativada por items.lua via ToggleForensicFlashlight()
-- ============================================================

-- Função global acessível pelo items.lua no mesmo resource
function ToggleForensicFlashlight(state)
    flashlightActive = state
end

function IsForensicFlashlightActive()
    return flashlightActive
end

-- Thread de destaque visual com lanterna forense ativa
CreateThread(function()
    while true do
        if flashlightActive then
            Wait(0) -- A 60fps quando a lanterna está ativa

            local ped    = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local range  = (Config.WorldEvidence and Config.WorldEvidence.FlashlightRange) or 15.0
            local colors = (Config.WorldEvidence and Config.WorldEvidence.DiscoveryMarkerColors) or {}

            local found = false
            for evId, evData in pairs(worldEvidenceCache) do
                if evData.coords then
                    local evCoords = vec3(evData.coords.x, evData.coords.y, evData.coords.z)
                    local dist     = #(coords - evCoords)

                    if dist <= range then
                        found = true
                        local c = colors[evData.category] or { r = 180, g = 180, b = 255, a = 160 }

                        -- Marcador pulsante no chão
                        DrawMarker(
                            27,                                    -- tipo: cilindro pequeno
                            evData.coords.x, evData.coords.y, evData.coords.z,
                            0.0, 0.0, 0.0,                         -- direção
                            0.0, 0.0, 0.0,                         -- rotação
                            0.35, 0.35, 0.35,                      -- escala
                            c.r, c.g, c.b, c.a,                   -- cor
                            false, true, 2, nil, nil, false
                        )

                        -- Halo luminoso acima
                        DrawMarker(
                            28,                                    -- tipo: halo
                            evData.coords.x, evData.coords.y, evData.coords.z + 0.05,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            0.4, 0.4, 0.15,
                            c.r, c.g, c.b, math.min(c.a, 120),
                            false, false, 2, nil, nil, false
                        )

                        -- Texto flutuante com tipo da evidência
                        if dist <= 6.0 then
                            SetDrawOrigin(evData.coords.x, evData.coords.y, evData.coords.z + 0.5, 0)
                            SetTextFont(4)
                            SetTextScale(0.0, 0.3)
                            SetTextColour(c.r, c.g, c.b, 220)
                            SetTextCentre(true)
                            SetTextEntry('STRING')
                            AddTextComponentString(evData.type or 'VESTÍGIO')
                            DrawText(0.0, 0.0)
                            ClearDrawOrigin()
                        end

                        -- Linha de trajetória do atirador (ShowShootersLine)
                        -- Inspirado em lsn-evidence: exibe linha vermelha do shooter ao ponto de impacto
                        -- Disponível para buraco_de_bala e fragmento_veiculo que armazenam shooter_coords
                        if Config.WorldEvidence.ShowShootersLine
                            and evData.shooter_coords
                            and (evData.type == 'buraco_de_bala' or evData.type == 'fragmento_veiculo')
                        then
                            local sc = evData.shooter_coords
                            local lc = Config.WorldEvidence.ShootersLineColor or { r = 255, g = 50, b = 50, a = 200 }
                            DrawLine(
                                sc.x, sc.y, sc.z,
                                evData.coords.x, evData.coords.y, evData.coords.z,
                                lc.r, lc.g, lc.b, lc.a
                            )
                            -- Marcador na posição do atirador
                            DrawMarker(
                                1,
                                sc.x, sc.y, sc.z,
                                0.0, 0.0, 0.0,
                                0.0, 0.0, 0.0,
                                0.3, 0.3, 0.3,
                                lc.r, lc.g, lc.b, math.min(lc.a, 150),
                                false, true, 2, nil, nil, false
                            )
                        end
                    end
                end
            end

            if not found and not next(worldEvidenceCache) then
                Wait(500) -- Sem evidências próximas, reduzir ciclos
            end
        else
            Wait(500) -- Lanterna desligada, verificar a cada 500ms
        end
    end
end)

-- ============================================================
-- CLEANUP ao parar o resource
-- ============================================================
AddEventHandler('onResourceStop', function(res)
    if res ~= resourceName then return end
    for evId, _ in pairs(evidenceZones) do
        pcall(function()
            exports.ox_target:removeZone(evidenceZones[evId])
        end)
    end
    evidenceZones      = {}
    worldEvidenceCache = {}
    flashlightActive   = false
end)
