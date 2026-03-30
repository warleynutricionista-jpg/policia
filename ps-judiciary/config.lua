Config = Config or {}

Config.Debug = false
Config.Command = 'tribunal'
Config.OpenKeybind = 'F10'

Config.CaseTrigger = {
    defaultRequiredCases = 3,
    min = 1,
    max = 10,
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
            create = false,
            schedule = false,
            verdict = false,
            settings = false,
            defenseNotes = true,
        }
    }
}

Config.RoleByJob = {
    juiz = 'judge',
    promotor = 'prosecutor',
    advogado = 'lawyer',
}

Config.Statuses = {
    'triagem',
    'audiencia_marcada',
    'em_julgamento',
    'sentenciado',
    'arquivado'
}
