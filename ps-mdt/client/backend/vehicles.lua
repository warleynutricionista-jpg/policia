local resourceName = tostring(GetCurrentResourceName())
local vehicleSearchState = {
    lastQuery = '',
    lastAt = 0,
    lastResult = { vehicles = {}, bolos = {}, page = 1, limit = 25, total = 0, hasMore = false }
}
local VEHICLE_SEARCH_DEBOUNCE_MS = 250

local function handleGetVehicles(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto', vehicles = {}, bolos = {}, page = 1, limit = 25, total = 0, hasMore = false })
        return
    end
    data = data or {}
    local vehicleList = ps.callback(resourceName .. ':server:GetVehicles', { page = data.page or 1, limit = data.limit })
    ps.debug('[getVehicles] Triggered NUI callback on client', vehicleList)
    cb(vehicleList or { vehicles = {}, bolos = {}, page = data.page or 1, limit = data.limit or 25, total = 0, hasMore = false })
end

local function handleGetVehicle(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    if type(data) ~= 'table' or not data.plate then
        cb({ success = false, message = 'Faltando placa' })
        return
    end

    local result = ps.callback(resourceName .. ':server:GetVehicle', data.plate)
    if result then
        cb(result)
    else
        cb({ success = false, message = 'Veículo não encontrado' })
    end
end

local function handleUpdateVehicle(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    if type(data) ~= 'table' or not data.plate then
        cb({ success = false, message = 'Faltando placa' })
        return
    end

    local result = ps.callback(resourceName .. ':server:UpdateVehicle', data)
    if result then
        cb(result)
    else
        cb({ success = false, message = 'Falha ao atualizar o veículo' })
    end
end

RegisterNUICallback('getVehicles', function(data, cb)
    handleGetVehicles(data, cb)
end)

RegisterNUICallback('getVeículos', function(data, cb)
    handleGetVehicles(data, cb)
end)

RegisterNUICallback('getVehicleBolos', function(data, cb)
    if not MDTOpen then cb({}) return end
    local result = ps.callback(resourceName .. ':server:getBOLO', 'vehicle')
    ps.debug('[getVehicleBolos] Fetched vehicle BOLOs:', result)
    cb(result)
end)

RegisterNUICallback('getVehicle', function(data, cb)
    handleGetVehicle(data, cb)
end)

RegisterNUICallback('updateVehicle', function(data, cb)
    handleUpdateVehicle(data, cb)
end)

RegisterNUICallback('getVeículo', function(data, cb)
    handleGetVehicle(data, cb)
end)

RegisterNUICallback('updateVeículo', function(data, cb)
    handleUpdateVehicle(data, cb)
end)

RegisterNUICallback('searchVeículos', function(data, cb)
    if not MDTOpen then
        cb({ vehicles = {}, bolos = {} })
        return
    end

    local query = data and data.query or ''
    if query == '' then
        cb({ vehicles = {}, bolos = {}, page = 1, limit = data and data.limit or 25, total = 0, hasMore = false })
        return
    end

    local now = GetGameTimer()
    if vehicleSearchState.lastQuery == query and (now - vehicleSearchState.lastAt) < VEHICLE_SEARCH_DEBOUNCE_MS then
        cb(vehicleSearchState.lastResult)
        return
    end

    local result = ps.callback(resourceName .. ':server:SearchVehicles', {
        query = query,
        page = data and data.page or 1,
        limit = data and data.limit or nil
    })
    vehicleSearchState.lastQuery = query
    vehicleSearchState.lastAt = now
    vehicleSearchState.lastResult = result or { vehicles = {}, bolos = {}, page = data and data.page or 1, limit = data and data.limit or 25, total = 0, hasMore = false }
    cb(vehicleSearchState.lastResult)
end)

RegisterNUICallback('getReportsByPlate', function(data, cb)
    if not MDTOpen then
        cb({ success = false, reports = {} })
        return
    end

    if type(data) ~= 'table' or not data.plate then
        cb({ success = false, reports = {} })
        return
    end

    local result = ps.callback(resourceName .. ':server:getReportsByPlate', data.plate)
    cb({ success = true, reports = result or {} })
end)

RegisterNUICallback('getReportsByPlaca', function(data, cb)
    if not MDTOpen then
        cb({ success = false, reports = {} })
        return
    end

    if type(data) ~= 'table' or not data.plate then
        cb({ success = false, reports = {} })
        return
    end

    local result = ps.callback(resourceName .. ':server:getReportsByPlate', data.plate)
    cb({ success = true, reports = result or {} })
end)
