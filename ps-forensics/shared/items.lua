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

