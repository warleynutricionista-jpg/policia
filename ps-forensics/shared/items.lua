ForensicItemActions = {
    open_tablet = {
        required = { 'forensic_tablet' },
    },
    open_forensic_toolkit = {
        required = { 'forensic_kit' },
    },
    collect_evidence = {
        required = { 'forensic_kit', 'evidence_bag' },
        consume = { evidence_bag = 1 },
    },
    collect_biological = {
        required = { 'forensic_kit', 'disposable_gloves', 'dna_swab', 'evidence_bag' },
        consume = { dna_swab = 1, evidence_bag = 1 },
        optionalConsume = { evidence_seal = 1 },
    },
    collect_fingerprint_sequence = {
        required = { 'forensic_kit', 'fingerprint_kit', 'fingerprint_powder', 'fingerprint_tape', 'evidence_bag' },
        consume = { fingerprint_powder = 1, fingerprint_tape = 1, evidence_bag = 1 },
    },
    collect_ballistic = {
        required = { 'forensic_kit', 'ballistic_kit', 'forensic_tweezers', 'evidence_bag' },
        consume = { evidence_bag = 1 },
    },
    run_gsr_test = {
        required = { 'forensic_kit', 'gsr_kit' },
        consume = { gsr_kit = 1 },
    },
    run_drug_test = {
        required = { 'forensic_kit', 'drug_test_kit' },
        consume = { drug_test_kit = 1 },
    },
    run_blood_test = {
        required = { 'forensic_kit', 'blood_reagent' },
        consume = { blood_reagent = 1 },
    },
    capture_evidence_photo = {
        required = { 'forensic_camera' },
    },
    place_evidence_marker = {
        required = { 'evidence_marker' },
        consume = { evidence_marker = 1 },
    },
    tag_evidence = {
        required = { 'evidence_tag' },
        consume = { evidence_tag = 1 },
    },
    seal_evidence = {
        required = { 'evidence_seal' },
        consume = { evidence_seal = 1 },
    },
    autopsy_exam = {
        required = { 'medical_exam_case', 'body_bag', 'disposable_gloves' },
        consume = { body_bag = 1, disposable_gloves = 1 },
    },
    scene_dark_search = {
        required = { 'forensic_flashlight' },
    },
}

ForensicItemUsageMap = {
    forensic_kit = { action = 'open_forensic_toolkit', serverValidate = true },
    disposable_gloves = { action = 'scene_dark_search', serverValidate = false },
    evidence_bag = { action = 'collect_evidence', serverValidate = true, requiresTarget = true },
    evidence_seal = { action = 'seal_evidence', serverValidate = true, requiresTarget = true },
    dna_swab = { action = 'collect_biological', serverValidate = true, requiresTarget = true, allowedTypes = { sangue = true } },
    fingerprint_kit = { action = 'collect_fingerprint_sequence', serverValidate = true, requiresTarget = true, allowedTypes = { impressao_digital = true } },
    fingerprint_powder = { action = 'collect_fingerprint_sequence', serverValidate = true, requiresTarget = true, allowedTypes = { impressao_digital = true, pegada = true }, effect = 'reveal' },
    fingerprint_tape = { action = 'collect_fingerprint_sequence', serverValidate = true, requiresTarget = true, allowedTypes = { impressao_digital = true }, effect = 'collect' },
    blood_reagent = { action = 'run_blood_test', serverValidate = true, requiresTarget = true, allowedTypes = { sangue = true }, effect = 'reveal' },
    gsr_kit = { action = 'run_gsr_test', serverValidate = true, requiresTarget = true, allowedTypes = { residuo_polvora = true }, effect = 'analyze' },
    drug_test_kit = { action = 'run_drug_test', serverValidate = true, requiresTarget = true, allowedTypes = { residuo_droga = true, substancia_po = true }, effect = 'analyze' },
    forensic_tweezers = { action = 'collect_ballistic', serverValidate = true, requiresTarget = true, allowedTypes = { capsula = true, projetil = true, fragmento_veiculo = true }, effect = 'collect' },
    forensic_camera = { action = 'capture_evidence_photo', serverValidate = true, requiresTarget = false, effect = 'photo' },
    evidence_marker = { action = 'place_evidence_marker', serverValidate = true, requiresTarget = false, effect = 'place_marker' },
    evidence_tag = { action = 'tag_evidence', serverValidate = true, requiresTarget = true, effect = 'tag' },
    medical_exam_case = { action = 'autopsy_exam', serverValidate = true, requiresTarget = false },
    body_bag = { action = 'autopsy_exam', serverValidate = true, requiresTarget = false },
    forensic_flashlight = { action = 'scene_dark_search', serverValidate = true, requiresTarget = false, effect = 'flashlight' },
    ballistic_kit = { action = 'collect_ballistic', serverValidate = true, requiresTarget = true, allowedTypes = { capsula = true, projetil = true, buraco_de_bala = true }, effect = 'analyze' },
    forensic_tablet = { action = 'open_tablet', serverValidate = true, requiresTarget = false, effect = 'ui' },
    mdtcitation = { action = 'issue_citation', serverValidate = false, requiresTarget = false, effect = 'mdt' },
}

ForensicEvidenceVisualMap = {
    sangue = { dict = 'blooddrops', texture = 'blooddrops', fallbackMarker = 27, requiresReveal = true },
    capsula = { dict = 'casings', texture = 'casings', fallbackMarker = 2 },
    projetil = { dict = 'casings', texture = 'casings', fallbackMarker = 2 },
    buraco_de_bala = { dict = 'bullethole', texture = 'bullethole', fallbackMarker = 1 },
    fragmento_veiculo = { dict = 'bullethole', texture = 'bullethole', fallbackMarker = 1 },
    impressao_digital = { dict = 'fingerprints', texture = 'fingerprints', fallbackMarker = 28, requiresReveal = true },
    pegada = { dict = 'footprint', texture = 'footprint', fallbackMarker = 28, requiresReveal = true },
    marcador_cena = { dict = 'interact', texture = 'interact', fallbackMarker = 6 },
}
