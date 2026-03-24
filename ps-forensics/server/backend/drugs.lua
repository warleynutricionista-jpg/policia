-- ============================================================
-- PS-FORENSICS - Módulo: Drogas e Substâncias (Server)
-- ============================================================

local resourceName = GetCurrentResourceName()

-- ============================================================
-- REGISTRAR ANÁLISE DE DROGA
-- ============================================================
lib.callback.register(resourceName .. ':server:registerDrugAnalysis', function(source, data)
    local src = source
    if not CheckForensicAuth(src) then return { success = false } end

    local playerData = GetPlayerData(src)

    local drugId = MySQL.insert.await([[
        INSERT INTO forensic_drug_analysis
        (evidence_id, scene_id, lab_test_id, substance_category,
         preliminary_classification, weight_grams, quantity_units,
         test_result, analyzed_by, notes)
        VALUES (?, ?, ?, ?, ?, ?, ?, 'suspeita', ?, ?)
    ]], {
        data.evidence_id and tonumber(data.evidence_id) or nil,
        data.scene_id and tonumber(data.scene_id) or nil,
        data.lab_test_id and tonumber(data.lab_test_id) or nil,
        data.substance_category or 'substancia_desconhecida',
        data.preliminary_classification or '',
        data.weight_grams or nil,
        data.quantity_units or nil,
        playerData.citizenid,
        data.notes or '',
    })

    ForensicAuditLog(src, 'drug_analysis_created', 'drug', drugId, {
        category = data.substance_category,
        weight = data.weight_grams,
    })

    return { success = true, id = drugId }
end)

-- ============================================================
-- CONFIRMAR SUBSTÂNCIA
-- ============================================================
lib.callback.register(resourceName .. ':server:confirmDrugSubstance', function(source, drugId, confirmedSubstance, purity, testResult)
    local src = source
    if not CheckForensicAuth(src) then return { success = false } end
    if not CheckForensicPermission(src, 'canRunLabTests') then
        return { success = false, error = 'Sem permissão' }
    end

    drugId = tonumber(drugId)
    local playerData = GetPlayerData(src)

    MySQL.update.await([[
        UPDATE forensic_drug_analysis
        SET confirmed_substance = ?, purity_percent = ?,
            test_result = ?, analyzed_by = ?
        WHERE id = ?
    ]], { confirmedSubstance, purity, testResult or 'confirmado', playerData.citizenid, drugId })

    ForensicAuditLog(src, 'drug_confirmed', 'drug', drugId, {
        substance = confirmedSubstance, purity = purity,
    })

    return { success = true }
end)

-- ============================================================
-- LISTAR ANÁLISES DE DROGA
-- ============================================================
lib.callback.register(resourceName .. ':server:getDrugAnalyses', function(source, filters)
    local src = source
    if not CheckForensicAuth(src) then return { success = false } end

    filters = filters or {}
    local queryParts = { '1=1' }
    local values = {}

    if filters.scene_id then
        queryParts[#queryParts + 1] = 'scene_id = ?'
        values[#values + 1] = tonumber(filters.scene_id)
    end

    if filters.substance_category and filters.substance_category ~= '' then
        queryParts[#queryParts + 1] = 'substance_category = ?'
        values[#values + 1] = filters.substance_category
    end

    local where = table.concat(queryParts, ' AND ')
    local items = MySQL.query.await(('SELECT * FROM forensic_drug_analysis WHERE %s ORDER BY created_at DESC LIMIT 50'):format(where), values)

    return { success = true, data = items or {} }
end)
