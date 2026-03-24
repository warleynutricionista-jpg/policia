-- ============================================================
-- PS-FORENSICS - Módulo: Impressões Digitais (Server)
-- ============================================================

local resourceName = GetCurrentResourceName()

-- ============================================================
-- REGISTRAR DIGITAL DE CIDADÃO NO BANCO
-- ============================================================
lib.callback.register(resourceName .. ':server:registerFingerprint', function(source, citizenid, citizenName)
    local src = source
    if not CheckForensicAuth(src) then return { success = false } end

    if not citizenid then return { success = false, error = 'CitizenID obrigatório' } end

    -- Verificar se já existe
    local existing = MySQL.scalar.await('SELECT COUNT(*) FROM forensic_fingerprint_profiles WHERE citizenid = ?', { citizenid })
    if existing and existing > 0 then
        return { success = false, error = 'Digital já cadastrada para este cidadão' }
    end

    local hash = ForensicUtils.GenerateFingerprintHash(citizenid)
    local playerData = GetPlayerData(src)

    MySQL.insert.await([[
        INSERT INTO forensic_fingerprint_profiles (citizenid, citizen_name, fingerprint_hash, registered_by)
        VALUES (?, ?, ?, ?)
    ]], { citizenid, citizenName or '', hash, playerData and playerData.citizenid or '' })

    ForensicAuditLog(src, 'fingerprint_registered', 'fingerprint_profile', nil, { citizenid = citizenid })

    return { success = true, hash = hash }
end)

-- ============================================================
-- COLETAR DIGITAL EM CENA/OBJETO
-- ============================================================
lib.callback.register(resourceName .. ':server:collectFingerprint', function(source, data)
    local src = source
    if not CheckForensicAuth(src) then return { success = false } end
    if not CheckForensicPermission(src, 'canCollectEvidence') then
        return { success = false, error = 'Sem permissão' }
    end

    local playerData = GetPlayerData(src)

    local fpId = MySQL.insert.await([[
        INSERT INTO forensic_fingerprints_collected
        (evidence_id, scene_id, source_description, source_type, quality,
         match_status, collected_by, collected_by_name, notes)
        VALUES (?, ?, ?, ?, ?, 'pendente', ?, ?, ?)
    ]], {
        data.evidence_id and tonumber(data.evidence_id) or nil,
        data.scene_id and tonumber(data.scene_id) or nil,
        data.source_description or 'Superfície não especificada',
        data.source_type or 'objeto',
        data.quality or 'parcial',
        playerData.citizenid,
        playerData.name,
        data.notes or '',
    })

    ForensicAuditLog(src, 'fingerprint_collected', 'fingerprint', fpId, {
        source = data.source_description,
        sourceType = data.source_type,
    })

    return { success = true, id = fpId }
end)

-- ============================================================
-- PROCESSAR / COMPARAR DIGITAL
-- ============================================================
lib.callback.register(resourceName .. ':server:analyzeFingerprint', function(source, fingerprintId)
    local src = source
    if not CheckForensicAuth(src) then return { success = false } end
    if not CheckForensicPermission(src, 'canRunLabTests') then
        return { success = false, error = 'Sem permissão para análise laboratorial' }
    end

    fingerprintId = tonumber(fingerprintId)
    if not fingerprintId then return { success = false } end

    local playerData = GetPlayerData(src)
    local fp = MySQL.single.await('SELECT * FROM forensic_fingerprints_collected WHERE id = ?', { fingerprintId })
    if not fp then return { success = false, error = 'Digital não encontrada' } end

    -- Determinar qualidade da digital - afeta chance de match
    local qualityChances = {
        boa = 0.90,
        parcial = 0.60,
        degradada = 0.30,
        ilegivel = 0.05,
    }

    local chance = qualityChances[fp.quality] or 0.50
    local roll = math.random()

    -- Gerar hash baseado na cena (simula digital real)
    -- Se existe cidadão vinculado à evidência, usar hash dele
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

    if targetCitizenId and roll <= chance then
        -- Tenta encontrar no banco
        local profile = MySQL.single.await(
            'SELECT * FROM forensic_fingerprint_profiles WHERE citizenid = ?',
            { targetCitizenId }
        )

        if profile then
            if fp.quality == 'boa' then
                matchStatus = 'positiva'
                confidence = 85 + math.random(15)
            elseif fp.quality == 'parcial' then
                matchStatus = 'parcial'
                confidence = 50 + math.random(30)
            else
                matchStatus = 'parcial'
                confidence = 20 + math.random(30)
            end

            matchedCitizenId = profile.citizenid
            matchedName = profile.citizen_name

            -- Gerar hash para a digital coletada
            MySQL.update.await(
                'UPDATE forensic_fingerprints_collected SET fingerprint_hash = ? WHERE id = ?',
                { profile.fingerprint_hash, fingerprintId }
            )
        end
    else
        -- Sem match ou falha na qualidade
        if roll > chance and fp.quality ~= 'ilegivel' then
            matchStatus = 'sem_correspondencia'
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
    if matchedCitizenId then
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
        ('Resultado: %s | Cidadão: %s | Confiança: %d%%'):format(matchStatus, matchedName or 'N/A', confidence),
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
