-- Authorisation --
local ps = RequirePs('server/auth.lua')

function CheckAuth(source)
    ps.debug('Checking MDT Authorization')
    local jobType = ps.getJobType(source)
    if jobType ~= Config.PoliceJobType and jobType ~= Config.MedicalJobType then
        ps.debug('Access Denied for ID: ' .. source .. ', Name: ' .. ps.getPlayerName(source) .. ', not an authorized job type')
        ps.notify(source, 'Acesso negado: apenas pessoal autorizado', 'error')
        return false
    else
        ps.debug('Access Granted for ID: ' .. source .. ', Name: ' .. ps.getPlayerName(source) .. ', job type: ' .. tostring(jobType))
        return true
    end
end

-- Check if a player has a specific permission (by job + grade lookup)
function CheckPermission(source, permName)
    if not source or not permName then return false end

    local jobData = ps.getJobData and ps.getJobData(source) or nil
    local jobName = ps.getJobName(source) or 'police'
    local gradeValue = NormalizeMdtGradeValue(jobData and jobData.grade or 0)
    local rankData = GetMdtRankData(jobName, gradeValue, type(jobData and jobData.grade) == 'table' and jobData.grade or nil)

    -- Boss always has all permissions
    if rankData.isBoss or (ps.isBoss and ps.isBoss(source)) then return true end

    -- Check database
    local row = MySQL.single.await('SELECT permissions FROM mdt_permission_roles WHERE job = ? AND grade = ?', { jobName, gradeValue })
    if row and row.permissions then
        local ok, decoded = pcall(json.decode, row.permissions)
        if ok and type(decoded) == 'table' then
            for _, p in ipairs(decoded) do
                if p == permName then return true end
            end
            return false
        end
    end

    -- Check config defaults
    for _, p in ipairs(GetMdtDefaultPermissions(jobName, gradeValue, rankData.isBoss)) do
        if p == permName then return true end
    end

    return false
end

local function upsertProfileSession(src, action)
    if not src then return end
    local citizenid = ps.getIdentifier(src)
    if not citizenid then return end

    local fullName = ps.getPlayerName(src)
    local callsign = ps.getMetadata(src, 'callsign')
    local job = ps.getJobData and ps.getJobData(src) or nil
    local jobName = job and job.name or ps.getJobName(src)
    local jobGrade = job and job.grade and job.grade.name or ps.getJobGradeName(src)

    local ok, profileId = pcall(EnsureProfileData,
        citizenid,
        fullName,
        callsign,
        callsign,
        jobGrade,
        jobName
    )

    if not ok or not profileId then
        ps.warn('Failed to upsert profile session for ' .. tostring(citizenid) .. ': ' .. tostring(profileId))
        return
    end

    if action == 'login' then
        -- Wrap all login operations in a single transaction to prevent race conditions
        local okTx, errTx = pcall(MySQL.transaction.await, {
            {
                query = [[
                    UPDATE mdt_profile_sessions
                    SET logout_at = NOW()
                    WHERE profile_id = ? AND logout_at IS NULL
                ]],
                values = { profileId }
            },
            {
                query = [[
                    INSERT INTO mdt_profile_sessions (profile_id, citizenid, source, login_at)
                    VALUES (?, ?, ?, NOW())
                ]],
                values = { profileId, citizenid, src }
            },
            {
                query = 'UPDATE mdt_profiles SET last_login_at = NOW() WHERE id = ?',
                values = { profileId }
            },
        })
        if not okTx then
            ps.warn('Failed to create login session (transaction): ' .. tostring(errTx))
        end
    elseif action == 'logout' then
        local okTx, errTx = pcall(MySQL.transaction.await, {
            {
                query = [[
                    UPDATE mdt_profile_sessions
                    SET logout_at = NOW()
                    WHERE profile_id = ? AND logout_at IS NULL
                    ORDER BY id DESC
                    LIMIT 1
                ]],
                values = { profileId }
            },
            {
                query = 'UPDATE mdt_profiles SET last_logout_at = NOW() WHERE id = ?',
                values = { profileId }
            },
        })
        if not okTx then
            ps.warn('Failed to update logout session (transaction): ' .. tostring(errTx))
        end
    end
end

-- Discord webhook helper for duty logging
local function SendDutyWebhook(officerName, citizenid, action, jobName)
    local webhook = Config.Webhooks and Config.Webhooks.DutyLog or ''
    if webhook == '' then return end

    local color = action == 'login' and 65280 or 16711680 -- green for login, red for logout
    local title = action == 'login' and 'Entrada de serviço no MDT' or 'Saída de serviço no MDT'
    local timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')

    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({
        embeds = {{
            title = title,
            color = color,
            fields = {
                { name = 'Officer', value = officerName or 'Unknown', inline = true },
                { name = 'Citizen ID', value = citizenid or 'N/A', inline = true },
                { name = 'Department', value = jobName or 'Unknown', inline = true },
                { name = 'Time', value = os.date('%Y-%m-%d %H:%M:%S'), inline = false },
            },
            timestamp = timestamp,
        }}
    }), { ['Content-Type'] = 'application/json' })
end

RegisterNetEvent('ps-mdt:server:trackLogin', function()
    local src = source
    upsertProfileSession(src, 'login')
    if ps.auditLog then
        ps.auditLog(src, 'mdt_login', 'profile', ps.getIdentifier(src), {})
    end
    -- Discord webhook
    local officerName = ps.getPlayerName(src) or 'Unknown'
    local citizenid = ps.getIdentifier(src) or 'N/A'
    local jobName = ps.getJobName(src) or 'Unknown'
    SendDutyWebhook(officerName, citizenid, 'login', jobName)
end)

RegisterNetEvent('ps-mdt:server:trackLogout', function()
    local src = source
    upsertProfileSession(src, 'logout')
    if ps.auditLog then
        ps.auditLog(src, 'mdt_logout', 'profile', ps.getIdentifier(src), {})
    end
    -- Discord webhook
    local officerName = ps.getPlayerName(src) or 'Unknown'
    local citizenid = ps.getIdentifier(src) or 'N/A'
    local jobName = ps.getJobName(src) or 'Unknown'
    SendDutyWebhook(officerName, citizenid, 'logout', jobName)
end)

AddEventHandler('playerDropped', function()
    local src = source
    upsertProfileSession(src, 'logout')
end)

ps.registerCallback(tostring(GetCurrentResourceName())..':server:checkAuth', function(source)
    return CheckAuth(source)
end)

-- Get the current player's permissions based on their job + grade
ps.registerCallback(tostring(GetCurrentResourceName())..':server:getMyPermissions', function(source)
    local src = source
    if not CheckAuth(src) then return { permissions = {} } end

    local jobName = ps.getJobName(src) or 'police'
    local jobData = ps.getJobData and ps.getJobData(src) or nil
    local gradeValue = NormalizeMdtGradeValue(jobData and jobData.grade or 0)
    local rankData = GetMdtRankData(jobName, gradeValue, type(jobData and jobData.grade) == 'table' and jobData.grade or nil)

    -- Boss gets all permissions
    if rankData.isBoss or (ps.isBoss and ps.isBoss(src)) then
        return { permissions = GetMdtAllPermissions(), isBoss = true }
    end

    -- Check database for stored permissions
    local row = MySQL.single.await('SELECT permissions FROM mdt_permission_roles WHERE job = ? AND grade = ?', { jobName, gradeValue })
    if row and row.permissions then
        local ok, decoded = pcall(json.decode, row.permissions)
        if ok and type(decoded) == 'table' then
            return { permissions = decoded, isBoss = false, grade = gradeValue, rank = rankData.label }
        end
    end

    -- Check config defaults
    return {
        permissions = GetMdtDefaultPermissions(jobName, gradeValue, false),
        isBoss = false,
        grade = gradeValue,
        rank = rankData.label,
    }
end)
