-- ============================================================
-- PS-FORENSICS - Integração com PS-MDT
-- Callbacks que estendem o MDT com dados forenses
-- ============================================================

local resourceName = GetCurrentResourceName()

local function hasMDTAccess(src)
    if not CheckForensicAuth(src) then return false end
    return CheckForensicPermission(src, 'canRunLabTests')
        or CheckForensicPermission(src, 'canEmitReport')
        or CheckForensicPermission(src, 'canPerformAutopsy')
end

local function normalizeLikeQuery(value)
    if not value then return nil end
    local v = tostring(value):gsub('^%s*(.-)%s*$', '%1')
    if v == '' then return nil end
    return v
end

local function safeQuery(sql, params)
    local ok, result = pcall(function()
        return MySQL.query.await(sql, params or {})
    end)
    return ok and (result or {}) or {}
end

local function safeSingle(sql, params)
    local ok, result = pcall(function()
        return MySQL.single.await(sql, params or {})
    end)
    return ok and result or nil
end

-- ============================================================
-- BUSCAR DADOS FORENSES POR CASO (para exibir no MDT)
-- ============================================================
lib.callback.register(resourceName .. ':server:getForensicDataByCase', function(source, caseId)
    local src = source
    if not hasMDTAccess(src) then return nil end

    caseId = tonumber(caseId)
    if not caseId then return nil end

    local data = {
        scenes = MySQL.query.await(
            'SELECT id, scene_number, classification, status, location_name, created_at FROM forensic_crime_scenes WHERE case_id = ? ORDER BY created_at DESC',
            { caseId }
        ) or {},

        evidence = MySQL.query.await(
            'SELECT id, evidence_number, type, category, status, seal_number, forensic_report_id, collected_by_name, collection_time FROM forensic_evidence WHERE case_id = ? ORDER BY created_at DESC',
            { caseId }
        ) or {},

        reports = MySQL.query.await(
            'SELECT id, report_number, type, title, status, author_name, created_at FROM forensic_reports WHERE case_id = ? ORDER BY created_at DESC',
            { caseId }
        ) or {},

        lab_tests = MySQL.query.await([[
            SELECT lt.id, lt.test_type, lt.test_name, lt.result_level, lt.result_details, lt.status, lt.created_at
            FROM forensic_lab_tests lt
            INNER JOIN forensic_evidence fe ON lt.evidence_id = fe.id
            WHERE fe.case_id = ?
            ORDER BY lt.created_at DESC
        ]], { caseId }) or {},

        citizens = MySQL.query.await([[
            SELECT DISTINCT linked_citizenid AS citizenid
            FROM forensic_evidence
            WHERE case_id = ? AND linked_citizenid IS NOT NULL AND linked_citizenid != ''
        ]], { caseId }) or {},
        suspects = MySQL.query.await([[
            SELECT DISTINCT target_id AS citizenid, relationship, confidence
            FROM forensic_cross_references
            WHERE target_type = 'citizenid' AND source_type IN ('evidence','fingerprint','dna','ballistic','autopsy')
              AND source_id IN (
                SELECT id FROM forensic_evidence WHERE case_id = ?
              )
        ]], { caseId }) or {},
        vehicles = MySQL.query.await([[
            SELECT DISTINCT linked_vehicle_plate AS plate
            FROM forensic_evidence
            WHERE case_id = ? AND linked_vehicle_plate IS NOT NULL AND linked_vehicle_plate != ''
        ]], { caseId }) or {},
        weapons = MySQL.query.await([[
            SELECT DISTINCT linked_weapon_serial AS serial
            FROM forensic_evidence
            WHERE case_id = ? AND linked_weapon_serial IS NOT NULL AND linked_weapon_serial != ''
        ]], { caseId }) or {},
    }

    return data
end)

-- ============================================================
-- BUSCAR DADOS FORENSES POR RELATÓRIO
-- ============================================================
lib.callback.register(resourceName .. ':server:getForensicDataByReport', function(source, reportId)
    local src = source
    if not hasMDTAccess(src) then return nil end

    reportId = tonumber(reportId)
    if not reportId then return nil end

    local data = {
        scenes = MySQL.query.await(
            'SELECT id, scene_number, classification, status FROM forensic_crime_scenes WHERE report_id = ? ORDER BY created_at DESC',
            { reportId }
        ) or {},

        evidence = MySQL.query.await(
            'SELECT id, evidence_number, type, category, status, seal_number, forensic_report_id FROM forensic_evidence WHERE report_id = ? ORDER BY created_at DESC',
            { reportId }
        ) or {},

        reports = MySQL.query.await(
            'SELECT id, report_number, type, title, status FROM forensic_reports WHERE mdt_report_id = ? ORDER BY created_at DESC',
            { reportId }
        ) or {},
        evidence_links = MySQL.query.await([[
            SELECT DISTINCT linked_citizenid, linked_vehicle_plate, linked_weapon_serial
            FROM forensic_evidence
            WHERE report_id = ?
        ]], { reportId }) or {},
    }

    return data
end)

-- ============================================================
-- BUSCAR DADOS FORENSES POR CIDADÃO (para perfil no MDT)
-- ============================================================
lib.callback.register(resourceName .. ':server:getForensicDataByCitizen', function(source, citizenid)
    local src = source
    if not hasMDTAccess(src) then return nil end
    if not citizenid then return nil end

    local data = {
        -- Digital cadastrada?
        has_fingerprint = MySQL.scalar.await(
            'SELECT COUNT(*) FROM forensic_fingerprint_profiles WHERE citizenid = ?', { citizenid }
        ) > 0,

        -- DNA cadastrado?
        has_dna = MySQL.scalar.await(
            'SELECT COUNT(*) FROM forensic_dna_profiles WHERE citizenid = ?', { citizenid }
        ) > 0,

        -- Matches de digital
        fingerprint_matches = MySQL.query.await([[
            SELECT fc.match_status, fc.match_confidence, fc.source_description, fc.created_at,
                   fe.evidence_number, fcs.scene_number
            FROM forensic_fingerprints_collected fc
            LEFT JOIN forensic_evidence fe ON fc.evidence_id = fe.id
            LEFT JOIN forensic_crime_scenes fcs ON fc.scene_id = fcs.id
            WHERE fc.matched_citizenid = ?
            ORDER BY fc.created_at DESC LIMIT 10
        ]], { citizenid }) or {},

        -- Matches de DNA
        dna_matches = MySQL.query.await([[
            SELECT ds.match_status, ds.match_confidence, ds.source_type, ds.created_at,
                   fe.evidence_number, fcs.scene_number
            FROM forensic_dna_samples ds
            LEFT JOIN forensic_evidence fe ON ds.evidence_id = fe.id
            LEFT JOIN forensic_crime_scenes fcs ON ds.scene_id = fcs.id
            WHERE ds.matched_citizenid = ?
            ORDER BY ds.created_at DESC LIMIT 10
        ]], { citizenid }) or {},

        -- Cenas onde aparece
        scenes_involved = MySQL.scalar.await([[
            SELECT COUNT(DISTINCT scene_id) FROM (
                SELECT scene_id FROM forensic_evidence WHERE linked_citizenid = ? AND scene_id IS NOT NULL
                UNION SELECT scene_id FROM forensic_fingerprints_collected WHERE matched_citizenid = ? AND scene_id IS NOT NULL
                UNION SELECT scene_id FROM forensic_dna_samples WHERE matched_citizenid = ? AND scene_id IS NOT NULL
            ) t
        ]], { citizenid, citizenid, citizenid }) or 0,

        -- Evidências vinculadas
        evidence_count = MySQL.scalar.await(
            'SELECT COUNT(*) FROM forensic_evidence WHERE linked_citizenid = ?', { citizenid }
        ) or 0,

        -- Armas vinculadas via balística
        ballistic_weapons = MySQL.query.await([[
            SELECT DISTINCT fb.weapon_serial, fb.weapon_model, fb.caliber
            FROM forensic_ballistics fb
            INNER JOIN forensic_evidence fe ON fb.evidence_id = fe.id
            WHERE fe.linked_citizenid = ? AND fb.weapon_serial IS NOT NULL
        ]], { citizenid }) or {},

        forensic_intelligence = MySQL.query.await([[
            SELECT id, case_id, report_id, scene_id, evidence_id, source_type, source_id,
                   match_kind, association_level, confidence_score, rationale, exam_origin,
                   exam_performed_by, created_at
            FROM forensic_intelligence_links
            WHERE citizenid = ?
            ORDER BY created_at DESC
            LIMIT 50
        ]], { citizenid }) or {},

        auto_watchlist_history = MySQL.query.await([[
            SELECT id, event_type, report_id, case_id, reason, source_type, source_id,
                   algorithm_name, algorithm_version, confidence_score, association_level,
                   occurred_at
            FROM forensic_watchlist_events
            WHERE citizenid = ?
              AND event_type IN ('suspect_linked', 'auto_wanted_added', 'auto_wanted_removed')
            ORDER BY occurred_at DESC
            LIMIT 50
        ]], { citizenid }) or {},

        active_warrants = MySQL.query.await([[
            SELECT reportid, expirydate, felonies, misdemeanors, infractions
            FROM mdt_reports_warrants
            WHERE citizenid = ? AND expirydate >= NOW()
            ORDER BY expirydate ASC
        ]], { citizenid }) or {},
    }

    return data
end)

-- ============================================================
-- BUSCAR DADOS FORENSES POR ARMA
-- ============================================================
lib.callback.register(resourceName .. ':server:getForensicDataByWeapon', function(source, weaponSerial)
    local src = source
    if not hasMDTAccess(src) then return nil end
    if not weaponSerial then return nil end

    local data = {
        ballistics = MySQL.query.await([[
            SELECT fb.*, fcs.scene_number, fcs.classification
            FROM forensic_ballistics fb
            LEFT JOIN forensic_crime_scenes fcs ON fb.scene_id = fcs.id
            WHERE fb.weapon_serial = ? OR fb.matched_weapon_serial = ?
            ORDER BY fb.created_at DESC
        ]], { weaponSerial, weaponSerial }) or {},

        scenes_count = MySQL.scalar.await([[
            SELECT COUNT(DISTINCT scene_id) FROM forensic_ballistics
            WHERE (weapon_serial = ? OR matched_weapon_serial = ?) AND scene_id IS NOT NULL
        ]], { weaponSerial, weaponSerial }) or 0,

        evidence = MySQL.query.await([[
            SELECT id, evidence_number, type, status, seal_number, collection_time
            FROM forensic_evidence WHERE linked_weapon_serial = ?
            ORDER BY created_at DESC
        ]], { weaponSerial }) or {},
    }

    return data
end)

-- ============================================================
-- BUSCAR DADOS FORENSES POR VEÍCULO
-- ============================================================
lib.callback.register(resourceName .. ':server:getForensicDataByVehicle', function(source, plate)
    local src = source
    if not hasMDTAccess(src) then return nil end
    if not plate then return nil end

    local data = {
        evidence = MySQL.query.await([[
            SELECT id, evidence_number, type, category, status, seal_number, collection_time
            FROM forensic_evidence WHERE linked_vehicle_plate = ?
            ORDER BY created_at DESC
        ]], { plate }) or {},

        lab_tests = MySQL.query.await([[
            SELECT lt.test_type, lt.test_name, lt.result_level, lt.result_details, lt.created_at
            FROM forensic_lab_tests lt
            WHERE lt.target_vehicle = ?
            ORDER BY lt.created_at DESC
        ]], { plate }) or {},

        fingerprints = MySQL.query.await([[
            SELECT fc.source_description, fc.match_status, fc.matched_name, fc.match_confidence
            FROM forensic_fingerprints_collected fc
            WHERE fc.source_type = 'veiculo' AND fc.source_description LIKE ?
        ]], { '%' .. plate .. '%' }) or {},
    }

    return data
end)

-- ============================================================
-- ESTATÍSTICAS FORENSES (para dashboard do MDT)
-- ============================================================
lib.callback.register(resourceName .. ':server:getForensicStats', function(source)
    local src = source
    if not hasMDTAccess(src) then return nil end

    local stats = {
        total_scenes = MySQL.scalar.await('SELECT COUNT(*) FROM forensic_crime_scenes') or 0,
        active_scenes = MySQL.scalar.await("SELECT COUNT(*) FROM forensic_crime_scenes WHERE status != 'finalizada'") or 0,
        total_evidence = MySQL.scalar.await('SELECT COUNT(*) FROM forensic_evidence') or 0,
        pending_tests = MySQL.scalar.await("SELECT COUNT(*) FROM forensic_lab_tests WHERE status IN ('solicitado', 'em_andamento')") or 0,
        completed_tests = MySQL.scalar.await("SELECT COUNT(*) FROM forensic_lab_tests WHERE status = 'concluido'") or 0,
        total_autopsies = MySQL.scalar.await('SELECT COUNT(*) FROM forensic_autopsy') or 0,
        total_reports = MySQL.scalar.await('SELECT COUNT(*) FROM forensic_reports') or 0,
        fingerprint_matches = MySQL.scalar.await("SELECT COUNT(*) FROM forensic_fingerprints_collected WHERE match_status = 'positiva'") or 0,
        dna_matches = MySQL.scalar.await("SELECT COUNT(*) FROM forensic_dna_samples WHERE match_status = 'compativel'") or 0,
    }

    return stats
end)

-- ============================================================
-- BUSCAR DADOS FORENSES POR EVIDÊNCIA
-- ============================================================
lib.callback.register(resourceName .. ':server:getForensicDataByEvidence', function(source, evidenceId)
    local src = source
    if not hasMDTAccess(src) then return nil end

    evidenceId = tonumber(evidenceId)
    if not evidenceId then return nil end

    local evidence = MySQL.single.await('SELECT * FROM forensic_evidence WHERE id = ?', { evidenceId })
    if not evidence then return nil end

    evidence.custody = MySQL.query.await('SELECT * FROM forensic_chain_of_custody WHERE evidence_id = ? ORDER BY created_at ASC', { evidenceId }) or {}
    evidence.tests = MySQL.query.await('SELECT * FROM forensic_lab_tests WHERE evidence_id = ? ORDER BY created_at DESC', { evidenceId }) or {}
    evidence.dna = MySQL.query.await('SELECT * FROM forensic_dna_samples WHERE evidence_id = ? ORDER BY created_at DESC', { evidenceId }) or {}
    evidence.fingerprints = MySQL.query.await('SELECT * FROM forensic_fingerprints_collected WHERE evidence_id = ? ORDER BY created_at DESC', { evidenceId }) or {}
    evidence.ballistics = MySQL.query.await('SELECT * FROM forensic_ballistics WHERE evidence_id = ? ORDER BY created_at DESC', { evidenceId }) or {}
    evidence.crossrefs = MySQL.query.await(
        "SELECT * FROM forensic_cross_references WHERE (source_type = 'evidence' AND source_id = ?) OR (target_type = 'evidence' AND target_id = ?) ORDER BY created_at DESC",
        { evidenceId, tostring(evidenceId) }
    ) or {}

    return evidence
end)

-- ============================================================
-- BUSCA GLOBAL FORENSE (MDT / painel)
-- ============================================================
lib.callback.register(resourceName .. ':server:searchForensicGlobal', function(source, filters)
    local src = source
    if not hasMDTAccess(src) then return { success = false, data = {} } end
    filters = filters or {}

    local query = normalizeLikeQuery(filters.query)
    local citizenid = normalizeLikeQuery(filters.citizenid)
    local plate = normalizeLikeQuery(filters.plate)
    local serial = normalizeLikeQuery(filters.serial)

    local like = query and ('%' .. query .. '%') or nil

    local data = {
        evidence = {},
        dna = {},
        fingerprints = {},
        weapons = {},
        vehicles = {},
        citizens = {},
    }

    if like then
        data.evidence = MySQL.query.await([[
            SELECT id, evidence_number, type, category, status, seal_number, linked_citizenid, linked_vehicle_plate, linked_weapon_serial, created_at
            FROM forensic_evidence
            WHERE evidence_number LIKE ? OR description LIKE ? OR seal_number LIKE ? OR linked_citizenid LIKE ? OR linked_vehicle_plate LIKE ? OR linked_weapon_serial LIKE ?
            ORDER BY created_at DESC LIMIT 50
        ]], { like, like, like, like, like, like }) or {}
    end

    if citizenid or like then
        local c = citizenid or query
        data.dna = MySQL.query.await('SELECT * FROM forensic_dna_samples WHERE matched_citizenid = ? ORDER BY created_at DESC LIMIT 30', { c }) or {}
        data.fingerprints = MySQL.query.await('SELECT * FROM forensic_fingerprints_collected WHERE matched_citizenid = ? ORDER BY created_at DESC LIMIT 30', { c }) or {}
        data.citizens = safeQuery('SELECT * FROM mdt_profiles WHERE citizenid = ? LIMIT 1', { c })
    end

    if plate or like then
        local p = plate or query
        data.vehicles = MySQL.query.await('SELECT * FROM forensic_evidence WHERE linked_vehicle_plate = ? ORDER BY created_at DESC LIMIT 30', { p }) or {}
    end

    if serial or like then
        local s = serial or query
        data.weapons = MySQL.query.await([[
            SELECT * FROM forensic_ballistics
            WHERE weapon_serial = ? OR matched_weapon_serial = ?
            ORDER BY created_at DESC LIMIT 30
        ]], { s, s }) or {}
    end

    return { success = true, data = data }
end)

-- ============================================================
-- BUNDLE DE INTEGRAÇÃO MDT/POLICIAL
-- ============================================================
lib.callback.register(resourceName .. ':server:getMDTIntegrationBundle', function(source, filters)
    local src = source
    if not hasMDTAccess(src) then return { success = false } end
    filters = filters or {}

    local caseId = filters.case_id and tonumber(filters.case_id) or nil
    local reportId = filters.report_id and tonumber(filters.report_id) or nil
    local evidenceId = filters.evidence_id and tonumber(filters.evidence_id) or nil
    local citizenid = normalizeLikeQuery(filters.citizenid)
    local suspectid = normalizeLikeQuery(filters.suspectid) or citizenid
    local vehiclePlate = normalizeLikeQuery(filters.vehicle_plate)
    local weaponSerial = normalizeLikeQuery(filters.weapon_serial)
    local warrantId = filters.warrant_id and tostring(filters.warrant_id) or nil
    local arrestId = filters.arrest_id and tostring(filters.arrest_id) or nil

    local bundle = {
        case = caseId and safeSingle('SELECT * FROM mdt_cases WHERE id = ?', { caseId }) or nil,
        report = reportId and safeSingle('SELECT * FROM mdt_reports WHERE id = ?', { reportId }) or nil,
        evidence = evidenceId and MySQL.single.await('SELECT * FROM forensic_evidence WHERE id = ?', { evidenceId }) or nil,
        forensic_case = caseId and MySQL.query.await('SELECT id, scene_number, classification, status FROM forensic_crime_scenes WHERE case_id = ? ORDER BY created_at DESC', { caseId }) or {},
        forensic_report = reportId and MySQL.query.await('SELECT id, report_number, type, title, status FROM forensic_reports WHERE mdt_report_id = ? ORDER BY created_at DESC', { reportId }) or {},
        citizen_profile = citizenid and safeQuery('SELECT * FROM mdt_profiles WHERE citizenid = ? LIMIT 1', { citizenid }) or {},
        suspect_profile = suspectid and safeQuery('SELECT * FROM mdt_profiles WHERE citizenid = ? LIMIT 1', { suspectid }) or {},
        vehicle_records = vehiclePlate and safeQuery('SELECT * FROM player_vehicles WHERE plate = ? LIMIT 1', { vehiclePlate }) or {},
        weapon_records = weaponSerial and safeQuery('SELECT * FROM mdt_weapons WHERE serial = ? LIMIT 1', { weaponSerial }) or {},
        warrants = warrantId and safeQuery('SELECT * FROM mdt_warrants WHERE id = ? LIMIT 1', { warrantId })
            or (suspectid and safeQuery('SELECT * FROM mdt_warrants WHERE citizenid = ? ORDER BY created_at DESC LIMIT 20', { suspectid }) or {}),
        arrests = arrestId and safeQuery('SELECT * FROM mdt_arrests WHERE id = ? LIMIT 1', { arrestId })
            or (suspectid and safeQuery('SELECT * FROM mdt_arrests WHERE citizenid = ? ORDER BY created_at DESC LIMIT 20', { suspectid }) or {}),
    }

    return { success = true, data = bundle }
end)
