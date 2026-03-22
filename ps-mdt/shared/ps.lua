local resourceName = GetCurrentResourceName()

local function getResourceStartedState(name)
    local state = GetResourceState(name)
    return state == 'started' or state == 'starting'
end

local function safePrint(level, ...)
    local parts = { ('[%s][%s]'):format(resourceName, level) }
    for i = 1, select('#', ...) do
        parts[#parts + 1] = tostring(select(i, ...))
    end
    print(table.concat(parts, ' '))
end

local function tryInitPsLib()
    if not getResourceStartedState('ps_lib') then
        return nil
    end

    local ok, result = pcall(function()
        return exports.ps_lib:init()
    end)

    if not ok or type(result) ~= 'table' then
        return nil
    end

    if type(result.callback) ~= 'function' then
        return nil
    end

    if IsDuplicityVersion() and type(result.registerCallback) ~= 'function' then
        return nil
    end

    return result
end

local function getCoreObject()
    local okQbx, qbx = pcall(function()
        return exports['qbx_core']:GetCoreObject()
    end)
    if okQbx and qbx then
        return qbx, 'qbx'
    end

    local okQb, qb = pcall(function()
        return exports['qb-core']:GetCoreObject()
    end)
    if okQb and qb then
        return qb, 'qb'
    end

    return nil, nil
end

local function getSharedJobs()
    local core = select(1, getCoreObject())
    return core and core.Shared and core.Shared.Jobs or nil
end

local function getSharedJob(jobName)
    local jobs = getSharedJobs()
    return jobs and jobs[jobName] or nil
end

local function normalizePlayerData(player)
    if not player then return nil end
    return player.PlayerData or player
end

local function getPlayerFromCore(source)
    local core = select(1, getCoreObject())
    if not core or not core.Functions or not core.Functions.GetPlayer then
        return nil
    end
    return core.Functions.GetPlayer(source)
end

local function getPlayerByCitizenId(citizenid)
    if not citizenid then return nil end

    local okQbx, qbxPlayer = pcall(function()
        return exports['qbx_core']:GetPlayerByCitizenId(citizenid)
    end)
    if okQbx and qbxPlayer then
        return qbxPlayer
    end

    local core = select(1, getCoreObject())
    if core and core.Functions and core.Functions.GetPlayerByCitizenId then
        return core.Functions.GetPlayerByCitizenId(citizenid)
    end

    return nil
end

local function getClientPlayerData()
    local core = select(1, getCoreObject())
    if core and core.Functions and core.Functions.GetPlayerData then
        local ok, data = pcall(core.Functions.GetPlayerData)
        if ok and data then
            return data
        end
    end

    local state = LocalPlayer and LocalPlayer.state or nil
    if state and state.PlayerData then
        return state.PlayerData
    end

    return nil
end

local function getServerPlayerData(source)
    local player = getPlayerFromCore(source)
    return normalizePlayerData(player)
end

local function getPlayerData(source)
    if IsDuplicityVersion() then
        return getServerPlayerData(source)
    end
    return getClientPlayerData()
end

local function getJobData(source)
    local playerData = getPlayerData(source)
    return playerData and playerData.job or nil
end

local function getGradeLevel(grade)
    if type(grade) ~= 'table' then
        return tonumber(grade) or grade or 0
    end
    return grade.level or grade.grade or grade.rank or grade.value or grade.id or 0
end

local function getMetadataValue(metadata, key)
    if type(metadata) ~= 'table' then return nil end
    if key == nil then return metadata end
    return metadata[key]
end

local function resolveNameFromData(playerData)
    if not playerData then return nil end
    local charinfo = playerData.charinfo or {}
    local first = charinfo.firstname or ''
    local last = charinfo.lastname or ''
    local fullname = (first .. ' ' .. last):gsub('^%s+', ''):gsub('%s+$', '')
    if fullname ~= '' then
        return fullname
    end
    return playerData.name or playerData.charname or nil
end

local function ensureLoadedModel(model)
    if type(model) == 'string' then
        model = joaat(model)
    end
    if not model then return false end
    if HasModelLoaded(model) then return true end
    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do
        Wait(0)
    end
    return HasModelLoaded(model)
end

local function ensureLoadedAnim(dict)
    if not dict then return false end
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do
        Wait(0)
    end
    return HasAnimDictLoaded(dict)
end

local fallback = {
    __name = 'ps-mdt-fallback',
}

function fallback.debug(...)
    if Config and Config.Debug then
        safePrint('DEBUG', ...)
    end
end

function fallback.info(...)
    safePrint('INFO', ...)
end

function fallback.warn(...)
    safePrint('WARN', ...)
end

function fallback.error(...)
    safePrint('ERROR', ...)
end

function fallback.callback(name, ...)
    if not lib or not lib.callback or not lib.callback.await then
        fallback.warn('lib.callback.await unavailable for', name)
        return nil
    end
    return lib.callback.await(name, false, ...)
end

function fallback.registerCallback(name, handler)
    if not lib or not lib.callback or not lib.callback.register then
        fallback.warn('lib.callback.register unavailable for', name)
        return
    end
    lib.callback.register(name, handler)
end

function fallback.notify(targetOrDescription, descriptionOrType, typeOrDuration, duration)
    if IsDuplicityVersion() then
        local target = tonumber(targetOrDescription)
        if not target then
            return
        end
        TriggerClientEvent('ox_lib:notify', target, {
            description = tostring(descriptionOrType or ''),
            type = typeOrDuration or 'inform',
            duration = duration,
        })
        return
    end

    local payload
    if type(targetOrDescription) == 'table' then
        payload = targetOrDescription
    else
        payload = {
            description = tostring(targetOrDescription or ''),
            type = descriptionOrType or 'inform',
            duration = typeOrDuration,
        }
    end

    if lib and lib.notify then
        lib.notify(payload)
    else
        safePrint('INFO', payload.description or '')
    end
end

function fallback.getPlayer(source)
    if not IsDuplicityVersion() then
        return getClientPlayerData()
    end
    return getPlayerFromCore(source)
end

function fallback.getPlayerData(source)
    return getPlayerData(source)
end

function fallback.getJob(source)
    return getJobData(source)
end

function fallback.getJobData(source)
    return getJobData(source)
end

function fallback.getJobName(source)
    local job = getJobData(source)
    return job and job.name or nil
end

function fallback.getJobType(source)
    local job = getJobData(source)
    return job and job.type or nil
end

function fallback.getJobDuty(source)
    local job = getJobData(source)
    return job and job.onduty or false
end

function fallback.getJobGradeName(source)
    local job = getJobData(source)
    local grade = job and job.grade or nil
    if type(grade) == 'table' then
        return grade.name or grade.label or ('Grade ' .. tostring(getGradeLevel(grade)))
    end

    local jobName = job and job.name or nil
    local shared = jobName and getSharedJob(jobName) or nil
    local gradeData = shared and shared.grades and shared.grades[tostring(grade)] or shared and shared.grades and shared.grades[tonumber(grade or 0)] or nil
    return gradeData and (gradeData.name or gradeData.label) or (grade ~= nil and ('Grade ' .. tostring(grade)) or nil)
end

function fallback.getJobGradePay(source)
    local job = getJobData(source)
    local grade = job and job.grade or nil
    if type(grade) == 'table' then
        return grade.payment or grade.pay or 0
    end

    local jobName = job and job.name or nil
    local shared = jobName and getSharedJob(jobName) or nil
    local gradeData = shared and shared.grades and shared.grades[tostring(grade)] or shared and shared.grades and shared.grades[tonumber(grade or 0)] or nil
    return gradeData and (gradeData.payment or gradeData.pay) or 0
end

function fallback.getJobCount(jobName)
    if not IsDuplicityVersion() or not jobName then return 0 end
    local count = 0
    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        if fallback.getJobName(src) == jobName then
            count = count + 1
        end
    end
    return count
end

function fallback.getJobTypeCount(jobType)
    if not IsDuplicityVersion() or not jobType then return 0 end
    local count = 0
    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        if fallback.getJobType(src) == jobType then
            count = count + 1
        end
    end
    return count
end

function fallback.getIdentifier(source)
    local playerData = getPlayerData(source)
    return playerData and (playerData.citizenid or playerData.citizenId) or nil
end

function fallback.getMetadata(source, key)
    local playerData = getPlayerData(source)
    return getMetadataValue(playerData and playerData.metadata or nil, key)
end

function fallback.getCharInfo(field)
    if IsDuplicityVersion() then return nil end
    local playerData = getClientPlayerData()
    local charinfo = playerData and playerData.charinfo or nil
    if field == nil then
        return charinfo
    end
    return charinfo and charinfo[field] or nil
end

function fallback.getName(source)
    return fallback.getPlayerName(source)
end

function fallback.getPlayerName(source)
    if IsDuplicityVersion() then
        local playerData = getServerPlayerData(source)
        return resolveNameFromData(playerData) or GetPlayerName(source) or 'Unknown'
    end
    return resolveNameFromData(getClientPlayerData()) or GetPlayerName(PlayerId()) or 'Unknown'
end

function fallback.getPlayerByIdentifier(citizenid)
    if not IsDuplicityVersion() then return nil end
    return getPlayerByCitizenId(citizenid)
end

function fallback.getPlayerNameByIdentifier(citizenid)
    local player = getPlayerByCitizenId(citizenid)
    local playerData = normalizePlayerData(player)
    if playerData then
        return resolveNameFromData(playerData) or 'Unknown Person'
    end

    local row = MySQL and MySQL.single and MySQL.single.await and MySQL.single.await('SELECT charinfo FROM players WHERE citizenid = ? LIMIT 1', { citizenid }) or nil
    if row and row.charinfo then
        local ok, charinfo = pcall(json.decode, row.charinfo)
        if ok and type(charinfo) == 'table' then
            local fullname = ((charinfo.firstname or '') .. ' ' .. (charinfo.lastname or '')):gsub('^%s+', ''):gsub('%s+$', '')
            if fullname ~= '' then
                return fullname
            end
        end
    end

    return 'Unknown Person'
end

function fallback.getAllPlayers()
    if not IsDuplicityVersion() then return {} end
    local players = {}
    for _, playerId in ipairs(GetPlayers()) do
        players[#players + 1] = tonumber(playerId)
    end
    return players
end

function fallback.isBoss(source)
    local job = getJobData(source)
    local grade = job and job.grade or nil
    if type(grade) == 'table' then
        return grade.isboss == true or grade.isBoss == true or grade.boss == true
    end

    local shared = job and job.name and getSharedJob(job.name) or nil
    local gradeData = shared and shared.grades and (shared.grades[tostring(grade)] or shared.grades[tonumber(grade or 0)]) or nil
    return gradeData and (gradeData.isboss == true or gradeData.isBoss == true or gradeData.boss == true) or false
end

function fallback.getSharedJob(jobName)
    return getSharedJob(jobName)
end

function fallback.getSharedJobData(jobName)
    return getSharedJob(jobName)
end

function fallback.getSharedJobGrade(jobName, grade)
    local job = getSharedJob(jobName)
    return job and job.grades and (job.grades[tostring(grade)] or job.grades[tonumber(grade or 0)]) or nil
end

function fallback.getSharedJobGradeData(jobName, grade, field)
    local gradeData = fallback.getSharedJobGrade(jobName, grade)
    if field == nil then
        return gradeData
    end
    return gradeData and gradeData[field] or nil
end

function fallback.removeMoney(source, account, amount, reason)
    if not IsDuplicityVersion() then return false end
    local player = getPlayerFromCore(source)
    if not player or not player.Functions or not player.Functions.RemoveMoney then
        return false
    end
    local ok, result = pcall(function()
        return player.Functions.RemoveMoney(account, amount, reason)
    end)
    return ok and result == true
end

function fallback.setJob(source, jobName, grade)
    if not IsDuplicityVersion() then return false end
    local player = getPlayerFromCore(source)
    if not player or not player.Functions or not player.Functions.SetJob then
        return false
    end
    local ok, result = pcall(function()
        return player.Functions.SetJob(jobName, grade)
    end)
    return ok and result ~= false
end

function fallback.addKeybind(options)
    if lib and lib.addKeybind then
        return lib.addKeybind(options)
    end
    fallback.warn('lib.addKeybind unavailable')
    return nil
end

function fallback.requestModel(model)
    return ensureLoadedModel(model)
end

function fallback.requestAnim(dict)
    return ensureLoadedAnim(dict)
end

function fallback.isDead()
    if IsDuplicityVersion() then return false end

    local state = LocalPlayer and LocalPlayer.state or nil
    if state then
        if state.isDead ~= nil then return state.isDead == true end
        if state.dead ~= nil then return state.dead == true end
        if state.laststand ~= nil and state.laststand == true then return true end
    end

    local ped = PlayerPedId()
    return IsEntityDead(ped) or IsPedFatallyInjured(ped)
end

function fallback.auditLog(...)
    fallback.debug('auditLog fallback invoked', ...)
end

function fallback.isActionTracked()
    return true
end

function fallback.getPlayerById(source)
    return fallback.getPlayer(source)
end

local activePs = tryInitPsLib()
if activePs then
    ps = activePs
else
    ps = fallback
    safePrint('INFO', 'ps_lib export unavailable or incompatible; using internal compatibility bootstrap')
end
