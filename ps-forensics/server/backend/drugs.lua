-- ============================================================
-- PS-FORENSICS - Módulo: Drogas e Substâncias (Server)
-- ============================================================

local resourceName = GetCurrentResourceName()

local allowedCategories = {
    cocaina = true,
    maconha = true,
    crack = true,
    metanfetamina = true,
    comprimidos = true,
    substancia_desconhecida = true,
    solvente = true,
    droga_liquida = true,
    drogas_sinteticas = true,
    opioides = true,
    outros = true,
}

local allowedResultLevels = {
    suspeita = true,
    presumido = true,
    inconclusivo = true,
    compativel = true,
    confirmado = true,
    negativo = true,
}

local function hasRequiredItem(src, itemName)
    if not itemName then return true end
    if GetResourceState('ox_inventory') ~= 'started' then return true end
    return (exports.ox_inventory:GetItemCount(src, itemName) or 0) > 0
end

local function normalizeCategory(category)
    local c = (category or 'substancia_desconhecida'):lower():gsub('%s+', '_')
    return allowedCategories[c] and c or 'substancia_desconhecida'
end

local function normalizeResultLevel(level)
    local l = (level or 'suspeita'):lower():gsub('%s+', '_')
    return allowedResultLevels[l] and l or 'suspeita'
end

local function resolveCaseAndReport(sceneId, evidenceId)
    local caseId, reportId = nil, nil
    if evidenceId then
        local evidence = MySQL.single.await('SELECT id, scene_id, case_id, report_id FROM forensic_evidence WHERE id = ?', { evidenceId })
        if not evidence then return nil, nil, false end
        sceneId = sceneId or evidence.scene_id
        caseId = evidence.case_id
        reportId = evidence.report_id
    end

    if sceneId then
        local scene = MySQL.single.await('SELECT id, case_id, report_id FROM forensic_crime_scenes WHERE id = ?', { sceneId })
        if not scene then return nil, nil, false end
        caseId = caseId or scene.case_id
        reportId = reportId or scene.report_id
    end

    return caseId, reportId, true
end

-- ============================================================
-- REGISTRAR ANÁLISE DE DROGA
-- ============================================================
lib.callback.register(resourceName .. ':server:registerDrugAnalysis', function(source, data)
    local src = source
    if not CheckForensicAuth(src) then return { success = false, error = L('drugs.errors.not_authorized') } end
    if not CheckForensicPermission(src, 'canRunBasicTests') then
        return { success = false, error = L('drugs.errors.no_permission_register') }
    end

    local playerData = GetPlayerData(src)
    if not playerData then return { success = false, error = L('scene.errors.player_data_unavailable') } end
    data = data or {}

    local evidenceId = data.evidence_id and tonumber(data.evidence_id) or nil
    local sceneId = data.scene_id and tonumber(data.scene_id) or nil
    local labTestId = data.lab_test_id and tonumber(data.lab_test_id) or nil
    local category = normalizeCategory(data.substance_category)
    local preliminary = data.preliminary_classification and tostring(data.preliminary_classification):sub(1, 100) or ''
    local notes = data.notes and tostring(data.notes):sub(1, 1000) or ''
    local weightGrams = data.weight_grams and tonumber(data.weight_grams) or nil
    local quantityUnits = data.quantity_units and tonumber(data.quantity_units) or nil
    local testResult = normalizeResultLevel(data.test_result)

    if weightGrams and weightGrams < 0 then
        return { success = false, error = L('drugs.errors.invalid_weight') }
    end
    if quantityUnits and quantityUnits < 0 then
        return { success = false, error = L('drugs.errors.invalid_quantity') }
    end

    local itemValidation = ValidateAndConsumeForensicAction(src, 'run_drug_test')
    if not itemValidation.success then
        return { success = false, error = itemValidation.error or L('drugs.errors.missing_required_item', Config.Items.drug_test_kit) }
    end

    local caseId, reportId, okLink = resolveCaseAndReport(sceneId, evidenceId)
    if not okLink then
        return { success = false, error = L('drugs.errors.evidence_or_scene_not_found') }
    end

    local drugId = MySQL.insert.await([[
        INSERT INTO forensic_drug_analysis
        (evidence_id, scene_id, lab_test_id, substance_category,
         preliminary_classification, weight_grams, quantity_units,
         test_result, analyzed_by, notes, case_id, report_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        evidenceId,
        sceneId,
        labTestId,
        category,
        preliminary,
        weightGrams,
        quantityUnits,
        testResult,
        playerData.citizenid,
        notes,
        caseId,
        reportId,
    })

    if not drugId then
        return { success = false, error = L('drugs.errors.register_failed') }
    end

    if caseId then
        MySQL.insert.await([[
            INSERT INTO forensic_cross_references
            (source_type, source_id, target_type, target_id, relationship, confidence, created_by, notes)
            VALUES ('drug', ?, 'case', ?, 'teste_substancia', 'media', ?, ?)
            ON DUPLICATE KEY UPDATE
                confidence = VALUES(confidence),
                notes = VALUES(notes),
                updated_at = NOW()
        ]], { drugId, tostring(caseId), playerData.citizenid, ('Análise de substância vinculada ao caso %s'):format(caseId) })
    end

    if reportId then
        MySQL.insert.await([[
            INSERT INTO forensic_cross_references
            (source_type, source_id, target_type, target_id, relationship, confidence, created_by, notes)
            VALUES ('drug', ?, 'report', ?, 'teste_substancia', 'media', ?, ?)
            ON DUPLICATE KEY UPDATE
                confidence = VALUES(confidence),
                notes = VALUES(notes),
                updated_at = NOW()
        ]], { drugId, tostring(reportId), playerData.citizenid, ('Análise de substância vinculada ao relatório %s'):format(reportId) })
    end

    ForensicAuditLog(src, 'drug_analysis_created', 'drug', drugId, {
        category = category,
        weight = weightGrams,
        evidenceId = evidenceId,
        sceneId = sceneId,
        caseId = caseId,
        reportId = reportId,
        usedItems = itemValidation.usedItems,
    })

    return { success = true, id = drugId, testResult = testResult }
end)

-- ============================================================
-- CONFIRMAR SUBSTÂNCIA
-- ============================================================
lib.callback.register(resourceName .. ':server:confirmDrugSubstance', function(source, drugId, confirmedSubstance, purity, testResult)
    local src = source
    if not CheckForensicAuth(src) then return { success = false, error = L('drugs.errors.not_authorized') } end
    if not CheckForensicPermission(src, 'canRunLabTests') then
        return { success = false, error = L('drugs.errors.no_permission_confirm') }
    end

    drugId = tonumber(drugId)
    if not drugId then return { success = false, error = L('drugs.errors.invalid_id') } end
    local playerData = GetPlayerData(src)
    if not playerData then return { success = false, error = L('scene.errors.player_data_unavailable') } end
    local drug = MySQL.single.await('SELECT * FROM forensic_drug_analysis WHERE id = ?', { drugId })
    if not drug then return { success = false, error = L('drugs.errors.not_found') } end

    local normalizedResult = normalizeResultLevel(testResult or 'confirmado')
    local purityNum = purity and tonumber(purity) or nil
    if purityNum and (purityNum < 0 or purityNum > 100) then
        return { success = false, error = L('drugs.errors.invalid_purity') }
    end

    MySQL.update.await([[
        UPDATE forensic_drug_analysis
        SET confirmed_substance = ?, purity_percent = ?,
            test_result = ?, analyzed_by = ?, notes = ?
        WHERE id = ?
    ]], {
        confirmedSubstance and tostring(confirmedSubstance):sub(1, 100) or nil,
        purityNum,
        normalizedResult,
        playerData.citizenid,
        ('Resultado: %s | Substância: %s | Pureza: %s%%'):format(
            L(('drugs.result.%s'):format(normalizedResult)),
            confirmedSubstance or L('labels.unknown'),
            purityNum and ('%.2f'):format(purityNum) or L('labels.na')
        ),
        drugId
    })

    if drug.lab_test_id then
        MySQL.update.await([[
            UPDATE forensic_lab_tests
            SET result_level = ?, status = 'concluido', completed_at = NOW(),
                performed_by = ?, performed_by_name = ?, result_details = ?
            WHERE id = ?
        ]], {
            normalizedResult,
            playerData.citizenid,
            playerData.name,
            ('Substância: %s | Pureza: %s%%'):format(
                confirmedSubstance or L('labels.unknown'),
                purityNum and ('%.2f'):format(purityNum) or L('labels.na')
            ),
            drug.lab_test_id
        })
    end

    ForensicAuditLog(src, 'drug_confirmed', 'drug', drugId, {
        substance = confirmedSubstance, purity = purityNum, result = normalizedResult,
    })

    return { success = true, result = normalizedResult }
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
