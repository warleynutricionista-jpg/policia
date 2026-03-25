-- ============================================================
-- PS-FORENSICS - Módulo: Cena de Crime (Server)
-- ============================================================

local resourceName = GetCurrentResourceName()
local validStatuses = {}

for _, status in ipairs((Config.Enums and Config.Enums.SceneStatus) or { 'aberta', 'isolada', 'em_processamento', 'finalizada', 'reaberta' }) do
    validStatuses[status] = true
end

local statusTransitions = {
    aberta = { isolada = true, em_processamento = true, finalizada = true },
    isolada = { em_processamento = true, finalizada = true, reaberta = true },
    em_processamento = { finalizada = true, isolada = true, reaberta = true },
    finalizada = { reaberta = true },
    reaberta = { isolada = true, em_processamento = true, finalizada = true },
}

local function isValidClassification(classification)
    if not classification then return false end
    for _, item in ipairs(Config.SceneClassifications or {}) do
        if item.value == classification then
            return true
        end
    end
    return false
end

local function ensureScenePersonnel(sceneId, playerData, role, notes)
    if not sceneId or not playerData then return end
    local exists = MySQL.scalar.await(
        'SELECT COUNT(*) FROM forensic_scene_personnel WHERE scene_id = ? AND citizenid = ?',
        { sceneId, playerData.citizenid }
    )
    if exists and exists > 0 then return end

    MySQL.insert.await([[
        INSERT INTO forensic_scene_personnel (scene_id, citizenid, name, role, arrival_time, notes)
        VALUES (?, ?, ?, ?, NOW(), ?)
    ]], { sceneId, playerData.citizenid, playerData.name, role or 'investigador', notes or '' })
end

-- ============================================================
-- CRIAR CENA DE CRIME
-- ============================================================
lib.callback.register(resourceName .. ':server:createScene', function(source, data)
    local src = source
    if not CheckForensicAuth(src) then return { success = false, error = L('scene.errors.not_authorized') } end
    if not CheckForensicPermission(src, 'canCreateScene') then
        return { success = false, error = L('scene.errors.no_permission_create') }
    end

    local playerData = GetPlayerData(src)
    if not playerData then return { success = false, error = L('scene.errors.player_data_unavailable') } end
    if not isValidClassification(data.classification or 'outros') then
        return { success = false, error = L('scene.errors.invalid_classification') }
    end

    local caseId = data.case_id and tonumber(data.case_id) or nil
    local reportId = data.report_id and tonumber(data.report_id) or nil

    local sceneId = MySQL.insert.await([[
        INSERT INTO forensic_crime_scenes
        (scene_number, classification, status, location_name, location_x, location_y, location_z,
         perimeter_radius, description, weather_conditions, lighting_conditions,
         arrival_time, created_by, created_by_name, department, case_id, report_id)
        VALUES ('', ?, 'aberta', ?, ?, ?, ?, ?, ?, ?, ?, NOW(), ?, ?, ?, ?, ?)
    ]], {
        data.classification or 'outros',
        data.location_name or L('scene.unknown_location'),
        data.x or 0.0, data.y or 0.0, data.z or 0.0,
        data.perimeter_radius or 50.0,
        data.description or '',
        data.weather or '',
        data.lighting or '',
        playerData.citizenid,
        playerData.name,
        playerData.job,
        caseId,
        reportId,
    })

    if not sceneId then
        return { success = false, error = L('scene.errors.create_failed') }
    end

    -- Gerar número da cena
    local sceneNumber = ForensicUtils.GenerateSceneNumber(sceneId)
    MySQL.update.await('UPDATE forensic_crime_scenes SET scene_number = ? WHERE id = ?', { sceneNumber, sceneId })

    -- Adicionar criador como primeiro respondente
    ensureScenePersonnel(sceneId, playerData, 'primeiro_respondente', L('scene.logs.creator_first_responder'))

    ForensicAuditLog(src, 'scene_created', 'scene', sceneId, {
        sceneNumber = sceneNumber,
        classification = data.classification,
        caseId = caseId,
        reportId = reportId,
        location = data.location_name or '',
    })

    -- Notificar todos os policiais online
    TriggerClientEvent(resourceName .. ':client:sceneCreated', -1, {
        id = sceneId,
        sceneNumber = sceneNumber,
        classification = data.classification,
        x = data.x, y = data.y, z = data.z,
        status = 'aberta',
        createdBy = playerData.name,
    })

    return {
        success = true,
        sceneId = sceneId,
        sceneNumber = sceneNumber,
    }
end)

-- ============================================================
-- ATUALIZAR CENA
-- ============================================================
lib.callback.register(resourceName .. ':server:updateScene', function(source, sceneId, data)
    local src = source
    if not CheckForensicAuth(src) then return { success = false, error = L('scene.errors.not_authorized') } end
    if not CheckForensicPermission(src, 'canCreateScene') then
        return { success = false, error = L('scene.errors.no_permission_update') }
    end

    sceneId = tonumber(sceneId)
    if not sceneId then return { success = false, error = L('scene.errors.invalid_id') } end

    local playerData = GetPlayerData(src)
    if not playerData then return { success = false, error = L('scene.errors.player_data_unavailable') } end

    local currentScene = MySQL.single.await('SELECT * FROM forensic_crime_scenes WHERE id = ?', { sceneId })
    if not currentScene then return { success = false, error = L('scene.errors.not_found') } end

    ensureScenePersonnel(sceneId, playerData, 'investigador', L('scene.logs.auto_linked_personnel'))

    local updates = {}
    local values = {}

    local fields = {
        'classification', 'status', 'description', 'weather_conditions',
        'lighting_conditions', 'perimeter_radius', 'location_name'
    }

    for _, field in ipairs(fields) do
        if data[field] ~= nil then
            if field == 'classification' and not isValidClassification(data[field]) then
                return { success = false, error = L('scene.errors.invalid_classification') }
            end
            updates[#updates + 1] = field .. ' = ?'
            values[#values + 1] = data[field]
        end
    end

    if data.status ~= nil then
        if not validStatuses[data.status] then
            return { success = false, error = L('scene.errors.invalid_status') }
        end

        local transition = statusTransitions[currentScene.status] or {}
        if currentScene.status ~= data.status and not transition[data.status] then
            return { success = false, error = L('scene.errors.invalid_transition') }
        end

        if data.status == 'finalizada' or data.status == 'reaberta' then
            if not CheckForensicPermission(src, 'canFinalizeReport') then
                return { success = false, error = L('scene.errors.no_permission_finalize') }
            end
        end

        if data.status == 'em_processamento' and not currentScene.processing_start and not data.skip_processing_start then
            updates[#updates + 1] = 'processing_start = NOW()'
        end

        if data.status == 'finalizada' then
            updates[#updates + 1] = 'processing_end = NOW()'
        elseif data.status == 'reaberta' then
            updates[#updates + 1] = 'processing_end = NULL'
        end
    end

    local caseId = data.case_id and tonumber(data.case_id) or nil
    if data.case_id ~= nil then
        updates[#updates + 1] = 'case_id = ?'
        values[#values + 1] = caseId
    end

    local reportId = data.report_id and tonumber(data.report_id) or nil
    if data.report_id ~= nil then
        updates[#updates + 1] = 'report_id = ?'
        values[#values + 1] = reportId
    end

    if #updates == 0 then
        return { success = false, error = L('scene.errors.no_update') }
    end

    values[#values + 1] = sceneId
    MySQL.update.await(('UPDATE forensic_crime_scenes SET %s WHERE id = ?'):format(table.concat(updates, ', ')), values)

    if data.case_id ~= nil then
        MySQL.update.await([[
            UPDATE forensic_evidence
            SET case_id = ?
            WHERE scene_id = ? AND (case_id IS NULL OR case_id = ?)
        ]], { caseId, sceneId, currentScene.case_id })
    end

    if data.report_id ~= nil then
        MySQL.update.await([[
            UPDATE forensic_evidence
            SET report_id = ?
            WHERE scene_id = ? AND (report_id IS NULL OR report_id = ?)
        ]], { reportId, sceneId, currentScene.report_id })
    end

    local auditData = data
    if data.status then
        auditData = {
            previousStatus = currentScene.status,
            newStatus = data.status,
            case_id = caseId,
            report_id = reportId,
        }
    end

    ForensicAuditLog(src, 'scene_updated', 'scene', sceneId, auditData)

    TriggerClientEvent(resourceName .. ':client:sceneUpdated', -1, sceneId, data)

    return { success = true }
end)

-- ============================================================
-- LISTAR CENAS
-- ============================================================
lib.callback.register(resourceName .. ':server:getScenes', function(source, filters)
    local src = source
    if not CheckForensicAuth(src) then return { success = false } end

    filters = filters or {}
    local queryParts = { '1=1' }
    local values = {}

    if filters.status and filters.status ~= '' then
        queryParts[#queryParts + 1] = 'status = ?'
        values[#values + 1] = filters.status
    end

    if filters.classification and filters.classification ~= '' then
        queryParts[#queryParts + 1] = 'classification = ?'
        values[#values + 1] = filters.classification
    end

    if filters.search and filters.search ~= '' then
        queryParts[#queryParts + 1] = '(scene_number LIKE ? OR description LIKE ? OR location_name LIKE ?)'
        local like = '%' .. filters.search .. '%'
        values[#values + 1] = like
        values[#values + 1] = like
        values[#values + 1] = like
    end

    local page = tonumber(filters.page) or 1
    local limit = tonumber(filters.limit) or 20
    local offset = (page - 1) * limit

    local where = table.concat(queryParts, ' AND ')

    local total = MySQL.scalar.await(('SELECT COUNT(*) FROM forensic_crime_scenes WHERE %s'):format(where), values)

    local listValues = { table.unpack(values) }
    listValues[#listValues + 1] = limit
    listValues[#listValues + 1] = offset

    local scenes = MySQL.query.await(([[
        SELECT * FROM forensic_crime_scenes WHERE %s ORDER BY created_at DESC LIMIT ? OFFSET ?
    ]]):format(where), listValues)

    return {
        success = true,
        data = {
            items = scenes or {},
            total = total or 0,
            page = page,
        }
    }
end)

-- ============================================================
-- OBTER CENA ESPECÍFICA
-- ============================================================
lib.callback.register(resourceName .. ':server:getScene', function(source, sceneId)
    local src = source
    if not CheckForensicAuth(src) then return nil end

    sceneId = tonumber(sceneId)
    if not sceneId then return nil end

    local scene = MySQL.single.await('SELECT * FROM forensic_crime_scenes WHERE id = ?', { sceneId })
    if not scene then return nil end

    -- Obter equipe
    scene.personnel = MySQL.query.await('SELECT * FROM forensic_scene_personnel WHERE scene_id = ? ORDER BY arrival_time', { sceneId })

    -- Obter evidências da cena
    scene.evidence_count = MySQL.scalar.await('SELECT COUNT(*) FROM forensic_evidence WHERE scene_id = ?', { sceneId })

    -- Obter fotos
    scene.photos = MySQL.query.await('SELECT * FROM forensic_scene_photos WHERE scene_id = ? ORDER BY taken_at', { sceneId })

    return scene
end)

-- ============================================================
-- ADICIONAR PESSOAL À CENA
-- ============================================================
lib.callback.register(resourceName .. ':server:addScenePersonnel', function(source, sceneId, data)
    local src = source
    if not CheckForensicAuth(src) then return { success = false, error = L('scene.errors.not_authorized') } end

    sceneId = tonumber(sceneId)
    local playerData = GetPlayerData(src)
    if not sceneId then return { success = false, error = L('scene.errors.invalid_id') } end
    if not playerData then return { success = false, error = L('scene.errors.player_data_unavailable') } end

    local citizenid = data.citizenid or playerData.citizenid
    local name = data.name or playerData.name
    local role = data.role or 'investigador'

    -- Verificar duplicata
    local existing = MySQL.scalar.await(
        'SELECT COUNT(*) FROM forensic_scene_personnel WHERE scene_id = ? AND citizenid = ?',
        { sceneId, citizenid }
    )
    if existing and existing > 0 then
        return { success = false, error = L('scene.errors.personnel_already_registered') }
    end

    MySQL.insert.await([[
        INSERT INTO forensic_scene_personnel (scene_id, citizenid, name, role, arrival_time, notes)
        VALUES (?, ?, ?, ?, NOW(), ?)
    ]], { sceneId, citizenid, name, role, data.notes or '' })

    ForensicAuditLog(src, 'personnel_added', 'scene', sceneId, { citizenid = citizenid, role = role })

    return { success = true }
end)

-- ============================================================
-- ADICIONAR FOTO À CENA
-- ============================================================
lib.callback.register(resourceName .. ':server:addScenePhoto', function(source, sceneId, photoData)
    local src = source
    if not CheckForensicAuth(src) then return { success = false, error = L('scene.errors.not_authorized') } end

    sceneId = tonumber(sceneId)
    if not sceneId then return { success = false, error = L('scene.errors.invalid_id') } end
    if not photoData or not photoData.url or photoData.url == '' then
        return { success = false, error = L('scene.errors.photo_url_required') }
    end

    local playerData = GetPlayerData(src)

    local photoId = MySQL.insert.await([[
        INSERT INTO forensic_scene_photos (scene_id, url, label, taken_by)
        VALUES (?, ?, ?, ?)
    ]], { sceneId, photoData.url, photoData.label or '', playerData and playerData.citizenid or '' })

    return { success = true, id = photoId }
end)
