-- ============================================================
-- PS-FORENSICS - Módulo: DNA (Server)
-- ============================================================

local resourceName = GetCurrentResourceName()
local allowedSourceTypes = {
    sangue = true,
    cabelo = true,
    saliva = true,
    tecido = true,
    suor = true,
    roupa = true,
    arma = true,
    veiculo = true,
    corpo_vitima = true,
    corpo_suspeito = true,
    outro = true,
}

local sourceAliases = {
    tecido_biologico = 'tecido',
    vestigio_biologico = 'tecido',
    ['vestígio_biológico'] = 'tecido',
    ['veículo'] = 'veiculo',
}

local requiredItemBySource = {
    sangue = Config.Items.blood_reagent,
    cabelo = Config.Items.dna_swab,
    saliva = Config.Items.dna_swab,
    suor = Config.Items.dna_swab,
    tecido = Config.Items.dna_swab,
    corpo_vitima = Config.Items.dna_swab,
    corpo_suspeito = Config.Items.dna_swab,
    roupa = Config.Items.evidence_bag,
    arma = Config.Items.ballistic_kit,
    veiculo = Config.Items.evidence_marker,
    outro = Config.Items.forensic_kit,
}

local function normalizeSourceType(sourceType)
    local t = (sourceType or 'outro'):lower():gsub('%s+', '_')
    t = sourceAliases[t] or t
    if not allowedSourceTypes[t] then
        return 'outro'
    end
    return t
end

local function hasRequiredItem(src, itemName)
    if not itemName then return true end
    if GetResourceState('ox_inventory') ~= 'started' then return true end
    return (exports.ox_inventory:GetItemCount(src, itemName) or 0) > 0
end

local function getCitizenNameFromMDT(citizenid)
    if not citizenid or citizenid == '' then return nil end
    local row = MySQL.single.await('SELECT firstname, lastname FROM mdt_profiles WHERE citizenid = ?', { citizenid })
    if row then
        return (('%s %s'):format(row.firstname or '', row.lastname or '')):gsub('^%s*(.-)%s*$', '%1')
    end
    return nil
end

-- ============================================================
-- REGISTRAR PERFIL GENÉTICO DE CIDADÃO
-- ============================================================
lib.callback.register(resourceName .. ':server:registerDNAProfile', function(source, citizenid, citizenName, bloodType)
    local src = source
    if not CheckForensicAuth(src) then return { success = false, error = L('dna.errors.not_authorized') } end

    if not citizenid then return { success = false, error = L('dna.errors.citizenid_required') } end
    citizenid = tostring(citizenid)

    if not IsCitizenInInvestigativeBase(citizenid) then
        return { success = false, error = 'Cidadão fora da base investigativa criminal.' }
    end

    local existing = MySQL.single.await('SELECT id, dna_hash, dna_code FROM forensic_dna_profiles WHERE citizenid = ?', { citizenid })
    if existing then
        if not existing.dna_code or existing.dna_code == '' then
            local generatedCode = ('DNA-%08d'):format(tonumber(existing.id) or 0)
            MySQL.update.await('UPDATE forensic_dna_profiles SET dna_code = ? WHERE id = ?', { generatedCode, existing.id })
            existing.dna_code = generatedCode
        end
        return { success = true, hash = existing.dna_hash, code = existing.dna_code, reused = true }
    end

    local hash = ForensicUtils.GenerateDNAHash(citizenid)
    local playerData = GetPlayerData(src)
    local resolvedName = citizenName or getCitizenNameFromMDT(citizenid) or L('labels.unknown')

    local actorCitizenId = playerData and playerData.citizenid or 'system'
    local insertedId = MySQL.insert.await([[
        INSERT INTO forensic_dna_profiles (citizenid, citizen_name, dna_hash, blood_type, registered_by, created_by)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], { citizenid, resolvedName, hash, bloodType or L('labels.unknown'), actorCitizenId, actorCitizenId })

    local dnaCode = insertedId and ('DNA-%08d'):format(insertedId) or nil
    if insertedId and dnaCode then
        MySQL.update.await('UPDATE forensic_dna_profiles SET dna_code = ? WHERE id = ?', { dnaCode, insertedId })
    end

    local retroMatches = MySQL.query.await([[
        SELECT id FROM forensic_dna_samples
        WHERE dna_hash = ?
          AND (matched_citizenid IS NULL OR matched_citizenid = '')
    ]], { hash }) or {}

    for _, row in ipairs(retroMatches) do
        MySQL.update.await([[
            UPDATE forensic_dna_samples
            SET match_status = 'compativel',
                matched_citizenid = ?,
                matched_name = ?,
                match_confidence = 94,
                analyzed_by = ?,
                analyzed_at = NOW()
            WHERE id = ?
        ]], { citizenid, resolvedName, actorCitizenId, row.id })
    end

    EnsureInvestigativeSubject(citizenid, 'Perfil de DNA forense cadastrado', 'forensic_dna_profile', tostring(insertedId or ''), actorCitizenId)

    ForensicAuditLog(src, 'dna_profile_registered', 'dna_profile', nil, { citizenid = citizenid })

    return { success = true, hash = hash, code = dnaCode, retroMatches = #retroMatches }
end)

-- ============================================================
-- COLETAR AMOSTRA DE DNA
-- ============================================================
lib.callback.register(resourceName .. ':server:collectDNASample', function(source, data)
    local src = source
    if not CheckForensicAuth(src) then return { success = false, error = L('dna.errors.not_authorized') } end
    if not CheckForensicPermission(src, 'canCollectEvidence') then
        return { success = false, error = L('dna.errors.no_permission_collect') }
    end

    local playerData = GetPlayerData(src)
    if not playerData then return { success = false, error = L('scene.errors.player_data_unavailable') } end
    data = data or {}

    local evidenceId = data.evidence_id and tonumber(data.evidence_id) or nil
    local sceneId = data.scene_id and tonumber(data.scene_id) or nil
    local sourceType = normalizeSourceType(data.source_type)
    if data.subject_type == 'vitima' then
        sourceType = 'corpo_vitima'
    elseif data.subject_type == 'suspeito' then
        sourceType = 'corpo_suspeito'
    elseif data.subject_type == 'cadaver' and sourceType == 'outro' then
        sourceType = 'tecido'
    end
    local sourceDescription = data.source_description or L('dna.defaults.unknown_source')
    local notes = data.notes or ''
    local linkedCitizenId = data.linked_citizenid

    if evidenceId then
        local evidence = MySQL.single.await('SELECT id, scene_id, linked_citizenid FROM forensic_evidence WHERE id = ?', { evidenceId })
        if not evidence then
            return { success = false, error = L('dna.errors.evidence_not_found') }
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
                return { success = false, error = L('dna.errors.too_far_from_scene') }
            end
        end
    end

    local actionName = 'collect_biological'
    if sourceType == 'arma' or sourceType == 'veiculo' then
        actionName = 'collect_ballistic'
    end
    local itemValidation = ValidateAndConsumeForensicAction(src, actionName)
    if not itemValidation.success then
        return { success = false, error = itemValidation.error }
    end

    local sampleHash = nil
    if linkedCitizenId and linkedCitizenId ~= '' then
        local profile = MySQL.single.await('SELECT dna_hash FROM forensic_dna_profiles WHERE citizenid = ?', { linkedCitizenId })
        sampleHash = profile and profile.dna_hash or ForensicUtils.GenerateDNAHash(linkedCitizenId)
    else
        sampleHash = ForensicUtils.GenerateDNAHash(('%s-%s-%s'):format(sceneId or 0, evidenceId or 0, os.time()))
    end

    local sampleId = MySQL.insert.await([[
        INSERT INTO forensic_dna_samples
        (evidence_id, scene_id, source_type, source_description, dna_hash,
         match_status, collected_by, collected_by_name, notes)
        VALUES (?, ?, ?, ?, ?, 'pendente', ?, ?, ?)
    ]], {
        evidenceId,
        sceneId,
        sourceType,
        sourceDescription,
        sampleHash,
        playerData.citizenid,
        playerData.name,
        notes,
    })

    ForensicAuditLog(src, 'dna_sample_collected', 'dna', sampleId, {
        source_type = sourceType,
        linkedCitizenId = linkedCitizenId,
        actionName = actionName,
        usedItems = itemValidation.usedItems,
    })

    return { success = true, id = sampleId }
end)

-- ============================================================
-- ANALISAR / COMPARAR DNA
-- ============================================================
lib.callback.register(resourceName .. ':server:analyzeDNA', function(source, sampleId)
    local src = source
    if not CheckForensicAuth(src) then return { success = false, error = L('dna.errors.not_authorized') } end
    if not CheckForensicPermission(src, 'canRunLabTests') then
        return { success = false, error = L('dna.errors.no_permission_analyze') }
    end

    sampleId = tonumber(sampleId)
    if not sampleId then return { success = false, error = L('dna.errors.invalid_id') } end

    local playerData = GetPlayerData(src)
    if not playerData then return { success = false, error = L('scene.errors.player_data_unavailable') } end
    local sample = MySQL.single.await('SELECT * FROM forensic_dna_samples WHERE id = ?', { sampleId })
    if not sample then return { success = false, error = L('dna.errors.sample_not_found') } end

    -- Determinar cidadão-alvo
    local targetCitizenId = nil
    if sample.evidence_id then
        local ev = MySQL.single.await('SELECT linked_citizenid FROM forensic_evidence WHERE id = ?', { sample.evidence_id })
        if ev and ev.linked_citizenid then
            targetCitizenId = ev.linked_citizenid
        end
    end

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

    local matchStatus = 'sem_correspondencia'
    local matchedCitizenId = nil
    local matchedName = nil
    local confidence = 0

    if sample.source_type == 'outro' and chance < 0.55 then
        chance = 0.55
    end

    if sample.dna_hash and sample.dna_hash ~= '' then
        local exactProfile = MySQL.single.await(
            'SELECT citizenid, citizen_name, dna_hash FROM forensic_dna_profiles WHERE dna_hash = ?',
            { sample.dna_hash }
        )
        if exactProfile then
            matchedCitizenId = exactProfile.citizenid
            matchedName = exactProfile.citizen_name
            matchStatus = chance >= 0.75 and 'compativel' or 'parcialmente_compativel'
            confidence = math.floor((chance * 100) - 5 + math.random(15))
        end
    end

    if not matchedCitizenId and targetCitizenId then
        local profile = MySQL.single.await(
            'SELECT citizenid, citizen_name, dna_hash FROM forensic_dna_profiles WHERE citizenid = ?',
            { targetCitizenId }
        )

        if profile then
            matchedCitizenId = profile.citizenid
            matchedName = profile.citizen_name
            matchStatus = chance >= 0.75 and 'compativel' or 'parcialmente_compativel'
            confidence = math.floor((chance * 100) - 10 + math.random(20))

            MySQL.update.await(
                'UPDATE forensic_dna_samples SET dna_hash = ? WHERE id = ?',
                { profile.dna_hash, sampleId }
            )
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

    if matchedCitizenId and ForensicProcessIntelligenceMatch then
        local evidence = sample.evidence_id and MySQL.single.await('SELECT id, case_id, report_id, scene_id FROM forensic_evidence WHERE id = ?', { sample.evidence_id }) or nil
        local intelligence = ForensicProcessIntelligenceMatch({
            citizenid = matchedCitizenId,
            citizen_name = matchedName,
            case_id = evidence and evidence.case_id or nil,
            report_id = evidence and evidence.report_id or nil,
            scene_id = sample.scene_id or (evidence and evidence.scene_id or nil),
            evidence_id = sample.evidence_id,
            source_type = 'dna',
            source_id = sampleId,
            match_kind = 'dna',
            association_level = matchStatus == 'compativel' and 'confirmacao' or 'compatibilidade_parcial',
            confidence_score = confidence,
            algorithm_name = 'dna_profile_match_v1',
            algorithm_version = '2026.03',
            exam_performed_by = playerData.citizenid,
            generated_by = playerData.citizenid,
            exam_origin = sample.source_type,
            rationale = ('Match de DNA (%s) com confiança %d%%'):format(matchStatus, confidence),
            metadata = {
                sample_id = sampleId,
                source_type = sample.source_type,
                match_status = matchStatus,
            },
        })
        if intelligence and intelligence.autoWanted then
            ForensicAuditLog(src, 'forensic_auto_wanted_from_dna', 'dna', sampleId, {
                citizenid = matchedCitizenId,
                confidence = confidence,
            })
        end
    end

    ForensicAuditLog(src, 'dna_analyzed', 'dna', sampleId, {
        matchStatus = matchStatus, matchedCitizenId = matchedCitizenId, confidence = confidence,
    })

    return {
        success = true,
        matchStatus = matchStatus,
        matchedCitizenId = matchedCitizenId,
        matchedName = matchedName,
        confidence = confidence,
        resultLabel = L(('dna.result.%s'):format(matchStatus)),
        forensicReport = ('DNA %s | Fonte: %s | Vínculo: %s | Confiança: %d%%'):format(
            matchStatus,
            sample.source_type,
            matchedName or L('labels.unknown'),
            confidence
        ),
    }
end)

-- ============================================================
-- BUSCAR DNA POR CIDADÃO
-- ============================================================
lib.callback.register(resourceName .. ':server:searchDNAByCitizen', function(source, citizenid)
    local src = source
    if not CheckForensicAuth(src) then return {} end
    if not IsCitizenInInvestigativeBase(citizenid) then return {} end

    return MySQL.query.await([[
        SELECT ds.*, fe.evidence_number, dp.dna_code
        FROM forensic_dna_samples ds
        LEFT JOIN forensic_evidence fe ON ds.evidence_id = fe.id
        LEFT JOIN forensic_dna_profiles dp ON dp.citizenid = ds.matched_citizenid
        WHERE ds.matched_citizenid = ?
        ORDER BY ds.created_at DESC
    ]], { citizenid }) or {}
end)
