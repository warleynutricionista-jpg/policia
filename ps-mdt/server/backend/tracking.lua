local resourceName = tostring(GetCurrentResourceName())
local trackingCache = {
    payload = nil,
    expiresAt = 0,
}

local function getOnDutyOfficerSnapshots()
    local ok, snapshots = pcall(function()
        return exports[resourceName]:GetOnDutyOfficerSnapshots()
    end)

    if not ok or type(snapshots) ~= 'table' then
        return {}
    end

    return snapshots
end

local function getOfficerTrackers(officerSnapshots)
    local officers = {}

    for _, officer in ipairs(officerSnapshots) do
        officers[#officers + 1] = {
            citizenid = officer.citizenid,
            name = officer.name,
            callsign = officer.callsign,
            rank = officer.rank,
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
            citizenid = officer.citizenid,
            name = officer.name,
            callsign = officer.callsign,
            coords = officer.coords,
            heading = officer.heading,
        }
    end

    return bodycams
end

local function getVehicleTrackers(officerSnapshots)
    local vehicles = {}
    local seenVehicles = {}

    for _, officer in ipairs(officerSnapshots) do
        local ped = officer.ped or GetPlayerPed(officer.source)
        if ped and ped ~= 0 then
            local vehicle = GetVehiclePedIsIn(ped, false)
            if vehicle and vehicle ~= 0 and not seenVehicles[vehicle] then
                seenVehicles[vehicle] = true

                local vehicleClass = GetVehicleClass(vehicle)
                local isEmergency = vehicleClass == 18
                local hasPoliceSiren = IsVehicleSirenOn(vehicle) or IsVehicleSirenAudioOn(vehicle)

                if isEmergency or hasPoliceSiren then
                    local coords = GetEntityCoords(vehicle)
                    local heading = GetEntityHeading(vehicle)
                    local plate = (GetVehicleNumberPlateText(vehicle) or ''):gsub('^%s*(.-)%s*$', '%1')

                    vehicles[#vehicles + 1] = {
                        plate = plate,
                        coords = { x = coords.x, y = coords.y, z = coords.z },
                        heading = heading,
                        officerName = officer.name,
                        callsign = officer.callsign,
                    }
                end
            end
        end
    end

    return vehicles
end

ps.registerCallback(resourceName .. ':server:getTracking', function(source)
    local src = source
    if not CheckAuth(src) then return { officers = {}, vehicles = {}, bodycams = {} } end

    local now = GetGameTimer()
    if trackingCache.payload and trackingCache.expiresAt > now then
        return trackingCache.payload
    end

    local snapshots = getOnDutyOfficerSnapshots()
    local payload = {
        officers = getOfficerTrackers(snapshots),
        vehicles = getVehicleTrackers(snapshots),
        bodycams = getBodycamTrackers(snapshots),
    }

    trackingCache.payload = payload
    trackingCache.expiresAt = now + 1000

    return payload
end)
