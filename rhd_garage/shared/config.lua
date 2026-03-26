Config = {}

-- Carregamento de dados de garagens e nomes customizados
GarageZone = lib.loadJson('data.garages')          ---@type table<string, GarageData>
CNV        = lib.loadJson('data.vehiclesname')     ---@type table<string, CustomName>

----------------------------------------------------------
-- CONFIGURAÇÃO GERAL
----------------------------------------------------------

Config.Target               = 'ox'           -- 'ox' / 'qb'
Config.RadialMenu           = 'ox'           -- 'ox' / 'qb' / 'rhd'
Config.FuelScript           = 'cdn-fuel'     -- 'rhd_fuel' / 'ox_fuel' / 'LegacyFuel' / 'ps-fuel' / 'cdn-fuel'

Config.changeNamePrice      = 15000          -- preço para trocar nome do veículo
Config.SpawnInVehicle       = false          -- true = player entra no carro ao spawnar
Config.VehiclesInAllGarages = false          -- true = todos os veículos aparecem em todas as garagens
Config.DisableVehicleCamera = false          -- desativa câmera ao puxar veículo
Config.LocateVehicleOutGarage = true         -- permite localizar veículos fora da garagem

-- Extras (requer ox_target ou qb-target)
Config.UseJobVechileShop    = false          -- loja de veículos de trabalho
Config.UsePoliceImpound     = true           -- sistema de apreensão / pátio da polícia

Config.InDevelopment        = true           -- desligar quando terminar configuração do script

----------------------------------------------------------
-- TRANSFERÊNCIA / TROCA DE GARAGEM / CHAVES
----------------------------------------------------------

Config.TransferVehicle = {
    enable = true,
    price  = 100
}

Config.SwapGarage = {
    enable = true,
    price  = 500
}

Config.GiveKeys = {
    tempkeys = false,   -- se true, as chaves são temporárias
    enable   = true,
    onspawn  = true,    -- dá chave automaticamente ao spawnar o veículo pela garagem
    price    = 500
}

----------------------------------------------------------
-- ÍCONES E ANIMAÇÕES
----------------------------------------------------------

Config.IconAnimation = 'fade'   -- animação de ícones em menus (lib)

-- Ícones por tipo de veículo (usado em contextos / menus)
Config.Icons = {
    [8]  = 'motorcycle',
    [13] = 'bicycle',
    [14] = 'sailboat',
    [15] = 'helicopter',
    [16] = 'plane',
}

----------------------------------------------------------
-- PREÇOS DE APREENSÃO POR TIPO DE VEÍCULO
----------------------------------------------------------

Config.ImpoundPrice = {
    [0]  = 15000,
    [1]  = 15000,
    [2]  = 15000,
    [3]  = 15000,
    [4]  = 15000,
    [5]  = 15000,
    [6]  = 15000,
    [7]  = 15000,
    [8]  = 15000,
    [9]  = 15000,
    [10] = 15000,
    [11] = 15000,
    [12] = 15000,
    [13] = 15000,
    [14] = 15000,
    [15] = 15000,
    [16] = 15000,
    [17] = 15000,
    [18] = 0,
    [19] = 15000,
    [20] = 15000,
    [21] = 0
}

-- Valor padrão usado no client caso não venha nada da DB
Config.ImpoundPriceDefault = 15000

----------------------------------------------------------
-- APREENSÃO PELA POLÍCIA (ON-TARGET NO VEÍCULO)
-- Aqui só definimos quais jobs podem apreender e quais
-- "pátios" existem na lista para o input da polícia.
----------------------------------------------------------

Config.PoliceImpound = {
    Target = {
        groups = {
            police = 0,  -- job = 'police', grau mínimo 0
            -- sheriff = 0, etc (se quiser adicionar mais)
        }
    },

    -- Esta lista é usada APENAS para o inputDialog na hora
    -- de APREENDER (escolher para qual pátio vai). O label
    -- precisa bater com o Label do pátio em Config.Impounds.
    location = {
        [1] = {
            label = 'Pátio do Detran',
        },
        -- se no futuro tiver outro pátio:
        -- [2] = { label = 'Pátio de Sandy Shores' },
    }
}

----------------------------------------------------------
-- PÁTIOS / DETRAN (RETIRO DO VEÍCULO)
-- Esses dados são usados pelo client para:
--  - Criar o ped do Detran
--  - Criar o blip no mapa
--  - Definir posição de spawn do veículo apreendido
----------------------------------------------------------

---@class ImpoundData
---@field Visible       boolean
---@field Type          string       -- 'car' | 'air' | 'boat' (apenas informativo por enquanto)
---@field Label         string
---@field Position      vector3      -- posição do blip / referência do pátio
---@field PedPosition   vector4      -- posição do ped que abre o menu
---@field Model         number|string-- modelo do ped
---@field SpawnPosition vector4      -- onde o veículo vai aparecer

---@type ImpoundData[]
Config.Impounds = {
    [1] = {
        Visible       = true,
        Type          = 'car',
        Label         = 'Pátio do Detran',

        -- Posição geral do pátio (usada pro blip)
        Position      = vec3(827.20, -1343.03, 26.00),

        -- Posição do ped que vai abrir o menu do pátio
        -- (ajusta se quiser deixar mais "bonitinho")
        PedPosition   = vec4(830.6, -1310.44, 28.26, 175.59),

        -- Modelo do ped do Detran
        Model         = `s_m_m_armoured_01`,

        -- Posição onde o carro vai ser spawnado ao retirar
        SpawnPosition = vec4(829.21, -1345.88, 26.09, 64.01),
    },
}

----------------------------------------------------------
-- LOJA DE VEÍCULOS DE TRABALHO (OPCIONAL)
----------------------------------------------------------

Config.JobVehicleShop = {
    {
        job   = 'police',
        label = 'Police Vehicle Shop',
        ped   = {
            model  = 'csb_trafficwarden',
            coords = vec(457.9160, -1026.4635, 28.4376, 57.2678)
        },
        spawn = vec(443.9391, -1021.4270, 28.2857, 92.6928),
        vehicle = {
            police = {
                price       = 500,
                label       = 'Police 1',
                prefixPlate = 'POL',
                forRank     = {
                    [0] = true,
                    [1] = true,
                    [2] = true
                }
            },
            police2 = {
                price       = 500,
                label       = 'Police 2',
                prefixPlate = 'POL',
                forRank     = {
                    [0] = true,
                    [1] = true,
                    [2] = true
                }
            }
        },
    }
}

----------------------------------------------------------
-- NÃO ALTERAR
----------------------------------------------------------

Config.HouseGarages = {}
