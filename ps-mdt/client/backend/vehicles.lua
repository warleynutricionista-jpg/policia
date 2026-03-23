local resourceName = tostring(GetCurrentResourceName())

local function handleGetVehicles(cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto', vehicles = {}, bolos = {} })
        return
    end
    local vehicleList = ps.callback(resourceName .. ':server:GetVehicles')
    ps.debug('[getVehicles] Triggered NUI callback on client', vehicleList)
    cb(vehicleList)
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

RegisterNUICallback('getVehicles', function(_, cb)
    handleGetVehicles(cb)
end)

RegisterNUICallback('getVeículos', function(_, cb)
    handleGetVehicles(cb)
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
    local result = ps.callback(resourceName .. ':server:SearchVehicles', query)
    cb(result or { vehicles = {}, bolos = {} })
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
