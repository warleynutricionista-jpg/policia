Config = Config or {}

Config.Debug = false
Config.Command = 'tribunal'
Config.OpenKeybind = 'F10'

Config.CaseTrigger = {
    defaultRequiredCases = 3,
    min = 1,
    max = 10,
}

Config.CourtCosts = {
    loserPays = 200000,
}

Config.CaseAreas = {
    familia = 'Vara de Família',
    trabalhista = 'Vara Trabalhista',
    geral = 'Processos Gerais',
    criminal = 'Vara Criminal',
}

Config.Roles = {
    judge = {
        label = 'Juiz',
        aces = { 'judiciary.role.judge' },
        can = {
            view = true,
            create = true,
            schedule = true,
            verdict = true,
            settings = true,
            defenseNotes = true,
        }
    },
    prosecutor = {
        label = 'Promotor',
        aces = { 'judiciary.role.promotor', 'judiciary.role.prosecutor' },
        can = {
            view = true,
            create = true,
            schedule = true,
            verdict = false,
            settings = false,
            defenseNotes = false,
        }
    },
    lawyer = {
        label = 'Advogado',
        aces = { 'judiciary.role.advogado', 'judiciary.role.lawyer' },
        can = {
            view = true,
            create = true,
            schedule = false,
            verdict = false,
            settings = false,
            defenseNotes = true,
            submitAnyCause = true,
        }
    }
}

Config.RoleByJob = {
    juiz = 'judge',
    promotor = 'prosecutor',
    advogado = 'lawyer',
}

Config.Statuses = {
    'aguardando_aceite',
    'rejeitado_entrada',
    'triagem',
    'audiencia_marcada',
    'em_julgamento',
    'sentenciado',
    'arquivado'
}
