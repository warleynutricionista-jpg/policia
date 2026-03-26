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

local function normalizeText(value)
    local text = tostring(value or ''):lower():gsub('^%s*(.-)%s*$', '%1')
    local accents = {
        ['á']='a',['à']='a',['â']='a',['ã']='a',['ä']='a',
        ['é']='e',['è']='e',['ê']='e',['ë']='e',
        ['í']='i',['ì']='i',['î']='i',['ï']='i',
        ['ó']='o',['ò']='o',['ô']='o',['õ']='o',['ö']='o',
        ['ú']='u',['ù']='u',['û']='u',['ü']='u',
        ['ç']='c'
    }
    text = text:gsub('[%z\1-\127\194-\244][\128-\191]*', function(char)
        return accents[char] or char
    end)
    text = text:gsub('[^%w%s]', ' '):gsub('%s+', ' '):gsub('^%s*(.-)%s*$', '%1')
    return text
end

local function isJudicialWarrantDocument(report)
    local fields = {
        report.type,
        report.title,
        report.tag,
        report.tags,
        report.details,
        report.contentplaintext,
    }

    local normalized = {}
    for _, field in ipairs(fields) do
        local value = normalizeText(field)
        if value ~= '' then
            normalized[#normalized + 1] = value
        end
    end

    local merged = table.concat(normalized, ' ')
    if merged == '' then
        return false
    end

    local keywords = {
        'mandado judicial',
        'mandado de prisao',
        'mandado de busca e apreensao',
        'ordem judicial',
        'warrant',
    }

    for _, keyword in ipairs(keywords) do
        if merged:find(keyword, 1, true) then
            return true
        end
    end

    return merged:find('mandado', 1, true) ~= nil
end

ps.registerCallback(resourceName .. ':server:getActiveWarrants', function(source)
    local src = source
    if not CheckAuth(src) then return {} end
    if not CheckPermission(src, 'warrants_view') then return {} end

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
    local dedupeByReportCitizen = {}
    for _, row in ipairs(rows or {}) do
        local name = ((row.firstname or '') .. ' ' .. (row.lastname or '')):gsub('^%s+', ''):gsub('%s+$', '')
        if name == '' then
            name = ps.getPlayerNameByIdentifier(row.citizenid) or 'Desconhecido'
        end
        local key = ('%s:%s'):format(tostring(row.reportid), tostring(row.citizenid))
        dedupeByReportCitizen[key] = true
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

    local reportRows = MySQL.query.await([[
        SELECT
            r.id AS reportid,
            r.title,
            r.type,
            r.details,
            r.contentplaintext,
            i.citizenid,
            GROUP_CONCAT(DISTINCT t.tag SEPARATOR ' ') AS tags
        FROM mdt_reports r
        LEFT JOIN mdt_reports_involved i ON i.reportid = r.id
        LEFT JOIN mdt_reports_tags t ON t.reportid = r.id
        GROUP BY r.id, i.citizenid
        ORDER BY r.id DESC
        LIMIT 500
    ]]) or {}

    for _, report in ipairs(reportRows) do
        if isJudicialWarrantDocument(report) then
            local citizenid = report.citizenid and tostring(report.citizenid) or 'N/A'
            local key = ('%s:%s'):format(tostring(report.reportid), citizenid)
            if not dedupeByReportCitizen[key] then
                dedupeByReportCitizen[key] = true
                local fullname = ps.getPlayerNameByIdentifier(citizenid) or 'Desconhecido'
                results[#results + 1] = {
                    reportid = tonumber(report.reportid),
                    citizenid = citizenid,
                    name = fullname,
                    felonies = 0,
                    misdemeanors = 0,
                    infractions = 0,
                    expirydate = os.date('%Y-%m-%d %H:%M:%S', os.time() + (7 * 24 * 60 * 60)),
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
