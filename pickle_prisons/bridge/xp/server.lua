-- @pickle_prisons/bridge/xp/server.lua
-- À prova de falhas: NUNCA indexa exports diretamente; usa pcall/ wrappers.
-- Fallback em memória se o provider não existir.

if not Config.XPEnabled then return end

local XP_RES = 'pickle_xp'  -- ajuste se seu recurso de XP tiver outro nome

local function providerReady()
    local st = GetResourceState(XP_RES)
    return st == 'started' or st == 'starting'
end

-- Obtém um export com segurança (sem estourar erro “No such export…”)
local function getExport(fnName)
    if not providerReady() then return nil, 'not_ready' end
    local ok, fn = pcall(function()
        return exports[XP_RES][fnName]
    end)
    if not ok or type(fn) ~= 'function' then
        return nil, 'no_export'
    end
    return fn, nil
end

-- Chama um export com segurança
local function callExport(fnName, ...)
    local fn, err = getExport(fnName)
    if not fn then return nil, err end
    local ok, res = pcall(fn, ...)
    if not ok then return nil, res end
    return res, nil
end

-- ===== Fallback em memória (zero DB) =====
local mem = {}  -- [identifier] = { [cat] = xp }

local function pid(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:find('license:') then return id end
    end
    return ('src:%s'):format(src)
end

local function getXP_local(src, cat)
    local id = pid(src); mem[id] = mem[id] or {}
    return mem[id][cat] or 0
end

local function setXP_local(src, cat, val)
    local id = pid(src); mem[id] = mem[id] or {}
    mem[id][cat] = math.max(0, tonumber(val) or 0)
    return mem[id][cat]
end

local function addXP_local(src, cat, amt)
    return setXP_local(src, cat, getXP_local(src, cat) + (tonumber(amt) or 0))
end

local function computeLevelFromXP(xp, def)
    local lvl, need, acc = 1, def.xpStart or 100, 0
    local max = def.maxLevel or 100
    local step = def.xpFactor or 50
    while lvl < max do
        acc = acc + need
        if xp < acc then break end
        lvl = lvl + 1
        need = need + step
    end
    return lvl
end

-- ===== API usada pelo pickle_prisons =====
function AddPlayerXP(source, category, amount)
    -- Tenta provider: AddPlayerXP, senão AddXP; senão fallback
    local ok = callExport('AddPlayerXP', source, category, amount)
    if ok ~= nil then return ok end
    local ok2 = callExport('AddXP', source, category, amount)
    if ok2 ~= nil then return ok2 end
    return addXP_local(source, category, amount)
end

function RemovePlayerXP(source, category, amount)
    local ok = callExport('RemovePlayerXP', source, category, amount)
    if ok ~= nil then return ok end
    local ok2 = callExport('RemoveXP', source, category, amount)
    if ok2 ~= nil then return ok2 end
    return addXP_local(source, category, -(tonumber(amount) or 0))
end

function GetPlayerLevel(source, category)
    -- Se o provider tiver GetPlayerLevel, use-o
    local level = callExport('GetPlayerLevel', source, category)
    if level ~= nil then return level end
    -- Senão, tente GetXP e converta para nível
    local xp = callExport('GetXP', source, category)
    if xp == nil then xp = getXP_local(source, category) end
    local def = Config.XPCategories[category] or {}
    return computeLevelFromXP(tonumber(xp) or 0, def)
end

function GetPlayerXPData(source)
    local data = {}
    for cat, def in pairs(Config.XPCategories) do
        data[cat] = {
            label = def.label or cat,
            level = GetPlayerLevel(source, cat),
        }
    end
    return data
end

-- ===== Registrar categorias (com retry quando o provider iniciar) =====
local function registerAllCategories(silent)
    local fn, err = getExport('RegisterXPCategory')
    if not fn then
        if not silent then
            for cat, _ in pairs(Config.XPCategories) do
                print(('[pickle_prisons] INFO: %s ainda não está pronto (%s); aguardando para registrar "%s"')
                    :format(XP_RES, tostring(err), cat))
            end
        end
        return false
    end

    for cat, def in pairs(Config.XPCategories) do
        local ok = pcall(fn, cat, def.label, def.xpStart, def.xpFactor, def.maxLevel)
        if not ok then
            pcall(fn, cat, {
                label = def.label,
                xpStart = def.xpStart,
                xpFactor = def.xpFactor,
                maxLevel = def.maxLevel
            })
        end
    end
    return true
end

-- 1) tenta já na carga
local okNow = registerAllCategories(true)

-- 2) se não deu, aguarda alguns segundos e tenta de novo silenciosamente
if not okNow then
    CreateThread(function()
        local deadline = GetGameTimer() + 8000 -- até 8s
        while GetGameTimer() < deadline do
            Wait(500)
            if registerAllCategories(true) then
                return
            end
        end
        -- 3) como fallback final, loga uma única vez (sem spam)
        registerAllCategories(false)
    end)
end

-- 4) re-registra imediatamente se o provider subir depois
AddEventHandler('onResourceStart', function(res)
    if res == XP_RES then
        registerAllCategories(true)
    end
end)
