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
