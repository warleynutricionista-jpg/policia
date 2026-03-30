-- ============================================================
-- PS-FORENSICS - Módulo: Cruzamento de Dados (Server)
-- ============================================================

local resourceName = GetCurrentResourceName()

-- ============================================================
-- BUSCAR CRUZAMENTOS POR CIDADÃO
-- ============================================================
lib.callback.register(resourceName .. ':server:getCrossRefByCitizen', function(source, citizenid)
    local src = source
    if not CheckForensicAuth(src) then return {} end
    if not citizenid then return {} end

    local refs = MySQL.query.await([[
        SELECT * FROM forensic_cross_references
        WHERE (target_type = 'citizenid' AND target_id = ?)
        ORDER BY created_at DESC LIMIT 50
    ]], { citizenid })

    -- Enriquecer com dados da fonte
    for _, ref in ipairs(refs or {}) do
        if ref.source_type == 'fingerprint' then
            local fp = MySQL.single.await('SELECT * FROM forensic_fingerprints_collected WHERE id = ?', { ref.source_id })
            ref.source_data = fp
        elseif ref.source_type == 'dna' then
            local dna = MySQL.single.await('SELECT * FROM forensic_dna_samples WHERE id = ?', { ref.source_id })
            ref.source_data = dna
        elseif ref.source_type == 'ballistic' then
            local bal = MySQL.single.await('SELECT * FROM forensic_ballistics WHERE id = ?', { ref.source_id })
            ref.source_data = bal
        elseif ref.source_type == 'evidence' then
            local ev = MySQL.single.await('SELECT * FROM forensic_evidence WHERE id = ?', { ref.source_id })
            ref.source_data = ev
        end
    end

    return refs or {}
end)

-- ============================================================
-- BUSCAR CRUZAMENTOS POR ARMA
-- ============================================================
lib.callback.register(resourceName .. ':server:getCrossRefByWeapon', function(source, weaponSerial)
    local src = source
    if not CheckForensicAuth(src) then return {} end
    if not weaponSerial then return {} end

    local refs = MySQL.query.await([[
        SELECT * FROM forensic_cross_references
        WHERE (target_type = 'weapon' AND target_id = ?)
        ORDER BY created_at DESC LIMIT 50
    ]], { weaponSerial })

    return refs or {}
end)

-- ============================================================
-- BUSCAR CRUZAMENTOS POR VEÍCULO
-- ============================================================
lib.callback.register(resourceName .. ':server:getCrossRefByVehicle', function(source, plate)
    local src = source
    if not CheckForensicAuth(src) then return {} end
    if not plate then return {} end

    local refs = MySQL.query.await([[
        SELECT * FROM forensic_cross_references
        WHERE (target_type = 'vehicle' AND target_id = ?)
        ORDER BY created_at DESC LIMIT 50
    ]], { plate })

    return refs or {}
end)

-- ============================================================
-- BUSCAR CRUZAMENTOS POR CENA
-- ============================================================
lib.callback.register(resourceName .. ':server:getCrossRefByScene', function(source, sceneId)
    local src = source
    if not CheckForensicAuth(src) then return {} end

    sceneId = tonumber(sceneId)
    if not sceneId then return {} end

    local refs = MySQL.query.await([[
        SELECT * FROM forensic_cross_references
        WHERE (target_type = 'scene' AND target_id = ?)
           OR (source_type = 'scene' AND source_id = ?)
        ORDER BY created_at DESC
    ]], { tostring(sceneId), sceneId })

    return refs or {}
end)

-- ============================================================
-- CRIAR REFERÊNCIA CRUZADA MANUAL
-- ============================================================
lib.callback.register(resourceName .. ':server:createCrossRef', function(source, data)
    local src = source
    if not CheckForensicAuth(src) then return { success = false } end

    local playerData = GetPlayerData(src)

    local refId = MySQL.insert.await([[
        INSERT INTO forensic_cross_references
        (source_type, source_id, target_type, target_id, relationship, confidence, created_by, notes)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.source_type,
        tonumber(data.source_id),
        data.target_type,
        tostring(data.target_id),
        data.relationship or '',
        data.confidence or 'media',
        playerData and playerData.citizenid or '',
        data.notes or '',
    })

    ForensicAuditLog(src, 'crossref_created', 'crossref', refId, data)

    return { success = true, id = refId }
end)

-- ============================================================
-- DASHBOARD DE INVESTIGAÇÃO - Dados consolidados por cidadão
-- ============================================================
lib.callback.register(resourceName .. ':server:getInvestigationDashboard', function(source, citizenid)
    local src = source
    if not CheckForensicAuth(src) then return nil end
    if not citizenid then return nil end

    local dashboard = {
        citizenid = citizenid,
        fingerprints = MySQL.query.await([[
            SELECT fc.*, fe.evidence_number, fcs.scene_number
            FROM forensic_fingerprints_collected fc
            LEFT JOIN forensic_evidence fe ON fc.evidence_id = fe.id
            LEFT JOIN forensic_crime_scenes fcs ON fc.scene_id = fcs.id
            WHERE fc.matched_citizenid = ?
            ORDER BY fc.created_at DESC LIMIT 20
        ]], { citizenid }) or {},

        dna_matches = MySQL.query.await([[
            SELECT ds.*, fe.evidence_number, fcs.scene_number
            FROM forensic_dna_samples ds
            LEFT JOIN forensic_evidence fe ON ds.evidence_id = fe.id
            LEFT JOIN forensic_crime_scenes fcs ON ds.scene_id = fcs.id
            WHERE ds.matched_citizenid = ?
            ORDER BY ds.created_at DESC LIMIT 20
        ]], { citizenid }) or {},

        scenes_involved = MySQL.query.await([[
            SELECT DISTINCT fcs.*
            FROM forensic_crime_scenes fcs
            WHERE fcs.id IN (
                SELECT scene_id FROM forensic_evidence WHERE linked_citizenid = ?
                UNION SELECT scene_id FROM forensic_fingerprints_collected WHERE matched_citizenid = ?
                UNION SELECT scene_id FROM forensic_dna_samples WHERE matched_citizenid = ?
            )
            ORDER BY fcs.created_at DESC LIMIT 20
        ]], { citizenid, citizenid, citizenid }) or {},

        weapons_linked = MySQL.query.await([[
            SELECT DISTINCT fb.weapon_serial, fb.weapon_model, fb.caliber, fcs.scene_number
            FROM forensic_ballistics fb
            LEFT JOIN forensic_crime_scenes fcs ON fb.scene_id = fcs.id
            LEFT JOIN forensic_evidence fe ON fb.evidence_id = fe.id
            WHERE fe.linked_citizenid = ?
            ORDER BY fb.created_at DESC LIMIT 20
        ]], { citizenid }) or {},

        cross_references = MySQL.query.await([[
            SELECT * FROM forensic_cross_references
            WHERE target_type = 'citizenid' AND target_id = ?
            ORDER BY created_at DESC LIMIT 30
        ]], { citizenid }) or {},

        autopsies_victim = MySQL.query.await([[
            SELECT * FROM forensic_autopsy
            WHERE victim_citizenid = ?
            ORDER BY created_at DESC LIMIT 10
        ]], { citizenid }) or {},
    }

    return dashboard
end)

-- ============================================================
-- COMPARAR TODAS AS PROVAS DA CENA COM BASE DE CRIMINOSOS CONHECIDOS
-- ============================================================
lib.callback.register(resourceName .. ':server:compareSceneEvidenceWithKnownCriminals', function(source, sceneId)
    local src = source
    if not CheckForensicAuth(src) then return { success = false, error = 'Sem autorização.' } end

    sceneId = tonumber(sceneId)
    if not sceneId then
        return { success = false, error = 'Cena inválida.' }
    end

    local scene = MySQL.single.await('SELECT id, scene_number, classification, status, case_id, report_id FROM forensic_crime_scenes WHERE id = ?', { sceneId })
    if not scene then
        return { success = false, error = 'Cena não encontrada.' }
    end

    local evidences = MySQL.query.await([[
        SELECT id, evidence_number, category, type, subtype, linked_citizenid, linked_weapon_serial, linked_vehicle_plate, created_at
        FROM forensic_evidence
        WHERE scene_id = ?
        ORDER BY created_at DESC
        LIMIT 300
    ]], { sceneId }) or {}

    local candidateCitizenIds = {}
    local seen = {}
    local function addCandidate(cid)
        if not cid or cid == '' or seen[cid] then return end
        seen[cid] = true
        candidateCitizenIds[#candidateCitizenIds + 1] = cid
    end

    for _, ev in ipairs(evidences) do
        addCandidate(ev.linked_citizenid)
    end

    local fpMatches = MySQL.query.await([[
        SELECT DISTINCT matched_citizenid
        FROM forensic_fingerprints_collected
        WHERE scene_id = ? AND matched_citizenid IS NOT NULL AND matched_citizenid <> ''
    ]], { sceneId }) or {}
    for _, row in ipairs(fpMatches) do
        addCandidate(row.matched_citizenid)
    end

    local dnaMatches = MySQL.query.await([[
        SELECT DISTINCT matched_citizenid
        FROM forensic_dna_samples
        WHERE scene_id = ? AND matched_citizenid IS NOT NULL AND matched_citizenid <> ''
    ]], { sceneId }) or {}
    for _, row in ipairs(dnaMatches) do
        addCandidate(row.matched_citizenid)
    end

    local footwearCandidates = MySQL.query.await([[
        SELECT DISTINCT fp.citizenid
        FROM forensic_evidence fe
        INNER JOIN forensic_footwear_profiles fp ON CAST(fp.shoe_model AS CHAR) = fe.subtype
        WHERE fe.scene_id = ? AND fe.type = 'pegada'
    ]], { sceneId }) or {}
    for _, row in ipairs(footwearCandidates) do
        addCandidate(row.citizenid)
    end

    local matches = {}
    for _, cid in ipairs(candidateCitizenIds) do
        local profile = MySQL.single.await('SELECT citizenid, firstname, lastname FROM mdt_profiles WHERE citizenid = ? LIMIT 1', { cid }) or {}
        local subject = MySQL.single.await([[
            SELECT citizenid, status, reason, source_type, source_id, updated_at
            FROM forensic_investigative_subjects
            WHERE citizenid = ? AND status = 'active'
            LIMIT 1
        ]], { cid })

        local warrants = tonumber(MySQL.scalar.await('SELECT COUNT(*) FROM mdt_warrants WHERE citizenid = ?', { cid })) or 0
        local arrests = tonumber(MySQL.scalar.await('SELECT COUNT(*) FROM mdt_arrests WHERE citizenid = ?', { cid })) or 0

        if subject or warrants > 0 or arrests > 0 then
            matches[#matches + 1] = {
                citizenid = cid,
                name = ((profile.firstname or '') .. ' ' .. (profile.lastname or '')):gsub('^%s*(.-)%s*$', '%1'),
                known_criminal = subject ~= nil,
                reason = subject and subject.reason or nil,
                source_type = subject and subject.source_type or nil,
                active_warrants = warrants,
                arrests = arrests,
            }
        end
    end

    local ballisticInScene = MySQL.query.await([[
        SELECT id, weapon_serial, matched_weapon_serial, caliber, weapon_model, scene_id, evidence_id, created_at
        FROM forensic_ballistics
        WHERE scene_id = ?
        ORDER BY created_at DESC
        LIMIT 120
    ]], { sceneId }) or {}

    local reportLines = {
        'RELATÓRIO PADRONIZADO DE ACHADOS FORENSES',
        ('Cena: %s (ID %s)'):format(scene.scene_number or ('Cena #' .. tostring(scene.id or sceneId)), tostring(scene.id or sceneId)),
        ('Classificação: %s | Status: %s'):format(scene.classification or 'N/D', scene.status or 'N/D'),
        ('Total de provas analisadas: %d'):format(#evidences),
        ('Suspeitos com vínculo em base criminal: %d'):format(#matches),
        ('Registros balísticos na cena: %d'):format(#ballisticInScene),
        '--- ACHADOS ---',
    }

    if #matches == 0 then
        reportLines[#reportLines + 1] = '• Nenhum suspeito da cena foi localizado na base de criminosos conhecidos.'
    else
        for _, match in ipairs(matches) do
            reportLines[#reportLines + 1] = ('• %s (%s) | base=%s | mandados=%d | prisões=%d'):format(
                match.name and match.name ~= '' and match.name or 'Sem nome',
                match.citizenid or 'N/D',
                match.known_criminal and 'SIM' or 'NÃO',
                tonumber(match.active_warrants) or 0,
                tonumber(match.arrests) or 0
            )
        end
    end

    if #ballisticInScene > 0 then
        reportLines[#reportLines + 1] = '--- BALÍSTICA ---'
        for _, bal in ipairs(ballisticInScene) do
            reportLines[#reportLines + 1] = ('• Serial: %s | Calibre: %s | Modelo: %s'):format(
                bal.weapon_serial or bal.matched_weapon_serial or 'N/D',
                bal.caliber or 'N/D',
                bal.weapon_model or 'N/D'
            )
        end
    end

    local standardizedReport = table.concat(reportLines, '\n')

    return {
        success = true,
        data = {
            scene = scene,
            evidence = evidences,
            suspect_matches = matches,
            ballistic = ballisticInScene,
            standardized_report = standardizedReport,
        }
    }
end)
