ForensicShared = ForensicShared or {}

ForensicShared.Jobs = {
    Police = {
        'police', 'ftpolicia', 'policiacivil', 'lspd', 'bcso', 'sahp', 'fib', 'gov'
    },
    Forensic = {
        'police', 'ftpolicia', 'policiacivil', 'lspd', 'bcso', 'sahp', 'fib'
    },
    Medical = {
        'ambulance'
    },
}

ForensicShared.Roles = {
    policial_operacional = {
        minGrade = 0,
        canCreateScene = true,
        canCollectEvidence = true,
        canRunBasicTests = false,
        canRunLabTests = false,
        canEmitReport = false,
        canPerformAutopsy = false,
        canModifyCustody = true,
        canFinalizeReport = false,
    },
    policiacivil_especializado = {
        minGrade = 0,
        jobs = { 'policiacivil' },
        canCreateScene = true,
        canCollectEvidence = true,
        canRunBasicTests = true,
        canRunLabTests = true,
        canEmitReport = true,
        canPerformAutopsy = true,
        canModifyCustody = true,
        canFinalizeReport = true,
    },
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
}

ForensicShared.PermissionMatrix = {
    levels = {
        operacional = 1,
        investigacao = 2,
        administracao = 3,
    },
    byJob = {
        policiacivil = 'investigacao',
        police = 'operacional',
        ftpolicia = 'operacional',
        lspd = 'operacional',
        bcso = 'operacional',
        sahp = 'operacional',
        fib = 'investigacao',
        gov = 'investigacao',
        ambulance = 'investigacao',
    },
    permissions = {
        canCreateScene = 1,
        canCollectEvidence = 1,
        canRunBasicTests = 1,
        canModifyCustody = 1,
        canRunLabTests = 2,
        canEmitReport = 2,
        canPerformAutopsy = 2,
        canFinalizeReport = 2,
        canAdminForensics = 3,
    },
}

ForensicShared.Enums = {
    SceneStatus = { 'aberta', 'isolada', 'em_processamento', 'finalizada', 'reaberta' },
    EvidenceStatus = { 'coletada', 'lacrada', 'em_analise', 'analisada', 'armazenada', 'descartada', 'devolvida', 'em_julgamento' },
    LabStatus = { 'solicitado', 'em_andamento', 'concluido', 'cancelado' },
    TestResult = { 'pendente', 'presumido', 'inconclusivo', 'compativel', 'confirmado', 'negativo' },
    ReportStatus = { 'rascunho', 'em_revisao', 'finalizado', 'anexado_mdt' },
}

ForensicShared.SceneClassifications = {
    { value = 'homicidio', labelKey = 'scene.classification.homicidio' },
    { value = 'tentativa_homicidio', labelKey = 'scene.classification.tentativa_homicidio' },
    { value = 'latrocinio', labelKey = 'scene.classification.latrocinio' },
    { value = 'roubo', labelKey = 'scene.classification.roubo' },
    { value = 'furto', labelKey = 'scene.classification.furto' },
    { value = 'trafico', labelKey = 'scene.classification.trafico' },
    { value = 'confronto', labelKey = 'scene.classification.confronto' },
    { value = 'acidente', labelKey = 'scene.classification.acidente' },
    { value = 'sequestro', labelKey = 'scene.classification.sequestro' },
    { value = 'violencia_domestica', labelKey = 'scene.classification.violencia_domestica' },
    { value = 'ocultacao_cadaver', labelKey = 'scene.classification.ocultacao_cadaver' },
    { value = 'incendio_criminoso', labelKey = 'scene.classification.incendio_criminoso' },
    { value = 'explosao', labelKey = 'scene.classification.explosao' },
    { value = 'envenenamento', labelKey = 'scene.classification.envenenamento' },
    { value = 'estupro', labelKey = 'scene.classification.estupro' },
    { value = 'outros', labelKey = 'scene.classification.outros' },
}

ForensicShared.EvidenceCategories = {
    { value = 'balistica', labelKey = 'evidence.category.balistica' },
    { value = 'biologica', labelKey = 'evidence.category.biologica' },
    { value = 'digital_impressao', labelKey = 'evidence.category.digital_impressao' },
    { value = 'quimica', labelKey = 'evidence.category.quimica' },
    { value = 'documental', labelKey = 'evidence.category.documental' },
    { value = 'eletronica', labelKey = 'evidence.category.eletronica' },
    { value = 'vestimenta', labelKey = 'evidence.category.vestimenta' },
    { value = 'veiculo', labelKey = 'evidence.category.veiculo' },
    { value = 'objeto_cortante', labelKey = 'evidence.category.objeto_cortante' },
    { value = 'objeto_contundente', labelKey = 'evidence.category.objeto_contundente' },
    { value = 'outros', labelKey = 'evidence.category.outros' },
}

ForensicShared.EvidenceTypes = {
    { category = 'balistica', type = 'capsula', labelKey = 'evidence.type.capsula' },
    { category = 'balistica', type = 'projetil', labelKey = 'evidence.type.projetil' },
    { category = 'balistica', type = 'arma_fogo', labelKey = 'evidence.type.arma_fogo' },
    { category = 'balistica', type = 'municao', labelKey = 'evidence.type.municao' },
    { category = 'balistica', type = 'fragmento_projetil', labelKey = 'evidence.type.fragmento_projetil' },
    { category = 'biologica', type = 'sangue', labelKey = 'evidence.type.sangue' },
    { category = 'biologica', type = 'cabelo', labelKey = 'evidence.type.cabelo' },
    { category = 'biologica', type = 'saliva', labelKey = 'evidence.type.saliva' },
    { category = 'biologica', type = 'suor', labelKey = 'evidence.type.suor' },
    { category = 'biologica', type = 'tecido_biologico', labelKey = 'evidence.type.tecido_biologico' },
    { category = 'biologica', type = 'fluido_biologico', labelKey = 'evidence.type.fluido_biologico' },
    { category = 'digital_impressao', type = 'impressao_digital', labelKey = 'evidence.type.impressao_digital' },
    { category = 'digital_impressao', type = 'pegada', labelKey = 'evidence.type.pegada' },
    { category = 'digital_impressao', type = 'marca_pneu', labelKey = 'evidence.type.marca_pneu' },
    { category = 'quimica', type = 'residuo_polvora', labelKey = 'evidence.type.residuo_polvora' },
    { category = 'quimica', type = 'residuo_droga', labelKey = 'evidence.type.residuo_droga' },
    { category = 'quimica', type = 'substancia_po', labelKey = 'evidence.type.substancia_po' },
    { category = 'quimica', type = 'substancia_liquida', labelKey = 'evidence.type.substancia_liquida' },
    { category = 'quimica', type = 'comprimido', labelKey = 'evidence.type.comprimido' },
    { category = 'quimica', type = 'seringa', labelKey = 'evidence.type.seringa' },
    { category = 'quimica', type = 'embalagem', labelKey = 'evidence.type.embalagem' },
    { category = 'quimica', type = 'residuo_quimico', labelKey = 'evidence.type.residuo_quimico' },
    { category = 'documental', type = 'documento', labelKey = 'evidence.type.documento' },
    { category = 'documental', type = 'celular', labelKey = 'evidence.type.celular' },
    { category = 'eletronica', type = 'dispositivo_eletronico', labelKey = 'evidence.type.dispositivo_eletronico' },
    { category = 'eletronica', type = 'midia_digital', labelKey = 'evidence.type.midia_digital' },
    { category = 'vestimenta', type = 'roupa', labelKey = 'evidence.type.roupa' },
    { category = 'vestimenta', type = 'calcado', labelKey = 'evidence.type.calcado' },
    { category = 'veiculo', type = 'veiculo_cena', labelKey = 'evidence.type.veiculo_cena' },
    { category = 'objeto_cortante', type = 'faca', labelKey = 'evidence.type.faca' },
    { category = 'objeto_cortante', type = 'lamina', labelKey = 'evidence.type.lamina' },
    { category = 'objeto_cortante', type = 'objeto_perfurante', labelKey = 'evidence.type.objeto_perfurante' },
    { category = 'objeto_contundente', type = 'objeto_contundente', labelKey = 'evidence.type.objeto_contundente' },
    { category = 'outros', type = 'objeto_queimado', labelKey = 'evidence.type.objeto_queimado' },
    { category = 'outros', type = 'outros', labelKey = 'evidence.type.outros' },
}

ForensicShared.QuickTests = {
    { value = 'residuo_polvora_maos', labelKey = 'test.type.residuo_polvora_maos' },
    { value = 'residuo_polvora_roupa', labelKey = 'test.type.residuo_polvora_roupa' },
    { value = 'residuo_polvora_arma', labelKey = 'test.type.residuo_polvora_arma' },
    { value = 'residuo_polvora_veiculo', labelKey = 'test.type.residuo_polvora_veiculo' },
    { value = 'teste_droga_presuntivo', labelKey = 'test.type.teste_droga_presuntivo' },
    { value = 'teste_sangue_presuntivo', labelKey = 'test.type.teste_sangue_presuntivo' },
    { value = 'alcoolemia', labelKey = 'test.type.alcoolemia' },
}
