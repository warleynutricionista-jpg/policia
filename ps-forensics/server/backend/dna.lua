-- ============================================================
-- PS-FORENSICS - Módulo: DNA (Server)
-- ============================================================

local resourceName = GetCurrentResourceName()

-- ============================================================
-- REGISTRAR PERFIL GENÉTICO DE CIDADÃO
-- ============================================================
lib.callback.register(resourceName .. ':server:registerDNAProfile', function(source, citizenid, citizenName, bloodType)
    local src = source
    if not CheckForensicAuth(src) then return { success = false } end

    if not citizenid then return { success = false, error = 'CitizenID obrigatório' } end

    local existing = MySQL.scalar.await('SELECT COUNT(*) FROM forensic_dna_profiles WHERE citizenid = ?', { citizenid })
    if existing and existing > 0 then
        return { success = false, error = 'Perfil genético já cadastrado' }
    end

    local hash = ForensicUtils.GenerateDNAHash(citizenid)
    local playerData = GetPlayerData(src)

    MySQL.insert.await([[
        INSERT INTO forensic_dna_profiles (citizenid, citizen_name, dna_hash, blood_type, registered_by)
        VALUES (?, ?, ?, ?, ?)
    ]], { citizenid, citizenName or '', hash, bloodType or 'Desconhecido', playerData and playerData.citizenid or '' })

    ForensicAuditLog(src, 'dna_profile_registered', 'dna_profile', nil, { citizenid = citizenid })

    return { success = true, hash = hash }
end)

-- ============================================================
-- COLETAR AMOSTRA DE DNA
-- ============================================================
lib.callback.register(resourceName .. ':server:collectDNASample', function(source, data)
    local src = source
    if not CheckForensicAuth(src) then return { success = false } end
    if not CheckForensicPermission(src, 'canCollectEvidence') then
        return { success = false, error = 'Sem permissão' }
    end

    local playerData = GetPlayerData(src)

    local sampleId = MySQL.insert.await([[
        INSERT INTO forensic_dna_samples
        (evidence_id, scene_id, source_type, source_description,
         match_status, collected_by, collected_by_name, notes)
        VALUES (?, ?, ?, ?, 'pendente', ?, ?, ?)
    ]], {
        data.evidence_id and tonumber(data.evidence_id) or nil,
        data.scene_id and tonumber(data.scene_id) or nil,
        data.source_type or 'outro',
        data.source_description or '',
        playerData.citizenid,
        playerData.name,
        data.notes or '',
    })

    ForensicAuditLog(src, 'dna_sample_collected', 'dna', sampleId, {
        source_type = data.source_type,
    })

    return { success = true, id = sampleId }
end)

-- ============================================================
-- ANALISAR / COMPARAR DNA
-- ============================================================
lib.callback.register(resourceName .. ':server:analyzeDNA', function(source, sampleId)
    local src = source
    if not CheckForensicAuth(src) then return { success = false } end
    if not CheckForensicPermission(src, 'canRunLabTests') then
        return { success = false, error = 'Sem permissão para análise laboratorial' }
    end

    sampleId = tonumber(sampleId)
    if not sampleId then return { success = false } end

    local playerData = GetPlayerData(src)
    local sample = MySQL.single.await('SELECT * FROM forensic_dna_samples WHERE id = ?', { sampleId })
    if not sample then return { success = false, error = 'Amostra não encontrada' } end

    -- Determinar cidadão-alvo
    local targetCitizenId = nil
    if sample.evidence_id then
        local ev = MySQL.single.await('SELECT linked_citizenid FROM forensic_evidence WHERE id = ?', { sample.evidence_id })
        if ev and ev.linked_citizenid then
            targetCitizenId = ev.linked_citizenid
        end
    end

    -- Qualidade de match por tipo de fonte
    local sourceQuality = {
        sangue = 0.95,
        cabelo = 0.80,
        saliva = 0.85,
        tecido = 0.90,
        suor = 0.60,
        roupa = 0.50,
        arma = 0.55,
        veiculo = 0.45,
        corpo_vitima = 0.95,
        corpo_suspeito = 0.95,
    }

    local chance = sourceQuality[sample.source_type] or 0.50
    local roll = math.random()

    local matchStatus = 'sem_correspondencia'
    local matchedCitizenId = nil
    local matchedName = nil
    local confidence = 0

    if targetCitizenId and roll <= chance then
        local profile = MySQL.single.await(
            'SELECT * FROM forensic_dna_profiles WHERE citizenid = ?',
            { targetCitizenId }
        )

        if profile then
            if chance >= 0.85 then
                matchStatus = 'compativel'
                confidence = 80 + math.random(20)
            elseif chance >= 0.60 then
                matchStatus = 'parcialmente_compativel'
                confidence = 50 + math.random(30)
            else
                matchStatus = 'parcialmente_compativel'
                confidence = 30 + math.random(30)
            end

            matchedCitizenId = profile.citizenid
            matchedName = profile.citizen_name

            MySQL.update.await(
                'UPDATE forensic_dna_samples SET dna_hash = ? WHERE id = ?',
                { profile.dna_hash, sampleId }
            )
        end
    elseif not targetCitizenId then
        -- Busca no banco inteiro (simulação)
        local allProfiles = MySQL.query.await('SELECT citizenid, citizen_name, dna_hash FROM forensic_dna_profiles LIMIT 100')
        if allProfiles and #allProfiles > 0 then
            -- Chance aleatória de match com alguém no banco
            if math.random() < 0.3 then
                local randomProfile = allProfiles[math.random(#allProfiles)]
                matchStatus = 'parcialmente_compativel'
                matchedCitizenId = randomProfile.citizenid
                matchedName = randomProfile.citizen_name
                confidence = 30 + math.random(40)
            end
        end
    end

    MySQL.update.await([[
        UPDATE forensic_dna_samples
        SET match_status = ?, matched_citizenid = ?, matched_name = ?,
            match_confidence = ?, dna_hash = COALESCE(dna_hash, ?),
            analyzed_by = ?, analyzed_at = NOW()
        WHERE id = ?
    ]], {
        matchStatus, matchedCitizenId, matchedName,
        confidence,
        ForensicUtils.GenerateDNAHash(tostring(sampleId) .. tostring(os.time())),
        playerData.citizenid, sampleId
    })

    -- Referência cruzada
    if matchedCitizenId then
        MySQL.insert.await([[
            INSERT INTO forensic_cross_references
            (source_type, source_id, target_type, target_id, relationship, confidence, created_by, notes)
            VALUES ('dna', ?, 'citizenid', ?, 'match_dna', ?, ?, ?)
        ]], {
            sampleId, matchedCitizenId,
            confidence >= 80 and 'confirmada' or (confidence >= 50 and 'alta' or 'media'),
            playerData.citizenid,
            ('DNA %s - Fonte: %s - Confiança: %d%%'):format(matchStatus, sample.source_type, confidence),
        })
    end

    -- Registrar teste
    MySQL.insert.await([[
        INSERT INTO forensic_lab_tests
        (evidence_id, scene_id, test_type, test_name, result_level, result_details,
         target_citizenid, target_name, requested_by, requested_by_name,
         performed_by, performed_by_name, started_at, completed_at, status)
        VALUES (?, ?, 'comparacao_dna', 'Comparação de Perfil Genético (DNA)', ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW(), 'concluido')
    ]], {
        sample.evidence_id, sample.scene_id,
        matchStatus == 'compativel' and 'confirmado' or (matchStatus == 'parcialmente_compativel' and 'compativel' or 'negativo'),
        ('DNA %s | Fonte: %s | Cidadão: %s | Confiança: %d%%'):format(matchStatus, sample.source_type, matchedName or 'N/A', confidence),
        matchedCitizenId, matchedName,
        playerData.citizenid, playerData.name,
        playerData.citizenid, playerData.name,
    })

    ForensicAuditLog(src, 'dna_analyzed', 'dna', sampleId, {
        matchStatus = matchStatus, matchedCitizenId = matchedCitizenId, confidence = confidence,
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
-- BUSCAR DNA POR CIDADÃO
-- ============================================================
lib.callback.register(resourceName .. ':server:searchDNAByCitizen', function(source, citizenid)
    local src = source
    if not CheckForensicAuth(src) then return {} end

    return MySQL.query.await([[
        SELECT ds.*, fe.evidence_number
        FROM forensic_dna_samples ds
        LEFT JOIN forensic_evidence fe ON ds.evidence_id = fe.id
        WHERE ds.matched_citizenid = ?
        ORDER BY ds.created_at DESC
    ]], { citizenid }) or {}
end)
