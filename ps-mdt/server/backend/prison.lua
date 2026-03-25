local resourceName = tostring(GetCurrentResourceName())
local prisonResource = 'pickle_prisons'

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

local function getPrisonExport(name)
    if GetResourceState(prisonResource) ~= 'started' then
        return nil
    end

    local ok, fn = pcall(function()
        return exports[prisonResource][name]
    end)

    if ok and fn then
        return fn
    end

    return nil
end

local function getIdentifierFromCitizenId(citizenid)
    if not citizenid then return nil end
    local player = ps.getPlayerByIdentifier(citizenid)
    if player then
        local source = player.source or (player.PlayerData and player.PlayerData.source)
        if source then
            return ps.getIdentifier(tonumber(source)) or citizenid
        end
    end
    return citizenid
end

local function getCitizenProfile(citizenid)
    if not citizenid then return nil end

    local row = MySQL.single.await([[
        SELECT
            p.citizenid,
            JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')) AS firstname,
            JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname')) AS lastname
        FROM players p
        WHERE p.citizenid = ?
        LIMIT 1
    ]], { citizenid })

    if not row then
        return nil
    end

    local fullName = trim((row.firstname or '') .. ' ' .. (row.lastname or ''))
    if fullName == '' then
        fullName = ps.getPlayerNameByIdentifier(citizenid) or 'Desconhecido'
    end

    return {
        citizenid = row.citizenid,
        fullName = fullName,
    }
end

local function getLatestPrisonEvents(citizenid)
    local rows = MySQL.query.await([[
        SELECT action, reason, report_id, case_id, warrant_report_id, applied_by, released_by, changed_by, time_after, created_at
        FROM mdt_prison_history
        WHERE citizenid = ?
        ORDER BY id DESC
        LIMIT 100
    ]], { citizenid }) or {}

    local latestJail, latestRelease
    for _, row in ipairs(rows) do
        if not latestJail and (row.action == 'jail' or row.action == 'jail_from_report' or row.action == 'jail_from_warrant') then
            latestJail = row
        end
        if not latestRelease and row.action == 'unjail' then
            latestRelease = row
        end
        if latestJail and latestRelease then break end
    end

    local timeline = {}
    for i = 1, math.min(25, #rows) do
        local row = rows[i]
        timeline[#timeline + 1] = {
            action = row.action,
            reason = row.reason,
            reportId = tonumber(row.report_id) or nil,
            caseId = tonumber(row.case_id) or nil,
            warrantReportId = tonumber(row.warrant_report_id) or nil,
            appliedBy = row.applied_by,
            releasedBy = row.released_by,
            changedBy = row.changed_by,
            timeAfter = tonumber(row.time_after) or 0,
            createdAt = row.created_at,
        }
    end

    return latestJail, latestRelease, timeline
end

local function fetchCaseIdByReport(reportId)
    if not reportId then return nil end
    return tonumber(MySQL.scalar.await('SELECT case_id FROM mdt_case_reports WHERE report_id = ? ORDER BY case_id DESC LIMIT 1', { reportId })) or nil
end

local function addPrisonHistory(entry)
    if not entry or not entry.citizenid then return end

    MySQL.insert.await([[
        INSERT INTO mdt_prison_history (
            citizenid,
            identifier,
            action,
            reason,
            report_id,
            case_id,
            warrant_report_id,
            time_before,
            time_after,
            applied_by,
            released_by,
            changed_by
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        entry.citizenid,
        entry.identifier,
        entry.action,
        entry.reason,
        entry.reportId,
        entry.caseId,
        entry.warrantReportId,
        entry.timeBefore,
        entry.timeAfter,
        entry.appliedBy,
        entry.releasedBy,
        entry.changedBy,
    })
end

local function getOfficerLabel(source)
    local cid = ps.getIdentifier(source)
    local name = ps.getName and ps.getName(source) or GetPlayerName(source)
    if cid and name then
        return ('%s (%s)'):format(name, cid)
    end
    return name or cid or ('source:' .. tostring(source))
end

local function getOnlinePrisonTargets(query)
    local term = trim(query):lower()
    local results = {}
    local getStatus = getPrisonExport('GetPrisonStatus')

    for _, playerId in ipairs(GetPlayers()) do
        local targetSource = tonumber(playerId)
        local playerData = ps.getPlayer(targetSource)
        local pd = playerData and (playerData.PlayerData or playerData) or nil
        local citizenid = pd and (pd.citizenid or pd.citizenId) or nil
        local charinfo = pd and pd.charinfo or {}
        local fullName = trim((charinfo.firstname or 'Desconhecido') .. ' ' .. (charinfo.lastname or ''))
        local searchable = string.lower(('%s %s'):format(fullName, citizenid or ''))

        if term == '' or searchable:find(term, 1, true) then
            local jailTime = tonumber(ps.getMetadata(targetSource, 'injail') or 0) or 0
            if getStatus and citizenid then
                local ok, prisonStatus = pcall(getStatus, citizenid)
                if ok and type(prisonStatus) == 'table' then
                    jailTime = tonumber(prisonStatus.time) or jailTime
                end
            end

            results[#results + 1] = {
                source = targetSource,
                citizenid = citizenid,
                fullName = fullName ~= '' and fullName or ('ID ' .. tostring(targetSource)),
                jailTime = jailTime,
                status = jailTime > 0 and 'Preso' or 'Livre',
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

local function getPrisonStatusPayload(citizenid, targetSource)
    local identifier = getIdentifierFromCitizenId(citizenid)
    local getStatus = getPrisonExport('GetPrisonStatus')

    local prisonStatus = nil
    if getStatus and identifier then
        local ok, data = pcall(getStatus, identifier)
        if ok and type(data) == 'table' then
            prisonStatus = data
        end
    end

    local jailTime = tonumber(prisonStatus and prisonStatus.time) or tonumber(targetSource and ps.getMetadata(targetSource, 'injail') or 0) or 0
    local status = jailTime > 0 and 'Preso' or 'Livre'
    local latestJail, latestRelease, timeline = getLatestPrisonEvents(citizenid)

    return {
        source = targetSource,
        citizenid = citizenid,
        jailTime = jailTime,
        status = status,
        prison = prisonStatus and prisonStatus.prison,
        prisonLabel = prisonStatus and prisonStatus.prisonLabel,
        sentenceDate = prisonStatus and prisonStatus.sentence_date,
        reason = latestJail and latestJail.reason or nil,
        appliedBy = latestJail and latestJail.applied_by or nil,
        releasedBy = latestRelease and latestRelease.released_by or nil,
        reportId = latestJail and tonumber(latestJail.report_id) or nil,
        caseId = latestJail and tonumber(latestJail.case_id) or nil,
        warrantReportId = latestJail and tonumber(latestJail.warrant_report_id) or nil,
        history = timeline,
    }
end

local function jailCitizen(source, payload)
    if GetResourceState(prisonResource) ~= 'started' then
        return { success = false, message = 'pickle_prisons não está em execução' }
    end

    local citizenid = payload.citizenid
    local sentence = tonumber(payload.sentence)
    local reason = trim(payload.reason)
    local reportId = tonumber(payload.reportId)
    local warrantReportId = tonumber(payload.warrantReportId)
    local caseId = tonumber(payload.caseId) or fetchCaseIdByReport(reportId)

    if not citizenid or not sentence or sentence <= 0 then
        return { success = false, message = 'CitizenID e tempo de prisão são obrigatórios' }
    end

    local targetPlayer = ps.getPlayerByIdentifier(citizenid)
    if not targetPlayer then
        return { success = false, message = 'O cidadão precisa estar online para ser preso' }
    end

    local targetSource = tonumber(targetPlayer.source or (targetPlayer.PlayerData and targetPlayer.PlayerData.source))
    if not targetSource or not GetPlayerName(targetSource) then
        return { success = false, message = 'Jogador alvo não encontrado' }
    end

    local identifier = getIdentifierFromCitizenId(citizenid)
    local currentStatus = getPrisonStatusPayload(citizenid, targetSource)

    local ok, errorMessage = pcall(function()
        exports[prisonResource]:JailPlayer(targetSource, sentence, 'default')
    end)

    if not ok then
        return { success = false, message = ('Falha ao enviar para o pickle_prisons: %s'):format(tostring(errorMessage)) }
    end

    addPrisonHistory({
        citizenid = citizenid,
        identifier = identifier,
        action = payload.action or 'jail',
        reason = reason ~= '' and reason or nil,
        reportId = reportId,
        caseId = caseId,
        warrantReportId = warrantReportId,
        timeBefore = tonumber(currentStatus.jailTime) or 0,
        timeAfter = sentence,
        appliedBy = getOfficerLabel(source),
        changedBy = getOfficerLabel(source),
    })

    TriggerEvent('ps-forensics:server:seedProfilesFromPrison', {
        citizenid = citizenid,
        actor_citizenid = ps.getIdentifier(source),
        reason = reason ~= '' and reason or 'Prisão registrada no MDT',
    })

    local newStatus = getPrisonStatusPayload(citizenid, targetSource)
    return {
        success = true,
        message = 'Prisão aplicada via pickle_prisons',
        data = newStatus,
    }
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

    if not citizenid then
        return { success = false, message = 'CitizenID não encontrado para o alvo selecionado' }
    end

    local profile = getPrisonStatusPayload(citizenid, targetId)
    profile.fullName = trim((charinfo.firstname or 'Desconhecido') .. ' ' .. (charinfo.lastname or ''))

    return { success = true, data = profile }
end)

ps.registerCallback(resourceName .. ':server:getPrisonStatusByCitizen', function(source, citizenid)
    local src = source
    if not hasPrisonAccess(src) then
        return { success = false, message = 'Sem permissão para consultar presos' }
    end

    citizenid = trim(citizenid)
    if citizenid == '' then
        return { success = false, message = 'CitizenID inválido' }
    end

    local profile = getCitizenProfile(citizenid)
    if not profile then
        return { success = false, message = 'Cidadão não encontrado' }
    end

    local targetPlayer = ps.getPlayerByIdentifier(citizenid)
    local targetSource = targetPlayer and tonumber(targetPlayer.source or (targetPlayer.PlayerData and targetPlayer.PlayerData.source)) or nil
    local prisonData = getPrisonStatusPayload(citizenid, targetSource)

    return {
        success = true,
        data = {
            fullName = profile.fullName,
            source = targetSource,
            citizenid = citizenid,
            status = prisonData.status,
            jailTime = prisonData.jailTime,
            reason = prisonData.reason,
            appliedBy = prisonData.appliedBy,
            releasedBy = prisonData.releasedBy,
            reportId = prisonData.reportId,
            caseId = prisonData.caseId,
            warrantReportId = prisonData.warrantReportId,
            prison = prisonData.prison,
            prisonLabel = prisonData.prisonLabel,
            sentenceDate = prisonData.sentenceDate,
            history = prisonData.history,
        }
    }
end)

ps.registerCallback(resourceName .. ':server:prisonTabJail', function(source, payload)
    local src = source
    if not hasPrisonAccess(src) then
        return { success = false, message = 'Sem permissão para prender' }
    end

    payload = payload or {}
    local targetSource = tonumber(payload.source)
    if not targetSource or not GetPlayerName(targetSource) then
        return { success = false, message = 'Alvo inválido' }
    end

    local playerData = ps.getPlayer(targetSource)
    local pd = playerData and (playerData.PlayerData or playerData) or nil
    local citizenid = pd and (pd.citizenid or pd.citizenId) or nil

    if not citizenid then
        return { success = false, message = 'CitizenID do alvo não encontrado' }
    end

    return jailCitizen(src, {
        citizenid = citizenid,
        sentence = payload.sentence,
        reason = payload.reason,
        action = 'jail',
    })
end)

ps.registerCallback(resourceName .. ':server:prisonTabUnjail', function(source, payload)
    local src = source
    if not hasPrisonAccess(src) then
        return { success = false, message = 'Sem permissão para soltar' }
    end

    payload = payload or {}
    local targetSource = tonumber(payload.source)
    if not targetSource or not GetPlayerName(targetSource) then
        return { success = false, message = 'Alvo inválido' }
    end

    local playerData = ps.getPlayer(targetSource)
    local pd = playerData and (playerData.PlayerData or playerData) or nil
    local citizenid = pd and (pd.citizenid or pd.citizenId) or nil

    if not citizenid then
        return { success = false, message = 'CitizenID do alvo não encontrado' }
    end

    local identifier = getIdentifierFromCitizenId(citizenid)
    local currentStatus = getPrisonStatusPayload(citizenid, targetSource)
    local unjailByIdentifier = getPrisonExport('UnjailByIdentifier')

    if not unjailByIdentifier then
        return { success = false, message = 'Export UnjailByIdentifier não disponível no pickle_prisons' }
    end

    local ok, success, actionResult = pcall(unjailByIdentifier, identifier)
    if not ok or success ~= true then
        local message = actionResult == 'offline_release_not_supported' and 'Soltura offline não suportada pelo pickle_prisons' or 'Falha ao soltar preso'
        return { success = false, message = message }
    end

    addPrisonHistory({
        citizenid = citizenid,
        identifier = identifier,
        action = 'unjail',
        reason = trim(payload.reason),
        timeBefore = tonumber(currentStatus.jailTime) or 0,
        timeAfter = 0,
        releasedBy = getOfficerLabel(src),
        changedBy = getOfficerLabel(src),
    })

    local newStatus = getPrisonStatusPayload(citizenid, targetSource)
    return { success = true, message = 'Preso solto via pickle_prisons', data = newStatus }
end)

ps.registerCallback(resourceName .. ':server:prisonFromReport', function(source, payload)
    local src = source
    if not hasPrisonAccess(src) then
        return { success = false, message = 'Sem permissão para prender a partir de relatório' }
    end

    payload = payload or {}
    local reportId = tonumber(payload.reportId)
    local citizenid = trim(payload.citizenid)

    if not reportId or citizenid == '' then
        return { success = false, message = 'Informe reportId e citizenid' }
    end

    local reportExists = MySQL.scalar.await('SELECT id FROM mdt_reports WHERE id = ? LIMIT 1', { reportId })
    if not reportExists then
        return { success = false, message = 'Relatório não encontrado' }
    end

    return jailCitizen(src, {
        citizenid = citizenid,
        sentence = payload.sentence,
        reason = payload.reason,
        reportId = reportId,
        caseId = fetchCaseIdByReport(reportId),
        action = 'jail_from_report',
    })
end)

ps.registerCallback(resourceName .. ':server:prisonFromWarrant', function(source, payload)
    local src = source
    if not hasPrisonAccess(src) then
        return { success = false, message = 'Sem permissão para prender a partir de mandado' }
    end

    payload = payload or {}
    local reportId = tonumber(payload.reportId)
    local citizenid = trim(payload.citizenid)

    if not reportId or citizenid == '' then
        return { success = false, message = 'Informe reportId e citizenid' }
    end

    local warrant = MySQL.single.await([[
        SELECT reportid
        FROM mdt_reports_warrants
        WHERE reportid = ?
            AND citizenid = ?
            AND expirydate >= NOW()
        LIMIT 1
    ]], { reportId, citizenid })

    if not warrant then
        return { success = false, message = 'Não existe mandado ativo para este cidadão neste relatório' }
    end

    return jailCitizen(src, {
        citizenid = citizenid,
        sentence = payload.sentence,
        reason = payload.reason,
        reportId = reportId,
        warrantReportId = reportId,
        caseId = fetchCaseIdByReport(reportId),
        action = 'jail_from_warrant',
    })
end)
