-- ============================================================
-- PS-FORENSICS - Dispatcher central de callbacks NUI
-- ============================================================

local resourceName = GetCurrentResourceName()

local function respond(cb, payload)
    cb(payload or { success = false, error = 'Resposta vazia' })
end

local function serverCall(serverRoute, ...)
    return lib.callback.await(resourceName .. ':server:' .. serverRoute, false, ...)
end

local function withProgress(progressDef, handler)
    return function(data, cb)
        local completed = lib.progressBar(progressDef(data or {}))
        if not completed then
            return respond(cb, { success = false, error = L('test.canceled') })
        end

        local ok, result = pcall(handler, data or {})
        if not ok then
            print(('[%s] NUI callback erro com progress: %s'):format(resourceName, tostring(result)))
            return respond(cb, { success = false, error = 'Falha ao processar operação. Verifique o console.' })
        end

        if not result then
            print(('[%s] NUI callback com progress retornou nil do server'):format(resourceName))
            return respond(cb, { success = false, error = 'Sem resposta do servidor.' })
        end

        respond(cb, result)
    end
end

local directCallbacks = {
    { nui = 'getScenes', server = 'getScenes', args = function(data) return { data } end },
    { nui = 'getScene', server = 'getScene', args = function(data) return { data.id } end },
    { nui = 'updateScene', server = 'updateScene', args = function(data) return { data.id, data } end },

    { nui = 'getEvidenceList', server = 'getEvidenceList', args = function(data) return { data } end },
    { nui = 'getEvidence', server = 'getEvidence', args = function(data) return { data.id } end },
    { nui = 'updateEvidence', server = 'updateEvidence', args = function(data) return { data.id, data } end },
    { nui = 'transferEvidence', server = 'transferEvidence', args = function(data) return { data.evidenceId, data.toCitizenId, data.toName, data.notes } end },
    { nui = 'getCustodyChain', server = 'getCustodyChain', args = function(data) return { data.evidenceId } end },

    { nui = 'registerFingerprint', server = 'registerFingerprint', args = function(data) return { data.citizenid, data.name } end },
    { nui = 'registerDNA', server = 'registerDNAProfile', args = function(data) return { data.citizenid, data.name, data.bloodType } end },
    { nui = 'searchFingerprintsByCitizen', server = 'searchFingerprintsByCitizen', args = function(data) return { data.citizenid } end },
    { nui = 'searchDNAByCitizen', server = 'searchDNAByCitizen', args = function(data) return { data.citizenid } end },
    { nui = 'lookupCitizenProfile', server = 'lookupCitizenProfile', args = function(data) return { data.query or data.citizenid or data.name } end },
    { nui = 'lookupWeaponRegistry', server = 'lookupWeaponRegistry', args = function(data) return { data.serial } end },

    { nui = 'registerBallistic', server = 'registerBallistic', args = function(data) return { data } end },
    { nui = 'getWeaponBallisticHistory', server = 'getWeaponBallisticHistory', args = function(data) return { data.serial } end },

    { nui = 'requestLabTest', server = 'requestLabTest', args = function(data) return { data } end },
    { nui = 'getLabTests', server = 'getLabTests', args = function(data) return { data } end },

    { nui = 'registerDrugAnalysis', server = 'registerDrugAnalysis', args = function(data) return { data } end },
    { nui = 'confirmDrug', server = 'confirmDrugSubstance', args = function(data) return { data.id, data.substance, data.purity, data.result } end },
    { nui = 'getDrugAnalyses', server = 'getDrugAnalyses', args = function(data) return { data } end },

    { nui = 'createAutopsy', server = 'createAutopsy', args = function(data) return { data } end },
    { nui = 'updateAutopsy', server = 'updateAutopsy', args = function(data) return { data.id, data } end },
    { nui = 'getAutopsy', server = 'getAutopsy', args = function(data) return { data.id } end },
    { nui = 'getAutopsies', server = 'getAutopsies', args = function(data) return { data } end },

    { nui = 'createReport', server = 'createForensicReport', args = function(data) return { data } end },
    { nui = 'updateReport', server = 'updateForensicReport', args = function(data) return { data.id, data } end },
    { nui = 'finalizeReport', server = 'finalizeForensicReport', args = function(data) return { data.id } end },
    { nui = 'attachReportToMDT', server = 'attachReportToMDT', args = function(data) return { data.id } end },
    { nui = 'getReports', server = 'getForensicReports', args = function(data) return { data } end },
    { nui = 'getReport', server = 'getForensicReport', args = function(data) return { data.id } end },

    { nui = 'getCrossRefByCitizen', server = 'getCrossRefByCitizen', args = function(data) return { data.citizenid } end },
    { nui = 'getCrossRefByWeapon', server = 'getCrossRefByWeapon', args = function(data) return { data.serial } end },
    { nui = 'getCrossRefByVehicle', server = 'getCrossRefByVehicle', args = function(data) return { data.plate } end },
    { nui = 'getInvestigationDashboard', server = 'getInvestigationDashboard', args = function(data) return { data.citizenid } end },

    { nui = 'getForensicDataByCase', server = 'getForensicDataByCase', args = function(data) return { data.caseId } end },
    { nui = 'getMDTCases', server = 'getMDTCases', args = function(data) return { data } end },
    { nui = 'getForensicDataByReport', server = 'getForensicDataByReport', args = function(data) return { data.reportId } end },
    { nui = 'getForensicDataByCitizen', server = 'getForensicDataByCitizen', args = function(data) return { data.citizenid } end },
    { nui = 'getForensicDataByWeapon', server = 'getForensicDataByWeapon', args = function(data) return { data.serial } end },
    { nui = 'getForensicDataByVehicle', server = 'getForensicDataByVehicle', args = function(data) return { data.plate } end },
    { nui = 'getForensicDataByEvidence', server = 'getForensicDataByEvidence', args = function(data) return { data.evidenceId } end },
    { nui = 'searchForensicGlobal', server = 'searchForensicGlobal', args = function(data) return { data } end },
    { nui = 'getMDTIntegrationBundle', server = 'getMDTIntegrationBundle', args = function(data) return { data } end },
    { nui = 'getForensicStats', server = 'getForensicStats', args = function(_) return {} end },
    { nui = 'addScenePhoto', server = 'addScenePhoto', args = function(data) return { data.sceneId, data.photo } end },
}

for _, def in ipairs(directCallbacks) do
    RegisterNUICallback(def.nui, function(data, cb)
        local ok, result = pcall(function()
            local args = def.args and def.args(data or {}) or { data }
            return serverCall(def.server, table.unpack(args))
        end)

        if not ok then
            print(('[%s] NUI callback "%s" falhou: %s'):format(resourceName, def.nui, tostring(result)))
            return respond(cb, { success = false, error = 'Falha interna ao processar callback.' })
        end

        if result == nil then
            print(('[%s] NUI callback "%s" retornou nil do server'):format(resourceName, def.nui))
            return respond(cb, { success = false, error = 'Sem resposta do servidor.' })
        end

        respond(cb, result)
    end)
end

RegisterNUICallback('close', function(_, cb)
    CloseForensicsUI()
    respond(cb, 'ok')
end)

RegisterNUICallback('createScene', function(data, cb)
    local ok, result = pcall(function()
        local payload = data or {}
        local coords = GetEntityCoords(PlayerPedId())
        payload.x, payload.y, payload.z = coords.x, coords.y, coords.z

        local streetHash = select(1, GetStreetNameAtCoord(coords.x, coords.y, coords.z))
        local streetName = (streetHash and streetHash ~= 0) and GetStreetNameFromHashKey(streetHash) or nil
        payload.location_name = payload.location_name or streetName or L('scene.unknown_location')

        print(('[%s] NUI createScene -> enviando ao server: classification=%s, location=%s'):format(
            resourceName, tostring(payload.classification), tostring(payload.location_name)))

        return serverCall('createScene', payload)
    end)

    if not ok then
        print(('[%s] NUI callback "createScene" falhou: %s'):format(resourceName, tostring(result)))
        return respond(cb, { success = false, error = 'Falha ao criar cena de crime. Verifique o console do servidor.' })
    end

    if not result then
        print(('[%s] NUI callback "createScene" retornou nil do server'):format(resourceName))
        return respond(cb, { success = false, error = 'Sem resposta do servidor ao criar cena.' })
    end

    print(('[%s] NUI createScene <- resposta: success=%s'):format(resourceName, tostring(result.success)))
    respond(cb, result)
end)

RegisterNUICallback('collectEvidence', withProgress(function()
    return {
        duration = ((Config.TestProcessingTimes and Config.TestProcessingTimes['coleta_digital']) or 10) * 1000,
        label = L('evidence.collecting'),
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = { dict = 'anim@gangops@facility@servers@bodysearch@', clip = 'player_search' },
    }
end, function(data)
    local payload = data or {}
    local coords = GetEntityCoords(PlayerPedId())
    payload.x, payload.y, payload.z = coords.x, coords.y, coords.z

    local streetHash = select(1, GetStreetNameAtCoord(coords.x, coords.y, coords.z))
    local streetName = (streetHash and streetHash ~= 0) and GetStreetNameFromHashKey(streetHash) or nil
    payload.location_name = payload.location_name or streetName or ''

    return serverCall('collectEvidence', payload)
end))

RegisterNUICallback('collectFingerprint', withProgress(function()
    return {
        duration = ((Config.TestProcessingTimes and Config.TestProcessingTimes['coleta_digital']) or 12) * 1000,
        label = L('test.collecting_fingerprint'),
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a' },
    }
end, function(data) return serverCall('collectFingerprint', data) end))

RegisterNUICallback('analyzeFingerprint', withProgress(function()
    return {
        duration = ((Config.TestProcessingTimes and Config.TestProcessingTimes['comparacao_digital']) or 40) * 1000,
        label = L('test.processing_fingerprint'),
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
    }
end, function(data) return serverCall('analyzeFingerprint', data.id) end))

RegisterNUICallback('collectDNA', withProgress(function()
    return {
        duration = ((Config.TestProcessingTimes and Config.TestProcessingTimes['coleta_dna']) or 15) * 1000,
        label = L('test.collecting_dna'),
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = { dict = 'anim@gangops@facility@servers@bodysearch@', clip = 'player_search' },
    }
end, function(data) return serverCall('collectDNASample', data) end))

RegisterNUICallback('analyzeDNA', withProgress(function()
    return {
        duration = ((Config.TestProcessingTimes and Config.TestProcessingTimes['comparacao_dna']) or 60) * 1000,
        label = L('test.processing_dna'),
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
    }
end, function(data) return serverCall('analyzeDNA', data.id) end))

RegisterNUICallback('ballisticComparison', withProgress(function()
    return {
        duration = ((Config.TestProcessingTimes and Config.TestProcessingTimes['confronto_balistico']) or 45) * 1000,
        label = L('test.running_ballistics'),
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
    }
end, function(data) return serverCall('ballisticComparison', data.ballisticId, data.weaponSerial) end))

RegisterNUICallback('performLabTest', withProgress(function(data)
    local testType = data and data.test_type or 'outro'
    local duration = Config.TestProcessingTimes and Config.TestProcessingTimes[testType] or 20
    return {
        duration = duration * 1000,
        label = L('test.running'),
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
    }
end, function(data) return serverCall('performLabTest', data.id) end))

RegisterNUICallback('performToxicology', withProgress(function()
    return {
        duration = ((Config.TestProcessingTimes and Config.TestProcessingTimes['toxicologico']) or 50) * 1000,
        label = L('test.running_toxicology'),
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
    }
end, function(data) return serverCall('performToxicology', data.id) end))
