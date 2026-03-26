local resourceName = tostring(GetCurrentResourceName())
local CITIZEN_LIST_CACHE_PREFIX = 'citizens:list:'
local CITIZEN_SEARCH_CACHE_PREFIX = 'citizens:search:'
local CITIZEN_CACHE_TTL = 8

local function buildInClause(values)
    local placeholders = {}
    for i = 1, #values do
        placeholders[i] = '?'
    end
    return table.concat(placeholders, ',')
end

local function hasTable(tableName)
    return type(MdtTableExists) == 'function' and MdtTableExists(tableName) or false
end

local function getVehicleTableName()
    if hasTable('player_vehicles') then
        return 'player_vehicles'
    end
    if hasTable('vehicles') then
        return 'vehicles'
    end
    return nil
end

local function buildVehicleOwnerExpr(tableName)
    local parts = {}
    if type(MdtColumnExists) == 'function' and MdtColumnExists(tableName, 'citizenid') then
        parts[#parts + 1] = "NULLIF(citizenid, '')"
    end
    if type(MdtColumnExists) == 'function' and MdtColumnExists(tableName, 'owner') then
        parts[#parts + 1] = "NULLIF(owner, '')"
    end
    if type(MdtColumnExists) == 'function' and MdtColumnExists(tableName, 'owner_citizenid') then
        parts[#parts + 1] = "NULLIF(owner_citizenid, '')"
    end
    if #parts == 0 then
        return "NULL"
    end
    return 'COALESCE(' .. table.concat(parts, ', ') .. ')'
end

local function queryCitizenProperties(inClause, citizenids)
    if not hasTable('player_houses') then
        return {}
    end

    return MySQL.query.await(
        ('SELECT citizenid, COUNT(*) AS cnt FROM player_houses WHERE citizenid IN (%s) GROUP BY citizenid'):format(inClause),
        citizenids
    ) or {}
end

local function queryCitizenPropertyList(citizenid)
    if not hasTable('player_houses') then
        return {}
    end

    return MySQL.query.await('SELECT house FROM player_houses WHERE citizenid = ?', { citizenid }) or {}
end

local function collectCitizenFlags(citizenids)
    EnsureMdtSchema()
    local flagsByCid = {}
    if not citizenids or #citizenids == 0 then
        return flagsByCid
    end

    for i = 1, #citizenids do
        flagsByCid[citizenids[i]] = {}
    end

    local inClause = buildInClause(citizenids)

    local warrantRows = MySQL.query.await(([[
        SELECT citizenid
        FROM mdt_reports_warrants
        WHERE expirydate >= NOW()
        AND citizenid IN (%s)
        GROUP BY citizenid
    ]]):format(inClause), citizenids)

    for _, row in ipairs(warrantRows or {}) do
        if row.citizenid then
            flagsByCid[row.citizenid] = flagsByCid[row.citizenid] or {}
            table.insert(flagsByCid[row.citizenid], 'Active Warrant')
        end
    end

    local boloValues = { 'citizen', 'active' }
    for i = 1, #citizenids do
        boloValues[#boloValues + 1] = citizenids[i]
    end

    local boloRows = MySQL.query.await(([[
        SELECT subject_id
        FROM mdt_bolos
        WHERE type = ? AND status = ?
        AND subject_id IN (%s)
    ]]):format(inClause), boloValues)

    local boloSeen = {}
    for _, row in ipairs(boloRows or {}) do
        if row.subject_id and not boloSeen[row.subject_id] then
            boloSeen[row.subject_id] = true
            flagsByCid[row.subject_id] = flagsByCid[row.subject_id] or {}
            table.insert(flagsByCid[row.subject_id], 'Procurado Ativo')
        end
    end

    return flagsByCid
end

local function getGender(gen)
    if gen == 0 then
        return 'Masculino'
    elseif gen == 1 then
        return 'Feminino'
    end
    return 'Desconhecido'
end

local function normalizeSearchQuery(raw)
    local query = tostring(raw or ''):gsub('^%s*(.-)%s*$', '%1')
    if query == '' then
        return nil
    end
    return query
end

local function buildSearchLike(search)
    local escaped = search
        :gsub('\\', '\\\\')
        :gsub('%%', '\\%%')
        :gsub('_', '\\_')
    return '%' .. escaped:lower() .. '%'
end

-- getCitizens - pulls citizens from database with pagination support
ps.registerCallback(resourceName .. ':server:getCitizens', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { citizens = {}, page = 1, limit = 20, total = 0, hasMore = false } end
    local startTime = os.clock()

    local page = 1
    local limit = Config.Pagination and Config.Pagination.Citizens or 20
    if type(payload) == 'table' then
        page = tonumber(payload.page or payload.currentPage) or 1
        limit = tonumber(payload.limit) or limit
    else
        page = tonumber(payload) or 1
    end

    page = math.max(1, page)
    limit = math.min(math.max(1, limit), 100)
    local offset = (page - 1) * limit
    local cacheKey = ('%s%s:%s'):format(CITIZEN_LIST_CACHE_PREFIX, page, limit)

    local cached = Cache.get(cacheKey)
    if cached then
        return cached
    end

    local total = MySQL.scalar.await('SELECT COUNT(*) FROM players') or 0

    local query = [[
        SELECT mp.id, p.citizenid, JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')) AS firstname,
        JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname')) AS lastname,
        JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.gender')) AS gender,
        JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.birthdate')) AS dateofbirth,
        JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.phone')) AS phone,
        JSON_UNQUOTE(JSON_EXTRACT(p.job, '$.label')) AS job
        FROM players AS p
        LEFT JOIN mdt_profiles AS mp
        ON CONVERT(p.citizenid USING utf8mb4) COLLATE utf8mb4_general_ci = CONVERT(mp.citizenid USING utf8mb4) COLLATE utf8mb4_general_ci
        ORDER BY p.citizenid ASC
        LIMIT ? OFFSET ?
    ]]
    local result = MySQL.query.await(query, { limit, offset })

    local citizenids = {}
    for _, v in ipairs(result) do
        if v.citizenid then
            citizenids[#citizenids + 1] = v.citizenid
        end
    end
    local flagsByCid = collectCitizenFlags(citizenids)

    -- Batch fetch profile pictures, property counts, vehicle counts, and arrest counts
    local profilePics = {}
    local propCounts = {}
    local vehCounts = {}
    local arrestCounts = {}

    if #citizenids > 0 then
        local inClause = buildInClause(citizenids)

        local profileRows = MySQL.query.await(
            ('SELECT citizenid, profilepicture FROM mdt_profiles WHERE citizenid IN (%s)'):format(inClause),
            citizenids
        )
        for _, row in ipairs(profileRows or {}) do
            if row.profilepicture and row.profilepicture ~= '' then
                profilePics[row.citizenid] = row.profilepicture
            end
        end

        local propRows = queryCitizenProperties(inClause, citizenids)
        for _, row in ipairs(propRows or {}) do
            propCounts[row.citizenid] = tonumber(row.cnt) or 0
        end

        local vehicleTable = getVehicleTableName()
        local vehRows = {}
        if vehicleTable then
            local ownerExpr = buildVehicleOwnerExpr(vehicleTable)
            vehRows = MySQL.query.await(
                ('SELECT %s AS owner_cid, COUNT(*) AS cnt FROM %s WHERE %s IN (%s) GROUP BY owner_cid'):format(ownerExpr, vehicleTable, ownerExpr, inClause),
                citizenids
            ) or {}
        end
        for _, row in ipairs(vehRows or {}) do
            vehCounts[row.owner_cid] = tonumber(row.cnt) or 0
        end

        local arrestRows = MySQL.query.await(
            ('SELECT citizenid, COUNT(*) AS cnt FROM mdt_arrests WHERE citizenid IN (%s) GROUP BY citizenid'):format(inClause),
            citizenids
        )
        for _, row in ipairs(arrestRows or {}) do
            arrestCounts[row.citizenid] = tonumber(row.cnt) or 0
        end
    end

    for _, v in ipairs(result) do
        v.id = _
        v.cid = v.citizenid
        v.firstName = v.firstname
        v.lastName = v.lastname
        v.gender = getGender(tonumber(v.gender))
        v.dob = v.dateofbirth
        v.phone = v.phone
        v.image = profilePics[v.citizenid] or nil
        v.occupations = { v.job }
        v.properties = propCounts[v.citizenid] or 0
        v.vehicles = vehCounts[v.citizenid] or 0
        v.arrests = arrestCounts[v.citizenid] or 0
        v.flags = flagsByCid[v.citizenid] or {}
    end
    local endTime = os.clock()
    local elapsedTime = (endTime - startTime) * 1000
    ps.debug(string.format("getCitizens callback executed in %.2f ms for page %d", elapsedTime, page))

    if result[1] then
        ps.debug('[getCitizens] Sample citizen data structure:', result[1])
    end

    local response = {
        citizens = result,
        page = page,
        limit = limit,
        total = tonumber(total) or 0,
        hasMore = (offset + #result) < (tonumber(total) or 0)
    }

    Cache.set(cacheKey, response, CITIZEN_CACHE_TTL)
    return response
end)

-- searchPlayers - searches the database for citizens by provided query (first/last name, citizenid, phone number, occupation)
-- Returns the same data structure as getCitizens but filtered by search query
ps.registerCallback(resourceName .. ':server:searchCitizens', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { citizens = {}, page = 1, limit = 20, total = 0, hasMore = false } end
    local startTime = os.clock()

    if type(payload) ~= 'table' then
        payload = { query = payload }
    end

    local query = normalizeSearchQuery(payload.query)
    local page = math.max(1, tonumber(payload.page) or 1)
    local searchLimit = math.min(math.max(1, tonumber(payload.limit) or (Config.Pagination and Config.Pagination.CitizenSearch or 20)), 100)
    local offset = (page - 1) * searchLimit

    if not query or string.len(query) < 2 then
        return { citizens = {}, page = page, limit = searchLimit, total = 0, hasMore = false }
    end

    if ps.auditLog then
        ps.auditLog(src, 'search_citizens', 'search', nil, {
            query = query
        })
    end

    -- Sanitize the query for SQL LIKE operations
    local searchTerm = buildSearchLike(query)

    -- Build a complex search query that searches across multiple fields and returns same data as getCitizens
    local sqlQuery = [[
        SELECT DISTINCT
            mp.id,
            p.citizenid,
            JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')) AS firstname,
            JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname')) AS lastname,
            JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.gender')) AS gender,
            JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.birthdate')) AS dateofbirth,
            JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.phone')) AS phone,
            JSON_UNQUOTE(JSON_EXTRACT(p.job, '$.label')) AS job
        FROM players AS p
        LEFT JOIN mdt_profiles AS mp ON p.citizenid COLLATE utf8mb4_general_ci = mp.citizenid COLLATE utf8mb4_general_ci
        WHERE 
            LOWER(JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname'))) LIKE ? ESCAPE '\\' OR
            LOWER(JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname'))) LIKE ? ESCAPE '\\' OR
            LOWER(CONCAT(JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')), ' ', JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname')))) LIKE ? ESCAPE '\\' OR
            LOWER(p.citizenid) LIKE ? ESCAPE '\\' OR
            LOWER(JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.phone'))) LIKE ? ESCAPE '\\' OR
            LOWER(JSON_UNQUOTE(JSON_EXTRACT(p.job, '$.label'))) LIKE ? ESCAPE '\\'
        ORDER BY p.citizenid ASC
        LIMIT ?
    ]]

    local cacheKey = ('%s%s:%s:%s'):format(CITIZEN_SEARCH_CACHE_PREFIX, query:lower(), page, searchLimit)
    local cached = Cache.get(cacheKey)
    if cached then
        return cached
    end

    local countQuery = [[
        SELECT COUNT(*)
        FROM players AS p
        WHERE
            LOWER(JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname'))) LIKE ? ESCAPE '\\' OR
            LOWER(JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname'))) LIKE ? ESCAPE '\\' OR
            LOWER(CONCAT(JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')), ' ', JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname')))) LIKE ? ESCAPE '\\' OR
            LOWER(p.citizenid) LIKE ? ESCAPE '\\' OR
            LOWER(JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.phone'))) LIKE ? ESCAPE '\\' OR
            LOWER(JSON_UNQUOTE(JSON_EXTRACT(p.job, '$.label'))) LIKE ? ESCAPE '\\'
    ]]
    local total = MySQL.scalar.await(countQuery, { searchTerm, searchTerm, searchTerm, searchTerm, searchTerm, searchTerm }) or 0

    local result = MySQL.query.await(sqlQuery .. ' OFFSET ?', {
        searchTerm, searchTerm, searchTerm, searchTerm, searchTerm, searchTerm, searchLimit, offset
    })

    -- Process results to match getCitizens format exactly
    local citizenids = {}
    for _, v in ipairs(result) do
        if v.citizenid then
            citizenids[#citizenids + 1] = v.citizenid
        end
    end
    local flagsByCid = collectCitizenFlags(citizenids)

    -- Batch fetch profile pictures, property counts, vehicle counts, and arrest counts
    local profilePics = {}
    local propCounts = {}
    local vehCounts = {}
    local arrestCounts = {}

    if #citizenids > 0 then
        local inClause = buildInClause(citizenids)

        local profileRows = MySQL.query.await(
            ('SELECT citizenid, profilepicture FROM mdt_profiles WHERE citizenid IN (%s)'):format(inClause),
            citizenids
        )
        for _, row in ipairs(profileRows or {}) do
            if row.profilepicture and row.profilepicture ~= '' then
                profilePics[row.citizenid] = row.profilepicture
            end
        end

        local propRows = queryCitizenProperties(inClause, citizenids)
        for _, row in ipairs(propRows or {}) do
            propCounts[row.citizenid] = tonumber(row.cnt) or 0
        end

        local vehicleTable = getVehicleTableName()
        local vehRows = {}
        if vehicleTable then
            local ownerExpr = buildVehicleOwnerExpr(vehicleTable)
            vehRows = MySQL.query.await(
                ('SELECT %s AS owner_cid, COUNT(*) AS cnt FROM %s WHERE %s IN (%s) GROUP BY owner_cid'):format(ownerExpr, vehicleTable, ownerExpr, inClause),
                citizenids
            ) or {}
        end
        for _, row in ipairs(vehRows or {}) do
            vehCounts[row.owner_cid] = tonumber(row.cnt) or 0
        end

        local arrestRows = MySQL.query.await(
            ('SELECT citizenid, COUNT(*) AS cnt FROM mdt_arrests WHERE citizenid IN (%s) GROUP BY citizenid'):format(inClause),
            citizenids
        )
        for _, row in ipairs(arrestRows or {}) do
            arrestCounts[row.citizenid] = tonumber(row.cnt) or 0
        end
    end

    for _, v in ipairs(result) do
        v.id = _
        v.cid = v.citizenid
        v.firstName = v.firstname
        v.lastName = v.lastname
        v.gender = getGender(tonumber(v.gender))
        v.dob = v.dateofbirth
        v.phone = v.phone
        v.image = profilePics[v.citizenid] or nil
        v.occupations = { v.job }
        v.properties = propCounts[v.citizenid] or 0
        v.vehicles = vehCounts[v.citizenid] or 0
        v.arrests = arrestCounts[v.citizenid] or 0
        v.flags = flagsByCid[v.citizenid] or {}
    end

    local endTime = os.clock()
    local elapsedTime = (endTime - startTime) * 1000
    ps.debug(string.format("searchCitizens callback executed in %.2f ms for query: %s", elapsedTime, query))

    if result[1] then
        ps.debug('[searchCitizens] Sample citizen data structure:', result[1])
    end

    local response = {
        citizens = result,
        page = page,
        limit = searchLimit,
        total = tonumber(total) or 0,
        hasMore = (offset + #result) < (tonumber(total) or 0)
    }

    Cache.set(cacheKey, response, CITIZEN_CACHE_TTL)
    return response
end)

-- getCitizenBOLOs - gets active BOLOs by type, probably have a table of active bolos load on script start and use that then save it to db periodically or on resource stop
ps.registerCallback(resourceName .. ':server:getBOLO', function(source, boloType, boloStatus)
    local src = source
    if not CheckAuth(src) then return {} end
    boloType = boloType or 'citizen'
    boloStatus = boloStatus or 'active'
    local BOLOS
    if boloType == 'all' then
        if boloStatus == 'all' then
            BOLOS = MySQL.query.await('SELECT * FROM mdt_bolos ORDER BY id DESC', {})
        else
            BOLOS = MySQL.query.await('SELECT * FROM mdt_bolos WHERE status = ? ORDER BY id DESC', { boloStatus })
        end
    else
        if boloStatus == 'all' then
            BOLOS = MySQL.query.await('SELECT * FROM mdt_bolos WHERE type = ? ORDER BY id DESC', { boloType })
        else
            BOLOS = MySQL.query.await('SELECT * FROM mdt_bolos WHERE type = ? AND status = ? ORDER BY id DESC', { boloType, boloStatus })
        end
    end

    local result = {}
    for k, v in pairs(BOLOS) do
        local formattedBolo = {
            id = v.id,
            reportId = v.reportId and tostring(v.reportId) or 'N/A',
            name = v.subject_name or ps.getPlayerNameByIdentifier(v.subject_id) or 'Desconhecido',
            type = v.type,
            notes = v.notes or '',
            status = v.status,
        }
        table.insert(result, formattedBolo)
    end
    ps.debug('Fetched ' .. #result .. ' ' .. boloType .. ' BOLOs from database for source ' .. src, result)
    return result
end)

ps.registerCallback(resourceName .. ':server:getCitizenProfile', function(source, citizenid)
    local src = source
    if not CheckAuth(src) then return end

    if not citizenid or citizenid == '' then
        return { success = false, message = 'Faltando ID do cidadão' }
    end

    local playerRow = MySQL.single.await([[
        SELECT
            p.citizenid,
            JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')) AS firstname,
            JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname')) AS lastname,
            JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.gender')) AS gender,
            JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.birthdate')) AS dateofbirth,
            JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.phone')) AS phone,
            p.job,
            p.metadata
        FROM players AS p
        WHERE p.citizenid = ?
        LIMIT 1
    ]], { citizenid })

    if not playerRow then
        return { success = false, message = 'Cidadão não encontrado' }
    end

    local profileRow = MySQL.single.await('SELECT id, profilepicture, notes FROM mdt_profiles WHERE citizenid = ?', { citizenid })

    -- Fetch tags and gallery for this profile
    local profileTags = {}
    local profileGallery = {}
    if profileRow and profileRow.id then
        local tagRows = MySQL.query.await('SELECT tag FROM mdt_profiles_tags WHERE profileId = ?', { profileRow.id })
        for _, row in ipairs(tagRows or {}) do
            profileTags[#profileTags + 1] = row.tag
        end
        local galleryRows = MySQL.query.await('SELECT image, label, datecreated FROM mdt_profiles_gallery WHERE profileId = ? ORDER BY datecreated DESC', { profileRow.id })
        for _, row in ipairs(galleryRows or {}) do
            profileGallery[#profileGallery + 1] = { image = row.image, label = row.label, datecreated = row.datecreated }
        end
    end
    local occupations = {}
    if playerRow and playerRow.job then
        local ok, decoded = pcall(json.decode, playerRow.job)
        if ok and decoded then
            if decoded.label then
                occupations[#occupations + 1] = decoded.label
            elseif decoded.name then
                occupations[#occupations + 1] = decoded.name
            end
        end
    end
    local flags = collectCitizenFlags({ citizenid })
    local vehicleTable = getVehicleTableName()
    local vehicles = {}
    if vehicleTable then
        local ownerExpr = buildVehicleOwnerExpr(vehicleTable)
        vehicles = MySQL.query.await(
            ('SELECT plate, COALESCE(NULLIF(vehicle, \'\'), NULLIF(JSON_UNQUOTE(JSON_EXTRACT(vehicle, \'$.model\')), \'\'), \'unknown\') AS vehicle FROM %s WHERE %s = ?'):format(vehicleTable, ownerExpr),
            { citizenid }
        ) or {}
    end
    local vehiclesCount = #vehicles
    local properties = queryCitizenPropertyList(citizenid)
    local propertiesCount = #properties
    local arrestsCount = MySQL.scalar.await('SELECT COUNT(*) FROM mdt_arrests WHERE citizenid = ?', { citizenid }) or 0
    local activeWarrants = MySQL.query.await([[
        SELECT reportid, expirydate
        FROM mdt_reports_warrants
        WHERE citizenid = ? AND expirydate >= NOW()
        ORDER BY expirydate ASC
    ]], { citizenid }) or {}
    local activeBolos = MySQL.query.await([[
        SELECT id, reportId, type, notes
        FROM mdt_bolos
        WHERE status = ? AND subject_id = ?
        ORDER BY id DESC
    ]], { 'active', citizenid }) or {}
    local activeBoloDetails = {}
    for _, bolo in ipairs(activeBolos) do
        activeBoloDetails[#activeBoloDetails + 1] = {
            id = bolo.id,
            reportId = bolo.reportId and tostring(bolo.reportId) or 'N/A',
            type = bolo.type,
            notes = bolo.notes or ''
        }
    end

    local involvedReportIds = {}
    local reportIdSet = {}
    local involvedReports = MySQL.query.await([[
        SELECT reportid
        FROM mdt_reports_involved
        WHERE citizenid = ?
    ]], { citizenid }) or {}
    for _, row in ipairs(involvedReports) do
        local reportId = tonumber(row.reportid)
        if reportId and not reportIdSet[reportId] then
            reportIdSet[reportId] = true
            involvedReportIds[#involvedReportIds + 1] = reportId
        end
    end
    local chargedReports = MySQL.query.await([[
        SELECT reportid
        FROM mdt_reports_charges
        WHERE citizenid = ?
    ]], { citizenid }) or {}
    for _, row in ipairs(chargedReports) do
        local reportId = tonumber(row.reportid)
        if reportId and not reportIdSet[reportId] then
            reportIdSet[reportId] = true
            involvedReportIds[#involvedReportIds + 1] = reportId
        end
    end

    local caseIds = {}
    local caseIdSet = {}
    if #involvedReportIds > 0 then
        local placeholders = (string.rep('?,', #involvedReportIds)):sub(1, -2)
        local caseRows = MySQL.query.await(
            ('SELECT case_id FROM mdt_case_reports WHERE report_id IN (%s)'):format(placeholders),
            involvedReportIds
        ) or {}
        for _, row in ipairs(caseRows) do
            local caseId = tonumber(row.case_id)
            if caseId and not caseIdSet[caseId] then
                caseIdSet[caseId] = true
                caseIds[#caseIds + 1] = caseId
            end
        end
    end

    local evidence = {}
    if #involvedReportIds > 0 or #caseIds > 0 then
        local clauses = {}
        local params = {}
        if #involvedReportIds > 0 then
            clauses[#clauses + 1] = ('report_id IN (%s)'):format((string.rep('?,', #involvedReportIds)):sub(1, -2))
            for _, value in ipairs(involvedReportIds) do
                params[#params + 1] = value
            end
        end
        if #caseIds > 0 then
            clauses[#clauses + 1] = ('case_id IN (%s)'):format((string.rep('?,', #caseIds)):sub(1, -2))
            for _, value in ipairs(caseIds) do
                params[#params + 1] = value
            end
        end
        local evidenceQuery = 'SELECT id, case_id, report_id, title, type, serial, notes, location, created_at FROM mdt_evidence_items WHERE ' .. table.concat(clauses, ' OR ') .. ' ORDER BY created_at DESC'
        evidence = MySQL.query.await(evidenceQuery, params) or {}
    end

    local weapons = MySQL.query.await([[
        SELECT id, serial, scratched, owner, information, weaponClass, weaponModel
        FROM mdt_weapons
        WHERE owner = ?
        ORDER BY id DESC
    ]], { citizenid }) or {}

    local linkedReports = {}
    if #involvedReportIds > 0 then
        local placeholders = (string.rep('?,', #involvedReportIds)):sub(1, -2)
        linkedReports = MySQL.query.await(
            ('SELECT id, title, type, datecreated FROM mdt_reports WHERE id IN (%s) ORDER BY datecreated DESC'):format(placeholders),
            involvedReportIds
        ) or {}
    end
    local licences = {}
    local fingerprint = nil
    local metadata = nil
    if playerRow and playerRow.metadata then
        local ok, decoded = pcall(json.decode, playerRow.metadata)
        if ok and decoded then
            metadata = decoded
            if decoded.licences then
                licences = decoded.licences
            end
            if decoded.fingerprint then
                fingerprint = decoded.fingerprint
            end
        end
    end

    -- Auto-fill fingerprint if configured and not already set
    if Config.FingerprintAutoFilled and not fingerprint then
        metadata = metadata or {}
        local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
        local function randomChar()
            local idx = math.random(1, #chars)
            return chars:sub(idx, idx)
        end
        fingerprint = randomChar() .. randomChar() .. '-'
            .. randomChar() .. randomChar() .. randomChar() .. randomChar() .. '-'
            .. randomChar() .. randomChar() .. randomChar() .. randomChar()
        metadata.fingerprint = fingerprint
        MySQL.update.await('UPDATE players SET metadata = ? WHERE citizenid = ?', { json.encode(metadata), citizenid })
    end

    return {
        success = true,
        profile = {
            citizenid = citizenid,
            firstName = playerRow.firstname or 'Desconhecido',
            lastName = playerRow.lastname or 'Desconhecido',
            gender = getGender(tonumber(playerRow.gender)),
            dob = playerRow.dateofbirth or 'N/A',
            phone = playerRow.phone or 'N/A',
            fingerprint = fingerprint,
            occupations = occupations,
            properties = propertiesCount,
            vehicles = vehiclesCount,
            arrests = arrestsCount,
            flags = flags[citizenid] or {},
            image = (profileRow and profileRow.profilepicture and profileRow.profilepicture ~= '') and profileRow.profilepicture or nil,
            notes = profileRow and profileRow.notes or '',
            tags = profileTags,
            gallery = profileGallery,
            activeWarrants = activeWarrants,
            activeBolos = activeBoloDetails,
            evidence = evidence,
            weapons = weapons,
            linkedReports = linkedReports,
            ownedVehicles = vehicles,
            propertiesList = properties,
            licenses = {
                driver = licences.driver or false,
                weapon = licences.weapon or false,
            },
            customLicenses = (function()
                local customRows = MySQL.query.await([[
                    SELECT cl.id, cl.name, cl.description,
                           COALESCE(cil.active, 0) as active
                    FROM mdt_custom_licenses cl
                    LEFT JOIN mdt_citizen_licenses cil ON cil.license_id = cl.id AND cil.citizenid = ?
                    ORDER BY cl.id ASC
                ]], { citizenid })
                local result = {}
                for _, r in ipairs(customRows or {}) do
                    result[#result + 1] = {
                        id = r.id,
                        name = r.name,
                        description = r.description or '',
                        active = (tonumber(r.active) or 0) == 1,
                    }
                end
                return result
            end)(),
        }
    }
end)

ps.registerCallback(resourceName .. ':server:updateCitizenLicense', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end

    payload = payload or {}
    local citizenId = payload.citizenid
    local licenseType = payload.license
    local enabled = payload.enabled == true
    if not citizenId or not licenseType then
        return { success = false, message = 'Faltando ID do cidadão ou licença' }
    end

    local row = MySQL.single.await('SELECT metadata FROM players WHERE citizenid = ? LIMIT 1', { citizenId })
    if not row then
        return { success = false, message = 'Cidadão não encontrado' }
    end

    local metadata = row.metadata and json.decode(row.metadata) or {}
    metadata.licences = metadata.licences or {}
    metadata.licences[licenseType] = enabled

    MySQL.update.await('UPDATE players SET metadata = ? WHERE citizenid = ?', { json.encode(metadata), citizenId })
    return { success = true }
end)

ps.registerCallback(resourceName .. ':server:updateCitizenCustomLicense', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end

    payload = payload or {}
    local citizenId = payload.citizenid
    local licenseId = tonumber(payload.licenseId)
    local enabled = payload.enabled == true

    if not citizenId or not licenseId then
        return { success = false, message = 'Faltando ID do cidadão ou licença id' }
    end

    -- Verify the license exists
    local licenseExists = MySQL.scalar.await('SELECT id FROM mdt_custom_licenses WHERE id = ?', { licenseId })
    if not licenseExists then
        return { success = false, message = 'Licença não encontrada' }
    end

    local grantedBy = ps.getIdentifier(src)

    MySQL.query.await([[
        INSERT INTO mdt_citizen_licenses (citizenid, license_id, active, granted_by)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE active = VALUES(active), granted_by = VALUES(granted_by)
    ]], { citizenId, licenseId, enabled and 1 or 0, grantedBy })

    return { success = true }
end)

-- Add fingerprint to a citizen's metadata
ps.registerCallback(resourceName .. ':server:addSuspectFingerprint', function(source, citizenid)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end

    if not citizenid or citizenid == '' then
        return { success = false, message = 'Faltando ID do cidadão' }
    end

    local row = MySQL.single.await('SELECT metadata FROM players WHERE citizenid = ? LIMIT 1', { citizenid })
    if not row then
        return { success = false, message = 'Cidadão não encontrado' }
    end

    local metadata = row.metadata and json.decode(row.metadata) or {}

    -- If fingerprint already exists, return it
    if metadata.fingerprint and metadata.fingerprint ~= '' then
        return { success = true, fingerprint = metadata.fingerprint }
    end

    -- Generate a unique fingerprint (format: XX-XXXX-XXXX)
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local function randomChar()
        local idx = math.random(1, #chars)
        return chars:sub(idx, idx)
    end
    local fp = randomChar() .. randomChar() .. '-'
        .. randomChar() .. randomChar() .. randomChar() .. randomChar() .. '-'
        .. randomChar() .. randomChar() .. randomChar() .. randomChar()

    metadata.fingerprint = fp
    MySQL.update.await('UPDATE players SET metadata = ? WHERE citizenid = ?', { json.encode(metadata), citizenid })

    if ps.auditLog then
        ps.auditLog(src, 'add_fingerprint', 'citizens', citizenid, { fingerprint = fp })
    end

    return { success = true, fingerprint = fp }
end)

ps.registerCallback(resourceName .. ':server:createBolo', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end

    payload = payload or {}
    local boloType = payload.type or 'citizen'
	local subjectId = payload.subjectId
	local subjectName = payload.subjectName
    local reportId = payload.reportId
    local notes = payload.notes

	if not subjectName or subjectName == '' then
		return { success = false, message = 'Faltam campos obrigatórios' }
	end

    local allowedTypes = { citizen = true, vehicle = true, weapon = true, property = true, other = true }
    if not allowedTypes[boloType] then
        boloType = 'citizen'
    end

	local reportValue = reportId and tonumber(reportId) or nil
	local subjectValue = subjectId and tostring(subjectId) or ''

	-- Prevent duplicate: one active BOLO per subject per report
	if reportValue and subjectValue ~= '' then
		local existing = MySQL.single.await([[
			SELECT id FROM mdt_bolos
			WHERE type = ? AND subject_id = ? AND reportId = ? AND status = 'active'
			LIMIT 1
		]], { boloType, subjectValue, reportValue })
		if existing then
			return { success = false, message = 'Já existe um procurado ativo.' }
		end
	end

	local inserted = MySQL.insert.await([[
		INSERT INTO mdt_bolos (type, subject_id, subject_name, reportId, notes, status)
		VALUES (?, ?, ?, ?, ?, 'active')
	]], {
		boloType,
		subjectValue,
		subjectName,
		reportValue,
		notes or '',
	})

    if not inserted then
        return { success = false, message = 'Falha ao criar o procurado' }
    end

    return { success = true, id = inserted }
end)

-- Delete a BOLO
ps.registerCallback(resourceName .. ':server:deleteBolo', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end

    payload = payload or {}
    local id = tonumber(payload.id)
    if not id then
        return { success = false, message = 'ID do procurado inválido' }
    end

    MySQL.query.await('DELETE FROM mdt_bolos WHERE id = ?', { id })
    return { success = true }
end)

-- Update BOLO status (resolve, deactivate, reactivate)
ps.registerCallback(resourceName .. ':server:updateBoloStatus', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end

    payload = payload or {}
    local id = tonumber(payload.id)
    local status = payload.status
    if not id or not status then
        return { success = false, message = 'Faltando ID do procurado ou status' }
    end

    local allowedStatuses = { active = true, inactive = true, resolved = true }
    if not allowedStatuses[status] then
        return { success = false, message = 'Status inválido' }
    end

    MySQL.update.await('UPDATE mdt_bolos SET status = ? WHERE id = ?', { status, id })
    return { success = true }
end)

-- Save citizen profile notes and profile picture
ps.registerCallback(resourceName .. ':server:updateCitizen', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end

    payload = payload or {}
    local citizenId = payload.citizenid
    if not citizenId or citizenId == '' then
        return { success = false, message = 'Faltando ID do cidadão' }
    end

    EnsureProfileExists(citizenId)

    if payload.notes ~= nil then
        MySQL.update.await('UPDATE mdt_profiles SET notes = ? WHERE citizenid = ?', { payload.notes, citizenId })
    end
    if payload.profilepicture ~= nil then
        MySQL.update.await('UPDATE mdt_profiles SET profilepicture = ? WHERE citizenid = ?', { payload.profilepicture, citizenId })
    end

    return { success = true }
end)

-- Add a tag to a citizen profile
ps.registerCallback(resourceName .. ':server:addCitizenTag', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end

    payload = payload or {}
    local citizenId = payload.citizenid
    local tag = payload.tag
    if not citizenId or not tag or tag == '' then
        return { success = false, message = 'Faltando ID do cidadão ou tag' }
    end

    local profile = MySQL.single.await('SELECT id FROM mdt_profiles WHERE citizenid = ?', { citizenId })
    if not profile then
        return { success = false, message = 'Perfil não encontrado' }
    end

    -- Check for duplicate
    local existing = MySQL.scalar.await('SELECT COUNT(*) FROM mdt_profiles_tags WHERE profileId = ? AND tag = ?', { profile.id, tag })
    if existing and existing > 0 then
        return { success = false, message = 'A tag já existe' }
    end

    MySQL.insert.await('INSERT INTO mdt_profiles_tags (profileId, tag) VALUES (?, ?)', { profile.id, tag })
    return { success = true }
end)

-- Remove a tag from a citizen profile
ps.registerCallback(resourceName .. ':server:removeCitizenTag', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end

    payload = payload or {}
    local citizenId = payload.citizenid
    local tag = payload.tag
    if not citizenId or not tag then
        return { success = false, message = 'Faltando ID do cidadão ou tag' }
    end

    local profile = MySQL.single.await('SELECT id FROM mdt_profiles WHERE citizenid = ?', { citizenId })
    if not profile then
        return { success = false, message = 'Perfil não encontrado' }
    end

    MySQL.query.await('DELETE FROM mdt_profiles_tags WHERE profileId = ? AND tag = ?', { profile.id, tag })
    return { success = true }
end)

-- Add an image to a citizen profile gallery
ps.registerCallback(resourceName .. ':server:addCitizenGallery', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end

    payload = payload or {}
    local citizenId = payload.citizenid
    local image = payload.image
    local label = payload.label or ''
    if not citizenId or not image or image == '' then
        return { success = false, message = 'Faltando ID do cidadão ou URL da imagem' }
    end

    local profile = MySQL.single.await('SELECT id FROM mdt_profiles WHERE citizenid = ?', { citizenId })
    if not profile then
        return { success = false, message = 'Perfil não encontrado' }
    end

    MySQL.insert.await('INSERT INTO mdt_profiles_gallery (profileId, image, label) VALUES (?, ?, ?)', { profile.id, image, label })
    return { success = true }
end)

-- Remove an image from a citizen profile gallery
ps.registerCallback(resourceName .. ':server:removeCitizenGallery', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end

    payload = payload or {}
    local citizenId = payload.citizenid
    local image = payload.image
    if not citizenId or not image then
        return { success = false, message = 'Faltando ID do cidadão ou imagem' }
    end

    local profile = MySQL.single.await('SELECT id FROM mdt_profiles WHERE citizenid = ?', { citizenId })
    if not profile then
        return { success = false, message = 'Perfil não encontrado' }
    end

    MySQL.query.await('DELETE FROM mdt_profiles_gallery WHERE profileId = ? AND image = ?', { profile.id, image })
    return { success = true }
end)
