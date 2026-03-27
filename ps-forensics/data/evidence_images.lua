-- ============================================================
-- PS-FORENSICS - Mapeamento de Imagens por Tipo de Evidência
-- As imagens devem estar em: ps-forensics/html/images/evidence/
--
-- SISTEMA DE FALLBACK:
--   1. Busca pelo nome mapeado em TypeMap (específico por tipo)
--   2. Caso não exista, busca pelo CategoryMap (por categoria)
--   3. Caso não exista, usa Default (imagem genérica)
--
-- Para adicionar novos tipos: basta adicionar ao TypeMap abaixo.
-- Não é necessário alterar nenhum outro arquivo.
--
-- COMPATIBILIDADE: Os nomes de arquivo são intencionalmente
-- similares aos usados no script 'evidences' (noobsystems),
-- facilitando o reaproveitamento das imagens se disponíveis.
-- ============================================================

EvidenceImages = EvidenceImages or {}

-- Caminho base (relativo ao resource, usado no NUI como nui://ps-forensics/...)
EvidenceImages.BasePath = 'html/images/evidence/'

-- Imagem padrão quando nenhum mapeamento for encontrado
EvidenceImages.Default = 'evidence_generic.svg'

-- ============================================================
-- MAPEAMENTO POR TIPO DE EVIDÊNCIA
-- ============================================================
EvidenceImages.TypeMap = {
    -- Balística
    capsula                = 'shell_casing.png',
    projetil               = 'bullet.png',
    arma_fogo              = 'firearm.png',
    municao                = 'ammo.png',
    fragmento_projetil     = 'bullet_fragment.png',

    -- Biológica
    sangue                 = 'blood.png',
    saliva                 = 'saliva.png',
    cabelo                 = 'hair.png',
    suor                   = 'sweat.png',
    tecido_biologico       = 'biological_tissue.png',
    fluido_biologico       = 'biological_fluid.png',

    -- Digital / Impressão
    impressao_digital      = 'fingerprint.png',
    pegada                 = 'footprint.png',
    marca_pneu             = 'tire_mark.png',

    -- Química
    residuo_polvora        = 'gunshot_residue.png',
    residuo_droga          = 'drug_residue.png',
    substancia_po          = 'powder.png',
    substancia_liquida     = 'liquid.png',
    comprimido             = 'pill.png',
    seringa                = 'syringe.png',
    embalagem              = 'package.png',
    residuo_quimico        = 'chemical.png',

    -- Documental / Eletrônico
    documento              = 'document.png',
    celular                = 'phone.png',
    dispositivo_eletronico = 'electronic.png',
    midia_digital          = 'digital_media.png',

    -- Vestimenta
    roupa                  = 'clothing.png',
    calcado                = 'shoe.png',

    -- Veículo
    veiculo_cena           = 'vehicle.png',

    -- Objetos
    faca                   = 'knife.png',
    lamina                 = 'blade.png',
    objeto_perfurante      = 'sharp_object.png',
    objeto_contundente     = 'blunt_object.png',
    objeto_queimado        = 'burned_object.png',

    -- Genérico
    outros                 = 'evidence_generic.svg',
}

-- ============================================================
-- MAPEAMENTO POR CATEGORIA (fallback de segundo nível)
-- ============================================================
EvidenceImages.CategoryMap = {
    balistica          = 'category_ballistics.png',
    biologica          = 'blood.png',
    digital_impressao  = 'fingerprint.png',
    quimica            = 'chemical.png',
    documental         = 'document.png',
    eletronica         = 'electronic.png',
    vestimenta         = 'clothing.png',
    veiculo            = 'vehicle.png',
    objeto_cortante    = 'knife.png',
    objeto_contundente = 'blunt_object.png',
    outros             = 'evidence_generic.svg',
}

-- ============================================================
-- FUNÇÃO UTILITÁRIA (use no servidor e compartilhado)
-- Retorna apenas o nome do arquivo (sem caminho)
-- ============================================================
function EvidenceImages.GetImageFile(evidenceType, evidenceCategory)
    return EvidenceImages.TypeMap[evidenceType]
        or EvidenceImages.CategoryMap[evidenceCategory]
        or EvidenceImages.Default
end
