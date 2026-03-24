-- ============================================================
-- PS-FORENSICS - Dados de Tipos de Evidência e Munição
-- Integração com ND_Police ammo types
-- ============================================================

return {
    -- Mapeamento de calibres ND_Police -> labels forenses
    ammo_types = {
        ['AMMO_PISTOL']         = { caliber = '9mm',        label = '9mm Parabellum' },
        ['AMMO_SMG']            = { caliber = '9mm',        label = '9mm Parabellum' },
        ['AMMO_RIFLE']          = { caliber = '5.56x45',    label = '5.56x45mm NATO' },
        ['AMMO_MG']             = { caliber = '7.62x51',    label = '7.62x51mm NATO' },
        ['AMMO_SHOTGUN']        = { caliber = '12 Gauge',   label = '12 Gauge' },
        ['AMMO_SNIPER']         = { caliber = '.50BMG',     label = '.50 BMG' },
        ['AMMO_PISTOL_MK2']     = { caliber = '9mm',        label = '9mm Mk2' },
        ['AMMO_SMG_MK2']        = { caliber = '9mm',        label = '9mm Mk2' },
        ['AMMO_RIFLE_MK2']      = { caliber = '5.56x45',    label = '5.56x45mm Mk2' },
        ['AMMO_SNIPER_MK2']     = { caliber = '.50BMG',     label = '.50 BMG Mk2' },
    },

    -- Tipos de coleta de evidência e seus métodos recomendados
    collection_methods = {
        capsula         = 'Pinça metálica estéril',
        projetil        = 'Pinça metálica estéril',
        arma_fogo       = 'Luvas nitrílicas + saco de evidência',
        sangue          = 'Swab estéril + tubo de coleta',
        cabelo          = 'Pinça estéril + envelope de evidência',
        saliva          = 'Swab bucal estéril',
        impressao_digital = 'Kit de revelação (pó + pincel)',
        residuo_polvora = 'Fita adesiva de coleta GSR',
        substancia_po   = 'Espátula + recipiente estéril',
        roupa           = 'Saco de papel para evidência',
        faca            = 'Luvas + caixa de evidência',
    },

    -- Classificação de drogas por cor de reagente (teste presuntivo)
    drug_reagent_colors = {
        cocaina         = { reagent = 'Scott',      positive_color = 'Azul' },
        maconha         = { reagent = 'Duquenois',  positive_color = 'Roxo' },
        metanfetamina   = { reagent = 'Marquis',    positive_color = 'Laranja' },
        opioides        = { reagent = 'Marquis',    positive_color = 'Roxo escuro' },
        mdma            = { reagent = 'Marquis',    positive_color = 'Preto/Roxo' },
        anfetamina      = { reagent = 'Marquis',    positive_color = 'Laranja/Marrom' },
    },
}
