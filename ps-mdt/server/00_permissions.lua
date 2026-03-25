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

local ROLE_PERMISSION_PROFILES = {
    soldado = {
        'reports_view',
        'reports_create',
    },
    cabo = {
        'reports_view',
        'reports_create',
        'reports_edit',
    },
    sargento = {
        'reports_view',
        'reports_create',
        'reports_edit',
    },
    delegado = {
        'reports_view',
        'reports_create',
        'reports_edit',
        'reports_approve',
        'reports_sign',
        'reports_archive',
        'reports_unarchive',
        'reports_delete',
        'warrants_issue',
        'warrants_close',
    },
    comando = {
        'reports_view',
        'reports_create',
        'reports_edit',
        'reports_approve',
        'reports_sign',
        'reports_archive',
        'reports_unarchive',
        'reports_delete',
        'warrants_issue',
        'warrants_close',
        'management_permissions',
        'management_bulletins',
        'management_activity',
        'management_tags',
        'management_tracking',
        'management_settings',
    },
    perito = {
        'forensics_view',
        'forensics_collect',
        'forensics_lab_basic',
        'forensics_lab_advanced',
        'forensics_reports',
        'forensics_custody',
        'forensics_crossref',
    },
    legista = {
        'forensics_view',
        'forensics_collect',
        'forensics_lab_basic',
        'forensics_lab_advanced',
        'forensics_reports',
        'forensics_autopsy',
        'forensics_custody',
        'forensics_crossref',
    },
}

local function normalizeRankLabel(label)
    return tostring(label or ''):lower()
end

local function resolveRoleProfile(jobName, rankData)
    local rankLabel = normalizeRankLabel(rankData and rankData.label)

    if rankData and rankData.isBoss then
        return 'comando'
    end

    if jobName == 'policiacivil' and rankLabel:find('delegad', 1, true) then
        return 'delegado'
    end

    if rankLabel:find('delegad', 1, true) then return 'delegado' end
    if rankLabel:find('coronel', 1, true) or rankLabel:find('comando', 1, true) then return 'comando' end
    if rankLabel:find('sargento', 1, true) then return 'sargento' end
    if rankLabel:find('cabo', 1, true) then return 'cabo' end
    if rankLabel:find('soldado', 1, true) then return 'soldado' end
    if rankLabel:find('perit', 1, true) then return 'perito' end
    if rankLabel:find('legista', 1, true) then return 'legista' end

    return nil
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

    local permissions = cloneArray(defaults[tostring(NormalizeMdtGradeValue(gradeValue))] or {})
    local rankData = GetMdtRankData(jobName, gradeValue)
    local roleProfile = resolveRoleProfile(jobName, rankData)
    if roleProfile and ROLE_PERMISSION_PROFILES[roleProfile] then
        for _, permission in ipairs(ROLE_PERMISSION_PROFILES[roleProfile]) do
            permissions[#permissions + 1] = permission
        end
    end

    return normalizeUnique(permissions)
end
