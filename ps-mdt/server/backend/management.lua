local resourceName = tostring(GetCurrentResourceName())

local function resolvePoliceJobName(source)
    local jobName = (Config and Config.PoliceJobs and Config.PoliceJobs[1]) or 'police'
    if source and ps and ps.getJobName then
        local playerJob = ps.getJobName(source)
        if playerJob then
            jobName = playerJob
        end
    end
    return jobName
end

local function normalizeGrades(grades)
    local result = {}
    for key, data in pairs(grades or {}) do
        local gradeKey = key
        if type(data) == 'table' then
            gradeKey = data.level or data.grade or data.rank or data.value or data.id or key
        end
        result[tostring(gradeKey)] = data
    end
    return result
end

local function isBossGrade(gradeData)
    return gradeData and GetMdtRankData(nil, gradeData.level or gradeData.grade or gradeData.rank or gradeData.value or gradeData.id, gradeData).isBoss
end

local function getGradeLabel(jobName, gradeData, gradeKeyString)
    return GetMdtRankData(jobName, gradeKeyString, gradeData).label
end

local function getPoliceJobDefinition(source)
    local jobName = resolvePoliceJobName(source)

    local QBCore = nil
    local okQbx, qbx = pcall(function() return exports['qbx_core']:GetCoreObject() end)
    if okQbx and qbx then
        QBCore = qbx
    else
        local okQb, qb = pcall(function() return exports['qb-core']:GetCoreObject() end)
        if okQb and qb then QBCore = qb end
    end

    if QBCore then
        local jobs = QBCore and QBCore.Shared and QBCore.Shared.Jobs
        if jobs and jobs[jobName] then
            return jobName, jobs[jobName]
        end
    end

    if ps and ps.getSharedJobData then
        local job = ps.getSharedJobData(jobName)
        if job then
            return jobName, job
        end
    end

    return jobName, nil
end

local function getAllPermissions()
    return GetMdtAllPermissions()
end

local function normalizePermissionList(list)
    local result = {}
    local seen = {}
    for _, perm in ipairs(list or {}) do
        if perm and not seen[perm] then
            seen[perm] = true
            result[#result + 1] = perm
        end
    end
    table.sort(result)
    return result
end

local function getDefaultRolePermissions(jobName, gradeKey, isBoss)
    return normalizePermissionList(GetMdtDefaultPermissions(jobName, gradeKey, isBoss))
end

ps.registerCallback(resourceName .. ':server:getPermissionRoles', function(source)
    local src = source
    if not CheckAuth(src) then return {} end
    if not CheckPermission(src, 'management_permissions') then return {} end

    local jobName, job = getPoliceJobDefinition(src)
    local hasBossAccess = false
    if ps and ps.getJobData then
        local jobData = ps.getJobData(src)
        if jobData and jobData.grade then
            local currentGrade = NormalizeMdtGradeValue(jobData.grade)
            local grades = job and job.grades and normalizeGrades(job.grades) or nil
            local gradeData = grades and grades[tostring(currentGrade)] or (type(jobData.grade) == 'table' and jobData.grade or nil)
            hasBossAccess = GetMdtRankData(jobName, currentGrade, gradeData).isBoss
        end
    end
    ps.debug('[getPermissionRoles] jobName', jobName, 'job', job and job.label or 'nil')
    if not job or not job.grades then
        ps.debug('[getPermissionRoles] no job grades, using fallback')
        local isBoss = ps and ps.isBoss and ps.isBoss(src) or false
        local fallbackPermissions = getDefaultRolePermissions(jobName, 0, isBoss)
        return {
            job = jobName,
            label = 'Aplicação da Lei',
            roles = {
                {
                    key = '0',
                    label = GetMdtRankData(jobName, 0).label,
                    isBoss = isBoss,
                    permissions = fallbackPermissions,
                }
            },
            permissions = getAllPermissions(),
        }
    end

    local roles = {}
    local storedRows = MySQL.query.await('SELECT grade, permissions FROM mdt_permission_roles WHERE job = ?', { jobName }) or {}
    ps.debug('[getPermissionRoles] stored rows', storedRows and #storedRows or 0)
    local storedByGrade = {}
    for _, row in ipairs(storedRows) do
        if row.grade ~= nil then
            local ok, decoded = pcall(json.decode, row.permissions)
            storedByGrade[tostring(row.grade)] = ok and decoded or {}
        end
    end

    local grades = normalizeGrades(job.grades)
    local gradeCount = 0
    for _ in pairs(grades or {}) do
        gradeCount = gradeCount + 1
    end
    ps.debug('[getPermissionRoles] grade count', gradeCount)
    for gradeKeyString, gradeData in pairs(grades) do
        local rankData = GetMdtRankData(jobName, gradeKeyString, gradeData)
        local isBoss = hasBossAccess or rankData.isBoss
        local permissions = storedByGrade[gradeKeyString]
        if not permissions or #permissions == 0 then
            permissions = getDefaultRolePermissions(jobName, gradeKeyString, isBoss)
        end
        permissions = normalizePermissionList(permissions)

        roles[#roles + 1] = {
            key = gradeKeyString,
            label = rankData.label,
            isBoss = isBoss,
            permissions = permissions,
        }
    end

    if #roles == 0 and ps and ps.getJobData then
        local jobData = ps.getJobData(src)
        if jobData then
            local gradeValue = NormalizeMdtGradeValue(jobData.grade)
            local gradeKeyString = tostring(gradeValue)
            local rankData = GetMdtRankData(jobName, gradeValue, type(jobData.grade) == 'table' and jobData.grade or nil)
            local permissions = storedByGrade[gradeKeyString]
            if not permissions or #permissions == 0 then
                permissions = getDefaultRolePermissions(jobName, gradeKeyString, rankData.isBoss)
            end
            permissions = normalizePermissionList(permissions)
            roles[#roles + 1] = {
                key = gradeKeyString,
                label = rankData.label,
                isBoss = rankData.isBoss,
                permissions = permissions,
            }
        end
    end

    table.sort(roles, function(a, b)
        local numA = tonumber(a.key)
        local numB = tonumber(b.key)
        if numA and numB then return numA < numB end
        if numA then return true end
        if numB then return false end
        return (a.key or '') < (b.key or '')
    end)

    return {
        job = jobName,
        label = job and job.label or 'Aplicação da Lei',
        roles = roles,
        permissions = getAllPermissions(),
    }
end)

ps.registerCallback(resourceName .. ':server:updatePermissionRole', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end
    if not CheckPermission(src, 'management_permissions') then
        return { success = false, message = 'Sem permissão para editar permissões' }
    end

    payload = payload or {}
    if not payload.job or payload.grade == nil or type(payload.permissions) ~= 'table' then
        return { success = false, message = 'Payload inválido' }
    end

    local jobName, job = getPoliceJobDefinition(src)
    local isBoss = false
    if job and job.grades then
        local grades = normalizeGrades(job.grades)
        local gradeData = grades[tostring(payload.grade)]
        if gradeData then
            isBoss = GetMdtRankData(payload.job, payload.grade, gradeData).isBoss
        end
    end

    local permissions = normalizePermissionList(payload.permissions)
    if isBoss then
        permissions = normalizePermissionList(getAllPermissions())
    end

    local updatedBy = ps.getIdentifier(src)
    MySQL.update.await([[
        INSERT INTO mdt_permission_roles (job, grade, permissions, updated_by)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE permissions = VALUES(permissions), updated_by = VALUES(updated_by)
    ]], { payload.job, tonumber(payload.grade), json.encode(permissions), updatedBy })

    return { success = true }
end)

-- TAG MANAGEMENT

-- Ensure mdt_tags table exists
CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `mdt_tags` (
            `id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
            `name` VARCHAR(25) NOT NULL,
            `type` ENUM('officer','report','both') NOT NULL DEFAULT 'officer',
            `color` VARCHAR(7) NOT NULL DEFAULT '#6b7280',
            `job_type` ENUM('leo','ems','all') NOT NULL DEFAULT 'all',
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `unique_tag_name` (`name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- Fix ENUM if table was created with old 'citizen' value
    pcall(MySQL.query.await, [[
        ALTER TABLE `mdt_tags` MODIFY COLUMN `type` ENUM('officer','report','both') NOT NULL DEFAULT 'officer'
    ]])
    pcall(MySQL.query.await, [[
        ALTER TABLE `mdt_tags` ADD COLUMN `job_type` ENUM('leo','ems','all') NOT NULL DEFAULT 'all' AFTER `color`
    ]])
    -- Migrate any old 'citizen' rows to 'officer'
    pcall(MySQL.query.await, [[UPDATE `mdt_tags` SET `type` = 'officer' WHERE `type` = 'citizen']])

    -- Seed default tags if table is empty
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM mdt_tags')
    if (tonumber(count) or 0) == 0 then
        -- Default officer tags
        local officerDefaults = {
            { name = 'SWAT',          color = '#3b82f6' },
            { name = 'FTO',           color = '#10b981' },
            { name = 'Detective',     color = '#8b5cf6' },
            { name = 'Probation',     color = '#f59e0b' },
            { name = 'Command',       color = '#ef4444' },
            { name = 'K9 Certified',  color = '#06b6d4' },
            { name = 'Air Certified', color = '#ec4899' },
        }
        for _, tag in ipairs(officerDefaults) do
            pcall(MySQL.insert.await, 'INSERT IGNORE INTO mdt_tags (name, type, color) VALUES (?, ?, ?)', { tag.name, 'officer', tag.color })
        end

        -- Default report tags
        local reportDefaults = {
            { name = 'Robbery',            color = '#ef4444' },
            { name = 'Armed',              color = '#f97316' },
            { name = 'Priority',           color = '#f59e0b' },
            { name = 'Active',             color = '#10b981' },
            { name = 'Ballistics',         color = '#8b5cf6' },
            { name = 'Gang Related',       color = '#ec4899' },
            { name = 'Drug Related',       color = '#06b6d4' },
            { name = 'Traffic',            color = '#3b82f6' },
            { name = 'Domestic',           color = '#6b7280' },
            { name = 'Assault',            color = '#ef4444' },
            { name = 'High Priority',      color = '#f59e0b' },
            { name = 'Confidential',       color = '#8b5cf6' },
            { name = 'Active Investigation', color = '#10b981' },
        }
        for _, tag in ipairs(reportDefaults) do
            pcall(MySQL.insert.await, 'INSERT IGNORE INTO mdt_tags (name, type, color) VALUES (?, ?, ?)', { tag.name, 'report', tag.color })
        end

        -- Also import any existing tags from usage tables
        local existing = MySQL.query.await('SELECT DISTINCT tag FROM mdt_profiles_tags')
        for _, row in ipairs(existing or {}) do
            pcall(MySQL.insert.await, 'INSERT IGNORE INTO mdt_tags (name, type) VALUES (?, ?)', { row.tag, 'officer' })
        end
        local existingReport = MySQL.query.await('SELECT DISTINCT tag FROM mdt_reports_tags')
        for _, row in ipairs(existingReport or {}) do
            pcall(MySQL.insert.await, 'INSERT IGNORE INTO mdt_tags (name, type) VALUES (?, ?)', { row.tag, 'report' })
        end
    end
end)

ps.registerCallback(resourceName .. ':server:getTags', function(source, data)
    local src = source
    if not CheckAuth(src) then return {} end
    if not CheckPermission(src, 'management_tags') then return {} end
    EnsureMdtSchema()

    data = data or {}
    local jobType = data.jobType

    local query, params
    if jobType and (jobType == 'leo' or jobType == 'ems') then
        query = [[
            SELECT t.id, t.name, t.type, t.color, t.job_type, t.created_at,
                   (SELECT COUNT(*) FROM mdt_profiles_tags pt WHERE pt.tag = t.name) +
                   (SELECT COUNT(*) FROM mdt_reports_tags rt WHERE rt.tag = t.name) AS usage_count
            FROM mdt_tags t
            WHERE t.job_type = ? OR t.job_type = 'all'
            ORDER BY t.name ASC
        ]]
        params = { jobType }
    else
        query = [[
            SELECT t.id, t.name, t.type, t.color, t.job_type, t.created_at,
                   (SELECT COUNT(*) FROM mdt_profiles_tags pt WHERE pt.tag = t.name) +
                   (SELECT COUNT(*) FROM mdt_reports_tags rt WHERE rt.tag = t.name) AS usage_count
            FROM mdt_tags t
            ORDER BY t.name ASC
        ]]
        params = {}
    end

    local rows = MySQL.query.await(query, params)
    return rows or {}
end)

ps.registerCallback(resourceName .. ':server:createTag', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end
    if not CheckPermission(src, 'management_tags') then
        return { success = false, message = 'Sem permissão para gerenciar tags' }
    end
    EnsureMdtSchema()

    payload = payload or {}
    local name = payload.name
    local tagType = payload.type or 'officer'
    local color = payload.color or '#6b7280'
    local jobType = payload.job_type or 'all'

    if not name or name == '' then
        return { success = false, message = 'O nome da tag é obrigatório' }
    end
    if #name > 25 then
        return { success = false, message = 'O nome da tag deve ter no máximo 25 caracteres' }
    end

    -- Check duplicate
    local existing = MySQL.scalar.await('SELECT id FROM mdt_tags WHERE name = ?', { name })
    if existing then
        return { success = false, message = 'A tag já existe' }
    end

    local id = MySQL.insert.await('INSERT INTO mdt_tags (name, type, color, job_type) VALUES (?, ?, ?, ?)', { name, tagType, color, jobType })
    if not id then
        return { success = false, message = 'Falha ao criar a tag' }
    end

    return { success = true, id = id }
end)

ps.registerCallback(resourceName .. ':server:updateTag', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end
    if not CheckPermission(src, 'management_tags') then
        return { success = false, message = 'Sem permissão para gerenciar tags' }
    end
    EnsureMdtSchema()

    payload = payload or {}
    local id = tonumber(payload.id)
    local name = payload.name
    local tagType = payload.type
    local color = payload.color
    local jobType = payload.job_type or 'all'

    if not id then
        return { success = false, message = 'ID da tag inválido' }
    end
    if not name or name == '' then
        return { success = false, message = 'O nome da tag é obrigatório' }
    end
    if #name > 25 then
        return { success = false, message = 'O nome da tag deve ter no máximo 25 caracteres' }
    end

    -- Get old name to update references
    local oldRow = MySQL.query.await('SELECT name FROM mdt_tags WHERE id = ?', { id })
    local oldName = oldRow and oldRow[1] and oldRow[1].name

    -- Check duplicate (excluding self)
    local dup = MySQL.scalar.await('SELECT id FROM mdt_tags WHERE name = ? AND id != ?', { name, id })
    if dup then
        return { success = false, message = 'Já existe outra tag com esse nome' }
    end

    MySQL.update.await('UPDATE mdt_tags SET name = ?, type = ?, color = ?, job_type = ? WHERE id = ?', { name, tagType, color, jobType, id })

    -- Update references in profile tags and report tags if name changed
    if oldName and oldName ~= name then
        pcall(MySQL.update.await, 'UPDATE mdt_profiles_tags SET tag = ? WHERE tag = ?', { name, oldName })
        pcall(MySQL.update.await, 'UPDATE mdt_reports_tags SET tag = ? WHERE tag = ?', { name, oldName })
    end

    return { success = true }
end)

-- AWARDS MANAGEMENT -------------------------------------------

ps.registerCallback(resourceName .. ':server:getAwardConfigs', function(source)
    local src = source
    if not CheckAuth(src) then return {} end
    if not CheckPermission(src, 'management_settings') then return {} end

    local rows = MySQL.query.await([[
        SELECT id, name, description, icon, category, goal_type, goal_amount
        FROM mdt_awards
        ORDER BY id ASC
    ]])

    local result = {}
    for _, row in ipairs(rows or {}) do
        result[#result + 1] = {
            id = row.id,
            name = row.name,
            description = row.description or '',
            icon = row.icon or 'emoji_events',
            category = row.category or 'general',
            goalType = row.goal_type,
            goalAmount = tonumber(row.goal_amount) or 1,
        }
    end
    return result
end)

ps.registerCallback(resourceName .. ':server:saveAward', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end
    if not CheckPermission(src, 'management_settings') then
        return { success = false, message = 'Sem permissão para gerenciar premiações' }
    end

    payload = payload or {}
    local name = payload.name
    local description = payload.description or ''
    local icon = payload.icon or 'emoji_events'
    local category = payload.category or 'general'
    local goalType = payload.goalType
    local goalAmount = tonumber(payload.goalAmount) or 1

    if not name or name == '' then
        return { success = false, message = 'O nome da premiação é obrigatório' }
    end
    if not goalType or goalType == '' then
        return { success = false, message = 'O tipo de meta é obrigatório' }
    end

    local id = payload.id and tonumber(payload.id)

    if id then
        -- Update existing
        MySQL.update.await([[
            UPDATE mdt_awards
            SET name = ?, description = ?, icon = ?, category = ?, goal_type = ?, goal_amount = ?
            WHERE id = ?
        ]], { name, description, icon, category, goalType, goalAmount, id })
    else
        -- Create new
        id = MySQL.insert.await([[
            INSERT INTO mdt_awards (name, description, icon, category, goal_type, goal_amount)
            VALUES (?, ?, ?, ?, ?, ?)
        ]], { name, description, icon, category, goalType, goalAmount })
    end

    if not id then
        return { success = false, message = 'Falha ao salvar a premiação' }
    end

    return { success = true, id = id }
end)

ps.registerCallback(resourceName .. ':server:deleteAward', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end
    if not CheckPermission(src, 'management_settings') then
        return { success = false, message = 'Sem permissão para gerenciar premiações' }
    end

    payload = payload or {}
    local id = tonumber(payload.id)
    if not id then
        return { success = false, message = 'ID da premiação inválido' }
    end

    MySQL.query.await('DELETE FROM mdt_awards WHERE id = ?', { id })
    return { success = true }
end)

local function buildEmptyAwardsStats()
    return {
        name = 'Desconhecido',
        callsign = '',
        rank = '',
        reports = 0,
        arrests = 0,
        cases = 0,
        evidence = 0,
        bolos = 0,
        warrants = 0,
        totalFined = 0,
        totalMonths = 0,
        totalMultado = 0, -- frontend compatibility
        totalMeses = 0, -- frontend compatibility
        citations = 0,
    }
end

ps.registerCallback(resourceName .. ':server:getAwardsData', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, stats = buildEmptyAwardsStats(), awards = {}, leaderboard = {} } end
    if not CheckPermission(src, 'management_settings') then
        return { success = false, stats = buildEmptyAwardsStats(), awards = {}, leaderboard = {} }
    end
    EnsureMdtSchema()

    local citizenid = ps.getIdentifier(src)
    if not citizenid then return { success = false, stats = buildEmptyAwardsStats(), awards = {}, leaderboard = {} } end

    -- Get officer info
    local playerName = ps.getName(src) or 'Desconhecido'
    local jobData = ps.getJobData(src)
    local callsign = ''
    local rank = ''
    if jobData then
        callsign = jobData.callsign or ''
        if type(jobData.grade) == 'table' then
            rank = jobData.grade.name or jobData.grade.label or ''
        end
    end

    -- Get officer's stats from reports
    local reportCount = tonumber(MySQL.scalar.await(
        'SELECT COUNT(*) FROM mdt_reports WHERE author = ?', { citizenid }
    )) or 0

    local arrestCount = tonumber(MySQL.scalar.await(
        'SELECT COUNT(*) FROM mdt_reports WHERE author = ? AND type = ?', { citizenid, 'Arrest Report' }
    )) or 0

    local caseCount = tonumber(MySQL.scalar.await(
        'SELECT COUNT(DISTINCT co.case_id) FROM mdt_case_officers co WHERE co.citizenid = ?', { citizenid }
    )) or 0

    local evidenceCount = tonumber(MySQL.scalar.await(
        'SELECT COUNT(*) FROM mdt_evidence_items WHERE created_by = ?', { citizenid }
    )) or 0

    -- BOLOs linked via reports the officer authored
    local boloCount = tonumber(MySQL.scalar.await(
        'SELECT COUNT(*) FROM mdt_bolos b INNER JOIN mdt_reports r ON r.id = b.reportId WHERE r.author = ?', { citizenid }
    )) or 0

    -- Warrants linked via reports the officer authored
    local warrantCount = tonumber(MySQL.scalar.await(
        'SELECT COUNT(*) FROM mdt_reports_warrants w INNER JOIN mdt_reports r ON r.id = w.reportid WHERE r.author = ?', { citizenid }
    )) or 0

    local totalFined = tonumber(MySQL.scalar.await(
        'SELECT COALESCE(SUM(rc.fine), 0) FROM mdt_reports_charges rc INNER JOIN mdt_reports r ON r.id = rc.reportid WHERE r.author = ?', { citizenid }
    )) or 0

    local totalMonths = tonumber(MySQL.scalar.await(
        'SELECT COALESCE(SUM(rc.time), 0) FROM mdt_reports_charges rc INNER JOIN mdt_reports r ON r.id = rc.reportid WHERE r.author = ?', { citizenid }
    )) or 0

    local citations = tonumber(MySQL.scalar.await(
        'SELECT COUNT(*) FROM mdt_reports WHERE author = ? AND type = ?', { citizenid, 'Citation' }
    )) or 0

    local myStats = {
        name = playerName,
        callsign = callsign,
        rank = rank,
        reports = reportCount,
        arrests = arrestCount,
        cases = caseCount,
        evidence = evidenceCount,
        bolos = boloCount,
        warrants = warrantCount,
        totalFined = totalFined,
        totalMonths = totalMonths,
        totalMultado = totalFined, -- frontend compatibility
        totalMeses = totalMonths, -- frontend compatibility
        citations = citations,
    }

    -- Map stat names to goal types
    local statMap = {
        reports = reportCount,
        arrests = arrestCount,
        cases = caseCount,
        evidence = evidenceCount,
        bolos = boloCount,
        warrants = warrantCount,
        totalFined = totalFined,
        totalMonths = totalMonths,
        citations = citations,
    }

    -- Get award configs and compute progress
    local awardRows = MySQL.query.await([[
        SELECT id, name, description, icon, category, goal_type, goal_amount
        FROM mdt_awards ORDER BY id ASC
    ]])

    local awards = {}
    for _, row in ipairs(awardRows or {}) do
        local progress = statMap[row.goal_type] or 0
        local goalAmount = tonumber(row.goal_amount) or 1
        local earned = progress >= goalAmount

        awards[#awards + 1] = {
            id = row.id,
            name = row.name,
            description = row.description or '',
            icon = row.icon or 'emoji_events',
            category = row.category or 'general',
            goalType = row.goal_type,
            goalAmount = goalAmount,
            progress = progress,
            earned = earned,
            earnedDate = earned and os.date('%Y-%m-%d') or nil,
        }
    end

    -- Build leaderboard from all officers who have filed reports
    local leaderboardRows = MySQL.query.await([[
        SELECT
            r.author,
            r.authorplaintext,
            COUNT(*) as total_reports,
            SUM(CASE WHEN r.type = 'Arrest Report' THEN 1 ELSE 0 END) as total_arrests,
            SUM(CASE WHEN r.type = 'Citation' THEN 1 ELSE 0 END) as total_citations
        FROM mdt_reports r
        WHERE r.author IS NOT NULL AND r.author != ''
        GROUP BY r.author, r.authorplaintext
        ORDER BY total_reports DESC
        LIMIT 25
    ]])

    local leaderboard = {}
    for i, row in ipairs(leaderboardRows or {}) do
        local cid = row.author
        local reports = tonumber(row.total_reports) or 0
        local arrests = tonumber(row.total_arrests) or 0

        -- Get additional stats per officer
        local oCases = tonumber(MySQL.scalar.await(
            'SELECT COUNT(DISTINCT case_id) FROM mdt_case_officers WHERE citizenid = ?', { cid }
        )) or 0

        local oWarrants = tonumber(MySQL.scalar.await(
            'SELECT COUNT(*) FROM mdt_reports_warrants w INNER JOIN mdt_reports r ON r.id = w.reportid WHERE r.author = ?', { cid }
        )) or 0

        local oFined = tonumber(MySQL.scalar.await(
            'SELECT COALESCE(SUM(rc.fine), 0) FROM mdt_reports_charges rc INNER JOIN mdt_reports r ON r.id = rc.reportid WHERE r.author = ?', { cid }
        )) or 0

        local oMonths = tonumber(MySQL.scalar.await(
            'SELECT COALESCE(SUM(rc.time), 0) FROM mdt_reports_charges rc INNER JOIN mdt_reports r ON r.id = rc.reportid WHERE r.author = ?', { cid }
        )) or 0

        local score = reports + (arrests * 2) + (oCases * 3) + (oWarrants * 5) + math.floor(oFined / 1000) + oMonths

        leaderboard[#leaderboard + 1] = {
            rank = i,
            name = row.authorplaintext or 'Desconhecido',
            callsign = '',
            department = '',
            reports = reports,
            arrests = arrests,
            cases = oCases,
            warrants = oWarrants,
            totalFined = oFined,
            totalMonths = oMonths,
            totalMultado = oFined, -- frontend compatibility
            totalMeses = oMonths, -- frontend compatibility
            score = score,
            isCurrentUser = (cid == citizenid),
        }
    end

    -- Sort leaderboard by score descending and re-rank
    table.sort(leaderboard, function(a, b) return a.score > b.score end)
    for i, entry in ipairs(leaderboard) do
        entry.rank = i
    end

    return {
        success = true,
        stats = myStats,
        awards = awards,
        leaderboard = leaderboard,
    }
end)

-- CUSTOM LICENSES MANAGEMENT -------------------------------------------

ps.registerCallback(resourceName .. ':server:getCustomLicenses', function(source)
    local src = source
    if not CheckAuth(src) then return {} end
    if not CheckPermission(src, 'management_settings') then return {} end

    local rows = MySQL.query.await([[
        SELECT id, name, description FROM mdt_custom_licenses ORDER BY id ASC
    ]])

    local result = {}
    for _, row in ipairs(rows or {}) do
        result[#result + 1] = {
            id = row.id,
            name = row.name,
            description = row.description or '',
        }
    end
    return result
end)

ps.registerCallback(resourceName .. ':server:saveCustomLicense', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end
    if not CheckPermission(src, 'management_settings') then
        return { success = false, message = 'Sem permissão para gerenciar licenças' }
    end

    payload = payload or {}
    local name = payload.name
    local description = payload.description or ''

    if not name or name == '' then
        return { success = false, message = 'O nome da licença é obrigatório' }
    end

    local id = payload.id and tonumber(payload.id)

    if id then
        -- Check duplicate (excluding self)
        local dup = MySQL.scalar.await('SELECT id FROM mdt_custom_licenses WHERE name = ? AND id != ?', { name, id })
        if dup then
            return { success = false, message = 'Já existe uma licença com esse nome' }
        end
        MySQL.update.await('UPDATE mdt_custom_licenses SET name = ?, description = ? WHERE id = ?', { name, description, id })
    else
        -- Check duplicate
        local existing = MySQL.scalar.await('SELECT id FROM mdt_custom_licenses WHERE name = ?', { name })
        if existing then
            return { success = false, message = 'Já existe uma licença com esse nome' }
        end
        id = MySQL.insert.await('INSERT INTO mdt_custom_licenses (name, description) VALUES (?, ?)', { name, description })
    end

    if not id then
        return { success = false, message = 'Falha ao salvar a licença' }
    end

    return { success = true, id = id }
end)

ps.registerCallback(resourceName .. ':server:deleteCustomLicense', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end
    if not CheckPermission(src, 'management_settings') then
        return { success = false, message = 'Sem permissão para gerenciar licenças' }
    end

    payload = payload or {}
    local id = tonumber(payload.id)
    if not id then
        return { success = false, message = 'ID da licença inválido' }
    end

    MySQL.query.await('DELETE FROM mdt_custom_licenses WHERE id = ?', { id })
    return { success = true }
end)

ps.registerCallback(resourceName .. ':server:deleteTag', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end
    if not CheckPermission(src, 'management_tags') then
        return { success = false, message = 'Sem permissão para gerenciar tags' }
    end
    EnsureMdtSchema()

    payload = payload or {}
    local id = tonumber(payload.id)
    if not id then
        return { success = false, message = 'ID da tag inválido' }
    end

    -- Get name before deleting so we can clean up references
    local row = MySQL.query.await('SELECT name FROM mdt_tags WHERE id = ?', { id })
    local tagName = row and row[1] and row[1].name

    MySQL.query.await('DELETE FROM mdt_tags WHERE id = ?', { id })

    -- Optionally clean up references (remove tag from all profiles/reports)
    if tagName then
        pcall(MySQL.query.await, 'DELETE FROM mdt_profiles_tags WHERE tag = ?', { tagName })
        pcall(MySQL.query.await, 'DELETE FROM mdt_reports_tags WHERE tag = ?', { tagName })
    end

    return { success = true }
end)
