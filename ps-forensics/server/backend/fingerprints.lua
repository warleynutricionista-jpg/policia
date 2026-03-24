-- ============================================================
-- PS-FORENSICS - Módulo: Impressões Digitais (Server)
-- ============================================================

local resourceName = GetCurrentResourceName()
local allowedSourceTypes = {
    objeto = true,
    veiculo = true,
    arma = true,
    porta = true,
    superficie = true,
}

local sourceTypeAliases = {
    veículo = 'veiculo',
    arma_fogo = 'arma',
    weapon = 'arma',
    vehicle = 'veiculo',
    door = 'porta',
    object = 'objeto',
    surface = 'superficie',
}

local function normalizeSourceType(sourceType)
    local t = (sourceType or 'objeto'):lower():gsub('%s+', '_')
    t = sourceTypeAliases[t] or t
    if t == 'vidro' then t = 'superficie' end
    return allowedSourceTypes[t] and t or 'objeto'
end

local function getCitizenNameFromMDT(citizenid)
    if not citizenid or citizenid == '' then return nil end
    local row = MySQL.single.await('SELECT firstname, lastname FROM mdt_profiles WHERE citizenid = ?', { citizenid })
    if row then
        return (('%s %s'):format(row.firstname or '', row.lastname or '')):gsub('^%s*(.-)%s*$', '%1')
    end
    return nil
end

local function getConfidenceByQuality(quality, exactMatch)
    if quality == 'boa' then
        return exactMatch and (90 + math.random(10)) or (70 + math.random(15))
    end
    if quality == 'parcial' then
        return exactMatch and (70 + math.random(15)) or (45 + math.random(20))
    end
    if quality == 'degradada' then
        return exactMatch and (40 + math.random(20)) or (20 + math.random(20))
    end
    return 0
end

-- ============================================================
-- REGISTRAR DIGITAL DE CIDADÃO NO BANCO
-- ============================================================
lib.callback.register(resourceName .. ':server:registerFingerprint', function(source, citizenid, citizenName)
    local src = source
    if not CheckForensicAuth(src) then return { success = false, error = L('fingerprints.errors.not_authorized') } end

    if not citizenid then return { success = false, error = L('fingerprints.errors.citizenid_required') } end

    -- Verificar se já existe
    local existing = MySQL.scalar.await('SELECT COUNT(*) FROM forensic_fingerprint_profiles WHERE citizenid = ?', { citizenid })
    if existing and existing > 0 then
        return { success = false, error = L('fingerprints.errors.profile_exists') }
    end

    local hash = ForensicUtils.GenerateFingerprintHash(citizenid)
    local playerData = GetPlayerData(src)
    local resolvedName = citizenName or getCitizenNameFromMDT(citizenid) or L('labels.unknown')

    MySQL.insert.await([[
        INSERT INTO forensic_fingerprint_profiles (citizenid, citizen_name, fingerprint_hash, registered_by)
        VALUES (?, ?, ?, ?)
    ]], { citizenid, resolvedName, hash, playerData and playerData.citizenid or '' })

    ForensicAuditLog(src, 'fingerprint_registered', 'fingerprint_profile', nil, { citizenid = citizenid })

    return { success = true, hash = hash }
end)

-- ============================================================
-- COLETAR DIGITAL EM CENA/OBJETO
-- ============================================================
lib.callback.register(resourceName .. ':server:collectFingerprint', function(source, data)
    local src = source
    if not CheckForensicAuth(src) then return { success = false, error = L('fingerprints.errors.not_authorized') } end
    if not CheckForensicPermission(src, 'canCollectEvidence') then
        return { success = false, error = L('fingerprints.errors.no_permission_collect') }
    end

    local playerData = GetPlayerData(src)
    if not playerData then return { success = false, error = L('scene.errors.player_data_unavailable') } end
    data = data or {}

    local evidenceId = data.evidence_id and tonumber(data.evidence_id) or nil
    local sceneId = data.scene_id and tonumber(data.scene_id) or nil
    local sourceType = normalizeSourceType(data.source_type)
    local sourceDescription = data.source_description or L('fingerprints.defaults.unknown_surface')
    local quality = data.quality or 'parcial'
    local notes = data.notes or ''

    if quality ~= 'boa' and quality ~= 'parcial' and quality ~= 'degradada' and quality ~= 'ilegivel' then
        quality = 'parcial'
    end

    local linkedCitizenId = data.linked_citizenid

    if evidenceId then
        local evidence = MySQL.single.await('SELECT id, scene_id, linked_citizenid FROM forensic_evidence WHERE id = ?', { evidenceId })
        if not evidence then
            return { success = false, error = L('fingerprints.errors.evidence_not_found') }
        end
        if not sceneId and evidence.scene_id then
            sceneId = evidence.scene_id
        end
        if not linkedCitizenId and evidence.linked_citizenid then
            linkedCitizenId = evidence.linked_citizenid
        end
    end

    if sceneId then
        local scene = MySQL.single.await('SELECT id, status, location_x, location_y, location_z FROM forensic_crime_scenes WHERE id = ?', { sceneId })
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
                return { success = false, error = L('fingerprints.errors.too_far_from_scene') }
            end
        end
    end

    local fingerprintHash = nil
    if linkedCitizenId and linkedCitizenId ~= '' then
        local profile = MySQL.single.await('SELECT fingerprint_hash FROM forensic_fingerprint_profiles WHERE citizenid = ?', { linkedCitizenId })
        fingerprintHash = profile and profile.fingerprint_hash or ForensicUtils.GenerateFingerprintHash(linkedCitizenId)
    elseif quality ~= 'ilegivel' then
        local seed = ('%s-%s-%s-%s'):format(sceneId or 0, evidenceId or 0, sourceType, os.time())
        fingerprintHash = ForensicUtils.GenerateFingerprintHash(seed)
    end

    local fpId = MySQL.insert.await([[
        INSERT INTO forensic_fingerprints_collected
        (evidence_id, scene_id, source_description, source_type, fingerprint_hash, quality,
         match_status, collected_by, collected_by_name, notes)
        VALUES (?, ?, ?, ?, ?, ?, 'pendente', ?, ?, ?)
    ]], {
        evidenceId,
        sceneId,
        sourceDescription,
        sourceType,
        fingerprintHash,
        quality,
        playerData.citizenid,
        playerData.name,
        notes,
    })

    ForensicAuditLog(src, 'fingerprint_collected', 'fingerprint', fpId, {
        source = sourceDescription,
        sourceType = sourceType,
        sceneId = sceneId,
        evidenceId = evidenceId,
        linkedCitizenId = linkedCitizenId,
    })

    return { success = true, id = fpId }
end)

-- ============================================================
-- PROCESSAR / COMPARAR DIGITAL
-- ============================================================
lib.callback.register(resourceName .. ':server:analyzeFingerprint', function(source, fingerprintId)
    local src = source
    if not CheckForensicAuth(src) then return { success = false, error = L('fingerprints.errors.not_authorized') } end
    if not CheckForensicPermission(src, 'canRunLabTests') then
        return { success = false, error = L('fingerprints.errors.no_permission_analyze') }
    end

    fingerprintId = tonumber(fingerprintId)
    if not fingerprintId then return { success = false, error = L('fingerprints.errors.invalid_id') } end

    local playerData = GetPlayerData(src)
    if not playerData then return { success = false, error = L('scene.errors.player_data_unavailable') } end

    local fp = MySQL.single.await('SELECT * FROM forensic_fingerprints_collected WHERE id = ?', { fingerprintId })
    if not fp then return { success = false, error = L('fingerprints.errors.not_found') } end

    local targetCitizenId = nil
    if fp.evidence_id then
        local ev = MySQL.single.await('SELECT linked_citizenid FROM forensic_evidence WHERE id = ?', { fp.evidence_id })
        if ev and ev.linked_citizenid then
            targetCitizenId = ev.linked_citizenid
        end
    end

    local matchStatus = 'sem_correspondencia'
    local matchedCitizenId = nil
    local matchedName = nil
    local confidence = 0

    if fp.quality ~= 'ilegivel' and fp.fingerprint_hash and fp.fingerprint_hash ~= '' then
        local profileByHash = MySQL.single.await(
            'SELECT citizenid, citizen_name, fingerprint_hash FROM forensic_fingerprint_profiles WHERE fingerprint_hash = ?',
            { fp.fingerprint_hash }
        )

        if profileByHash then
            matchedCitizenId = profileByHash.citizenid
            matchedName = profileByHash.citizen_name
            confidence = getConfidenceByQuality(fp.quality, true)
            matchStatus = confidence >= 80 and 'positiva' or 'parcial'
        elseif targetCitizenId then
            local profile = MySQL.single.await(
                'SELECT citizenid, citizen_name, fingerprint_hash FROM forensic_fingerprint_profiles WHERE citizenid = ?',
                { targetCitizenId }
            )
            if profile then
                matchedCitizenId = profile.citizenid
                matchedName = profile.citizen_name
                confidence = getConfidenceByQuality(fp.quality, false)
                matchStatus = confidence >= 70 and 'positiva' or 'parcial'
                MySQL.update.await(
                    'UPDATE forensic_fingerprints_collected SET fingerprint_hash = ? WHERE id = ?',
                    { profile.fingerprint_hash, fingerprintId }
                )
            end
        end
    end

    -- Atualizar resultado
    MySQL.update.await([[
        UPDATE forensic_fingerprints_collected
        SET match_status = ?, matched_citizenid = ?, matched_name = ?,
            match_confidence = ?, analyzed_by = ?, analyzed_at = NOW()
        WHERE id = ?
    ]], {
        matchStatus, matchedCitizenId, matchedName,
        confidence, playerData.citizenid, fingerprintId
    })

    -- Se houve match, criar referência cruzada
    if matchedCitizenId and (matchStatus == 'positiva' or matchStatus == 'parcial') then
        MySQL.insert.await([[
            INSERT INTO forensic_cross_references
            (source_type, source_id, target_type, target_id, relationship, confidence, created_by, notes)
            VALUES ('fingerprint', ?, 'citizenid', ?, 'match_digital', ?, ?, ?)
        ]], {
            fingerprintId, matchedCitizenId,
            matchStatus == 'positiva' and 'confirmada' or 'media',
            playerData.citizenid,
            ('Digital %s - Confiança: %d%%'):format(matchStatus, confidence),
        })
    end

    -- Registrar teste no lab
    MySQL.insert.await([[
        INSERT INTO forensic_lab_tests
        (evidence_id, scene_id, test_type, test_name, result_level, result_details,
         target_citizenid, target_name, requested_by, requested_by_name,
         performed_by, performed_by_name, started_at, completed_at, status)
        VALUES (?, ?, 'comparacao_digital', 'Comparação de Impressão Digital', ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW(), 'concluido')
    ]], {
        fp.evidence_id, fp.scene_id,
        matchStatus == 'positiva' and 'confirmado' or (matchStatus == 'parcial' and 'compativel' or 'negativo'),
        ('Resultado: %s | Cidadão: %s | Confiança: %d%%'):format(matchStatus, matchedName or L('labels.na'), confidence),
        matchedCitizenId, matchedName,
        playerData.citizenid, playerData.name,
        playerData.citizenid, playerData.name,
    })

    ForensicAuditLog(src, 'fingerprint_analyzed', 'fingerprint', fingerprintId, {
        matchStatus = matchStatus,
        matchedCitizenId = matchedCitizenId,
        confidence = confidence,
    })

    return {
        success = true,
        matchStatus = matchStatus,
        matchedCitizenId = matchedCitizenId,
        matchedName = matchedName,
        confidence = confidence,
        resultLabel = L(('fingerprints.result.%s'):format(matchStatus)),
    }
end)

-- ============================================================
-- BUSCAR DIGITAIS POR CIDADÃO
-- ============================================================
lib.callback.register(resourceName .. ':server:searchFingerprintsByCitizen', function(source, citizenid)
    local src = source
    if not CheckForensicAuth(src) then return {} end

    return MySQL.query.await([[
        SELECT fc.*, fe.evidence_number, fe.scene_id
        FROM forensic_fingerprints_collected fc
        LEFT JOIN forensic_evidence fe ON fc.evidence_id = fe.id
        WHERE fc.matched_citizenid = ?
        ORDER BY fc.created_at DESC
    ]], { citizenid }) or {}
end)
