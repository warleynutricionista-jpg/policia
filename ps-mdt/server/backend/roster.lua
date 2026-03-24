
local function getCertifications(citizenid)
    EnsureProfileExists(citizenid)

    local profile = MySQL.single.await('SELECT certifications FROM mdt_profiles WHERE citizenid = ?', { citizenid })
    if not profile then
        return {}
    end

    if profile.certifications and profile.certifications ~= '' then
        local ok, decoded = pcall(json.decode, profile.certifications)
        if ok and type(decoded) == 'table' then
            return decoded
        end
    end

    return {}
end

local function checkDuty(citizenid)
   local player = ps.getPlayerByIdentifier(citizenid)
   if not player then return 'Fora de serviço' end

   local src = player.source or (player.PlayerData and player.PlayerData.source)
   if not src then return 'Fora de serviço' end

   if IsPoliceJob(ps.getJobName(src), ps.getJobType(src)) and ps.getJobDuty(src) then
      return 'Em serviço'
   end
   return 'Fora de serviço'
end

local function getMultiJobEmployeeData(citizenid, jobName)
    if GetResourceState('ps-multijob') ~= 'started' or not exports['ps-multijob'] then
        return nil
    end

    local ok, jobs = pcall(function()
        return exports['ps-multijob']:GetJobs(citizenid)
    end)
    if not ok or type(jobs) ~= 'table' then
        return nil
    end

    if type(jobs[jobName]) == 'table' then
        return jobs[jobName]
    end

    for _, jobData in pairs(jobs) do
        if type(jobData) == 'table' then
            local name = tostring(jobData.job or jobData.name or '')
            if name == tostring(jobName) then
                return jobData
            end
        end
    end

    return nil
end

local function getPoliceEmployeeData(citizenid, primaryJob)
    local primaryJobName = primaryJob and primaryJob.name and tostring(primaryJob.name) or nil
    if primaryJobName and IsPoliceJob(primaryJobName, primaryJob.type) then
        return {
            job = primaryJobName,
            grade = NormalizeMdtGradeValue(primaryJob.grade),
            gradeData = type(primaryJob.grade) == 'table' and primaryJob.grade or ps.getSharedJobGrade(primaryJobName, primaryJob.grade),
            type = primaryJob.type,
        }
    end

    if GetResourceState('ps-multijob') ~= 'started' or not exports['ps-multijob'] then
        return nil
    end

    local ok, jobs = pcall(function()
        return exports['ps-multijob']:GetJobs(citizenid)
    end)
    if not ok or type(jobs) ~= 'table' then
        return nil
    end

    for _, jobData in pairs(jobs) do
        if type(jobData) == 'table' then
            local jobName = tostring(jobData.job or jobData.name or '')
            local sharedGrade = ps.getSharedJobGrade(jobName, jobData.grade)
            local sharedJob = ps.getSharedJobData(jobName)
            local jobType = jobData.type or (sharedGrade and sharedGrade.type) or (sharedJob and sharedJob.type) or nil
            if IsPoliceJob(jobName, jobType) then
                return {
                    job = jobName,
                    grade = NormalizeMdtGradeValue(jobData.grade),
                    gradeData = sharedGrade,
                    type = jobType,
                }
            end
        end
    end

    return nil
end

local function decodeJsonField(value)
    if not value or value == '' then
        return {}
    end

    local ok, decoded = pcall(json.decode, value)
    return ok and type(decoded) == 'table' and decoded or {}
end

local function buildRosterEntry(citizenid, charinfo, metadata, employee, status)
    local firstName = charinfo.firstname or 'N/A'
    local lastName = charinfo.lastname or 'N/A'
    local callsign = metadata.callsign or 'N/A'
    local rankData = GetMdtRankData(employee.job, employee.grade, employee.gradeData)

    return {
        citizenid = citizenid,
        callsign = callsign,
        firstName = firstName,
        lastName = lastName,
        rank = rankData.label,
        rankOrder = rankData.level,
        department = employee.job or ((Config and Config.PoliceJobs and Config.PoliceJobs[1]) or 'police'),
        status = status,
        certifications = getCertifications(citizenid),
        badgeNumber = callsign,
    }
end

local function buildRoster()
    local rosterList = {}
    local activeUnits = {}
    local byCitizenId = {}

    for _, playerId in ipairs(ps.getAllPlayers() or {}) do
        local src = tonumber(playerId)
        local playerData = ps.getPlayerData(src)
        if playerData and playerData.citizenid then
            local employee = getPoliceEmployeeData(playerData.citizenid, playerData.job)
            if employee then
                local entry = buildRosterEntry(
                    playerData.citizenid,
                    playerData.charinfo or {},
                    playerData.metadata or {},
                    employee,
                    (playerData.job and playerData.job.onduty) and 'Em serviço' or 'Fora de serviço'
                )
                byCitizenId[playerData.citizenid] = entry
            end
        end
    end

    for _, citizen in ipairs(MySQL.query.await('SELECT citizenid, charinfo, job, metadata FROM players', {}) or {}) do
        local citizenid = citizen.citizenid
        if citizenid and not byCitizenId[citizenid] then
            local charinfo = decodeJsonField(citizen.charinfo)
            local job = decodeJsonField(citizen.job)
            local metadata = decodeJsonField(citizen.metadata)
            local employee = getPoliceEmployeeData(citizenid, job)
            if employee then
                byCitizenId[citizenid] = buildRosterEntry(citizenid, charinfo, metadata, employee, checkDuty(citizenid))
            end
        end
    end

    for citizenid, entry in pairs(byCitizenId) do
        entry.id = #rosterList + 1
        rosterList[#rosterList + 1] = entry

        if entry.status == 'Em serviço' then
            activeUnits[#activeUnits + 1] = {
                id = entry.id,
                badgeNumber = entry.badgeNumber,
                callsign = entry.callsign,
                firstName = entry.firstName,
                lastName = entry.lastName,
                rank = entry.rank,
                rankOrder = entry.rankOrder,
            }
        end
    end

    table.sort(rosterList, function(a, b)
        if a.rankOrder ~= b.rankOrder then
            return (a.rankOrder or 0) < (b.rankOrder or 0)
        end
        if a.department ~= b.department then
            return (a.department or '') < (b.department or '')
        end
        if a.callsign ~= b.callsign then
            return (a.callsign or '') < (b.callsign or '')
        end
        return ((a.firstName or '') .. (a.lastName or '')) < ((b.firstName or '') .. (b.lastName or ''))
    end)

    table.sort(activeUnits, function(a, b)
        if a.rankOrder ~= b.rankOrder then
            return (a.rankOrder or 0) < (b.rankOrder or 0)
        end
        return (a.callsign or '') < (b.callsign or '')
    end)

    for index, entry in ipairs(rosterList) do
        entry.id = index
    end

    for index, entry in ipairs(activeUnits) do
        entry.id = index
    end

    return {
        roster = rosterList,
        activeUnits = activeUnits,
    }
end

ps.registerCallback('ps-mdt:server:getRosterList', function(source)
    if not CheckAuth(source) then
        return { roster = {}, activeUnits = {} }
    end

    return buildRoster()
end)

-- Get available officer tags/certifications
ps.registerCallback('ps-mdt:server:getOfficerTags', function(source)
    local src = source
    if not CheckAuth(src) then return {} end
    local rows = MySQL.query.await([[
        SELECT id, name, color FROM mdt_tags
        WHERE type IN ('officer', 'both')
        ORDER BY name ASC
    ]])
    return rows or {}
end)

-- Update officer certifications
ps.registerCallback('ps-mdt:server:updateOfficerCertifications', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end
    if not CheckPermission(src, 'roster_manage_certifications') then
        return { success = false, message = 'Sem permissão para gerenciar certificações' }
    end

    payload = payload or {}
    local citizenid = payload.citizenid
    local certifications = payload.certifications

    if not citizenid or type(certifications) ~= 'table' then
        return { success = false, message = 'Payload inválido' }
    end

    EnsureProfileExists(citizenid)

    local encoded = json.encode(certifications)
    MySQL.update.await('UPDATE mdt_profiles SET certifications = ? WHERE citizenid = ?', { encoded, citizenid })

    return { success = true }
end)

-- Get job grades for a specific department
ps.registerCallback('ps-mdt:server:getJobGrades', function(source, payload)
    local src = source
    if not CheckAuth(src) then return {} end
    if not CheckPermission(src, 'roster_manage_officers') then return {} end

    payload = payload or {}
    local jobName = payload.job or ps.getJobName(src) or ((Config and Config.PoliceJobs and Config.PoliceJobs[1]) or 'police')

    local jobData = ps.getSharedJob(jobName)
    if not jobData or not jobData.grades then return {} end

    local grades = {}
    for gradeKey, gradeValue in pairs(jobData.grades) do
        local rankData = GetMdtRankData(jobName, gradeKey, gradeValue)
        grades[#grades + 1] = {
            grade = rankData.level,
            name = rankData.label,
            isBoss = rankData.isBoss,
        }
    end

    table.sort(grades, function(a, b) return a.grade < b.grade end)
    return grades
end)

-- Promote/demote an officer (change their job grade)
ps.registerCallback('ps-mdt:server:promoteOfficer', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end
    if not CheckPermission(src, 'roster_manage_officers') then
        return { success = false, message = 'Sem permissão para gerenciar oficiais' }
    end

    payload = payload or {}
    local citizenid = payload.citizenid
    local jobName = payload.job
    local newGrade = tonumber(payload.grade)

    if not citizenid or not jobName or not newGrade then
        return { success = false, message = 'Faltam campos obrigatórios' }
    end

    -- Validate the grade exists
    local gradeData = ps.getSharedJobGrade(jobName, newGrade)
    if not gradeData then
        return { success = false, message = 'Patente inválida para este emprego' }
    end

    -- Find the target player (must be online for QBCore SetJob)
    local targetPlayer = ps.getPlayerByIdentifier(citizenid)
    if not targetPlayer then
        return { success = false, message = 'O oficial precisa estar online para alterar a patente' }
    end

    local targetSrc = targetPlayer.source or (targetPlayer.PlayerData and targetPlayer.PlayerData.source)
    if not targetSrc then
        return { success = false, message = 'Não foi possível identificar a source do oficial' }
    end

    -- Don't allow changing your own rank
    if targetSrc == src then
        return { success = false, message = 'Você não pode alterar sua própria patente' }
    end

    ps.setJob(targetSrc, jobName, newGrade)
    Cache.invalidate('reports:officers:directory')

    local gradeName = GetMdtRankData(jobName, newGrade, gradeData).label

    if ps.auditLog then
        ps.auditLog(src, 'officer_promoted', 'officers', citizenid, {
            job = jobName,
            grade = newGrade,
            gradeName = gradeName,
        })
    end

    return { success = true, message = 'Patente do oficial atualizada para ' .. gradeName }
end)

-- Fire an officer (set their job to unemployed)
ps.registerCallback('ps-mdt:server:fireOfficer', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end
    if not CheckPermission(src, 'roster_manage_officers') then
        return { success = false, message = 'Sem permissão para gerenciar oficiais' }
    end

    payload = payload or {}
    local citizenid = payload.citizenid

    if not citizenid then
        return { success = false, message = 'Faltando ID do cidadão' }
    end

    local targetPlayer = ps.getPlayerByIdentifier(citizenid)
    if not targetPlayer then
        return { success = false, message = 'O oficial precisa estar online para ser desligado' }
    end

    local targetSrc = targetPlayer.source or (targetPlayer.PlayerData and targetPlayer.PlayerData.source)
    if not targetSrc then
        return { success = false, message = 'Não foi possível identificar a source do oficial' }
    end

    -- Don't allow firing yourself
    if targetSrc == src then
        return { success = false, message = 'Você não pode demitir a si mesmo' }
    end

    ps.setJob(targetSrc, 'unemployed', 0)
    Cache.invalidate('reports:officers:directory')

    if ps.auditLog then
        ps.auditLog(src, 'officer_fired', 'officers', citizenid, {})
    end

    return { success = true, message = 'O oficial foi desligado' }
end)

-- Update officer callsign (wrapper around existing setCallsign for NUI)
ps.registerCallback('ps-mdt:server:updateOfficerCallsign', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end
    if not CheckPermission(src, 'roster_manage_officers') then
        return { success = false, message = 'Sem permissão para gerenciar oficiais' }
    end

    payload = payload or {}
    local citizenid = payload.citizenid
    local newCallsign = payload.callsign

    if not citizenid or not newCallsign or newCallsign == '' then
        return { success = false, message = 'Faltando ID do cidadão ou indicativo' }
    end

    -- Use the existing setCallsign callback logic (QBox first, fallback QBCore)
    local QBCore = nil
    local okQbx, qbx = pcall(function() return exports['qbx_core']:GetCoreObject() end)
    if okQbx and qbx then
        QBCore = qbx
    else
        local okQb, qb = pcall(function() return exports['qb-core']:GetCoreObject() end)
        if okQb and qb then QBCore = qb end
    end

    if not QBCore then
        return { success = false, message = 'Framework principal indisponível' }
    end

    local Player = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    if not Player then
        return { success = false, message = 'O oficial precisa estar online para atualizar o indicativo' }
    end

    Player.Functions.SetMetaData('callsign', newCallsign)

    local resourceName = GetCurrentResourceName()
    TriggerClientEvent(resourceName .. ':client:updateCallsign', Player.PlayerData.source, newCallsign)

    MySQL.update.await('UPDATE mdt_profiles SET callsign = ? WHERE citizenid = ?', { newCallsign, citizenid })
    Cache.invalidate('reports:officers:directory')

    if ps.auditLog then
        ps.auditLog(src, 'callsign_changed', 'officers', citizenid, { callsign = newCallsign })
    end

    return { success = true, message = 'Indicativo atualizado para ' .. newCallsign }
end)
