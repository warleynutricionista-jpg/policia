Config = Config or {}

-- ============================================================
-- CONFIGURAÇÕES GERAIS
-- ============================================================
Config.Debug = false
Config.Framework = 'qbx'

-- ============================================================
-- JOBS E CARGOS
-- ============================================================
Config.PoliceJobs = {
    'police', 'ftpolicia', 'policiacivil', 'lspd', 'bcso', 'sahp', 'fib', 'gov'
}

Config.ForensicJobs = {
    'police', 'ftpolicia', 'policiacivil', 'lspd', 'bcso', 'sahp', 'fib'
}

Config.MedicalJobs = {
    'ambulance'
}

-- Cargos/funções no sistema forense
-- Define quem pode fazer o quê
Config.Roles = {
    -- Policial operacional: coleta básica, isolar cena
    policial = {
        minGrade = 0,
        canCreateScene = true,
        canCollectEvidence = true,
        canRunBasicTests = true,
        canRunLabTests = false,
        canEmitReport = false,
        canPerformAutopsy = false,
        canModifyCustody = true,
        canFinalizeReport = false,
    },
    -- Investigador: tudo do policial + testes avançados
    investigador = {
        minGrade = 0, -- policiacivil grade 0
        jobs = { 'policiacivil' },
        canCreateScene = true,
        canCollectEvidence = true,
        canRunBasicTests = true,
        canRunLabTests = true,
        canEmitReport = true,
        canPerformAutopsy = false,
        canModifyCustody = true,
        canFinalizeReport = false,
    },
    -- Perito criminal: tudo do investigador + laudos + lab completo
    perito = {
        minGrade = 2,
        canCreateScene = true,
        canCollectEvidence = true,
        canRunBasicTests = true,
        canRunLabTests = true,
        canEmitReport = true,
        canPerformAutopsy = false,
        canModifyCustody = true,
        canFinalizeReport = true,
    },
    -- Legista: tudo do perito + autópsia
    legista = {
        minGrade = 2,
        jobs = { 'ambulance' },
        canCreateScene = true,
        canCollectEvidence = true,
        canRunBasicTests = true,
        canRunLabTests = true,
        canEmitReport = true,
        canPerformAutopsy = true,
        canModifyCustody = true,
        canFinalizeReport = true,
    },
    -- Delegado: acesso total
    delegado = {
        minGrade = 5,
        canCreateScene = true,
        canCollectEvidence = true,
        canRunBasicTests = true,
        canRunLabTests = true,
        canEmitReport = true,
        canPerformAutopsy = false,
        canModifyCustody = true,
        canFinalizeReport = true,
    },
    -- Comando: acesso total
    comando = {
        minGrade = 7,
        canCreateScene = true,
        canCollectEvidence = true,
        canRunBasicTests = true,
        canRunLabTests = true,
        canEmitReport = true,
        canPerformAutopsy = false,
        canModifyCustody = true,
        canFinalizeReport = true,
    },
}

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
-- CLASSIFICAÇÕES DE CENA
-- ============================================================
Config.SceneClassifications = {
    { value = 'homicidio',              label = 'Homicídio' },
    { value = 'tentativa_homicidio',    label = 'Tentativa de Homicídio' },
    { value = 'latrocinio',             label = 'Latrocínio' },
    { value = 'roubo',                  label = 'Roubo' },
    { value = 'furto',                  label = 'Furto' },
    { value = 'trafico',               label = 'Tráfico' },
    { value = 'confronto',             label = 'Confronto Armado' },
    { value = 'acidente',              label = 'Acidente' },
    { value = 'sequestro',             label = 'Sequestro' },
    { value = 'violencia_domestica',   label = 'Violência Doméstica' },
    { value = 'ocultacao_cadaver',     label = 'Ocultação de Cadáver' },
    { value = 'incendio_criminoso',    label = 'Incêndio Criminoso' },
    { value = 'explosao',             label = 'Explosão' },
    { value = 'envenenamento',         label = 'Envenenamento' },
    { value = 'estupro',              label = 'Estupro' },
    { value = 'outros',               label = 'Outros' },
}

-- ============================================================
-- TIPOS DE EVIDÊNCIA
-- ============================================================
Config.EvidenceTypes = {
    -- Balística
    { category = 'balistica', type = 'capsula',            label = 'Cápsula' },
    { category = 'balistica', type = 'projetil',           label = 'Projétil' },
    { category = 'balistica', type = 'arma_fogo',          label = 'Arma de Fogo' },
    { category = 'balistica', type = 'municao',            label = 'Munição' },
    { category = 'balistica', type = 'fragmento_projetil', label = 'Fragmento de Projétil' },

    -- Biológica
    { category = 'biologica', type = 'sangue',             label = 'Sangue' },
    { category = 'biologica', type = 'cabelo',             label = 'Cabelo/Pelo' },
    { category = 'biologica', type = 'saliva',             label = 'Saliva' },
    { category = 'biologica', type = 'suor',               label = 'Suor' },
    { category = 'biologica', type = 'tecido_biologico',   label = 'Tecido Biológico' },
    { category = 'biologica', type = 'fluido_biologico',   label = 'Fluido Biológico' },

    -- Impressões
    { category = 'digital_impressao', type = 'impressao_digital', label = 'Impressão Digital' },
    { category = 'digital_impressao', type = 'pegada',            label = 'Pegada' },
    { category = 'digital_impressao', type = 'marca_pneu',        label = 'Marca de Pneu' },

    -- Química
    { category = 'quimica', type = 'residuo_polvora',     label = 'Resíduo de Pólvora' },
    { category = 'quimica', type = 'residuo_droga',        label = 'Resíduo de Droga' },
    { category = 'quimica', type = 'substancia_po',        label = 'Substância em Pó' },
    { category = 'quimica', type = 'substancia_liquida',   label = 'Substância Líquida' },
    { category = 'quimica', type = 'comprimido',           label = 'Comprimido' },
    { category = 'quimica', type = 'seringa',              label = 'Seringa' },
    { category = 'quimica', type = 'embalagem',            label = 'Embalagem' },
    { category = 'quimica', type = 'residuo_quimico',      label = 'Resíduo Químico' },

    -- Documental
    { category = 'documental', type = 'documento',         label = 'Documento' },
    { category = 'documental', type = 'celular',           label = 'Celular' },

    -- Eletrônica
    { category = 'eletronica', type = 'dispositivo_eletronico', label = 'Dispositivo Eletrônico' },
    { category = 'eletronica', type = 'midia_digital',          label = 'Mídia Digital' },

    -- Vestimenta
    { category = 'vestimenta', type = 'roupa',             label = 'Roupa/Vestimenta' },
    { category = 'vestimenta', type = 'calcado',           label = 'Calçado' },

    -- Veículo
    { category = 'veiculo', type = 'veiculo_cena',         label = 'Veículo na Cena' },

    -- Objetos
    { category = 'objeto_cortante', type = 'faca',         label = 'Faca' },
    { category = 'objeto_cortante', type = 'lamina',       label = 'Lâmina' },
    { category = 'objeto_cortante', type = 'objeto_perfurante', label = 'Objeto Perfurante' },
    { category = 'objeto_contundente', type = 'objeto_contundente', label = 'Objeto Contundente' },
    { category = 'outros', type = 'objeto_queimado',       label = 'Objeto Queimado' },
    { category = 'outros', type = 'outros',                label = 'Outros' },
}

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
    OpenForensics = 'forensics',
    CreateScene = 'criarCena',
    CollectEvidence = 'coletarEvidencia',
    RunTest = 'testeForense',
    OpenLab = 'laboratorio',
    OpenMorgue = 'iml',
}

-- ============================================================
-- ITENS NO OX_INVENTORY
-- ============================================================
Config.Items = {
    forensic_kit       = 'forensic_kit',
    evidence_bag       = 'evidence_bag',
    swab_kit           = 'swab_kit',
    fingerprint_kit    = 'fingerprint_kit',
    gsr_kit            = 'gsr_test_kit',
    drug_test_kit      = 'drug_test_kit',
    blood_test_kit     = 'blood_test_kit',
    evidence_seal      = 'evidence_seal',
    camera             = 'camera',
    forensic_tablet    = 'forensic_tablet',
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
