-- ============================================================
-- PS-FORENSICS - Módulo: Medicina Legal / Necropsia (Server)
-- ============================================================

local resourceName = GetCurrentResourceName()

local validVictimStatus = {
    identificado = true,
    nao_identificado = true,
    parcialmente_identificado = true,
}

local validCauseOfDeath = {
    arma_de_fogo = true,
    arma_branca = true,
    trauma_contundente = true,
    asfixia = true,
    queimadura = true,
    overdose = true,
    envenenamento = true,
    afogamento = true,
    eletrocussao = true,
    multiplos_ferimentos = true,
    causa_natural = true,
    indeterminado = true,
}

local validMannerOfDeath = {
    homicidio = true,
    suicidio = true,
    acidente = true,
    natural = true,
    indeterminado = true,
}

local validRigorMortis = {
    ausente = true,
    inicial = true,
    completo = true,
    resolvendo = true,
}

local function hasRequiredItem(src, itemName)
    if not itemName then return true end
    if GetResourceState('ox_inventory') ~= 'started' then return true end
    return (exports.ox_inventory:GetItemCount(src, itemName) or 0) > 0
end

local function parseTimestamp(value)
    if not value then return nil end
    if type(value) == 'number' then return value end
    if type(value) ~= 'string' then return nil end
    local y, mo, d, h, mi, s = value:match('^(%d+)%-(%d+)%-(%d+)[ T](%d+):(%d+):?(%d*)')
    if not y then return nil end
    return os.time({
        year = tonumber(y),
        month = tonumber(mo),
        day = tonumber(d),
        hour = tonumber(h),
        min = tonumber(mi),
        sec = tonumber(s) or 0
    })
end

local function inferEstimatedTimeOfDeath(bodyTemperature, rigor)
    local temp = tonumber(bodyTemperature)
    if temp and temp > 0 and temp <= 42 then
        local loss = 37.0 - temp
        if loss < 0 then loss = 0 end
        local hours = math.floor((loss / 0.83) + 0.5)
        return os.time() - (hours * 3600)
    end

    if rigor == 'inicial' then
        return os.time() - (3 * 3600)
    elseif rigor == 'completo' then
        return os.time() - (10 * 3600)
    elseif rigor == 'resolvendo' then
        return os.time() - (26 * 3600)
    end
    return nil
end

-- ============================================================
-- CRIAR EXAME CADAVÉRICO / NECROPSIA
-- ============================================================
lib.callback.register(resourceName .. ':server:createAutopsy', function(source, data)
    local src = source
    if not CheckForensicAuth(src) then return { success = false, error = L('autopsy.errors.not_authorized') } end
    if not CheckForensicPermission(src, 'canPerformAutopsy') then
        return { success = false, error = L('autopsy.errors.no_permission') }
    end

    local playerData = GetPlayerData(src)
    if not playerData then return { success = false, error = L('scene.errors.player_data_unavailable') } end
    data = data or {}
    local actionValidation = ValidateAndConsumeForensicAction(src, 'autopsy_exam')
    if not actionValidation.success then
        return { success = false, error = actionValidation.error }
    end

    local sceneId = data.scene_id and tonumber(data.scene_id) or nil
    local caseId = data.case_id and tonumber(data.case_id) or nil
    local reportId = data.report_id and tonumber(data.report_id) or nil
    local victimStatus = validVictimStatus[data.victim_status or 'nao_identificado'] and data.victim_status or 'nao_identificado'
    local causeOfDeath = validCauseOfDeath[data.cause_of_death or 'indeterminado'] and data.cause_of_death or 'indeterminado'
    local mannerOfDeath = validMannerOfDeath[data.manner_of_death or 'indeterminado'] and data.manner_of_death or 'indeterminado'
    local rigor = data.rigor_mortis and (validRigorMortis[data.rigor_mortis] and data.rigor_mortis or nil) or nil
    local estimatedTime = parseTimestamp(data.estimated_time_of_death) or inferEstimatedTimeOfDeath(data.body_temperature, rigor)
    local estimatedTimeSql = estimatedTime and os.date('%Y-%m-%d %H:%M:%S', estimatedTime) or nil
    local traumaType = data.trauma_type and tostring(data.trauma_type):sub(1, 50) or nil
    local traumaDescription = data.trauma_description and tostring(data.trauma_description):sub(1, 1000) or ''

    if sceneId then
        local scene = MySQL.single.await('SELECT id, case_id, report_id FROM forensic_crime_scenes WHERE id = ?', { sceneId })
        if not scene then
            return { success = false, error = L('scene.errors.not_found') }
        end
        if not caseId and scene.case_id then caseId = scene.case_id end
        if not reportId and scene.report_id then reportId = scene.report_id end
    end

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
        sceneId,
        caseId,
        reportId,
        data.victim_citizenid or nil,
        data.victim_name or L('labels.unknown'),
        victimStatus,
        causeOfDeath,
        mannerOfDeath,
        estimatedTimeSql,
        data.body_temperature or nil,
        rigor,
        data.livor_mortis or nil,
        traumaType and (('%s: %s'):format(traumaType, traumaDescription)) or traumaDescription,
        data.wounds_count or 0,
        data.wounds_description or '',
        data.clothing_description or '',
        data.personal_effects or '',
        data.external_exam_notes or '',
        playerData.citizenid,
        playerData.name,
    })

    if not autopsyId then
        return { success = false, error = L('autopsy.errors.create_failed') }
    end

    if caseId then
        MySQL.insert.await([[
            INSERT INTO forensic_cross_references
            (source_type, source_id, target_type, target_id, relationship, confidence, created_by, notes)
            VALUES ('autopsy', ?, 'case', ?, 'necropsia_vinculada', 'alta', ?, ?)
        ]], { autopsyId, tostring(caseId), playerData.citizenid, ('Necropsia vinculada ao caso %s'):format(caseId) })
    end

    if reportId then
        MySQL.insert.await([[
            INSERT INTO forensic_cross_references
            (source_type, source_id, target_type, target_id, relationship, confidence, created_by, notes)
            VALUES ('autopsy', ?, 'report', ?, 'necropsia_vinculada', 'alta', ?, ?)
        ]], { autopsyId, tostring(reportId), playerData.citizenid, ('Necropsia vinculada ao relatório %s'):format(reportId) })
    end

    ForensicAuditLog(src, 'autopsy_created', 'autopsy', autopsyId, {
        victimName = data.victim_name,
        causeOfDeath = causeOfDeath,
        caseId = caseId,
        reportId = reportId,
        estimatedTime = estimatedTimeSql,
        usedItems = actionValidation.usedItems,
    })

    return { success = true, id = autopsyId }
end)

-- ============================================================
-- ATUALIZAR NECROPSIA
-- ============================================================
lib.callback.register(resourceName .. ':server:updateAutopsy', function(source, autopsyId, data)
    local src = source
    if not CheckForensicAuth(src) then return { success = false, error = L('autopsy.errors.not_authorized') } end
    if not CheckForensicPermission(src, 'canPerformAutopsy') then
        return { success = false, error = L('autopsy.errors.no_permission') }
    end

    autopsyId = tonumber(autopsyId)
    if not autopsyId then return { success = false, error = L('autopsy.errors.invalid_id') } end
    data = data or {}
    local playerData = GetPlayerData(src)
    if not playerData then return { success = false, error = L('scene.errors.player_data_unavailable') } end
    local autopsy = MySQL.single.await('SELECT * FROM forensic_autopsy WHERE id = ?', { autopsyId })
    if not autopsy then return { success = false, error = L('autopsy.errors.not_found') } end

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
            elseif field == 'cause_of_death' then
                values[#values + 1] = validCauseOfDeath[data[field]] and data[field] or 'indeterminado'
            elseif field == 'manner_of_death' then
                values[#values + 1] = validMannerOfDeath[data[field]] and data[field] or 'indeterminado'
            elseif field == 'victim_status' then
                values[#values + 1] = validVictimStatus[data[field]] and data[field] or 'nao_identificado'
            elseif field == 'rigor_mortis' then
                values[#values + 1] = validRigorMortis[data[field]] and data[field] or nil
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
        return { success = false, error = L('autopsy.errors.no_update') }
    end

    values[#values + 1] = autopsyId
    MySQL.update.await(('UPDATE forensic_autopsy SET %s WHERE id = ?'):format(table.concat(updates, ', ')), values)

    if data.dna_collected and autopsy.dna_collected ~= 1 then
        local requiredItem = Config.Items.dna_swab
        if hasRequiredItem(src, requiredItem) then
            local sampleHash = ForensicUtils.GenerateDNAHash(autopsy.victim_citizenid or ('autopsy-' .. autopsyId))
            MySQL.insert.await([[
                INSERT INTO forensic_dna_samples
                (evidence_id, scene_id, source_type, source_description, dna_hash,
                 match_status, collected_by, collected_by_name, notes)
                VALUES (NULL, ?, 'corpo_vitima', ?, ?, 'pendente', ?, ?, ?)
            ]], {
                autopsy.scene_id,
                ('Coleta em cadáver - Necropsia #%d'):format(autopsyId),
                sampleHash,
                playerData.citizenid,
                playerData.name,
                ('Coleta de DNA vinculada à necropsia #%d'):format(autopsyId),
            })
        end
    end

    if data.fingerprints_collected and autopsy.fingerprints_collected ~= 1 then
        local requiredItem = Config.Items.fingerprint_kit
        if hasRequiredItem(src, requiredItem) then
            local fpHash = ForensicUtils.GenerateFingerprintHash(autopsy.victim_citizenid or ('autopsy-' .. autopsyId))
            MySQL.insert.await([[
                INSERT INTO forensic_fingerprints_collected
                (evidence_id, scene_id, source_description, source_type, fingerprint_hash, quality,
                 match_status, collected_by, collected_by_name, notes)
                VALUES (NULL, ?, ?, 'corpo', ?, 'boa', 'pendente', ?, ?, ?)
            ]], {
                autopsy.scene_id,
                ('Coleta em cadáver - Necropsia #%d'):format(autopsyId),
                fpHash,
                playerData.citizenid,
                playerData.name,
                ('Coleta de digitais vinculada à necropsia #%d'):format(autopsyId),
            })
        end
    end

    if data.status == 'concluido' then
        local conclusion = data.conclusion or autopsy.conclusion or L('autopsy.defaults.no_conclusion')
        local body = ([[
Exame cadavérico concluído.
Vítima: %s (%s)
Causa da morte: %s
Maneira da morte: %s
Horário provável da morte: %s
Trauma: %s
Lesões: %s
Toxicologia: %s
DNA coletado: %s | Digitais coletadas: %s
Conclusão médico-legal: %s
        ]]):format(
            data.victim_name or autopsy.victim_name or L('labels.unknown'),
            data.victim_citizenid or autopsy.victim_citizenid or L('labels.unknown'),
            ForensicUtils.GetCauseOfDeathLabel(data.cause_of_death or autopsy.cause_of_death),
            data.manner_of_death or autopsy.manner_of_death or L('labels.unknown'),
            data.estimated_time_of_death or autopsy.estimated_time_of_death or L('labels.na'),
            data.trauma_description or autopsy.trauma_description or L('labels.na'),
            data.wounds_description or autopsy.wounds_description or L('labels.na'),
            data.toxicology_result or autopsy.toxicology_result or L('labels.na'),
            (data.dna_collected or autopsy.dna_collected == 1) and 'SIM' or 'NÃO',
            (data.fingerprints_collected or autopsy.fingerprints_collected == 1) and 'SIM' or 'NÃO',
            conclusion
        )

        local reportType = 'laudo_necropsia'
        local reportId = MySQL.insert.await([[
            INSERT INTO forensic_reports
            (report_number, scene_id, case_id, mdt_report_id, type, title, summary, body, conclusion,
             linked_citizenids, author_citizenid, author_name, author_role, status, finalized_at)
            VALUES ('', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'finalizado', NOW())
        ]], {
            autopsy.scene_id,
            autopsy.case_id,
            autopsy.report_id,
            reportType,
            ('Laudo Médico-Legal - Necropsia #%d'):format(autopsyId),
            ('Conclusão preliminar: %s'):format(conclusion),
            body,
            conclusion,
            autopsy.victim_citizenid and json.encode({ autopsy.victim_citizenid }) or nil,
            playerData.citizenid,
            playerData.name,
            GetPlayerRole(src) or 'legista',
        })

        if reportId then
            local reportNumber = ForensicUtils.GenerateReportNumber(reportId)
            MySQL.update.await('UPDATE forensic_reports SET report_number = ? WHERE id = ?', { reportNumber, reportId })
        end
    end

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
    if not CheckForensicAuth(src) then return { success = false, error = L('autopsy.errors.not_authorized') } end
    if not CheckForensicPermission(src, 'canPerformAutopsy') then
        return { success = false, error = L('autopsy.errors.no_permission') }
    end

    autopsyId = tonumber(autopsyId)
    if not autopsyId then return { success = false, error = L('autopsy.errors.invalid_id') } end
    local autopsy = MySQL.single.await('SELECT * FROM forensic_autopsy WHERE id = ?', { autopsyId })
    if not autopsy then return { success = false, error = L('autopsy.errors.not_found') } end

    local playerData = GetPlayerData(src)
    if not playerData then return { success = false, error = L('scene.errors.player_data_unavailable') } end

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
