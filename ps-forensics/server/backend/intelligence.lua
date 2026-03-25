-- ============================================================
-- PS-FORENSICS - Módulo: Inteligência Forense Investigativa
-- ============================================================

local resourceName = GetCurrentResourceName()

local function normalizeAssociationLevel(level)
    local map = {
        vestigio = 'vestigio_relacionado',
        vestigio_relacionado = 'vestigio_relacionado',
        parcial = 'compatibilidade_parcial',
        compatibilidade_parcial = 'compatibilidade_parcial',
        forte = 'compatibilidade_forte',
        compatibilidade_forte = 'compatibilidade_forte',
        confirmacao = 'confirmacao',
        confirmacao_total = 'confirmacao',
    }

    local key = tostring(level or ''):lower():gsub('%s+', '_')
    return map[key] or 'compatibilidade_parcial'
end

local function mapConfidenceToAssociation(score)
    local s = tonumber(score) or 0
    if s >= 92 then return 'confirmacao' end
    if s >= 75 then return 'compatibilidade_forte' end
    if s >= 45 then return 'compatibilidade_parcial' end
    return 'vestigio_relacionado'
end

local function normalizeMatchKind(kind)
    local aliases = {
        fingerprint = 'digital',
        dna = 'dna',
        ballistic = 'capsula',
        capsula = 'capsula',
        projetil = 'projetil',
        arma = 'arma',
        gsr = 'residuo_polvora',
        residuo_polvora = 'residuo_polvora',
        biologico = 'material_biologico',
        material_biologico = 'material_biologico',
    }

    local k = tostring(kind or ''):lower():gsub('%s+', '_')
    return aliases[k] or 'material_biologico'
end

local function getCitizenName(citizenid)
    if not citizenid or citizenid == '' then return nil end
    local row = MySQL.single.await('SELECT firstname, lastname FROM mdt_profiles WHERE citizenid = ? LIMIT 1', { citizenid })
    if row then
        return (('%s %s'):format(row.firstname or '', row.lastname or '')):gsub('^%s*(.-)%s*$', '%1')
    end

    row = MySQL.single.await([[
        SELECT
            JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname')) AS firstname,
            JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname')) AS lastname
        FROM players WHERE citizenid = ? LIMIT 1
    ]], { citizenid })

    if row then
        return (('%s %s'):format(row.firstname or '', row.lastname or '')):gsub('^%s*(.-)%s*$', '%1')
    end

    return nil
end

local function ensureProfile(citizenid, actorCitizenId, profileType, reason)
    if not citizenid or citizenid == '' then return false end

    if profileType == 'digital' then
        local exists = tonumber(MySQL.scalar.await('SELECT COUNT(*) FROM forensic_fingerprint_profiles WHERE citizenid = ?', { citizenid })) or 0
        if exists > 0 then return false end

        MySQL.insert.await([[
            INSERT INTO forensic_fingerprint_profiles (citizenid, citizen_name, fingerprint_hash, registered_by)
            VALUES (?, ?, ?, ?)
        ]], {
            citizenid,
            getCitizenName(citizenid) or 'Desconhecido',
            ForensicUtils.GenerateFingerprintHash(citizenid),
            actorCitizenId or 'system',
        })

        MySQL.insert.await([[
            INSERT INTO forensic_watchlist_events
            (citizenid, event_type, reason, source_module, algorithm_name, confidence_score, metadata)
            VALUES (?, 'profile_seeded', ?, 'prison', 'prison_profile_seed', 100, ?)
        ]], { citizenid, reason or 'Cadastro automático de digital em prisão', json.encode({ profileType = profileType }) })

        return true
    end

    if profileType == 'dna' then
        local exists = tonumber(MySQL.scalar.await('SELECT COUNT(*) FROM forensic_dna_profiles WHERE citizenid = ?', { citizenid })) or 0
        if exists > 0 then return false end

        MySQL.insert.await([[
            INSERT INTO forensic_dna_profiles (citizenid, citizen_name, dna_hash, blood_type, registered_by)
            VALUES (?, ?, ?, ?, ?)
        ]], {
            citizenid,
            getCitizenName(citizenid) or 'Desconhecido',
            ForensicUtils.GenerateDNAHash(citizenid),
            'DESCONHECIDO',
            actorCitizenId or 'system',
        })

        MySQL.insert.await([[
            INSERT INTO forensic_watchlist_events
            (citizenid, event_type, reason, source_module, algorithm_name, confidence_score, metadata)
            VALUES (?, 'profile_seeded', ?, 'prison', 'prison_profile_seed', 100, ?)
        ]], { citizenid, reason or 'Cadastro automático de DNA em prisão', json.encode({ profileType = profileType }) })

        return true
    end

    return false
end

function ForensicEnsureCitizenForensicProfiles(citizenid, actorCitizenId, reason)
    if not citizenid or citizenid == '' then return { createdFingerprint = false, createdDNA = false } end

    local createdFingerprint = ensureProfile(citizenid, actorCitizenId, 'digital', reason)
    local createdDNA = ensureProfile(citizenid, actorCitizenId, 'dna', reason)

    return {
        createdFingerprint = createdFingerprint,
        createdDNA = createdDNA,
    }
end

local function maybeCreateAutoWarrant(match)
    local confidence = tonumber(match.confidence_score) or 0
    local association = normalizeAssociationLevel(match.association_level)
    if confidence < 86 then return false end
    if association ~= 'compatibilidade_forte' and association ~= 'confirmacao' then return false end
    if not match.report_id and not match.case_id then return false end

    local reportId = tonumber(match.report_id)
    if not reportId and match.case_id then
        reportId = tonumber(MySQL.scalar.await('SELECT report_id FROM mdt_case_reports WHERE case_id = ? ORDER BY id DESC LIMIT 1', { tonumber(match.case_id) }))
    end
    if not reportId then return false end

    local existing = MySQL.single.await(
        'SELECT reportid FROM mdt_reports_warrants WHERE reportid = ? AND citizenid = ? AND expirydate >= NOW() LIMIT 1',
        { reportId, match.citizenid }
    )

    if existing then return false end

    local expiryDate = os.date('%Y-%m-%d %H:%M:%S', os.time() + (7 * 24 * 60 * 60))
    MySQL.insert.await([[
        INSERT INTO mdt_reports_warrants (reportid, citizenid, felonies, misdemeanors, infractions, expirydate)
        VALUES (?, ?, 1, 0, 0, ?)
    ]], { reportId, match.citizenid, expiryDate })

    local reason = ('Inclusão automática por inteligência forense (%s, %.1f%%). Origem: %s #%s'):format(
        normalizeMatchKind(match.match_kind), confidence, tostring(match.source_type or 'forense'), tostring(match.source_id or 0)
    )

    MySQL.insert.await([[
        INSERT INTO forensic_watchlist_events
        (citizenid, event_type, report_id, case_id, reason, source_module, source_type, source_id,
         algorithm_name, algorithm_version, confidence_score, association_level, metadata)
        VALUES (?, 'auto_wanted_added', ?, ?, ?, 'forensics_intelligence', ?, ?, ?, ?, ?, ?, ?)
    ]], {
        match.citizenid,
        reportId,
        match.case_id,
        reason,
        match.source_type,
        match.source_id,
        match.algorithm_name or 'rule_engine',
        match.algorithm_version or 'v1',
        confidence,
        association,
        json.encode({ expiryDate = expiryDate, generatedBy = match.generated_by }),
    })

    return true
end

function ForensicProcessIntelligenceMatch(match)
    if type(match) ~= 'table' or not match.citizenid or match.citizenid == '' then return nil end

    local confidence = tonumber(match.confidence_score) or 0
    local association = normalizeAssociationLevel(match.association_level or mapConfidenceToAssociation(confidence))
    local createdAt = os.date('%Y-%m-%d %H:%M:%S')

    local id = MySQL.insert.await([[
        INSERT INTO forensic_intelligence_links
        (citizenid, citizen_name, case_id, report_id, scene_id, evidence_id,
         source_type, source_id, match_kind, association_level, confidence_score,
         algorithm_name, algorithm_version, exam_performed_by, exam_generated_by,
         exam_origin, rationale, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        match.citizenid,
        match.citizen_name or getCitizenName(match.citizenid) or 'Desconhecido',
        match.case_id,
        match.report_id,
        match.scene_id,
        match.evidence_id,
        match.source_type or 'forense',
        tonumber(match.source_id) or nil,
        normalizeMatchKind(match.match_kind),
        association,
        confidence,
        match.algorithm_name or 'rule_engine',
        match.algorithm_version or 'v1',
        match.exam_performed_by or '',
        match.generated_by or '',
        match.exam_origin or 'laboratorio',
        match.rationale or '',
        json.encode(match.metadata or {}),
    })

    MySQL.insert.await([[
        INSERT INTO forensic_watchlist_events
        (citizenid, event_type, report_id, case_id, source_module, source_type, source_id,
         reason, algorithm_name, algorithm_version, confidence_score, association_level, metadata)
        VALUES (?, 'suspect_linked', ?, ?, 'forensics_intelligence', ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        match.citizenid,
        match.report_id,
        match.case_id,
        match.source_type or 'forense',
        match.source_id,
        match.rationale or 'Vínculo automático por match forense',
        match.algorithm_name or 'rule_engine',
        match.algorithm_version or 'v1',
        confidence,
        association,
        json.encode(match.metadata or {}),
    })

    local autoWanted = maybeCreateAutoWarrant({
        citizenid = match.citizenid,
        source_type = match.source_type,
        source_id = match.source_id,
        report_id = match.report_id,
        case_id = match.case_id,
        confidence_score = confidence,
        association_level = association,
        match_kind = match.match_kind,
        algorithm_name = match.algorithm_name,
        algorithm_version = match.algorithm_version,
        generated_by = match.generated_by,
    })

    return {
        id = id,
        autoWanted = autoWanted,
        associationLevel = association,
        createdAt = createdAt,
    }
end

RegisterNetEvent(resourceName .. ':server:seedProfilesFromPrison', function(payload)
    local data = payload or {}
    local citizenid = tostring(data.citizenid or '')
    if citizenid == '' then return end

    local actorCitizenId = tostring(data.actor_citizenid or 'system')
    local result = ForensicEnsureCitizenForensicProfiles(citizenid, actorCitizenId, data.reason or 'Registro de prisão')

    ForensicAuditLog(nil, 'forensic_profiles_seeded_from_prison', 'citizen', nil, {
        citizenid = citizenid,
        createdFingerprint = result.createdFingerprint,
        createdDNA = result.createdDNA,
        actor = actorCitizenId,
    })
end)
