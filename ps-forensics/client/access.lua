-- ============================================================
-- PS-FORENSICS - Access helpers (Client)
-- Fonte única de autenticação/autorização no client.
-- ============================================================

local QBX = nil

local function ensureCore()
    if QBX then return QBX end

    local ok, core = pcall(function()
        return exports['qbx_core']:GetCoreObject()
    end)
    if ok and core then
        QBX = core
        return QBX
    end

    local ok2, core2 = pcall(function()
        return exports['qb-core']:GetCoreObject()
    end)
    if ok2 and core2 then
        QBX = core2
        return QBX
    end

    return nil
end

CreateThread(function()
    ensureCore()
end)

local function getPlayerDataInternal()
    local core = ensureCore()
    if not core then return nil end

    local ok, pd = pcall(function()
        return core.Functions.GetPlayerData()
    end)

    if ok and pd then
        return pd
    end

    return nil
end

local function getPlayerJobInternal()
    local playerData = getPlayerDataInternal()
    if not playerData then return '', 0, '' end

    local job = playerData.job or {}
    local grade = job.grade or {}

    local gradeLevel = tonumber(grade.level)
    if not gradeLevel and type(grade) == 'number' then
        gradeLevel = tonumber(grade)
    end

    local jobType = job.type or ''

    return job.name or '', gradeLevel or 0, grade.name or '', jobType
end

local function hasAccessInternal()
    local jobName = select(1, getPlayerJobInternal())
    return ForensicUtils.IsAuthorizedForensicsJob(jobName)
end

ForensicsAccess = {
    ensureCore = ensureCore,
    getPlayerData = getPlayerDataInternal,
    getPlayerJob = getPlayerJobInternal,
    hasAccess = hasAccessInternal,
}

-- Compatibilidade com código legado que chama funções globais.
function hasAccess()
    return hasAccessInternal()
end

function getPlayerJob()
    return getPlayerJobInternal()
end

function getPlayerData()
    return getPlayerDataInternal()
end
