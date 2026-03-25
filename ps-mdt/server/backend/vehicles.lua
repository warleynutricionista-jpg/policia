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
local vehicleTableCache = nil

local function hasTable(tableName)
    return type(MdtTableExists) == 'function' and MdtTableExists(tableName) or false
end

local function hasColumn(tableName, columnName)
    return type(MdtColumnExists) == 'function' and MdtColumnExists(tableName, columnName) or false
end

local function getVehicleTableName()
    if vehicleTableCache then
        return vehicleTableCache
    end

    if hasTable('player_vehicles') then
        vehicleTableCache = 'player_vehicles'
    elseif hasTable('vehicles') then
        vehicleTableCache = 'vehicles'
    end

    return vehicleTableCache
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

local function serializeVehicleRow(v, reportCountsByPlate, activeBoloByPlate)
    local model = normalizeSearchTerm(v.vehicle)
    if model == '' then
        model = 'unknown'
    end
    local vehicleData = getVehicleShared(model)
    local plate = normalizePlate(v.plate)
    if plate == '' then
        plate = 'UNKNOWN'
    end
    local reportCount = tonumber(reportCountsByPlate and reportCountsByPlate[plate] or 0) or 0
    local hasActiveBolo = (activeBoloByPlate and activeBoloByPlate[plate] == true) or v.boloactive == 1
    local flags = buildVehicleFlags(v.stolen == 1, hasActiveBolo, v.status)

    return {
        id = v.id,
        model = model,
        label = vehicleData and vehicleData.name or formatLabel(model),
        plate = plate,
        owner = buildOwnerName(v.owner_name, v.citizenid),
        ownerCitizenId = v.citizenid,
        class = formatLabel(vehicleData and vehicleData.category or 'Desconhecido'),
        type = formatLabel(vehicleData and vehicleData.type or 'Desconhecido'),
        flags = flags,
        image = (v.image and v.image ~= '' and v.image) or ('https://docs.fivem.net/vehicles/' .. model .. '.webp'),
        seenIn = reportCount,
        points = tonumber(v.points) or 0,
        status = v.status or 'valid',
        core_state = tonumber(v.core_state) or 0,
    }
end


local function paginateRows(rows, page, limit)
    local safeLimit = math.max(1, tonumber(limit) or (Config.Pagination and Config.Pagination.Vehicles) or 25)
    safeLimit = math.min(safeLimit, 100)
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

function GetMdtVehicleDirectory(forceRefresh)
    if forceRefresh then
        Cache.invalidate(VEHICLE_DIRECTORY_CACHE_KEY)
        vehicleTableCache = nil
    end

    return Cache.getOrSet(VEHICLE_DIRECTORY_CACHE_KEY, VEHICLE_DIRECTORY_TTL, function()
        EnsureMdtSchema()
        local vehicleTable = getVehicleTableName()
        if not vehicleTable then
            return { vehicles = {}, bolos = {} }
        end

        local ownerExpr = buildVehicleOwnerExpr(vehicleTable, 'pv')
        local modelExpr = "COALESCE(NULLIF(pv.vehicle, ''), NULLIF(JSON_UNQUOTE(JSON_EXTRACT(pv.vehicle, '$.model')), ''), 'unknown')"
        if hasColumn(vehicleTable, 'mods') then
            modelExpr = "COALESCE(NULLIF(pv.vehicle, ''), NULLIF(JSON_UNQUOTE(JSON_EXTRACT(pv.vehicle, '$.model')), ''), NULLIF(JSON_UNQUOTE(JSON_EXTRACT(pv.mods, '$.model')), ''), 'unknown')"
        end

        local infoExpr = hasColumn(vehicleTable, 'mdt_vehicle_information') and 'pv.mdt_vehicle_information' or "NULL"
        local pointsExpr = hasColumn(vehicleTable, 'mdt_vehicle_points') and 'pv.mdt_vehicle_points' or '0'
        local statusExpr = hasColumn(vehicleTable, 'mdt_vehicle_status') and 'pv.mdt_vehicle_status' or "'valid'"
        local stolenExpr = hasColumn(vehicleTable, 'mdt_vehicle_stolen') and 'pv.mdt_vehicle_stolen' or '0'
        local boloExpr = hasColumn(vehicleTable, 'mdt_vehicle_boloactive') and 'pv.mdt_vehicle_boloactive' or '0'
        local imageExpr = hasColumn(vehicleTable, 'mdt_vehicle_image') and 'pv.mdt_vehicle_image' or "NULL"
        local stateExpr = hasColumn(vehicleTable, 'state') and 'pv.state' or '0'

        local vehList = MySQL.query.await(([[
            SELECT
                pv.id,
                pv.plate,
                %s AS vehicle,
                %s AS citizenid,
                %s AS information,
                %s AS points,
                %s AS status,
                %s AS stolen,
                %s AS boloactive,
                %s AS image,
                %s AS core_state,
                CONCAT_WS(
                    ' ',
                    NULLIF(JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')), 'null'),
                    NULLIF(JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname')), 'null')
                ) AS owner_name
            FROM %s pv
            LEFT JOIN players p
                ON p.citizenid COLLATE utf8mb4_general_ci = (%s) COLLATE utf8mb4_general_ci
            ORDER BY pv.plate ASC
        ]]):format(
            modelExpr,
            ownerExpr,
            infoExpr,
            pointsExpr,
            statusExpr,
            stolenExpr,
            boloExpr,
            imageExpr,
            stateExpr,
            vehicleTable,
            ownerExpr
        )) or {}

        local boloRows = MySQL.query.await([[
            SELECT id, reportId, subject_name, notes, status, subject_id, image, type
            FROM mdt_bolos
            WHERE type = ? AND status = ?
        ]], { 'vehicle', 'active' }) or {}

        local reportRows = MySQL.query.await([[
            SELECT UPPER(REPLACE(plate, ' ', '')) AS normalized_plate, COUNT(DISTINCT reportid) AS report_count
            FROM mdt_report_vehicles
            GROUP BY normalized_plate
        ]]) or {}

        local reportCountsByPlate = {}
        local activeBoloByPlate = {}
        local bolos = {}

        for _, reportRow in ipairs(reportRows) do
            if reportRow.normalized_plate and reportRow.normalized_plate ~= '' then
                reportCountsByPlate[reportRow.normalized_plate] = tonumber(reportRow.report_count) or 0
            end
        end

        for _, bolo in pairs(boloRows) do
            local plate = normalizePlate(bolo.subject_id)
            if plate ~= '' then
                activeBoloByPlate[plate] = true
            end

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

    payload = payload or {}
    local page = payload.page or payload.currentPage or 1
    local limit = payload.limit

    local directory = GetMdtVehicleDirectory()
    local bolos = directory.bolos or {}
    local pageResult = paginateRows(directory.vehicles or {}, page, limit)

    local endTime = os.clock()
    local elapsedTime = (endTime - startTime) * 1000
    ps.debug(string.format("getVehicles callback executed in %.2f ms (page %s, limit %s)", elapsedTime, tostring(pageResult.page), tostring(pageResult.limit)))

    return {
        vehicles = pageResult.data,
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

    if type(payload) ~= 'table' then
        payload = { query = payload }
    end

    local trimmedQuery = normalizeSearchTerm(payload.query)
    if trimmedQuery == '' then
        return { vehicles = {}, bolos = {}, page = 1, limit = payload.limit or 25, total = 0, hasMore = false }
    end

    local directory = GetMdtVehicleDirectory()
    local filtered = {}

    for _, vehicle in ipairs(directory.vehicles or {}) do
        if matchesVehicleQuery(vehicle, trimmedQuery) then
            filtered[#filtered + 1] = vehicle
        end
    end

    local pageResult = paginateRows(filtered, payload.page or 1, payload.limit)

    return {
        vehicles = pageResult.data,
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
    local vehicleTable = getVehicleTableName()
    if not vehicleTable then
        return { success = false, message = 'Tabela de veículos não encontrada' }
    end

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
    local vehicleTable = getVehicleTableName()
    if not vehicleTable then
        return { success = false, message = 'Tabela de veículos não encontrada' }
    end

    local informationExpr = hasColumn(vehicleTable, 'mdt_vehicle_information') and 'pv.mdt_vehicle_information' or 'NULL'
    local pointsExpr = hasColumn(vehicleTable, 'mdt_vehicle_points') and 'pv.mdt_vehicle_points' or '0'
    local statusExpr = hasColumn(vehicleTable, 'mdt_vehicle_status') and 'pv.mdt_vehicle_status' or "'valid'"
    local stolenExpr = hasColumn(vehicleTable, 'mdt_vehicle_stolen') and 'pv.mdt_vehicle_stolen' or '0'
    local boloExpr = hasColumn(vehicleTable, 'mdt_vehicle_boloactive') and 'pv.mdt_vehicle_boloactive' or '0'
    local imageExpr = hasColumn(vehicleTable, 'mdt_vehicle_image') and 'pv.mdt_vehicle_image' or 'NULL'
    local stateExpr = hasColumn(vehicleTable, 'state') and 'pv.state' or '0'

    local ownerExpr = buildVehicleOwnerExpr(vehicleTable, 'pv')
    local vehicleRow = MySQL.query.await(([[
        SELECT
            pv.id,
            pv.plate,
            COALESCE(NULLIF(pv.vehicle, ''), NULLIF(JSON_UNQUOTE(JSON_EXTRACT(pv.vehicle, '$.model')), ''), 'unknown') AS vehicle,
            %s AS citizenid,
            %s AS information,
            %s AS points,
            %s AS status,
            %s AS stolen,
            %s AS boloactive,
            %s AS image,
            %s AS core_state,
            CONCAT_WS(
                ' ',
                NULLIF(JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')), 'null'),
                NULLIF(JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname')), 'null')
            ) AS owner_name
        FROM %s pv
        LEFT JOIN players p
            ON p.citizenid COLLATE utf8mb4_general_ci = (%s) COLLATE utf8mb4_general_ci
        WHERE UPPER(REPLACE(pv.plate, ' ', '')) = ?
        LIMIT 1
    ]]):format(ownerExpr, informationExpr, pointsExpr, statusExpr, stolenExpr, boloExpr, imageExpr, stateExpr, vehicleTable, ownerExpr), { plate })

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
    local flags = buildVehicleFlags(row.stolen == 1, hasActiveBolo or row.boloactive == 1, row.status)

    return {
        success = true,
        vehicle = {
            id = row.id,
            model = row.vehicle,
            label = vehicleData and vehicleData.name or 'Veículo desconhecido',
            brand = vehicleData and vehicleData.brand or nil,
            plate = plateUpper,
            owner = buildOwnerName(row.owner_name, row.citizenid),
            class = formatLabel(vehicleData and vehicleData.category or 'Desconhecido'),
            type = formatLabel(vehicleData and vehicleData.type or 'Desconhecido'),
            image = (row.image and row.image ~= '' and row.image) or ('https://docs.fivem.net/vehicles/' .. row.vehicle .. '.webp'),
            information = row.information or '',
            points = tonumber(row.points) or 0,
            status = row.status or 'valid',
            core_state = tonumber(row.core_state) or 0,
            stolen = row.stolen == 1,
            boloactive = row.boloactive == 1,
            flags = flags,
            seenIn = reportCount,
            bolos = bolos,
        }
    }
end)
