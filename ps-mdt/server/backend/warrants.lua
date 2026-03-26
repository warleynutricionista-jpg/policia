local resourceName = tostring(GetCurrentResourceName())

local function validateExpiry(expiry)
    if not expiry then
        return nil
    end
    local asNumber = tonumber(expiry)
    if asNumber then
        return asNumber
    end
    if type(expiry) == 'string' then
        local trimmed = expiry:match('^%s*(.-)%s*$')
        if trimmed and trimmed ~= '' then
            return trimmed
        end
    end
    return nil
end

local function toTimestamp(value)
    if not value then
        return nil
    end
    local numeric = tonumber(value)
    if numeric then
        if numeric > 100000000000 then
            return math.floor(numeric / 1000)
        end
        return numeric
    end
    return nil
end

local function getExpiryDate(value)
    local ts = toTimestamp(value)
    if ts then
        return os.date('%Y-%m-%d %H:%M:%S', ts)
    end
    if type(value) == 'string' and value ~= '' then
        return value
    end
    return nil
end

-- Padrões normalizados que identificam documentos do tipo mandado judicial
local WARRANT_TYPE_PATTERNS = {
    'mandado',
    'mandado judicial',
    'mandado de prisao',
    'mandado de busca',
    'mandado de busca e apreensao',
    'mandado de apreensao',
    'mandado de conducao',
    'mandado de internacao',
    'warrant',
    'search warrant',
    'arrest warrant',
}

local function normalizeForComparison(value)
    if not value or value == '' then return '' end
    local s = tostring(value):lower()
    s = s:gsub('^%s+', ''):gsub('%s+$', '')
    -- Remover acentos comuns do português
    s = s:gsub('[áàâã]', 'a')
    s = s:gsub('[éèê]', 'e')
    s = s:gsub('[íìî]', 'i')
    s = s:gsub('[óòôõ]', 'o')
    s = s:gsub('[úùû]', 'u')
    s = s:gsub('[ç]', 'c')
    return s
end

local function isWarrantType(reportType)
    if not reportType or reportType == '' then return false end
    local normalized = normalizeForComparison(reportType)
    for _, pattern in ipairs(WARRANT_TYPE_PATTERNS) do
        if normalized == pattern or normalized:find(pattern, 1, true) then
            return true
        end
    end
    return false
end

ps.registerCallback(resourceName .. ':server:getActiveWarrants', function(source)
    local src = source
    if not CheckAuth(src) then return {} end
    if not CheckPermission(src, 'warrants_view') then return {} end

    -- 1) Mandados explícitos da tabela mdt_reports_warrants (sistema original)
    local rows = MySQL.query.await([[
        SELECT
            w.reportid,
            w.citizenid,
            w.felonies,
            w.misdemeanors,
            w.infractions,
            w.expirydate,
            JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')) AS firstname,
            JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname')) AS lastname
        FROM mdt_reports_warrants w
        LEFT JOIN players p ON p.citizenid COLLATE utf8mb4_general_ci = w.citizenid COLLATE utf8mb4_general_ci
        WHERE w.expirydate >= NOW()
        ORDER BY w.expirydate ASC
    ]])

    local results = {}
    local seenKeys = {}

    for _, row in ipairs(rows or {}) do
        local name = ((row.firstname or '') .. ' ' .. (row.lastname or '')):gsub('^%s+', ''):gsub('%s+$', '')
        if name == '' then
            name = ps.getPlayerNameByIdentifier(row.citizenid) or 'Desconhecido'
        end
        local key = tostring(row.reportid) .. ':' .. tostring(row.citizenid)
        seenKeys[key] = true
        results[#results + 1] = {
            reportid = row.reportid,
            citizenid = row.citizenid,
            name = name,
            felonies = tonumber(row.felonies) or 0,
            misdemeanors = tonumber(row.misdemeanors) or 0,
            infractions = tonumber(row.infractions) or 0,
            expirydate = row.expirydate,
        }
    end

    -- 2) Relatórios do tipo mandado judicial (mdt_reports com type contendo "mandado")
    local reportRows = MySQL.query.await([[
        SELECT
            r.id AS reportid,
            r.type AS report_type,
            r.title,
            r.datecreated,
            ri.citizenid
        FROM mdt_reports r
        LEFT JOIN mdt_reports_involved ri ON ri.reportid = r.id
        WHERE r.report_status NOT IN ('archived')
        ORDER BY r.datecreated DESC
    ]]) or {}

    for _, row in ipairs(reportRows) do
        if isWarrantType(row.report_type) then
            local citizenid = row.citizenid or ''
            local key = tostring(row.reportid) .. ':' .. citizenid
            if not seenKeys[key] then
                seenKeys[key] = true
                local name = 'Desconhecido'
                if citizenid ~= '' then
                    name = ps.getPlayerNameByIdentifier(citizenid) or 'Desconhecido'
                end
                results[#results + 1] = {
                    reportid = row.reportid,
                    citizenid = citizenid,
                    name = name,
                    felonies = 0,
                    misdemeanors = 0,
                    infractions = 0,
                    expirydate = nil,
                    reportTitle = row.title,
                    reportType = row.report_type,
                }
            end
        end
    end

    return results
end)

ps.registerCallback(resourceName .. ':server:issueWarrant', function(source, data)
    local src = source
    if not CheckAuth(src) then return { success = false, error = 'Não autorizado' } end
    if not CheckPermission(src, 'warrants_issue') then return { success = false, error = 'Sem permissão para emitir mandado' } end

    data = data or {}
    local reportId = tonumber(data.reportId)
    local citizenid = data.citizenid
    local expiryValue = validateExpiry(data.expirydate)
    local expiryDate = getExpiryDate(expiryValue)
    if not expiryDate then
        local defaultDays = (Config and Config.Warrants and Config.Warrants.DefaultExpiryDays) or 7
        expiryDate = os.date('%Y-%m-%d %H:%M:%S', os.time() + (defaultDays * 24 * 60 * 60))
    end

    if not reportId or not citizenid then
        return { success = false, error = 'Campos obrigatórios ausentes' }
    end

    local existing = MySQL.single.await('SELECT reportid FROM mdt_reports_warrants WHERE reportid = ? AND citizenid = ?', { reportId, citizenid })
    if existing and existing.reportid then
        return { success = false, error = 'Já existe um mandado ativo para este indivíduo neste relatório' }
    else
        MySQL.insert.await([[
            INSERT INTO mdt_reports_warrants (reportid, citizenid, felonies, misdemeanors, infractions, expirydate)
            VALUES (?, ?, 0, 0, 0, ?)
        ]], { reportId, citizenid, expiryDate })
    end

    if ps.auditLog then
        ps.auditLog(src, 'warrant_issued', 'warrant', reportId, {
            citizenid = citizenid,
            expirydate = expiryDate
        })
    end

    return { success = true }
end)

ps.registerCallback(resourceName .. ':server:closeWarrant', function(source, data)
    local src = source
    if not CheckAuth(src) then return { success = false, error = 'Não autorizado' } end
    if not CheckPermission(src, 'warrants_close') then return { success = false, error = 'Sem permissão para encerrar mandado' } end

    data = data or {}
    local reportId = tonumber(data.reportId)
    local citizenid = data.citizenid
    if not reportId or not citizenid then
        return { success = false, error = 'Campos obrigatórios ausentes' }
    end

    local updated = MySQL.update.await([[
        UPDATE mdt_reports_warrants
        SET expirydate = NOW()
        WHERE reportid = ? AND citizenid = ?
    ]], { reportId, citizenid })

    if updated and updated > 0 then
        if ps.auditLog then
            ps.auditLog(src, 'warrant_closed', 'warrant', reportId, {
                citizenid = citizenid
            })
        end
        return { success = true }
    end

    return { success = false, error = 'Mandado não encontrado' }
end)
