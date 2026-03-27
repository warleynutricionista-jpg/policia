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
local worldEvidence  = {}
local evidenceSeq    = 0

local function getExpirationTime()
    return (Config.WorldEvidence and Config.WorldEvidence.ExpirationTime) or 3600
end

local function getMinDistance()
    return (Config.WorldEvidence and Config.WorldEvidence.MinDistanceBetweenSameType) or 2.0
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
    if not data or not data.type then return nil end

    -- Verificar se world evidence está habilitado
    if not Config.WorldEvidence or not Config.WorldEvidence.Enabled then
        return nil
    end

    -- Verificar duplicata próxima
    if hasDuplicateNearby(data.type, data.coords) then
        return nil
    end

    local evId = generateWorldEvidenceId()
    local now  = os.time()
    local exp  = getExpirationTime()

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

-- ============================================================
-- EVENT: Jogador dispara spawn de vestígio
-- Acionado por game events no client (dano, entrada veículo, etc.)
-- ============================================================
RegisterNetEvent(resourceName .. ':world:spawnEvidence', function(data)
    local src = source
    if not src or src <= 0 then return end

    -- Validar que é um jogador legítimo (não precisa ser policial para gerar)
    local playerData = GetPlayerData(src)
    if not playerData then return end

    -- Validação básica dos dados recebidos
    if type(data) ~= 'table' then return end
    if not data.type or type(data.type) ~= 'string' then return end

    -- Sanitizar coordenadas
    if data.coords then
        data.coords.x = tonumber(data.coords.x) or 0
        data.coords.y = tonumber(data.coords.y) or 0
        data.coords.z = tonumber(data.coords.z) or 0
    end

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
lib.callback.register(resourceName .. ':server:collectWorldEvidence', function(source, evId)
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

    -- Verificar item requerido para coleta
    local requiredItemByType = {
        sangue              = Config.Items and Config.Items.blood_reagent,
        impressao_digital   = Config.Items and Config.Items.fingerprint_kit,
        capsula             = Config.Items and Config.Items.forensic_tweezers,
        projetil            = Config.Items and Config.Items.ballistic_kit,
        residuo_polvora     = Config.Items and Config.Items.gsr_kit,
        residuo_droga       = Config.Items and Config.Items.drug_test_kit,
        substancia_po       = Config.Items and Config.Items.drug_test_kit,
    }

    local requiredItem = requiredItemByType[evData.type]
        or (Config.Items and Config.Items.forensic_kit)
        or 'forensic_kit'

    if GetResourceState('ox_inventory') == 'started' then
        local count = exports.ox_inventory:GetItemCount(src, requiredItem) or 0
        if count <= 0 then
            return { success = false, error = L('evidence.errors.missing_required_item', requiredItem) }
        end
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
        (evidence_number, category, type, description,
         collection_location, collection_x, collection_y, collection_z,
         collected_by, collected_by_name, collection_method, seal_number, status,
         linked_vehicle_plate, linked_weapon_serial, collection_source, world_evidence_id)
        VALUES ('', ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Campo - Auto', ?, 'coletada', ?, ?, 'campo', ?)
    ]], {
        evData.category,
        evData.type,
        ('Vestígio de campo: %s | Origem: %s'):format(evData.type, evData.source_type),
        evData.location or '',
        coords.x, coords.y, coords.z,
        playerData.citizenid,
        playerData.name,
        sealNum,
        evData.linked_vehicle_plate or nil,
        evData.linked_weapon_serial or nil,
        evId,
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

    -- Reduzir durabilidade do item de coleta
    if GetResourceState('ox_inventory') == 'started' then
        local ok, items = pcall(function()
            return exports.ox_inventory:GetInventoryItems(src)
        end)
        if ok and items then
            for _, item in pairs(items) do
                if item.name == requiredItem then
                    local curDur = tonumber(item.durability) or 100
                    local newDur = math.max(0, curDur - 10)
                    pcall(function()
                        exports.ox_inventory:SetDurability(src, item.slot, newDur)
                    end)
                    break
                end
            end
        end
    end

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
