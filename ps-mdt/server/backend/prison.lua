local resourceName = tostring(GetCurrentResourceName())
local prisonResource = 'pickle_prisons'

local function trim(value)
    if value == nil then return nil end
    local text = tostring(value):gsub('^%s+', ''):gsub('%s+$', '')
    if text == '' then return nil end
    return text
end

local function isPrisonResourceReady()
    local state = GetResourceState(prisonResource)
    return state == 'started' or state == 'starting'
end

local function hasPrisonPanelAccess(source)
    if not CheckAuth(source) then
        return false
    end

    if Config.OnlyShowOnDuty and ps.getJobDuty and not ps.getJobDuty(source) then
        return false
    end

    if CheckPermission(source, 'reports_create') or CheckPermission(source, 'charges_edit') then
        return true
    end

    local jobName = ps.getJobName(source) or nil
    local jobType = ps.getJobType(source) or nil
    return IsPoliceJob(jobName, jobType)
end

local function getPrisonExports()
    if not isPrisonResourceReady() then
        return nil
    end

    return exports[prisonResource]
end

local function getTargetSourceByCitizenId(citizenid)
    local onlinePlayer = ps.getPlayerByIdentifier(citizenid)
    local playerData = onlinePlayer and (onlinePlayer.PlayerData or onlinePlayer) or nil
    return playerData and (playerData.source or onlinePlayer.source) or nil
end

local function translatePrisonResult(code, fallback)
    local messages = {
        not_found = 'O cidadão não está preso no pickle_prisons',
        offline_release_not_supported = 'A soltura pelo painel exige que o preso esteja online',
        updated = 'Situação prisional atualizada',
        released = 'Preso liberado com sucesso',
    }

    return messages[code] or fallback or 'Ação não executada'
end

local function buildTargetIdentity(citizenid)
    if not citizenid then return nil end

    local onlinePlayer = ps.getPlayerByIdentifier(citizenid)
    local playerData = onlinePlayer and (onlinePlayer.PlayerData or onlinePlayer) or nil
    local charinfo = playerData and playerData.charinfo or {}

    local firstname = charinfo.firstname or 'Desconhecido'
    local lastname = charinfo.lastname or ''
    local fullName = (('%s %s'):format(firstname, lastname)):gsub('^%s+', ''):gsub('%s+$', '')

    local source = playerData and (playerData.source or onlinePlayer.source) or nil
    local status = nil
    local prisonExports = getPrisonExports()
    if prisonExports and prisonExports.GetPrisonStatus then
        local ok, result = pcall(function()
            return prisonExports:GetPrisonStatus(citizenid)
        end)
        if ok and type(result) == 'table' then
            status = result
        end
    end

    if not fullName or fullName == '' then
        fullName = ps.getPlayerNameByIdentifier(citizenid) or citizenid
    end

    return {
        citizenid = citizenid,
        id = citizenid,
        fullName = fullName,
        online = source ~= nil,
        source = source,
        status = status,
    }
end

ps.registerCallback(resourceName .. ':server:getPrisonConfig', function(source)
    local src = source
    if not hasPrisonPanelAccess(src) then
        return { success = false, message = 'Sem permissão para acessar a aba Prisão' }
    end

    local prisonExports = getPrisonExports()
    if not prisonExports then
        return { success = false, message = 'pickle_prisons não está iniciado' }
    end

    local prisons = {}
    local ok, result = pcall(function()
        return prisonExports:GetPrisons()
    end)
    if ok and type(result) == 'table' then
        prisons = result
    end

    return {
        success = true,
        prisons = prisons,
        canManage = true,
    }
end)

ps.registerCallback(resourceName .. ':server:searchPrisonRecords', function(source, query)
    local src = source
    if not hasPrisonPanelAccess(src) then
        return { success = false, message = 'Sem permissão', data = {} }
    end

    local term = trim(query)
    if not term or #term < 2 then
        return { success = true, data = {} }
    end

    if ps.auditLog then
        ps.auditLog(src, 'search_players', 'search', nil, {
            query = term,
            context = 'prison_mdt'
        })
    end

    local likeQuery = ('%%%s%%'):format(term)
    local rows = MySQL.query.await([[
        SELECT
            p.citizenid,
            JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')) as firstname,
            JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname')) as lastname,
            mp.profilepicture
        FROM players p
        LEFT JOIN mdt_profiles mp ON mp.citizenid COLLATE utf8mb4_general_ci = p.citizenid COLLATE utf8mb4_general_ci
        WHERE (
            p.citizenid LIKE ?
            OR JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')) LIKE ?
            OR JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname')) LIKE ?
            OR CONCAT(
                JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')),
                ' ',
                JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname'))
            ) LIKE ?
        )
        LIMIT 25
    ]], { likeQuery, likeQuery, likeQuery, likeQuery })

    local records = {}
    local prisonExports = getPrisonExports()

    for _, row in ipairs(rows or {}) do
        local fullName = (((row.firstname or 'Desconhecido') .. ' ' .. (row.lastname or '')):gsub('^%s+', ''):gsub('%s+$', ''))
        local playerSource = getTargetSourceByCitizenId(row.citizenid)
        local status = nil

        if prisonExports and prisonExports.GetPrisonStatus then
            local okStatus, resultStatus = pcall(function()
                return prisonExports:GetPrisonStatus(row.citizenid)
            end)
            if okStatus and type(resultStatus) == 'table' then
                status = resultStatus
            end
        end

        records[#records + 1] = {
            citizenid = row.citizenid,
            id = row.citizenid,
            fullName = fullName ~= '' and fullName or row.citizenid,
            image = row.profilepicture,
            online = playerSource ~= nil,
            source = playerSource,
            status = status,
        }
    end

    return { success = true, data = records }
end)

ps.registerCallback(resourceName .. ':server:getPrisonStatus', function(source, payload)
    local src = source
    if not hasPrisonPanelAccess(src) then
        return { success = false, message = 'Sem permissão' }
    end

    local citizenid = trim(type(payload) == 'table' and (payload.citizenid or payload.id) or payload)
    if not citizenid then
        return { success = false, message = 'Citizen ID inválido' }
    end

    local prisonExports = getPrisonExports()
    if not prisonExports then
        return { success = false, message = 'pickle_prisons não está iniciado' }
    end

    local ok, status = pcall(function()
        return prisonExports:GetPrisonStatus(citizenid)
    end)
    if not ok or type(status) ~= 'table' then
        return { success = false, message = 'Falha ao consultar situação da prisão' }
    end

    local target = buildTargetIdentity(citizenid)
    return {
        success = true,
        target = target,
        status = status,
    }
end)

ps.registerCallback(resourceName .. ':server:submitPrisonAction', function(source, payload)
    local src = source
    if not hasPrisonPanelAccess(src) then
        return { success = false, message = 'Sem permissão para ações de prisão' }
    end

    local prisonExports = getPrisonExports()
    if not prisonExports then
        return { success = false, message = 'pickle_prisons não está iniciado' }
    end

    payload = type(payload) == 'table' and payload or {}

    local action = trim(payload.action)
    local citizenid = trim(payload.citizenid or payload.id)
    local prisonIndex = trim(payload.prison) or 'default'
    local time = tonumber(payload.time) or 0
    local reason = trim(payload.reason) or 'Sem motivo informado'

    if not action or not citizenid then
        return { success = false, message = 'Ação ou citizenid inválidos' }
    end

    local beforeStatus = nil
    if prisonExports.GetPrisonStatus then
        local okBefore, resultBefore = pcall(function()
            return prisonExports:GetPrisonStatus(citizenid)
        end)
        if okBefore and type(resultBefore) == 'table' then
            beforeStatus = resultBefore
        end
    end

    local success, message, afterStatus = false, 'Ação não executada', nil
    local auditAction = nil
    local targetSource = getTargetSourceByCitizenId(citizenid)

    if action == 'jail' then
        if time <= 0 then
            return { success = false, message = 'Informe um tempo de prisão válido' }
        end

        if beforeStatus and beforeStatus.jailed then
            return { success = false, message = 'Este cidadão já está preso no pickle_prisons' }
        end

        if not targetSource then
            return { success = false, message = 'O alvo precisa estar online para ser preso pelo painel' }
        end

        local okJail, errJail = pcall(function()
            prisonExports:JailPlayer(targetSource, math.floor(time), prisonIndex)
        end)

        if not okJail then
            return { success = false, message = ('Falha ao chamar JailPlayer: %s'):format(tostring(errJail)) }
        end

        success = true
        message = ('%s enviado para %s por %s minuto(s)'):format(ps.getPlayerNameByIdentifier(citizenid), prisonIndex, math.floor(time))
        auditAction = 'sent_to_jail'
    elseif action == 'add_time' then
        if time <= 0 then
            return { success = false, message = 'Informe quantos minutos deseja adicionar' }
        end

        local okAdjust, adjustState, adjustMessage, adjustStatus = pcall(function()
            return prisonExports:AdjustPrisonTimeByIdentifier(citizenid, math.floor(time))
        end)

        if okAdjust and adjustState == true then
            success = true
            message = ('Tempo adicionado: +%s minuto(s)'):format(math.floor(time))
            afterStatus = adjustStatus
            auditAction = 'sent_to_jail'
        else
            message = translatePrisonResult(adjustMessage, 'Não foi possível adicionar tempo ao preso')
        end
    elseif action == 'reduce_time' then
        if time <= 0 then
            return { success = false, message = 'Informe quantos minutos deseja reduzir' }
        end

        local okAdjust, adjustState, adjustMessage, adjustStatus = pcall(function()
            return prisonExports:AdjustPrisonTimeByIdentifier(citizenid, math.floor(time) * -1)
        end)

        if okAdjust and adjustState == true then
            success = true
            message = ('Tempo reduzido: -%s minuto(s)'):format(math.floor(time))
            afterStatus = adjustStatus
            auditAction = 'sent_to_jail'
        else
            message = translatePrisonResult(adjustMessage, 'Não foi possível reduzir tempo do preso')
        end
    elseif action == 'release' then
        local okRelease, releaseState, releaseMessage, releaseStatus = pcall(function()
            return prisonExports:UnjailByIdentifier(citizenid)
        end)

        if okRelease and releaseState == true then
            success = true
            message = 'Preso liberado com sucesso'
            afterStatus = releaseStatus
            auditAction = 'sent_to_jail'
        else
            message = translatePrisonResult(releaseMessage, 'Não foi possível liberar o preso')
        end
    elseif action == 'status' or action == 'refresh' then
        success = true
        message = 'Situação atualizada'
    else
        return { success = false, message = 'Ação de prisão desconhecida' }
    end

    if prisonExports.GetPrisonStatus then
        local okAfter, resultAfter = pcall(function()
            return prisonExports:GetPrisonStatus(citizenid)
        end)
        if okAfter and type(resultAfter) == 'table' then
            afterStatus = resultAfter
        end
    end

    if success and ps.auditLog and auditAction then
        ps.auditLog(src, auditAction, 'citizen', citizenid, {
            context = 'prison_tab',
            prison = prisonIndex,
            reason = reason,
            delta = math.floor(time),
            action = action,
            beforeTime = beforeStatus and beforeStatus.time or nil,
            afterTime = afterStatus and afterStatus.time or nil,
            targetSource = targetSource,
        })
    end

    return {
        success = success,
        message = message,
        target = buildTargetIdentity(citizenid),
        status = afterStatus,
    }
end)
