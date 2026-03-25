-- ============================================================
-- PS-FORENSICS - Módulo: Inteligência Forense Investigativa
-- ============================================================

local resourceName = GetCurrentResourceName()

local LEVEL_MULTIPLIER = {
    vestigio_relacionado = 0.55,
    presumido = 0.70,
    inconclusivo = 0.35,
    compatibilidade_parcial = 0.80,
    compatibilidade_forte = 1.00,
    confirmacao = 1.30,
}

local MATCH_WEIGHT_FALLBACK = {
    dna = 45,
    digital = 35,
    capsula = 30,
    projetil = 30,
    arma = 42,
    residuo_polvora = 24,
    material_biologico = 28,
    objeto = 16,
    veiculo = 22,
}

local SUSPICION_LEVELS = {
    { id = 'sem_suspeicao', min = 0, max = 24 },
    { id = 'pessoa_interesse', min = 25, max = 49 },
    { id = 'suspeito_tecnico', min = 50, max = 74 },
    { id = 'suspeito_prioritario', min = 75, max = 99 },
    { id = 'procurado_automatico', min = 100, max = 9999 },
}

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

local function normalizeAssociationLevel(level)
    local map = {
        vestigio = 'vestigio_relacionado',
        vestigio_relacionado = 'vestigio_relacionado',
        parcial = 'compatibilidade_parcial',
        compativel = 'compatibilidade_parcial',
        compatibilidade_parcial = 'compatibilidade_parcial',
        forte = 'compatibilidade_forte',
        compatibilidade_forte = 'compatibilidade_forte',
        confirmacao = 'confirmacao',
        confirmado = 'confirmacao',
        confirmacao_total = 'confirmacao',
        presumido = 'presumido',
        inconclusivo = 'inconclusivo',
    }

    local key = tostring(level or ''):lower():gsub('%s+', '_')
    return map[key] or 'compatibilidade_parcial'
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
        vehicle = 'veiculo',
        veiculo = 'veiculo',
        object = 'objeto',
        objeto = 'objeto',
    }

    local k = tostring(kind or ''):lower():gsub('%s+', '_')
    return aliases[k] or 'material_biologico'
end

local function mapConfidenceToAssociation(score)
    local s = tonumber(score) or 0
    if s >= 92 then return 'confirmacao' end
    if s >= 75 then return 'compatibilidade_forte' end
    if s >= 45 then return 'compatibilidade_parcial' end
    return 'vestigio_relacionado'
end

local function getSuspicionLevel(score)
    local s = tonumber(score) or 0
    for _, level in ipairs(SUSPICION_LEVELS) do
        if s >= level.min and s <= level.max then
            return level.id
        end
    end
    return 'sem_suspeicao'
end

local function ensureCitizenProfile(citizenid, actorCitizenId)
    if not citizenid or citizenid == '' then return nil end

    local existing = MySQL.single.await('SELECT id FROM forensic_citizen_profiles WHERE citizenid = ? LIMIT 1', { citizenid })
    if existing and existing.id then
        return existing.id
    end

    local createdId = MySQL.insert.await([[
        INSERT INTO forensic_citizen_profiles
        (citizenid, citizen_name, job_name, identification_status, created_by, updated_by)
        VALUES (?, ?, ?, 'confirmado_identificado', ?, ?)
    ]], {
        citizenid,
        getCitizenName(citizenid) or 'Desconhecido',
        '',
        actorCitizenId or 'system',
        actorCitizenId or 'system',
    })

    return createdId
end

local function loadSuspicionRule(matchKind, associationLevel)
    local row = MySQL.single.await([[
        SELECT * FROM forensic_suspicion_rules
        WHERE enabled = 1
          AND (match_kind = ? OR match_kind = 'all')
          AND (association_level = ? OR association_level = 'all')
        ORDER BY priority DESC, id ASC
        LIMIT 1
    ]], { matchKind, associationLevel })

    if row then return row end

    return {
        rule_key = 'fallback_rule',
        base_weight = MATCH_WEIGHT_FALLBACK[matchKind] or 20,
        confidence_multiplier = 1.0,
        reliability_multiplier = 1.0,
        requires_manual_review = 0,
        can_auto_wanted = 0,
    }
end

local function createAlert(citizenid, caseId, reportId, severity, title, message, metadata)
    MySQL.insert.await([[
        INSERT INTO forensic_intelligence_alerts
        (citizenid, case_id, report_id, severity, title, message, status, metadata)
        VALUES (?, ?, ?, ?, ?, ?, 'novo', ?)
    ]], { citizenid, caseId, reportId, severity, title, message, json.encode(metadata or {}) })
end

local function computeSuspicion(citizenid)
    local links = MySQL.query.await([[
        SELECT id, match_kind, association_level, confidence_score, metadata, created_at
        FROM forensic_intelligence_links
        WHERE citizenid = ?
          AND review_status != 'invalidado'
          AND created_at >= DATE_SUB(NOW(), INTERVAL 45 DAY)
    ]], { citizenid }) or {}

    local total, factors, distinctEvidence = 0, {}, {}

    for _, link in ipairs(links) do
        local mk = normalizeMatchKind(link.match_kind)
        local al = normalizeAssociationLevel(link.association_level)
        local rule = loadSuspicionRule(mk, al)
        local confidence = tonumber(link.confidence_score) or 0
        local metadata = {}
        if link.metadata and link.metadata ~= '' then
            metadata = json.decode(link.metadata) or {}
        end
        local reliability = tonumber(metadata.reliability_factor) or 1.0

        local weighted = (tonumber(rule.base_weight) or (MATCH_WEIGHT_FALLBACK[mk] or 20))
            * (LEVEL_MULTIPLIER[al] or 0.75)
            * (tonumber(rule.confidence_multiplier) or 1.0)
            * (math.max(confidence, 1) / 100)
            * (tonumber(rule.reliability_multiplier) or 1.0)
            * reliability

        total = total + weighted
        factors[#factors + 1] = {
            link_id = link.id,
            match_kind = mk,
            association_level = al,
            confidence = confidence,
            rule_key = rule.rule_key,
            weighted_score = math.floor(weighted * 100) / 100,
            can_auto_wanted = tonumber(rule.can_auto_wanted or 0) == 1,
        }

        if link.id then
            distinctEvidence[tostring(link.id)] = true
        end
    end

    local factorCount = 0
    local hasCritical = false
    for _, factor in ipairs(factors) do
        factorCount = factorCount + 1
        if factor.can_auto_wanted and factor.weighted_score >= 30 then
            hasCritical = true
        end
    end

    local normalized = math.floor(total + 0.5)
    local level = getSuspicionLevel(normalized)

    return {
        score = normalized,
        level = level,
        factors = factors,
        factorCount = factorCount,
        hasCritical = hasCritical,
    }
end

local function maybeCreateAutoWarrant(citizenid, caseId, reportId, suspicion, trigger)
    if not citizenid or citizenid == '' then return false end
    if not suspicion then return false end

    local threshold = tonumber(MySQL.scalar.await([[SELECT value_number FROM forensic_suspicion_settings WHERE setting_key = 'auto_wanted_threshold' LIMIT 1]])) or 100
    local minFactors = tonumber(MySQL.scalar.await([[SELECT value_number FROM forensic_suspicion_settings WHERE setting_key = 'auto_wanted_min_factors' LIMIT 1]])) or 3

    if suspicion.score < threshold then return false end
    if suspicion.factorCount < minFactors and not suspicion.hasCritical then return false end

    local resolvedReportId = tonumber(reportId)
    if not resolvedReportId and caseId then
        resolvedReportId = tonumber(MySQL.scalar.await('SELECT report_id FROM mdt_case_reports WHERE case_id = ? ORDER BY id DESC LIMIT 1', { tonumber(caseId) }))
    end
    if not resolvedReportId then return false end

    local existing = MySQL.single.await(
        'SELECT reportid FROM mdt_reports_warrants WHERE reportid = ? AND citizenid = ? AND expirydate >= NOW() LIMIT 1',
        { resolvedReportId, citizenid }
    )
    if existing then return false end

    local expiryDate = os.date('%Y-%m-%d %H:%M:%S', os.time() + (7 * 24 * 60 * 60))
    MySQL.insert.await([[
        INSERT INTO mdt_reports_warrants (reportid, citizenid, felonies, misdemeanors, infractions, expirydate)
        VALUES (?, ?, 1, 0, 0, ?)
    ]], { resolvedReportId, citizenid, expiryDate })

    MySQL.insert.await([[
        INSERT INTO forensic_watchlist_events
        (citizenid, created_by, event_type, report_id, case_id, reason, source_module,
         source_type, source_id, algorithm_name, algorithm_version, confidence_score, association_level, metadata)
        VALUES (?, 'system', 'auto_wanted_added', ?, ?, ?, 'forensics_intelligence',
                ?, ?, 'suspicion_engine', 'v2', ?, ?, ?)
    ]], {
        citizenid,
        resolvedReportId,
        caseId,
        ('Entrada automática em procurados por score %d e regra %s'):format(suspicion.score, trigger or 'threshold'),
        trigger or 'score',
        0,
        suspicion.score,
        "confirmacao",
        json.encode({ expiryDate = expiryDate, factors = suspicion.factors, suspicion_level = suspicion.level }),
    })

    createAlert(citizenid, caseId, resolvedReportId, 'critico', 'Entrada automática em Procurados',
        ('Cidadão entrou em Procurados automaticamente (score %d).'):format(suspicion.score),
        { suspicion = suspicion, reason = trigger })

    return true
end

local function persistSuspicionSnapshot(citizenid, profileId, caseId, reportId, sceneId, sourceType, sourceId, suspicion)
    MySQL.insert.await([[
        INSERT INTO forensic_suspicion_snapshots
        (profile_id, citizenid, case_id, report_id, scene_id, source_type, source_id,
         suspicion_level, score_total, score_breakdown, triggered_rule, auto_wanted_candidate)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        profileId,
        citizenid,
        caseId,
        reportId,
        sceneId,
        sourceType,
        sourceId,
        suspicion.level,
        suspicion.score,
        json.encode(suspicion.factors),
        'rolling_45d',
        suspicion.score >= 100 and 1 or 0,
    })

    MySQL.update.await([[
        UPDATE forensic_citizen_profiles
        SET suspicion_score = ?, suspicion_level = ?, last_match_at = NOW(), updated_at = NOW(), updated_by = 'system'
        WHERE citizenid = ?
    ]], { suspicion.score, suspicion.level, citizenid })
end

function ForensicAttachEvidenceToCitizen(data)
    if type(data) ~= 'table' then return end
    if not data.citizenid or data.citizenid == '' or not data.evidence_id then return end

    local profileId = ensureCitizenProfile(data.citizenid, data.actor_citizenid)

    MySQL.insert.await([[
        INSERT INTO forensic_evidence_person_links
        (evidence_id, citizenid, profile_id, possession_type, link_origin, confidence_score, linked_by, notes)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            confidence_score = GREATEST(confidence_score, VALUES(confidence_score)),
            notes = VALUES(notes),
            updated_at = NOW()
    ]], {
        tonumber(data.evidence_id),
        data.citizenid,
        profileId,
        data.possession_type or 'ambiente',
        data.link_origin or 'apreensao',
        tonumber(data.confidence_score) or 65,
        data.actor_citizenid or 'system',
        data.notes or '',
    })
end

function ForensicProcessIntelligenceMatch(match)
    if type(match) ~= 'table' or not match.citizenid or match.citizenid == '' then return nil end

    local confidence = tonumber(match.confidence_score) or 0
    local association = normalizeAssociationLevel(match.association_level or mapConfidenceToAssociation(confidence))
    local actor = match.generated_by or match.exam_performed_by or 'system'
    local profileId = ensureCitizenProfile(match.citizenid, actor)

    local id = MySQL.insert.await([[
        INSERT INTO forensic_intelligence_links
        (citizenid, citizen_name, case_id, report_id, scene_id, evidence_id,
         source_type, source_id, match_kind, association_level, confidence_score,
         algorithm_name, algorithm_version, exam_performed_by, exam_generated_by,
         created_by, exam_origin, rationale, metadata, review_status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pendente')
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
        match.algorithm_version or 'v2',
        match.exam_performed_by or '',
        match.generated_by or '',
        actor,
        match.exam_origin or 'laboratorio',
        match.rationale or '',
        json.encode(match.metadata or {}),
    })

    ForensicAttachEvidenceToCitizen({
        citizenid = match.citizenid,
        evidence_id = match.evidence_id,
        actor_citizenid = actor,
        possession_type = match.possession_type or 'ambiente',
        link_origin = 'match_forense',
        confidence_score = confidence,
        notes = match.rationale,
    })

    local suspicion = computeSuspicion(match.citizenid)
    persistSuspicionSnapshot(match.citizenid, profileId, match.case_id, match.report_id, match.scene_id, match.source_type, match.source_id, suspicion)

    local autoWanted = maybeCreateAutoWarrant(match.citizenid, match.case_id, match.report_id, suspicion, normalizeMatchKind(match.match_kind))

    MySQL.insert.await([[
        INSERT INTO forensic_watchlist_events
        (citizenid, created_by, event_type, report_id, case_id, source_module, source_type, source_id,
         reason, algorithm_name, algorithm_version, confidence_score, association_level, metadata)
        VALUES (?, ?, 'suspect_linked', ?, ?, 'forensics_intelligence', ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        match.citizenid,
        actor,
        match.report_id,
        match.case_id,
        match.source_type or 'forense',
        match.source_id,
        match.rationale or 'Vínculo automático por match forense',
        match.algorithm_name or 'rule_engine',
        match.algorithm_version or 'v2',
        confidence,
        association,
        json.encode({ metadata = match.metadata or {}, suspicion = suspicion, autoWanted = autoWanted }),
    })

    createAlert(match.citizenid, match.case_id, match.report_id,
        autoWanted and 'critico' or (suspicion.level == 'suspeito_prioritario' and 'alto' or 'medio'),
        'Novo vínculo forense técnico',
        ('%s com confiança %.1f%% gerou nível %s (score %d).'):format(normalizeMatchKind(match.match_kind), confidence, suspicion.level, suspicion.score),
        { intelligence_id = id, suspicion = suspicion, autoWanted = autoWanted })

    return {
        id = id,
        autoWanted = autoWanted,
        associationLevel = association,
        suspicion = suspicion,
        createdAt = os.date('%Y-%m-%d %H:%M:%S'),
    }
end

function ForensicEnsureCitizenForensicProfiles(citizenid, actorCitizenId, reason)
    if not citizenid or citizenid == '' then return { createdFingerprint = false, createdDNA = false } end

    local createdFingerprint = false
    local createdDNA = false

    local fpExists = tonumber(MySQL.scalar.await('SELECT COUNT(*) FROM forensic_fingerprint_profiles WHERE citizenid = ?', { citizenid })) or 0
    if fpExists == 0 then
        MySQL.insert.await([[
            INSERT INTO forensic_fingerprint_profiles (citizenid, citizen_name, fingerprint_hash, registered_by, created_by)
            VALUES (?, ?, ?, ?, ?)
        ]], { citizenid, getCitizenName(citizenid) or 'Desconhecido', ForensicUtils.GenerateFingerprintHash(citizenid), actorCitizenId or 'system', actorCitizenId or 'system' })
        createdFingerprint = true
    end

    local dnaExists = tonumber(MySQL.scalar.await('SELECT COUNT(*) FROM forensic_dna_profiles WHERE citizenid = ?', { citizenid })) or 0
    if dnaExists == 0 then
        MySQL.insert.await([[
            INSERT INTO forensic_dna_profiles (citizenid, citizen_name, dna_hash, blood_type, registered_by, created_by)
            VALUES (?, ?, ?, ?, ?, ?)
        ]], { citizenid, getCitizenName(citizenid) or 'Desconhecido', ForensicUtils.GenerateDNAHash(citizenid), 'DESCONHECIDO', actorCitizenId or 'system', actorCitizenId or 'system' })
        createdDNA = true
    end

    ensureCitizenProfile(citizenid, actorCitizenId)

    if createdFingerprint or createdDNA then
        MySQL.insert.await([[
            INSERT INTO forensic_watchlist_events
            (citizenid, created_by, event_type, reason, source_module, algorithm_name, confidence_score, metadata)
            VALUES (?, ?, 'profile_seeded', ?, 'prison', 'prison_profile_seed', 100, ?)
        ]], { citizenid, actorCitizenId or 'system', reason or 'Cadastro automático de perfil forense por prisão', json.encode({ createdFingerprint = createdFingerprint, createdDNA = createdDNA }) })
    end

    return { createdFingerprint = createdFingerprint, createdDNA = createdDNA }
end

lib.callback.register(resourceName .. ':server:reviewIntelligenceMatch', function(source, payload)
    local src = source
    if not CheckForensicAuth(src) then return { success = false, error = 'Não autorizado' } end
    if not (CheckForensicPermission(src, 'canRunLabTests') or CheckForensicPermission(src, 'canEmitReport')) then
        return { success = false, error = 'Sem permissão para revisão' }
    end

    payload = payload or {}
    local linkId = tonumber(payload.link_id)
    if not linkId then return { success = false, error = 'link_id inválido' } end

    local decision = tostring(payload.decision or 'confirmado')
    if decision ~= 'confirmado' and decision ~= 'rebaixado' and decision ~= 'invalidado' and decision ~= 'reexame' then
        decision = 'confirmado'
    end

    local playerData = GetPlayerData(src)
    local reviewer = playerData and playerData.citizenid or 'system'
    local note = tostring(payload.justification or ''):sub(1, 1200)

    local link = MySQL.single.await('SELECT * FROM forensic_intelligence_links WHERE id = ? LIMIT 1', { linkId })
    if not link then return { success = false, error = 'Vínculo não encontrado' } end

    MySQL.insert.await([[
        INSERT INTO forensic_intelligence_reviews
        (intelligence_link_id, citizenid, decision, previous_association_level, new_association_level,
         previous_confidence, new_confidence, reviewed_by, reviewed_by_name, justification)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        linkId,
        link.citizenid,
        decision,
        link.association_level,
        payload.new_association_level or link.association_level,
        link.confidence_score,
        tonumber(payload.new_confidence) or link.confidence_score,
        reviewer,
        playerData and playerData.name or reviewer,
        note,
    })

    MySQL.update.await([[
        UPDATE forensic_intelligence_links
        SET review_status = ?, reviewed_by = ?, reviewed_at = NOW(), review_notes = ?,
            association_level = ?, confidence_score = ?, updated_at = NOW()
        WHERE id = ?
    ]], {
        decision,
        reviewer,
        note,
        payload.new_association_level or link.association_level,
        tonumber(payload.new_confidence) or link.confidence_score,
        linkId,
    })

    local suspicion = computeSuspicion(link.citizenid)
    local profileId = ensureCitizenProfile(link.citizenid, reviewer)
    persistSuspicionSnapshot(link.citizenid, profileId, link.case_id, link.report_id, link.scene_id, link.source_type, link.source_id, suspicion)

    return { success = true, suspicion = suspicion }
end)

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
