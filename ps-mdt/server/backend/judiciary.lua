local resourceName = tostring(GetCurrentResourceName())

local VALID_JUDICIAL_STATUS = {
    submitted = true,
    screening = true,
    hearing_scheduled = true,
    in_trial = true,
    awaiting_verdict = true,
    sentenced = true,
    archived = true,
    rejected = true,
}

local VALID_PRIORITY = {
    low = true,
    medium = true,
    high = true,
    urgent = true,
}

local VALID_HEARING_TYPE = {
    preliminary = true,
    custody = true,
    instruction = true,
    trial = true,
    sentencing = true,
    appeal = true,
}

local VALID_VERDICT = {
    pending = true,
    guilty = true,
    not_guilty = true,
    dismissed = true,
    plea_deal = true,
}

local function trim(value)
    if value == nil then return nil end
    local text = tostring(value)
    text = text:gsub('^%s+', ''):gsub('%s+$', '')
    if text == '' then return nil end
    return text
end

local function normalizeStatus(status)
    local normalized = trim(status)
    normalized = normalized and normalized:lower() or 'submitted'
    if VALID_JUDICIAL_STATUS[normalized] then
        return normalized
    end
    return 'submitted'
end

local function normalizePriority(priority)
    local normalized = trim(priority)
    normalized = normalized and normalized:lower() or 'medium'
    if VALID_PRIORITY[normalized] then
        return normalized
    end
    return 'medium'
end

local function normalizeHearingType(hearingType)
    local normalized = trim(hearingType)
    normalized = normalized and normalized:lower() or 'preliminary'
    if VALID_HEARING_TYPE[normalized] then
        return normalized
    end
    return 'preliminary'
end

local function normalizeVerdict(verdict)
    local normalized = trim(verdict)
    normalized = normalized and normalized:lower() or 'pending'
    if VALID_VERDICT[normalized] then
        return normalized
    end
    return 'pending'
end

local function hasJudiciaryPermission(src, permission)
    if CheckPermission then
        return CheckPermission(src, permission)
    end
    return CheckAuth(src)
end

local function getOfficerDisplayName(src)
    local callsign = ps.getMetadata(src, 'callsign')
    local name = ps.getPlayerName(src) or 'Desconhecido'
    if callsign and callsign ~= '' then
        return callsign .. ' ' .. name
    end
    return name
end

local function buildCourtNumber(id)
    return ('TRB-%s-%05d'):format(os.date('%Y'), id)
end

local function judicialCaseExistsByMdtCase(caseId)
    return MySQL.single.await('SELECT id, court_number FROM mdt_judicial_cases WHERE case_id = ?', { caseId })
end

local function buildCaseSummary(caseId)
    local reportCountRow = MySQL.single.await('SELECT COUNT(*) as total FROM mdt_case_reports WHERE case_id = ?', { caseId })
    local evidenceCountRow = MySQL.single.await('SELECT COUNT(*) as total FROM mdt_evidence_items WHERE case_id = ?', { caseId })

    return {
        reports = reportCountRow and tonumber(reportCountRow.total) or 0,
        evidence = evidenceCountRow and tonumber(evidenceCountRow.total) or 0,
    }
end

ps.registerCallback(resourceName .. ':server:submitCaseToJudiciary', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, error = 'Não autorizado' } end
    if not hasJudiciaryPermission(src, 'judiciary_submit_case') then
        return { success = false, error = 'Sem permissão para enviar caso ao tribunal' }
    end

    payload = payload or {}
    local caseId = tonumber(payload.caseId)
    if not caseId then
        return { success = false, error = 'Caso inválido' }
    end

    local caseRow = MySQL.single.await('SELECT id, case_number, title, summary, status FROM mdt_cases WHERE id = ?', { caseId })
    if not caseRow then
        return { success = false, error = 'Caso não encontrado no MDT' }
    end

    local existing = judicialCaseExistsByMdtCase(caseId)
    if existing then
        return {
            success = true,
            alreadyExists = true,
            judicialCaseId = existing.id,
            courtNumber = existing.court_number,
        }
    end

    local prosecutorId = ps.getIdentifier(src)
    if not prosecutorId then
        return { success = false, error = 'Identificador do policial ausente' }
    end

    local prosecutorName = getOfficerDisplayName(src)
    local branch = trim(payload.courtBranch) or 'tribunal_criminal'
    local priority = normalizePriority(payload.priority)
    local status = normalizeStatus(payload.status)

    local summarySnapshot = buildCaseSummary(caseId)
    local prosecutorSummary = trim(payload.prosecutorSummary)
        or ('Encaminhado com %d relatório(s) e %d evidência(s) vinculada(s).'):format(summarySnapshot.reports, summarySnapshot.evidence)

    local judicialCaseId = MySQL.insert.await([[
        INSERT INTO mdt_judicial_cases
            (court_number, case_id, status, priority, court_branch, prosecutor_citizenid, prosecutor_name, defendant_summary, prosecutor_summary, notes)
        VALUES
            ('', ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        caseId,
        status,
        priority,
        branch,
        prosecutorId,
        prosecutorName,
        trim(payload.defendantSummary),
        prosecutorSummary,
        trim(payload.notes),
    })

    if not judicialCaseId then
        return { success = false, error = 'Falha ao registrar caso judicial' }
    end

    local courtNumber = buildCourtNumber(judicialCaseId)
    MySQL.update.await('UPDATE mdt_judicial_cases SET court_number = ? WHERE id = ?', { courtNumber, judicialCaseId })

    MySQL.update.await('UPDATE mdt_cases SET status = ? WHERE id = ?', { 'in_progress', caseId })

    if ps.auditLog then
        ps.auditLog(src, 'judiciary_case_submitted', 'judicial_case', judicialCaseId, {
            case_id = caseId,
            court_number = courtNumber,
            priority = priority,
            court_branch = branch,
        })
    end

    return {
        success = true,
        judicialCaseId = judicialCaseId,
        courtNumber = courtNumber,
    }
end)

ps.registerCallback(resourceName .. ':server:getJudicialQueue', function(source, page, filters)
    local src = source
    if not CheckAuth(src) then return { success = false, data = {}, hasMore = false } end
    if not hasJudiciaryPermission(src, 'judiciary_view') then
        return { success = false, error = 'Sem permissão para visualizar pauta judicial', data = {}, hasMore = false }
    end

    page = tonumber(page) or 1
    local limit = Config.Pagination and Config.Pagination.Cases or 20
    local offset = (page - 1) * limit

    filters = filters or {}
    local clauses, values = {}, {}

    if filters.status then
        clauses[#clauses + 1] = 'jc.status = ?'
        values[#values + 1] = normalizeStatus(filters.status)
    end

    if filters.priority then
        clauses[#clauses + 1] = 'jc.priority = ?'
        values[#values + 1] = normalizePriority(filters.priority)
    end

    if filters.query and tostring(filters.query):match('%S') then
        local query = ('%%%s%%'):format(tostring(filters.query):match('^%s*(.-)%s*$'))
        clauses[#clauses + 1] = '(jc.court_number LIKE ? OR mc.case_number LIKE ? OR mc.title LIKE ? OR CAST(jc.id AS CHAR) LIKE ?)'
        values[#values + 1] = query
        values[#values + 1] = query
        values[#values + 1] = query
        values[#values + 1] = query
    end

    local whereClause = ''
    if #clauses > 0 then
        whereClause = 'WHERE ' .. table.concat(clauses, ' AND ')
    end

    values[#values + 1] = limit
    values[#values + 1] = offset

    local rows = MySQL.query.await(([[
        SELECT jc.id, jc.court_number, jc.case_id, jc.status, jc.priority, jc.court_branch,
               jc.prosecutor_name, jc.judge_name, jc.verdict, jc.filed_at, jc.updated_at,
               mc.case_number, mc.title,
               (SELECT COUNT(*) FROM mdt_judicial_hearings jh WHERE jh.judicial_case_id = jc.id) AS hearings_count,
               (SELECT COUNT(*) FROM mdt_judicial_decisions jd WHERE jd.judicial_case_id = jc.id) AS decisions_count
        FROM mdt_judicial_cases jc
        LEFT JOIN mdt_cases mc ON mc.id = jc.case_id
        %s
        ORDER BY jc.updated_at DESC
        LIMIT ? OFFSET ?
    ]]):format(whereClause), values)

    return {
        success = true,
        data = rows or {},
        hasMore = rows and #rows >= limit or false,
    }
end)

ps.registerCallback(resourceName .. ':server:getJudicialCase', function(source, judicialCaseId)
    local src = source
    if not CheckAuth(src) then return { success = false, error = 'Não autorizado' } end
    if not hasJudiciaryPermission(src, 'judiciary_view') then
        return { success = false, error = 'Sem permissão para visualizar caso judicial' }
    end

    judicialCaseId = tonumber(judicialCaseId)
    if not judicialCaseId then
        return { success = false, error = 'Identificador judicial inválido' }
    end

    local row = MySQL.single.await([[
        SELECT jc.*, mc.case_number, mc.title, mc.summary,
               (SELECT COUNT(*) FROM mdt_case_reports mcr WHERE mcr.case_id = jc.case_id) AS reports_count,
               (SELECT COUNT(*) FROM mdt_evidence_items mei WHERE mei.case_id = jc.case_id) AS evidence_count
        FROM mdt_judicial_cases jc
        LEFT JOIN mdt_cases mc ON mc.id = jc.case_id
        WHERE jc.id = ?
    ]], { judicialCaseId })

    if not row then
        return { success = false, error = 'Caso judicial não encontrado' }
    end

    local hearings = MySQL.query.await([[
        SELECT id, hearing_type, scheduled_for, location, status, presiding_judge,
               created_by, created_by_name, outcome_notes, created_at, updated_at
        FROM mdt_judicial_hearings
        WHERE judicial_case_id = ?
        ORDER BY scheduled_for DESC
    ]], { judicialCaseId })

    local decisions = MySQL.query.await([[
        SELECT id, decision_type, decision_text, verdict, sentence_json, decided_by, decided_by_name, decided_at
        FROM mdt_judicial_decisions
        WHERE judicial_case_id = ?
        ORDER BY decided_at DESC
    ]], { judicialCaseId })

    return {
        success = true,
        data = {
            case = row,
            hearings = hearings or {},
            decisions = decisions or {},
        }
    }
end)

ps.registerCallback(resourceName .. ':server:scheduleJudicialHearing', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, error = 'Não autorizado' } end
    if not hasJudiciaryPermission(src, 'judiciary_schedule_hearing') then
        return { success = false, error = 'Sem permissão para agendar audiência' }
    end

    payload = payload or {}
    local judicialCaseId = tonumber(payload.judicialCaseId)
    if not judicialCaseId then
        return { success = false, error = 'Caso judicial inválido' }
    end

    local caseRow = MySQL.single.await('SELECT id FROM mdt_judicial_cases WHERE id = ?', { judicialCaseId })
    if not caseRow then
        return { success = false, error = 'Caso judicial não encontrado' }
    end

    local scheduledFor = trim(payload.scheduledFor)
    if not scheduledFor then
        return { success = false, error = 'Data/hora da audiência é obrigatória' }
    end

    local hearingType = normalizeHearingType(payload.hearingType)
    local officerId = ps.getIdentifier(src)
    local officerName = getOfficerDisplayName(src)

    local hearingId = MySQL.insert.await([[
        INSERT INTO mdt_judicial_hearings
            (judicial_case_id, hearing_type, scheduled_for, location, status, presiding_judge, created_by, created_by_name, outcome_notes)
        VALUES
            (?, ?, ?, ?, 'scheduled', ?, ?, ?, ?)
    ]], {
        judicialCaseId,
        hearingType,
        scheduledFor,
        trim(payload.location),
        trim(payload.presidingJudge),
        officerId,
        officerName,
        trim(payload.outcomeNotes),
    })

    MySQL.update.await('UPDATE mdt_judicial_cases SET status = ?, judge_name = COALESCE(?, judge_name), updated_at = NOW() WHERE id = ?', {
        'hearing_scheduled',
        trim(payload.presidingJudge),
        judicialCaseId,
    })

    if ps.auditLog then
        ps.auditLog(src, 'judiciary_hearing_scheduled', 'judicial_case', judicialCaseId, {
            hearing_id = hearingId,
            hearing_type = hearingType,
            scheduled_for = scheduledFor,
        })
    end

    return { success = true, hearingId = hearingId }
end)

ps.registerCallback(resourceName .. ':server:recordJudicialDecision', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, error = 'Não autorizado' } end
    if not hasJudiciaryPermission(src, 'judiciary_record_verdict') then
        return { success = false, error = 'Sem permissão para registrar decisão judicial' }
    end

    payload = payload or {}
    local judicialCaseId = tonumber(payload.judicialCaseId)
    if not judicialCaseId then
        return { success = false, error = 'Caso judicial inválido' }
    end

    local caseRow = MySQL.single.await('SELECT id, case_id FROM mdt_judicial_cases WHERE id = ?', { judicialCaseId })
    if not caseRow then
        return { success = false, error = 'Caso judicial não encontrado' }
    end

    local decisionText = trim(payload.decisionText)
    if not decisionText then
        return { success = false, error = 'Texto da decisão é obrigatório' }
    end

    local verdict = normalizeVerdict(payload.verdict)
    local sentenceJson = payload.sentence and json.encode(payload.sentence) or trim(payload.sentenceJson)

    local officerId = ps.getIdentifier(src)
    local officerName = getOfficerDisplayName(src)

    local decisionId = MySQL.insert.await([[
        INSERT INTO mdt_judicial_decisions
            (judicial_case_id, decision_type, decision_text, verdict, sentence_json, decided_by, decided_by_name)
        VALUES
            (?, ?, ?, ?, ?, ?, ?)
    ]], {
        judicialCaseId,
        trim(payload.decisionType) or 'verdict',
        decisionText,
        verdict,
        sentenceJson,
        officerId,
        officerName,
    })

    local nextStatus = 'awaiting_verdict'
    local closedAt = nil
    if verdict ~= 'pending' then
        nextStatus = verdict == 'guilty' and 'sentenced' or 'archived'
        closedAt = os.date('%Y-%m-%d %H:%M:%S')
    end

    MySQL.update.await([[
        UPDATE mdt_judicial_cases
        SET verdict = ?, sentence_json = COALESCE(?, sentence_json),
            status = ?, judge_citizenid = ?, judge_name = ?,
            closed_at = COALESCE(?, closed_at), updated_at = NOW()
        WHERE id = ?
    ]], {
        verdict,
        sentenceJson,
        nextStatus,
        officerId,
        officerName,
        closedAt,
        judicialCaseId,
    })

    if verdict ~= 'pending' then
        MySQL.update.await('UPDATE mdt_cases SET status = ? WHERE id = ?', { 'closed', caseRow.case_id })
    end

    if ps.auditLog then
        ps.auditLog(src, 'judiciary_decision_recorded', 'judicial_case', judicialCaseId, {
            decision_id = decisionId,
            verdict = verdict,
            status = nextStatus,
        })
    end

    return { success = true, decisionId = decisionId, status = nextStatus }
end)

ps.registerCallback(resourceName .. ':server:updateJudicialCaseStatus', function(source, judicialCaseId, status, note)
    local src = source
    if not CheckAuth(src) then return { success = false, error = 'Não autorizado' } end
    if not hasJudiciaryPermission(src, 'judiciary_close_case') then
        return { success = false, error = 'Sem permissão para alterar status judicial' }
    end

    judicialCaseId = tonumber(judicialCaseId)
    if not judicialCaseId then
        return { success = false, error = 'Caso judicial inválido' }
    end

    local nextStatus = normalizeStatus(status)
    local closedAt = nil
    if nextStatus == 'archived' or nextStatus == 'rejected' then
        closedAt = os.date('%Y-%m-%d %H:%M:%S')
    end

    MySQL.update.await([[
        UPDATE mdt_judicial_cases
        SET status = ?,
            notes = CONCAT(COALESCE(notes, ''), CASE WHEN ? IS NULL THEN '' ELSE CONCAT('\n[STATUS] ', ?) END),
            closed_at = COALESCE(?, closed_at),
            updated_at = NOW()
        WHERE id = ?
    ]], {
        nextStatus,
        trim(note),
        trim(note),
        closedAt,
        judicialCaseId,
    })

    if ps.auditLog then
        ps.auditLog(src, 'judiciary_status_changed', 'judicial_case', judicialCaseId, {
            status = nextStatus,
            note = trim(note),
        })
    end

    return { success = true, status = nextStatus }
end)
