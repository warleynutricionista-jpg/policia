-- config.lua
-- Configurações do painel de Oficiais Ativos (PT-BR)

Config = {}

--========================[ TECLAS / ATALHOS ]========================--
-- Tecla padrão para abrir o painel de configurações dos oficiais
-- (o client registra via RegisterKeyMapping usando este valor)
Config.SettingsPanelKey = 'F12'

--========================[ HIERARQUIA / PATENTES ]===================--
-- Patente padrão e ícone caso o nível de grade não esteja mapeado
Config.DefaultRank     = 'Oficial'
Config.DefaultRankIcon = 'img/ranks/officer.png'

-- Nome das patentes por nível de grade (ajuste conforme seu job de polícia)
Config.Ranks = {
    [0] = 'Cadete',
    [1] = 'Oficial',
    [2] = 'Oficial Sênior',
    [3] = 'Cabo',
    [4] = 'Sargento',
    [5] = 'Tenente',
    [6] = 'Capitão',
    [7] = 'Subchefe',
    [8] = 'Chefe de Polícia',
}

-- Ícones por patente (garanta que os caminhos existem no seu NUI)
Config.RankIcons = {
    [0] = 'img/ranks/cadet.png',
    [1] = 'img/ranks/officer.png',
    [2] = 'img/ranks/senior_officer.png',
    [3] = 'img/ranks/corporal.png',
    [4] = 'img/ranks/sergeant.png',
    [5] = 'img/ranks/lieutenant.png',
    [6] = 'img/ranks/captain.png',
    [7] = 'img/ranks/assistant_chief.png',
    [8] = 'img/ranks/chief.png',
}

-- Cores por patente (opcional, usado quando UI.colorCodedRanks = true)
Config.RankColors = {
    [0] = '#95a5a6', -- Cadete
    [1] = '#2980b9', -- Oficial
    [2] = '#1abc9c', -- Oficial Sênior
    [3] = '#16a085', -- Cabo
    [4] = '#f1c40f', -- Sargento
    [5] = '#e67e22', -- Tenente
    [6] = '#d35400', -- Capitão
    [7] = '#8e44ad', -- Subchefe
    [8] = '#c0392b', -- Chefe
}

--========================[ INTEGRAÇÃO DE RÁDIO ]=====================--
Config.RadioIntegration = {
    enabled        = true,     -- habilita integração automática com o rádio
    voiceResource  = 'auto',   -- 'auto' | 'qb-voice' | 'pma-voice' (o client tenta em ordem)
    policeChannels = {1,2,3,4,5,6,7,8}, -- canais padrão de polícia
    emergencyChannel = 10,     -- canal compartilhado de emergência
}

--========================[ CATEGORIAS ⇄ CANAIS ]=====================--
-- Mantém coerência com o client (GetCategoryName e sincronização de canal)
Config.CategoryToChannel = {
    main          = '1B',
    store         = '2B',
    fleeca        = '3B',
    pacific       = '4B',
    jewelry       = '5B',
    pursuit       = '6B',
    traffic       = '7B',
    investigation = '8B',
}

-- Se seu voice usa números, o client extrai o dígito (ex.: "6B" -> 6)
Config.ChannelToCategory = {
    [1] = 'main',
    [2] = 'store',
    [3] = 'fleeca',
    [4] = 'pacific',
    [5] = 'jewelry',
    [6] = 'pursuit',
    [7] = 'traffic',
    [8] = 'investigation',
}

--========================[ UI / APARÊNCIA ]==========================--
Config.UI = {
    showRadioChannel  = true,  -- exibe o canal de rádio na UI
    colorCodedRanks   = true,  -- usa cores por patente (RankColors)
    showPlayerFaces   = true,  -- mostra rostos/fotos na lista (se disponível)
    showOnlyOnDuty    = true,  -- na lista, preferir exibir apenas quem está de serviço
    compactList       = false, -- lista compacta (menos espaçamento)
}

--========================[ PERMISSÕES ESPECIAIS ]====================--
-- Nível mínimo de grade para acessar configurações avançadas (ex.: cores)
Config.CommissionerGrade = 31

--========================[ AJUSTES OPCIONAIS ]=======================--
-- Caso queira filtrar jobs adicionais considerados “polícia”
Config.PoliceJobs = { 'police' }  -- mantenha sincronizado com o server
