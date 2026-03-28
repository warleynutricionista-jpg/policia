-- ============================================================
-- PS-FORENSICS - Módulo: Balística (Server)
-- ============================================================

local resourceName = GetCurrentResourceName()

local allowedItemTypes = {
    capsula = true,
    projetil = true,
    arma = true,
    municao = true,
}

local itemTypeAliases = {
    ['cápsula'] = 'capsula',
    projectile = 'projetil',
    cartridge = 'capsula',
    bullet = 'projetil',
    weapon = 'arma',
    ammo = 'municao',
}

local function normalizeItemType(itemType)
    local t = (itemType or 'capsula'):lower():gsub('%s+', '_')
    t = itemTypeAliases[t] or t
    return allowedItemTypes[t] and t or 'capsula'
end

local function normalizeSerial(serial)
    if not serial then return nil end
    local s = tostring(serial):upper():gsub('%s+', '')
    if s == '' then return nil end
    return s
end

local function getBallisticSignature(serial, model, caliber)
    local seed = ('%s|%s|%s'):format(serial or 'SEM_SERIAL', model or 'MODELO_ND', caliber or 'CAL_ND')
    local sum = 0
    for i = 1, #seed do
        sum = (sum + (string.byte(seed, i) * (i + 13))) % 2147483647
    end
    return ('BAL-%010d'):format(sum)
end

local function generateIllegalSerial()
    local base = os.date('%y%m%d')
    local rand = math.random(100000, 999999)
    return normalizeSerial(('ILG-%s-%s'):format(base, rand))
end

local function ensureWeaponRegistry(serial, model, caliber, origin, ownerCitizenId, actorCitizenId)
    if not serial or serial == '' then return nil end
    local signature = getBallisticSignature(serial, model, caliber)
    MySQL.insert.await([[
        INSERT INTO forensic_weapon_registry
        (serial, weapon_model, caliber, origin_type, current_holder_citizenid, ballistic_signature, status, created_by)
        VALUES (?, ?, ?, ?, ?, ?, 'active', ?)
        ON DUPLICATE KEY UPDATE
            weapon_model = COALESCE(VALUES(weapon_model), weapon_model),
            caliber = COALESCE(VALUES(caliber), caliber),
            current_holder_citizenid = COALESCE(VALUES(current_holder_citizenid), current_holder_citizenid),
            ballistic_signature = COALESCE(VALUES(ballistic_signature), ballistic_signature),
            updated_at = CURRENT_TIMESTAMP
    ]], { serial, model, caliber, origin or 'ilegal', ownerCitizenId, signature, actorCitizenId or 'system' })
    return signature
end

local function hasRequiredItem(src, itemName)
    if not itemName then return true end
    if GetResourceState('ox_inventory') ~= 'started' then return true end
    return (exports.ox_inventory:GetItemCount(src, itemName) or 0) > 0
end

local function calcBallisticConfidence(ballistic, hasWeaponProfile, hasHistoricalMatch, exactSerialMatch)
    local confidence = 25 + math.random(20)
    if ballistic.caliber and ballistic.caliber ~= '' then
        confidence = confidence + 20
    end
    if hasWeaponProfile then
        confidence = confidence + 20
    end
    if hasHistoricalMatch then
        confidence = confidence + 20
    end
    if exactSerialMatch then
        confidence = confidence + 20
    end
    if confidence > 99 then confidence = 99 end
    return confidence
end

local function classifyBallisticResult(confidence)
    if confidence >= 90 then return 'confirmado' end
    if confidence >= 65 then return 'compativel' end
    return 'sem_correspondencia'
end

local function uniqueNumberList(list)
    local out, seen = {}, {}
    for _, value in ipairs(list or {}) do
        local n = tonumber(value)
        if n and not seen[n] then
            seen[n] = true
            out[#out + 1] = n
        end
    end
    return out
end

-- ============================================================
-- REGISTRAR ITEM BALÍSTICO
-- ============================================================
lib.callback.register(resourceName .. ':server:registerBallistic', function(source, data)
    local src = source
    if not CheckForensicAuth(src) then return { success = false, error = L('ballistics.errors.not_authorized') } end
    if not CheckForensicPermission(src, 'canCollectEvidence') then
        return { success = false, error = L('ballistics.errors.no_permission_collect') }
    end

    local playerData = GetPlayerData(src)
    if not playerData then return { success = false, error = L('scene.errors.player_data_unavailable') } end
    data = data or {}

    local evidenceId = data.evidence_id and tonumber(data.evidence_id) or nil
    local sceneId = data.scene_id and tonumber(data.scene_id) or nil
    local itemType = normalizeItemType(data.item_type)
    local caliber = data.caliber and tostring(data.caliber):sub(1, 30) or nil
    local weaponSerial = normalizeSerial(data.weapon_serial)
    local weaponModel = data.weapon_model and tostring(data.weapon_model):sub(1, 80) or nil
    local weaponScratched = data.weapon_scratched and 1 or 0
    local notes = data.notes and tostring(data.notes):sub(1, 1000) or ''
    local caseId = data.case_id and tonumber(data.case_id) or nil
    local reportId = data.report_id and tonumber(data.report_id) or nil

    if itemType == 'arma' and not weaponSerial then
        weaponSerial = generateIllegalSerial()
        weaponScratched = 1
    end

    local itemValidation = ValidateAndConsumeForensicAction(src, 'collect_ballistic')
    if not itemValidation.success then
        return { success = false, error = itemValidation.error or L('ballistics.errors.missing_required_item', Config.Items.ballistic_kit) }
    end

    if evidenceId then
        local evidence = MySQL.single.await('SELECT id, scene_id, case_id, report_id FROM forensic_evidence WHERE id = ?', { evidenceId })
        if not evidence then
            return { success = false, error = L('ballistics.errors.evidence_not_found') }
        end

        if not sceneId and evidence.scene_id then sceneId = evidence.scene_id end
        if not caseId and evidence.case_id then caseId = evidence.case_id end
        if not reportId and evidence.report_id then reportId = evidence.report_id end
    end

    if sceneId then
        local scene = MySQL.single.await('SELECT id, status, case_id, report_id, location_x, location_y, location_z FROM forensic_crime_scenes WHERE id = ?', { sceneId })
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
                return { success = false, error = L('ballistics.errors.too_far_from_scene') }
            end
        end

        if not caseId and scene.case_id then caseId = scene.case_id end
        if not reportId and scene.report_id then reportId = scene.report_id end
    end

    local weapon = nil
    local ownerCitizenId = nil
    if weaponSerial then
        weapon = MySQL.single.await('SELECT serial, owner, type FROM mdt_weapons WHERE serial = ?', { weaponSerial })
        if weapon and not weaponModel then
            weaponModel = weapon.type
        end
        if weapon and weapon.owner and weapon.owner ~= '' then
            ownerCitizenId = weapon.owner
        end
    end
    local originType = weapon and 'mdt_legal' or 'ilegal'
    local ballisticSignature = ensureWeaponRegistry(weaponSerial, weaponModel, caliber, originType, ownerCitizenId, playerData.citizenid)

    local ballisticId = MySQL.insert.await([[
        INSERT INTO forensic_ballistics
        (evidence_id, scene_id, item_type, caliber, weapon_serial, weapon_model,
         weapon_scratched, rifling_match, collected_by, notes)
        VALUES (?, ?, ?, ?, ?, ?, ?, 'pendente', ?, ?)
    ]], {
        evidenceId,
        sceneId,
        itemType,
        caliber,
        weaponSerial,
        weaponModel,
        weaponScratched,
        playerData.citizenid,
        notes,
    })

    if not ballisticId then
        return { success = false, error = L('ballistics.errors.register_failed') }
    end

    if weaponSerial then
        MySQL.insert.await([[
            INSERT INTO forensic_cross_references
            (source_type, source_id, target_type, target_id, relationship, confidence, created_by, notes)
            VALUES ('ballistic', ?, 'weapon', ?, 'arma_apreendida', 'alta', ?, ?)
            ON DUPLICATE KEY UPDATE
                confidence = VALUES(confidence),
                notes = VALUES(notes),
                updated_at = NOW()
        ]], {
            ballisticId,
            weaponSerial,
            playerData.citizenid,
            ('Registro balístico: %s | Tipo: %s'):format(weaponSerial, itemType),
        })
    end

    if caseId then
        MySQL.insert.await([[
            INSERT INTO forensic_cross_references
            (source_type, source_id, target_type, target_id, relationship, confidence, created_by, notes)
            VALUES ('ballistic', ?, 'case', ?, 'vinculo_caso', 'media', ?, ?)
            ON DUPLICATE KEY UPDATE
                confidence = VALUES(confidence),
                notes = VALUES(notes),
                updated_at = NOW()
        ]], {
            ballisticId,
            tostring(caseId),
            playerData.citizenid,
            ('Item balístico vinculado ao caso %s'):format(caseId),
        })
    end

    if reportId then
        MySQL.insert.await([[
            INSERT INTO forensic_cross_references
            (source_type, source_id, target_type, target_id, relationship, confidence, created_by, notes)
            VALUES ('ballistic', ?, 'report', ?, 'vinculo_relatorio', 'media', ?, ?)
            ON DUPLICATE KEY UPDATE
                confidence = VALUES(confidence),
                notes = VALUES(notes),
                updated_at = NOW()
        ]], {
            ballisticId,
            tostring(reportId),
            playerData.citizenid,
            ('Item balístico vinculado ao relatório %s'):format(reportId),
        })
    end

    ForensicAuditLog(src, 'ballistic_registered', 'ballistic', ballisticId, {
        itemType = itemType,
        caliber = caliber,
        weaponSerial = weaponSerial,
        caseId = caseId,
        reportId = reportId,
        usedItems = itemValidation.usedItems,
    })

    return {
        success = true,
        id = ballisticId,
        itemType = itemType,
        weaponSerial = weaponSerial,
        ballisticSignature = ballisticSignature,
    }
end)

-- ============================================================
-- CONFRONTO BALÍSTICO
-- ============================================================
lib.callback.register(resourceName .. ':server:ballisticComparison', function(source, ballisticId, weaponSerial)
    local src = source
    if not CheckForensicAuth(src) then return { success = false, error = L('ballistics.errors.not_authorized') } end
    if not CheckForensicPermission(src, 'canRunLabTests') then
        return { success = false, error = L('ballistics.errors.no_permission_analyze') }
    end

    ballisticId = tonumber(ballisticId)
    weaponSerial = normalizeSerial(weaponSerial)
    if not ballisticId then return { success = false, error = L('ballistics.errors.invalid_id') } end

    local playerData = GetPlayerData(src)
    if not playerData then return { success = false, error = L('scene.errors.player_data_unavailable') } end
    local ballistic = MySQL.single.await('SELECT * FROM forensic_ballistics WHERE id = ?', { ballisticId })
    if not ballistic then return { success = false, error = L('ballistics.errors.not_found') } end
    if ballistic.item_type == 'arma' and not weaponSerial and ballistic.weapon_serial then
        weaponSerial = normalizeSerial(ballistic.weapon_serial)
    end
    if not weaponSerial then
        return { success = false, error = L('ballistics.errors.weapon_serial_compare_required') }
    end

    local weapon = MySQL.single.await('SELECT serial, owner, type FROM mdt_weapons WHERE serial = ?', { weaponSerial })
    local hasWeaponProfile = weapon ~= nil
    local exactSerialMatch = ballistic.weapon_serial and normalizeSerial(ballistic.weapon_serial) == weaponSerial

    local historicalMatch = MySQL.single.await([[
        SELECT id, scene_id, evidence_id
        FROM forensic_ballistics
        WHERE id != ?
          AND (
            matched_weapon_serial = ?
            OR weapon_serial = ?
          )
          AND (caliber = ? OR ? IS NULL OR ? = '')
        ORDER BY created_at DESC
        LIMIT 1
    ]], { ballisticId, weaponSerial, weaponSerial, ballistic.caliber, ballistic.caliber, ballistic.caliber })

    local hasHistoricalMatch = historicalMatch ~= nil
    local confidence = calcBallisticConfidence(ballistic, hasWeaponProfile, hasHistoricalMatch, exactSerialMatch)
    local result = classifyBallisticResult(confidence)
    local matchedSerial = result ~= 'sem_correspondencia' and weaponSerial or nil

    MySQL.update.await([[
        UPDATE forensic_ballistics
        SET rifling_match = ?, matched_weapon_serial = ?,
            analyzed_by = ?, analyzed_at = NOW()
        WHERE id = ?
    ]], { result, matchedSerial, playerData.citizenid, ballisticId })

    local linkedScenes, linkedCases, linkedReports = {}, {}, {}
    if matchedSerial then
        local links = MySQL.query.await([[
            SELECT DISTINCT
                fb.scene_id,
                COALESCE(fe.case_id, fcs.case_id) AS case_id,
                COALESCE(fe.report_id, fcs.report_id) AS report_id
            FROM forensic_ballistics fb
            LEFT JOIN forensic_evidence fe ON fe.id = fb.evidence_id
            LEFT JOIN forensic_crime_scenes fcs ON fcs.id = fb.scene_id
            WHERE (fb.matched_weapon_serial = ? OR fb.weapon_serial = ?)
              AND fb.id != ?
        ]], { matchedSerial, matchedSerial, ballisticId }) or {}

        for _, row in ipairs(links) do
            if row.scene_id then
                linkedScenes[#linkedScenes + 1] = row.scene_id
            end
            if row.case_id then
                linkedCases[#linkedCases + 1] = tonumber(row.case_id)
            end
            if row.report_id then
                linkedReports[#linkedReports + 1] = tonumber(row.report_id)
            end
        end

        linkedCases = uniqueNumberList(linkedCases)
        linkedReports = uniqueNumberList(linkedReports)

        if #linkedScenes > 0 then
            MySQL.update.await(
                'UPDATE forensic_ballistics SET linked_scenes = ? WHERE id = ?',
                { json.encode(linkedScenes), ballisticId }
            )
        end

        MySQL.insert.await([[
            INSERT INTO forensic_cross_references
            (source_type, source_id, target_type, target_id, relationship, confidence, created_by, notes)
            VALUES ('ballistic', ?, 'weapon', ?, 'confronto_balistico', ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                confidence = VALUES(confidence),
                notes = VALUES(notes),
                updated_at = NOW()
        ]], {
            ballisticId, matchedSerial,
            result == 'confirmado' and 'confirmada' or 'alta',
            playerData.citizenid,
            ('Confronto balístico: %s | Tipo: %s | Calibre: %s | Confiança: %d%%'):format(
                result, ballistic.item_type or 'N/A', ballistic.caliber or 'N/A', confidence
            ),
        })

        if weapon and weapon.owner then
            MySQL.insert.await([[
                INSERT INTO forensic_cross_references
                (source_type, source_id, target_type, target_id, relationship, confidence, created_by, notes)
                VALUES ('ballistic', ?, 'citizenid', ?, 'proprietario_arma', ?, ?, ?)
                ON DUPLICATE KEY UPDATE
                    confidence = VALUES(confidence),
                    notes = VALUES(notes),
                    updated_at = NOW()
            ]], {
                ballisticId, weapon.owner,
                result == 'confirmado' and 'confirmada' or 'alta',
                playerData.citizenid,
                ('Proprietário da arma serial %s'):format(matchedSerial),
            })
        end

        for _, caseId in ipairs(linkedCases) do
            MySQL.insert.await([[
                INSERT INTO forensic_cross_references
                (source_type, source_id, target_type, target_id, relationship, confidence, created_by, notes)
                VALUES ('ballistic', ?, 'case', ?, 'arma_correlacionada', ?, ?, ?)
                ON DUPLICATE KEY UPDATE
                    confidence = VALUES(confidence),
                    notes = VALUES(notes),
                    updated_at = NOW()
            ]], {
                ballisticId,
                tostring(caseId),
                result == 'confirmado' and 'confirmada' or 'alta',
                playerData.citizenid,
                ('Arma correlacionada ao caso %s via confronto balístico'):format(caseId),
            })
        end

        for _, reportId in ipairs(linkedReports) do
            MySQL.insert.await([[
                INSERT INTO forensic_cross_references
                (source_type, source_id, target_type, target_id, relationship, confidence, created_by, notes)
                VALUES ('ballistic', ?, 'report', ?, 'arma_correlacionada', ?, ?, ?)
                ON DUPLICATE KEY UPDATE
                    confidence = VALUES(confidence),
                    notes = VALUES(notes),
                    updated_at = NOW()
            ]], {
                ballisticId,
                tostring(reportId),
                result == 'confirmado' and 'confirmada' or 'alta',
                playerData.citizenid,
                ('Arma correlacionada ao relatório %s via confronto balístico'):format(reportId),
            })
        end
    end

    MySQL.insert.await([[
        INSERT INTO forensic_lab_tests
        (evidence_id, scene_id, test_type, test_name, result_level, result_details,
         target_weapon_serial, requested_by, requested_by_name,
         performed_by, performed_by_name, started_at, completed_at, status)
        VALUES (?, ?, 'confronto_balistico', 'Confronto Balístico', ?, ?, ?, ?, ?, ?, ?, NOW(), NOW(), 'concluido')
    ]], {
        ballistic.evidence_id, ballistic.scene_id,
        result == 'confirmado' and 'confirmado' or (result == 'compativel' and 'compativel' or 'negativo'),
        ('Arma: %s | Resultado: %s | Tipo: %s | Calibre: %s | Confiança: %d%% | Cenas vinculadas: %d'):format(
            weaponSerial, result, ballistic.item_type or 'N/A', ballistic.caliber or 'N/A', confidence, #linkedScenes
        ),
        weaponSerial,
        playerData.citizenid, playerData.name,
        playerData.citizenid, playerData.name,
    })

    if matchedSerial and weapon and weapon.owner and ForensicProcessIntelligenceMatch then
        local ev = ballistic.evidence_id and MySQL.single.await('SELECT id, case_id, report_id, scene_id FROM forensic_evidence WHERE id = ?', { ballistic.evidence_id }) or nil
        local intelligence = ForensicProcessIntelligenceMatch({
            citizenid = weapon.owner,
            case_id = ev and ev.case_id or (linkedCases and linkedCases[1] or nil),
            report_id = ev and ev.report_id or (linkedReports and linkedReports[1] or nil),
            scene_id = ballistic.scene_id or (ev and ev.scene_id or nil),
            evidence_id = ballistic.evidence_id,
            source_type = 'ballistic',
            source_id = ballisticId,
            match_kind = ballistic.item_type == 'projetil' and 'projetil' or (ballistic.item_type == 'capsula' and 'capsula' or 'arma'),
            association_level = result == 'confirmado' and 'confirmacao' or 'compatibilidade_forte',
            confidence_score = confidence,
            algorithm_name = 'ballistic_cross_case_v1',
            algorithm_version = '2026.03',
            exam_performed_by = playerData.citizenid,
            generated_by = playerData.citizenid,
            exam_origin = ballistic.item_type,
            rationale = ('Confronto balístico %s com serial %s e confiança %d%%'):format(result, matchedSerial, confidence),
            metadata = {
                ballistic_id = ballisticId,
                weapon_serial = matchedSerial,
                linked_scenes = linkedScenes,
            },
        })
        if intelligence and intelligence.autoWanted then
            ForensicAuditLog(src, 'forensic_auto_wanted_from_ballistics', 'ballistic', ballisticId, {
                citizenid = weapon.owner,
                confidence = confidence,
            })
        end
    end

    ForensicAuditLog(src, 'ballistic_comparison', 'ballistic', ballisticId, {
        weaponSerial = weaponSerial, result = result, confidence = confidence,
        linkedScenes = linkedScenes,
    })

    return {
        success = true,
        result = result,
        confidence = confidence,
        resultLabel = L(('ballistics.result.%s'):format(result)),
        weaponOwner = weapon and weapon.owner or nil,
        matchedWeaponSerial = matchedSerial,
        linkedScenes = linkedScenes,
        linkedCases = linkedCases,
        linkedReports = linkedReports,
        forensicReport = ('Balística %s | Item: %s | Calibre: %s | Arma: %s | Confiança: %d%%'):format(
            result,
            ballistic.item_type or 'N/A',
            ballistic.caliber or 'N/A',
            matchedSerial or weaponSerial,
            confidence
        ),
    }
end)

-- ============================================================
-- HISTÓRICO BALÍSTICO DE ARMA
-- ============================================================
lib.callback.register(resourceName .. ':server:getWeaponBallisticHistory', function(source, weaponSerial)
    local src = source
    if not CheckForensicAuth(src) then return {} end
    weaponSerial = normalizeSerial(weaponSerial)
    if not weaponSerial then return {} end

    return MySQL.query.await([[
        SELECT
            fb.*,
            fcs.scene_number,
            fcs.classification,
            COALESCE(fe.case_id, fcs.case_id) AS case_id,
            COALESCE(fe.report_id, fcs.report_id) AS report_id
        FROM forensic_ballistics fb
        LEFT JOIN forensic_crime_scenes fcs ON fb.scene_id = fcs.id
        LEFT JOIN forensic_evidence fe ON fb.evidence_id = fe.id
        WHERE fb.weapon_serial = ? OR fb.matched_weapon_serial = ?
        ORDER BY fb.created_at DESC
    ]], { weaponSerial, weaponSerial }) or {}
end)
