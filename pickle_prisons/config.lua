Config = {}

-- =================== Opções Gerais ===================
Config.Debug = true
Config.Language = "pt-br"

-- Alvo/Target usado no servidor
Config.Target = "ox_target"

Config.RenderDistance    = 20.0
Config.InteractDistance  = 2.0
Config.UseTarget         = false
Config.NoModelTargeting  = true

Config.Marker = {
    enabled = true,
    id      = 2,
    scale   = 0.25,
    color   = { 255, 255, 255, 127 },
}

Config.NavigationDisplay = true
Config.ServeTimeOffline  = false
Config.EnableSneakout    = false

-- =================== XP (Pickle) =====================
Config.XPEnabled = true
Config.XPCategories = {
    strength = { label = "Força",     xpStart = 1000, xpFactor = 0.2, maxLevel = 100 },
    cooking  = { label = "Culinária", xpStart = 1000, xpFactor = 0.2, maxLevel = 100 },
}

-- =================== Permissões & Roupas =============
Config.Default = {
    permissions = {
        jail   = { jobs = { police = 0, corrections = 0 }, groups = { "admin", "god" } },
        unjail = { jobs = { police = 2, corrections = 2 }, groups = { "admin", "god" } },
        alert  = { jobs = { police = 0, corrections = 0 }, groups = { "admin", "god" } },
    },
    outfit = {
        male = {
            arms=0, tshirt_1=15, tshirt_2=0, torso_1=86, torso_2=0,
            bproof_1=0, bproof_2=0, decals_1=0, decals_2=0,
            chain_1=0, chain_2=0, pants_1=10, pants_2=2,
            shoes_1=56, shoes_2=0, helmet_1=14, helmet_2=0,
        },
        female = {
            arms=0, tshirt_1=15, tshirt_2=0, torso_1=86, torso_2=0,
            bproof_1=0, bproof_2=0, decals_1=0, decals_2=0,
            chain_1=0, chain_2=0, pants_1=10, pants_2=2,
            shoes_1=56, shoes_2=0, helmet_1=14, helmet_2=0,
        },
    },
}

-- =================== Atividades (labels traduzidos) ==
Config.Activities = {
    workout = {
        label = "Treino",
        sections = {
            lift = {
                label   = "Levantamento de Peso",
                rewards = { { type = "xp", name = "strength", amount = 1000 } },
                process = function(data)
                    local ped = PlayerPedId()
                    FreezeEntityPosition(ped, true)
                    SetEntityCoords(ped, data.coords.x, data.coords.y, data.coords.z - 1.0)
                    SetEntityHeading(ped, data.heading)
                    PlayAnim(ped, "amb@world_human_muscle_free_weights@male@barbell@base", "base", -8.0, 8.0, -1, 1, 1.0)
                    local prop = CreateProp(`prop_curl_bar_01`, data.coords.x, data.coords.y, data.coords.z + 1.0, true, true, false)
                    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, true, 2, true)
                    local ok
                    for i = 1, 3 do
                        ok = lib.skillCheck({ "easy", "medium", "easy" }, { "e" })
                        if not ok then break end
                        Wait(1000)
                    end
                    FreezeEntityPosition(ped, false)
                    ClearPedTasks(ped)
                    DeleteEntity(prop)
                    return ok
                end,
            },
            situp = {
                label   = "Abdominais",
                rewards = { { type = "xp", name = "strength", amount = 1000 } },
                process = function(data)
                    local ped = PlayerPedId()
                    FreezeEntityPosition(ped, true)
                    SetEntityCoords(ped, data.coords.x, data.coords.y, data.coords.z - 1.0)
                    SetEntityHeading(ped, data.heading)
                    PlayAnim(ped, "amb@world_human_sit_ups@male@idle_a", "idle_a", -8.0, 8.0, -1, 1, 1.0)
                    local ok
                    for i = 1, 3 do
                        ok = lib.skillCheck({ "easy", "medium", "easy" }, { "e" })
                        if not ok then break end
                        Wait(1000)
                    end
                    FreezeEntityPosition(ped, false)
                    ClearPedTasks(ped)
                    return ok
                end,
            },
            pushup = {
                label   = "Flexões",
                rewards = { { type = "xp", name = "strength", amount = 1000 } },
                process = function(data)
                    local ped = PlayerPedId()
                    FreezeEntityPosition(ped, true)
                    SetEntityCoords(ped, data.coords.x, data.coords.y, data.coords.z - 1.0)
                    SetEntityHeading(ped, data.heading)
                    PlayAnim(ped, "amb@world_human_push_ups@male@idle_a", "idle_d", -8.0, 8.0, -1, 1, 1.0)
                    local ok
                    for i = 1, 3 do
                        ok = lib.skillCheck({ "easy", "medium", "easy" }, { "e" })
                        if not ok then break end
                        Wait(1000)
                    end
                    FreezeEntityPosition(ped, false)
                    ClearPedTasks(ped)
                    return ok
                end,
            },
            pullup = {
                label   = "Barra Fixa",
                rewards = { { type = "xp", name = "strength", amount = 1000 } },
                process = function(data)
                    local ped = PlayerPedId()
                    FreezeEntityPosition(ped, true)
                    SetEntityCoords(ped, data.coords.x, data.coords.y, data.coords.z - 1.0)
                    SetEntityHeading(ped, data.heading)
                    TaskStartScenarioInPlace(ped, "prop_human_muscle_chin_ups", 0, -1)
                    Wait(3000)
                    local ok
                    for i = 1, 3 do
                        ok = lib.skillCheck({ "easy", "medium", "easy" }, { "e" })
                        if not ok then break end
                        Wait(1000)
                    end
                    FreezeEntityPosition(ped, false)
                    ClearPedTasks(ped)
                    return ok
                end,
            },
        },
    },

    clean = {
        label = "Limpeza da Prisão",
        sections = {
            sweep = {
                label   = "Varrer o Chão",
                rewards = { { type = "cash", amount = 50 } },
                process = function(data)
                    local ped = PlayerPedId()
                    FreezeEntityPosition(ped, true)
                    SetEntityCoords(ped, data.coords.x, data.coords.y, data.coords.z)
                    SetEntityHeading(ped, data.heading)
                    PlayAnim(ped, "anim@amb@drug_field_workers@rake@male_a@base", "base", -8.0, 8.0, -1, 1, 1.0)
                    local prop = CreateProp(`prop_tool_broom`, data.coords.x, data.coords.y, data.coords.z + 1.0, true, true, false)
                    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 28422), -0.01, 0.04, -0.03, 0.0, 0.0, 0.0, false, false, false, true, 2, true)
                    Wait(3000)
                    FreezeEntityPosition(ped, false)
                    ClearPedTasks(ped)
                    DeleteEntity(prop)
                    return true
                end,
            },
        },
    },

    kitchen = {
        label = "Trabalho na Cozinha",
        sections = {
            stock = {
                label   = "Coletar Ingredientes",
                rewards = nil,
                process = function(data)
                    local ped = PlayerPedId()
                    FreezeEntityPosition(ped, true)
                    SetEntityHeading(ped, data.heading)
                    PlayAnim(ped, "amb@world_human_stand_fire@male@idle_a", "idle_a", -8.0, 8.0, -1, 1, 1.0)
                    Wait(5000)
                    FreezeEntityPosition(ped, false)
                    ClearPedTasks(ped)
                    return true
                end,
            },
            cook = {
                label   = "Cozinhar",
                rewards = nil,
                process = function(data)
                    local ped = PlayerPedId()
                    FreezeEntityPosition(ped, true)
                    SetEntityHeading(ped, data.heading)
                    TaskStartScenarioInPlace(ped, "PROP_HUMAN_BBQ", 0, 1)
                    local ok
                    for i = 1, 3 do
                        ok = lib.skillCheck({ "easy", "medium", "easy" }, { "e" })
                        if not ok then break end
                        Wait(1000)
                    end
                    FreezeEntityPosition(ped, false)
                    ClearPedTasks(ped)
                    return ok
                end,
            },
            toppings = {
                label   = "Adicionar Coberturas",
                rewards = nil,
                process = function(data)
                    local ped = PlayerPedId()
                    FreezeEntityPosition(ped, true)
                    SetEntityHeading(ped, data.heading)
                    PlayAnim(ped, "amb@world_human_stand_fire@male@idle_a", "idle_a", -8.0, 8.0, -1, 1, 1.0)
                    Wait(5000)
                    FreezeEntityPosition(ped, false)
                    ClearPedTasks(ped)
                    return true
                end,
            },
            delivery = {
                label   = "Entregar Comida",
                rewards = {
                    { type = "cash",   amount = 200 },
                    { type = "xp",     name = "cooking", amount = 1000 },
                },
                process = function(data)
                    local ped  = PlayerPedId()
                    local prop = GetActivityEntity and GetActivityEntity("tray") or nil
                    if not prop then
                        prop = CreateProp(`prop_food_tray_03`, data.coords.x, data.coords.y, data.coords.z + 1.0, true, true, false)
                        if AddActivityEntity then AddActivityEntity("tray", prop) end
                        AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, true, 2, true)
                    end
                    FreezeEntityPosition(ped, true)
                    SetEntityHeading(ped, data.heading)
                    PlayAnim(ped, "mini@repair", "fixing_a_ped", -8.0, 8.0, -1, 1, 1.0)
                    Wait(500)
                    DetachEntity(prop, true, true)
                    FreezeEntityPosition(prop, true)
                    PlaceObjectOnGroundProperly(prop)
                    SetEntityHeading(prop, data.heading)
                    Wait(1000)
                    FreezeEntityPosition(ped, false)
                    ClearPedTasks(ped)
                    if DeleteActivityEntity then DeleteActivityEntity("tray") else DeleteEntity(prop) end
                    return true
                end,
            },
        },
    },
}

-- =================== Itens não confiscados =============
Config.UnrevokedItems = { "burguer", "water_bottle", "cash", "money" }

-- =================== Breakout (processo de cavar) =====
Config.Breakout = {
    alert  = true,
    time   = 120,
    model  = { modelType = "prop", hash = `prop_rock_1_i`, offset = vector3(0.0, 0.0, -0.2) },
    required = {
        { type = "item", name = "shovel", amount = 1 }, -- item interno da pá
    },
    process = function(data)
        local ped = PlayerPedId()
        FreezeEntityPosition(ped, true)
        SetEntityCoords(ped, data.coords.x, data.coords.y, data.coords.z - 1.0)
        SetEntityHeading(ped, data.heading)
        PlayAnim(ped, "random@burial", "a_burial", -8.0, 8.0, -1, 1, 1.0)
        local prop = CreateProp(`prop_tool_shovel`, data.coords.x, data.coords.y, data.coords.z + 1.0, true, true, false)
        AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, true, 2, true)
        local ok
        for i = 1, 3 do
            ok = lib.skillCheck({ "easy", "medium", "easy" }, { "e" })
            if not ok then break end
            Wait(1000)
        end
        FreezeEntityPosition(ped, false)
        ClearPedTasks(ped)
        DeleteEntity(prop)
        return ok
    end,
}

-- =================== Alertas sirene =====================
Config.Alerts = function(index, disabled)
    local prison = Config.Prisons[index]
    if not disabled then
        ShowNotification("A sirene da prisão foi ativada em " .. (prison.label or "Prisão") .. "!")
    else
        ShowNotification("A sirene da prisão foi desligada em " .. (prison.label or "Prisão") .. ".")
    end
end

-- =================== PRISÃO (seu mapa) =================
Config.Prisons = {
    default = {
        label  = "Presídio República",
        coords = vector3(3906.20, 30.97, 39.49),
        radius = 250.0,
        permissions = nil,
        outfit      = nil,

        blip = {
            label = "Presídio República",
            coords = vector3(3906.20, 30.97, 39.49),
            id    = 188,
            color = 44,
            scale = 0.85,
        },

        hospital = { coords = vector3(4025.00, -1.73, 18.58), heading = 284.22 },
        release  = { coords = vector3(3867.21, -22.20, 6.43), heading = 231.70 },

        -- ========== FUGA (com teleport interno do túnel) ==========
        breakout = {
            -- 1) Iniciar escavação no pátio/área
            start = {
                label  = "Iniciar Escavação",
                coords = vector3(3992.78, 54.37, 22.34),
                heading = 328.08
            },
            -- 2) Entrada do túnel (teleporta para o início do túnel)
            enter = {
                label   = "Entrar no Túnel",
                coords  = vector3(3882.89, 18.73, 23.89),  -- ponto dentro da prisão
                heading = 326.59,
                teleportTo = {
                    coords  = vector3(-531.2, 1901.51, 123.02), -- INÍCIO do túnel
                    heading = 243.49
                }
            },
            -- 3) Perto da saída interna do túnel (teleporta para fora)
            leave = {
                label   = "Saída do Túnel",
                coords  = vector3(-482, 1894.76, 119.74),   -- fim do túnel
                heading = 275.74,
                teleportTo = {
                    coords  = vector3(3867.21, -22.20, 6.43),   -- fora do presídio
                    heading = 231.70
                }
            },
            -- 4) Finalizar fuga (opcional, marcador fora)
            finish = {
                label  = "Fugir",
                coords = vector3(3867.21, -22.20, 6.43),
                heading = 231.70
            },
        },

        -- ========== ATIVIDADES ==========
        activities = {
            {
                name    = "workout",  -- chave interna = Config.Activities
                model   = { hash = `u_m_y_prisoner_01` },
                coords  = vector3(3942.56, 56.81, 22.34),
                heading = 12.65,
                zOffset = 0.00,
                randomSection = true,
                sections = {
                    { name = "lift",   coords = vector3(3948.83, 47.42, 22.35), heading = 112.27 },
                    { name = "situp",  coords = vector3(3948.42, 50.02, 22.74), heading = 190.68 },
                    { name = "pushup", coords = vector3(3954.38, 48.17, 22.35), heading = 134.98 },
                    { name = "pullup", coords = vector3(3955.89, 56.19, 22.35), heading = 199.18 },
                },
            },
            {
                name    = "clean",
                model   = { hash = `u_m_y_prisoner_01` },
                coords  = vector3(3912.68, 33.37, 23.89),
                heading = 39.63,
                zOffset = 0.00,
                randomSection = true,
                sections = {
                    { name = "sweep", coords = vector3(3907.41, 21.87, 23.89), heading =  90.01 },
                    { name = "sweep", coords = vector3(3900.99, 22.48, 23.89), heading =  90.08 },
                    { name = "sweep", coords = vector3(3895.58, 23.11, 23.89), heading =  85.85 },
                    { name = "sweep", coords = vector3(3886.20, 21.53, 23.89), heading =  27.55 },
                    { name = "sweep", coords = vector3(3885.30, 30.98, 23.89), heading = 271.99 },
                    { name = "sweep", coords = vector3(3897.84, 29.36, 23.89), heading = 256.29 },
                    { name = "sweep", coords = vector3(3905.76, 28.30, 23.89), heading = 270.53 },
                    -- piso superior
                    { name = "sweep", coords = vector3(3902.19, 22.20, 27.43), heading = 137.99 },
                    { name = "sweep", coords = vector3(3895.20, 29.85, 27.43), heading = 260.51 },
                    { name = "sweep", coords = vector3(3890.33, 23.12, 27.43), heading = 249.25 },
                    { name = "sweep", coords = vector3(3902.50, 29.49, 27.43), heading = 262.30 },
                },
            },
            {
                name    = "kitchen",
                model   = { hash = `s_m_y_chef_01` },
                coords  = vector3(3927.48, 31.88, 23.89),
                heading = 173.87,
                zOffset = 0.00,
                randomSection = false,
                sections = {
                    { name = "stock",    coords = vector3(3920.18, 33.89, 23.89), heading =  87.11 },
                    { name = "cook",     coords = vector3(3920.38, 32.02, 23.89), heading =  86.29 },
                    { name = "toppings", coords = vector3(3920.86, 32.48, 23.89), heading = 267.61 },
                    { name = "delivery", coords = vector3(3924.62, 28.58, 23.89), heading = 325.94 },
                },
            },
        },

        -- ========== CELAS (18) ==========
        cells = {
            { coords = vector3(3908.35, 18.29, 22.89), heading = 0.0, size = 1.5 },
            { coords = vector3(3904.81, 18.91, 22.89), heading = 0.0, size = 1.5 },
            { coords = vector3(3897.65, 19.40, 22.89), heading = 0.0, size = 1.5 },
            { coords = vector3(3893.92, 19.52, 22.89), heading = 0.0, size = 1.5 },
            { coords = vector3(3890.77, 19.98, 22.89), heading = 0.0, size = 1.5 },
            { coords = vector3(3895.07, 32.55, 22.89), heading = 0.0, size = 1.5 },
            { coords = vector3(3898.67, 32.09, 22.89), heading = 0.0, size = 1.5 },
            { coords = vector3(3905.65, 31.51, 22.89), heading = 0.0, size = 1.5 },
            { coords = vector3(3909.28, 31.78, 22.89), heading = 0.0, size = 1.5 },
            { coords = vector3(3895.29, 33.30, 26.43), heading = 0.0, size = 1.5 },
            { coords = vector3(3898.90, 32.36, 26.43), heading = 0.0, size = 1.5 },
            { coords = vector3(3905.86, 32.27, 26.43), heading = 0.0, size = 1.5 },
            { coords = vector3(3909.40, 31.91, 26.43), heading = 0.0, size = 1.5 },
            { coords = vector3(3908.22, 18.73, 26.43), heading = 0.0, size = 1.5 },
            { coords = vector3(3904.66, 19.36, 26.43), heading = 0.0, size = 1.5 },
            { coords = vector3(3897.67, 19.67, 26.43), heading = 0.0, size = 1.5 },
            { coords = vector3(3894.15, 19.95, 26.43), heading = 0.0, size = 1.5 },
            { coords = vector3(3890.53, 20.29, 26.43), heading = 0.0, size = 1.5 },
        },

        -- ========== LOJAS ==========
        -- ui.showCashAsValue: true => mostra "Valor: $X" (cantina)
        --                      false => não mostra o valor no texto (fornecedor)
        stores = {
            {
                label   = "Cantina da Prisão",
                coords  = vector3(3921.97, 27.07, 22.89),
                heading = 270.0,
                model   = { hash = `s_m_y_chef_01` },
                zOffset = 0.04,
                ui      = { showCashAsValue = true },
                catalog = {
                    {
                        name = "burguer",
                        label = "Hambúrguer",
                        description = "Hambúrguer da cantina.",
                        amount = 1,
                        required = { { type = "cash", amount = 100 } }
                    },
                    {
                        name = "water_bottle",
                        label = "Água",
                        description = "Água mineral gelada.",
                        amount = 1,
                        required = { { type = "cash", amount = 100 } }
                    },
                },
            },
            {
                label   = "Fornecedor (Prisão)",
                coords  = vector3(3980.51, 29.94, 21.34),
                heading = 270.0,
                model   = { hash = `s_m_y_prisoner_01` },
                zOffset = 0.04,
                ui      = { showCashAsValue = false },  -- oculta preço na descrição
                catalog = {
                    {
                        name = "WEAPON_SWITCHBLADE",
                        label = "Canivete",
                        description = "Canivete dobrável.",
                        amount = 1,
                        required = {
                            { type = "item", name = "wood",       amount = 1 },
                            { type = "item", name = "metalscrap", amount = 1 },
                        }
                    },
                    {
                        name = "shovel",
                        label = "Pá",
                        description = "Pá robusta para serviço pesado.",
                        amount = 1,
                        required = {
                            { type = "item", name = "wood",       amount = 1 },
                            { type = "item", name = "metalscrap", amount = 1 },
                            { type = "item", name = "rope",       amount = 1 },
                            { type = "cash", amount = 600 },
                        }
                    },
                },
            },
        },

        -- ========== LOOT ==========
        lootables = {
            {
                label = "Madeira",
                coords = vector3(3919.13, 27.96, 22.89),
                heading = 0.0,
                model = { modelType = "prop", hash = `prop_cons_plank` },
                regenTime = 5,
                rewards = { { type = "item", name = "wood", amount = 1 } },
            },
            {
                label = "Metal",
                coords = vector3(3927.12, 25.29, 23.72),
                heading = 0.0,
                model = { modelType = "prop", hash = `prop_ladel`, offset = vector3(0.0, 0.0, 1.0) },
                regenTime = 5,
                rewards = { { type = "item", name = "metalscrap", amount = 1 } },
            },
            {
                label = "Corda",
                coords = vector3(3919.32, 23.95, 24.20),
                heading = 0.0,
                model = { modelType = "prop", hash = `prop_rope_family_3` },
                regenTime = 5,
                rewards = { { type = "item", name = "rope", amount = 1 } },
            },
            {
                label = "Sucata",
                coords = vector3(3941.42, 18.12, 24.51),
                heading = 0.0,
                model = { modelType = "prop", hash = `prop_ladel`, offset = vector3(0.0, 0.0, 1.0) },
                regenTime = 5,
                rewards = { { type = "item", name = "metalscrap", amount = 1 } },
            },
        },
    },
}
