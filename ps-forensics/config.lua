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
    forensic_tablet       = 'forensic_tablet',
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
