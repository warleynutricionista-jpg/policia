-- ============================================================
-- PS-FORENSICS - Módulo: Balística (Server)
-- ============================================================

local resourceName = GetCurrentResourceName()

-- ============================================================
-- REGISTRAR ITEM BALÍSTICO
-- ============================================================
lib.callback.register(resourceName .. ':server:registerBallistic', function(source, data)
    local src = source
    if not CheckForensicAuth(src) then return { success = false } end
    if not CheckForensicPermission(src, 'canCollectEvidence') then
        return { success = false, error = 'Sem permissão' }
    end

    local playerData = GetPlayerData(src)

    local ballisticId = MySQL.insert.await([[
        INSERT INTO forensic_ballistics
        (evidence_id, scene_id, item_type, caliber, weapon_serial, weapon_model,
         weapon_scratched, rifling_match, collected_by, notes)
        VALUES (?, ?, ?, ?, ?, ?, ?, 'pendente', ?, ?)
    ]], {
        data.evidence_id and tonumber(data.evidence_id) or nil,
        data.scene_id and tonumber(data.scene_id) or nil,
        data.item_type or 'capsula',
        data.caliber or '',
        data.weapon_serial or nil,
        data.weapon_model or nil,
        data.weapon_scratched and 1 or 0,
        playerData.citizenid,
        data.notes or '',
    })

    ForensicAuditLog(src, 'ballistic_registered', 'ballistic', ballisticId, {
        itemType = data.item_type,
        caliber = data.caliber,
    })

    return { success = true, id = ballisticId }
end)

-- ============================================================
-- CONFRONTO BALÍSTICO
-- ============================================================
lib.callback.register(resourceName .. ':server:ballisticComparison', function(source, ballisticId, weaponSerial)
    local src = source
    if not CheckForensicAuth(src) then return { success = false } end
    if not CheckForensicPermission(src, 'canRunLabTests') then
        return { success = false, error = 'Sem permissão para análise laboratorial' }
    end

    ballisticId = tonumber(ballisticId)
    if not ballisticId or not weaponSerial then return { success = false } end

    local playerData = GetPlayerData(src)
    local ballistic = MySQL.single.await('SELECT * FROM forensic_ballistics WHERE id = ?', { ballisticId })
    if not ballistic then return { success = false, error = 'Item balístico não encontrado' } end

    -- Verificar arma no MDT
    local weapon = MySQL.single.await('SELECT * FROM mdt_weapons WHERE serial = ?', { weaponSerial })

    local result = 'sem_correspondencia'
    local confidence = 0

    if weapon then
        -- Simular confronto baseado no calibre
        if ballistic.caliber and ballistic.caliber ~= '' then
            -- Se calibre bate, alta chance de match
            local calibreMatch = math.random() < 0.80
            if calibreMatch then
                result = 'compativel'
                confidence = 70 + math.random(25)

                if confidence > 90 then
                    result = 'confirmado'
                end
            end
        else
            -- Sem calibre definido, chance menor
            if math.random() < 0.40 then
                result = 'compativel'
                confidence = 40 + math.random(30)
            end
        end
    end

    MySQL.update.await([[
        UPDATE forensic_ballistics
        SET rifling_match = ?, matched_weapon_serial = ?,
            analyzed_by = ?, analyzed_at = NOW()
        WHERE id = ?
    ]], { result, result ~= 'sem_correspondencia' and weaponSerial or nil, playerData.citizenid, ballisticId })

    -- Buscar outras cenas onde a mesma arma foi usada
    local linkedScenes = {}
    if result == 'compativel' or result == 'confirmado' then
        local otherMatches = MySQL.query.await([[
            SELECT DISTINCT scene_id FROM forensic_ballistics
            WHERE matched_weapon_serial = ? AND scene_id IS NOT NULL AND id != ?
        ]], { weaponSerial, ballisticId })

        if otherMatches then
            for _, row in ipairs(otherMatches) do
                linkedScenes[#linkedScenes + 1] = row.scene_id
            end
        end

        if #linkedScenes > 0 then
            MySQL.update.await(
                'UPDATE forensic_ballistics SET linked_scenes = ? WHERE id = ?',
                { json.encode(linkedScenes), ballisticId }
            )
        end

        -- Referência cruzada
        MySQL.insert.await([[
            INSERT INTO forensic_cross_references
            (source_type, source_id, target_type, target_id, relationship, confidence, created_by, notes)
            VALUES ('ballistic', ?, 'weapon', ?, 'confronto_balistico', ?, ?, ?)
        ]], {
            ballisticId, weaponSerial,
            confidence >= 90 and 'confirmada' or 'alta',
            playerData.citizenid,
            ('Confronto balístico: %s | Calibre: %s | Confiança: %d%%'):format(result, ballistic.caliber or 'N/A', confidence),
        })

        -- Se a arma tem dono, vincular ao cidadão
        if weapon and weapon.owner then
            MySQL.insert.await([[
                INSERT INTO forensic_cross_references
                (source_type, source_id, target_type, target_id, relationship, confidence, created_by, notes)
                VALUES ('ballistic', ?, 'citizenid', ?, 'proprietario_arma', ?, ?, ?)
            ]], {
                ballisticId, weapon.owner,
                confidence >= 90 and 'confirmada' or 'alta',
                playerData.citizenid,
                ('Proprietário da arma serial %s'):format(weaponSerial),
            })
        end
    end

    -- Registrar teste
    MySQL.insert.await([[
        INSERT INTO forensic_lab_tests
        (evidence_id, scene_id, test_type, test_name, result_level, result_details,
         target_weapon_serial, requested_by, requested_by_name,
         performed_by, performed_by_name, started_at, completed_at, status)
        VALUES (?, ?, 'confronto_balistico', 'Confronto Balístico', ?, ?, ?, ?, ?, ?, ?, NOW(), NOW(), 'concluido')
    ]], {
        ballistic.evidence_id, ballistic.scene_id,
        result == 'confirmado' and 'confirmado' or (result == 'compativel' and 'compativel' or 'negativo'),
        ('Arma: %s | Resultado: %s | Confiança: %d%% | Cenas vinculadas: %d'):format(
            weaponSerial, result, confidence, #linkedScenes
        ),
        weaponSerial,
        playerData.citizenid, playerData.name,
        playerData.citizenid, playerData.name,
    })

    ForensicAuditLog(src, 'ballistic_comparison', 'ballistic', ballisticId, {
        weaponSerial = weaponSerial, result = result, confidence = confidence,
        linkedScenes = linkedScenes,
    })

    return {
        success = true,
        result = result,
        confidence = confidence,
        weaponOwner = weapon and weapon.owner or nil,
        linkedScenes = linkedScenes,
    }
end)

-- ============================================================
-- HISTÓRICO BALÍSTICO DE ARMA
-- ============================================================
lib.callback.register(resourceName .. ':server:getWeaponBallisticHistory', function(source, weaponSerial)
    local src = source
    if not CheckForensicAuth(src) then return {} end

    return MySQL.query.await([[
        SELECT fb.*, fcs.scene_number, fcs.classification
        FROM forensic_ballistics fb
        LEFT JOIN forensic_crime_scenes fcs ON fb.scene_id = fcs.id
        WHERE fb.weapon_serial = ? OR fb.matched_weapon_serial = ?
        ORDER BY fb.created_at DESC
    ]], { weaponSerial, weaponSerial }) or {}
end)
