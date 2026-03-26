-- ============================================================
-- PS-FORENSICS - Módulo: Laudos Técnicos (Server)
-- ============================================================

local resourceName = GetCurrentResourceName()

local function normalizeIdList(list)
    if type(list) ~= 'table' then return {} end
    local out, seen = {}, {}
    for _, value in ipairs(list) do
        local n = tonumber(value)
        if n and n > 0 and not seen[n] then
            seen[n] = true
            out[#out + 1] = n
        end
    end
    return out
end

local function upsertCrossRef(sourceId, targetType, targetId, relationship, actorCitizenId, notes)
    if not sourceId or not targetType or not targetId then return end
    local existing = MySQL.scalar.await([[
        SELECT id FROM forensic_cross_references
        WHERE source_type = 'report' AND source_id = ? AND target_type = ? AND target_id = ?
        LIMIT 1
    ]], { sourceId, targetType, tostring(targetId) })
    if existing then return end

    MySQL.insert.await([[
        INSERT INTO forensic_cross_references
        (source_type, source_id, target_type, target_id, relationship, confidence, created_by, notes)
        VALUES ('report', ?, ?, ?, ?, 'alta', ?, ?)
    ]], { sourceId, targetType, tostring(targetId), relationship, actorCitizenId, notes or '' })
end

local function syncReportLinks(reportId, payload, actorCitizenId)
    if not reportId then return end
    local report = MySQL.single.await('SELECT id, scene_id, case_id, mdt_report_id, report_number FROM forensic_reports WHERE id = ?', { reportId })
    if not report then return end

    local evidenceIds = normalizeIdList(payload.evidence_ids)
    if #evidenceIds > 0 then
        local placeholders = table.concat((function()
            local t = {}
            for _ = 1, #evidenceIds do t[#t + 1] = '?' end
            return t
        end)(), ',')
        local params = { report.case_id, report.mdt_report_id, reportId }
        for _, eid in ipairs(evidenceIds) do params[#params + 1] = eid end
        MySQL.update.await(([[
            UPDATE forensic_evidence
            SET case_id = COALESCE(case_id, ?),
                report_id = COALESCE(report_id, ?),
                forensic_report_id = ?
            WHERE id IN (%s)
        ]]):format(placeholders), params)
        for _, eid in ipairs(evidenceIds) do
            upsertCrossRef(reportId, 'evidence', eid, 'laudo_associado', actorCitizenId, ('Laudo %s vinculado à evidência %s'):format(report.report_number or reportId, eid))
        end
    end

    local testIds = normalizeIdList(payload.lab_test_ids)
    if #testIds > 0 then
        local placeholders = table.concat((function()
            local t = {}
            for _ = 1, #testIds do t[#t + 1] = '?' end
            return t
        end)(), ',')
        local sceneParams = { report.scene_id }
        for _, tid in ipairs(testIds) do sceneParams[#sceneParams + 1] = tid end
        MySQL.update.await(([[
            UPDATE forensic_lab_tests
            SET scene_id = COALESCE(scene_id, ?)
            WHERE id IN (%s)
        ]]):format(placeholders), sceneParams)
        local params = { report.case_id, report.mdt_report_id, reportId }
        for _, tid in ipairs(testIds) do params[#params + 1] = tid end
        MySQL.update.await(([[
            UPDATE forensic_evidence fe
            INNER JOIN forensic_lab_tests lt ON lt.evidence_id = fe.id
            SET fe.case_id = COALESCE(fe.case_id, ?),
                fe.report_id = COALESCE(fe.report_id, ?),
                fe.forensic_report_id = ?
            WHERE lt.id IN (%s)
        ]]):format(placeholders), params)
    end

    if report.case_id then
        upsertCrossRef(reportId, 'case', report.case_id, 'laudo_relacionado_ao_caso', actorCitizenId, ('Laudo %s associado ao caso %s'):format(report.report_number or reportId, report.case_id))
    end
    if report.mdt_report_id then
        upsertCrossRef(reportId, 'report', report.mdt_report_id, 'laudo_relacionado_ao_relatorio', actorCitizenId, ('Laudo %s associado ao relatório MDT %s'):format(report.report_number or reportId, report.mdt_report_id))
    end
    if report.scene_id then
        upsertCrossRef(reportId, 'scene', report.scene_id, 'laudo_relacionado_a_cena', actorCitizenId, ('Laudo %s associado à cena %s'):format(report.report_number or reportId, report.scene_id))
    end
end

-- ============================================================
-- CRIAR LAUDO
-- ============================================================
lib.callback.register(resourceName .. ':server:createForensicReport', function(source, data)
    local src = source
    if not CheckForensicAuth(src) then return { success = false } end
    if not CheckForensicPermission(src, 'canEmitReport') then
        return { success = false, error = 'Sem permissão para emitir laudos' }
    end

    local playerData = GetPlayerData(src)
    local roleName = GetPlayerRole(src)

    local reportId = MySQL.insert.await([[
        INSERT INTO forensic_reports
        (report_number, scene_id, case_id, mdt_report_id, type, title, summary, body,
         conclusion, evidence_ids, lab_test_ids,
         linked_citizenids, linked_weapon_serials, linked_vehicle_plates,
         author_citizenid, author_name, author_role, status)
        VALUES ('', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'rascunho')
    ]], {
        data.scene_id and tonumber(data.scene_id) or nil,
        data.case_id and tonumber(data.case_id) or nil,
        data.mdt_report_id and tonumber(data.mdt_report_id) or nil,
        data.type or 'laudo_pericial',
        data.title or 'Laudo sem título',
        data.summary or '',
        data.body or '',
        data.conclusion or '',
        data.evidence_ids and json.encode(data.evidence_ids) or nil,
        data.lab_test_ids and json.encode(data.lab_test_ids) or nil,
        data.linked_citizenids and json.encode(data.linked_citizenids) or nil,
        data.linked_weapon_serials and json.encode(data.linked_weapon_serials) or nil,
        data.linked_vehicle_plates and json.encode(data.linked_vehicle_plates) or nil,
        playerData.citizenid,
        playerData.name,
        roleName or 'perito',
    })

    if not reportId then
        return { success = false, error = 'Falha ao criar laudo' }
    end

    local reportNumber = ForensicUtils.GenerateReportNumber(reportId)
    MySQL.update.await('UPDATE forensic_reports SET report_number = ? WHERE id = ?', { reportNumber, reportId })

    ForensicAuditLog(src, 'report_created', 'forensic_report', reportId, {
        reportNumber = reportNumber, type = data.type,
    })
    syncReportLinks(reportId, data or {}, playerData.citizenid)

    return { success = true, id = reportId, reportNumber = reportNumber }
end)

-- ============================================================
-- ATUALIZAR LAUDO
-- ============================================================
lib.callback.register(resourceName .. ':server:updateForensicReport', function(source, reportId, data)
    local src = source
    if not CheckForensicAuth(src) then return { success = false } end

    reportId = tonumber(reportId)
    if not reportId then return { success = false } end

    local playerData = GetPlayerData(src)
    if not playerData then return { success = false, error = L('scene.errors.player_data_unavailable') } end

    local updates = {}
    local values = {}

    local allowedFields = {
        'title', 'summary', 'body', 'conclusion', 'type', 'status',
        'case_id', 'mdt_report_id',
    }

    for _, field in ipairs(allowedFields) do
        if data[field] ~= nil then
            updates[#updates + 1] = field .. ' = ?'
            values[#values + 1] = data[field]
        end
    end

    -- JSON fields
    local jsonFields = { 'evidence_ids', 'lab_test_ids', 'linked_citizenids', 'linked_weapon_serials', 'linked_vehicle_plates' }
    for _, field in ipairs(jsonFields) do
        if data[field] ~= nil then
            updates[#updates + 1] = field .. ' = ?'
            values[#values + 1] = type(data[field]) == 'table' and json.encode(data[field]) or data[field]
        end
    end

    if #updates == 0 then
        return { success = false, error = 'Nenhuma atualização' }
    end

    values[#values + 1] = reportId
    MySQL.update.await(('UPDATE forensic_reports SET %s WHERE id = ?'):format(table.concat(updates, ', ')), values)
    syncReportLinks(reportId, data or {}, playerData.citizenid)

    ForensicAuditLog(src, 'report_updated', 'forensic_report', reportId, data)

    return { success = true }
end)

-- ============================================================
-- FINALIZAR LAUDO
-- ============================================================
lib.callback.register(resourceName .. ':server:finalizeForensicReport', function(source, reportId)
    local src = source
    if not CheckForensicAuth(src) then return { success = false } end
    if not CheckForensicPermission(src, 'canFinalizeReport') then
        return { success = false, error = 'Sem permissão para finalizar laudos' }
    end

    reportId = tonumber(reportId)
    local playerData = GetPlayerData(src)

    MySQL.update.await([[
        UPDATE forensic_reports
        SET status = 'finalizado', finalized_at = NOW(),
            reviewer_citizenid = ?, reviewer_name = ?
        WHERE id = ?
    ]], { playerData.citizenid, playerData.name, reportId })

    ForensicAuditLog(src, 'report_finalized', 'forensic_report', reportId, {})

    return { success = true }
end)

-- ============================================================
-- ANEXAR LAUDO AO MDT
-- ============================================================
lib.callback.register(resourceName .. ':server:attachReportToMDT', function(source, reportId)
    local src = source
    if not CheckForensicAuth(src) then return { success = false } end

    reportId = tonumber(reportId)
    local report = MySQL.single.await('SELECT * FROM forensic_reports WHERE id = ?', { reportId })
    if not report then return { success = false, error = 'Laudo não encontrado' } end

    if report.status ~= 'finalizado' then
        return { success = false, error = 'Laudo precisa estar finalizado para anexar ao MDT' }
    end

    local playerData = GetPlayerData(src)

    -- Se tem case_id, vincular o laudo como attachment ao caso no MDT
    if report.case_id then
        MySQL.insert.await([[
            INSERT INTO mdt_case_attachments (case_id, type, url, label, uploaded_by)
            VALUES (?, 'document', ?, ?, ?)
        ]], {
            report.case_id,
            ('forensic-report://%d'):format(reportId),
            ('[LAUDO] %s - %s'):format(report.report_number, report.title),
            playerData.citizenid,
        })
    end

    -- Criar evidência no MDT referenciando o laudo
    local mdtEvidenceId = MySQL.insert.await([[
        INSERT INTO mdt_evidence_items
        (case_id, report_id, title, type, serial, notes, location, stored, last_holder, created_by)
        VALUES (?, ?, ?, 'Laudo Forense', ?, ?, '', 1, ?, ?)
    ]], {
        report.case_id,
        report.mdt_report_id,
        ('[LAUDO] %s - %s'):format(report.report_number, report.title),
        report.report_number,
        report.conclusion or report.summary or '',
        playerData.citizenid,
        playerData.citizenid,
    })

    MySQL.update.await(
        "UPDATE forensic_reports SET status = 'anexado_mdt' WHERE id = ?",
        { reportId }
    )

    ForensicAuditLog(src, 'report_attached_mdt', 'forensic_report', reportId, {
        mdtEvidenceId = mdtEvidenceId,
        caseId = report.case_id,
    })

    return { success = true, mdtEvidenceId = mdtEvidenceId }
end)

-- ============================================================
-- LISTAR LAUDOS
-- ============================================================
lib.callback.register(resourceName .. ':server:getForensicReports', function(source, filters)
    local src = source
    if not CheckForensicAuth(src) then return { success = false } end

    filters = filters or {}
    local queryParts = { '1=1' }
    local values = {}

    if filters.scene_id then
        queryParts[#queryParts + 1] = 'scene_id = ?'
        values[#values + 1] = tonumber(filters.scene_id)
    end

    if filters.case_id then
        queryParts[#queryParts + 1] = 'case_id = ?'
        values[#values + 1] = tonumber(filters.case_id)
    end

    if filters.type and filters.type ~= '' then
        queryParts[#queryParts + 1] = 'type = ?'
        values[#values + 1] = filters.type
    end

    if filters.status and filters.status ~= '' then
        queryParts[#queryParts + 1] = 'status = ?'
        values[#values + 1] = filters.status
    end

    if filters.search and filters.search ~= '' then
        queryParts[#queryParts + 1] = '(report_number LIKE ? OR title LIKE ? OR summary LIKE ?)'
        local like = '%' .. filters.search .. '%'
        values[#values + 1] = like
        values[#values + 1] = like
        values[#values + 1] = like
    end

    local where = table.concat(queryParts, ' AND ')
    local items = MySQL.query.await(('SELECT * FROM forensic_reports WHERE %s ORDER BY created_at DESC LIMIT 50'):format(where), values)

    return { success = true, data = items or {} }
end)

-- ============================================================
-- OBTER LAUDO ESPECÍFICO
-- ============================================================
lib.callback.register(resourceName .. ':server:getForensicReport', function(source, reportId)
    local src = source
    if not CheckForensicAuth(src) then return nil end

    reportId = tonumber(reportId)
    if not reportId then return nil end

    return MySQL.single.await('SELECT * FROM forensic_reports WHERE id = ?', { reportId })
end)
