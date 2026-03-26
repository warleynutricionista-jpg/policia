local resourceName = tostring(GetCurrentResourceName())

local trackingCache = {
    payload = nil,
    expiresAt = 0,
}

local OFFICER_RESOURCE = 'qb-activeofficers'
local GARAGE_RESOURCE = 'rhd_garage'

local OFFICER_EXPORT_CANDIDATES = {
    'GetActiveOfficers',
    'GetActiveOfficersData',
    'GetOfficerLocations',
    'GetOfficers',
    'GetUnits',
}

local GARAGE_EXPORT_CANDIDATES = {
    'GetActiveVehicles',
    'GetTrackedVehicles',
    'GetSpawnedVehicles',
    'GetVehiclesInUse',
    'GetPoliceVehiclesInUse',
}

local function trim(value)
    if value == nil then return '' end
    return tostring(value):gsub('^%s*(.-)%s*$', '%1')
end

local function normalizeCoords(coords)
    if not coords then return nil end

    if type(coords) == 'vector3' then
        return { x = coords.x, y = coords.y, z = coords.z }
    end

    if type(coords) ~= 'table' then return nil end

    if coords.x and coords.y then
        return {
            x = tonumber(coords.x) or 0.0,
            y = tonumber(coords.y) or 0.0,
            z = tonumber(coords.z) or 0.0,
        }
    end

    if coords[1] and coords[2] then
        return {
            x = tonumber(coords[1]) or 0.0,
            y = tonumber(coords[2]) or 0.0,
            z = tonumber(coords[3]) or 0.0,
        }
    end

    return nil
end

local function isPoliceVehicleByModel(vehicleEntity)
    if not vehicleEntity or vehicleEntity == 0 then return false end

    local vehicleClass = GetVehicleClass(vehicleEntity)
    if vehicleClass == 18 then
        return true
    end

    return IsVehicleSirenOn(vehicleEntity) or IsVehicleSirenAudioOn(vehicleEntity)
end

local function getOnDutyOfficerSnapshotsFallback()
    local ok, snapshots = pcall(function()
        return exports[resourceName]:GetOnDutyOfficerSnapshots()
    end)

    if not ok or type(snapshots) ~= 'table' then
        return {}
    end

    return snapshots
end

local function callExportCandidates(targetResource, exportNames)
    if GetResourceState(targetResource) ~= 'started' then
        return nil
    end

    for _, exportName in ipairs(exportNames) do
        local ok, result = pcall(function()
            return exports[targetResource][exportName]()
        end)

        if ok and type(result) == 'table' then
            return result
        end
    end

    return nil
end

local function getOfficerSnapshotsFromActiveOfficers()
    local raw = callExportCandidates(OFFICER_RESOURCE, OFFICER_EXPORT_CANDIDATES)
    if type(raw) ~= 'table' then
        return nil
    end

    local snapshots = {}

    for _, officer in pairs(raw) do
        local src = tonumber(officer.source or officer.src or officer.id or officer.playerId)
        local coords = normalizeCoords(officer.coords or officer.location or officer.position)

        if (not coords) and src then
            local ped = GetPlayerPed(src)
            if ped and ped ~= 0 then
                local pedCoords = GetEntityCoords(ped)
                coords = { x = pedCoords.x, y = pedCoords.y, z = pedCoords.z }
            end
        end

        local heading = tonumber(officer.heading or officer.h or 0.0)
        if heading == 0.0 and src then
            local ped = GetPlayerPed(src)
            if ped and ped ~= 0 then
                heading = GetEntityHeading(ped)
            end
        end

        if src and coords then
            local citizenid = officer.citizenid or officer.citizenId or officer.cid
            local callsign = officer.callsign or officer.callSign or officer.badge
            local officerName = officer.name or officer.fullname or officer.fullName
            local rank = officer.rank or officer.grade
            local job = officer.job

            snapshots[#snapshots + 1] = {
                source = src,
                citizenid = citizenid,
                name = officerName or (GetPlayerName(src) or 'Desconhecido'),
                callsign = callsign,
                rank = rank,
                job = job,
                coords = coords,
                heading = heading,
                status = officer.status or officer.state or (officer.onduty and 'onduty' or nil),
                ped = GetPlayerPed(src),
            }
        end
    end

    return snapshots
end

local function getOfficerTrackers(officerSnapshots)
    local officers = {}

    for _, officer in ipairs(officerSnapshots) do
        officers[#officers + 1] = {
            id = officer.source,
            citizenid = officer.citizenid,
            name = officer.name,
            callsign = officer.callsign,
            rank = officer.rank,
            job = officer.job,
            status = officer.status or 'onduty',
            coords = officer.coords,
            heading = officer.heading,
        }
    end

    return officers
end

local function getBodycamTrackers(officerSnapshots)
    local bodycams = {}

    for _, officer in ipairs(officerSnapshots) do
        bodycams[#bodycams + 1] = {
            id = officer.source,
            citizenid = officer.citizenid,
            name = officer.name,
            callsign = officer.callsign,
            status = officer.status or 'onduty',
            coords = officer.coords,
            heading = officer.heading,
        }
    end

    return bodycams
end

local function buildVehicleFromEntity(vehicleEntity, officer)
    local coords = GetEntityCoords(vehicleEntity)
    local heading = GetEntityHeading(vehicleEntity)
    local plate = trim(GetVehicleNumberPlateText(vehicleEntity) or '')

    return {
        id = plate ~= '' and plate or tostring(vehicleEntity),
        plate = plate,
        coords = { x = coords.x, y = coords.y, z = coords.z },
        heading = heading,
        status = 'in_use',
        markerType = 'vehicle',
        officerName = officer and officer.name or nil,
        callsign = officer and officer.callsign or nil,
        source = officer and officer.source or nil,
    }
end

local function getVehiclesFromOfficerSnapshots(officerSnapshots)
    local vehicles = {}
    local seenVehicles = {}

    for _, officer in ipairs(officerSnapshots) do
        local ped = officer.ped or GetPlayerPed(officer.source)
        if ped and ped ~= 0 then
            local vehicle = GetVehiclePedIsIn(ped, false)
            if vehicle and vehicle ~= 0 and not seenVehicles[vehicle] then
                seenVehicles[vehicle] = true

                if isPoliceVehicleByModel(vehicle) then
                    vehicles[#vehicles + 1] = buildVehicleFromEntity(vehicle, officer)
                end
            end
        end
    end

    return vehicles
end

local function isOfficialVehicleFromGarageRow(vehicle)
    local job = trim(vehicle.job or vehicle.garageJob or vehicle.department):lower()
    local garage = trim(vehicle.garage or vehicle.garageName):lower()
    local isPoliceFlag = vehicle.isPolice == true or vehicle.official == true or vehicle.isOfficial == true

    if isPoliceFlag then return true end
    if IsPoliceJob(job, nil) then return true end
    if job:find('police', 1, true) then return true end
    if garage:find('police', 1, true) then return true end

    return false
end

local function getGarageVehicles(officerSnapshots)
    local raw = callExportCandidates(GARAGE_RESOURCE, GARAGE_EXPORT_CANDIDATES)
    if type(raw) ~= 'table' then
        return nil
    end

    local vehicles = {}
    local seen = {}

    for _, vehicle in pairs(raw) do
        if isOfficialVehicleFromGarageRow(vehicle) then
            local coords = normalizeCoords(vehicle.coords or vehicle.location or vehicle.position)
            local plate = trim(vehicle.plate or vehicle.licensePlate or vehicle.props and vehicle.props.plate)

            local entity = tonumber(vehicle.entity or vehicle.vehicle or vehicle.netId)
            if (not coords) and entity and entity ~= 0 and DoesEntityExist(entity) then
                local entityCoords = GetEntityCoords(entity)
                coords = { x = entityCoords.x, y = entityCoords.y, z = entityCoords.z }
            end

            if coords then
                local id = plate ~= '' and plate or tostring(entity or (#vehicles + 1))
                if not seen[id] then
                    seen[id] = true
                    vehicles[#vehicles + 1] = {
                        id = id,
                        plate = plate,
                        coords = coords,
                        heading = tonumber(vehicle.heading or 0.0),
                        status = trim(vehicle.status) ~= '' and trim(vehicle.status) or 'in_use',
                        markerType = 'vehicle',
                        job = vehicle.job,
                        garage = vehicle.garage or vehicle.garageName,
                        source = tonumber(vehicle.source or vehicle.src or vehicle.playerId),
                        officerName = vehicle.officerName or vehicle.driverName,
                        callsign = vehicle.callsign,
                    }
                end
            end
        end
    end

    if #vehicles == 0 then
        return getVehiclesFromOfficerSnapshots(officerSnapshots)
    end

    return vehicles
end

local function getTrackingSources()
    local officerSnapshots = getOfficerSnapshotsFromActiveOfficers()
    if type(officerSnapshots) ~= 'table' or #officerSnapshots == 0 then
        officerSnapshots = getOnDutyOfficerSnapshotsFallback()
    end

    local vehicles = getGarageVehicles(officerSnapshots)
    if type(vehicles) ~= 'table' then
        vehicles = getVehiclesFromOfficerSnapshots(officerSnapshots)
    end

    return officerSnapshots, vehicles
end

ps.registerCallback(resourceName .. ':server:getTracking', function(source)
    local src = source
    if not CheckAuth(src) then
        return { officers = {}, vehicles = {}, bodycams = {} }
    end

    local now = GetGameTimer()
    if trackingCache.payload and trackingCache.expiresAt > now then
        return trackingCache.payload
    end

    local snapshots, vehicles = getTrackingSources()

    local payload = {
        officers = getOfficerTrackers(snapshots),
        vehicles = vehicles,
        bodycams = getBodycamTrackers(snapshots),
    }

    trackingCache.payload = payload
    trackingCache.expiresAt = now + 1000

    return payload
end)
