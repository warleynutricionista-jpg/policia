-- ============================================================
-- PS-FORENSICS - Utilitários Compartilhados
-- ============================================================

ForensicUtils = {}

local function normalizeJobName(jobName)
    if not jobName then return '' end
    return tostring(jobName):lower():gsub('[%s_-]+', '')
end

local function normalizeGradeName(gradeName)
    if not gradeName then return '' end
    return tostring(gradeName):lower()
end

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
    local normalizedJob = normalizeJobName(jobName)
    for _, job in ipairs(Config.PoliceJobs or {}) do
        if normalizeJobName(job) == normalizedJob then return true end
    end
    return false
end

-- Verificar se jogador é forense
function ForensicUtils.IsForensicJob(jobName)
    if not jobName then return false end
    local normalizedJob = normalizeJobName(jobName)
    for _, job in ipairs(Config.ForensicJobs or {}) do
        if normalizeJobName(job) == normalizedJob then return true end
    end
    return false
end

-- Verificar se jogador é médico/legista
function ForensicUtils.IsMedicalJob(jobName)
    if not jobName then return false end
    local normalizedJob = normalizeJobName(jobName)
    for _, job in ipairs(Config.MedicalJobs or {}) do
        if normalizeJobName(job) == normalizedJob then return true end
    end
    return false
end

function ForensicUtils.IsAuthorizedForensicsJob(jobName)
    if not jobName then return false end
    return ForensicUtils.IsPoliceJob(jobName) or ForensicUtils.IsMedicalJob(jobName)
end

-- Obter role do jogador baseado em job e grade
function ForensicUtils.GetPlayerRole(jobName, grade, gradeName)
    grade = tonumber(grade) or 0
    local normalizedJob = normalizeJobName(jobName)
    local normalizedGrade = normalizeGradeName(gradeName)

    -- Legista por profissão médica ou por cargo explícito
    if ForensicUtils.IsMedicalJob(jobName) or normalizedGrade:find('legista', 1, true) then
        return 'legista', Config.Roles.legista
    end

    -- Polícia Civil (acesso especializado)
    if normalizedJob == 'policiacivil' then
        return 'policiacivil_especializado', Config.Roles.policiacivil_especializado
    end

    -- Polícia operacional (acesso limitado de campo)
    if normalizedJob == 'police' or normalizedJob == 'ftpolicia' then
        return 'policial_operacional', Config.Roles.policial_operacional
    end

    -- Fallback para demais jobs policiais cadastrados
    return 'policial_operacional', Config.Roles.policial_operacional
end

-- Verificar permissão específica
function ForensicUtils.HasPermission(jobName, grade, permission, gradeName)
    local _, roleConfig = ForensicUtils.GetPlayerRole(jobName, grade, gradeName)
    if not roleConfig then return false end
    return roleConfig[permission] == true
end

-- Formatar timestamp
function ForensicUtils.FormatTimestamp(timestamp)
    if not timestamp then return L('labels.na') end
    return os.date('%d/%m/%Y %H:%M', timestamp)
end

-- Obter label da classificação da cena
function ForensicUtils.GetClassificationLabel(value)
    for _, v in ipairs(Config.SceneClassifications or {}) do
        if v.value == value then
            if v.labelKey then
                local localized = L(v.labelKey)
                if localized ~= v.labelKey then
                    return localized
                end
            end
            return v.label or value
        end
    end
    return value or L('labels.unknown')
end

-- Obter label do tipo de evidência
function ForensicUtils.GetEvidenceTypeLabel(typeValue)
    for _, v in ipairs(Config.EvidenceTypes or {}) do
        if v.type == typeValue then
            if v.labelKey then
                local localized = L(v.labelKey)
                if localized ~= v.labelKey then
                    return localized
                end
            end
            return v.label or typeValue
        end
    end
    return typeValue or L('labels.unknown')
end

function ForensicUtils.GetSceneClassificationOptions()
    local options = {}
    for _, classification in ipairs(Config.SceneClassifications or {}) do
        options[#options + 1] = {
            value = classification.value,
            label = ForensicUtils.GetClassificationLabel(classification.value),
        }
    end
    return options
end

function ForensicUtils.GetEvidenceCategoryOptions()
    local options = {}
    for _, category in ipairs(Config.EvidenceCategories or {}) do
        local label = category.value
        if category.labelKey then
            local localized = L(category.labelKey)
            if localized ~= category.labelKey then
                label = localized
            end
        elseif category.label then
            label = category.label
        end

        options[#options + 1] = {
            value = category.value,
            label = label,
        }
    end
    return options
end

function ForensicUtils.GetQuickTestOptions()
    local options = {}
    for _, test in ipairs(Config.QuickTests or {}) do
        local label = test.value
        if test.labelKey then
            local localized = L(test.labelKey)
            if localized ~= test.labelKey then
                label = localized
            end
        elseif test.label then
            label = test.label
        end

        options[#options + 1] = {
            value = test.value,
            label = label,
        }
    end
    return options
end

function ForensicUtils.GetEvidenceStatusLabel(status)
    local key = ('labels.evidence_status.%s'):format(status or '')
    local value = L(key)
    if value == key then
        return status or L('labels.unknown')
    end
    return value
end

function ForensicUtils.GetTestResultLabel(result)
    local key = ('labels.test_result.%s'):format(result or '')
    local value = L(key)
    if value == key then
        return result or L('labels.unknown')
    end
    return value
end

function ForensicUtils.GetCauseOfDeathLabel(cause)
    local key = ('labels.cause_of_death.%s'):format(cause or '')
    local value = L(key)
    if value == key then
        return cause or L('labels.unknown')
    end
    return value
end
