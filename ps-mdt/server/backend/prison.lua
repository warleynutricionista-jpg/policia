local resourceName = tostring(GetCurrentResourceName())

local function trim(value)
    if value == nil then return '' end
    return tostring(value):gsub('^%s+', ''):gsub('%s+$', '')
end

local function hasPrisonAccess(source)
    if not CheckAuth(source) then
        return false
    end

    if Config.OnlyShowOnDuty and ps.getJobDuty and not ps.getJobDuty(source) then
        return false
    end

    return IsPoliceJob(ps.getJobName(source), ps.getJobType(source))
end

local function getOnlinePrisonTargets(query)
    local term = trim(query):lower()
    local results = {}

    for _, playerId in ipairs(GetPlayers()) do
        local targetSource = tonumber(playerId)
        local playerData = ps.getPlayer(targetSource)
        local pd = playerData and (playerData.PlayerData or playerData) or nil
        local citizenid = pd and (pd.citizenid or pd.citizenId) or nil
        local charinfo = pd and pd.charinfo or {}
        local fullName = ((charinfo.firstname or 'Desconhecido') .. ' ' .. (charinfo.lastname or '')):gsub('^%s+', ''):gsub('%s+$', '')
        local injail = ps.getMetadata(targetSource, 'injail') or 0
        local searchable = string.lower(('%s %s'):format(fullName, citizenid or ''))

        if term == '' or searchable:find(term, 1, true) then
            results[#results + 1] = {
                source = targetSource,
                citizenid = citizenid,
                fullName = fullName ~= '' and fullName or ('ID ' .. tostring(targetSource)),
                jailTime = tonumber(injail) or 0,
                status = (tonumber(injail) or 0) > 0 and 'Preso' or 'Livre',
            }
        end
    end

    table.sort(results, function(a, b)
        if a.jailTime ~= b.jailTime then
            return a.jailTime > b.jailTime
        end
        return tostring(a.fullName) < tostring(b.fullName)
    end)

    return results
end

ps.registerCallback(resourceName .. ':server:getPrisonTargets', function(source, query)
    local src = source
    if not hasPrisonAccess(src) then
        return { success = false, message = 'Sem permissão para acessar a aba Prisão', data = {} }
    end

    return {
        success = true,
        data = getOnlinePrisonTargets(query),
    }
end)

ps.registerCallback(resourceName .. ':server:getPrisonTargetStatus', function(source, targetSource)
    local src = source
    if not hasPrisonAccess(src) then
        return { success = false, message = 'Sem permissão para consultar presos' }
    end

    local targetId = tonumber(targetSource)
    if not targetId or not GetPlayerName(targetId) then
        return { success = false, message = 'Jogador não encontrado' }
    end

    local playerData = ps.getPlayer(targetId)
    local pd = playerData and (playerData.PlayerData or playerData) or nil
    local citizenid = pd and (pd.citizenid or pd.citizenId) or nil
    local charinfo = pd and pd.charinfo or {}
    local injail = tonumber(ps.getMetadata(targetId, 'injail') or 0) or 0

    return {
        success = true,
        data = {
            source = targetId,
            citizenid = citizenid,
            fullName = ((charinfo.firstname or 'Desconhecido') .. ' ' .. (charinfo.lastname or '')):gsub('^%s+', ''):gsub('%s+$', ''),
            jailTime = injail,
            status = injail > 0 and 'Preso' or 'Livre',
        }
    }
end)
