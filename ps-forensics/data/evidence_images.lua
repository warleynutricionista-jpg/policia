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
    capsula                = 'shell_casing.svg',
    projetil               = 'bullet.svg',
    arma_fogo              = 'firearm.svg',
    municao                = 'ammo.svg',
    fragmento_projetil     = 'bullet_fragment.svg',

    -- Biológica
    sangue                 = 'blood.svg',
    saliva                 = 'saliva.svg',
    cabelo                 = 'hair.svg',
    suor                   = 'sweat.svg',
    tecido_biologico       = 'biological_tissue.svg',
    fluido_biologico       = 'biological_fluid.svg',

    -- Digital / Impressão
    impressao_digital      = 'fingerprint.png',
    pegada                 = 'footprint.svg',
    marca_pneu             = 'tire_mark.svg',

    -- Química
    residuo_polvora        = 'gunshot_residue.svg',
    residuo_droga          = 'drug_residue.svg',
    substancia_po          = 'powder.svg',
    substancia_liquida     = 'liquid.svg',
    comprimido             = 'pill.svg',
    seringa                = 'syringe.svg',
    embalagem              = 'package.svg',
    residuo_quimico        = 'chemical.svg',

    -- Documental / Eletrônico
    documento              = 'document.svg',
    celular                = 'phone.svg',
    dispositivo_eletronico = 'electronic.svg',
    midia_digital          = 'digital_media.svg',

    -- Vestimenta
    roupa                  = 'clothing.svg',
    calcado                = 'shoe.svg',

    -- Veículo
    veiculo_cena           = 'vehicle.svg',

    -- Objetos
    faca                   = 'knife.svg',
    lamina                 = 'blade.svg',
    objeto_perfurante      = 'sharp_object.svg',
    objeto_contundente     = 'blunt_object.svg',
    objeto_queimado        = 'burned_object.svg',

    -- Genérico
    outros                 = 'evidence_generic.svg',
}

-- ============================================================
-- MAPEAMENTO POR CATEGORIA (fallback de segundo nível)
-- ============================================================
EvidenceImages.CategoryMap = {
    balistica          = 'category_ballistics.svg',
    biologica          = 'blood.svg',
    digital_impressao  = 'fingerprint.png',
    quimica            = 'chemical.svg',
    documental         = 'document.svg',
    eletronica         = 'electronic.svg',
    vestimenta         = 'clothing.svg',
    veiculo            = 'vehicle.svg',
    objeto_cortante    = 'knife.svg',
    objeto_contundente = 'blunt_object.svg',
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
