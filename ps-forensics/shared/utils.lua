-- ============================================================
-- PS-FORENSICS - Utilitários Compartilhados
-- ============================================================

ForensicUtils = {}

-- Gerar número de cena: CENA-2026-00001
function ForensicUtils.GenerateSceneNumber(id)
    return ('CENA-%s-%05d'):format(os.date('%Y'), id)
end

-- Gerar número de evidência: EV-2026-00001
function ForensicUtils.GenerateEvidenceNumber(id)
    return ('EV-%s-%05d'):format(os.date('%Y'), id)
end

-- Gerar número de laudo: LAUDO-2026-00001
function ForensicUtils.GenerateReportNumber(id)
    return ('LAUDO-%s-%05d'):format(os.date('%Y'), id)
end

-- Gerar número de lacre: LACRE-XXXXXX
function ForensicUtils.GenerateSealNumber()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local result = 'LACRE-'
    for _ = 1, 6 do
        local idx = math.random(1, #chars)
        result = result .. chars:sub(idx, idx)
    end
    return result
end

-- Gerar hash de digital (simulação forense)
function ForensicUtils.GenerateFingerprintHash(citizenid)
    local hash = ''
    local seed = 0
    for i = 1, #citizenid do
        seed = seed + string.byte(citizenid, i) * (i * 7)
    end
    math.randomseed(seed)
    local chars = '0123456789ABCDEF'
    for _ = 1, 32 do
        local idx = math.random(1, #chars)
        hash = hash .. chars:sub(idx, idx)
    end
    math.randomseed(os.time())
    return hash
end

-- Gerar hash de DNA (simulação forense)
function ForensicUtils.GenerateDNAHash(citizenid)
    local hash = ''
    local seed = 0
    for i = 1, #citizenid do
        seed = seed + string.byte(citizenid, i) * (i * 13)
    end
    math.randomseed(seed)
    local chars = 'ATCG'
    for _ = 1, 40 do
        local idx = math.random(1, #chars)
        hash = hash .. chars:sub(idx, idx)
    end
    math.randomseed(os.time())
    return hash
end

-- Verificar se jogador é policial
function ForensicUtils.IsPoliceJob(jobName)
    if not jobName then return false end
    for _, job in ipairs(Config.PoliceJobs or {}) do
        if job == jobName then return true end
    end
    return false
end

-- Verificar se jogador é forense
function ForensicUtils.IsForensicJob(jobName)
    if not jobName then return false end
    for _, job in ipairs(Config.ForensicJobs or {}) do
        if job == jobName then return true end
    end
    return false
end

-- Verificar se jogador é médico/legista
function ForensicUtils.IsMedicalJob(jobName)
    if not jobName then return false end
    for _, job in ipairs(Config.MedicalJobs or {}) do
        if job == jobName then return true end
    end
    return false
end

-- Obter role do jogador baseado em job e grade
function ForensicUtils.GetPlayerRole(jobName, grade)
    grade = tonumber(grade) or 0

    -- Legista (médico com grade adequada)
    if ForensicUtils.IsMedicalJob(jobName) then
        return 'legista', Config.Roles.legista
    end

    -- Investigador (policia civil)
    if jobName == 'policiacivil' then
        if grade >= 2 then
            return 'delegado', Config.Roles.delegado
        end
        return 'investigador', Config.Roles.investigador
    end

    -- Comando (grade alta)
    if grade >= 7 then
        return 'comando', Config.Roles.comando
    end

    -- Delegado (grade 5-6)
    if grade >= 5 then
        return 'delegado', Config.Roles.delegado
    end

    -- Perito (grade 2-4)
    if grade >= 2 then
        return 'perito', Config.Roles.perito
    end

    -- Policial operacional
    return 'policial', Config.Roles.policial
end

-- Verificar permissão específica
function ForensicUtils.HasPermission(jobName, grade, permission)
    local _, roleConfig = ForensicUtils.GetPlayerRole(jobName, grade)
    if not roleConfig then return false end
    return roleConfig[permission] == true
end

-- Formatar timestamp
function ForensicUtils.FormatTimestamp(timestamp)
    if not timestamp then return 'N/A' end
    return os.date('%d/%m/%Y %H:%M', timestamp)
end

-- Obter label da classificação da cena
function ForensicUtils.GetClassificationLabel(value)
    for _, v in ipairs(Config.SceneClassifications or {}) do
        if v.value == value then return v.label end
    end
    return value or 'Desconhecido'
end

-- Obter label do tipo de evidência
function ForensicUtils.GetEvidenceTypeLabel(typeValue)
    for _, v in ipairs(Config.EvidenceTypes or {}) do
        if v.type == typeValue then return v.label end
    end
    return typeValue or 'Desconhecido'
end

-- Traduzir status de evidência
ForensicUtils.EvidenceStatusLabels = {
    coletada = 'Coletada',
    lacrada = 'Lacrada',
    em_analise = 'Em Análise',
    analisada = 'Analisada',
    armazenada = 'Armazenada',
    descartada = 'Descartada',
    devolvida = 'Devolvida',
    em_julgamento = 'Em Julgamento',
}

-- Traduzir status de teste
ForensicUtils.TestResultLabels = {
    pendente = 'Pendente',
    presumido = 'Presumido',
    inconclusivo = 'Inconclusivo',
    compativel = 'Compatível',
    confirmado = 'Confirmado',
    negativo = 'Negativo',
}

-- Traduzir causa da morte
ForensicUtils.CauseOfDeathLabels = {
    arma_de_fogo = 'Perfuração por Arma de Fogo',
    arma_branca = 'Ferimento por Arma Branca',
    trauma_contundente = 'Trauma Contundente',
    asfixia = 'Asfixia',
    queimadura = 'Queimadura',
    overdose = 'Overdose',
    envenenamento = 'Envenenamento',
    afogamento = 'Afogamento',
    eletrocussao = 'Eletrocussão',
    multiplos_ferimentos = 'Múltiplos Ferimentos',
    causa_natural = 'Causa Natural',
    indeterminado = 'Indeterminado',
}
