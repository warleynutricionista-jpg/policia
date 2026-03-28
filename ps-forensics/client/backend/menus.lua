-- ============================================================
-- PS-FORENSICS - Menus ox_lib (Client)
-- Menus contextuais para ações rápidas no mundo
-- ============================================================

local resourceName = GetCurrentResourceName()

local function getMDTCaseOptions()
    local rows = lib.callback.await(resourceName .. ':server:getMDTCases', false, { limit = 200 })
    local options = {
        { value = '', label = L('common.optional') }
    }

    local caseRows = rows and rows.success and rows.data or {}
    for _, caseRow in ipairs(caseRows or {}) do
        local label = ('#%s | %s'):format(caseRow.id or '?', caseRow.title or L('labels.unknown'))
        options[#options + 1] = { value = tostring(caseRow.id), label = label }
    end

    return options
end

-- ============================================================
-- MENU: CRIAR CENA DE CRIME
-- ============================================================
function OpenCreateSceneMenu()
    local classOptions = ForensicUtils.GetSceneClassificationOptions()
    local caseOptions = getMDTCaseOptions()

    local input = lib.inputDialog(L('scene.title'), {
        { type = 'select', label = L('form.scene.classification'), options = classOptions, required = true },
        { type = 'textarea', label = L('form.scene.description'), required = false },
        { type = 'number', label = L('form.scene.perimeter_radius'), default = 50, min = 10, max = 200 },
        { type = 'input', label = L('form.scene.weather'), placeholder = L('form.scene.weather_placeholder') },
        { type = 'input', label = L('form.scene.lighting'), placeholder = L('form.scene.lighting_placeholder') },
        { type = 'select', label = L('form.scene.case_id'), options = caseOptions, required = false },
        { type = 'input', label = L('form.scene.report_id'), placeholder = L('common.optional') },
    })

    if not input then return end

    local coords = GetEntityCoords(PlayerPedId())
    local streetHash, _ = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)

    local result = lib.callback.await(resourceName .. ':server:createScene', false, {
        classification = input[1],
        description = input[2] or '',
        perimeter_radius = input[3] or 50,
        weather = input[4] or '',
        lighting = input[5] or '',
        case_id = input[6] ~= '' and input[6] or nil,
        report_id = input[7] ~= '' and input[7] or nil,
        location_name = streetName or L('scene.unidentified_location'),
        x = coords.x,
        y = coords.y,
        z = coords.z,
    })

    if result and result.success then
        lib.notify({
            title = L('scene.title'),
            description = L('scene.created_success', result.sceneNumber),
            type = 'success',
        })
    else
        lib.notify({
            title = L('common.error_title'),
            description = result and result.error or L('scene.create_failed'),
            type = 'error',
        })
    end
end

-- ============================================================
-- MENU: COLETAR EVIDÊNCIA
-- ============================================================
function OpenCollectEvidenceMenu()
    local categoryOptions = ForensicUtils.GetEvidenceCategoryOptions()

    -- Buscar tipos da categoria
    local input = lib.inputDialog(L('evidence.collecting'), {
        { type = 'select', label = L('form.evidence.category'), options = categoryOptions, required = true },
        { type = 'input', label = L('form.evidence.type'), placeholder = L('form.evidence.type_placeholder'), required = true },
        { type = 'input', label = L('form.evidence.subtype'), placeholder = L('form.evidence.subtype_placeholder') },
        { type = 'textarea', label = L('form.evidence.description'), placeholder = L('form.evidence.description_placeholder') },
        { type = 'input', label = L('form.evidence.collection_method'), placeholder = L('form.evidence.collection_method_placeholder') },
        { type = 'number', label = L('form.evidence.scene_id'), placeholder = L('form.evidence.scene_id_placeholder') },
        { type = 'select', label = L('form.evidence.priority'), options = {
            { value = 'baixa', label = L('form.priority.baixa') },
            { value = 'media', label = L('form.priority.media') },
            { value = 'alta', label = L('form.priority.alta') },
            { value = 'urgente', label = L('form.priority.urgente') },
        }, default = 'media' },
    })

    if not input then return end

    local coords = GetEntityCoords(PlayerPedId())
    local streetHash, _ = GetStreetNameAtCoord(coords.x, coords.y, coords.z)

    -- Animação de coleta
    lib.requestAnimDict('anim@gangops@facility@servers@bodysearch@')
    TaskPlayAnim(PlayerPedId(), 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, -8.0, 5000, 49, 0, false, false, false)

    if lib.progressBar({
        duration = 8000,
        label = L('evidence.collecting'),
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
    }) then
        ClearPedTasks(PlayerPedId())

        local result = lib.callback.await(resourceName .. ':server:collectEvidence', false, {
            category = input[1],
            type = input[2],
            subtype = input[3] or nil,
            description = input[4] or '',
            collection_method = input[5] or 'Manual',
            scene_id = input[6] and input[6] > 0 and input[6] or nil,
            priority = input[7] or 'media',
            location_name = GetStreetNameFromHashKey(streetHash) or '',
            x = coords.x, y = coords.y, z = coords.z,
        })

        if result and result.success then
            lib.notify({
                title = L('evidence.collected_title'),
                description = L('evidence.collected_message', result.evidenceNumber, result.sealNumber),
                type = 'success',
                duration = 8000,
            })
        else
            lib.notify({
                title = L('common.error_title'),
                description = result and result.error or L('evidence.collect_failed'),
                type = 'error',
            })
        end
    else
        ClearPedTasks(PlayerPedId())
    end
end

-- ============================================================
-- MENU: EXECUTAR TESTE RÁPIDO
-- ============================================================
function OpenRunTestMenu()
    local testOptions = ForensicUtils.GetQuickTestOptions()

    local input = lib.inputDialog(L('test.quick_title'), {
        { type = 'select', label = L('form.test.type'), options = testOptions, required = true },
        { type = 'input', label = L('form.test.target_name'), placeholder = L('form.test.target_name_placeholder') },
        { type = 'input', label = L('form.test.target_citizenid'), placeholder = L('form.test.target_citizenid_placeholder') },
        { type = 'textarea', label = L('form.test.notes'), placeholder = L('form.test.notes_placeholder') },
        { type = 'number', label = L('form.test.evidence_id'), placeholder = L('form.test.evidence_id_placeholder') },
        { type = 'number', label = L('form.test.scene_id'), placeholder = L('form.test.scene_id_placeholder') },
    })

    if not input then return end

    local testType = input[1]
    local duration = Config.TestProcessingTimes[testType] or 10
    local selectedTestLabel = testType
    for _, option in ipairs(testOptions) do
        if option.value == testType then
            selectedTestLabel = option.label
            break
        end
    end

    -- Solicitar teste
    local testResult = lib.callback.await(resourceName .. ':server:requestLabTest', false, {
        test_type = testType,
        test_name = L('test.quick_name_prefix') .. selectedTestLabel,
        target_name = input[2] or nil,
        target_citizenid = input[3] ~= '' and input[3] or nil,
        description = input[4] or '',
        evidence_id = input[5] and input[5] > 0 and input[5] or nil,
        scene_id = input[6] and input[6] > 0 and input[6] or nil,
    })

    if not testResult or not testResult.success then
        lib.notify({
            title = L('common.error_title'),
            description = testResult and testResult.error or L('test.request_failed'),
            type = 'error',
        })
        return
    end

    -- Executar teste com progressbar
    lib.requestAnimDict('mini@repair')
    TaskPlayAnim(PlayerPedId(), 'mini@repair', 'fixing_a_ped', 8.0, -8.0, -1, 49, 0, false, false, false)

    if lib.progressBar({
        duration = duration * 1000,
        label = L('test.running'),
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
    }) then
        ClearPedTasks(PlayerPedId())

        local performResult = lib.callback.await(resourceName .. ':server:performLabTest', false, testResult.id)

        if performResult and performResult.success then
            local resultColor = {
                confirmado = 'success',
                compativel = 'success',
                presumido = 'warning',
                inconclusivo = 'warning',
                negativo = 'inform',
            }

            lib.notify({
                title = L('test.result_title'),
                description = performResult.resultDetails or (L('test.result_prefix') .. (performResult.resultLevel or L('labels.na'))),
                type = resultColor[performResult.resultLevel] or 'inform',
                duration = 12000,
            })
        else
            lib.notify({
                title = L('common.error_title'),
                description = performResult and performResult.error or L('test.request_failed'),
                type = 'error',
            })
        end
    else
        ClearPedTasks(PlayerPedId())
        lib.notify({
            title = L('test.cancelled_title'),
            description = L('test.cancelled_desc'),
            type = 'error',
        })
    end
end

-- Teste GSR: acessível via aba Laboratório no painel /pericia
