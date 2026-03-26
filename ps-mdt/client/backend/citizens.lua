local resourceName = tostring(GetCurrentResourceName())
local citizenSearchState = {
    lastQuery = '',
    lastAt = 0,
    lastResult = { citizens = {}, page = 1, limit = 20, total = 0, hasMore = false }
}
local SEARCH_DEBOUNCE_MS = 250

RegisterNUICallback('getCitizens', function(data, cb)
    if not MDTOpen then
        cb({ citizens = {}, page = 1, limit = (data and data.limit) or 20, total = 0, hasMore = false })
        return
    end
    if type(data) ~= 'table' then
        data = {page = 1}
    end
    local page = data.page or 1 -- Default to page 1 if not provided
    local result = ps.callback(resourceName..':server:getCitizens', { page = page, limit = data.limit })
    ps.debug(('[getCitizens] Triggered NUI callback on client for page %d'):format(page), result)
    cb(result or { citizens = {}, page = page, limit = data.limit or 20, total = 0, hasMore = false })
end)

RegisterNUICallback('searchCitizens', function(data, cb)
    if not MDTOpen then
        cb({ citizens = {}, page = 1, limit = (data and data.limit) or 20, total = 0, hasMore = false })
        return
    end
    if not data or not data.query then
        cb({ citizens = {}, page = 1, limit = (data and data.limit) or 20, total = 0, hasMore = false })
        return
    end
    local query = tostring(data.query)
    if #query < 2 then
        citizenSearchState.lastResult = { citizens = {}, page = 1, limit = data.limit or 20, total = 0, hasMore = false }
        cb(citizenSearchState.lastResult)
        return
    end

    local now = GetGameTimer()
    if citizenSearchState.lastQuery == query and (now - citizenSearchState.lastAt) < SEARCH_DEBOUNCE_MS then
        cb(citizenSearchState.lastResult)
        return
    end

    local result = ps.callback(resourceName..':server:searchCitizens', {
        query = query,
        page = data.page or 1,
        limit = data.limit
    })

    citizenSearchState.lastQuery = query
    citizenSearchState.lastAt = now
    citizenSearchState.lastResult = result or { citizens = {}, page = data.page or 1, limit = data.limit or 20, total = 0, hasMore = false }
    cb(citizenSearchState.lastResult)
end)

RegisterNUICallback('getBolos', function(data, cb)
    if not MDTOpen then cb({}) return end
    local boloType = 'citizen'
    local boloStatus = nil
    if type(data) == 'table' then
        if data.type and data.type ~= '' then
            boloType = data.type
        end
        if data.status and data.status ~= '' then
            boloStatus = data.status
        end
    end
    if boloType == 'all' then
        boloStatus = boloStatus or 'all'
    end
    local result = ps.callback(resourceName..':server:getBOLO', boloType, boloStatus)
    ps.debug('[getBolos] Fetched BOLOs:', result)
    cb(result)
end)

RegisterNUICallback('createBolo', function(data, cb)
    if not MDTOpen then cb({ success = false }) return end
    local result = ps.callback(resourceName .. ':server:createBolo', data)
    cb(result or { success = false })
end)

RegisterNUICallback('deleteBolo', function(data, cb)
    if not MDTOpen then cb({ success = false }) return end
    if not data or not data.id then
        cb({ success = false, message = 'Faltando ID do procurado' })
        return
    end
    local result = ps.callback(resourceName .. ':server:deleteBolo', data)
    cb(result or { success = false })
end)

RegisterNUICallback('updateBoloStatus', function(data, cb)
    if not MDTOpen then cb({ success = false }) return end
    if not data or not data.id or not data.status then
        cb({ success = false, message = 'Faltando ID do procurado ou status' })
        return
    end
    local result = ps.callback(resourceName .. ':server:updateBoloStatus', data)
    cb(result or { success = false })
end)

RegisterNUICallback('viewBolo', function(data, cb)
    cb({})
    if data and data.boloId then
        TriggerServerEvent(resourceName..':server:viewBolo', data.boloId)
    end
end)

RegisterNetEvent('ps-mdt:client:viewReport', function(reportId)
    if not reportId then return end
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'viewReport', reportId = tostring(reportId) })
end)

RegisterNUICallback('getCitizen', function(data, cb)
    if not MDTOpen then cb({}) return end
    if not data or not data.citizenid then
        cb({ success = false, message = 'Faltando ID do cidadão' })
        return
    end

    local result = ps.callback(resourceName .. ':server:getCitizenProfile', data.citizenid)
    if result then
        cb(result)
    else
        cb({ success = false, message = 'Cidadão não encontrado' })
    end
end)

RegisterNUICallback('updateCitizenLicense', function(data, cb)
    if not MDTOpen then cb({ success = false, message = 'O MDT não está aberto' }) return end
    if not data or not data.citizenid or not data.license then
        cb({ success = false, message = 'Faltando ID do cidadão ou licença' })
        return
    end

    local result = ps.callback(resourceName .. ':server:updateCitizenLicense', data)
    if result then
        cb(result)
    else
        cb({ success = false, message = 'Falha ao atualizar a licença' })
    end
end)

RegisterNUICallback('updateCitizenCustomLicense', function(data, cb)
    if not MDTOpen then cb({ success = false, message = 'O MDT não está aberto' }) return end
    if not data or not data.citizenid or not data.licenseId then
        cb({ success = false, message = 'Faltando ID do cidadão ou licença id' })
        return
    end
    local result = ps.callback(resourceName .. ':server:updateCitizenCustomLicense', data)
    cb(result or { success = false, message = 'Falha ao atualizar a licença personalizada' })
end)

RegisterNUICallback('updateCitizen', function(data, cb)
    if not MDTOpen then cb({ success = false, message = 'O MDT não está aberto' }) return end
    if not data or not data.citizenid then
        cb({ success = false, message = 'Faltando ID do cidadão' })
        return
    end
    local result = ps.callback(resourceName .. ':server:updateCitizen', data)
    cb(result or { success = false, message = 'Falha ao atualizar o cidadão' })
end)

RegisterNUICallback('addCitizenTag', function(data, cb)
    if not MDTOpen then cb({ success = false }) return end
    if not data or not data.citizenid or not data.tag then
        cb({ success = false, message = 'Faltando ID do cidadão ou tag' })
        return
    end
    local result = ps.callback(resourceName .. ':server:addCitizenTag', data)
    cb(result or { success = false })
end)

RegisterNUICallback('removeCitizenTag', function(data, cb)
    if not MDTOpen then cb({ success = false }) return end
    if not data or not data.citizenid or not data.tag then
        cb({ success = false, message = 'Faltando ID do cidadão ou tag' })
        return
    end
    local result = ps.callback(resourceName .. ':server:removeCitizenTag', data)
    cb(result or { success = false })
end)

RegisterNUICallback('addCitizenGallery', function(data, cb)
    if not MDTOpen then cb({ success = false }) return end
    if not data or not data.citizenid or not data.image then
        cb({ success = false, message = 'Faltando ID do cidadão ou imagem' })
        return
    end
    local result = ps.callback(resourceName .. ':server:addCitizenGallery', data)
    cb(result or { success = false })
end)

RegisterNUICallback('removeCitizenGallery', function(data, cb)
    if not MDTOpen then cb({ success = false }) return end
    if not data or not data.citizenid or not data.image then
        cb({ success = false, message = 'Faltando ID do cidadão ou imagem' })
        return
    end
    local result = ps.callback(resourceName .. ':server:removeCitizenGallery', data)
    cb(result or { success = false })
end)

-- Add fingerprint to a suspect's record
RegisterNUICallback('addSuspectFingerprint', function(data, cb)
    if not MDTOpen then cb({ success = false }) return end
    if not data or not data.citizenid then
        cb({ success = false, message = 'Faltando ID do cidadão' })
        return
    end
    local result = ps.callback(resourceName .. ':server:addSuspectFingerprint', data.citizenid)
    cb(result or { success = false, message = 'Falha ao adicionar a impressão digital' })
end)

-- Capture mugshot from officer's view (hide MDT, screenshot, upload, re-show MDT)
RegisterNUICallback('triggerSuspectMugshot', function(data, cb)
    if not data or not data.citizenid then
        cb({ success = false, message = 'Faltando ID do cidadão' })
        return
    end
    -- Respond immediately to avoid NUI timeout (which closes the MDT)
    cb({ success = true, message = 'Iniciando captura de foto...' })
    -- Then run the async mugshot capture in a separate thread
    CreateThread(function()
        local ok, imageUrl = pcall(CaptureMugshot, data.citizenid)
        if ok and imageUrl then
            -- Notify the frontend with the captured image URL via NUI message
            SendNUIMessage({
                action = 'mugshotCaptured',
                data = {
                    success = true,
                    citizenid = data.citizenid,
                    imageUrl = imageUrl,
                    message = 'Foto de ficha capturada',
                }
            })
        else
            SendNUIMessage({
                action = 'mugshotCaptured',
                data = {
                    success = false,
                    citizenid = data.citizenid,
                    message = 'Falha ao capturar a foto de ficha',
                }
            })
        end
    end)
end)

-- Upload a profile photo for a suspect via base64
RegisterNUICallback('uploadSuspectPhoto', function(data, cb)
    if not MDTOpen then cb({ success = false }) return end
    if not data or not data.citizenid or not data.image then
        cb({ success = false, message = 'Faltando ID do cidadão ou imagem data' })
        return
    end
    local result = ps.callback(resourceName .. ':server:uploadSuspectPhoto', data.citizenid, data.image)
    cb(result or { success = false, message = 'Falha ao enviar a foto' })
end)
