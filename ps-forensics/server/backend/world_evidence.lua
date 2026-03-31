-- ============================================================
-- PS-FORENSICS - Evidências de Mundo (Server)
-- Gerencia vestígios físicos auto-gerados por eventos de jogo.
--
-- Armazenamento: memória apenas (GlobalState local do módulo).
-- Persistência: quando o policial coleta, grava em forensic_evidence.
--
-- Expiração: thread de limpeza a cada 60s remove vestígios vencidos
-- e notifica todos os clientes para remover as zonas visuais.
-- ============================================================

local resourceName = GetCurrentResourceName()

-- Armazenamento em memória
-- { [id] = { id, type, category, coords, spawnedAt, expiresAt, ... } }
local worldEvidence          = {}
local evidenceSeq            = 0
local sourceRateLimit        = {}
local sourceRateLimitByType  = {} -- rate limit por tipo por jogador (ex: "12:sangue")

local allowedWorldTypes = {}
for evidenceType, _ in pairs((Config.WorldEvidence and Config.WorldEvidence.Chances) or {}) do
    allowedWorldTypes[evidenceType] = true
end
allowedWorldTypes.buraco_de_bala = true
allowedWorldTypes.fragmento_veiculo = true

local function sanitizeWorldCoords(coords)
    if type(coords) ~= 'table' then return nil end

    local x = tonumber(coords.x)
    local y = tonumber(coords.y)
    local z = tonumber(coords.z)

    if not x or not y or not z then return nil end
    if math.abs(x) > 10000 or math.abs(y) > 10000 or z < -400 or z > 2000 then
        return nil
    end

    return { x = x, y = y, z = z }
end

local function getMaxSpawnDistanceForType(evidenceType)
    local worldCfg = Config.WorldEvidence or {}
    local defaultMax = tonumber(worldCfg.MaxSpawnDistanceFromPlayer) or 20.0
    local byType = worldCfg.MaxSpawnDistanceByType

    if type(byType) == 'table' then
        local specific = tonumber(byType[evidenceType or ''])
        if specific and specific > 0 then
            return specific
        end
    end

    -- Fallback seguro para evidências balísticas de longo alcance.
    -- Buraco/fragmento podem ocorrer distante do ped devido ao raycast.
    if evidenceType == 'buraco_de_bala' or evidenceType == 'fragmento_veiculo' then
        return math.max(defaultMax, 180.0)
    end

    return defaultMax
end

local function isSpawnPlausibleForSource(src, evidenceType, coords)
    if not coords then return false end

    local ped = GetPlayerPed(src)
    if not ped or ped <= 0 then return false end

    local pedCoords = GetEntityCoords(ped)
    if not pedCoords then return false end

    local dx = pedCoords.x - coords.x
    local dy = pedCoords.y - coords.y
    local dz = pedCoords.z - coords.z

    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
    local maxDistance = getMaxSpawnDistanceForType(evidenceType)

    return dist <= maxDistance
end


local function getExpirationTime()
    return (Config.WorldEvidence and Config.WorldEvidence.ExpirationTime) or 3600
end

local function getMinDistance()
    return (Config.WorldEvidence and Config.WorldEvidence.MinDistanceBetweenSameType) or 2.0
end

local function isFootprintBlockedForJob(jobName, jobType)
    if not Config.WorldEvidence or Config.WorldEvidence.DisablePoliceFootprints ~= true then
        return false
    end

    local normalizedType = tostring(jobType or ''):lower():gsub('[%s_-]+', '')
    if normalizedType == 'leo' or normalizedType == 'police' then
        return true
    end

    local normalizedJob = tostring(jobName or ''):lower():gsub('[%s_-]+', '')
    if normalizedJob == '' then return false end

    local blockedJobs = (Config.WorldEvidence and Config.WorldEvidence.FootprintBlockedJobs) or Config.PoliceJobs or {}
    for _, blocked in ipairs(blockedJobs) do
        local normalizedBlocked = tostring(blocked):lower():gsub('[%s_-]+', '')
        if normalizedBlocked == normalizedJob then
            return true
        end
    end

    if ForensicUtils and ForensicUtils.IsPoliceJob and ForensicUtils.IsPoliceJob(jobName) then
        return true
    end

    if normalizedJob:find('police', 1, true)
        or normalizedJob:find('policia', 1, true)
        or normalizedJob:find('sheriff', 1, true)
        or normalizedJob:find('trooper', 1, true)
    then
        return true
    end

    return false
end

-- ID único para cada vestígio de campo
local function generateWorldEvidenceId()
    evidenceSeq = evidenceSeq + 1
    return ('WEVID-%06d-%04X'):format(evidenceSeq, math.random(0, 0xFFFF))
end

-- ============================================================
-- VERIFICAÇÃO DE DUPLICATA PRÓXIMA
-- Evita spam de evidências do mesmo tipo em raio curto
-- ============================================================
local function hasDuplicateNearby(evidenceType, coords)
    if not coords then return false end
    local minDist = getMinDistance()

    for _, ev in pairs(worldEvidence) do
        if ev.type == evidenceType and ev.coords then
            local dx = math.abs(ev.coords.x - coords.x)
            local dy = math.abs(ev.coords.y - coords.y)
            -- Verificação rápida por bounding box antes de calcular distância real
            if dx < minDist and dy < minDist then
                local dist = math.sqrt(dx * dx + dy * dy)
                if dist < minDist then
                    return true
                end
            end
        end
    end

    return false
end

-- ============================================================
-- CRIAR VESTÍGIO
-- ============================================================
local function spawnWorldEvidence(src, data)
    if type(data) ~= 'table' or type(data.type) ~= 'string' then return nil end

    -- Verificar se world evidence está habilitado
    if not Config.WorldEvidence or not Config.WorldEvidence.Enabled then
        return nil
    end

    if not allowedWorldTypes[data.type] then
        if Config.Debug then
            print(('[%s] WorldEvidence: tipo bloqueado no spawn: %s'):format(resourceName, tostring(data.type)))
        end
        return nil
    end

    data.coords = sanitizeWorldCoords(data.coords)
    if not data.coords then return nil end

    -- Verificar duplicata próxima
    if hasDuplicateNearby(data.type, data.coords) then
        return nil
    end

    local evId = generateWorldEvidenceId()
    local now  = os.time()
    local exp  = getExpirationTime()

    -- Validar shooter_coords se presentes
    local shooterCoords = nil
    if type(data.shooter_coords) == 'table' then
        shooterCoords = {
            x = tonumber(data.shooter_coords.x) or 0,
            y = tonumber(data.shooter_coords.y) or 0,
            z = tonumber(data.shooter_coords.z) or 0,
        }
    end

    local evData = {
        id                   = evId,
        type                 = data.type,
        category             = data.category or 'outros',
        coords               = data.coords,
        entity_type          = data.entity_type,
        entity_net_id        = data.entity_net_id,
        linked_vehicle_plate = data.linked_vehicle_plate,
        linked_weapon_serial = data.linked_weapon_serial,
        weapon_hash          = data.weapon_hash,
        source_type          = data.source_type or 'manual',
        location             = data.location and tostring(data.location):sub(1, 200) or '',
        spawned_by           = src,
        spawnedAt            = now,
        expiresAt            = now + exp,
        -- Campos adicionais inspirados no lsn-evidence
        shooter_coords       = shooterCoords,                          -- posição do atirador (buracos de bala / fragmentos)
        shooter_heading      = tonumber(data.shooter_heading) or nil,  -- direção do atirador
        shoe_model           = tonumber(data.shoe_model) or nil,       -- drawable do sapato (pegadas)
        vehicle_color_r      = tonumber(data.vehicle_color_r) or nil,  -- cor da lataria atingida
        vehicle_color_g      = tonumber(data.vehicle_color_g) or nil,
        vehicle_color_b      = tonumber(data.vehicle_color_b) or nil,
        revealed             = data.revealed == true,
    }

    worldEvidence[evId] = evData

    -- Broadcast para todos os clientes
    TriggerClientEvent(resourceName .. ':world:evidenceSpawned', -1, evData)

    if Config.Debug then
        print(('[%s] WorldEvidence: vestígio "%s" criado em (%.1f, %.1f) | ID: %s'):format(
            resourceName, evData.type, evData.coords and evData.coords.x or 0,
            evData.coords and evData.coords.y or 0, evId
        ))
    end

    return evData
end

function GetWorldEvidenceById(evId)
    return worldEvidence[evId]
end

function UpdateWorldEvidenceById(evId, patch)
    if not worldEvidence[evId] or type(patch) ~= 'table' then return false end
    for k, v in pairs(patch) do
        worldEvidence[evId][k] = v
    end
    TriggerClientEvent(resourceName .. ':world:evidenceUpdated', -1, evId, patch)
    return true
end

function SpawnManualWorldEvidence(src, data)
    return spawnWorldEvidence(src, data)
end

-- ============================================================
-- EVENT: Jogador dispara spawn de vestígio
-- Acionado por game events no client (dano, entrada veículo, etc.)
-- ============================================================
-- Cooldowns por tipo de evidência por jogador (ms)
local typeCooldownsMs = {
    sangue              = 3000,
    capsula             = 400,
    impressao_digital   = 2000,
    pegada              = 2000,
    buraco_de_bala      = 250,
    fragmento_veiculo   = 400,
}

RegisterNetEvent(resourceName .. ':world:spawnEvidence', function(data)
    local src = source
    if not src or src <= 0 then return end

    local now = GetGameTimer()
    local cooldownMs = (Config.WorldEvidence and Config.WorldEvidence.ServerSpawnRateLimitMs) or 250

    -- Rate limit global por jogador
    if sourceRateLimit[src] and (now - sourceRateLimit[src]) < cooldownMs then
        if Config.Debug then
            print(('[%s] WorldEvidence: rate-limit global acionado para source %s'):format(resourceName, tostring(src)))
        end
        return
    end
    sourceRateLimit[src] = now

    -- Rate limit por tipo por jogador (mais restritivo)
    if type(data) == 'table' and type(data.type) == 'string' then
        local evType = data.type
        local key = ('%d:%s'):format(src, evType)
        local typeCooldown = typeCooldownsMs[evType] or 1000
        if sourceRateLimitByType[key] and (now - sourceRateLimitByType[key]) < typeCooldown then
            if Config.Debug then
                print(('[%s] WorldEvidence: rate-limit por tipo "%s" acionado para source %s'):format(resourceName, evType, tostring(src)))
            end
            return
        end
        sourceRateLimitByType[key] = now
    end

    local playerData = GetPlayerData(src)
    if not playerData then return end

    if type(data) ~= 'table' or type(data.type) ~= 'string' then
        return
    end

    if data.type == 'pegada' and isFootprintBlockedForJob(playerData.job, playerData.jobType) then
        if Config.Debug then
            print(('[%s] WorldEvidence: pegada bloqueada para job "%s" (src=%s)'):format(
                resourceName, tostring(playerData.job), tostring(src)
            ))
        end
        return
    end

    if not allowedWorldTypes[data.type] then
        print(('[%s] WorldEvidence: tentativa bloqueada de tipo inválido "%s" por %s'):format(resourceName, tostring(data.type), tostring(src)))
        return
    end

    data.coords = sanitizeWorldCoords(data.coords)
    if not data.coords then
        if Config.Debug then
            print(('[%s] WorldEvidence: coords inválidas recebidas de %s'):format(resourceName, tostring(src)))
        end
        return
    end

    if not isSpawnPlausibleForSource(src, data.type, data.coords) then
        print(('[%s] WorldEvidence: spawn rejeitado por distância inválida (src=%s, type=%s)'):format(resourceName, tostring(src), tostring(data.type)))
        return
    end

    data.category = tostring(data.category or 'outros'):sub(1, 40)
    data.location = tostring(data.location or ''):sub(1, 200)

    spawnWorldEvidence(src, data)
end)

-- ============================================================
-- EVENT: Late-joiner solicita sincronização de vestígios ativos
-- ============================================================
RegisterNetEvent(resourceName .. ':world:requestSync', function()
    local src = source
    if not src or src <= 0 then return end

    local now    = os.time()
    local active = {}

    for _, ev in pairs(worldEvidence) do
        if ev.expiresAt > now then
            active[#active + 1] = ev
        end
    end

    TriggerClientEvent(resourceName .. ':world:syncAll', src, active)

    if Config.Debug then
        print(('[%s] WorldEvidence: sync enviado para %s (%d vestígios ativos)'):format(
            resourceName, tostring(src), #active
        ))
    end
end)

-- ============================================================
-- CALLBACK: Coletar vestígio de campo e persistir no banco
-- ============================================================
lib.callback.register(resourceName .. ':server:collectWorldEvidence', function(source, evId, sceneId)
    local src = source

    -- Autenticação forense
    if not CheckForensicAuth(src) then
        return { success = false, error = L('scene.errors.not_authorized') }
    end
    if not CheckForensicPermission(src, 'canCollectEvidence') then
        return { success = false, error = L('evidence.errors.no_permission_collect') }
    end

    -- Verificar se vestígio ainda existe
    local evData = worldEvidence[evId]
    if not evData then
        return { success = false, error = 'Vestígio não encontrado ou já expirado' }
    end

    -- Verificar expiração
    if os.time() > evData.expiresAt then
        worldEvidence[evId] = nil
        TriggerClientEvent(resourceName .. ':world:evidenceRemoved', -1, evId)
        return { success = false, error = 'Vestígio expirado' }
    end

    local playerData = GetPlayerData(src)
    if not playerData then
        return { success = false, error = L('scene.errors.player_data_unavailable') }
    end

    sceneId = sceneId and tonumber(sceneId) or nil
    local caseId, reportId
    if sceneId then
        local scene = MySQL.single.await('SELECT id, status, case_id, report_id, location_x, location_y, location_z FROM forensic_crime_scenes WHERE id = ?', { sceneId })
        if not scene then
            return { success = false, error = L('scene.errors.not_found') }
        end
        if scene.status == 'finalizada' then
            return { success = false, error = L('scene.errors.scene_closed_for_collection') }
        end

        local ped = GetPlayerPed(src)
        if ped and ped > 0 and scene.location_x and scene.location_y and scene.location_z then
            local pCoords = GetEntityCoords(ped)
            local distance = #(vector3(scene.location_x, scene.location_y, scene.location_z) - pCoords)
            if distance > 150.0 then
                return { success = false, error = L('evidence.errors.too_far_from_scene') }
            end
        end

        caseId = scene.case_id or nil
        reportId = scene.report_id or nil
    end

    local actionName = 'collect_evidence'
    if evData.type == 'sangue' then
        actionName = 'collect_biological'
    elseif evData.type == 'impressao_digital' then
        actionName = 'collect_fingerprint_sequence'
    elseif evData.type == 'capsula' or evData.type == 'projetil' then
        actionName = 'collect_ballistic'
    elseif evData.type == 'residuo_polvora' then
        actionName = 'run_gsr_test'
    elseif evData.type == 'residuo_droga' or evData.type == 'substancia_po' then
        actionName = 'run_drug_test'
    end

    local itemValidation = ValidateAndConsumeForensicAction(src, actionName)
    if not itemValidation.success then
        return { success = false, error = itemValidation.error }
    end

    -- Gerar número de lacre único
    local sealNum = ForensicUtils.GenerateSealNumber()
    local tries   = 0
    while tries < 5 do
        local exists = MySQL.scalar.await('SELECT COUNT(*) FROM forensic_evidence WHERE seal_number = ?', { sealNum })
        if not exists or tonumber(exists) == 0 then break end
        sealNum = ForensicUtils.GenerateSealNumber()
        tries   = tries + 1
    end

    local coords = evData.coords or { x = 0, y = 0, z = 0 }

    -- Inserir em forensic_evidence
    local evidenceId = MySQL.insert.await([[
        INSERT INTO forensic_evidence
        (evidence_number, category, type, subtype, description,
         collection_location, collection_x, collection_y, collection_z,
         collected_by, collected_by_name, collection_method, seal_number, status,
         linked_vehicle_plate, linked_weapon_serial, collection_source, world_evidence_id,
         scene_id, case_id, report_id)
        VALUES ('', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Campo - Auto', ?, 'coletada', ?, ?, 'campo', ?, ?, ?, ?)
    ]], {
        evData.category,
        evData.type,
        (evData.type == 'pegada' and evData.shoe_model and tostring(evData.shoe_model)) or nil,
        (function()
            local desc = ('Vestígio de campo: %s | Origem: %s'):format(evData.type, evData.source_type)
            if evData.shoe_model then
                desc = desc .. (' | Modelo sapato: %d'):format(evData.shoe_model)
            end
            if evData.vehicle_color_r then
                desc = desc .. (' | Cor veículo RGB(%d,%d,%d)'):format(
                    evData.vehicle_color_r, evData.vehicle_color_g or 0, evData.vehicle_color_b or 0)
            end
            return desc
        end)(),
        evData.location or '',
        coords.x, coords.y, coords.z,
        playerData.citizenid,
        playerData.name,
        sealNum,
        evData.linked_vehicle_plate or nil,
        evData.linked_weapon_serial or nil,
        evId,
        sceneId,
        caseId,
        reportId,
    })

    if not evidenceId then
        return { success = false, error = L('evidence.errors.register_failed') }
    end

    -- Gerar número sequencial da evidência
    local evidenceNumber = ForensicUtils.GenerateEvidenceNumber(evidenceId)
    MySQL.update.await([[
        UPDATE forensic_evidence
        SET evidence_number = ?, current_holder_citizenid = ?, current_holder_name = ?
        WHERE id = ?
    ]], { evidenceNumber, playerData.citizenid, playerData.name, evidenceId })

    -- Cadeia de custódia inicial com integridade SHA-256
    MySQL.insert.await([[
        INSERT INTO forensic_chain_of_custody
        (evidence_id, action, to_citizenid, to_name, location, notes,
         integrity_hash, previous_integrity_hash)
        VALUES (?, 'coletada', ?, ?, ?, ?,
            SHA2(CONCAT(?, '|coletada|', COALESCE(?, ''), '|', COALESCE(?, '')), 256),
            NULL)
    ]], {
        evidenceId,
        playerData.citizenid,
        playerData.name,
        evData.location or '',
        ('Coleta de campo automatizada | Lacre: %s | Origem: %s'):format(sealNum, evData.source_type),
        tostring(evidenceId),
        playerData.citizenid or '',
        sealNum,
    })

    -- Remover da memória e notificar clientes
    worldEvidence[evId] = nil
    TriggerClientEvent(resourceName .. ':world:evidenceRemoved', -1, evId)

    -- Registrar no audit log
    ForensicAuditLog(src, 'world_evidence_collected', 'evidence', evidenceId, {
        worldEvidenceId = evId,
        type            = evData.type,
        category        = evData.category,
        sealNumber      = sealNum,
        sourceType      = evData.source_type,
        actionName      = actionName,
        usedItems       = itemValidation.usedItems,
    })

    return {
        success        = true,
        evidenceId     = evidenceId,
        evidenceNumber = evidenceNumber,
        sealNumber     = sealNum,
    }
end)

-- ============================================================
-- THREAD DE LIMPEZA POR EXPIRAÇÃO (ciclo de 60 segundos)
-- ============================================================
CreateThread(function()
    while true do
        Wait(60000)

        if not Config.WorldEvidence or not Config.WorldEvidence.Enabled then
            goto cleanupContinue
        end

        local now     = os.time()
        local removed = 0

        for evId, ev in pairs(worldEvidence) do
            if ev.expiresAt <= now then
                worldEvidence[evId] = nil
                TriggerClientEvent(resourceName .. ':world:evidenceRemoved', -1, evId)
                removed = removed + 1
            end
        end

        if removed > 0 then
            print(('[%s] WorldEvidence: %d vestígio(s) expirado(s) removido(s)'):format(
                resourceName, removed
            ))
        end

        ::cleanupContinue::
    end
end)

-- ============================================================
-- EXPORT: contar vestígios ativos (para debug/dashboard)
-- ============================================================
exports('GetActiveWorldEvidenceCount', function()
    local count = 0
    local now   = os.time()
    for _, ev in pairs(worldEvidence) do
        if ev.expiresAt > now then
            count = count + 1
        end
    end
    return count
end)
