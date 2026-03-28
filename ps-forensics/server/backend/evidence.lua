-- ============================================================
-- PS-FORENSICS - Módulo: Coleta de Evidências (Server)
-- ============================================================

local resourceName = GetCurrentResourceName()
local evidenceTypeMap = {}
local evidenceCategoryMap = {}

for _, entry in ipairs(Config.EvidenceTypes or {}) do
    evidenceTypeMap[entry.type] = entry
    evidenceCategoryMap[entry.category] = true
end

local typeAliases = {
    arma = 'arma_fogo',
    digital = 'impressao_digital',
    dna = 'tecido_biologico',
    droga = 'residuo_droga',
    ['residuo_de_polvora'] = 'residuo_polvora',
    ['resíduo_de_pólvora'] = 'residuo_polvora',
    residuodepolvora = 'residuo_polvora',
    vestigio_biologico = 'fluido_biologico',
    ['vestígio_biológico'] = 'fluido_biologico',
    eletronico = 'dispositivo_eletronico',
    ['eletrônico'] = 'dispositivo_eletronico',
    objeto = 'outros',
    veiculo = 'veiculo_cena',
    ['veículo'] = 'veiculo_cena',
}

local requiredItemByType = {
    sangue = Config.Items.blood_reagent,
    capsula = Config.Items.forensic_tweezers,
    projetil = Config.Items.ballistic_kit,
    arma_fogo = Config.Items.ballistic_kit,
    impressao_digital = Config.Items.fingerprint_kit,
    tecido_biologico = Config.Items.dna_swab,
    fluido_biologico = Config.Items.dna_swab,
    residuo_droga = Config.Items.drug_test_kit,
    residuo_polvora = Config.Items.gsr_kit,
    roupa = Config.Items.evidence_bag,
    faca = Config.Items.forensic_tweezers,
    dispositivo_eletronico = Config.Items.evidence_bag,
    veiculo_cena = Config.Items.evidence_marker,
    outros = Config.Items.forensic_kit,
}

local function hasRequiredItem(src, itemName)
    if not itemName then return true end
    if GetResourceState('ox_inventory') ~= 'started' then return true end

    local count = exports.ox_inventory:GetItemCount(src, itemName) or 0
    return count > 0
end

local function normalizeEvidenceType(inputType)
    local t = (inputType or 'outros'):lower()
    t = t:gsub('%s+', '_')
    return typeAliases[t] or t
end

local function isValidURL(url)
    if not url or url == '' then return true end
    return url:match('^https?://') ~= nil or url:match('^forensic%-') ~= nil
end

local function validateCaseAndReport(caseId, reportId)
    if caseId then
        local caseExists = MySQL.scalar.await('SELECT COUNT(*) FROM mdt_cases WHERE id = ? LIMIT 1', { caseId })
        if tonumber(caseExists) == 0 then
            return false, L('scene.errors.not_found')
        end
    end

    if reportId then
        local report = MySQL.single.await('SELECT id, report_status FROM mdt_reports WHERE id = ? LIMIT 1', { reportId })
        if not report then
            return false, L('reports.errors.not_found')
        end
        if report.report_status == 'archived' then
            return false, L('reports.errors.archived')
        end
    end

    return true, nil
end

local function generateUniqueSealNumber()
    local tries = 0
    while tries < 5 do
        local seal = ForensicUtils.GenerateSealNumber()
        local exists = MySQL.scalar.await('SELECT COUNT(*) FROM forensic_evidence WHERE seal_number = ?', { seal })
        if not exists or exists == 0 then
            return seal
        end
        tries = tries + 1
    end
    return ForensicUtils.GenerateSealNumber() .. tostring(math.random(10, 99))
end

local function normalizeLookupValue(value)
    if value == nil then return nil end
    local str = tostring(value):gsub('^%s*(.-)%s*$', '%1')
    if str == '' then return nil end
    return str
end

local function queryCitizenProfileByIdentifier(identifier)
    local needle = normalizeLookupValue(identifier)
    if not needle then return nil end

    if GetResourceState('ps-mdt') == 'started' then
        local ok, mdtResult = pcall(function()
            return lib.callback.await('ps-mdt:server:lookupCitizenIdentity', false, { query = needle })
        end)
        if ok and mdtResult and mdtResult.citizenid then
            return mdtResult
        end
    end

    local exact = MySQL.single.await([[
        SELECT mp.citizenid,
               mp.fullname AS profile_name,
               JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')) AS firstname,
               JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname')) AS lastname,
               JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.phone')) AS phone,
               JSON_UNQUOTE(JSON_EXTRACT(p.job, '$.label')) AS job_label
        FROM mdt_profiles mp
        LEFT JOIN players p ON p.citizenid = mp.citizenid
        WHERE mp.citizenid = ?
        LIMIT 1
    ]], { needle })

    if not exact then
        local like = '%' .. needle:lower() .. '%'
        exact = MySQL.single.await([[
            SELECT mp.citizenid,
                   mp.fullname AS profile_name,
                   JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')) AS firstname,
                   JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname')) AS lastname,
                   JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.phone')) AS phone,
                   JSON_UNQUOTE(JSON_EXTRACT(p.job, '$.label')) AS job_label
            FROM mdt_profiles mp
            LEFT JOIN players p ON p.citizenid = mp.citizenid
            WHERE LOWER(mp.fullname) LIKE ?
               OR LOWER(JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname'))) LIKE ?
               OR LOWER(JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname'))) LIKE ?
               OR LOWER(CONCAT(
                    COALESCE(JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')), ''),
                    ' ',
                    COALESCE(JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname')), '')
               )) LIKE ?
            ORDER BY mp.id DESC
            LIMIT 1
        ]], { like, like, like, like })
    end

    if not exact then return nil end

    local fullName = exact.profile_name
    if (not fullName or fullName == '') and (exact.firstname or exact.lastname) then
        fullName = ('%s %s'):format(exact.firstname or '', exact.lastname or ''):gsub('^%s*(.-)%s*$', '%1')
    end

    return {
        citizenid = exact.citizenid,
        name = fullName or L('labels.unknown'),
        firstname = exact.firstname or nil,
        lastname = exact.lastname or nil,
        phone = exact.phone or nil,
        job = exact.job_label or nil,
    }
end

local function queryWeaponRegistryBySerial(serial)
    local normalizedSerial = normalizeLookupValue(serial)
    if not normalizedSerial then return nil end

    if GetResourceState('ps-mdt') == 'started' then
        local ok, mdtResult = pcall(function()
            return lib.callback.await('ps-mdt:server:lookupWeaponRegistry', false, { serial = normalizedSerial })
        end)
        if ok and mdtResult and mdtResult.serial then
            return mdtResult
        end
    end

    local weapon = MySQL.single.await([[
        SELECT w.id, w.serial, w.weaponModel, w.weaponClass, w.owner,
               mp.fullname AS owner_name
        FROM mdt_weapons w
        LEFT JOIN mdt_profiles mp ON mp.citizenid = w.owner
        WHERE w.serial = ?
        LIMIT 1
    ]], { normalizedSerial })

    if not weapon then
        weapon = MySQL.single.await([[
            SELECT w.id, w.serial, w.weaponModel, w.weaponClass, w.owner,
                   mp.fullname AS owner_name
            FROM mdt_weapons w
            LEFT JOIN mdt_profiles mp ON mp.citizenid = w.owner
            WHERE LOWER(w.serial) LIKE ?
            ORDER BY w.id DESC
            LIMIT 1
        ]], { '%' .. normalizedSerial:lower() .. '%' })
    end

    if not weapon then return nil end

    return {
        id = weapon.id,
        serial = weapon.serial,
        weapon_model = weapon.weaponModel,
        weapon_class = weapon.weaponClass,
        owner_citizenid = weapon.owner,
        owner_name = weapon.owner_name or nil,
    }
end

local validEvidenceStatuses = {}
for _, status in ipairs((Config.Enums and Config.Enums.EvidenceStatus) or {
    'coletada', 'lacrada', 'em_analise', 'analisada', 'armazenada', 'descartada', 'devolvida', 'em_julgamento'
}) do
    validEvidenceStatuses[status] = true
end

local statusTransitions = {
    coletada = { lacrada = true, em_analise = true, armazenada = true, devolvida = true, descartada = true },
    lacrada = { em_analise = true, armazenada = true, devolvida = true, em_julgamento = true },
    em_analise = { analisada = true, lacrada = true },
    analisada = { lacrada = true, armazenada = true, devolvida = true, em_julgamento = true, descartada = true },
    armazenada = { em_analise = true, devolvida = true, em_julgamento = true, descartada = true },
    em_julgamento = { armazenada = true, devolvida = true },
    devolvida = {},
    descartada = {},
}

local actionByStatus = {
    lacrada = 'lacrada',
    em_analise = 'aberta_analise',
    analisada = 'relacrada',
    armazenada = 'armazenada',
    descartada = 'descartada',
    devolvida = 'devolvida',
    em_julgamento = 'encaminhada_julgamento',
}

lib.callback.register(resourceName .. ':server:lookupCitizenProfile', function(source, identifier)
    local src = source
    if not CheckForensicAuth(src) then return nil end
    if not CheckForensicPermission(src, 'canCollectEvidence') then return nil end
    return queryCitizenProfileByIdentifier(identifier)
end)

lib.callback.register(resourceName .. ':server:lookupWeaponRegistry', function(source, serial)
    local src = source
    if not CheckForensicAuth(src) then return nil end
    if not CheckForensicPermission(src, 'canCollectEvidence') then return nil end
    return queryWeaponRegistryBySerial(serial)
end)

local function recordCustody(evidenceId, action, fromCitizenId, fromName, toCitizenId, toName, location, notes)
    local previousHash = MySQL.scalar.await(
        'SELECT integrity_hash FROM forensic_chain_of_custody WHERE evidence_id = ? ORDER BY id DESC LIMIT 1',
        { evidenceId }
    )
    local raw = table.concat({
        tostring(evidenceId or ''),
        tostring(action or ''),
        tostring(fromCitizenId or ''),
        tostring(toCitizenId or ''),
        tostring(location or ''),
        tostring(notes or ''),
        tostring(previousHash or ''),
        tostring(os.time()),
    }, '|')
    local integrityHash = MySQL.scalar.await('SELECT SHA2(?, 256)', { raw })

    return MySQL.insert.await([[
        INSERT INTO forensic_chain_of_custody
        (evidence_id, action, from_citizenid, from_name, to_citizenid, to_name, location, notes, integrity_hash, previous_integrity_hash)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        evidenceId, action, fromCitizenId, fromName, toCitizenId, toName, location or '', notes or '', integrityHash, previousHash
    })
end

local function syncMDTCustody(mdtId, fromCitizenId, toCitizenId, action, notes)
    if not mdtId then return end
    if toCitizenId and toCitizenId ~= '' then
        MySQL.update.await('UPDATE mdt_evidence_items SET last_holder = ? WHERE id = ?', { toCitizenId, mdtId })
    end
    MySQL.insert.await([[
        INSERT INTO mdt_evidence_custody (evidence_id, from_citizenid, to_citizenid, action, notes)
        VALUES (?, ?, ?, ?, ?)
    ]], { mdtId, fromCitizenId, toCitizenId, action, notes or '' })
end

local function getOrCreateDefaultDeposit(src, playerData)
    local code = 'DEP-PADRAO'
    local existing = MySQL.single.await(
        'SELECT id, deposit_code, name FROM forensic_evidence_deposits WHERE deposit_code = ? LIMIT 1',
        { code }
    )
    if existing then return existing end

    local actor = (playerData and playerData.citizenid) or (GetPlayerData(src) and GetPlayerData(src).citizenid) or 'system'
    local insertedId = MySQL.insert.await([[
        INSERT INTO forensic_evidence_deposits
        (deposit_code, name, location_label, is_active, created_by)
        VALUES (?, ?, ?, 1, ?)
    ]], { code, 'Depósito Central de Evidências', 'Central Forense', actor })

    return MySQL.single.await('SELECT id, deposit_code, name FROM forensic_evidence_deposits WHERE id = ?', { insertedId })
end

local function autoStoreEvidenceInDeposit(src, evidenceId, evidenceNumber, actorData, noteOverride)
    local evidenceRow = MySQL.single.await('SELECT id, mdt_evidence_id FROM forensic_evidence WHERE id = ?', { evidenceId })
    if not evidenceRow then
        return false, 'Evidência não encontrada para armazenamento.'
    end

    local deposit = getOrCreateDefaultDeposit(src, actorData)
    if not deposit or not deposit.id then
        return false, 'Falha ao resolver depósito de evidências.'
    end

    local locationLabel = ('%s (%s)'):format(deposit.name or 'Depósito', deposit.deposit_code or '')
    MySQL.update.await([[
        UPDATE forensic_evidence
        SET status = 'armazenada',
            storage_location = ?,
            deposit_id = ?,
            current_holder_citizenid = ?,
            current_holder_name = ?
        WHERE id = ?
    ]], {
        locationLabel,
        deposit.id,
        actorData and actorData.citizenid or nil,
        actorData and actorData.name or nil,
        evidenceId
    })

    MySQL.insert.await([[
        INSERT INTO forensic_evidence_storage_events
        (evidence_id, deposit_id, action, action_by, action_by_name, notes)
        VALUES (?, ?, 'stored', ?, ?, ?)
    ]], {
        evidenceId,
        deposit.id,
        actorData and actorData.citizenid or 'system',
        actorData and actorData.name or 'Sistema',
        noteOverride or ('Evidência %s armazenada automaticamente no depósito %s'):format(evidenceNumber or tostring(evidenceId), deposit.deposit_code or '')
    })

    recordCustody(
        evidenceId,
        'armazenada',
        actorData and actorData.citizenid or nil,
        actorData and actorData.name or nil,
        actorData and actorData.citizenid or nil,
        actorData and actorData.name or nil,
        locationLabel,
        ('Vínculo automático ao depósito %s'):format(deposit.deposit_code or '')
    )

    syncMDTCustody(
        evidenceRow.mdt_evidence_id,
        actorData and actorData.citizenid or nil,
        actorData and actorData.citizenid or nil,
        'stored',
        ('Armazenada no depósito %s'):format(deposit.deposit_code or '')
    )

    return true, deposit
end

-- ============================================================
-- COLETAR EVIDÊNCIA
-- ============================================================
lib.callback.register(resourceName .. ':server:collectEvidence', function(source, data)
    local src = source
    if not CheckForensicAuth(src) then return { success = false, error = L('scene.errors.not_authorized') } end
    if not CheckForensicPermission(src, 'canCollectEvidence') then
        return { success = false, error = L('evidence.errors.no_permission_collect') }
    end

    local playerData = GetPlayerData(src)
    if not playerData then return { success = false, error = L('scene.errors.player_data_unavailable') } end
    data = data or {}

    local sceneId = data.scene_id and tonumber(data.scene_id) or nil
    local caseId = data.case_id and tonumber(data.case_id) or nil
    local reportId = data.report_id and tonumber(data.report_id) or nil
    local incidentId = data.incident_id and tonumber(data.incident_id) or nil
    local mdtEvidenceId = data.mdt_evidence_id and tonumber(data.mdt_evidence_id) or nil
    local evidenceType = normalizeEvidenceType(data.type)
    local evidenceEntry = evidenceTypeMap[evidenceType]
    local evidenceCategory = data.category or (evidenceEntry and evidenceEntry.category) or 'outros'
    local subtype = data.subtype and tostring(data.subtype):sub(1, 80) or nil
    local description = data.description and tostring(data.description):sub(1, 1000) or ''
    local locationName = data.location_name and tostring(data.location_name):sub(1, 200) or ''
    local photoUrl = data.photo_url and tostring(data.photo_url):sub(1, 255) or nil
    local autoStore = data.auto_store == true

    if not evidenceEntry then
        return { success = false, error = L('evidence.errors.invalid_type') }
    end

    if not evidenceCategoryMap[evidenceCategory] then
        return { success = false, error = L('evidence.errors.invalid_category') }
    end

    if not isValidURL(photoUrl) then
        return { success = false, error = L('evidence.errors.invalid_photo_url') }
    end

    local actionName = 'collect_evidence'
    if evidenceType == 'sangue' or evidenceType == 'tecido_biologico' or evidenceType == 'fluido_biologico' then
        actionName = 'collect_biological'
    elseif evidenceType == 'impressao_digital' then
        actionName = 'collect_fingerprint_sequence'
    elseif evidenceType == 'capsula' or evidenceType == 'projetil' or evidenceType == 'arma_fogo' then
        actionName = 'collect_ballistic'
    end

    local itemValidation = ValidateAndConsumeForensicAction(src, actionName)
    if not itemValidation.success then
        return { success = false, error = itemValidation.error or L('evidence.errors.missing_required_item', 'item') }
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
                return { success = false, error = L('evidence.errors.too_far_from_scene') }
            end
        end

        if not caseId and scene.case_id then caseId = scene.case_id end
        if not reportId and scene.report_id then reportId = scene.report_id end
    end

    local linksOk, linksError = validateCaseAndReport(caseId, reportId)
    if not linksOk then
        return { success = false, error = linksError }
    end

    local duplicateEvidence = MySQL.scalar.await([[
        SELECT id
        FROM forensic_evidence
        WHERE type = ?
          AND IFNULL(scene_id, 0) = IFNULL(?, 0)
          AND ABS(IFNULL(collection_x, 0) - IFNULL(?, 0)) < 1.0
          AND ABS(IFNULL(collection_y, 0) - IFNULL(?, 0)) < 1.0
          AND TIMESTAMPDIFF(SECOND, created_at, NOW()) <= 180
        ORDER BY id DESC
        LIMIT 1
    ]], { evidenceType, sceneId, data.x or 0.0, data.y or 0.0 })
    if duplicateEvidence then
        return { success = false, error = L('evidence.errors.already_collected') }
    end

    local sealNumber = generateUniqueSealNumber()

    local evidenceId = MySQL.insert.await([[
        INSERT INTO forensic_evidence
        (evidence_number, scene_id, case_id, report_id, incident_id, mdt_evidence_id, category, type, subtype,
         description, collection_location, collection_x, collection_y, collection_z,
         collected_by, collected_by_name, collection_method, seal_number, status,
         photo_url, linked_citizenid, linked_vehicle_plate, linked_weapon_serial, priority)
        VALUES ('', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'coletada', ?, ?, ?, ?, ?)
    ]], {
        sceneId,
        caseId,
        reportId,
        incidentId,
        mdtEvidenceId,
        evidenceCategory,
        evidenceType,
        subtype,
        description,
        locationName,
        data.x or 0.0, data.y or 0.0, data.z or 0.0,
        playerData.citizenid,
        playerData.name,
        (data.collection_method or 'Manual') .. (' | Itens: %s'):format(json.encode(itemValidation.usedItems or {})),
        sealNumber,
        photoUrl,
        data.linked_citizenid or nil,
        data.linked_vehicle_plate or nil,
        data.linked_weapon_serial or nil,
        data.priority or 'media',
    })

    if not evidenceId then
        return { success = false, error = L('evidence.errors.register_failed') }
    end

    -- Gerar número de evidência
    local evidenceNumber = ForensicUtils.GenerateEvidenceNumber(evidenceId)
    MySQL.update.await('UPDATE forensic_evidence SET evidence_number = ? WHERE id = ?', { evidenceNumber, evidenceId })

    -- Registrar na cadeia de custódia
    MySQL.insert.await([[
        INSERT INTO forensic_chain_of_custody
        (evidence_id, action, to_citizenid, to_name, location, notes, integrity_hash, previous_integrity_hash)
        VALUES (?, 'coletada', ?, ?, ?, ?, SHA2(CONCAT(?, '|coletada|', COALESCE(?, ''), '|', COALESCE(?, ''), '|', COALESCE(?, '')), 256), NULL)
    ]], {
        evidenceId,
        playerData.citizenid,
        playerData.name,
        locationName,
        L('evidence.custody.initial_collect', sealNumber),
        evidenceId,
        playerData.citizenid,
        locationName,
        sealNumber,
    })

    -- Sincronizar com mdt_evidence_items do ps-mdt
    local mdtEvidenceId = MySQL.insert.await([[
        INSERT INTO mdt_evidence_items
        (case_id, report_id, title, type, serial, notes, location, stored, last_holder, created_by)
        VALUES (?, ?, ?, ?, ?, ?, ?, 0, ?, ?)
    ]], {
        caseId,
        reportId,
        ('[FORENSE] %s - %s'):format(ForensicUtils.GetEvidenceTypeLabel(evidenceType), evidenceNumber),
        evidenceCategory or 'Evidence',
        sealNumber,
        description,
        locationName,
        playerData.citizenid,
        playerData.citizenid,
    })

    if mdtEvidenceId then
        MySQL.update.await('UPDATE forensic_evidence SET mdt_evidence_id = ? WHERE id = ?', { mdtEvidenceId, evidenceId })

        -- Registrar custódia no MDT também
        MySQL.insert.await([[
            INSERT INTO mdt_evidence_custody (evidence_id, from_citizenid, to_citizenid, action, notes)
            VALUES (?, NULL, ?, 'collected', ?)
        ]], { mdtEvidenceId, playerData.citizenid, ('Evidência forense #%s coletada'):format(evidenceNumber) })
    end

    MySQL.update.await([[
        UPDATE forensic_evidence
        SET current_holder_citizenid = ?, current_holder_name = ?, sealed_at = NOW()
        WHERE id = ?
    ]], { playerData.citizenid, playerData.name, evidenceId })

    if ForensicAttachEvidenceToCitizen and data.linked_citizenid and data.linked_citizenid ~= '' then
        ForensicAttachEvidenceToCitizen({
            evidence_id = evidenceId,
            citizenid = data.linked_citizenid,
            actor_citizenid = playerData.citizenid,
            possession_type = data.possession_type or 'ambiente',
            link_origin = data.link_origin or 'apreensao',
            confidence_score = tonumber(data.link_confidence_score) or 65,
            notes = data.link_notes or description,
        })
    end

    ForensicAuditLog(src, 'evidence_collected', 'evidence', evidenceId, {
        evidenceNumber = evidenceNumber,
        type = evidenceType,
        category = evidenceCategory,
        sealNumber = sealNumber,
        sceneId = sceneId,
        caseId = caseId,
        reportId = reportId,
        actionName = actionName,
        usedItems = itemValidation.usedItems,
    })

    TriggerEvent('ps-forensics:server:onEvidenceCollect', {
        caseId = caseId,
        reportId = reportId,
        type = evidenceType,
        notes = description,
        location = locationName,
        identifier = sealNumber,
        holderCitizenId = playerData.citizenid,
        createdBy = playerData.citizenid,
        mdtEvidenceId = mdtEvidenceId,
    })

    if autoStore then
        local okStore, storeResult = autoStoreEvidenceInDeposit(src, evidenceId, evidenceNumber, playerData, 'Armazenada automaticamente no momento da coleta.')
        if not okStore then
            return { success = false, error = storeResult or 'Falha ao armazenar evidência no depósito.' }
        end
    end

    return {
        success = true,
        evidenceId = evidenceId,
        evidenceNumber = evidenceNumber,
        sealNumber = sealNumber,
        mdtEvidenceId = mdtEvidenceId,
    }
end)

-- ============================================================
-- LISTAR EVIDÊNCIAS
-- ============================================================
lib.callback.register(resourceName .. ':server:getEvidenceList', function(source, filters)
    local src = source
    if not CheckForensicAuth(src) then return { success = false } end

    filters = filters or {}
    local queryParts = { '1=1' }
    local values = {}

    if filters.scene_id then
        queryParts[#queryParts + 1] = 'scene_id = ?'
        values[#values + 1] = tonumber(filters.scene_id)
    end

    if filters.category and filters.category ~= '' then
        queryParts[#queryParts + 1] = 'category = ?'
        values[#values + 1] = filters.category
    end

    if filters.status and filters.status ~= '' then
        queryParts[#queryParts + 1] = 'status = ?'
        values[#values + 1] = filters.status
    end

    if filters.linked_citizenid and filters.linked_citizenid ~= '' then
        queryParts[#queryParts + 1] = 'linked_citizenid = ?'
        values[#values + 1] = filters.linked_citizenid
    end

    if filters.linked_weapon_serial and filters.linked_weapon_serial ~= '' then
        queryParts[#queryParts + 1] = 'linked_weapon_serial = ?'
        values[#values + 1] = filters.linked_weapon_serial
    end

    if filters.search and filters.search ~= '' then
        queryParts[#queryParts + 1] = '(evidence_number LIKE ? OR description LIKE ? OR type LIKE ? OR seal_number LIKE ?)'
        local like = '%' .. filters.search .. '%'
        values[#values + 1] = like
        values[#values + 1] = like
        values[#values + 1] = like
        values[#values + 1] = like
    end

    local page = tonumber(filters.page) or 1
    local limit = 20
    local offset = (page - 1) * limit
    local where = table.concat(queryParts, ' AND ')

    local total = MySQL.scalar.await(('SELECT COUNT(*) FROM forensic_evidence WHERE %s'):format(where), values)

    local listValues = { table.unpack(values) }
    listValues[#listValues + 1] = limit
    listValues[#listValues + 1] = offset

    local items = MySQL.query.await(([[
        SELECT * FROM forensic_evidence WHERE %s ORDER BY created_at DESC LIMIT ? OFFSET ?
    ]]):format(where), listValues)

    return {
        success = true,
        data = { items = items or {}, total = total or 0, page = page }
    }
end)

-- ============================================================
-- OBTER EVIDÊNCIA ESPECÍFICA
-- ============================================================
lib.callback.register(resourceName .. ':server:getEvidence', function(source, evidenceId)
    local src = source
    if not CheckForensicAuth(src) then return nil end

    evidenceId = tonumber(evidenceId)
    if not evidenceId then return nil end

    local evidence = MySQL.single.await('SELECT * FROM forensic_evidence WHERE id = ?', { evidenceId })
    if not evidence then return nil end

    -- Cadeia de custódia
    evidence.custody = MySQL.query.await(
        'SELECT * FROM forensic_chain_of_custody WHERE evidence_id = ? ORDER BY created_at',
        { evidenceId }
    )

    -- Testes realizados
    evidence.tests = MySQL.query.await(
        'SELECT * FROM forensic_lab_tests WHERE evidence_id = ? ORDER BY created_at',
        { evidenceId }
    )

    -- Digitais vinculadas
    evidence.fingerprints = MySQL.query.await(
        'SELECT * FROM forensic_fingerprints_collected WHERE evidence_id = ?',
        { evidenceId }
    )

    -- DNA vinculado
    evidence.dna_samples = MySQL.query.await(
        'SELECT * FROM forensic_dna_samples WHERE evidence_id = ?',
        { evidenceId }
    )

    -- Balística
    evidence.ballistics = MySQL.query.await(
        'SELECT * FROM forensic_ballistics WHERE evidence_id = ?',
        { evidenceId }
    )

    return evidence
end)

-- ============================================================
-- ATUALIZAR EVIDÊNCIA
-- ============================================================
lib.callback.register(resourceName .. ':server:updateEvidence', function(source, evidenceId, data)
    local src = source
    if not CheckForensicAuth(src) then return { success = false, error = L('scene.errors.not_authorized') } end

    evidenceId = tonumber(evidenceId)
    if not evidenceId then return { success = false, error = L('evidence.errors.invalid_id') } end
    data = data or {}
    local playerData = GetPlayerData(src)
    if not playerData then return { success = false, error = L('scene.errors.player_data_unavailable') } end
    local evidence = MySQL.single.await('SELECT * FROM forensic_evidence WHERE id = ?', { evidenceId })
    if not evidence then return { success = false, error = L('evidence.errors.not_found') } end

    local updates = {}
    local values = {}

    local allowedFields = {
        'status', 'description', 'storage_location', 'priority',
        'linked_citizenid', 'linked_vehicle_plate', 'linked_weapon_serial',
        'case_id', 'report_id',
    }

    for _, field in ipairs(allowedFields) do
        if data[field] ~= nil then
            if field == 'status' and not validEvidenceStatuses[data[field]] then
                return { success = false, error = L('evidence.errors.invalid_status') }
            end
            updates[#updates + 1] = field .. ' = ?'
            values[#values + 1] = data[field]
        end
    end

    if #updates == 0 then
        return { success = false, error = L('evidence.errors.no_update') }
    end

    if data.status and data.status ~= evidence.status then
        local allowed = statusTransitions[evidence.status] or {}
        if not allowed[data.status] then
            return { success = false, error = L('evidence.errors.invalid_status_transition') }
        end
    end

    if data.status == 'armazenada' then
        local okStore, storeResult = autoStoreEvidenceInDeposit(src, evidenceId, evidence.evidence_number, playerData, data.notes)
        if not okStore then
            return { success = false, error = storeResult or 'Falha ao armazenar evidência no depósito.' }
        end
    end

    if (data.status == 'em_analise' or data.status == 'analisada') and (not data.notes or data.notes == '') then
        return { success = false, error = L('evidence.errors.analysis_notes_required') }
    end

    if (data.status == 'devolvida' or data.status == 'descartada') and (not data.notes or data.notes == '') then
        return { success = false, error = L('evidence.errors.final_destination_notes_required') }
    end

    if data.status == 'lacrada' and (not evidence.seal_number or evidence.seal_number == '') then
        local newSeal = generateUniqueSealNumber()
        updates[#updates + 1] = 'seal_number = ?'
        values[#values + 1] = newSeal
        updates[#updates + 1] = 'sealed_at = NOW()'
        evidence.seal_number = newSeal
    end

    updates[#updates + 1] = 'current_holder_citizenid = ?'
    values[#values + 1] = playerData.citizenid
    updates[#updates + 1] = 'current_holder_name = ?'
    values[#values + 1] = playerData.name

    values[#values + 1] = evidenceId
    MySQL.update.await(('UPDATE forensic_evidence SET %s WHERE id = ?'):format(table.concat(updates, ', ')), values)

    -- Registrar mudança de status na cadeia de custódia
    if data.status and data.status ~= 'armazenada' then
        local action = actionByStatus[data.status] or 'transferida'
        local custodyNotes = data.notes or ('Status alterado para: ' .. data.status)
        if evidence.seal_number and evidence.seal_number ~= '' then
            custodyNotes = ('%s | Lacre: %s'):format(custodyNotes, evidence.seal_number)
        end

        recordCustody(
            evidenceId,
            action,
            playerData and playerData.citizenid or nil,
            playerData and playerData.name or nil,
            playerData and playerData.citizenid or nil,
            playerData and playerData.name or nil,
            data.storage_location or '',
            custodyNotes
        )

        syncMDTCustody(
            evidence.mdt_evidence_id,
            playerData and playerData.citizenid or nil,
            playerData and playerData.citizenid or nil,
            action,
            custodyNotes
        )
    end

    ForensicAuditLog(src, 'evidence_updated', 'evidence', evidenceId, data)

    return { success = true }
end)

-- ============================================================
-- CADEIA DE CUSTÓDIA - TRANSFERIR
-- ============================================================
lib.callback.register(resourceName .. ':server:transferEvidence', function(source, evidenceId, toCitizenId, toName, notes)
    local src = source
    if not CheckForensicAuth(src) then return { success = false, error = L('scene.errors.not_authorized') } end
    if not CheckForensicPermission(src, 'canModifyCustody') then
        return { success = false, error = L('evidence.errors.no_permission_transfer') }
    end

    evidenceId = tonumber(evidenceId)
    if not evidenceId then return { success = false, error = L('evidence.errors.invalid_id') } end
    if not toCitizenId or toCitizenId == '' then
        return { success = false, error = L('evidence.errors.target_required') }
    end
    local playerData = GetPlayerData(src)
    if not playerData then return { success = false, error = L('scene.errors.player_data_unavailable') } end
    local evidence = MySQL.single.await('SELECT * FROM forensic_evidence WHERE id = ?', { evidenceId })
    if not evidence then return { success = false, error = L('evidence.errors.not_found') } end
    if evidence.status == 'descartada' or evidence.status == 'devolvida' then
        return { success = false, error = L('evidence.errors.transfer_not_allowed_finalized') }
    end

    local custodyNotes = notes or L('evidence.custody.transfer_default_note')
    if evidence.seal_number and evidence.seal_number ~= '' then
        custodyNotes = ('%s | Lacre: %s'):format(custodyNotes, evidence.seal_number)
    end

    recordCustody(
        evidenceId,
        'transferida',
        playerData and playerData.citizenid or nil,
        playerData and playerData.name or nil,
        toCitizenId,
        toName,
        evidence.storage_location or '',
        custodyNotes
    )

    -- Atualizar no MDT também
    syncMDTCustody(
        evidence.mdt_evidence_id,
        playerData and playerData.citizenid or nil,
        toCitizenId,
        'transferred',
        custodyNotes
    )

    MySQL.update.await(
        'UPDATE forensic_evidence SET status = ?, current_holder_citizenid = ?, current_holder_name = ? WHERE id = ?',
        { 'armazenada', toCitizenId, toName, evidenceId }
    )

    ForensicAuditLog(src, 'evidence_transferred', 'evidence', evidenceId, {
        to = toCitizenId, toName = toName
    })

    return { success = true }
end)

-- ============================================================
-- OBTER CADEIA DE CUSTÓDIA
-- ============================================================
lib.callback.register(resourceName .. ':server:getCustodyChain', function(source, evidenceId)
    local src = source
    if not CheckForensicAuth(src) then return {} end

    evidenceId = tonumber(evidenceId)
    if not evidenceId then return {} end

    return MySQL.query.await(
        'SELECT * FROM forensic_chain_of_custody WHERE evidence_id = ? ORDER BY created_at ASC',
        { evidenceId }
    ) or {}
end)
