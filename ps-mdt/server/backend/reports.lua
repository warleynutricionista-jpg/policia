local resourceName = tostring(GetCurrentResourceName())
local OFFICER_DIRECTORY_CACHE_KEY = 'reports:officers:directory'
local OFFICER_DIRECTORY_TTL = 15

local function normalizeSearchTerm(value)
    return tostring(value or ''):match('^%s*(.-)%s*$') or ''
end

local function normalizeCallsignValue(value)
    local trimmed = normalizeSearchTerm(value)
    if trimmed == '' then
        return nil
    end

    local upper = trimmed:upper()
    if upper == 'SEM CALLSIGN' or upper == 'SEM INDICATIVO' or upper == 'NO CALLSIGN' or upper == 'N/A' then
        return nil
    end

    return trimmed
end

local function buildFullName(firstname, lastname, citizenid)
    local first = firstname and tostring(firstname) or ''
    local last = lastname and tostring(lastname) or ''
    local full = (first .. ' ' .. last):gsub('^%s+', ''):gsub('%s+$', '')
    if full ~= '' then
        return full
    end
    return ps.getPlayerNameByIdentifier(citizenid) or 'Desconhecido'
end

local function formatOfficerDisplayName(callsign, fullname)
    local sanitizedCallsign = normalizeCallsignValue(callsign)
    local sanitizedName = normalizeSearchTerm(fullname)
    if sanitizedName == '' then
        sanitizedName = 'Desconhecido'
    end

    if sanitizedCallsign then
        return ('%s %s'):format(sanitizedCallsign, sanitizedName)
    end

    return sanitizedName
end

local function decodeJsonField(value)
    if not value or value == '' then
        return {}
    end

    local ok, decoded = pcall(json.decode, value)
    return ok and type(decoded) == 'table' and decoded or {}
end

local function reportTimestampToSql(value)
    if not value then
        return nil
    end

    local raw = tostring(value)
    if raw == '' then
        return nil
    end

    local normalized = raw:gsub('T', ' '):gsub('Z$', '')
    local y, m, d, hh, mm, ss = normalized:match('^(%d%d%d%d)%-(%d%d)%-(%d%d)%s+(%d%d):(%d%d):(%d%d)')
    if y then
        return ('%s-%s-%s %s:%s:%s'):format(y, m, d, hh, mm, ss)
    end

    return nil
end

local function validateEntityReferences(reportData)
    if type(reportData) ~= 'table' then
        return true, nil
    end

    for _, involved in ipairs(reportData.involved or {}) do
        local cid = involved and involved.citizenid and normalizeSearchTerm(involved.citizenid) or ''
        if cid ~= '' then
            local exists = MySQL.scalar.await('SELECT COUNT(*) FROM players WHERE citizenid = ? LIMIT 1', { cid })
            if tonumber(exists) == 0 then
                return false, ('Cidadão não encontrado: %s'):format(cid)
            end
        end
    end

    for _, charge in ipairs(reportData.charges or {}) do
        local cid = charge and charge.citizenid and normalizeSearchTerm(charge.citizenid) or ''
        if cid ~= '' then
            local exists = MySQL.scalar.await('SELECT COUNT(*) FROM players WHERE citizenid = ? LIMIT 1', { cid })
            if tonumber(exists) == 0 then
                return false, ('Cidadão não encontrado para acusação: %s'):format(cid)
            end
        end
    end

    for _, vehicle in ipairs(reportData.vehicles or {}) do
        local plate = vehicle and vehicle.plate and normalizeSearchTerm(vehicle.plate) or ''
        if plate ~= '' then
            local exists = MySQL.scalar.await([[
                SELECT COUNT(*)
                FROM player_vehicles
                WHERE plate = ?
                LIMIT 1
            ]], { plate })
            if tonumber(exists) == 0 then
                return false, ('Veículo não encontrado para placa: %s'):format(plate)
            end
        end
    end

    return true, nil
end

local function canViewReports(src)
    return CheckPermission(src, 'reports_view')
end

local function canCreateReports(src)
    return CheckPermission(src, 'reports_create')
end

local function canEditReports(src)
    return CheckPermission(src, 'reports_edit')
end

local function canDeleteReports(src)
    return CheckPermission(src, 'reports_delete')
end

local function canApproveReports(src)
    return CheckPermission(src, 'reports_approve')
end

local function canArchiveReports(src)
    return CheckPermission(src, 'reports_archive')
end

local function canUnarchiveReports(src)
    return CheckPermission(src, 'reports_unarchive')
end

local function canSignReports(src)
    return CheckPermission(src, 'reports_sign')
end

local function buildDigitalSignature(identifier, reportId, content)
    local base = ('%s|%s|%s|%s'):format(
        tostring(identifier or 'unknown'),
        tostring(reportId or '0'),
        tostring(GetGameTimer()),
        tostring(content or '')
    )
    return tostring(GetHashKey(base))
end

local function getOfficerEmployment(citizenid, primaryJob)
    local primaryJobName = primaryJob and primaryJob.name and tostring(primaryJob.name) or nil
    if primaryJobName and IsPoliceJob(primaryJobName, primaryJob.type) then
        local sharedGrade = type(primaryJob.grade) == 'table' and primaryJob.grade or ps.getSharedJobGrade(primaryJobName, primaryJob.grade)
        return {
            job = primaryJobName,
            grade = NormalizeMdtGradeValue(primaryJob.grade),
            gradeData = sharedGrade,
            type = primaryJob.type,
        }
    end

    if GetResourceState('ps-multijob') ~= 'started' or not exports['ps-multijob'] then
        return nil
    end

    local ok, jobs = pcall(function()
        return exports['ps-multijob']:GetJobs(citizenid)
    end)
    if not ok or type(jobs) ~= 'table' then
        return nil
    end

    for _, jobData in pairs(jobs) do
        if type(jobData) == 'table' then
            local jobName = tostring(jobData.job or jobData.name or '')
            local sharedGrade = ps.getSharedJobGrade(jobName, jobData.grade)
            local sharedJob = ps.getSharedJobData(jobName)
            local jobType = jobData.type or (sharedGrade and sharedGrade.type) or (sharedJob and sharedJob.type) or nil
            if IsPoliceJob(jobName, jobType) then
                return {
                    job = jobName,
                    grade = NormalizeMdtGradeValue(jobData.grade),
                    gradeData = sharedGrade,
                    type = jobType,
                }
            end
        end
    end

    return nil
end

local function buildOfficerDirectory()
    return Cache.getOrSet(OFFICER_DIRECTORY_CACHE_KEY, OFFICER_DIRECTORY_TTL, function()
        local rows = MySQL.query.await([[
            SELECT
                p.citizenid,
                p.charinfo,
                p.job,
                p.metadata,
                mp.callsign AS profile_callsign
            FROM players p
            LEFT JOIN mdt_profiles mp
                ON mp.citizenid COLLATE utf8mb4_general_ci = p.citizenid COLLATE utf8mb4_general_ci
        ]]) or {}

        local results = {}
        for _, row in ipairs(rows) do
            local citizenid = row.citizenid
            local charinfo = decodeJsonField(row.charinfo)
            local job = decodeJsonField(row.job)
            local metadata = decodeJsonField(row.metadata)
            local employment = getOfficerEmployment(citizenid, job)

            if citizenid and employment then
                local callsign = normalizeCallsignValue(row.profile_callsign or metadata.callsign)
                local fullName = buildFullName(charinfo.firstname, charinfo.lastname, citizenid)
                local rankData = GetMdtRankData(employment.job, employment.grade, employment.gradeData)
                results[#results + 1] = {
                    id = citizenid,
                    citizenid = citizenid,
                    fullName = fullName,
                    badgeId = callsign,
                    rank = rankData.label ~= 'Officer' and rankData.label or (employment.gradeData and employment.gradeData.name) or nil,
                    department = employment.job,
                    label = callsign and ('%s - %s'):format(callsign, fullName) or fullName,
                    searchText = table.concat({
                        citizenid,
                        fullName,
                        callsign or '',
                        employment.job or '',
                        rankData.label or '',
                    }, ' '):lower(),
                }
            end
        end

        table.sort(results, function(a, b)
            local aCallsign = a.badgeId or ''
            local bCallsign = b.badgeId or ''
            if aCallsign ~= bCallsign then
                return aCallsign < bCallsign
            end

            return (a.fullName or '') < (b.fullName or '')
        end)

        return results
    end) or {}
end

local function searchOfficerDirectory(query)
    local needle = normalizeSearchTerm(query):lower()
    local results = {}

    for _, officer in ipairs(buildOfficerDirectory()) do
        if needle == '' or (officer.searchText and officer.searchText:find(needle, 1, true)) then
            results[#results + 1] = {
                id = officer.id,
                citizenid = officer.citizenid,
                fullName = officer.fullName,
                badgeId = officer.badgeId,
                rank = officer.rank,
                department = officer.department,
                label = officer.label,
            }
            if #results >= 50 then
                break
            end
        end
    end

    return results
end


local function collectCitizenIds(reportData)
    local citizenids = {}

    if reportData.involved then
        for _, involved in ipairs(reportData.involved) do
            if involved.citizenid then
                citizenids[involved.citizenid] = true
            end
        end
    end

    if reportData.charges then
        for _, charge in ipairs(reportData.charges) do
            if charge.citizenid then
                citizenids[charge.citizenid] = true
            end
        end
    end

    return citizenids
end

local function checkReportAccess(src, reportId)
    if not src or not reportId then
        return false
    end

    local identifier = ps.getIdentifier(src)
    local job = ps.getJobName(src)
    local jobType = ps.getJobType(src)

    if not identifier then
        return false
    end

    local hasAccess = MySQL.query.await([[
        SELECT mr.id
        FROM mdt_reports mr
        LEFT JOIN mdt_reports_restrictions mrr_check ON mr.id = mrr_check.reportid
        WHERE mr.id = ?
        AND (
            mrr_check.reportid IS NULL
            OR (mrr_check.type = 'citizenid' AND mrr_check.identifier = ?)
            OR (mrr_check.type = 'job' AND mrr_check.identifier = ?)
            OR (mrr_check.type = 'jobtype' AND mrr_check.identifier = ?)
        )
        GROUP BY mr.id
    ]], {reportId, identifier, job, jobType})

    return hasAccess and hasAccess[1] ~= nil
end

local function normalizeDateFilter(value)
    if not value then
        return nil
    end
    local year, month, day = tostring(value):match('^(%d%d%d%d)%-(%d%d)%-(%d%d)$')
    if not year then
        return nil
    end
    return ('%s-%s-%s'):format(year, month, day)
end

local function buildReportFilterClause(filters)
	local clauses = {}
	local values = {}
	if not filters then
		return '', values
	end

	local function hasValue(value)
		if value == nil then
			return false
		end
		if json and value == json.null then
			return false
		end
		if type(value) == 'string' then
			return value:gsub('%s+', '') ~= ''
		end
		return true
	end

	if hasValue(filters.type) then
		clauses[#clauses + 1] = 'mr.type = ?'
		values[#values + 1] = filters.type
	end

	if hasValue(filters.author) then
		local likeQuery = '%' .. tostring(filters.author) .. '%'
		clauses[#clauses + 1] = '(mr.authorplaintext LIKE ? OR mr.author LIKE ?)'
		values[#values + 1] = likeQuery
		values[#values + 1] = likeQuery
	end

    local startDate = normalizeDateFilter(filters.startDate)
    if startDate then
        clauses[#clauses + 1] = 'mr.datecreated >= CONCAT(?, " 00:00:00")'
        values[#values + 1] = startDate
    end

    local endDate = normalizeDateFilter(filters.endDate)
    if endDate then
        clauses[#clauses + 1] = 'mr.datecreated <= CONCAT(?, " 23:59:59")'
        values[#values + 1] = endDate
    end

    if #clauses == 0 then
        return '', values
    end

    return ' AND ' .. table.concat(clauses, ' AND '), values
end

local function buildReportAnalyticsClause(filters)
	local clauses = {}
	local values = {}
	if not filters then
		return '', values
	end

	local function hasValue(value)
		if value == nil then
			return false
		end
		if json and value == json.null then
			return false
		end
		if type(value) == 'string' then
			return value:gsub('%s+', '') ~= ''
		end
		return true
	end

	if hasValue(filters.author) then
		local likeQuery = '%' .. tostring(filters.author) .. '%'
		clauses[#clauses + 1] = '(mr.authorplaintext LIKE ? OR mr.author LIKE ?)'
		values[#values + 1] = likeQuery
		values[#values + 1] = likeQuery
	end

    local startDate = normalizeDateFilter(filters.startDate)
    if startDate then
        clauses[#clauses + 1] = 'mr.datecreated >= CONCAT(?, " 00:00:00")'
        values[#values + 1] = startDate
    end

    local endDate = normalizeDateFilter(filters.endDate)
    if endDate then
        clauses[#clauses + 1] = 'mr.datecreated <= CONCAT(?, " 23:59:59")'
        values[#values + 1] = endDate
    end

    if #clauses == 0 then
        return '', values
    end

    return ' AND ' .. table.concat(clauses, ' AND '), values
end

local function buildReportAccessClause()
    return [[
        (
            (mrr.reportid IS NULL AND ? = 'leo')
            OR (mrr.type = 'citizenid' AND mrr.identifier = ?)
            OR (mrr.type = 'job' AND mrr.identifier = ?)
            OR (mrr.type = 'jobtype' AND mrr.identifier = ?)
        )
    ]]
end


ps.registerCallback(resourceName .. ':server:getReports', function(source, page, filters)
	local src = source
	if not CheckAuth(src) then return end
    if not canViewReports(src) then
        return { reports = {}, page = 1, limit = 20, total = 0, hasMore = false }
    end

    local identifier = ps.getIdentifier(src)
    local job = ps.getJobName(src)
    local jobType = ps.getJobType(src)

	local pageNumber = tonumber(page) or 1
	pageNumber = math.max(1, pageNumber)
	local limit = 20
	local offset = (pageNumber - 1) * limit


	local filterClause, filterValues = buildReportFilterClause(filters)
	filterClause = filterClause or ''

	local reportsQuery = ([[
		SELECT
			mr.id,
			mr.id as reportId,
			mr.title,
			mr.type,
			mr.contentyjs,
			mr.contentplaintext,
			mr.author,
			mr.authorplaintext,
			mr.datecreated,
			mr.dateupdated,
			(SELECT mrt.tag FROM mdt_reports_tags mrt WHERE mrt.reportid = mr.id LIMIT 1) as tag,
			(SELECT COUNT(*) FROM mdt_reports_tags mrt WHERE mrt.reportid = mr.id) as tagCount
		FROM
			mdt_reports AS mr
		LEFT JOIN
			mdt_reports_restrictions AS mrr ON mr.id = mrr.reportid
		WHERE
			%s%s
		GROUP BY
			mr.id
		ORDER BY
			mr.datecreated DESC
		LIMIT %d
		OFFSET %d
	]]):format(buildReportAccessClause(), filterClause, limit, offset)
	local params = { jobType, identifier, job, jobType }
	for _, value in ipairs(filterValues or {}) do
		params[#params + 1] = value
	end
	local reports = MySQL.query.await(reportsQuery, params) or {}

    local countQuery = ([[
        SELECT COUNT(DISTINCT mr.id) AS total
        FROM mdt_reports AS mr
        LEFT JOIN mdt_reports_restrictions AS mrr ON mr.id = mrr.reportid
        WHERE %s%s
    ]]):format(buildReportAccessClause(), filterClause)
    local total = MySQL.scalar.await(countQuery, params) or 0

	return {
        reports = reports,
        page = pageNumber,
        limit = limit,
        total = tonumber(total) or 0,
        hasMore = (offset + #reports) < (tonumber(total) or 0)
    }
end)

ps.registerCallback(resourceName..':server:getReport', function(source, reportid)
    local src = source
	if not CheckAuth(src) then return end
    if not canViewReports(src) then return nil end

	local identifier = ps.getIdentifier(src)
    local job = ps.getJobName(src)
    local jobType = ps.getJobType(src)

    local result = MySQL.query.await([[
        SELECT
            mr.*,
            (SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'citizenid', mri.citizenid,
                    'type', mri.type,
                    'notes', mri.notes,
                    'warrantActive', CASE
                        WHEN mri.type = 'suspect' AND EXISTS(
                            SELECT 1 FROM mdt_reports_warrants mw
                            WHERE mw.reportid = mr.id AND mw.citizenid = mri.citizenid AND mw.expirydate >= NOW()
                        ) THEN true
                        ELSE false
                    END
                )
            ) FROM mdt_reports_involved mri WHERE mri.reportid = mr.id) as involved,
            (SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'citizenid', mrc.citizenid,
                    'charge', mrc.charge,
                    'count', mrc.count,
                    'time', mrc.time,
                    'fine', mrc.fine
                )
            ) FROM mdt_reports_charges mrc WHERE mrc.reportid = mr.id) as charges,
            (SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'type', mre.type,
                    'content', mre.content,
                    'note', mre.note,
                    'stored', mre.stored
                )
            ) FROM mdt_reports_evidence mre WHERE mre.reportid = mr.id) as evidence,
            (SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'type', mrr.type,
                    'identifier', mrr.identifier
                )
            ) FROM mdt_reports_restrictions mrr WHERE mrr.reportid = mr.id) as restrictions,
            (SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'tag', mrt.tag
                )
            ) FROM mdt_reports_tags mrt WHERE mrt.reportid = mr.id) as tags,
            (SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'plate', mrv.plate,
                    'vehicle_label', mrv.vehicle_label,
                    'owner_name', mrv.owner_name,
                    'owner_citizenid', mrv.owner_citizenid
                )
            ) FROM mdt_report_vehicles mrv WHERE mrv.reportid = mr.id) as vehicles
        FROM mdt_reports mr
        WHERE mr.id = ?
    ]], {reportid})

    local report = result[1] or nil
    if not report then return nil end

    -- Post-process: resolve names and profile images for involved persons
    local enrichOk, enrichErr = pcall(function()
        local involved = report.involved
        if type(involved) == 'string' then
            local ok, decoded = pcall(json.decode, involved)
            if ok then involved = decoded end
        end

        if type(involved) ~= 'table' or #involved == 0 then return end

        -- Collect unique citizenids
        local cids = {}
        for _, entry in ipairs(involved) do
            if entry and entry.citizenid and entry.citizenid ~= '' then
                cids[entry.citizenid] = true
            end
        end

        local cidList = {}
        for cid in pairs(cids) do
            cidList[#cidList + 1] = cid
        end

        if #cidList > 0 then
            local placeholders = string.rep('?,', #cidList):sub(1, -2)
            local lookupQuery = ([[
                SELECT
                    p.citizenid,
                    CONCAT(
                        JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')),
                        ' ',
                        JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname'))
                    ) as fullname,
                    mp.profilepicture as image
                FROM players p
                LEFT JOIN mdt_profiles mp ON mp.citizenid COLLATE utf8mb4_general_ci = p.citizenid COLLATE utf8mb4_general_ci
                WHERE p.citizenid COLLATE utf8mb4_general_ci IN (%s)
            ]]):format(placeholders)

            local lookupRows = MySQL.query.await(lookupQuery, cidList)
            local cidInfo = {}
            if lookupRows then
                for _, row in ipairs(lookupRows) do
                    cidInfo[row.citizenid] = { name = row.fullname, image = row.image }
                end
            end

            for _, entry in ipairs(involved) do
                if entry and entry.citizenid and cidInfo[entry.citizenid] then
                    local info = cidInfo[entry.citizenid]
                    entry.name = info.name or entry.name
                    entry.image = info.image
                end
            end
        end

        report.involved = json.encode(involved)
    end)

    if not enrichOk then
        ps.warn(('[getReport] Failed to enrich involved data: %s'):format(tostring(enrichErr)))
    end

    return report
end)

ps.registerCallback(resourceName .. ':server:searchPlayers', function(source, query)
    local src = source
    if not CheckAuth(src) then return end

    if not query or query == '' then
        return {}
    end

    if ps.auditLog then
        ps.auditLog(src, 'search_players', 'search', nil, {
            query = query
        })
    end

    local likeQuery = '%' .. query .. '%'

    local rows = MySQL.query.await([[
        SELECT
            p.citizenid,
            JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')) as firstname,
            JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname')) as lastname,
            JSON_UNQUOTE(JSON_EXTRACT(p.metadata, '$.fingerprint')) as fingerprint,
            mp.profilepicture
        FROM players p
        LEFT JOIN mdt_profiles mp ON mp.citizenid COLLATE utf8mb4_general_ci = p.citizenid COLLATE utf8mb4_general_ci
        WHERE (
            p.citizenid LIKE ?
            OR JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')) LIKE ?
            OR JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname')) LIKE ?
            OR CONCAT(
                JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')),
                ' ',
                JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname'))
            ) LIKE ?
        )
        LIMIT 25
    ]], { likeQuery, likeQuery, likeQuery, likeQuery })

    local results = {}
    for _, row in ipairs(rows or {}) do
        local fullName = buildFullName(row.firstname, row.lastname, row.citizenid)
        local fingerprint = (row.fingerprint and row.fingerprint ~= 'null') and row.fingerprint or nil
        table.insert(results, {
            id = row.citizenid,
            citizenid = row.citizenid,
            fullName = fullName,
            fingerprint = fingerprint,
            image = row.profilepicture or nil,
        })
    end

    return results
end)

ps.registerCallback(resourceName .. ':server:searchOfficers', function(source, query)
    local src = source
    if not CheckAuth(src) then return {} end

    local payload = query
    if type(payload) ~= 'table' then
        payload = { query = payload }
    end

    local page = math.max(1, tonumber(payload.page) or 1)
    local limit = math.min(math.max(1, tonumber(payload.limit) or (Config.Pagination and Config.Pagination.Officers or 25)), 100)
    local trimmedQuery = tostring(payload.query or ''):match('^%s*(.-)%s*$') or ''
    local hasSearch = trimmedQuery ~= ''
    local likeQuery = '%' .. trimmedQuery .. '%'

    if hasSearch and ps.auditLog then
        ps.auditLog(src, 'search_officers', 'search', nil, {
            query = trimmedQuery
        })
    end

    local matched = searchOfficerDirectory(trimmedQuery)
    local offset = (page - 1) * limit
    local paged = {}
    for i = offset + 1, math.min(#matched, offset + limit) do
        paged[#paged + 1] = matched[i]
    end

    return {
        officers = paged,
        page = page,
        limit = limit,
        total = #matched,
        hasMore = (offset + limit) < #matched
    }
end)

ps.registerCallback(resourceName .. ':server:searchVehiclesForReport', function(source, query)
    local src = source
    if not CheckAuth(src) then return {} end
    local trimmedQuery = normalizeSearchTerm(query)
    local directory = GetMdtVehicleDirectory and GetMdtVehicleDirectory() or { vehicles = {} }
    local results = {}

    for _, vehicle in ipairs(directory.vehicles or {}) do
        local searchText = table.concat({
            vehicle.plate or '',
            vehicle.model or '',
            vehicle.label or '',
            vehicle.owner or '',
            vehicle.ownerCitizenId or '',
        }, ' '):lower()

        if trimmedQuery == '' or searchText:find(trimmedQuery:lower(), 1, true) then
            results[#results + 1] = {
                plate = vehicle.plate,
                vehicle_label = vehicle.label,
                owner_name = vehicle.owner,
                owner_citizenid = vehicle.ownerCitizenId,
                model = vehicle.model,
            }
            if #results >= 25 then
                break
            end
        end
    end

    return results
end)

ps.registerCallback(resourceName..':server:saveReport', function(source, reportData)
    local src = source
    if not CheckAuth(src) then return end
    EnsureMdtSchema()

    local identifier = ps.getIdentifier(src)
    local playerName = ps.getPlayerName(src)
    local callsign = normalizeCallsignValue(ps.getMetadata(src, 'callsign'))

    if not identifier or normalizeSearchTerm(identifier) == '' then
        return { success = false, error = 'Falha ao salvar: oficial responsável não identificado' }
    end

    local referencesOk, referenceError = validateEntityReferences(reportData)
    if not referencesOk then
        return { success = false, error = referenceError }
    end

    local title = reportData.report and reportData.report.title
    if not title or title == "" then
        ps.notify(src, 'Falha ao salvar o relatório: é necessário um título', 'error')
        ps.warn('Report with missing/empty title from player: ' .. src .. ' Name: ' .. playerName)
        return { success = false, error = 'O relatório precisa de um título' }
    end

    local content = reportData.report and reportData.report.content
    if not content or content == "" then
        ps.notify(src, 'Falha ao salvar o relatório: é necessário conteúdo', 'error')
        ps.warn('Report with missing/empty content from player: ' .. src .. ' Name: ' .. playerName)
        return { success = false, error = 'O relatório precisa de conteúdo' }
    end

    -- Tags are required
    local tags = reportData.tags
    if not tags or type(tags) ~= 'table' or #tags == 0 then
        ps.notify(src, 'Falha ao salvar o relatório: é necessária pelo menos uma tag', 'error')
        return { success = false, message = 'É necessária pelo menos uma tag' }
    end

    local reportId = reportData.report and tonumber(reportData.report.id) or nil
    if not reportId and not canCreateReports(src) then
        return { success = false, error = 'Sem permissão para criar relatório' }
    end
    if reportId and not canEditReports(src) then
        return { success = false, error = 'Sem permissão para editar relatório' }
    end

    local reportType = reportData.report and reportData.report.type or 'Incident Report'

    local citizenids = collectCitizenIds(reportData)

    for citizenid, _ in pairs(citizenids) do
        if not EnsureProfileExists(citizenid) then
            -- Profile creation failed but don't block the save - the citizen
            -- may be offline or from a different framework. The report can still
            -- reference them by citizenid and the profile will be created when
            -- they are next looked up.
            ps.warn(('[Profile Auto-Create Skipped] Player [%s] %s saving report with citizen %s who has no profile yet')
                :format(src, playerName, citizenid))
        end
    end

    if reportId then
        if not checkReportAccess(src, reportId) then
            ps.notify(src, 'Falha ao salvar o relatório: não encontrado ou sem acesso', 'error')
            ps.warn(('[Failed to save] Player [%s] %s tried to save a report (%s), but it was not found or they do not have access.')
                :format(src, playerName, reportId))
            return { success = false, error = "Report not found or access denied" }
        end

        local current = MySQL.single.await('SELECT author, report_status FROM mdt_reports WHERE id = ? LIMIT 1', { reportId })
        if current and current.report_status == 'archived' and not canUnarchiveReports(src) then
            return { success = false, error = 'Relatório arquivado. Apenas cargos autorizados podem desarquivar e editar.' }
        end
        if current and current.report_status == 'approved' and current.author ~= identifier and not canApproveReports(src) then
            return { success = false, error = 'Relatório aprovado só pode ser editado por aprovação hierárquica.' }
        end

        local expectedDateUpdated = reportTimestampToSql(reportData.report and reportData.report.dateupdated)
        if expectedDateUpdated then
            local isCurrent = MySQL.scalar.await([[
                SELECT COUNT(*)
                FROM mdt_reports
                WHERE id = ?
                  AND DATE_FORMAT(dateupdated, '%Y-%m-%d %H:%i:%s') = ?
            ]], { reportId, expectedDateUpdated })
            if tonumber(isCurrent) == 0 then
                return {
                    success = false,
                    error = 'Este relatório foi alterado por outro oficial. Reabra o registro para evitar sobrescrita.',
                    conflict = true,
                }
            end
        end
    end

    if not reportId then
        local insertResult = MySQL.insert.await([[
            INSERT INTO mdt_reports (title, type, contentyjs, contentplaintext, author, authorplaintext)
            VALUES (?, ?, ?, ?, ?, ?)
        ]], {
            title,
            reportType,
            json.encode(content),
            type(content) == "string" and content or json.encode(content),
            identifier,
            formatOfficerDisplayName(callsign, playerName or 'Desconhecido')
        })

        if not insertResult then
            ps.notify(src, 'Falha ao salvar o relatório', 'error')
            ps.warn(('[Failed to save] Player [%s] %s tried to save a report (new). Insert failed.')
                :format(src, playerName))
            return { success = false, error = 'Falha ao inserir o relatório' }
        end
        reportId = insertResult
        MySQL.update.await([[
            UPDATE mdt_reports
            SET report_status = ?, requires_approval = ?
            WHERE id = ?
        ]], {
            canApproveReports(src) and 'approved' or 'pending_review',
            canApproveReports(src) and 0 or 1,
            reportId
        })
    else
        local updateSuccess = MySQL.update.await([[
            UPDATE mdt_reports
            SET title = ?, type = ?, contentyjs = ?, contentplaintext = ?, author = ?, authorplaintext = ?,
                report_status = IF(report_status = 'archived', report_status, IF(? = 1, report_status, 'pending_review')),
                requires_approval = IF(? = 1, 0, 1),
                dateupdated = CURRENT_TIMESTAMP
            WHERE id = ?
        ]], {
            title,
            reportType,
            json.encode(content),
            type(content) == "string" and content or json.encode(content),
            identifier,
            formatOfficerDisplayName(callsign, playerName or 'Desconhecido'),
            canApproveReports(src) and 1 or 0,
            canApproveReports(src) and 1 or 0,
            reportId
        })

        if not updateSuccess or updateSuccess == 0 then
            ps.notify(src, 'Falha ao salvar o relatório', 'error')
            ps.warn(('[Failed to save] Player [%s] %s tried to save a report (%s). Update failed.')
                :format(src, playerName, reportId))
            return { success = false, error = 'Falha ao atualizar o relatório' }
        end

        local cleanupQueries = {
            { query = "DELETE FROM mdt_reports_involved WHERE reportid = ?", values = { reportId } },
            { query = "DELETE FROM mdt_reports_charges WHERE reportid = ?", values = { reportId } },
            { query = "DELETE FROM mdt_reports_evidence WHERE reportid = ?", values = { reportId } },
            { query = "DELETE FROM mdt_reports_restrictions WHERE reportid = ?", values = { reportId } },
            { query = "DELETE FROM mdt_reports_tags WHERE reportid = ?", values = { reportId } },
            { query = "DELETE FROM mdt_report_vehicles WHERE reportid = ?", values = { reportId } },
            { query = "DELETE FROM mdt_arrests WHERE reportid = ?", values = { reportId } }
        }

        local cleanupOk, cleanupErr = pcall(function()
            return MySQL.transaction.await(cleanupQueries)
        end)
        if not cleanupOk then
            ps.warn(('[Cleanup Transaction Error] Report %s: %s'):format(reportId, tostring(cleanupErr)))
            return { success = false, error = "Failed to clean up old report data: " .. tostring(cleanupErr) }
        end
    end

    local attachmentQueries = {}
    local warrantCitizenIds = {}

    if reportData.involved and #reportData.involved > 0 then
        for _, involved in ipairs(reportData.involved) do
            table.insert(attachmentQueries, {
                query = "INSERT INTO mdt_reports_involved (reportid, citizenid, type, notes) VALUES (?, ?, ?, ?)",
                values = { reportId, involved.citizenid, involved.type, involved.notes }
            })
        end
    end

    if reportData.charges and #reportData.charges > 0 then
        for _, charge in ipairs(reportData.charges) do
            table.insert(attachmentQueries, {
                query = "INSERT INTO mdt_reports_charges (reportid, citizenid, charge, count, time, fine) VALUES (?, ?, ?, ?, ?, ?)",
                values = { reportId, charge.citizenid, charge.charge, charge.count or 1, charge.time, charge.fine }
            })
            if charge.warrant == true and charge.citizenid then
                warrantCitizenIds[charge.citizenid] = true
            end
        end
    end

    if reportData.evidence and #reportData.evidence > 0 then
        for _, evidence in ipairs(reportData.evidence) do
            table.insert(attachmentQueries, {
                query =
                "INSERT INTO mdt_reports_evidence (reportid, type, content, note, stored) VALUES (?, ?, ?, ?, ?)",
                values = { reportId, evidence.type, evidence.content, evidence.note, evidence.stored or 0 }
            })
        end
    end

    if reportData.restrictions and #reportData.restrictions > 0 then
        for _, restriction in ipairs(reportData.restrictions) do
            table.insert(attachmentQueries, {
                query = "INSERT INTO mdt_reports_restrictions (reportid, type, identifier) VALUES (?, ?, ?)",
                values = { reportId, restriction.type, restriction.identifier }
            })
        end
    end

    -- Auto-add jobtype restriction so reports are only visible to the same job type
    local creatorJobType = ps.getJobType(src)
    if creatorJobType then
        table.insert(attachmentQueries, {
            query = "INSERT INTO mdt_reports_restrictions (reportid, type, identifier) VALUES (?, ?, ?)",
            values = { reportId, 'jobtype', creatorJobType }
        })
    end

    if reportData.tags and #reportData.tags > 0 then
        for _, tag in ipairs(reportData.tags) do
            table.insert(attachmentQueries, {
                query = "INSERT INTO mdt_reports_tags (reportid, tag) VALUES (?, ?)",
                values = { reportId, tag.tag }
            })
        end
    end

    if reportData.vehicles and #reportData.vehicles > 0 then
        for _, vehicle in ipairs(reportData.vehicles) do
            table.insert(attachmentQueries, {
                query = "INSERT INTO mdt_report_vehicles (reportid, plate, vehicle_label, owner_name, owner_citizenid) VALUES (?, ?, ?, ?, ?)",
                values = { reportId, vehicle.plate, vehicle.vehicle_label, vehicle.owner_name, vehicle.owner_citizenid }
            })
        end
    end

    if #attachmentQueries > 0 then
        local attachOk, attachErr = pcall(function()
            return MySQL.transaction.await(attachmentQueries)
        end)
        if not attachOk then
            ps.warn(('[Attachment Transaction Error] Report %s: %s'):format(reportId, tostring(attachErr)))
            return { success = false, error = "Falha ao salvar os anexos do relatório: " .. tostring(attachErr) }
        end
    end

    if reportId and reportType == 'Arrest Report' and reportData.involved and #reportData.involved > 0 then
        local officerId = ps.getIdentifier(src)
        local officerName = formatOfficerDisplayName(callsign, playerName or '')
        local arrestQueries = {}
        for _, involved in ipairs(reportData.involved) do
            if involved.type == 'suspect' and involved.citizenid then
                table.insert(arrestQueries, {
                    query = [[
                        INSERT INTO mdt_arrests (reportid, citizenid, officer_citizenid, officer_name)
                        VALUES (?, ?, ?, ?)
                    ]],
                    values = { reportId, involved.citizenid, officerId, officerName }
                })
            end
        end
        if #arrestQueries > 0 then
            MySQL.transaction.await(arrestQueries)
            if ps.auditLog then
                for _, involved in ipairs(reportData.involved) do
                    if involved.type == 'suspect' and involved.citizenid then
                        ps.auditLog(src, 'arrest_logged', 'arrest', reportId, {
                            citizenid = involved.citizenid,
                            reportId = reportId
                        })
                    end
                end
            end
        end
    end

    -- For "Mandado Judicial" reports, auto-create warrants for all suspects
    if reportId and reportType == 'Mandado Judicial' and reportData.involved and #reportData.involved > 0 then
        for _, involved in ipairs(reportData.involved) do
            if involved.citizenid and (involved.type == 'suspect' or involved.type == 'Primary') then
                warrantCitizenIds[involved.citizenid] = true
            end
        end
    end

    if reportId and next(warrantCitizenIds) ~= nil then
        local defaultDays = (Config and Config.Warrants and Config.Warrants.DefaultExpiryDays) or 7
        local expiryDate = os.date('%Y-%m-%d %H:%M:%S', os.time() + (defaultDays * 24 * 60 * 60))
        local warrantQueries = {}
        for citizenid, _ in pairs(warrantCitizenIds) do
            table.insert(warrantQueries, {
                query = [[
                    INSERT INTO mdt_reports_warrants (reportid, citizenid, felonies, misdemeanors, infractions, expirydate)
                    VALUES (?, ?, 0, 0, 0, ?)
                    ON DUPLICATE KEY UPDATE expirydate = VALUES(expirydate)
                ]],
                values = { reportId, citizenid, expiryDate }
            })
        end
        MySQL.transaction.await(warrantQueries)
    end

    Cache.invalidatePrefix('reports:analytics:')

    if ps.auditLog then
        local action = reportId and reportData.report and reportData.report.id and 'report_updated' or 'report_created'
        ps.auditLog(src, action, 'report', reportId, {
            title = title,
            type = reportType
        })
    end

    Cache.invalidate('dashboard:reportStats')
    Cache.invalidate('dashboard:usageMetrics')
    return {
        success = true,
        reportId = reportId,
        message = reportId and "Report updated successfully" or "Report created successfully"
    }
end)

ps.registerCallback(resourceName..':server:updateReportContent', function(source, reportid, content, reportData)
    local src = source
    if not CheckAuth(src) then return { success = false, error = "Não autorizado" } end

    if not content then
        return { success = false, error = "Missing content" }
    end

    local reportId = reportid and tonumber(reportid) or nil
    local title = (reportData and reportData.title) or "Rascunho de Relatório"
    local reportType = (reportData and reportData.type) or "Incident Report"

    local identifier = ps.getIdentifier(src)
    local playerName = ps.getPlayerName(src)
    local callsign = normalizeCallsignValue(ps.getMetadata(src, 'callsign'))

    if not identifier then return { success = false, error = "Player not found" } end

    if reportData and reportData.dateupdated and reportId then
        local expectedDateUpdated = reportTimestampToSql(reportData.dateupdated)
        if expectedDateUpdated then
            local isCurrent = MySQL.scalar.await([[
                SELECT COUNT(*)
                FROM mdt_reports
                WHERE id = ?
                  AND DATE_FORMAT(dateupdated, '%Y-%m-%d %H:%i:%s') = ?
            ]], { reportId, expectedDateUpdated })
            if tonumber(isCurrent) == 0 then
                return { success = false, error = 'Conflito de edição detectado. Reabra o relatório antes de salvar.', conflict = true }
            end
        end
    end

    if reportId then
        if not checkReportAccess(src, reportId) then
            return { success = false, error = "Report not found or access denied" }
        end
        if not canEditReports(src) then
            return { success = false, error = 'Sem permissão para editar relatório' }
        end
    elseif not canCreateReports(src) then
        return { success = false, error = 'Sem permissão para criar relatório' }
    end

    if not reportId then
        local insertResult = MySQL.insert.await([[
            INSERT INTO mdt_reports (title, type, contentyjs, contentplaintext, author, authorplaintext)
            VALUES (?, ?, ?, ?, ?, ?)
        ]], {
            title,
            reportType,
            json.encode(content),
            type(content) == "string" and content or json.encode(content),
            identifier,
            formatOfficerDisplayName(callsign, playerName)
        })

        if not insertResult then
            return { success = false, error = "Failed to save content" }
        end

        MySQL.update.await([[
            UPDATE mdt_reports
            SET report_status = ?, requires_approval = ?
            WHERE id = ?
        ]], {
            canApproveReports(src) and 'approved' or 'pending_review',
            canApproveReports(src) and 0 or 1,
            insertResult
        })

        return {
            success = true,
            reportId = insertResult,
            message = "Conteúdo salvo com sucesso",
            isNewReport = true
        }
    end

    local updateSuccess = MySQL.update.await([[
        UPDATE mdt_reports
        SET contentyjs = ?, contentplaintext = ?, dateupdated = CURRENT_TIMESTAMP
        WHERE id = ?
    ]], {
        json.encode(content),
        type(content) == "string" and content or json.encode(content),
        reportId
    })

    if updateSuccess and updateSuccess > 0 then
        return {
            success = true,
            reportId = reportId,
            message = "Conteúdo salvo com sucesso",
            isNewReport = false
        }
    end

    return { success = false, error = "Failed to save content" }
end)

ps.registerCallback(resourceName..':server:deleteReport', function(source, reportId)
    local src = source
    if not CheckAuth(src) then return end

    reportId = tonumber(reportId)
    if not reportId then
        return { success = false, error = "Missing/Invalid report ID" }
    end
    if not canDeleteReports(src) then
        return { success = false, error = 'Sem permissão para excluir relatório' }
    end

    local playerName = ps.getPlayerName(src)

    if not checkReportAccess(src, reportId) then
        ps.notify(src, 'Falha ao excluir o relatório: não encontrado ou sem acesso', 'error')
        ps.warn(('[Failed to delete] Player [%s] %s tried to delete a report (%s), but it was not found or they do not have access.')
            :format(src, playerName, reportId))
        return { success = false, error = "Report not found or access denied" }
    end

    local reportInfo = MySQL.query.await("SELECT title FROM mdt_reports WHERE id = ?", { reportId })
    local reportTitle = reportInfo and reportInfo[1] and reportInfo[1].title or "Desconhecido"

    local success = MySQL.query.await("DELETE FROM mdt_reports WHERE id = ?", { reportId })

    if success then
        Cache.invalidate('dashboard:reportStats')
        Cache.invalidate('dashboard:usageMetrics')
        ps.notify(src, 'Relatório excluído com sucesso', 'success')
        ps.debug(('[Report Deleted] Player [%s] %s successfully deleted report (%s): "%s"')
            :format(src, playerName, reportId, reportTitle))

        if ps.auditLog then
            ps.auditLog(src, 'report_deleted', 'report', reportId, {
                title = reportTitle
            })
        end

        return {
            success = true,
            message = "Relatório excluído com sucesso",
            reportId = reportId
        }
    else
        ps.notify(src, 'Falha ao excluir o relatório', 'error')
        ps.warn(('[Failed to delete] Player [%s] %s tried to delete report (%s). Database query failed.')
            :format(src, playerName, reportId))

        return {
            success = false,
            error = "Falha ao excluir o relatório from database"
        }
    end
end)

ps.registerCallback(resourceName .. ':server:approveReport', function(source, reportId)
    local src = source
    if not CheckAuth(src) then return { success = false, error = 'Não autorizado' } end
    if not canApproveReports(src) then return { success = false, error = 'Sem permissão para aprovar relatório' } end

    reportId = tonumber(reportId)
    if not reportId then return { success = false, error = 'Relatório inválido' } end
    if not checkReportAccess(src, reportId) then return { success = false, error = 'Sem acesso ao relatório' } end

    local actor = ps.getIdentifier(src)
    MySQL.update.await([[
        UPDATE mdt_reports
        SET report_status = 'approved',
            requires_approval = 0,
            approved_by = ?,
            approved_at = CURRENT_TIMESTAMP
        WHERE id = ?
    ]], { actor, reportId })

    if ps.auditLog then
        ps.auditLog(src, 'report_approved', 'report', reportId, {})
    end

    return { success = true, reportId = reportId }
end)

ps.registerCallback(resourceName .. ':server:signReport', function(source, reportId)
    local src = source
    if not CheckAuth(src) then return { success = false, error = 'Não autorizado' } end
    if not canSignReports(src) then return { success = false, error = 'Sem permissão para assinar relatório' } end

    reportId = tonumber(reportId)
    if not reportId then return { success = false, error = 'Relatório inválido' } end
    if not checkReportAccess(src, reportId) then return { success = false, error = 'Sem acesso ao relatório' } end

    local actor = ps.getIdentifier(src)
    local signatureHash = buildDigitalSignature(actor, reportId, os.time())
    MySQL.update.await([[
        UPDATE mdt_reports
        SET signed_by = ?, signed_at = CURRENT_TIMESTAMP, signature_hash = ?
        WHERE id = ?
    ]], { actor, signatureHash, reportId })

    if ps.auditLog then
        ps.auditLog(src, 'report_signed', 'report', reportId, { signatureHash = signatureHash })
    end

    return { success = true, reportId = reportId, signatureHash = signatureHash }
end)

ps.registerCallback(resourceName .. ':server:archiveReport', function(source, reportId)
    local src = source
    if not CheckAuth(src) then return { success = false, error = 'Não autorizado' } end
    if not canArchiveReports(src) then return { success = false, error = 'Sem permissão para arquivar relatório' } end

    reportId = tonumber(reportId)
    if not reportId then return { success = false, error = 'Relatório inválido' } end
    if not checkReportAccess(src, reportId) then return { success = false, error = 'Sem acesso ao relatório' } end

    local actor = ps.getIdentifier(src)
    MySQL.update.await([[
        UPDATE mdt_reports
        SET report_status = 'archived', archived_by = ?, archived_at = CURRENT_TIMESTAMP
        WHERE id = ?
    ]], { actor, reportId })

    if ps.auditLog then
        ps.auditLog(src, 'report_archived', 'report', reportId, {})
    end

    return { success = true, reportId = reportId }
end)

ps.registerCallback(resourceName .. ':server:unarchiveReport', function(source, reportId)
    local src = source
    if not CheckAuth(src) then return { success = false, error = 'Não autorizado' } end
    if not canUnarchiveReports(src) then return { success = false, error = 'Sem permissão para desarquivar relatório' } end

    reportId = tonumber(reportId)
    if not reportId then return { success = false, error = 'Relatório inválido' } end
    if not checkReportAccess(src, reportId) then return { success = false, error = 'Sem acesso ao relatório' } end

    local actor = ps.getIdentifier(src)
    MySQL.update.await([[
        UPDATE mdt_reports
        SET report_status = 'approved',
            archived_by = NULL,
            archived_at = NULL,
            unarchived_by = ?,
            unarchived_at = CURRENT_TIMESTAMP
        WHERE id = ?
    ]], { actor, reportId })

    if ps.auditLog then
        ps.auditLog(src, 'report_unarchived', 'report', reportId, {})
    end

    return { success = true, reportId = reportId }
end)

ps.registerCallback(resourceName..':server:getAvailableTags', function(source, playerJobType)
    local src = source
    if not CheckAuth(src) then return {} end
    EnsureMdtSchema()

    local jt = playerJobType or 'leo'

    -- Pull from master mdt_tags table (report + both types) filtered by job_type
    local tags = MySQL.query.await([[
        SELECT t.name, t.color,
               (SELECT COUNT(*) FROM mdt_reports_tags rt WHERE rt.tag = t.name) AS usage_count
        FROM mdt_tags t
        WHERE t.type IN ('report', 'both')
          AND (t.job_type = ? OR t.job_type = 'all')
        ORDER BY t.name ASC
    ]], { jt })

    return tags or {}
end)

ps.registerCallback(resourceName..':server:generateReportId', function(source)
    local src = source
    if not CheckAuth(src) then return end

    return {
        success = true,
        reportId = nil
    }
end)

ps.registerCallback(resourceName..':server:getReportAnalytics', function(source, filters)
    local src = source
    if not CheckAuth(src) then return { success = false, error = "Não autorizado" } end

    local identifier = ps.getIdentifier(src)
    local job = ps.getJobName(src)
    local jobType = ps.getJobType(src)

    local filterClause, filterValues = buildReportFilterClause(filters)
    filterClause = filterClause or ''

	local accessClause = buildReportAccessClause()
    local cacheKeyParts = {
        identifier or '',
        job or '',
        jobType or '',
        filters and tostring(filters.startDate) or '',
        filters and tostring(filters.endDate) or '',
        filters and tostring(filters.author) or '',
    }
    local cacheKey = 'reports:analytics:' .. table.concat(cacheKeyParts, '|')

    local cached = Cache.get(cacheKey)
    if cached then
        return { success = true, data = cached }
    end

	local incidentQuery = ([[
        SELECT COUNT(*) AS total
        FROM mdt_reports AS mr
        LEFT JOIN mdt_reports_restrictions AS mrr ON mr.id = mrr.reportid
        WHERE %s%s
          AND mr.type = 'Incident Report'
	]]):format(accessClause, filterClause)
	local incidentParams = { jobType, identifier, job, jobType }
	for _, value in ipairs(filterValues or {}) do
		incidentParams[#incidentParams + 1] = value
	end
	local incidentRow = MySQL.single.await(incidentQuery, incidentParams)

	local arrestQuery = ([[
        SELECT COUNT(*) AS total
        FROM mdt_arrests AS ma
        INNER JOIN mdt_reports AS mr ON mr.id = ma.reportid
        LEFT JOIN mdt_reports_restrictions AS mrr ON mr.id = mrr.reportid
        WHERE %s%s
	]]):format(accessClause, filterClause)
	local arrestParams = { jobType, identifier, job, jobType }
	for _, value in ipairs(filterValues or {}) do
		arrestParams[#arrestParams + 1] = value
	end
	local arrestRow = MySQL.single.await(arrestQuery, arrestParams)

	local warrantQuery = ([[
        SELECT COUNT(*) AS total
        FROM mdt_reports_warrants AS mw
        INNER JOIN mdt_reports AS mr ON mr.id = mw.reportid
        LEFT JOIN mdt_reports_restrictions AS mrr ON mr.id = mrr.reportid
        WHERE %s%s
          AND mw.expirydate >= NOW()
	]]):format(accessClause, filterClause)
	local warrantParams = { jobType, identifier, job, jobType }
	for _, value in ipairs(filterValues or {}) do
		warrantParams[#warrantParams + 1] = value
	end
	local warrantRow = MySQL.single.await(warrantQuery, warrantParams)

    local data = {
        incidents = tonumber(incidentRow and incidentRow.total) or 0,
        arrests = tonumber(arrestRow and arrestRow.total) or 0,
        warrants = tonumber(warrantRow and warrantRow.total) or 0,
    }

    Cache.set(cacheKey, data, 15)

    return {
        success = true,
        data = data
    }
end)

ps.registerCallback(resourceName .. ':server:getReportsByPlate', function(source, plate)
    local src = source
    if not CheckAuth(src) then return {} end

    if not plate or plate == '' then
        return {}
    end

    local rows = MySQL.query.await([[
        SELECT
            mr.id,
            mr.title,
            mr.type,
            mr.datecreated,
            mr.authorplaintext
        FROM mdt_report_vehicles mrv
        INNER JOIN mdt_reports mr ON mr.id = mrv.reportid
        WHERE mrv.plate = ?
        ORDER BY mr.datecreated DESC
        LIMIT 20
    ]], { plate })

    return rows or {}
end)
