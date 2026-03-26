--=========================================================
-- qb-activeofficers | server/main.lua  (PT-BR + melhorias)
--=========================================================
-- - Autodetecta e aguarda qb-core / qbx-core iniciar (server)
-- - Banco: oxmysql (DDL idempotente + persistência de cores)
-- - Autorização por job.type == 'leo' ou nomes comuns
-- - Handlers compatíveis com assinaturas QB e Qbox
-- - Sanitização de callsign e failsafes em todos eventos
--=========================================================

--========================[ BOOTSTRAP CORE ]========================--
local CORE_CANDIDATES = { 'qbx-core', 'qb-core' }
local coreName, QBCore

local function TryGetCoreOnce()
    for _, name in ipairs(CORE_CANDIDATES) do
        if GetResourceState(name) == 'started' then
            local ok, obj = pcall(function() return exports[name]:GetCoreObject() end)
            if ok and obj then
                coreName, QBCore = name, obj
                print(("[activeofficers] Core detectado (server): ^2%s^0"):format(coreName))
                return true
            end
        end
    end
    return false
end

local function EnsureCore(timeoutMs)
    local t0 = GetGameTimer()
    while not QBCore do
        if TryGetCoreOnce() then break end
        Wait(200)
        if timeoutMs and (GetGameTimer() - t0) > timeoutMs then break end
    end
    return QBCore ~= nil
end

CreateThread(function()
    if not EnsureCore(10000) then
        print("^1[activeofficers] ERRO:^7 CoreObject (qb-core/qbx-core) não encontrado após aguardo.")
        print("^3Sugestão:^7 ensure oxmysql; ensure qbx-core|qb-core; ensure qb-activeofficers")
    end
end)

-- aborta registro se core não vier em tempo hábil
while not QBCore do
    if not EnsureCore(5000) then
        print("^1[activeofficers]^7 cancelando init por ausência de Core.")
        return
    end
end

--========================[ CONFIG LOCAL ]========================--
-- Jobs permitidos (nomes comuns) — pode editar/expandir
local JOBS_AUTORIZADOS = {
    police=true, lspd=true, sheriff=true, bcso=true, statepolice=true,
    policia=true, prf=true, rota=true, bope=true, civil=true, pmerj=true
}

local function IsJobAutorizado(jobOrName)
    if not jobOrName then return false end
    if type(jobOrName) == 'table' then
        if jobOrName.type and (jobOrName.type == 'leo' or jobOrName.type == 'police') then
            return true
        end
        return JOBS_AUTORIZADOS[jobOrName.name or ''] or false
    else
        return JOBS_AUTORIZADOS[jobOrName] or false
    end
end

--========================[ ESTADO EM MEMÓRIA ]========================--
local activeOfficers = {}   -- [src] = { ... }
local callsignColors = {}   -- tabela persistida em officer_data_colors

--========================[ HELPERS / DB ]========================--
local function Exec(query, params, cb)
    return exports.oxmysql:execute(query, params or {}, cb)
end

local function Fetch(query, params, cb)
    return exports.oxmysql:execute(query, params or {}, cb)
end

local function SanitizeCallsign(s)
    if not s or s == "" then return "NO CALLSIGN" end
    s = tostring(s):gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
    if #s > 24 then s = s:sub(1, 24) end
    return s
end

--========================[ CALLBACKS ]========================--
QBCore.Functions.CreateCallback('qb-activeofficers:server:getActiveOfficers', function(_, cb)
    cb(FormatOfficersList())
end)

QBCore.Functions.CreateCallback('qb-activeofficers:server:getCallsignColors', function(_, cb)
    cb(callsignColors or {})
end)

QBCore.Functions.CreateCallback('qb-activeofficers:server:getCallsign', function(source, cb)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not IsJobAutorizado(Player.PlayerData.job) then
        return cb("NO CALLSIGN", "0", nil, "main", "1B")
    end

    local citizenid  = Player.PlayerData.citizenid
    local gradeLevel = (Player.PlayerData.job.grade and Player.PlayerData.job.grade.level) or 0
    local badge      = tostring(gradeLevel)

    Fetch('SELECT callsign, badge, custom_image, category, channel FROM officer_data WHERE citizenid = ?',
    { citizenid }, function(result)
        local callsign, customImage, category, channel = "NO CALLSIGN", nil, "main", "1B"

        if result and result[1] then
            local row = result[1]
            if row.callsign and row.callsign ~= '' then callsign = row.callsign end
            if row.custom_image ~= nil               then customImage = row.custom_image end
            if row.category     ~= nil               then category    = row.category end
            if row.channel      ~= nil               then channel     = row.channel end
            if tostring(row.badge or '') ~= badge then
                Exec('UPDATE officer_data SET badge = ? WHERE citizenid = ?', { badge, citizenid })
            end
        else
            local metaCallsign = Player.PlayerData.metadata and Player.PlayerData.metadata.callsign
            if metaCallsign and metaCallsign ~= '' then callsign = metaCallsign end
            Exec('INSERT INTO officer_data (citizenid, callsign, badge, custom_image, category, channel) VALUES (?, ?, ?, ?, ?, ?)',
                { citizenid, callsign, badge, nil, category, channel })
        end

        cb(callsign, badge, customImage, category, channel)
    end)
end)

--========================[ EVENTOS: CLIENT -> SERVER ]========================--

-- Salvar/atualizar cores por faixa (comissionado: grade >= 31)
RegisterNetEvent('qb-activeofficers:server:saveCallsignColors', function(colors)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local job = Player.PlayerData.job or {}
    local grade = (job.grade and job.grade.level) or 0
    if IsJobAutorizado(job) and grade >= 31 then
        callsignColors = colors or {}

        Exec([[
            INSERT INTO officer_data_colors (setting_name, setting_value)
            VALUES (?, ?)
            ON DUPLICATE KEY UPDATE setting_value = ?
        ]], { 'callsignColors', json.encode(callsignColors), json.encode(callsignColors) })

        TriggerClientEvent('qb-activeofficers:client:refreshList', -1, FormatOfficersList())
    else
        print(("^3[activeofficers]^7 tentativa não autorizada de salvar cores (src %s)"):format(src))
    end
end)

-- Waypoint para um policial alvo
RegisterNetEvent('qb-activeofficers:server:requestLocation', function(targetServerId)
    local src       = source
    local requester = QBCore.Functions.GetPlayer(src)
    local targetSid = tonumber(targetServerId)
    local target    = targetSid and QBCore.Functions.GetPlayer(targetSid) or nil

    if not requester or not IsJobAutorizado(requester.PlayerData.job) then return end

    if target and IsJobAutorizado(target.PlayerData.job) then
        local playerName = (target.PlayerData.charinfo.firstname or '') .. ' ' .. (target.PlayerData.charinfo.lastname or '')
        local targetPed  = GetPlayerPed(targetSid)
        if targetPed and DoesEntityExist(targetPed) then
            local coords = GetEntityCoords(targetPed)
            TriggerClientEvent('qb-activeofficers:client:receivedLocation', src, { x=coords.x, y=coords.y, z=coords.z }, playerName)
        else
            TriggerClientEvent('qb-activeofficers:client:receivedLocation', src, nil, playerName)
        end
    else
        TriggerClientEvent('qb-activeofficers:client:receivedLocation', src, nil, "Officer")
    end
end)

-- Entrar/sair da lista de ativos conforme duty/job
RegisterNetEvent('qb-activeofficers:server:updateOfficerStatus', function()
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player and IsJobAutorizado(Player.PlayerData.job) then
        UpdateActiveOfficerList(src)
    elseif activeOfficers[src] then
        activeOfficers[src] = nil
        TriggerClientEvent('qb-activeofficers:client:refreshList', -1, FormatOfficersList())
    end
end)

-- Atualizar categoria/canal nominal (ex.: "main"/"1B")
RegisterNetEvent('qb-activeofficers:server:updateCategory', function(category, channel)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not IsJobAutorizado(Player.PlayerData.job) then return end
    if not activeOfficers[src] then UpdateActiveOfficerList(src) end

    local citizenid = Player.PlayerData.citizenid
    local defaultMap = { main='1B', store='2B', fleeca='3B', pacific='4B', jewelry='5B', pursuit='6B', traffic='7B', investigation='8B' }
    channel = channel or defaultMap[category] or '1B'

    Exec('UPDATE officer_data SET category = ?, channel = ? WHERE citizenid = ?', { category, channel, citizenid })

    activeOfficers[src].category = category
    activeOfficers[src].channel  = channel

    TriggerClientEvent('qb-activeofficers:client:updateCategory', src, category, channel)
    TriggerClientEvent('qb-activeofficers:client:refreshList', -1, FormatOfficersList())
end)

-- Atualizar callsign/imagem personalizada
RegisterNetEvent('qb-activeofficers:server:updateSettings', function(callsign, customImage)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not IsJobAutorizado(Player.PlayerData.job) then return end

    local citizenid  = Player.PlayerData.citizenid
    local badge      = tostring((Player.PlayerData.job.grade and Player.PlayerData.job.grade.level) or 0)
    local cleanCall  = SanitizeCallsign(callsign)

    TriggerClientEvent('qb-activeofficers:client:updateLocalCallsign', src, cleanCall)
    TriggerClientEvent('qb-activeofficers:client:updateCustomImage',   src, customImage)

    Fetch('SELECT 1 FROM officer_data WHERE citizenid = ?', { citizenid }, function(result)
        if result and result[1] then
            Exec('UPDATE officer_data SET callsign = ?, badge = ?, custom_image = ? WHERE citizenid = ?',
                { cleanCall, badge, customImage, citizenid })
        else
            Exec('INSERT INTO officer_data (citizenid, callsign, badge, custom_image, category, channel) VALUES (?, ?, ?, ?, ?, ?)',
                { citizenid, cleanCall, badge, customImage, "main", "1B" })
        end

        Player.Functions.SetMetaData('callsign', cleanCall)

        if activeOfficers[src] then
            activeOfficers[src].callsign    = cleanCall
            activeOfficers[src].badge       = badge
            activeOfficers[src].customImage = customImage
        else
            UpdateActiveOfficerList(src)
        end

        TriggerClientEvent('qb-activeofficers:client:refreshList', -1, FormatOfficersList())
    end)
end)

-- Back-compat: atualizar só o callsign
RegisterNetEvent('qb-activeofficers:server:updateCallsign', function(callsign)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not IsJobAutorizado(Player.PlayerData.job) then return end

    local citizenid  = Player.PlayerData.citizenid
    local badge      = tostring((Player.PlayerData.job.grade and Player.PlayerData.job.grade.level) or 0)
    local cleanCall  = SanitizeCallsign(callsign)

    TriggerClientEvent('qb-activeofficers:client:updateLocalCallsign', src, cleanCall)

    Fetch('SELECT 1 FROM officer_data WHERE citizenid = ?', { citizenid }, function(result)
        if result and result[1] then
            Exec('UPDATE officer_data SET callsign = ?, badge = ? WHERE citizenid = ?',
                { cleanCall, badge, citizenid })
        else
            Exec('INSERT INTO officer_data (citizenid, callsign, badge, category, channel) VALUES (?, ?, ?, ?, ?)',
                { citizenid, cleanCall, badge, "main", "1B" })
        end

        Player.Functions.SetMetaData('callsign', cleanCall)

        if activeOfficers[src] then
            activeOfficers[src].callsign = cleanCall
            activeOfficers[src].badge    = badge
        else
            UpdateActiveOfficerList(src)
        end

        TriggerClientEvent('qb-activeofficers:client:refreshList', -1, FormatOfficersList())
    end)
end)

-- Canal de rádio (numérico)
RegisterNetEvent('qb-activeofficers:server:updateRadioChannel', function(channel)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not IsJobAutorizado(Player.PlayerData.job) then return end

    if not activeOfficers[src] then
        return UpdateActiveOfficerList(src, channel)
    end

    local ch = tonumber(channel) or 0
    if ch < 0 then ch = 0 end
    activeOfficers[src].radioChannel = ch

    TriggerClientEvent('qb-activeofficers:client:refreshList', -1, FormatOfficersList())
end)

-- Status (standing/vehicle/aircraft/dead)
RegisterNetEvent('qb-activeofficers:server:updatePlayerStatus', function(status)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not IsJobAutorizado(Player.PlayerData.job) then return end
    if not activeOfficers[src] then return end

    if activeOfficers[src].status ~= status then
        activeOfficers[src].status = status
        TriggerClientEvent('qb-activeofficers:client:refreshList', -1, FormatOfficersList())
    end
end)

-- Talking no rádio (atualização pontual)
RegisterNetEvent('qb-activeofficers:server:updateTalking', function(talking)
    local src = source
    if not activeOfficers[src] then return end
    activeOfficers[src].isTalking = talking and true or false

    for _, ply in pairs(GetPlayers()) do
        TriggerClientEvent('qb-activeofficers:client:updateTalking',
            tonumber(ply), src, activeOfficers[src].isTalking, activeOfficers[src].radioChannel)
    end
end)

--========================[ VIDA ÚTIL / HOOKS ]========================--
AddEventHandler('playerDropped', function()
    local src = source
    if activeOfficers[src] then
        activeOfficers[src] = nil
        TriggerClientEvent('qb-activeofficers:client:refreshList', -1, FormatOfficersList())
    end
end)

-- Handler único para mudança de job (QB e Qbox diferem)
RegisterNetEvent('QBCore:Server:OnJobUpdate', function(a, b)
    local src, newJob
    if type(a) == 'table' and b == nil then
        -- QB: function(JobInfo)
        src, newJob = source, a
    elseif type(a) == 'number' and type(b) == 'table' then
        -- Qbox: function(src, JobInfo)
        src, newJob = a, b
    else
        src = source
        local Ply = QBCore.Functions.GetPlayer(src)
        newJob = Ply and Ply.PlayerData and Ply.PlayerData.job or nil
    end
    if not src or not newJob then return end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if IsJobAutorizado(newJob) then
        local citizenid  = Player.PlayerData.citizenid
        local gradeLevel = (newJob.grade and newJob.grade.level) or 0
        local badge      = tostring(gradeLevel)

        Exec('UPDATE officer_data SET badge = ? WHERE citizenid = ?', { badge, citizenid })

        if activeOfficers[src] then
            activeOfficers[src].badge    = badge
            activeOfficers[src].gradelvl = gradeLevel
            activeOfficers[src].grade    = (newJob.grade and newJob.grade.name) or activeOfficers[src].grade
            activeOfficers[src].onduty   = newJob.onduty and true or false
        else
            UpdateActiveOfficerList(src)
        end
        TriggerClientEvent('qb-activeofficers:client:refreshList', -1, FormatOfficersList())
    else
        if activeOfficers[src] then
            activeOfficers[src] = nil
            TriggerClientEvent('qb-activeofficers:client:refreshList', -1, FormatOfficersList())
        end
    end
end)

-- Alternância de duty
RegisterNetEvent('QBCore:ToggleDuty', function()
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player and IsJobAutorizado(Player.PlayerData.job) then
        Wait(400) -- aguarda core propagar
        UpdateActiveOfficerList(src)
    end
end)

--========================[ BOOTSTRAP / DDL ]========================--
CreateThread(function()
    -- Tabela principal
    Exec([[
        CREATE TABLE IF NOT EXISTS officer_data (
            citizenid    VARCHAR(50)  PRIMARY KEY,
            callsign     VARCHAR(50)  DEFAULT 'NO CALLSIGN',
            badge        VARCHAR(50)  DEFAULT '',
            custom_image VARCHAR(255) DEFAULT NULL,
            category     VARCHAR(50)  DEFAULT 'main',
            channel      VARCHAR(10)  DEFAULT '1B'
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- Garantia de colunas (compatível com MySQL/MariaDB)
    local function EnsureColumn(tableName, columnName, alterSQL)
        Fetch(("SHOW COLUMNS FROM %s LIKE ?"):format(tableName), { columnName }, function(res)
            if not res or not res[1] then Exec(alterSQL) end
        end)
    end
    EnsureColumn('officer_data', 'custom_image', "ALTER TABLE officer_data ADD COLUMN custom_image VARCHAR(255) DEFAULT NULL;")
    EnsureColumn('officer_data', 'category',     "ALTER TABLE officer_data ADD COLUMN category     VARCHAR(50)  DEFAULT 'main';")
    EnsureColumn('officer_data', 'channel',      "ALTER TABLE officer_data ADD COLUMN channel      VARCHAR(10)  DEFAULT '1B';")

    -- Tabela de configurações
    Exec([[
        CREATE TABLE IF NOT EXISTS officer_data_colors (
            setting_name  VARCHAR(50) PRIMARY KEY,
            setting_value TEXT DEFAULT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- Seed / Load callsignColors
    Fetch([[SELECT setting_value FROM officer_data_colors WHERE setting_name = 'callsignColors']], {}, function(res)
        if res and res[1] and res[1].setting_value then
            local ok, decoded = pcall(json.decode, res[1].setting_value)
            callsignColors = ok and (decoded or {}) or {}
        else
            callsignColors = {
                { min = 100, max = 199, color = "#3498db", name = "Patrulha"     },
                { min = 200, max = 299, color = "#2ecc71", name = "Trânsito"     },
                { min = 300, max = 399, color = "#e67e22", name = "Investigação" },
                { min = 400, max = 499, color = "#9b59b6", name = "Comando"      },
            }
            Exec([[
                INSERT INTO officer_data_colors (setting_name, setting_value)
                VALUES (?, ?)
                ON DUPLICATE KEY UPDATE setting_value = ?
            ]], { 'callsignColors', json.encode(callsignColors), json.encode(callsignColors) })
        end
    end)
end)

--========================[ FUNÇÕES INTERNAS ]========================--
function UpdateActiveOfficerList(src, radioChannel)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not IsJobAutorizado(Player.PlayerData.job) then return end

    local pdata      = Player.PlayerData
    local citizenid  = pdata.citizenid
    local gradeLevel = (pdata.job.grade and pdata.job.grade.level) or 0
    local badge      = tostring(gradeLevel)

    Fetch('SELECT callsign, custom_image, category, channel FROM officer_data WHERE citizenid = ?',
    { citizenid }, function(result)
        local callsign, customImage, category, channel = "NO CALLSIGN", nil, "main", "1B"

        if result and result[1] then
            local row = result[1]
            if row.callsign and row.callsign ~= '' then callsign = row.callsign end
            if row.custom_image ~= nil               then customImage = row.custom_image end
            if row.category     ~= nil               then category    = row.category end
            if row.channel      ~= nil               then channel     = row.channel end
            Exec('UPDATE officer_data SET badge = ? WHERE citizenid = ?', { badge, citizenid })
        elseif pdata.metadata and pdata.metadata.callsign and pdata.metadata.callsign ~= '' then
            callsign = pdata.metadata.callsign
            Exec('INSERT INTO officer_data (citizenid, callsign, badge, category, channel) VALUES (?, ?, ?, ?, ?)',
                { citizenid, callsign, badge, category, channel })
        else
            Exec('INSERT INTO officer_data (citizenid, callsign, badge, category, channel) VALUES (?, ?, ?, ?, ?)',
                { citizenid, "NO CALLSIGN", badge, category, channel })
        end

        local prev  = activeOfficers[src]
        local status= (prev and prev.status) or 'standing'
        local radio = tonumber(radioChannel or (prev and prev.radioChannel) or 0) or 0
        if radio < 0 then radio = 0 end

        activeOfficers[src] = {
            source       = src,
            name         = (pdata.charinfo.firstname or '') .. ' ' .. (pdata.charinfo.lastname or ''),
            grade        = (pdata.job.grade and pdata.job.grade.name) or '',
            gradelvl     = gradeLevel,
            callsign     = callsign,
            badge        = badge,
            radioChannel = radio,
            citizenid    = citizenid,
            status       = status,
            customImage  = customImage,
            category     = category,
            channel      = channel,
            isTalking    = false,
            onduty       = pdata.job.onduty and true or false
        }

        TriggerClientEvent('qb-activeofficers:client:refreshList', -1, FormatOfficersList())
    end)
end

function FormatOfficersList()
    local list = {}
    for _, v in pairs(activeOfficers) do list[#list+1] = v end

    table.sort(list, function(a, b)
        local ca, cb = (a.category or ''), (b.category or '')
        if ca == cb then
            local na, nb = tonumber(a.callsign), tonumber(b.callsign)
            if na and nb then
                return na < nb
            elseif na and not nb then
                return true
            elseif not na and nb then
                return false
            else
                return (a.callsign or '') < (b.callsign or '')
            end
        else
            return ca < cb
        end
    end)

    return list
end
