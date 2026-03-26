--=========================================================
-- qb-activeofficers | client/main.lua  (PT-BR + melhorias)
--=========================================================
-- - Autodetecta qb-core / qbx-core e espera o Core ficar pronto
-- - Autorização por lista de jobs + fallback por job.type == 'leo'
-- - NUI callbacks protegidos contra QBCore nil (espera bootstrap)
-- - Integração com qb-voice / pma-voice (métodos alternativos)
-- - KVPs para posições/visibilidade; traduções e notificações
--=========================================================

--========================[ BOOTSTRAP CORE ]========================--
local CORE_CANDIDATES = { 'qbx-core', 'qbx_core', 'qb-core' }
local QBCore

local function TryGetCoreOnce()
    for _, name in ipairs(CORE_CANDIDATES) do
        local ok, obj = pcall(function() return exports[name]:GetCoreObject() end)
        if ok and obj then
            QBCore = obj
            print(('[activeofficers] Core detectado (client): ^2%s^0'):format(name))
            return QBCore
        end
    end
    return nil
end

local function EnsureCore(timeoutMs)
    local t0 = GetGameTimer()
    while not QBCore do
        TryGetCoreOnce()
        if QBCore then break end
        Wait(200)
        if timeoutMs and (GetGameTimer() - t0) > timeoutMs then break end
    end
    return QBCore
end

CreateThread(function()
    EnsureCore(8000) -- tenta por até 8s no boot (depois continuamos tentando sob demanda)
    if not QBCore then
        print('^3[activeofficers]^7 aguardando qb/qbx-core iniciar (client)...')
    end
end)

--========================[ CONFIG LOCAL ]========================--
-- Jobs autorizados (nomes comuns em várias bases). Você pode editar.
local JOBS_AUTORIZADOS = {
    police=true, lspd=true, sheriff=true, bcso=true, statepolice=true,
    policia=true, prf=true, rota=true, bope=true, civil=true, pmerj=true
}

-- Tecla padrão se não vier de Config.SettingsPanelKey
local DEFAULT_SETTINGS_KEY = 'F11'

--========================[ ESTADO ]========================--
local PlayerData, PlayerJob = {}, {}
local policiaisAtivos = {}

local painelConfiguracoesAberto = false
local listaPoliciaisVisivel = false

local indicativoAtual = "SEM INDICATIVO"
local badgeAtual = "0"
local imagemPersonalizada = nil
local categoriaAtual = "main"
local canalAtualNome = "1B"

local meuServerId = nil
local ultimoStatusJogador = "standing"
local estouFalando = false
local canalRadio = 0

-- anti-spam NUI
local ultimoEnvioUI = 0
local INTERVALO_UI_MS = 120

--===================[ CATEGORIAS / CANAIS ]===================--
local categoriaParaCanalNome = {
    main="1B", store="2B", fleeca="3B", pacific="4B",
    jewelry="5B", pursuit="6B", traffic="7B", investigation="8B"
}
local canalNumeroParaCategoria = {
    [1]="main",[2]="store",[3]="fleeca",[4]="pacific",
    [5]="jewelry",[6]="pursuit",[7]="traffic",[8]="investigation"
}

--========================[ UTILS ]========================--
local function L(key, ...)
    local dict = {
        nao_autorizado       = "Você não tem autorização para usar este recurso.",
        lista_visivel        = "Lista de policiais agora está visível.",
        lista_oculta         = "Lista de policiais agora está oculta.",
        waypoint_definido    = "Waypoint definido para %s.",
        waypoint_falhou      = "Não foi possível localizar o policial.",
        indicativo_invalido  = "Informe um indicativo válido.",
        configuracoes_ok     = "Configurações atualizadas com sucesso!",
        categoria_ok         = "Categoria/rádio definida para: %s.",
        salvou_cores         = "Cores do indicativo salvas!",
        abriu_painel         = "Abrindo painel de policiais ativos...",
        fechou_painel        = "Fechando painel...",
    }
    local msg = dict[key] or key
    if select('#', ...) > 0 then msg = msg:format(...) end
    return msg
end

local function Notificar(msg, tipo)
    if EnsureCore() and QBCore.Functions and QBCore.Functions.Notify then
        QBCore.Functions.Notify(msg, tipo or 'inform')
    else
        print(('[activeofficers] %s'):format(msg))
    end
end

local function IsJobAutorizado(job)
    if not job then return false end
    if job.type and (job.type == 'leo' or job.type == 'police') then return true end
    return JOBS_AUTORIZADOS[job.name or ''] or false
end

local function NUISend(payload)
    local now = GetGameTimer()
    if (now - ultimoEnvioUI) < INTERVALO_UI_MS then Wait(INTERVALO_UI_MS) end
    ultimoEnvioUI = GetGameTimer()
    SendNUIMessage(payload)
end

--========================[ COMANDO/PAINEL ]========================--
RegisterCommand('officersettings', function()
    EnsureCore()
    if not IsJobAutorizado(PlayerJob) then
        return Notificar(L('nao_autorizado'), 'error')
    end
    BuscarPoliciaisAtivos()
    AlternarPainelConfiguracoes()
end)

function AlternarPainelConfiguracoes()
    EnsureCore()
    painelConfiguracoesAberto = not painelConfiguracoesAberto

    if painelConfiguracoesAberto then
        SetNuiFocus(true, true)
        pcall(SetNuiFocusKeepInput, false)

        QBCore.Functions.TriggerCallback('qb-activeofficers:server:getCallsign', function(_indicativo, _badge, _imgUrl, _categoria, _canalNome)
            indicativoAtual     = _indicativo or indicativoAtual
            badgeAtual          = _badge or badgeAtual
            imagemPersonalizada = _imgUrl or imagemPersonalizada
            categoriaAtual      = _categoria or "main"
            canalAtualNome      = _canalNome or categoriaParaCanalNome[categoriaAtual] or "1B"
            meuServerId         = GetPlayerServerId(PlayerId())

            local isCommissioner = (PlayerJob and PlayerJob.grade and tonumber(PlayerJob.grade.level) or 0) >= 31

            NUISend({
                action            = "openActiveOfficersPanel",
                officers          = policiaisAtivos,
                currentCallsign   = indicativoAtual,
                currentBadge      = badgeAtual,
                customImageUrl    = imagemPersonalizada,
                currentCategory   = categoriaAtual,
                currentChannel    = canalAtualNome,
                listVisible       = listaPoliciaisVisivel,
                myServerId        = meuServerId,
                isCommissioner    = isCommissioner
            })
            Notificar(L('abriu_painel'), 'inform')
        end)
    else
        SetNuiFocus(false, false)
        pcall(SetNuiFocusKeepInput, false)
        NUISend({ action = "closeActiveOfficersPanel" })
        Notificar(L('fechou_painel'), 'inform')
    end
end

--====================[ LISTA DE POLICIAIS ]====================--
function AlternarListaPoliciais()
    listaPoliciaisVisivel = not listaPoliciaisVisivel
    SetResourceKvpInt('activeofficers_list_visible', listaPoliciaisVisivel and 1 or 0)
    BuscarPoliciaisAtivos()

    NUISend({
        action    = "toggleOfficersList",
        visible   = listaPoliciaisVisivel,
        officers  = policiaisAtivos,
        myServerId= meuServerId
    })
    Notificar(listaPoliciaisVisivel and L('lista_visivel') or L('lista_oculta'),
              listaPoliciaisVisivel and 'success' or 'error')
end

RegisterNetEvent('qb-activeofficers:client:refreshList', function(lista)
    policiaisAtivos = lista or {}
    if painelConfiguracoesAberto then
        NUISend({ action="refreshOfficers", officers=policiaisAtivos, myServerId=meuServerId, noReload=true })
    end
    if listaPoliciaisVisivel then
        NUISend({ action="refreshOfficersList", officers=policiaisAtivos, myServerId=meuServerId, noReload=true })
    end
end)

RegisterNetEvent('qb-activeofficers:client:updateLocalCallsign', function(novoIndicativo)
    indicativoAtual = novoIndicativo or indicativoAtual
    if painelConfiguracoesAberto then
        NUISend({ action="updateLocalCallsign", callsign=indicativoAtual })
    end
    local sid = GetPlayerServerId(PlayerId())
    for _, ofc in ipairs(policiaisAtivos) do
        if ofc.source == sid then ofc.callsign = indicativoAtual break end
    end
    if listaPoliciaisVisivel then
        NUISend({ action="updateOfficerData", officers=policiaisAtivos, myServerId=sid, updatedFields={ callsign=true } })
    end
end)

RegisterNetEvent('qb-activeofficers:client:updateCustomImage', function(url)
    imagemPersonalizada = url or imagemPersonalizada
    if painelConfiguracoesAberto then
        NUISend({ action="updateCustomImage", imageUrl=imagemPersonalizada })
    end
    local sid = GetPlayerServerId(PlayerId())
    for _, ofc in ipairs(policiaisAtivos) do
        if ofc.source == sid then ofc.customImage = imagemPersonalizada break end
    end
    if listaPoliciaisVisivel then
        NUISend({ action="updateOfficerData", officers=policiaisAtivos, myServerId=sid, updatedFields={ customImage=true } })
    end
end)

RegisterNetEvent('qb-activeofficers:client:updateCategory', function(cat, chNome)
    categoriaAtual = cat or "main"
    canalAtualNome = chNome or categoriaParaCanalNome[categoriaAtual] or "1B"
    if painelConfiguracoesAberto then
        NUISend({ action="updateCategory", category=categoriaAtual, channel=canalAtualNome, officers=policiaisAtivos })
    end
    local sid = GetPlayerServerId(PlayerId())
    for _, ofc in ipairs(policiaisAtivos) do
        if ofc.source == sid then
            ofc.category = categoriaAtual
            ofc.channel  = canalAtualNome
            break
        end
    end
    if listaPoliciaisVisivel then
        NUISend({ action="updateOfficerData", officers=policiaisAtivos, myServerId=sid, updatedFields={ category=true } })
    end
end)

function BuscarPoliciaisAtivos()
    EnsureCore()
    QBCore.Functions.TriggerCallback('qb-activeofficers:server:getActiveOfficers', function(ofc)
        policiaisAtivos = ofc or {}
    end)
end

--====================[ CICLO DE VIDA DO PLAYER ]====================--
local function OnFullyLoaded()
    EnsureCore()
    local pdata = QBCore.Functions.GetPlayerData()
    PlayerData = pdata or {}
    PlayerJob  = pdata and pdata.job or {}
    meuServerId= GetPlayerServerId(PlayerId())

    if IsJobAutorizado(PlayerJob) then
        TriggerServerEvent('qb-activeofficers:server:updateOfficerStatus')
        IniciarMonitorStatus()
        IniciarMonitorVoz()

        SetTimeout(900, function()
            listaPoliciaisVisivel = (GetResourceKvpInt('activeofficers_list_visible') == 1)
            if listaPoliciaisVisivel then
                BuscarPoliciaisAtivos()
                Wait(200)
                NUISend({ action="toggleOfficersList", visible=true, officers=policiaisAtivos, myServerId=meuServerId })
            end
        end)
    end
end

AddEventHandler('QBCore:Client:OnPlayerLoaded', OnFullyLoaded)
-- fallback (algumas bases disparam SetPlayerData antes):
AddEventHandler('QBCore:Player:SetPlayerData', function(data)
    PlayerData = data or PlayerData
    if data and data.job then
        local before = PlayerJob
        PlayerJob = data.job
        if (not before) or (before.onduty ~= PlayerJob.onduty) then
            if IsJobAutorizado(PlayerJob) then
                TriggerServerEvent('qb-activeofficers:server:updateOfficerStatus')
            end
        end
    end
end)
-- fallback geral
AddEventHandler('onClientResourceStart', function(res)
    if res == GetCurrentResourceName() then
        CreateThread(function()
            EnsureCore()
            Wait(1000)
            if QBCore then OnFullyLoaded() end
        end)
    end
end)

AddEventHandler('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo or {}
    if IsJobAutorizado(PlayerJob) then
        TriggerServerEvent('qb-activeofficers:server:updateOfficerStatus')
        IniciarMonitorStatus()
        IniciarMonitorVoz()
    else
        if painelConfiguracoesAberto then AlternarPainelConfiguracoes() end
        if listaPoliciaisVisivel then
            listaPoliciaisVisivel = false
            SetResourceKvpInt('activeofficers_list_visible', 0)
            NUISend({ action="toggleOfficersList", visible=false })
        end
    end
end)

--====================[ WAYPOINTS ]====================--
local function HandleLocationClick(serverId)
    TriggerServerEvent('qb-activeofficers:server:requestLocation', serverId)
end

RegisterNUICallback('setWaypoint', function(data, cb)
    local sid = data and data.serverId
    if sid then
        HandleLocationClick(sid)
        local nomeAlvo = "Policial"
        for _, ofc in ipairs(policiaisAtivos) do
            if ofc.source == sid then nomeAlvo = ofc.name or nomeAlvo break end
        end
        if cb then cb({ success=true, officerName=nomeAlvo }) end
    else
        if cb then cb({ success=false }) end
    end
end)

RegisterNetEvent('qb-activeofficers:client:receivedLocation', function(coords, playerName)
    if coords and coords.x and coords.y then
        SetNewWaypoint(coords.x + 0.0, coords.y + 0.0)
        Notificar(L('waypoint_definido', playerName or "Policial"), 'success')
    else
        Notificar(L('waypoint_falhou'), 'error')
    end
end)

--====================[ RÁDIO / VOZ ]====================--
local function ObterCanalRadioSeguro()
    local canal = 0

    -- variáveis globais / estado local
    if _G.RadioChannel and tonumber(_G.RadioChannel) then
        canal = tonumber(_G.RadioChannel)
    end
    if canal == 0 then
        local st = LocalPlayer and LocalPlayer.state and LocalPlayer.state.radioChannel
        if st and tonumber(st) then canal = tonumber(st) end
    end

    -- qb-voice
    if canal == 0 then
        local ok, res = pcall(function()
            if rawget(exports, 'qb-voice') and exports['qb-voice'].getRadioChannel then
                return exports['qb-voice']:getRadioChannel()
            end
            return 0
        end)
        if ok and tonumber(res) then canal = tonumber(res) end
    end

    -- pma-voice
    if canal == 0 then
        local ok, res = pcall(function()
            if rawget(exports, 'pma-voice') and exports['pma-voice'].getRadioChannel then
                return exports['pma-voice']:getRadioChannel()
            end
            return 0
        end)
        if ok and tonumber(res) then canal = tonumber(res) end
    end

    if canal < 0 then canal = 0 end
    return canal
end

CreateThread(function()
    while true do
        Wait(500)
        if IsJobAutorizado(PlayerJob) then
            local atual = ObterCanalRadioSeguro()
            if atual ~= canalRadio then
                if atual > 0 then
                    canalRadio = atual
                    TriggerServerEvent('qb-activeofficers:server:updateRadioChannel', canalRadio)
                    if canalNumeroParaCategoria[canalRadio] then
                        TriggerServerEvent('qb-activeofficers:server:updateCategory', canalNumeroParaCategoria[canalRadio], tostring(canalRadio) .. "B")
                    end
                else
                    if canalRadio > 0 then
                        canalRadio = 0
                        TriggerServerEvent('qb-activeofficers:server:updateRadioChannel', 0)
                    end
                end
            end
        end
    end
end)

RegisterNetEvent('pma-voice:radioActive', function(ativo)
    if IsJobAutorizado(PlayerJob) and ativo then
        SetTimeout(120, function()
            local canal = ObterCanalRadioSeguro()
            if canal > 0 and canal ~= canalRadio then
                canalRadio = canal
                TriggerServerEvent('qb-activeofficers:server:updateRadioChannel', canal)
            end
        end)
    end
end)

RegisterNetEvent('pma-voice:setTalkingOnRadio', function(_talking)
    if IsJobAutorizado(PlayerJob) then
        SetTimeout(120, function()
            local canal = ObterCanalRadioSeguro()
            if canal > 0 and canal ~= canalRadio then
                canalRadio = canal
                TriggerServerEvent('qb-activeofficers:server:updateRadioChannel', canal)
            end
        end)
    end
end)

RegisterNetEvent('qb-voice:clSetPlayerRadio', function(novoCanal)
    if IsJobAutorizado(PlayerJob) and tonumber(novoCanal) then
        canalRadio = tonumber(novoCanal)
        TriggerServerEvent('qb-activeofficers:server:updateRadioChannel', canalRadio)
        if canalRadio > 0 and canalNumeroParaCategoria[canalRadio] then
            local novaCat = canalNumeroParaCategoria[canalRadio]
            local nomeCanal = tostring(canalRadio) .. "B"
            TriggerServerEvent('qb-activeofficers:server:updateCategory', novaCat, nomeCanal)
        end
    end
end)

RegisterNetEvent('qb-voice:radioChannel', function(canal)
    if IsJobAutorizado(PlayerJob) and tonumber(canal) then
        canalRadio = tonumber(canal)
        TriggerServerEvent('qb-activeofficers:server:updateRadioChannel', canalRadio)
    end
end)

--====================[ MONITORES ]====================--
function IniciarMonitorStatus()
    CreateThread(function()
        while IsJobAutorizado(PlayerJob) do
            local ped = PlayerPedId()
            local status = "standing"

            if IsEntityDead(ped) or (PlayerData and PlayerData.metadata and (PlayerData.metadata.isdead or PlayerData.metadata.inlaststand)) then
                status = "dead"
            elseif IsPedInAnyVehicle(ped, false) then
                local veh = GetVehiclePedIsIn(ped, false)
                if veh and DoesEntityExist(veh) then
                    local model = GetEntityModel(veh)
                    if IsThisModelAPlane(model) or IsThisModelAHeli(model) then
                        status = "aircraft"
                    else
                        status = "vehicle"
                    end
                end
            end

            if status ~= ultimoStatusJogador then
                ultimoStatusJogador = status
                TriggerServerEvent('qb-activeofficers:server:updatePlayerStatus', status)
            end

            Wait(1000)
        end
    end)
end

function IniciarMonitorVoz()
    CreateThread(function()
        while IsJobAutorizado(PlayerJob) do
            local falandoAgora = MumbleIsPlayerTalking(PlayerId()) -- bool
            if falandoAgora ~= estouFalando then
                estouFalando = falandoAgora

                NUISend({ action="updateTalking", serverId=meuServerId, isTalking=estouFalando, radioChannel=canalRadio })
                TriggerServerEvent('qb-activeofficers:server:updateTalking', estouFalando)

                if estouFalando and canalRadio == 0 then
                    local c = ObterCanalRadioSeguro()
                    if c > 0 then
                        canalRadio = c
                        TriggerServerEvent('qb-activeofficers:server:updateRadioChannel', canalRadio)
                    end
                end
            end
            Wait(220)
        end
    end)

    -- watchdog para “falando” travado
    CreateThread(function()
        while IsJobAutorizado(PlayerJob) do
            Wait(3000)
            if estouFalando and (not MumbleIsPlayerTalking(PlayerId())) then
                estouFalando = false
                NUISend({ action="updateTalking", serverId=meuServerId, isTalking=false, radioChannel=canalRadio })
                TriggerServerEvent('qb-activeofficers:server:updateTalking', false)
            end
        end
    end)
end

RegisterNetEvent('qb-activeofficers:client:updateTalking', function(serverId, isTalking)
    NUISend({ action="updateTalking", serverId=serverId, isTalking = (isTalking and true or false) })
end)

--====================[ NUI CALLBACKS ]====================--
RegisterNUICallback('closePanel', function(_, cb)
    painelConfiguracoesAberto = false
    SetNuiFocus(false, false)
    pcall(SetNuiFocusKeepInput, false)
    if cb then cb('ok') end
end)

RegisterNUICallback('savePosition', function(data, cb)
    if data and data.type == 'panel' then
        SetResourceKvp('activeofficers_panel_position', json.encode({ x=data.x, y=data.y }))
    elseif data and data.type == 'list' then
        SetResourceKvp('activeofficers_list_position', json.encode({ x=data.x, y=data.y }))
    end
    if cb then cb('ok') end
end)

RegisterNUICallback('getPosition', function(data, cb)
    local pos
    if data and data.type == 'panel' then
        pos = json.decode(GetResourceKvpString('activeofficers_panel_position') or '{"x":20,"y":20}')
    elseif data and data.type == 'list' then
        pos = json.decode(GetResourceKvpString('activeofficers_list_position') or '{"x":20,"y":20}')
    end
    cb(pos or { x=20, y=20 })
end)

RegisterNUICallback('toggleOfficersList', function(data, cb)
    listaPoliciaisVisivel = data and data.visible or false
    SetResourceKvpInt('activeofficers_list_visible', listaPoliciaisVisivel and 1 or 0)
    BuscarPoliciaisAtivos()
    Wait(100)
    NUISend({ action="toggleOfficersList", visible=listaPoliciaisVisivel, officers=policiaisAtivos, myServerId=meuServerId })
    if cb then cb('ok') end
end)

RegisterNUICallback('updateSettings', function(data, cb)
    if data and data.callsign and data.callsign ~= '' then
        indicativoAtual     = data.callsign
        imagemPersonalizada = data.customImage
        TriggerServerEvent('qb-activeofficers:server:updateSettings', indicativoAtual, imagemPersonalizada)
        Notificar(L('configuracoes_ok'), 'success')
    else
        Notificar(L('indicativo_invalido'), 'error')
    end
    if cb then cb('ok') end
end)

RegisterNUICallback('updateCategory', function(data, cb)
    if data and data.category then
        categoriaAtual = data.category
        canalAtualNome = data.channel or categoriaParaCanalNome[categoriaAtual] or "1B"
        TriggerServerEvent('qb-activeofficers:server:updateCategory', categoriaAtual, canalAtualNome)

        local numCanal = tonumber(string.match(canalAtualNome, "%d+"))
        if numCanal then
            local sucesso = false
            local voz
            if GetResourceState('qb-voice') == 'started' then
                voz = 'qb-voice'
            elseif GetResourceState('pma-voice') == 'started' then
                voz = 'pma-voice'
            end
            if voz then
                sucesso = pcall(function() return exports[voz]:setRadioChannel(numCanal) end)
                if not sucesso then sucesso = pcall(function() return exports[voz]:SetRadioChannel(numCanal) end) end
                if not sucesso then sucesso = pcall(function() return exports[voz]:addPlayerToRadio(numCanal) end) end
            end
            if not sucesso then
                TriggerEvent('qb-voice:client:JoinRadioChannel', numCanal)
                TriggerEvent('pma-voice:setRadioChannel', numCanal)
            end
            canalRadio = numCanal
            TriggerServerEvent('qb-activeofficers:server:updateRadioChannel', canalRadio)
        end
        Notificar(L('categoria_ok', ObterNomeCategoria(categoriaAtual)), 'success')
    end
    if cb then cb('ok') end
end)

RegisterNUICallback('saveCallsignColors', function(data, cb)
    TriggerServerEvent('qb-activeofficers:server:saveCallsignColors', data and data.colors or {})
    Notificar(L('salvou_cores'), 'success')
    if cb then cb('ok') end
end)

RegisterNUICallback('getCallsignColors', function(_, cb)
    EnsureCore()
    -- aguarda Core se ainda não disponível (evita nil na callback)
    local t0 = GetGameTimer()
    while not QBCore do
        if (GetGameTimer() - t0) > 6000 then break end
        EnsureCore()
        Wait(100)
    end
    if not QBCore then
        cb({})
        return
    end
    QBCore.Functions.TriggerCallback('qb-activeofficers:server:getCallsignColors', function(cores)
        cb(cores or {})
    end)
end)

--====================[ UTILS ]====================--
function ObterNomeCategoria(cat)
    if cat == "store" then return "Roubo em Loja"
    elseif cat == "fleeca" then return "Roubo ao Fleeca"
    elseif cat == "pacific" then return "Roubo ao Pacific"
    elseif cat == "jewelry" then return "Roubo à Joalheria"
    elseif cat == "pursuit" then return "Perseguição"
    elseif cat == "traffic" then return "Abordagem de Trânsito"
    elseif cat == "investigation" then return "Investigação"
    else return "Principal" end
end

--====================[ ESC FECHA PAINEL ]====================--
CreateThread(function()
    while true do
        Wait(0)
        if painelConfiguracoesAberto and IsControlJustReleased(0, 177) then -- ESC
            painelConfiguracoesAberto = false
            SetNuiFocus(false, false)
            pcall(SetNuiFocusKeepInput, false)
            NUISend({ action="closeActiveOfficersPanel" })
        end
    end
end)

--====================[ KEYMAPPING ]====================--
local settingsKey = (rawget(_G, 'Config') and Config and Config.SettingsPanelKey) or DEFAULT_SETTINGS_KEY
RegisterKeyMapping('officersettings', 'Abrir painel de policiais ativos (Configurações)', 'keyboard', settingsKey)
