-- ============================================================
-- PS-FORENSICS - Integração com PS-MDT
-- Callbacks que estendem o MDT com dados forenses
-- ============================================================

local resourceName = GetCurrentResourceName()

-- ============================================================
-- BUSCAR DADOS FORENSES POR CASO (para exibir no MDT)
-- ============================================================
lib.callback.register(resourceName .. ':server:getForensicDataByCase', function(source, caseId)
    local src = source
    if not CheckForensicAuth(src) then return nil end

    caseId = tonumber(caseId)
    if not caseId then return nil end

    local data = {
        scenes = MySQL.query.await(
            'SELECT id, scene_number, classification, status, location_name, created_at FROM forensic_crime_scenes WHERE case_id = ? ORDER BY created_at DESC',
            { caseId }
        ) or {},

        evidence = MySQL.query.await(
            'SELECT id, evidence_number, type, category, status, seal_number, collected_by_name, collection_time FROM forensic_evidence WHERE case_id = ? ORDER BY created_at DESC',
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
    }

    return data
end)

-- ============================================================
-- BUSCAR DADOS FORENSES POR RELATÓRIO
-- ============================================================
lib.callback.register(resourceName .. ':server:getForensicDataByReport', function(source, reportId)
    local src = source
    if not CheckForensicAuth(src) then return nil end

    reportId = tonumber(reportId)
    if not reportId then return nil end

    local data = {
        scenes = MySQL.query.await(
            'SELECT id, scene_number, classification, status FROM forensic_crime_scenes WHERE report_id = ? ORDER BY created_at DESC',
            { reportId }
        ) or {},

        evidence = MySQL.query.await(
            'SELECT id, evidence_number, type, category, status, seal_number FROM forensic_evidence WHERE report_id = ? ORDER BY created_at DESC',
            { reportId }
        ) or {},

        reports = MySQL.query.await(
            'SELECT id, report_number, type, title, status FROM forensic_reports WHERE mdt_report_id = ? ORDER BY created_at DESC',
            { reportId }
        ) or {},
    }

    return data
end)

-- ============================================================
-- BUSCAR DADOS FORENSES POR CIDADÃO (para perfil no MDT)
-- ============================================================
lib.callback.register(resourceName .. ':server:getForensicDataByCitizen', function(source, citizenid)
    local src = source
    if not CheckForensicAuth(src) then return nil end
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
    }

    return data
end)

-- ============================================================
-- BUSCAR DADOS FORENSES POR ARMA
-- ============================================================
lib.callback.register(resourceName .. ':server:getForensicDataByWeapon', function(source, weaponSerial)
    local src = source
    if not CheckForensicAuth(src) then return nil end
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
    if not CheckForensicAuth(src) then return nil end
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
    if not CheckForensicAuth(src) then return nil end

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
