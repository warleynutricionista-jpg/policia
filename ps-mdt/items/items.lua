return {
    ['mdtcitation'] = {
        label = 'Bloco de Citação MDT',
        description = 'Documento físico usado no fluxo de emissão de citação via MDT.',
        weight = 15,
        stack = true,
        consume = 0,
        close = false,
        client = { export = 'ps-mdt.OpenMDT' },
    },
}
