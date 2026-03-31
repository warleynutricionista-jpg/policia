return {
    ['mdttablet'] = {
        label = 'Tablet Policial',
        description = 'Tablet oficial para acessar o painel MDT.',
        weight = 650,
        stack = false,
        consume = 0,
        close = true,
        client = {
            image = 'police_tablet.png',
            export = 'ps-mdt.OpenMDT'
        },
    },
    ['mdtcitation'] = {
        label = 'Bloco de Citação MDT',
        description = 'Documento físico usado no fluxo de emissão de citação via MDT.',
        weight = 15,
        stack = true,
        consume = 0,
        close = false,
    },
}
