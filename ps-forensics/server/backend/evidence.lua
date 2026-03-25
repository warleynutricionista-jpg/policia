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
    eletrônico = 'dispositivo_eletronico',
    objeto = 'outros',
    veiculo = 'veiculo_cena',
    veículo = 'veiculo_cena',
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
    local evidenceType = normalizeEvidenceType(data.type)
    local evidenceEntry = evidenceTypeMap[evidenceType]
    local evidenceCategory = data.category or (evidenceEntry and evidenceEntry.category) or 'outros'
    local subtype = data.subtype and tostring(data.subtype):sub(1, 80) or nil
    local description = data.description and tostring(data.description):sub(1, 1000) or ''
    local locationName = data.location_name and tostring(data.location_name):sub(1, 200) or ''
    local photoUrl = data.photo_url and tostring(data.photo_url):sub(1, 255) or nil

    if not evidenceEntry then
        return { success = false, error = L('evidence.errors.invalid_type') }
    end

    if not evidenceCategoryMap[evidenceCategory] then
        return { success = false, error = L('evidence.errors.invalid_category') }
    end

    if not isValidURL(photoUrl) then
        return { success = false, error = L('evidence.errors.invalid_photo_url') }
    end

    local requiredItem = requiredItemByType[evidenceType] or Config.Items.forensic_kit
    if not hasRequiredItem(src, requiredItem) then
        return { success = false, error = L('evidence.errors.missing_required_item', requiredItem) }
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

    local sealNumber = generateUniqueSealNumber()

    local evidenceId = MySQL.insert.await([[
        INSERT INTO forensic_evidence
        (evidence_number, scene_id, case_id, report_id, category, type, subtype,
         description, collection_location, collection_x, collection_y, collection_z,
         collected_by, collected_by_name, collection_method, seal_number, status,
         photo_url, linked_citizenid, linked_vehicle_plate, linked_weapon_serial, priority)
        VALUES ('', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'coletada', ?, ?, ?, ?, ?)
    ]], {
        sceneId,
        caseId,
        reportId,
        evidenceCategory,
        evidenceType,
        subtype,
        description,
        locationName,
        data.x or 0.0, data.y or 0.0, data.z or 0.0,
        playerData.citizenid,
        playerData.name,
        data.collection_method or 'Manual',
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
        (evidence_id, action, to_citizenid, to_name, location, notes)
        VALUES (?, 'coletada', ?, ?, ?, ?)
    ]], {
        evidenceId,
        playerData.citizenid,
        playerData.name,
        locationName,
        L('evidence.custody.initial_collect', sealNumber),
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

    ForensicAuditLog(src, 'evidence_collected', 'evidence', evidenceId, {
        evidenceNumber = evidenceNumber,
        type = evidenceType,
        category = evidenceCategory,
        sealNumber = sealNumber,
        sceneId = sceneId,
        caseId = caseId,
        reportId = reportId,
        requiredItem = requiredItem,
    })

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
    if not CheckForensicAuth(src) then return { success = false } end

    evidenceId = tonumber(evidenceId)
    if not evidenceId then return { success = false } end

    local updates = {}
    local values = {}

    local allowedFields = {
        'status', 'description', 'storage_location', 'priority',
        'linked_citizenid', 'linked_vehicle_plate', 'linked_weapon_serial',
        'case_id', 'report_id',
    }

    for _, field in ipairs(allowedFields) do
        if data[field] ~= nil then
            updates[#updates + 1] = field .. ' = ?'
            values[#values + 1] = data[field]
        end
    end

    if #updates == 0 then
        return { success = false, error = 'Nenhuma atualização' }
    end

    values[#values + 1] = evidenceId
    MySQL.update.await(('UPDATE forensic_evidence SET %s WHERE id = ?'):format(table.concat(updates, ', ')), values)

    -- Registrar mudança de status na cadeia de custódia
    if data.status then
        local playerData = GetPlayerData(src)
        local actionMap = {
            lacrada = 'lacrada',
            em_analise = 'aberta_analise',
            analisada = 'relacrada',
            armazenada = 'armazenada',
            descartada = 'descartada',
            devolvida = 'devolvida',
            em_julgamento = 'encaminhada_julgamento',
        }

        local action = actionMap[data.status] or 'transferida'
        MySQL.insert.await([[
            INSERT INTO forensic_chain_of_custody
            (evidence_id, action, from_citizenid, from_name, to_citizenid, to_name, location, notes)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ]], {
            evidenceId, action,
            playerData and playerData.citizenid or nil,
            playerData and playerData.name or nil,
            playerData and playerData.citizenid or nil,
            playerData and playerData.name or nil,
            data.storage_location or '',
            data.notes or ('Status alterado para: ' .. data.status),
        })
    end

    ForensicAuditLog(src, 'evidence_updated', 'evidence', evidenceId, data)

    return { success = true }
end)

-- ============================================================
-- CADEIA DE CUSTÓDIA - TRANSFERIR
-- ============================================================
lib.callback.register(resourceName .. ':server:transferEvidence', function(source, evidenceId, toCitizenId, toName, notes)
    local src = source
    if not CheckForensicAuth(src) then return { success = false } end
    if not CheckForensicPermission(src, 'canModifyCustody') then
        return { success = false, error = 'Sem permissão' }
    end

    evidenceId = tonumber(evidenceId)
    local playerData = GetPlayerData(src)

    MySQL.insert.await([[
        INSERT INTO forensic_chain_of_custody
        (evidence_id, action, from_citizenid, from_name, to_citizenid, to_name, notes)
        VALUES (?, 'transferida', ?, ?, ?, ?, ?)
    ]], {
        evidenceId,
        playerData and playerData.citizenid or nil,
        playerData and playerData.name or nil,
        toCitizenId, toName,
        notes or '',
    })

    -- Atualizar no MDT também
    local mdtId = MySQL.scalar.await('SELECT mdt_evidence_id FROM forensic_evidence WHERE id = ?', { evidenceId })
    if mdtId then
        MySQL.update.await('UPDATE mdt_evidence_items SET last_holder = ? WHERE id = ?', { toCitizenId, mdtId })
        MySQL.insert.await([[
            INSERT INTO mdt_evidence_custody (evidence_id, from_citizenid, to_citizenid, action, notes)
            VALUES (?, ?, ?, 'transferred', ?)
        ]], { mdtId, playerData and playerData.citizenid, toCitizenId, notes or '' })
    end

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
