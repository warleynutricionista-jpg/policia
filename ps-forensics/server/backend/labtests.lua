-- ============================================================
-- PS-FORENSICS - Módulo: Testes Laboratoriais (Server)
-- ============================================================

local resourceName = GetCurrentResourceName()

local BASIC_TESTS = {
    residuo_polvora_maos = true,
    residuo_polvora_roupa = true,
    residuo_polvora_arma = true,
    residuo_polvora_veiculo = true,
    teste_droga_presuntivo = true,
    teste_sangue_presuntivo = true,
    coleta_digital = true,
    coleta_dna = true,
}

local REQUIRED_ITEM_BY_TEST = {
    residuo_polvora_maos = Config.Items.gsr_kit,
    residuo_polvora_roupa = Config.Items.gsr_kit,
    residuo_polvora_arma = Config.Items.gsr_kit,
    residuo_polvora_veiculo = Config.Items.gsr_kit,
    teste_droga_presuntivo = Config.Items.drug_test_kit,
    analise_substancia = Config.Items.drug_test_kit,
    teste_sangue_presuntivo = Config.Items.blood_reagent,
}

local VALID_RESULT_LEVELS = {
    pendente = true,
    presumido = true,
    inconclusivo = true,
    compativel = true,
    confirmado = true,
    negativo = true,
}

local function hasRequiredItem(src, itemName)
    if not itemName then return true end
    if GetResourceState('ox_inventory') ~= 'started' then return true end
    return (exports.ox_inventory:GetItemCount(src, itemName) or 0) > 0
end

local function isBasicTest(testType)
    if not testType then return false end
    return BASIC_TESTS[testType] or testType:find('residuo_polvora') ~= nil
end

local function normalizeResultLevel(level)
    local l = (level or 'inconclusivo'):lower()
    return VALID_RESULT_LEVELS[l] and l or 'inconclusivo'
end

local function getProcessingTier(seconds)
    local s = tonumber(seconds) or 0
    if s <= 15 then return 'simples' end
    if s <= 60 then return 'medio' end
    return 'complexo'
end

local function getUnixFromSQLTimestamp(ts)
    if not ts or ts == '' then return nil end
    if type(ts) == 'number' then return ts end
    local y, m, d, h, mi, s = tostring(ts):match('^(%d+)%-(%d+)%-(%d+)%s+(%d+):(%d+):(%d+)')
    if not y then return nil end
    return os.time({
        year = tonumber(y), month = tonumber(m), day = tonumber(d),
        hour = tonumber(h), min = tonumber(mi), sec = tonumber(s),
    })
end

local function validateEvidenceAndSceneLinks(data)
    local evidenceId = data.evidence_id and tonumber(data.evidence_id) or nil
    local sceneId = data.scene_id and tonumber(data.scene_id) or nil
    local resolvedReportId = nil

    if evidenceId then
        local evidence = MySQL.single.await('SELECT id, status, report_id, scene_id FROM forensic_evidence WHERE id = ?', { evidenceId })
        if not evidence then
            return false, L('evidence.errors.not_found')
        end
        if evidence.status == 'descartada' or evidence.status == 'devolvida' then
            return false, L('lab.errors.evidence_finalized')
        end
        resolvedReportId = evidence.report_id
        sceneId = sceneId or evidence.scene_id
    end

    if sceneId then
        local scene = MySQL.single.await('SELECT id, status, report_id FROM forensic_crime_scenes WHERE id = ?', { sceneId })
        if not scene then
            return false, L('scene.errors.not_found')
        end
        resolvedReportId = resolvedReportId or scene.report_id
    end

    if resolvedReportId then
        local report = MySQL.single.await('SELECT id, report_status FROM mdt_reports WHERE id = ? LIMIT 1', { resolvedReportId })
        if not report then
            return false, L('reports.errors.not_found')
        end
        if report.report_status == 'archived' then
            return false, L('reports.errors.archived')
        end
    end

    return true, nil
end

-- ============================================================
-- SOLICITAR TESTE
-- ============================================================
lib.callback.register(resourceName .. ':server:requestLabTest', function(source, data)
    local src = source
    if not CheckForensicAuth(src) then return { success = false, error = L('lab.errors.not_authorized') } end
    data = data or {}

    local isBasic = isBasicTest(data.test_type)

    if isBasic then
        if not CheckForensicPermission(src, 'canRunBasicTests') then
            return { success = false, error = L('lab.errors.no_permission_basic') }
        end
    else
        if not CheckForensicPermission(src, 'canRunLabTests') then
            return { success = false, error = L('lab.errors.no_permission_lab') }
        end
    end

    local playerData = GetPlayerData(src)
    if not playerData then return { success = false, error = L('scene.errors.player_data_unavailable') } end

    local linksOk, linksError = validateEvidenceAndSceneLinks(data)
    if not linksOk then
        return { success = false, error = linksError }
    end

    local requiredItem = REQUIRED_ITEM_BY_TEST[data.test_type]
    if not hasRequiredItem(src, requiredItem) then
        return { success = false, error = L('lab.errors.missing_required_item', requiredItem) }
    end

    local processingSeconds = Config.TestProcessingTimes[data.test_type] or 0
    local processingTier = getProcessingTier(processingSeconds)

    local testId = MySQL.insert.await([[
        INSERT INTO forensic_lab_tests
        (evidence_id, scene_id, test_type, test_name, description,
         target_citizenid, target_name, target_vehicle, target_weapon_serial,
         result_level, processing_time_minutes, processing_time_seconds, processing_tier,
         requested_by, requested_by_name, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pendente', ?, ?, ?, ?, ?, ?, 'solicitado')
    ]], {
        data.evidence_id and tonumber(data.evidence_id) or nil,
        data.scene_id and tonumber(data.scene_id) or nil,
        data.test_type or 'outro',
        data.test_name or L('lab.defaults.unnamed_test'),
        data.description or '',
        data.target_citizenid or nil,
        data.target_name or nil,
        data.target_vehicle or nil,
        data.target_weapon_serial or nil,
        processingSeconds > 0 and math.ceil(processingSeconds / 60) or 0,
        processingSeconds,
        processingTier,
        playerData.citizenid,
        playerData.name,
    })

    ForensicAuditLog(src, 'lab_test_requested', 'lab_test', testId, {
        testType = data.test_type,
        testName = data.test_name,
    })

    return { success = true, id = testId }
end)

-- ============================================================
-- EXECUTAR TESTE (processar resultado)
-- ============================================================
lib.callback.register(resourceName .. ':server:performLabTest', function(source, testId)
    local src = source
    if not CheckForensicAuth(src) then return { success = false, error = L('lab.errors.not_authorized') } end

    testId = tonumber(testId)
    if not testId then return { success = false, error = L('lab.errors.invalid_id') } end

    local playerData = GetPlayerData(src)
    if not playerData then return { success = false, error = L('scene.errors.player_data_unavailable') } end
    local test = MySQL.single.await('SELECT * FROM forensic_lab_tests WHERE id = ?', { testId })
    if not test then return { success = false, error = L('lab.errors.not_found') } end

    if isBasicTest(test.test_type) then
        if not CheckForensicPermission(src, 'canRunBasicTests') then
            return { success = false, error = L('lab.errors.no_permission_basic') }
        end
    elseif not CheckForensicPermission(src, 'canRunLabTests') then
        return { success = false, error = L('lab.errors.no_permission_lab') }
    end

    if test.status == 'concluido' then
        return { success = false, error = L('lab.errors.already_completed') }
    end

    local requiredItem = REQUIRED_ITEM_BY_TEST[test.test_type]
    if not hasRequiredItem(src, requiredItem) then
        return { success = false, error = L('lab.errors.missing_required_item', requiredItem) }
    end

    local processingSeconds = tonumber(test.processing_time_seconds)
    if not processingSeconds then
        processingSeconds = (tonumber(test.processing_time_minutes) or 0) * 60
    end
    local processingTier = test.processing_tier or getProcessingTier(processingSeconds)

    local startedUnix = getUnixFromSQLTimestamp(test.started_at)
    if not startedUnix then
        MySQL.update.await([[
            UPDATE forensic_lab_tests
            SET status = 'em_andamento', started_at = NOW(),
                available_at = DATE_ADD(NOW(), INTERVAL ? SECOND),
                processing_time_seconds = ?, processing_tier = ?,
                performed_by = ?, performed_by_name = ?
            WHERE id = ?
        ]], { processingSeconds, processingSeconds, processingTier, playerData.citizenid, playerData.name, testId })

        startedUnix = os.time()
        if processingSeconds > 15 then
            return {
                success = true,
                pending = true,
                processingTier = processingTier,
                waitSeconds = processingSeconds,
                message = ('Exame iniciado (%s). Retorne após o tempo de processamento.'):format(processingTier),
            }
        end
    elseif processingSeconds > 0 then
        local elapsed = os.time() - startedUnix
        if elapsed < processingSeconds then
            return {
                success = true,
                pending = true,
                processingTier = processingTier,
                waitSeconds = processingSeconds - elapsed,
                message = ('Exame em processamento (%s).'):format(processingTier),
            }
        end
    end

    -- Simular resultado baseado no tipo de teste
    local resultLevel, resultDetails = SimulateTestResult(test)
    resultLevel = normalizeResultLevel(resultLevel)

    -- Atualizar com resultado
    MySQL.update.await([[
        UPDATE forensic_lab_tests
        SET status = 'concluido', completed_at = NOW(),
            result_level = ?, result_details = ?
        WHERE id = ?
    ]], { resultLevel, resultDetails, testId })

    -- Se evidência vinculada, atualizar status
    if test.evidence_id then
        MySQL.update.await(
            'UPDATE forensic_evidence SET status = ? WHERE id = ?',
            { 'analisada', test.evidence_id }
        )
    end

    if ForensicProcessIntelligenceMatch and test.target_citizenid and test.target_citizenid ~= '' then
        local mk = nil
        if tostring(test.test_type):find('residuo_polvora') then
            mk = 'residuo_polvora'
        elseif test.test_type == 'teste_sangue_presuntivo' or test.test_type == 'analise_fluido_biologico' then
            mk = 'material_biologico'
        end

        if mk and (resultLevel == 'confirmado' or resultLevel == 'compativel' or resultLevel == 'presumido') then
            local confidenceMap = { confirmado = 92, compativel = 74, presumido = 48 }
            local ev = test.evidence_id and MySQL.single.await('SELECT id, case_id, report_id, scene_id FROM forensic_evidence WHERE id = ?', { test.evidence_id }) or nil
            ForensicProcessIntelligenceMatch({
                citizenid = test.target_citizenid,
                citizen_name = test.target_name,
                case_id = ev and ev.case_id or nil,
                report_id = ev and ev.report_id or nil,
                scene_id = test.scene_id or (ev and ev.scene_id or nil),
                evidence_id = test.evidence_id,
                source_type = 'lab_test',
                source_id = testId,
                match_kind = mk,
                association_level = resultLevel == 'confirmado' and 'confirmacao' or (resultLevel == 'compativel' and 'compatibilidade_forte' or 'vestigio_relacionado'),
                confidence_score = confidenceMap[resultLevel] or 40,
                algorithm_name = 'lab_rule_engine_v1',
                algorithm_version = '2026.03',
                exam_performed_by = playerData.citizenid,
                generated_by = playerData.citizenid,
                exam_origin = test.test_type,
                rationale = ('Teste %s resultou em %s para o alvo %s'):format(test.test_type, resultLevel, test.target_citizenid),
                metadata = { result = resultLevel, details = resultDetails },
            })
        end
    end

    if test.test_type == 'teste_droga_presuntivo' or test.test_type == 'analise_substancia' then
        local evidenceCase, evidenceReport = nil, nil
        if test.evidence_id then
            local evidence = MySQL.single.await('SELECT case_id, report_id FROM forensic_evidence WHERE id = ?', { test.evidence_id })
            if evidence then
                evidenceCase = evidence.case_id
                evidenceReport = evidence.report_id
            end
        end
        if (not evidenceCase or not evidenceReport) and test.scene_id then
            local scene = MySQL.single.await('SELECT case_id, report_id FROM forensic_crime_scenes WHERE id = ?', { test.scene_id })
            if scene then
                evidenceCase = evidenceCase or scene.case_id
                evidenceReport = evidenceReport or scene.report_id
            end
        end

        local existingDrug = MySQL.single.await('SELECT id FROM forensic_drug_analysis WHERE lab_test_id = ?', { testId })
        if existingDrug then
            MySQL.update.await([[
                UPDATE forensic_drug_analysis
                SET test_result = ?, analyzed_by = ?, case_id = COALESCE(case_id, ?), report_id = COALESCE(report_id, ?)
                WHERE id = ?
            ]], { resultLevel, playerData.citizenid, evidenceCase, evidenceReport, existingDrug.id })
        else
            MySQL.insert.await([[
                INSERT INTO forensic_drug_analysis
                (evidence_id, scene_id, lab_test_id, substance_category, preliminary_classification,
                 test_result, analyzed_by, notes, case_id, report_id)
                VALUES (?, ?, ?, 'substancia_desconhecida', ?, ?, ?, ?, ?, ?)
            ]], {
                test.evidence_id, test.scene_id, testId,
                test.target_name or L('labels.unknown'),
                resultLevel,
                playerData.citizenid,
                resultDetails,
                evidenceCase,
                evidenceReport,
            })
        end
    end

    ForensicAuditLog(src, 'lab_test_performed', 'lab_test', testId, {
        resultLevel = resultLevel,
    })

    local matchHash = test.target_citizenid
    if test.test_type == 'coleta_dna' then
        local dnaRow = MySQL.single.await('SELECT dna_hash FROM forensic_dna_profiles WHERE citizenid = ? LIMIT 1', { test.target_citizenid })
        if dnaRow and dnaRow.dna_hash then
            matchHash = dnaRow.dna_hash
        end
    elseif test.test_type == 'coleta_digital' then
        local fpRow = MySQL.single.await('SELECT fingerprint_hash FROM forensic_fingerprint_profiles WHERE citizenid = ? LIMIT 1', { test.target_citizenid })
        if fpRow and fpRow.fingerprint_hash then
            matchHash = fpRow.fingerprint_hash
        end
    end

    TriggerEvent('ps-forensics:server:LabTestComplete', test.evidence_id, {
        type = (test.test_type == 'coleta_dna' and 'dna') or (test.test_type == 'coleta_digital' and 'fingerprint') or (test.test_type or 'unknown'),
        hash = matchHash,
        level = resultLevel,
        details = resultDetails,
        testId = testId,
    })

    return {
        success = true,
        resultLevel = resultLevel,
        resultDetails = resultDetails,
        processingTier = processingTier,
    }
end)

-- ============================================================
-- SIMULAÇÃO DE RESULTADO DE TESTE
-- ============================================================
function SimulateTestResult(test)
    local testType = test.test_type
    local roll = math.random(100)

    -- RESÍDUO DE PÓLVORA
    if testType:find('residuo_polvora') then
        if roll <= 55 then
            return 'confirmado', 'Presença de resíduo de pólvora (GSR) confirmada. Partículas de bário, antimônio e chumbo detectadas na amostra.'
        elseif roll <= 75 then
            return 'compativel', 'Padrão de partículas compatível com resíduo de disparo, porém abaixo do limiar confirmatório.'
        elseif roll <= 88 then
            return 'presumido', 'Vestígios presumidos de resíduo de disparo. Quantidade insuficiente para confirmação definitiva.'
        elseif roll <= 95 then
            return 'inconclusivo', 'Resultado inconclusivo. Contaminação ambiental pode ter interferido na análise.'
        else
            return 'negativo', 'Nenhum resíduo de pólvora detectado na amostra analisada.'
        end
    end

    -- TESTE DE DROGAS
    if testType == 'teste_droga_presuntivo' or testType == 'analise_substancia' then
        local substances = { 'Cocaína', 'THC (Maconha)', 'Metanfetamina', 'MDMA', 'Heroína', 'Fentanil' }
        local substance = substances[math.random(#substances)]

        if roll <= 45 then
            return 'confirmado', ('Substância identificada: %s. Teste reagente positivo com confirmação cromatográfica.'):format(substance)
        elseif roll <= 65 then
            return 'compativel', ('Perfil químico compatível com %s. Indícios robustos, sem confirmação instrumental total.'):format(substance)
        elseif roll <= 80 then
            return 'presumido', ('Teste presuntivo positivo para %s. Recomenda-se análise confirmatória.'):format(substance)
        elseif roll <= 90 then
            return 'inconclusivo', 'Material insuficiente ou degradado para identificação precisa. Recomenda-se nova coleta.'
        else
            return 'negativo', 'Nenhuma substância controlada detectada na amostra.'
        end
    end

    -- TESTE DE SANGUE
    if testType == 'teste_sangue_presuntivo' or testType == 'analise_fluido_biologico' then
        if roll <= 50 then
            return 'confirmado', 'Presença de sangue humano confirmada. Teste de Kastle-Meyer e teste confirmatório positivos.'
        elseif roll <= 75 then
            return 'compativel', 'Reação compatível com sangue humano, com necessidade de exame confirmatório complementar.'
        elseif roll <= 88 then
            return 'presumido', 'Resultado presumido positivo para sangue. Teste de luminol revelou vestígios.'
        elseif roll <= 95 then
            return 'inconclusivo', 'Amostra com degradação/contaminação. Resultado inconclusivo para sangue humano.'
        else
            return 'negativo', 'Nenhum vestígio de sangue humano detectado na amostra.'
        end
    end

    -- ANÁLISE DE PUREZA
    if testType == 'analise_pureza' then
        local purity = math.random(15, 95)
        return 'confirmado', ('Pureza da substância: %d%%. Análise por espectrometria de massa concluída.'):format(purity)
    end

    -- TOXICOLÓGICO
    if testType == 'toxicologico' then
        local substances = {}
        if math.random() < 0.6 then substances[#substances + 1] = 'Álcool etílico' end
        if math.random() < 0.3 then substances[#substances + 1] = 'Cocaína' end
        if math.random() < 0.2 then substances[#substances + 1] = 'THC' end
        if math.random() < 0.1 then substances[#substances + 1] = 'Benzodiazepínicos' end

        if #substances > 0 then
            return 'confirmado', ('Substâncias detectadas no organismo: %s. Concentrações acima do limite de detecção.'):format(table.concat(substances, ', '))
        else
            return 'negativo', 'Nenhuma substância psicoativa ou tóxica detectada no organismo.'
        end
    end

    -- ALCOOLEMIA
    if testType == 'alcoolemia' then
        local bac = math.random(0, 35) / 10
        if bac > 0 then
            return 'confirmado', ('Teor alcoólico: %.1f dg/L. %s'):format(bac,
                bac >= 6 and 'ACIMA DO LIMITE LEGAL.' or 'Dentro do limite de tolerância.')
        else
            return 'negativo', 'Nenhum teor alcoólico detectado.'
        end
    end

    -- ANÁLISE GENÉRICA
    if roll <= 60 then
        return 'confirmado', 'Análise concluída com resultado positivo. Vestígios confirmados na amostra processada.'
    elseif roll <= 75 then
        return 'compativel', 'Resultado compatível com o material de referência. Recomenda-se análise complementar.'
    elseif roll <= 85 then
        return 'presumido', 'Resultado presumido. Dados insuficientes para confirmação definitiva.'
    elseif roll <= 93 then
        return 'inconclusivo', 'Resultado inconclusivo. Material degradado ou contaminado.'
    else
        return 'negativo', 'Nenhum vestígio relevante detectado na análise.'
    end
end

-- ============================================================
-- LISTAR TESTES
-- ============================================================
lib.callback.register(resourceName .. ':server:getLabTests', function(source, filters)
    local src = source
    if not CheckForensicAuth(src) then return { success = false } end

    filters = filters or {}
    local queryParts = { '1=1' }
    local values = {}

    if filters.evidence_id then
        queryParts[#queryParts + 1] = 'evidence_id = ?'
        values[#values + 1] = tonumber(filters.evidence_id)
    end

    if filters.scene_id then
        queryParts[#queryParts + 1] = 'scene_id = ?'
        values[#values + 1] = tonumber(filters.scene_id)
    end

    if filters.status and filters.status ~= '' then
        queryParts[#queryParts + 1] = 'status = ?'
        values[#values + 1] = filters.status
    end

    if filters.test_type and filters.test_type ~= '' then
        queryParts[#queryParts + 1] = 'test_type = ?'
        values[#values + 1] = filters.test_type
    end

    local page = tonumber(filters.page) or 1
    local limit = 20
    local offset = (page - 1) * limit
    local where = table.concat(queryParts, ' AND ')

    local total = MySQL.scalar.await(('SELECT COUNT(*) FROM forensic_lab_tests WHERE %s'):format(where), values)

    local listValues = { table.unpack(values) }
    listValues[#listValues + 1] = limit
    listValues[#listValues + 1] = offset

    local items = MySQL.query.await(([[
        SELECT * FROM forensic_lab_tests WHERE %s ORDER BY created_at DESC LIMIT ? OFFSET ?
    ]]):format(where), listValues)

    return {
        success = true,
        data = { items = items or {}, total = total or 0, page = page }
    }
end)

-- ============================================================
-- RESULTADO MANUAL DE TESTE (para peritos)
-- ============================================================
lib.callback.register(resourceName .. ':server:setTestResult', function(source, testId, resultLevel, resultDetails)
    local src = source
    if not CheckForensicAuth(src) then return { success = false } end
    if not CheckForensicPermission(src, 'canRunLabTests') then
        return { success = false, error = 'Sem permissão' }
    end

    testId = tonumber(testId)
    local playerData = GetPlayerData(src)

    resultLevel = normalizeResultLevel(resultLevel)
    local processingSeconds = Config.TestProcessingTimes[(MySQL.single.await('SELECT test_type FROM forensic_lab_tests WHERE id = ?', { testId }) or {}).test_type or ''] or 0
    MySQL.update.await([[
        UPDATE forensic_lab_tests
        SET result_level = ?, result_details = ?, status = 'concluido',
            completed_at = NOW(), processing_time_seconds = ?, processing_tier = ?,
            performed_by = ?, performed_by_name = ?
        WHERE id = ?
    ]], { resultLevel, resultDetails, processingSeconds, getProcessingTier(processingSeconds), playerData.citizenid, playerData.name, testId })

    ForensicAuditLog(src, 'test_result_set', 'lab_test', testId, {
        resultLevel = resultLevel,
    })

    return { success = true }
end)
