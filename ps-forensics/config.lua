Config = Config or {}

-- ============================================================
-- CONFIGURAÇÕES GERAIS
-- ============================================================
Config.Debug = false
Config.Framework = 'qbx'


-- ============================================================
-- LOCALIZAÇÃO
-- ============================================================
Config.Locale = {
    current = 'pt-BR',
    fallback = 'pt-BR',
    supported = { 'pt-BR', 'en', 'es' },
}

-- ============================================================
-- JOBS, ROLES E ENUMS (centralizados em shared/constants.lua)
-- ============================================================
Config.PoliceJobs = ForensicShared.Jobs.Police
Config.ForensicJobs = ForensicShared.Jobs.Forensic
Config.MedicalJobs = ForensicShared.Jobs.Medical
Config.Roles = ForensicShared.Roles
Config.Enums = ForensicShared.Enums
Config.PermissionMatrix = ForensicShared.PermissionMatrix
Config.AdminGroups = { 'admin', 'god', 'staff', 'mod' }

-- ============================================================
-- TEMPOS DE PROCESSAMENTO DOS TESTES (em segundos no jogo)
-- ============================================================
Config.TestProcessingTimes = {
    -- Testes rápidos (campo)
    residuo_polvora_maos = 10,
    residuo_polvora_roupa = 10,
    residuo_polvora_arma = 10,
    residuo_polvora_veiculo = 15,
    teste_droga_presuntivo = 8,
    teste_sangue_presuntivo = 8,
    coleta_digital = 12,
    coleta_dna = 15,

    -- Testes laboratoriais (mais demorados)
    analise_substancia = 30,
    analise_pureza = 45,
    analise_fluido_biologico = 30,
    comparacao_dna = 60,
    revelacao_digital = 25,
    comparacao_digital = 40,
    confronto_balistico = 45,
    analise_municao = 20,
    analise_capsula = 20,
    analise_projetil = 20,
    analise_vestimenta = 25,
    analise_objeto_cortante = 20,
    analise_objeto_contundente = 20,
    analise_eletronico = 40,
    analise_quimico = 35,
    toxicologico = 50,
    alcoolemia = 15,

    -- Medicina legal
    exame_cadaverico = 30,
    necropsia = 120,
    identificacao_cadaver = 20,
}

-- ============================================================
-- CLASSIFICAÇÕES E EVIDÊNCIAS (chaves internas centralizadas)
-- ============================================================
Config.SceneClassifications = ForensicShared.SceneClassifications
Config.EvidenceCategories = ForensicShared.EvidenceCategories
Config.EvidenceTypes = ForensicShared.EvidenceTypes
Config.QuickTests = ForensicShared.QuickTests

-- ============================================================
-- LOCAIS DE TRABALHO FORENSE
-- ============================================================
Config.Locations = {
    -- Laboratório forense
    Lab = {
        coords = vector3(475.0, -993.0, 31.0),
        radius = 3.0,
        label = 'Laboratório Forense',
        blip = {
            sprite = 628,
            color = 38,
            scale = 0.7,
            label = 'Lab. Forense',
        },
    },
    -- Instituto Médico Legal
    Morgue = {
        coords = vector3(240.0, -1379.0, 34.0),
        radius = 3.0,
        label = 'Instituto Médico Legal',
        blip = {
            sprite = 153,
            color = 1,
            scale = 0.7,
            label = 'IML',
        },
    },
    -- Depósito de evidências
    EvidenceStorage = {
        coords = vector3(441.0, -982.0, 30.7),
        radius = 2.0,
        label = 'Depósito de Evidências',
    },
}

-- ============================================================
-- COMANDOS
-- ============================================================
Config.Commands = {
    Open = {
        enabled = true,
        command = 'pericia',
    },
}

-- ============================================================
-- ABAS DO PAINEL (acesso por nível de permissão e cargo)
-- minLevel: 1 = operacional, 2 = investigacao, 3 = administracao
-- jobs: nil = todos os cargos com acesso forense, ou lista específica
-- ============================================================
Config.PanelTabs = {
    { id = 'dashboard',    label = 'Dashboard',    icon = 'fa-solid fa-chart-line',       minLevel = 1, jobs = nil },
    { id = 'scenes',       label = 'Cenas',         icon = 'fa-solid fa-location-dot',     minLevel = 1, jobs = nil },
    { id = 'evidence',     label = 'Evidências',    icon = 'fa-solid fa-box-archive',      minLevel = 1, jobs = nil },
    { id = 'lab',          label = 'Laboratório',   icon = 'fa-solid fa-flask',            minLevel = 2, jobs = nil },
    { id = 'fingerprints', label = 'Digitais',      icon = 'fa-solid fa-fingerprint',      minLevel = 2, jobs = nil },
    { id = 'dna',          label = 'DNA',           icon = 'fa-solid fa-dna',              minLevel = 2, jobs = nil },
    { id = 'ballistics',   label = 'Balística',     icon = 'fa-solid fa-gun',              minLevel = 2, jobs = nil },
    { id = 'drugs',        label = 'Drogas',        icon = 'fa-solid fa-pills',            minLevel = 2, jobs = nil },
    { id = 'autopsy',      label = 'Legista',       icon = 'fa-solid fa-skull',            minLevel = 2, jobs = { 'ambulance', 'policiacivil' } },
    { id = 'reports',      label = 'Laudos',        icon = 'fa-solid fa-file-medical',     minLevel = 2, jobs = nil },
    { id = 'crossref',     label = 'Cruzamento',    icon = 'fa-solid fa-diagram-project',  minLevel = 2, jobs = nil },
}

-- ============================================================
-- ITENS NO OX_INVENTORY
-- ============================================================
Config.Items = {
    forensic_kit          = 'forensic_kit',
    disposable_gloves     = 'disposable_gloves',
    evidence_bag          = 'evidence_bag',
    evidence_seal         = 'evidence_seal',
    dna_swab              = 'dna_swab',
    fingerprint_kit       = 'fingerprint_kit',
    fingerprint_powder    = 'fingerprint_powder',
    fingerprint_tape      = 'fingerprint_tape',
    blood_reagent         = 'blood_reagent',
    gsr_kit               = 'gsr_kit',
    drug_test_kit         = 'drug_test_kit',
    forensic_tweezers     = 'forensic_tweezers',
    forensic_camera       = 'forensic_camera',
    evidence_marker       = 'evidence_marker',
    evidence_tag          = 'evidence_tag',
    medical_exam_case     = 'medical_exam_case',
    body_bag              = 'body_bag',
    forensic_flashlight   = 'forensic_flashlight',
    ballistic_kit         = 'ballistic_kit',
    forensic_photo        = 'forensic_photo',
    forensic_tablet       = 'forensic_tablet',
    mdtcitation           = 'mdtcitation',
}

Config.ItemActions = Config.ItemActions or {}
Config.ItemConsumption = {
    collect_evidence = {
        evidence_bag = true,
    },
    collect_biological = {
        dna_swab = true,
        evidence_bag = true,
    },
    collect_fingerprint_sequence = {
        fingerprint_powder = true,
        fingerprint_tape = true,
        evidence_bag = true,
    },
    run_gsr_test = {
        gsr_kit = true,
    },
    run_drug_test = {
        drug_test_kit = true,
    },
    run_blood_test = {
        blood_reagent = true,
    },
    place_evidence_marker = {
        evidence_marker = true,
    },
    tag_evidence = {
        evidence_tag = true,
    },
    seal_evidence = {
        evidence_seal = true,
    },
    autopsy_exam = {
        body_bag = true,
        disposable_gloves = true,
    },
}

Config.OptionalItemConsumption = {
    collect_biological = true,
}

-- ============================================================
-- BLIP E MARCADOR DA CENA
-- ============================================================
Config.SceneBlip = {
    sprite = 526,
    color = 1,
    scale = 0.8,
    label = 'Cena de Crime',
}

Config.SceneMarker = {
    type = 1,
    scale = vector3(0.4, 0.4, 0.4),
    color = { r = 255, g = 0, b = 0, a = 180 },
}

-- ============================================================
-- NOTIFICAÇÕES
-- ============================================================
Config.Notifications = {
    position = 'top-right',
    duration = 5000,
}

Config.DisposableGlovesOutfit = {
    Enabled = true,
    ComponentId = 3,
    Male = { drawable = 86, texture = 0 },
    Female = { drawable = 109, texture = 0 },
}

-- ============================================================
-- EVIDÊNCIAS DE MUNDO (auto-spawn por eventos de jogo)
-- Inspirado nos padrões do script evidences (noobsystems) e renzu_evidence
-- ============================================================
Config.WorldEvidence = {
    -- Habilitar/desabilitar o sistema de spawn automático
    Enabled = true,

    -- Tempo de expiração das evidências de campo (segundos)
    -- Evidências não coletadas somem após esse tempo
    ExpirationTime = 3000, -- Recomendado: 2400~3600 (50 min padrão)

    -- Chance de spawn por tipo (0-100%)
    -- Baseado no modelo de probabilidade do renzu_evidence
    Chances = {
        sangue            = 65,  -- Alto: sangue é frequente em confrontos
        impressao_digital = 60,  -- Médio-alto: depende de luvas
        capsula           = 45,  -- Médio: nem todo projétil gera cápsula visível
        residuo_polvora   = 35,  -- Mais raro, requer análise específica
        pegada            = 55,  -- Médio-alto: corrida deixa marca no chão
        buraco_de_bala    = 70,  -- Alto: impacto de projétil em superfície sólida
        fragmento_veiculo = 60,  -- Médio-alto: tiro em veículo gera fragmento de tinta/metal
    },

    -- Detectar luvas antes de gerar impressão digital
    -- Se true, jogador com luvas não deixa digitais em veículos
    GloveDetection = true,

    -- Componente de luvas no ped (componente 5 = mãos)
    -- Drawable 0 = sem luvas (mãos nuas = deixa digital)
    GloveComponent = 5,
    BareHandsDrawable = 0,

    -- Dano mínimo recebido para gerar evidência de sangue
    MinBloodDamage = 10.0,

    -- Alcance da lanterna forense para destacar evidências próximas (metros)
    FlashlightRange = 13.5, -- Recomendado: 12~15

    -- Cooldown entre spawns do mesmo tipo por jogador (milissegundos)
    Cooldowns = {
        sangue            = 4000,
        impressao_digital = 2500,
        capsula           = 600,   -- Recomendado: 500~700
        residuo_polvora   = 8000,
        pegada            = 2500,  -- par com footprint delay do lsn-evidence
        buraco_de_bala    = 350,   -- Recomendado: 300~450
        fragmento_veiculo = 500,
    },


    -- Distância máxima entre jogador e coordenada enviada no spawn.
    -- Protege contra injeção client-side de evidências em pontos remotos.
    MaxSpawnDistanceFromPlayer = 20.0,

    -- Limite mínimo (ms) entre solicitações de spawn por jogador no servidor.
    ServerSpawnRateLimitMs = 250,

    -- Intervalo de polling para detectar queda de munição (cápsula)
    -- Menor = mais responsivo, porém mais uso de CPU no client.
    -- Recomendado para servidores médios: 180~250ms
    CasingPollIntervalMs = 200, -- Recomendado: 180~250

    -- Distância mínima entre duas evidências do mesmo tipo (evitar duplicatas)
    MinDistanceBetweenSameType = 2.0,

    -- Cor dos marcadores de descoberta por categoria (usado com lanterna)
    DiscoveryMarkerColors = {
        biologica          = { r = 255, g = 30,  b = 30,  a = 200 },
        balistica          = { r = 255, g = 165, b = 0,   a = 200 },
        digital_impressao  = { r = 0,   g = 150, b = 255, a = 200 },
        quimica            = { r = 100, g = 255, b = 80,  a = 200 },
        outros             = { r = 180, g = 180, b = 255, a = 160 },
    },

    -- ============================================================
    -- PEGADAS (inspirado em lsn-evidence: CEventFootStepHeard)
    -- ============================================================
    -- Habilitar sistema de pegadas automáticas ao correr
    AllowFootprints = true,

    -- Evita contaminação de cena por equipe policial/pericial.
    -- Quando true, jobs listados em FootprintBlockedJobs não geram pegadas automáticas.
    DisablePoliceFootprints = true,
    FootprintBlockedJobs = ForensicShared.Jobs.Police,

    -- Velocidade mínima do ped para gerar pegada (m/s) — corre ≈ 7, caminha ≈ 1.5
    FootprintMinSpeed = 6.5,

    -- Drawables de pé descalço por gênero (componente 6 = sapatos)
    -- Se o jogador usar esses drawables, não gera pegada
    BarehandsMaleShoes   = { 33, 34 }, -- masculino
    BarefootFemaleShoes  = { 34, 35 }, -- feminino

    -- ============================================================
    -- BURACO DE BALA E FRAGMENTO DE VEÍCULO
    -- (inspirado em lsn-evidence: CEventGunShot + lib.raycast.cam)
    -- ============================================================
    -- Habilitar geração de buracos de bala e fragmentos de veículo
    AllowBulletHoles = true,

    -- ============================================================
    -- LINHA DE TRAJETÓRIA (inspirado em lsn-evidence: ShowShootersLine)
    -- Quando a lanterna forense está ativa, exibe uma linha colorida
    -- ligando a posição do atirador ao buraco de bala / fragmento.
    -- ============================================================
    ShowShootersLine = true,
    ShootersLineColor = { r = 255, g = 50, b = 50, a = 200 },

    -- ============================================================
    -- ARMAS SEM EVIDÊNCIA BALÍSTICA
    -- Inspirado em lsn-evidence: WhitelistedWeapons
    -- Armas da lista não geram cápsula, buraco de bala nem fragmento
    -- ============================================================
    BlacklistedWeapons = {
        `weapon_unarmed`,
        `weapon_snowball`,
        `weapon_stungun`,
        `weapon_petrolcan`,
        `weapon_hazardcan`,
        `weapon_fireextinguisher`,
    },

    -- ============================================================
    -- CALIBRES DE MUNIÇÃO (inspirado em lsn-evidence: AmmoLabels)
    -- Mapeamento ammo_type -> nome real do calibre
    -- Salvo como metadado nas evidências balísticas
    -- ============================================================
    AmmoCalibersLabels = {
        ['AMMO_PISTOL']  = '9x19mm',
        ['AMMO_SMG']     = '9x19mm',
        ['AMMO_RIFLE']   = '7.62x39mm',
        ['AMMO_MG']      = '7.92x57mm',
        ['AMMO_SHOTGUN'] = '12-gauge',
        ['AMMO_SNIPER']  = 'Calibre pesado',
    },
}


-- Política de retenção de evidências persistentes (não-world)
Config.PersistencePolicy = {
    forensicEvidenceRetentionDays = 180,
    cleanupEnabled = false, -- por padrão não remove material forense automaticamente
}
