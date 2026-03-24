-- ============================================================
-- PS-FORENSICS - Módulo: Medicina Legal / Necropsia (Server)
-- ============================================================

local resourceName = GetCurrentResourceName()

-- ============================================================
-- CRIAR EXAME CADAVÉRICO / NECROPSIA
-- ============================================================
lib.callback.register(resourceName .. ':server:createAutopsy', function(source, data)
    local src = source
    if not CheckForensicAuth(src) then return { success = false } end
    if not CheckForensicPermission(src, 'canPerformAutopsy') then
        return { success = false, error = 'Apenas legistas podem realizar exames cadavéricos' }
    end

    local playerData = GetPlayerData(src)

    local autopsyId = MySQL.insert.await([[
        INSERT INTO forensic_autopsy
        (scene_id, case_id, report_id, victim_citizenid, victim_name, victim_status,
         cause_of_death, manner_of_death, estimated_time_of_death,
         body_temperature, rigor_mortis, livor_mortis,
         trauma_description, wounds_count, wounds_description,
         clothing_description, personal_effects,
         external_exam_notes, examiner_citizenid, examiner_name,
         exam_start, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), 'em_andamento')
    ]], {
        data.scene_id and tonumber(data.scene_id) or nil,
        data.case_id and tonumber(data.case_id) or nil,
        data.report_id and tonumber(data.report_id) or nil,
        data.victim_citizenid or nil,
        data.victim_name or 'Desconhecido',
        data.victim_status or 'nao_identificado',
        data.cause_of_death or 'indeterminado',
        data.manner_of_death or 'indeterminado',
        data.estimated_time_of_death or nil,
        data.body_temperature or nil,
        data.rigor_mortis or nil,
        data.livor_mortis or nil,
        data.trauma_description or '',
        data.wounds_count or 0,
        data.wounds_description or '',
        data.clothing_description or '',
        data.personal_effects or '',
        data.external_exam_notes or '',
        playerData.citizenid,
        playerData.name,
    })

    ForensicAuditLog(src, 'autopsy_created', 'autopsy', autopsyId, {
        victimName = data.victim_name,
        causeOfDeath = data.cause_of_death,
    })

    return { success = true, id = autopsyId }
end)

-- ============================================================
-- ATUALIZAR NECROPSIA
-- ============================================================
lib.callback.register(resourceName .. ':server:updateAutopsy', function(source, autopsyId, data)
    local src = source
    if not CheckForensicAuth(src) then return { success = false } end
    if not CheckForensicPermission(src, 'canPerformAutopsy') then
        return { success = false, error = 'Sem permissão' }
    end

    autopsyId = tonumber(autopsyId)
    if not autopsyId then return { success = false } end

    local updates = {}
    local values = {}

    local allowedFields = {
        'victim_citizenid', 'victim_name', 'victim_status',
        'cause_of_death', 'manner_of_death', 'estimated_time_of_death',
        'body_temperature', 'rigor_mortis', 'livor_mortis',
        'trauma_description', 'wounds_count', 'wounds_description',
        'toxicology_result', 'substances_found',
        'dna_collected', 'fingerprints_collected',
        'clothing_description', 'personal_effects',
        'external_exam_notes', 'internal_exam_notes',
        'conclusion', 'status',
    }

    for _, field in ipairs(allowedFields) do
        if data[field] ~= nil then
            updates[#updates + 1] = field .. ' = ?'
            if field == 'dna_collected' or field == 'fingerprints_collected' then
                values[#values + 1] = data[field] and 1 or 0
            elseif field == 'substances_found' and type(data[field]) == 'table' then
                values[#values + 1] = json.encode(data[field])
            else
                values[#values + 1] = data[field]
            end
        end
    end

    if data.status == 'concluido' then
        updates[#updates + 1] = 'exam_end = NOW()'
    end

    if #updates == 0 then
        return { success = false, error = 'Nenhuma atualização' }
    end

    values[#values + 1] = autopsyId
    MySQL.update.await(('UPDATE forensic_autopsy SET %s WHERE id = ?'):format(table.concat(updates, ', ')), values)

    ForensicAuditLog(src, 'autopsy_updated', 'autopsy', autopsyId, data)

    return { success = true }
end)

-- ============================================================
-- OBTER NECROPSIA
-- ============================================================
lib.callback.register(resourceName .. ':server:getAutopsy', function(source, autopsyId)
    local src = source
    if not CheckForensicAuth(src) then return nil end

    autopsyId = tonumber(autopsyId)
    if not autopsyId then return nil end

    return MySQL.single.await('SELECT * FROM forensic_autopsy WHERE id = ?', { autopsyId })
end)

-- ============================================================
-- LISTAR NECROPSIAS
-- ============================================================
lib.callback.register(resourceName .. ':server:getAutopsies', function(source, filters)
    local src = source
    if not CheckForensicAuth(src) then return { success = false } end

    filters = filters or {}
    local queryParts = { '1=1' }
    local values = {}

    if filters.scene_id then
        queryParts[#queryParts + 1] = 'scene_id = ?'
        values[#values + 1] = tonumber(filters.scene_id)
    end

    if filters.status and filters.status ~= '' then
        queryParts[#queryParts + 1] = 'status = ?'
        values[#values + 1] = filters.status
    end

    if filters.cause_of_death and filters.cause_of_death ~= '' then
        queryParts[#queryParts + 1] = 'cause_of_death = ?'
        values[#values + 1] = filters.cause_of_death
    end

    if filters.victim_citizenid and filters.victim_citizenid ~= '' then
        queryParts[#queryParts + 1] = 'victim_citizenid = ?'
        values[#values + 1] = filters.victim_citizenid
    end

    local where = table.concat(queryParts, ' AND ')
    local items = MySQL.query.await(('SELECT * FROM forensic_autopsy WHERE %s ORDER BY created_at DESC LIMIT 50'):format(where), values)

    return { success = true, data = items or {} }
end)

-- ============================================================
-- EXAME TOXICOLÓGICO (vinculado à necropsia)
-- ============================================================
lib.callback.register(resourceName .. ':server:performToxicology', function(source, autopsyId)
    local src = source
    if not CheckForensicAuth(src) then return { success = false } end

    autopsyId = tonumber(autopsyId)
    local autopsy = MySQL.single.await('SELECT * FROM forensic_autopsy WHERE id = ?', { autopsyId })
    if not autopsy then return { success = false, error = 'Necropsia não encontrada' } end

    local playerData = GetPlayerData(src)

    -- Simular resultado toxicológico
    local substances = {}
    if math.random() < 0.4 then substances[#substances + 1] = { name = 'Álcool Etílico', level = ('%.1f dg/L'):format(math.random(1, 40) / 10) } end
    if math.random() < 0.25 then substances[#substances + 1] = { name = 'Cocaína/Benzoilecgonina', level = 'Positivo' } end
    if math.random() < 0.15 then substances[#substances + 1] = { name = 'THC', level = 'Positivo' } end
    if math.random() < 0.10 then substances[#substances + 1] = { name = 'Benzodiazepínicos', level = 'Positivo' } end
    if math.random() < 0.05 then substances[#substances + 1] = { name = 'Opioides', level = 'Positivo' } end

    local resultText = 'Nenhuma substância detectada.'
    if #substances > 0 then
        local parts = {}
        for _, s in ipairs(substances) do
            parts[#parts + 1] = ('%s: %s'):format(s.name, s.level)
        end
        resultText = 'Substâncias detectadas: ' .. table.concat(parts, ' | ')
    end

    MySQL.update.await([[
        UPDATE forensic_autopsy
        SET toxicology_result = ?, substances_found = ?
        WHERE id = ?
    ]], { resultText, json.encode(substances), autopsyId })

    -- Registrar como teste laboratorial
    MySQL.insert.await([[
        INSERT INTO forensic_lab_tests
        (evidence_id, scene_id, test_type, test_name, result_level, result_details,
         target_citizenid, target_name, requested_by, requested_by_name,
         performed_by, performed_by_name, started_at, completed_at, status)
        VALUES (NULL, ?, 'toxicologico', 'Exame Toxicológico Post-Mortem', ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW(), 'concluido')
    ]], {
        autopsy.scene_id,
        #substances > 0 and 'confirmado' or 'negativo',
        resultText,
        autopsy.victim_citizenid, autopsy.victim_name,
        playerData.citizenid, playerData.name,
        playerData.citizenid, playerData.name,
    })

    ForensicAuditLog(src, 'toxicology_performed', 'autopsy', autopsyId, {
        substances = substances,
    })

    return {
        success = true,
        result = resultText,
        substances = substances,
    }
end)
