local function getCoreObject()
    -- QBox first
    local okQbx, qbx = pcall(function()
        return exports['qbx_core']:GetCoreObject()
    end)
    if okQbx and qbx then
        return qbx
    end

    -- Fallback to legacy QBCore
    local ok, core = pcall(function()
        return exports['qb-core']:GetCoreObject()
    end)
    if ok and core then
        return core
    end

    return nil
end

local Core = getCoreObject()
local resourceName = tostring(GetCurrentResourceName())
local VEHICLE_DIRECTORY_CACHE_KEY = 'vehicles:directory'
local VEHICLE_DIRECTORY_TTL = 15
local vehicleSourceCache = nil

local function hasTable(tableName)
    return type(MdtTableExists) == 'function' and MdtTableExists(tableName) or false
end

local function hasColumn(tableName, columnName)
    return type(MdtColumnExists) == 'function' and MdtColumnExists(tableName, columnName) or false
end

local function resolveVehicleSource()
    if vehicleSourceCache then
        return vehicleSourceCache
    end

    local sources = {
        {
            table = 'player_vehicles',
            alias = 'pv',
            id = 'pv.id',
            owner = "COALESCE(NULLIF(TRIM(pv.citizenid), ''), NULLIF(TRIM(pv.owner), ''))",
            model = "COALESCE(NULLIF(TRIM(pv.vehicle), ''), 'unknown')",
            plate = 'pv.plate',
            joinPlayers = true,
        },
        {
            table = 'owned_vehicles',
            alias = 'pv',
            id = 'NULL AS id',
            owner = "COALESCE(NULLIF(TRIM(pv.owner), ''), NULLIF(TRIM(pv.citizenid), ''))",
            model = "COALESCE(NULLIF(TRIM(JSON_UNQUOTE(JSON_EXTRACT(pv.vehicle, '$.model'))), ''), NULLIF(TRIM(pv.vehicle_name), ''), 'unknown')",
            plate = "COALESCE(NULLIF(TRIM(pv.plate), ''), NULLIF(TRIM(JSON_UNQUOTE(JSON_EXTRACT(pv.vehicle, '$.plate'))), ''))",
            joinPlayers = true,
        }
    }

    for _, source in ipairs(sources) do
        if hasTable(source.table) then
            vehicleSourceCache = source
            ps.debug(('[vehicles] using %s as source table'):format(source.table))
            return vehicleSourceCache
        end
    end

    return nil
end

local function buildVehicleOwnerExpr(tableName, alias)
    local prefix = alias and (alias .. '.') or ''
    local candidates = {}
    if hasColumn(tableName, 'citizenid') then
        candidates[#candidates + 1] = ("NULLIF(%scitizenid, '')"):format(prefix)
    end
    if hasColumn(tableName, 'owner') then
        candidates[#candidates + 1] = ("NULLIF(%sowner, '')"):format(prefix)
    end
    if hasColumn(tableName, 'owner_citizenid') then
        candidates[#candidates + 1] = ("NULLIF(%sowner_citizenid, '')"):format(prefix)
    end
    if #candidates == 0 then
        return "NULL"
    end
    return 'COALESCE(' .. table.concat(candidates, ', ') .. ')'
end

local function normalizeSearchTerm(value)
    local trimmed = tostring(value or ''):match('^%s*(.-)%s*$') or ''
    return trimmed
end

local function normalizePlate(value)
    local trimmed = normalizeSearchTerm(value)
    return trimmed ~= '' and trimmed:gsub('%s+', ''):upper() or ''
end

local function toStringOrDefault(value, fallback)
    if value == nil then
        return fallback
    end
    local cast = tostring(value)
    if cast == '' then
        return fallback
    end
    return cast
end

local function toNumberOrDefault(value, fallback)
    local cast = tonumber(value)
    if cast == nil then
        return fallback
    end
    return cast
end

local function toNumberOrNil(value)
    if value == nil then
        return nil
    end
    local cast = tonumber(value)
    if cast == nil then
        return nil
    end
    return cast
end

local function isTruthyDbBool(value)
    if value == true then return true end
    if value == false or value == nil then return false end
    local num = tonumber(value)
    if num ~= nil then
        return num == 1
    end
    local str = tostring(value):lower()
    return str == '1' or str == 'true' or str == 'yes'
end

local function buildOwnerName(rawName, citizenid)
    local trimmed = normalizeSearchTerm(rawName)
    if trimmed ~= '' and trimmed:lower() ~= 'null null' then
        return trimmed
    end

    return ps.getPlayerNameByIdentifier(citizenid) or 'Desconhecido'
end

local function formatLabel(value)
    if not value or value == '' then
        return 'Desconhecido'
    end
    local formatted = tostring(value)
    formatted = formatted:gsub("^%l", string.upper)
    formatted = formatted:gsub("_%l", function(s)
        return " " .. string.upper(s:sub(2))
    end)
    return formatted
end

local function getVehicleShared(model)
    if not Core or not Core.Shared or not Core.Shared.Vehicles then
        return nil
    end
    return Core.Shared.Vehicles[model]
end

local function buildVehicleFlags(stolen, hasActiveBolo, status)
    local flags = {}
    if hasActiveBolo then
        table.insert(flags, 'Procurado')
    end
    if stolen then
        table.insert(flags, 'Stolen')
    end
    if status and status ~= 'valid' then
        table.insert(flags, ('Status: %s'):format(formatLabel(status)))
    end
    return flags
end

local function countSetItems(set)
    if not set then
        return 0
    end
    local count = 0
    for _ in pairs(set) do
        count = count + 1
    end
    return count
end

--[[
    Vehicle tab payload contract (MSI Qbox / player_vehicles source of truth):
    - snake_case fields (legacy UI compatibility)
    - camelCase aliases (new contract): vehicleName, ownerName, displayName,
      mdtVehicleInformation, mdtVehiclePoints, mdtVehicleStatus, mdtVehicleStolen,
      mdtVehicleBoloactive, mdtVehicleImage
]]
local function serializeVehicleRow(v, reportCountsByPlate, activeBoloByPlate)
    local model = normalizeSearchTerm(v.vehicle)
    if model == '' then
        model = 'unknown'
    end
    local vehicleName = normalizeSearchTerm(v.vehicle_name)
    local displayName = vehicleName ~= '' and vehicleName or model
    local vehicleData = getVehicleShared(model)
    local plate = normalizePlate(v.plate)
    if plate == '' then
        plate = 'UNKNOWN'
    end
    local reportCount = tonumber(reportCountsByPlate and reportCountsByPlate[plate] or 0) or 0
    local hasActiveBolo = (activeBoloByPlate and activeBoloByPlate[plate] == true) or isTruthyDbBool(v.boloactive)
    local rawStatus = normalizeSearchTerm(v.status_text)
    if rawStatus == '' then
        rawStatus = 'unknown'
    end
    local mdtStatus = normalizeSearchTerm(v.mdt_status)
    if mdtStatus == '' then
        mdtStatus = 'valid'
    end
    local flags = buildVehicleFlags(isTruthyDbBool(v.stolen), hasActiveBolo, mdtStatus)

    return {
        id = v.id,
        citizenid = toStringOrDefault(v.citizenid, ''),
        model = model,
        vehicle = model,
        vehicle_name = vehicleName ~= '' and vehicleName or model,
        vehicleName = vehicleName ~= '' and vehicleName or model,
        displayName = displayName,
        label = displayName ~= '' and displayName or ((vehicleData and vehicleData.name) or formatLabel(model)),
        plate = plate,
        fakeplate = (v.fakeplate ~= nil and normalizeSearchTerm(v.fakeplate) ~= '') and tostring(v.fakeplate) or nil,
        owner = buildOwnerName(v.owner_name, v.citizenid),
        ownerName = buildOwnerName(v.owner_name, v.citizenid),
        ownerCitizenId = v.citizenid,
        garage = toStringOrDefault(v.garage, ''),
        fuel = toNumberOrNil(v.fuel),
        engine = toNumberOrNil(v.engine),
        body = toNumberOrNil(v.body),
        state = toNumberOrDefault(v.state, 0),
        status_text = rawStatus,
        mileage = toNumberOrNil(v.mileage),
        mdt_vehicle_information = toStringOrDefault(v.information, ''),
        mdtVehicleInformation = toStringOrDefault(v.information, ''),
        mdt_vehicle_points = toNumberOrDefault(v.points, 0),
        mdtVehiclePoints = toNumberOrDefault(v.points, 0),
        mdt_vehicle_status = mdtStatus,
        mdtVehicleStatus = mdtStatus,
        mdt_vehicle_stolen = isTruthyDbBool(v.stolen),
        mdtVehicleStolen = isTruthyDbBool(v.stolen),
        mdt_vehicle_boloactive = hasActiveBolo,
        mdtVehicleBoloactive = hasActiveBolo,
        mdt_vehicle_image = (v.image ~= nil and normalizeSearchTerm(v.image) ~= '') and tostring(v.image) or nil,
        mdtVehicleImage = (v.image ~= nil and normalizeSearchTerm(v.image) ~= '') and tostring(v.image) or nil,
        class = formatLabel(vehicleData and vehicleData.category or 'Desconhecido'),
        type = formatLabel(vehicleData and vehicleData.type or 'Desconhecido'),
        flags = flags,
        image = (v.image and v.image ~= '' and v.image) or ('https://docs.fivem.net/vehicles/' .. model .. '.webp'),
        seenIn = reportCount,
        information = toStringOrDefault(v.information, ''),
        points = toNumberOrDefault(v.points, 0),
        status = rawStatus,
        core_state = toNumberOrDefault(v.state, 0),
        stolen = isTruthyDbBool(v.stolen),
        boloactive = hasActiveBolo,
    }
end


local function paginateRows(rows, page, limit)
    local safeLimit = math.max(1, tonumber(limit) or (Config.Pagination and Config.Pagination.Vehicles) or 25)
    safeLimit = math.min(safeLimit, 5000)
    local safePage = math.max(1, tonumber(page) or 1)
    local total = #rows
    local offset = (safePage - 1) * safeLimit
    local paginated = {}

    for i = offset + 1, math.min(total, offset + safeLimit) do
        paginated[#paginated + 1] = rows[i]
    end

    return {
        data = paginated,
        page = safePage,
        limit = safeLimit,
        total = total,
        hasMore = (offset + safeLimit) < total,
    }
end

local function matchesVehicleQuery(vehicle, normalizedQuery)
    if not normalizedQuery or normalizedQuery == '' then
        return true
    end

    local needle = normalizedQuery:lower()
    local compactNeedle = normalizedQuery:gsub('%s+', ''):lower()
    local haystacks = {
        vehicle.plate or '',
        vehicle.model or '',
        vehicle.label or '',
        vehicle.owner or '',
        vehicle.ownerCitizenId or '',
        vehicle.class or '',
        vehicle.type or '',
        vehicle.status or '',
    }

    for i = 1, #haystacks do
        local value = tostring(haystacks[i] or '')
        if value:lower():find(needle, 1, true) or value:gsub('%s+', ''):lower():find(compactNeedle, 1, true) then
            return true
        end
    end

    return false
end

local function getVehicleSelectSql(source)
    local tbl = source.table
    local alias = source.alias or 'pv'
    local hasVehicleName = hasColumn(tbl, 'vehicle_name')
    local hasFakeplate = hasColumn(tbl, 'fakeplate')
    local hasLicense = hasColumn(tbl, 'license')
    local hasMileage = hasColumn(tbl, 'mileage')
    local hasFuel = hasColumn(tbl, 'fuel')
    local hasEngine = hasColumn(tbl, 'engine')
    local hasBody = hasColumn(tbl, 'body')
    local hasState = hasColumn(tbl, 'state')
    local hasStatus = hasColumn(tbl, 'status')
    local hasGarage = hasColumn(tbl, 'garage')
    local hasMdtInfo = hasColumn(tbl, 'mdt_vehicle_information')
    local hasMdtPoints = hasColumn(tbl, 'mdt_vehicle_points')
    local hasMdtStatus = hasColumn(tbl, 'mdt_vehicle_status')
    local hasMdtStolen = hasColumn(tbl, 'mdt_vehicle_stolen')
    local hasMdtBolo = hasColumn(tbl, 'mdt_vehicle_boloactive')
    local hasMdtImage = hasColumn(tbl, 'mdt_vehicle_image')

    return ([[
        SELECT
            %s AS id,
            %s
            %s AS citizenid,
            %s AS vehicle,
            %s
            %s AS hash,
            %s AS mods,
            %s AS plate,
            %s
            %s
            %s
            %s
            %s
            %s
            %s
            %s
            %s
            %s
            %s
            %s
            %s
            %s
            CONCAT_WS(
                ' ',
                NULLIF(
                    CASE
                        WHEN JSON_VALID(p.charinfo) THEN JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname'))
                        ELSE NULL
                    END,
                    'null'
                ),
                NULLIF(
                    CASE
                        WHEN JSON_VALID(p.charinfo) THEN JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname'))
                        ELSE NULL
                    END,
                    'null'
                )
            ) AS owner_name
        FROM %s pv
        LEFT JOIN players p
            ON p.citizenid = (%s)
    ]]):format(
        source.id or 'NULL',
        hasLicense and (alias .. '.license,') or '',
        source.owner,
        source.model,
        hasVehicleName and "NULLIF(TRIM(pv.vehicle_name), '') AS vehicle_name," or "NULL AS vehicle_name,",
        hasColumn(tbl, 'hash') and (alias .. '.hash') or 'NULL',
        hasColumn(tbl, 'mods') and (alias .. '.mods') or 'NULL',
        source.plate,
        hasFakeplate and "NULLIF(TRIM(pv.fakeplate), '') AS fakeplate," or "NULL AS fakeplate,",
        hasGarage and 'pv.garage,' or "NULL AS garage,",
        hasFuel and 'pv.fuel,' or "NULL AS fuel,",
        hasEngine and 'pv.engine,' or "NULL AS engine,",
        hasBody and 'pv.body,' or "NULL AS body,",
        hasState and 'CAST(COALESCE(pv.state, 0) AS SIGNED) AS state,' or "0 AS state,",
        hasStatus and "COALESCE(NULLIF(TRIM(pv.status), ''), '') AS status_text," or "'' AS status_text,",
        hasMileage and 'pv.mileage,' or "NULL AS mileage,",
        hasMdtInfo and 'pv.mdt_vehicle_information AS information,' or "NULL AS information,",
        hasMdtPoints and 'COALESCE(pv.mdt_vehicle_points, 0) AS points,' or "0 AS points,",
        hasMdtStatus and [[COALESCE(NULLIF(TRIM(pv.mdt_vehicle_status), ''), 'valid') AS mdt_status,]] or "'valid' AS mdt_status,",
        hasMdtStolen and 'COALESCE(pv.mdt_vehicle_stolen, 0) AS stolen,' or "0 AS stolen,",
        hasMdtBolo and 'COALESCE(pv.mdt_vehicle_boloactive, 0) AS boloactive,' or "0 AS boloactive,",
        hasMdtImage and "NULLIF(TRIM(pv.mdt_vehicle_image), '') AS image," or "NULL AS image,",
        tbl,
        source.owner
    )
end

local function buildVehicleSearchWhere(source, search)
    local trimmed = normalizeSearchTerm(search)
    if trimmed == '' then
        return '', {}
    end

    local tbl = source.table
    local alias = source.alias or 'pv'
    local hasFakeplate = hasColumn(tbl, 'fakeplate')
    local hasVehicleName = hasColumn(tbl, 'vehicle_name')
    local hasGarage = hasColumn(tbl, 'garage')

    local like = ('%%%s%%'):format(trimmed)
    local compact = normalizePlate(trimmed)
    local isLikelyPlate = compact ~= '' and compact:match('^[A-Z0-9]+$') ~= nil
    if isLikelyPlate then
        local conditions = {
            ("UPPER(REPLACE(%s, ' ', '')) = ?"):format(source.plate),
            ("UPPER(REPLACE(%s, ' ', '')) LIKE ?"):format(source.plate),
        }
        local compactLike = ('%%%s%%'):format(compact)
        local params = { compact, compactLike }

        if hasFakeplate then
            conditions[#conditions + 1] = ("UPPER(REPLACE(COALESCE(%s.fakeplate, ''), ' ', '')) LIKE ?"):format(alias)
            params[#params + 1] = compactLike
        end
        conditions[#conditions + 1] = ("COALESCE(%s, '') LIKE ?"):format(source.owner)
        params[#params + 1] = like
        conditions[#conditions + 1] = ("COALESCE(%s, '') LIKE ?"):format(source.model)
        params[#params + 1] = like
        if hasVehicleName then
            conditions[#conditions + 1] = ("COALESCE(%s.vehicle_name, '') LIKE ?"):format(alias)
            params[#params + 1] = like
        end
        if hasGarage then
            conditions[#conditions + 1] = ("COALESCE(%s.garage, '') LIKE ?"):format(alias)
            params[#params + 1] = like
        end

        return ('WHERE (%s)'):format(table.concat(conditions, ' OR ')), params
    end

    local conditions = {
        ("COALESCE(%s, '') LIKE ?"):format(source.plate),
    }
    local params = { like }

    if hasFakeplate then
        conditions[#conditions + 1] = ("COALESCE(%s.fakeplate, '') LIKE ?"):format(alias)
        params[#params + 1] = like
    end
    conditions[#conditions + 1] = ("COALESCE(%s, '') LIKE ?"):format(source.owner)
    params[#params + 1] = like
    conditions[#conditions + 1] = ("COALESCE(%s, '') LIKE ?"):format(source.model)
    params[#params + 1] = like
    if hasVehicleName then
        conditions[#conditions + 1] = ("COALESCE(%s.vehicle_name, '') LIKE ?"):format(alias)
        params[#params + 1] = like
    end
    if hasGarage then
        conditions[#conditions + 1] = ("COALESCE(%s.garage, '') LIKE ?"):format(alias)
        params[#params + 1] = like
    end

    return ('WHERE (%s)'):format(table.concat(conditions, ' OR ')), params
end

local function fetchVehicleReportCountsByPlate(normalizedPlates)
    local counts = {}
    if not normalizedPlates or #normalizedPlates == 0 then
        return counts
    end

    local placeholders = {}
    for i = 1, #normalizedPlates do
        placeholders[i] = '?'
    end

    local rows = MySQL.query.await(([[ 
        SELECT UPPER(REPLACE(plate, ' ', '')) AS normalized_plate, COUNT(DISTINCT reportid) AS report_count
        FROM mdt_report_vehicles
        WHERE UPPER(REPLACE(plate, ' ', '')) IN (%s)
        GROUP BY normalized_plate
    ]]):format(table.concat(placeholders, ', ')), normalizedPlates) or {}

    for _, row in ipairs(rows) do
        if row.normalized_plate and row.normalized_plate ~= '' then
            counts[row.normalized_plate] = tonumber(row.report_count) or 0
        end
    end

    return counts
end

local function fetchActiveBoloByPlate(normalizedPlates)
    local active = {}
    if not normalizedPlates or #normalizedPlates == 0 then
        return active
    end

    local placeholders = {}
    for i = 1, #normalizedPlates do
        placeholders[i] = '?'
    end

    local boloRows = MySQL.query.await(([[ 
        SELECT subject_id
        FROM mdt_bolos
        WHERE type = 'vehicle'
          AND status = 'active'
          AND UPPER(REPLACE(subject_id, ' ', '')) IN (%s)
    ]]):format(table.concat(placeholders, ', ')), normalizedPlates) or {}

    for _, bolo in ipairs(boloRows) do
        local normalized = normalizePlate(bolo.subject_id)
        if normalized ~= '' then
            active[normalized] = true
        end
    end

    return active
end

local function fetchVehicleBolos()
    local boloRows = MySQL.query.await([[
        SELECT id, reportId, subject_name, notes, status, subject_id, image, type
        FROM mdt_bolos
        WHERE type = ? AND status = ?
    ]], { 'vehicle', 'active' }) or {}

    local bolos = {}
    for _, bolo in pairs(boloRows) do
        table.insert(bolos, {
            id = bolo.id,
            reportId = bolo.reportId and tostring(bolo.reportId) or 'N/A',
            name = bolo.subject_name or 'Veículo desconhecido',
            type = bolo.type,
            notes = bolo.notes or '',
            status = bolo.status,
            plate = bolo.subject_id or 'Desconhecido',
            image = bolo.image or 'https://docs.fivem.net/vehicles/elegy.webp',
        })
    end
    return bolos
end

local function queryVehiclesPage(search, page, limit)
    local source = resolveVehicleSource()
    if not source then
        return { vehicles = {}, page = 1, limit = 25, total = 0, hasMore = false }
    end
    local safeLimit = math.max(1, tonumber(limit) or (Config.Pagination and Config.Pagination.Vehicles) or 25)
    safeLimit = math.min(safeLimit, 5000)
    local safePage = math.max(1, tonumber(page) or 1)
    local offset = (safePage - 1) * safeLimit
    local whereSql, whereParams = buildVehicleSearchWhere(source, search)

    local countSql = ('SELECT COUNT(*) AS total FROM %s %s %s'):format(source.table, source.alias or 'pv', whereSql)
    local countRow = MySQL.single.await(countSql, whereParams) or { total = 0 }
    local total = tonumber(countRow.total) or 0

    local orderBy = hasColumn(source.table, 'id') and 'pv.id DESC' or 'pv.plate ASC'
    local listSql = ([[%s %s ORDER BY %s LIMIT ? OFFSET ?]]):format(getVehicleSelectSql(source), whereSql, orderBy)
    local listParams = {}
    for i = 1, #whereParams do
        listParams[#listParams + 1] = whereParams[i]
    end
    listParams[#listParams + 1] = safeLimit
    listParams[#listParams + 1] = offset

    local rows = MySQL.query.await(listSql, listParams) or {}
    local normalizedPlates = {}
    local seen = {}
    for _, row in ipairs(rows) do
        local normalized = normalizePlate(row.plate)
        if normalized ~= '' and not seen[normalized] then
            seen[normalized] = true
            normalizedPlates[#normalizedPlates + 1] = normalized
        end
    end

    local reportCountsByPlate = fetchVehicleReportCountsByPlate(normalizedPlates)
    local activeBoloByPlate = fetchActiveBoloByPlate(normalizedPlates)
    local vehicles = {}
    for _, row in ipairs(rows) do
        vehicles[#vehicles + 1] = serializeVehicleRow(row, reportCountsByPlate, activeBoloByPlate)
    end

    return {
        vehicles = vehicles,
        page = safePage,
        limit = safeLimit,
        total = total,
        hasMore = (offset + safeLimit) < total,
    }
end

function GetMdtVehicleDirectory(forceRefresh)
    if forceRefresh then
        Cache.invalidate(VEHICLE_DIRECTORY_CACHE_KEY)
        vehicleSourceCache = nil
    end

    return Cache.getOrSet(VEHICLE_DIRECTORY_CACHE_KEY, VEHICLE_DIRECTORY_TTL, function()
        EnsureMdtSchema()
        local source = resolveVehicleSource()
        if not source then
            return { vehicles = {}, bolos = {} }
        end
        local vehList = MySQL.query.await(([[%s ORDER BY pv.plate ASC]]):format(getVehicleSelectSql(source))) or {}
        local normalizedPlates = {}
        local seen = {}
        for _, row in ipairs(vehList) do
            local plate = normalizePlate(row.plate)
            if plate ~= '' and not seen[plate] then
                seen[plate] = true
                normalizedPlates[#normalizedPlates + 1] = plate
            end
        end

        local reportCountsByPlate = fetchVehicleReportCountsByPlate(normalizedPlates)
        local activeBoloByPlate = fetchActiveBoloByPlate(normalizedPlates)
        local bolos = fetchVehicleBolos()

        local vehicles = {}
        for _, v in ipairs(vehList) do
            vehicles[#vehicles + 1] = serializeVehicleRow(v, reportCountsByPlate, activeBoloByPlate)
        end

        return {
            vehicles = vehicles,
            bolos = bolos,
        }
    end) or { vehicles = {}, bolos = {} }
end

ps.registerCallback(resourceName .. ':server:GetVehicles', function(source, payload)
    local startTime = os.clock()
    local src = source
    if not CheckAuth(src) then return { vehicles = {}, bolos = {}, page = 1, limit = 25, total = 0, hasMore = false } end
    EnsureMdtSchema()

    payload = payload or {}
    local page = payload.page or payload.currentPage or 1
    local limit = payload.limit or (Config.Pagination and Config.Pagination.Vehicles) or 25
    local pageResult = queryVehiclesPage(nil, page, limit)
    local bolos = fetchVehicleBolos()

    local endTime = os.clock()
    local elapsedTime = (endTime - startTime) * 1000
    ps.debug(string.format("getVehicles callback executed in %.2f ms (page %s, limit %s)", elapsedTime, tostring(pageResult.page), tostring(pageResult.limit)))

    return {
        vehicles = pageResult.vehicles or {},
        bolos = bolos,
        page = pageResult.page,
        limit = pageResult.limit,
        total = pageResult.total,
        hasMore = pageResult.hasMore,
    }
end)

ps.registerCallback(resourceName .. ':server:SearchVehicles', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { vehicles = {}, bolos = {}, page = 1, limit = 25, total = 0, hasMore = false } end
    EnsureMdtSchema()

    if type(payload) ~= 'table' then
        payload = { query = payload }
    end

    local trimmedQuery = normalizeSearchTerm(payload.query)
    if trimmedQuery == '' then
        return { vehicles = {}, bolos = {}, page = 1, limit = payload.limit or 25, total = 0, hasMore = false }
    end

    local pageResult = queryVehiclesPage(trimmedQuery, payload.page or 1, payload.limit)

    return {
        vehicles = pageResult.vehicles or {},
        bolos = {},
        page = pageResult.page,
        limit = pageResult.limit,
        total = pageResult.total,
        hasMore = pageResult.hasMore,
    }
end)

ps.registerCallback(resourceName .. ':server:UpdateVehicle', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end
    EnsureMdtSchema()

    payload = payload or {}
    local plate = normalizePlate(payload.plate)
    if not plate or plate == '' then
        return { success = false, message = 'Faltando placa' }
    end
    local source = resolveVehicleSource()
    if not source then
        return { success = false, message = 'Tabela de veículos não encontrada' }
    end
    local vehicleTable = source.table

    local ownerExpr = buildVehicleOwnerExpr(vehicleTable, nil)
    local ownerRow = MySQL.single.await(('SELECT %s AS citizenid FROM %s WHERE UPPER(REPLACE(plate, \' \', \'\')) = ? LIMIT 1'):format(ownerExpr, vehicleTable), { plate })
    if not ownerRow or not ownerRow.citizenid then
        return { success = false, message = 'Veículo não encontrado' }
    end

    local supportsMdtVehicleColumns = hasColumn(vehicleTable, 'mdt_vehicle_points') and hasColumn(vehicleTable, 'mdt_vehicle_status') and hasColumn(vehicleTable, 'mdt_vehicle_information')
    local existing = supportsMdtVehicleColumns
        and MySQL.single.await(('SELECT mdt_vehicle_points, mdt_vehicle_status, mdt_vehicle_information FROM %s WHERE UPPER(REPLACE(plate, \' \', \'\')) = ? LIMIT 1'):format(vehicleTable), { plate })
        or { mdt_vehicle_points = 0, mdt_vehicle_status = 'valid', mdt_vehicle_information = nil }
    local previousPoints = existing and tonumber(existing.mdt_vehicle_points) or 0

    local points = tonumber(payload.points)
    if points and points < 0 then
        points = 0
    end

    local allowedStatus = {
        valid = true,
        suspended = true,
        expired = true,
        impounded = true
    }
    local status = payload.status
    if status and not allowedStatus[status] then
        status = nil
    end

    local updates = {}
    local values = {}

    if payload.information ~= nil and hasColumn(vehicleTable, 'mdt_vehicle_information') then
        updates[#updates + 1] = 'mdt_vehicle_information = ?'
        values[#values + 1] = payload.information
    end

    if points ~= nil and hasColumn(vehicleTable, 'mdt_vehicle_points') then
        updates[#updates + 1] = 'mdt_vehicle_points = ?'
        values[#values + 1] = points
    end

    if status ~= nil and hasColumn(vehicleTable, 'mdt_vehicle_status') then
        updates[#updates + 1] = 'mdt_vehicle_status = ?'
        values[#values + 1] = status
    end

    if #updates == 0 then
        return { success = true }
    end

    values[#values + 1] = plate

    MySQL.update.await(('UPDATE %s SET %s WHERE UPPER(REPLACE(plate, \' \', \'\')) = ?'):format(vehicleTable, table.concat(updates, ', ')), values)
    Cache.invalidate(VEHICLE_DIRECTORY_CACHE_KEY)

    if ps.auditLog then
        ps.auditLog(src, 'vehicle_updated', 'vehicle', plate, {
            plate = plate,
            points = points,
            status = status,
            information = payload.information
        })
    end

    return { success = true }
end)

ps.registerCallback(resourceName .. ':server:GetVehicle', function(source, plate)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end
    EnsureMdtSchema()

    plate = normalizePlate(plate)
    if not plate or plate == '' then
        return { success = false, message = 'Faltando placa' }
    end
    local source = resolveVehicleSource()
    if not source then
        return { success = false, message = 'Tabela de veículos não encontrada' }
    end
    local vehicleTable = source.table

    local informationExpr = hasColumn(vehicleTable, 'mdt_vehicle_information') and 'pv.mdt_vehicle_information' or 'NULL'
    local pointsExpr = hasColumn(vehicleTable, 'mdt_vehicle_points') and 'pv.mdt_vehicle_points' or '0'
    local statusExpr = hasColumn(vehicleTable, 'mdt_vehicle_status') and 'pv.mdt_vehicle_status' or "'valid'"
    local stolenExpr = hasColumn(vehicleTable, 'mdt_vehicle_stolen') and 'pv.mdt_vehicle_stolen' or '0'
    local boloExpr = hasColumn(vehicleTable, 'mdt_vehicle_boloactive') and 'pv.mdt_vehicle_boloactive' or '0'
    local imageExpr = hasColumn(vehicleTable, 'mdt_vehicle_image') and 'pv.mdt_vehicle_image' or 'NULL'
    local stateExpr = hasColumn(vehicleTable, 'state') and 'pv.state' or '0'
    local vehicleNameExpr = hasColumn(vehicleTable, 'vehicle_name') and "NULLIF(TRIM(pv.vehicle_name), '')" or 'NULL'
    local fakeplateExpr = hasColumn(vehicleTable, 'fakeplate') and "NULLIF(TRIM(pv.fakeplate), '')" or 'NULL'
    local garageExpr = hasColumn(vehicleTable, 'garage') and 'pv.garage' or 'NULL'
    local fuelExpr = hasColumn(vehicleTable, 'fuel') and 'pv.fuel' or 'NULL'
    local engineExpr = hasColumn(vehicleTable, 'engine') and 'pv.engine' or 'NULL'
    local bodyExpr = hasColumn(vehicleTable, 'body') and 'pv.body' or 'NULL'
    local mileageExpr = hasColumn(vehicleTable, 'mileage') and 'pv.mileage' or 'NULL'
    local statusTextExpr = hasColumn(vehicleTable, 'status') and "COALESCE(NULLIF(TRIM(pv.status), ''), '')" or "''"

    local ownerExpr = buildVehicleOwnerExpr(vehicleTable, 'pv')
    local vehicleRow = MySQL.query.await(([[
        SELECT
            pv.id,
            pv.plate,
            COALESCE(NULLIF(TRIM(pv.vehicle), ''), 'unknown') AS vehicle,
            %s AS vehicle_name,
            %s AS fakeplate,
            %s AS garage,
            %s AS fuel,
            %s AS engine,
            %s AS body,
            %s AS mileage,
            %s AS status_text,
            %s AS citizenid,
            %s AS information,
            %s AS points,
            %s AS mdt_status,
            %s AS stolen,
            %s AS boloactive,
            %s AS image,
            %s AS state,
            CONCAT_WS(
                ' ',
                NULLIF(
                    CASE
                        WHEN JSON_VALID(p.charinfo) THEN JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname'))
                        ELSE NULL
                    END,
                    'null'
                ),
                NULLIF(
                    CASE
                        WHEN JSON_VALID(p.charinfo) THEN JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname'))
                        ELSE NULL
                    END,
                    'null'
                )
            ) AS owner_name
        FROM %s pv
        LEFT JOIN players p
            ON p.citizenid = (%s)
        WHERE UPPER(REPLACE(pv.plate, ' ', '')) = ?
        LIMIT 1
    ]]):format(vehicleNameExpr, fakeplateExpr, garageExpr, fuelExpr, engineExpr, bodyExpr, mileageExpr, statusTextExpr, ownerExpr, informationExpr, pointsExpr, statusExpr, stolenExpr, boloExpr, imageExpr, stateExpr, vehicleTable, ownerExpr), { plate })

    if not vehicleRow or not vehicleRow[1] then
        return { success = false, message = 'Veículo não encontrado' }
    end

    local row = vehicleRow[1]
    local vehicleData = getVehicleShared(row.vehicle)
    local plateUpper = normalizePlate(row.plate)
    if plateUpper == '' then
        plateUpper = 'UNKNOWN'
    end

    local boloRows = MySQL.query.await([[
        SELECT *
        FROM mdt_bolos
        WHERE type = ?
          AND UPPER(REPLACE(subject_id, ' ', '')) = ?
    ]], { 'vehicle', plate })
    local reportIdSet = {}
    local bolos = {}
    local hasActiveBolo = false
    for _, bolo in pairs(boloRows) do
        if bolo.reportId then
            reportIdSet[tostring(bolo.reportId)] = true
        end
        if bolo.status == 'active' then
            hasActiveBolo = true
        end
        table.insert(bolos, {
            id = bolo.id,
            reportId = bolo.reportId and tostring(bolo.reportId) or 'N/A',
            notes = bolo.notes or '',
            status = bolo.status,
            type = bolo.type,
        })
    end

    local reportCount = countSetItems(reportIdSet)
    local normalizedMdtStatus = normalizeSearchTerm(row.mdt_status)
    if normalizedMdtStatus == '' then normalizedMdtStatus = 'valid' end
    local rawStatus = normalizeSearchTerm(row.status_text)
    if rawStatus == '' then
        rawStatus = 'unknown'
    end
    local flags = buildVehicleFlags(isTruthyDbBool(row.stolen), hasActiveBolo or isTruthyDbBool(row.boloactive), normalizedMdtStatus)

    return {
        success = true,
        vehicle = {
            id = row.id,
            citizenid = toStringOrDefault(row.citizenid, ''),
            model = row.vehicle,
            vehicle = row.vehicle,
            vehicle_name = normalizeSearchTerm(row.vehicle_name) ~= '' and row.vehicle_name or row.vehicle,
            vehicleName = normalizeSearchTerm(row.vehicle_name) ~= '' and row.vehicle_name or row.vehicle,
            displayName = (normalizeSearchTerm(row.vehicle_name) ~= '' and row.vehicle_name) or row.vehicle,
            label = (normalizeSearchTerm(row.vehicle_name) ~= '' and row.vehicle_name) or (vehicleData and vehicleData.name) or row.vehicle or 'Veículo desconhecido',
            brand = vehicleData and vehicleData.brand or nil,
            plate = plateUpper,
            fakeplate = (row.fakeplate ~= nil and normalizeSearchTerm(row.fakeplate) ~= '') and tostring(row.fakeplate) or nil,
            owner = buildOwnerName(row.owner_name, row.citizenid),
            ownerName = buildOwnerName(row.owner_name, row.citizenid),
            ownerCitizenId = row.citizenid,
            garage = toStringOrDefault(row.garage, ''),
            fuel = toNumberOrNil(row.fuel),
            engine = toNumberOrNil(row.engine),
            body = toNumberOrNil(row.body),
            state = toNumberOrDefault(row.state, 0),
            status_text = rawStatus,
            mileage = toNumberOrNil(row.mileage),
            class = formatLabel(vehicleData and vehicleData.category or 'Desconhecido'),
            type = formatLabel(vehicleData and vehicleData.type or 'Desconhecido'),
            image = (row.image and row.image ~= '' and row.image) or ('https://docs.fivem.net/vehicles/' .. row.vehicle .. '.webp'),
            information = toStringOrDefault(row.information, ''),
            mdt_vehicle_information = toStringOrDefault(row.information, ''),
            mdtVehicleInformation = toStringOrDefault(row.information, ''),
            points = toNumberOrDefault(row.points, 0),
            mdt_vehicle_points = toNumberOrDefault(row.points, 0),
            mdtVehiclePoints = toNumberOrDefault(row.points, 0),
            status = rawStatus,
            mdt_vehicle_status = normalizedMdtStatus,
            mdtVehicleStatus = normalizedMdtStatus,
            core_state = toNumberOrDefault(row.state, 0),
            stolen = isTruthyDbBool(row.stolen),
            mdt_vehicle_stolen = isTruthyDbBool(row.stolen),
            mdtVehicleStolen = isTruthyDbBool(row.stolen),
            boloactive = isTruthyDbBool(row.boloactive),
            mdt_vehicle_boloactive = isTruthyDbBool(row.boloactive),
            mdtVehicleBoloactive = isTruthyDbBool(row.boloactive),
            mdt_vehicle_image = (row.image and row.image ~= '' and tostring(row.image)) or nil,
            mdtVehicleImage = (row.image and row.image ~= '' and tostring(row.image)) or nil,
            flags = flags,
            seenIn = reportCount,
            bolos = bolos,
        }
    }
end)
