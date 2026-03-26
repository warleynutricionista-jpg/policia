-- ============================================================
-- PS-FORENSICS - Settings Backend
-- Gerenciamento de configurações do painel via banco de dados
-- ============================================================

local resourceName = GetCurrentResourceName()

local ALL_FORENSIC_PERMISSIONS = {
    'canCreateScene',
    'canCollectEvidence',
    'canRunBasicTests',
    'canRunLabTests',
    'canEmitReport',
    'canPerformAutopsy',
    'canModifyCustody',
    'canFinalizeReport',
}

local function getDefaultRolePermissions(roleName)
    local role = Config.Roles and Config.Roles[roleName]
    if not role then return {} end
    local perms = {}
    for _, perm in ipairs(ALL_FORENSIC_PERMISSIONS) do
        if role[perm] == true then
            perms[#perms + 1] = perm
        end
    end
    return perms
end

local function getDefaultRoleNameForJob(jobName)
    local job = (jobName or ''):lower()
    if job == 'ambulance' then
        return 'legista'
    elseif job == 'policiacivil' then
        return 'policiacivil_especializado'
    else
        return 'policial_operacional'
    end
end

-- ============================================================
-- GET EFFECTIVE TABS FOR CURRENT PLAYER (chamado ao abrir painel)
-- ============================================================
lib.callback.register(resourceName .. ':server:getPlayerEffectiveTabs', function(source)
    if not CheckForensicAuth(source) then return { tabs = {} } end

    local data = GetPlayerData(source)
    if not data then return { tabs = {} } end

    local permLevelName = Config.PermissionMatrix.byJob[data.job] or 'operacional'
    local permLevel = Config.PermissionMatrix.levels[permLevelName] or 1

    -- Carregar overrides do banco
    local rows = MySQL.query.await('SELECT tab_id, min_level, allowed_jobs, is_enabled FROM forensic_panel_settings') or {}
    local overridesByTab = {}
    for _, row in ipairs(rows) do
        local jobs = nil
        if row.allowed_jobs then
            local ok, decoded = pcall(json.decode, row.allowed_jobs)
            if ok then jobs = decoded end
        end
        overridesByTab[row.tab_id] = {
            minLevel = tonumber(row.min_level),
            jobs = jobs,
            isEnabled = row.is_enabled == 1,
        }
    end

    local availableTabs = {}
    for _, tabDef in ipairs(Config.PanelTabs) do
        local override = overridesByTab[tabDef.id] or {}
        local effectiveMinLevel = override.minLevel or tabDef.minLevel
        local effectiveJobs = override.jobs or tabDef.jobs
        local isEnabled = override.isEnabled ~= nil and override.isEnabled or true

        if not isEnabled then goto continue end

        local hasLevel = permLevel >= effectiveMinLevel
        local hasJob = true
        if effectiveJobs then
            hasJob = false
            for _, j in ipairs(effectiveJobs) do
                if j == data.job then hasJob = true; break end
            end
        end

        if hasLevel and hasJob then
            availableTabs[#availableTabs + 1] = tabDef.id
        end

        ::continue::
    end

    return { tabs = availableTabs }
end)

-- ============================================================
-- GET PANEL SETTINGS (para a aba Configurações)
-- ============================================================
lib.callback.register(resourceName .. ':server:getForensicPanelSettings', function(source)
    if not CheckForensicAuth(source) then
        return { success = false, error = 'Não autorizado' }
    end
    if not CheckForensicPermission(source, 'canAdminForensics') then
        return { success = false, error = 'Sem permissão de administração' }
    end

    local rows = MySQL.query.await('SELECT tab_id, min_level, allowed_jobs, is_enabled FROM forensic_panel_settings') or {}
    local overridesByTab = {}
    for _, row in ipairs(rows) do
        local jobs = nil
        if row.allowed_jobs then
            local ok, decoded = pcall(json.decode, row.allowed_jobs)
            if ok then jobs = decoded end
        end
        overridesByTab[row.tab_id] = {
            minLevel = tonumber(row.min_level),
            jobs = jobs,
            isEnabled = row.is_enabled == 1,
        }
    end

    local tabs = {}
    for _, tabDef in ipairs(Config.PanelTabs) do
        local override = overridesByTab[tabDef.id] or {}
        tabs[#tabs + 1] = {
            id            = tabDef.id,
            label         = tabDef.label,
            icon          = tabDef.icon,
            minLevel      = override.minLevel or tabDef.minLevel,
            jobs          = override.jobs or tabDef.jobs,
            isEnabled     = override.isEnabled ~= nil and override.isEnabled or true,
            defaultMinLevel = tabDef.minLevel,
            defaultJobs   = tabDef.jobs,
        }
    end

    return {
        success = true,
        tabs = tabs,
        permissionLevels = {
            { value = 1, label = 'Operacional' },
            { value = 2, label = 'Investigação' },
            { value = 3, label = 'Administração' },
        },
        allJobs = Config.ForensicJobs,
    }
end)

-- ============================================================
-- SAVE TAB SETTINGS
-- ============================================================
lib.callback.register(resourceName .. ':server:saveTabSettings', function(source, payload)
    if not CheckForensicAuth(source) then
        return { success = false, error = 'Não autorizado' }
    end
    if not CheckForensicPermission(source, 'canAdminForensics') then
        return { success = false, error = 'Sem permissão de administração' }
    end

    payload = payload or {}
    local tabId    = payload.tabId
    local minLevel = tonumber(payload.minLevel)
    local allowedJobs = payload.jobs
    local isEnabled = payload.isEnabled ~= false

    if not tabId or not minLevel then
        return { success = false, error = 'Dados inválidos' }
    end

    local validTab = false
    for _, tabDef in ipairs(Config.PanelTabs) do
        if tabDef.id == tabId then validTab = true; break end
    end
    if not validTab then
        return { success = false, error = 'Aba inválida' }
    end

    local playerData = GetPlayerData(source)
    local updatedBy = playerData and playerData.citizenid or 'unknown'

    MySQL.query.await([[
        INSERT INTO forensic_panel_settings (tab_id, min_level, allowed_jobs, is_enabled, updated_by)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            min_level    = VALUES(min_level),
            allowed_jobs = VALUES(allowed_jobs),
            is_enabled   = VALUES(is_enabled),
            updated_by   = VALUES(updated_by)
    ]], {
        tabId,
        minLevel,
        allowedJobs and json.encode(allowedJobs) or nil,
        isEnabled and 1 or 0,
        updatedBy,
    })

    ForensicAuditLog(source, 'settings_tab_update', 'panel_tab', tabId, {
        minLevel  = minLevel,
        jobs      = allowedJobs,
        isEnabled = isEnabled,
    })

    return { success = true }
end)

-- ============================================================
-- GET FORENSIC ROLE PERMISSIONS
-- ============================================================
lib.callback.register(resourceName .. ':server:getForensicRolePermissions', function(source, data)
    if not CheckForensicAuth(source) then
        return { success = false, error = 'Não autorizado' }
    end
    if not CheckForensicPermission(source, 'canAdminForensics') then
        return { success = false, error = 'Sem permissão de administração' }
    end

    local filterJob = data and data.job or nil

    local query  = 'SELECT job, grade, permissions FROM forensic_permission_roles'
    local params = {}
    if filterJob then
        query  = query .. ' WHERE job = ?'
        params = { filterJob }
    end

    local rows = MySQL.query.await(query, params) or {}
    local storedByJobGrade = {}
    for _, row in ipairs(rows) do
        local key = row.job .. ':' .. tostring(row.grade)
        local ok, decoded = pcall(json.decode, row.permissions)
        storedByJobGrade[key] = ok and decoded or {}
    end

    local roles = {}
    local jobs = filterJob and { filterJob } or (Config.ForensicJobs or {})

    for _, jobName in ipairs(jobs) do
        local defaultRoleName = getDefaultRoleNameForJob(jobName)
        local defaultPerms    = getDefaultRolePermissions(defaultRoleName)

        local maxGrade = 4
        if jobName == 'policiacivil' then maxGrade = 3 end
        if jobName == 'ambulance'    then maxGrade = 3 end

        for grade = 0, maxGrade do
            local key      = jobName .. ':' .. tostring(grade)
            local stored   = storedByJobGrade[key]
            local isDefault = not stored or not next(stored)

            local permissions
            if not isDefault then
                permissions = {}
                for _, perm in ipairs(ALL_FORENSIC_PERMISSIONS) do
                    if stored[perm] == true then
                        permissions[#permissions + 1] = perm
                    end
                end
            else
                permissions = defaultPerms
            end

            roles[#roles + 1] = {
                job         = jobName,
                grade       = grade,
                permissions = permissions,
                isDefault   = isDefault,
            }
        end
    end

    return {
        success         = true,
        roles           = roles,
        allPermissions  = ALL_FORENSIC_PERMISSIONS,
        permissionLevels = Config.PermissionMatrix and Config.PermissionMatrix.byJob or {},
    }
end)

-- ============================================================
-- UPDATE FORENSIC ROLE PERMISSION
-- ============================================================
lib.callback.register(resourceName .. ':server:updateForensicRolePermission', function(source, payload)
    if not CheckForensicAuth(source) then
        return { success = false, error = 'Não autorizado' }
    end
    if not CheckForensicPermission(source, 'canAdminForensics') then
        return { success = false, error = 'Sem permissão de administração' }
    end

    payload = payload or {}
    local jobName        = payload.job
    local grade          = tonumber(payload.grade)
    local permissionsList = payload.permissions

    if not jobName or grade == nil or type(permissionsList) ~= 'table' then
        return { success = false, error = 'Dados inválidos' }
    end

    local permSet = {}
    for _, perm in ipairs(ALL_FORENSIC_PERMISSIONS) do
        permSet[perm] = false
    end
    for _, perm in ipairs(permissionsList) do
        if permSet[perm] ~= nil then
            permSet[perm] = true
        end
    end

    local playerData = GetPlayerData(source)
    local updatedBy  = playerData and playerData.citizenid or 'unknown'

    MySQL.query.await([[
        INSERT INTO forensic_permission_roles (job, grade, permissions, updated_by)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            permissions = VALUES(permissions),
            updated_by  = VALUES(updated_by)
    ]], { jobName, grade, json.encode(permSet), updatedBy })

    ForensicAuditLog(source, 'settings_role_update', 'permission_role',
        jobName .. ':' .. tostring(grade), { permissions = permissionsList })

    return { success = true }
end)

-- ============================================================
-- RESET FORENSIC SETTINGS
-- ============================================================
lib.callback.register(resourceName .. ':server:resetForensicSettings', function(source, payload)
    if not CheckForensicAuth(source) then
        return { success = false, error = 'Não autorizado' }
    end
    if not CheckForensicPermission(source, 'canAdminForensics') then
        return { success = false, error = 'Sem permissão de administração' }
    end

    payload = payload or {}
    local scope = payload.scope or 'all'

    if scope == 'all' or scope == 'tabs' then
        MySQL.query.await('DELETE FROM forensic_panel_settings')
    end
    if scope == 'all' or scope == 'permissions' then
        MySQL.query.await('DELETE FROM forensic_permission_roles')
    end

    ForensicAuditLog(source, 'settings_reset', 'settings', nil, { scope = scope })

    return { success = true }
end)
