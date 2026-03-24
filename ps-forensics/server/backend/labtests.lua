-- ============================================================
-- PS-FORENSICS - Módulo: Testes Laboratoriais (Server)
-- ============================================================

local resourceName = GetCurrentResourceName()

-- ============================================================
-- SOLICITAR TESTE
-- ============================================================
lib.callback.register(resourceName .. ':server:requestLabTest', function(source, data)
    local src = source
    if not CheckForensicAuth(src) then return { success = false } end

    local isBasicTest = data.test_type and (
        data.test_type:find('residuo_polvora') or
        data.test_type == 'teste_droga_presuntivo' or
        data.test_type == 'teste_sangue_presuntivo' or
        data.test_type == 'coleta_digital' or
        data.test_type == 'coleta_dna'
    )

    if isBasicTest then
        if not CheckForensicPermission(src, 'canRunBasicTests') then
            return { success = false, error = 'Sem permissão para testes básicos' }
        end
    else
        if not CheckForensicPermission(src, 'canRunLabTests') then
            return { success = false, error = 'Sem permissão para testes laboratoriais' }
        end
    end

    local playerData = GetPlayerData(src)

    local testId = MySQL.insert.await([[
        INSERT INTO forensic_lab_tests
        (evidence_id, scene_id, test_type, test_name, description,
         target_citizenid, target_name, target_vehicle, target_weapon_serial,
         result_level, processing_time_minutes,
         requested_by, requested_by_name, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pendente', ?, ?, ?, 'solicitado')
    ]], {
        data.evidence_id and tonumber(data.evidence_id) or nil,
        data.scene_id and tonumber(data.scene_id) or nil,
        data.test_type or 'outro',
        data.test_name or 'Teste não especificado',
        data.description or '',
        data.target_citizenid or nil,
        data.target_name or nil,
        data.target_vehicle or nil,
        data.target_weapon_serial or nil,
        Config.TestProcessingTimes[data.test_type] and math.ceil(Config.TestProcessingTimes[data.test_type] / 60) or 0,
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
    if not CheckForensicAuth(src) then return { success = false } end

    testId = tonumber(testId)
    if not testId then return { success = false } end

    local playerData = GetPlayerData(src)
    local test = MySQL.single.await('SELECT * FROM forensic_lab_tests WHERE id = ?', { testId })
    if not test then return { success = false, error = 'Teste não encontrado' } end

    if test.status == 'concluido' then
        return { success = false, error = 'Teste já foi concluído' }
    end

    -- Marcar como em andamento
    MySQL.update.await([[
        UPDATE forensic_lab_tests
        SET status = 'em_andamento', started_at = NOW(),
            performed_by = ?, performed_by_name = ?
        WHERE id = ?
    ]], { playerData.citizenid, playerData.name, testId })

    -- Simular resultado baseado no tipo de teste
    local resultLevel, resultDetails = SimulateTestResult(test)

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

    ForensicAuditLog(src, 'lab_test_performed', 'lab_test', testId, {
        resultLevel = resultLevel,
    })

    return {
        success = true,
        resultLevel = resultLevel,
        resultDetails = resultDetails,
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
        if roll <= 70 then
            return 'confirmado', 'Presença de resíduo de pólvora (GSR) confirmada. Partículas de bário, antimônio e chumbo detectadas na amostra.'
        elseif roll <= 85 then
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

        if roll <= 65 then
            return 'confirmado', ('Substância identificada: %s. Teste reagente positivo com confirmação cromatográfica.'):format(substance)
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
        if roll <= 75 then
            return 'confirmado', 'Presença de sangue humano confirmada. Teste de Kastle-Meyer e teste confirmatório positivos.'
        elseif roll <= 85 then
            return 'presumido', 'Resultado presumido positivo para sangue. Teste de luminol revelou vestígios.'
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

    MySQL.update.await([[
        UPDATE forensic_lab_tests
        SET result_level = ?, result_details = ?, status = 'concluido',
            completed_at = NOW(), performed_by = ?, performed_by_name = ?
        WHERE id = ?
    ]], { resultLevel, resultDetails, playerData.citizenid, playerData.name, testId })

    ForensicAuditLog(src, 'test_result_set', 'lab_test', testId, {
        resultLevel = resultLevel,
    })

    return { success = true }
end)
