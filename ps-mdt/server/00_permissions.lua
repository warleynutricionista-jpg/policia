local function cloneArray(values)
    local cloned = {}
    for i = 1, #(values or {}) do
        cloned[i] = values[i]
    end
    return cloned
end

local function normalizeUnique(values)
    local seen = {}
    local normalized = {}

    for _, value in ipairs(values or {}) do
        if value and not seen[value] then
            seen[value] = true
            normalized[#normalized + 1] = value
        end
    end

    table.sort(normalized)
    return normalized
end

function NormalizeMdtGradeValue(grade)
    if type(grade) == 'table' then
        return tonumber(grade.level or grade.grade or grade.rank or grade.value or grade.id) or 0
    end

    return tonumber(grade) or 0
end

function GetMdtRankData(jobName, gradeValue, fallbackGradeData)
    local normalizedGrade = NormalizeMdtGradeValue(gradeValue)
    local hierarchyByJob = IsPoliceJob(jobName, Config.PoliceJobType) and GetMdtHierarchyForJob(jobName) or nil
    local hierarchy = hierarchyByJob and hierarchyByJob[normalizedGrade] or nil
    local gradeData = type(fallbackGradeData) == 'table' and fallbackGradeData or {}

    return {
        level = normalizedGrade,
        label = hierarchy and hierarchy.label or gradeData.name or gradeData.label or gradeData.title or ('Grade ' .. tostring(normalizedGrade)),
        isBoss = (hierarchy and hierarchy.isBoss == true)
            or gradeData.isboss == true
            or gradeData.isBoss == true
            or gradeData.boss == true,
        hierarchy = hierarchy,
        gradeData = gradeData,
    }
end

function GetMdtAllPermissions()
    return normalizeUnique(cloneArray(Config and Config.ManagementPermissions or {}))
end

function GetMdtDefaultPermissions(jobName, gradeValue, isBoss)
    if isBoss then
        return GetMdtAllPermissions()
    end

    local defaults = Config and Config.PermissionDefaults and Config.PermissionDefaults[jobName] or nil
    if not defaults then
        return {}
    end

    return normalizeUnique(cloneArray(defaults[tostring(NormalizeMdtGradeValue(gradeValue))] or {}))
end
