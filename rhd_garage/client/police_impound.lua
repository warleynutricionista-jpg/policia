if not Config.UsePoliceImpound then
    return
end

local Deformation = require 'modules.deformation'
local VehicleShow = nil

PoliceImpound = PoliceImpound or {}

-------------------------------------------------
-- HELPERS GERAIS
-------------------------------------------------

local function deletePreviewVehicle()
    if VehicleShow and DoesEntityExist(VehicleShow) then
        SetEntityAsMissionEntity(VehicleShow, true, true)
        DeleteVehicle(VehicleShow)
    end
    VehicleShow = nil
end

local function giveVehicleKeys(veh, plate)
    if not plate or plate == '' then return end
    plate = utils.string.trim(plate)

    if GetResourceState('qb-vehiclekeys') == 'started' then
        TriggerEvent('qb-vehiclekeys:client:AddKeys', plate)
    elseif GetResourceState('qbx_vehiclekeys') == 'started' then
        local netId = NetworkGetNetworkIdFromEntity(veh)
        TriggerEvent('qbx_vehiclekeys:client:GiveKeys', netId or plate)
    elseif GetResourceState('vehiclekeys') == 'started' then
        TriggerEvent('vehiclekeys:client:SetOwner', plate)
    else
        -- fallback genérico
        TriggerEvent('vehiclekeys:client:SetOwner', plate)
    end
end

---@param data { props?: table, coords?: vector4, plate: string, deformation?: table }
---@param spawnPos? vector4
local function spawnImpoundVehicle(data, spawnPos)
    if not data or not data.plate then
        return print('^1[rhd_garage] spawnImpoundVehicle chamado sem plate válido.^0')
    end

    local plate  = utils.string.trim(data.plate)
    local coords = spawnPos or vec4(GetEntityCoords(cache.ped), GetEntityHeading(cache.ped))

    print(('[rhd_garage] spawnImpoundVehicle | plate=%s'):format(plate))

    -- Busca dados completos do veículo no servidor
    local vehData = lib.callback.await('rhd_garage:cb_server:getvehiclePropByPlate', false, plate) or {}

    local props     = data.props or vehData.props or {}
    local baseModel = (props and props.model) or vehData.model or vehData.vehicle

    if not baseModel then
        print(('[rhd_garage] Não foi possível determinar o modelo do veículo (%s).'):format(plate))
        utils.notify('Não foi possível determinar o modelo do veículo para spawn.', 'error')
        return
    end

    local vehEntity = utils.createPlyVeh(baseModel, coords, false, true, vehData.mods)
    if not vehEntity or not DoesEntityExist(vehEntity) then
        utils.notify('Falha ao spawnar o veículo apreendido.', 'error')
        return
    end

    SetVehicleOnGroundProperly(vehEntity)

    -- Aplica propriedades (props) salvas, se existirem
    if props and next(props) and vehFunc and vehFunc.svp then
        pcall(vehFunc.svp, vehEntity, props)
    elseif vehData.props and vehFunc and vehFunc.svp then
        pcall(vehFunc.svp, vehEntity, vehData.props)
    end

    -- Ajusta status mecânico (com fallback)
    local engine = vehData.engine or props.engineHealth or 1000.0
    local body   = vehData.body   or props.bodyHealth   or 1000.0
    local fuel   = vehData.fuel   or props.fuelLevel    or 50.0

    SetVehicleEngineHealth(vehEntity, engine + 0.0)
    SetVehicleBodyHealth(vehEntity, body + 0.0)
    utils.setFuel(vehEntity, fuel)

    -- Dano de deformação (se tiver)
    local deformation = data.deformation or vehData.deformation
    if deformation and next(deformation) then
        pcall(Deformation.set, vehEntity, deformation)
    end

    if Config.SpawnInVehicle then
        TaskWarpPedIntoVehicle(cache.ped, vehEntity, -1)
    end

    -- Remove do pátio no servidor
    TriggerServerEvent('rhd_garage:server:removeFromPoliceImpound', plate)

    -- Dar chave
    giveVehicleKeys(vehEntity, plate)

    utils.notify('Veículo retirado do pátio da polícia.', 'success')
end

-------------------------------------------------
-- MENU DO PÁTIO (USADO PELO PED DO DETRAN)
-------------------------------------------------
-- Usa Config.Impounds[index] (definido no config).

local function openImpoundMenu(index)
    local impounds = Config.Impounds or {}
    local loc      = impounds[index]

    if not loc then
        print(('[rhd_garage] openImpoundMenu chamado com índice inválido: %s'):format(tostring(index)))
        return utils.notify('Local de pátio inválido.', 'error')
    end

    local label = loc.Label or 'Pátio do Detran'
    print(('[rhd_garage] openImpoundMenu | idx=%d | label="%s"'):format(index, label))

    -- Busca TODOS os veículos da tabela police_impound
    -- (o servidor pode filtrar por owner depois, se quiser)
    local impoundedVehicles = lib.callback.await(
        'rhd_garage:cb_server:policeImpound.getVehicle',
        false,
        '' -- string vazia = sem filtro por garagem
    ) or {}

    print(('[rhd_garage] openImpoundMenu | recebidos %d veículo(s) do servidor.'):format(#impoundedVehicles))

    local context = {
        id      = ('rhd_garage:policeImpound:%d'):format(index),
        title   = label:upper(),
        onBack  = deletePreviewVehicle,
        onExit  = deletePreviewVehicle,
        options = {}
    }

    if #impoundedVehicles == 0 then
        context.options[1] = {
            title    = 'Não há veículos apreendidos.',
            disabled = true
        }
        utils.createMenu(context)
        return
    end

    for _, v in ipairs(impoundedVehicles) do
        local citizenid   = v.citizenid
        local props       = v.props or {}
        local deformation = v.deformation
        local plate       = v.plate
        local vehname     = v.vehicle or (props.model and tostring(props.model)) or 'Veículo'
        local owner       = v.owner or '-'
        local officer     = v.officer or '-'
        local fine        = tonumber(v.fine) or (Config.ImpoundPriceDefault or 10000)
        local paid        = tonumber(v.paid) or 0
        local date        = v.date or '-'

        local paidstatus = locale('context.policeImpound.not_paid')
        if paid > 0 then
            paidstatus = locale('context.policeImpound.paid')
        end

        context.options[#context.options+1] = {
            title       = ('%s [%s]'):format(vehname, (plate or ''):upper()),
            description = locale('context.policeImpound.vehdescription', fine, paidstatus),
            metadata    = {
                OWNER          = owner,
                OFFICER        = officer,
                ['PICKUP DATE'] = date,
            },
            iconAnimation = Config.IconAnimation,
            onSelect = function()
                deletePreviewVehicle()

                -- Posição de spawn definida no config
                local spawnPos = loc.SpawnPosition or vec4(GetEntityCoords(cache.ped), GetEntityHeading(cache.ped))
                local spawnVec3 = vec3(spawnPos.x, spawnPos.y, spawnPos.z)

                -- checa se já tem carro no spawn
                local already = lib.getClosestVehicle(spawnVec3)
                if DoesEntityExist(already)
                and #(GetEntityCoords(already) - spawnVec3) < 3.0
                then
                    return utils.notify(locale('notify.error.no_parking_spot'), 'error')
                end

                -----------------------------------------------------
                -- 1) SE NÃO FOI PAGO, ABRE FLUXO DE PAGAMENTO AQUI
                -----------------------------------------------------
                if paid < 1 then
                    print(('[rhd_garage] Veículo %s ainda não pago. Abrindo fluxo de multa.'):format(plate))

                    local wantPay = lib.alertDialog({
                        header   = locale('input.police_impound.fine_header', fw.gn()),
                        content  = locale('input.police_impound.fine_content', lib.math.groupdigits(fine, '.')),
                        centered = true,
                        cancel   = true,
                        labels   = {
                            confirm = locale('input.police_impound.fine_pay'),
                            cancel  = locale('input.police_impound.fine_ignore')
                        }
                    })

                    if wantPay ~= 'confirm' then
                        print('[rhd_garage] Jogador optou por NÃO pagar a multa.')
                        return
                    end

                    local pago  = false
                    local done  = false

                    utils.createMenu({
                        id    = 'rhd_garage:policeImpound.payoptions',
                        title = locale('context.insurance.pay_methode_header'):upper(),
                        onExit = function()
                            done = true
                        end,
                        options = {
                            {
                                title         = locale('context.insurance.pay_methode_cash_title'):upper(),
                                icon          = 'dollar-sign',
                                iconAnimation = Config.IconAnimation,
                                description   = locale('context.insurance.pay_methode_cash_title_desc'),
                                onSelect      = function()
                                    if fw.gm('cash') < fine then
                                        utils.notify(locale('notify.error.not_enough_cash'), 'error')
                                        done = true
                                        return
                                    end

                                    local success = lib.callback.await(
                                        'rhd_garage:cb_server:removeMoney',
                                        false,
                                        'cash',
                                        fine
                                    )

                                    if success then
                                        pago = true
                                        utils.notify('Você pagou a multa do seu veículo em DINHEIRO.', 'success')
                                    else
                                        utils.notify('Não foi possível cobrar o valor em dinheiro.', 'error')
                                    end

                                    done = true
                                end
                            },
                            {
                                title         = locale('context.insurance.pay_methode_bank_title'):upper(),
                                icon          = 'fab fa-cc-mastercard',
                                iconAnimation = Config.IconAnimation,
                                description   = locale('context.insurance.pay_methode_bank_title_desc'),
                                onSelect      = function()
                                    if fw.gm('bank') < fine then
                                        utils.notify(locale('notify.error.not_enough_bank'), 'error')
                                        done = true
                                        return
                                    end

                                    local success = lib.callback.await(
                                        'rhd_garage:cb_server:removeMoney',
                                        false,
                                        'bank',
                                        fine
                                    )

                                    if success then
                                        pago = true
                                        utils.notify('Você pagou a multa do seu veículo via BANCO.', 'success')
                                    else
                                        utils.notify('Não foi possível cobrar o valor no banco.', 'error')
                                    end

                                    done = true
                                end
                            }
                        },
                    })

                    while not done do
                        Wait(100)
                    end

                    if not pago then
                        print('[rhd_garage] Pagamento não concluído. Não marcar como pago.')
                        return
                    end

                    -- Marca como pago no banco
                    TriggerServerEvent('rhd_garage:server:policeImpound.markAsPaid', plate)
                    print(('[rhd_garage] Evento markAsPaid enviado para plate=%s'):format(tostring(plate)))

                    paid      = 1
                    paidstatus = locale('context.policeImpound.paid')
                    utils.notify('Multa paga com sucesso. Agora você já pode retirar o veículo quando o prazo de confisco permitir.', 'success')
                end

                -----------------------------------------------------
                -- 2) CHECA PRAZO DE CONFISCO (APÓS ESTAR PAGO)
                -----------------------------------------------------
                local canTake, daysLeft = lib.callback.await(
                    'rhd_garage:cb_server:policeImpound.cekDate',
                    false,
                    date
                )

                if not canTake and daysLeft and daysLeft > 0 then
                    utils.notify(
                        ('Ainda faltam %s dia(s) de confisco para este veículo.'):format(daysLeft),
                        'error'
                    )
                    return
                end

                -----------------------------------------------------
                -- 3) TUDO CERTO → SPAWNAR VEÍCULO
                -----------------------------------------------------
                local data = {
                    props       = props,
                    plate       = plate,
                    deformation = deformation
                }

                spawnImpoundVehicle(data, spawnPos)
            end
        }
    end

    utils.createMenu(context)
end

-------------------------------------------------
-- APREENDER VEÍCULO (POLÍCIA) – MESMA LÓGICA
-------------------------------------------------

local function checkAvailableGarage()
    local AvailableGarage = {}

    for _, v in pairs(Config.PoliceImpound.location) do
        AvailableGarage[#AvailableGarage+1] = {
            label = v.label,
            value = v.label
        }
    end

    return AvailableGarage
end

local function impoundVehicle(vehicle)
    local vehprop    = vehFunc.gvp(vehicle)
    local plate      = utils.string.trim(vehprop.plate)
    local vehdata    = vehFunc.gvibp(plate)
    local garageList = checkAvailableGarage()

    if not vehdata then
        return utils.notify(locale('notify.error.npc_vehicle'), 'error')
    end

    if #garageList < 1 then
        return utils.notify(locale('no_available_policeimpound_location'), 'error', 12000)
    end

    local vehName       = vehdata.vehicle_name or fw.gvn(vehdata.vehicle)
    local customvehName = CNV[plate] and CNV[plate].name
    local vehlabel      = customvehName or vehName

    local owner          = vehdata.owner
    local ownerName      = owner.name
    local ownerCitizenid = owner.citizenid
    local officerName    = fw.gn()

    local input = lib.inputDialog(('%s [%s]'):format(vehlabel, plate:upper()), {
        { type = 'input',  label = locale('input.police_impound.veh_owner'), placeholder = ownerName:upper(), disabled = true },
        { type = 'number', label = locale('input.police_impound.fine'), required = true, default = 10000, min = 1, max = 1000000 },
        { type = 'select', label = locale('input.police_impound.confiscate_garage_loc'), options = garageList, default = garageList[1].value },
        { type = 'date',   label = locale('input.police_impound.confiscate_until'), icon = {'far', 'calendar'}, default = true, format = 'DD/MM/YYYY' }
    })

    if not input then
        return
    end

    local sendToServer = {
        citizenid   = ownerCitizenid,
        owner       = ownerName,
        officer     = officerName,
        fine        = input[2],
        garage      = input[3],
        prop        = vehprop,
        plate       = plate,
        vehicle     = vehlabel,
        date        = math.floor(input[4] / 1000),
        deformation = Deformation.get(vehicle)
    }

    local ok = lib.progressBar({
        duration     = 5000,
        label        = locale('progressbar.confiscate_vehicle'),
        useWhileDead = false,
        canCancel    = true,
        disable = {
            move   = true,
            car    = true,
            combat = true,
            mouse  = false,
        },
        anim = {
            dict = 'missheistdockssetup1clipboard@base',
            clip = 'base',
            flags = 1
        },
        prop = {
            {
                model = 'prop_notepad_01',
                bone  = 18905,
                pos   = { x = 0.1,  y = 0.02, z = 0.05 },
                rot   = { x = 10.0, y = 0.0,  z = 0.0 },
            },
            {
                model = 'prop_pencil_01',
                bone  = 58866,
                pos   = { x = 0.11, y = -0.02, z = 0.001 },
                rot   = { x = -120.0, y = 0.0, z = 0.0 },
            },
        },
    })

    if not ok then
        ClearPedTasks(cache.ped)
        return
    end

    lib.callback('rhd_garage:cb_server:policeImpound.impoundveh', false, function(success)
        if success then
            SetEntityAsMissionEntity(vehicle, true, true)
            DeleteVehicle(vehicle)
            utils.notify(locale('notify.success.confiscate_vehicle', ownerName, input[3]), 'success')
        else
            utils.notify('Falha ao apreender veículo no servidor.', 'error')
        end
    end, sendToServer)

    ClearPedTasks(cache.ped)
end

-------------------------------------------------
-- TARGET (OX / QB) PARA APREENDER VEÍCULO
-------------------------------------------------

local function setUpTarget()
    local bones = {
        'door_dside_f', 'seat_dside_f',
        'door_pside_f', 'seat_pside_f',
        'door_dside_r', 'seat_dside_r',
        'door_pside_r', 'seat_pside_r',
        'bonnet', 'boot'
    }

    local TargetData  = Config.PoliceImpound.Target
    local TargetLabel = locale('target.confiscate_veh')

    if Config.Target == 'ox' then
        print('[rhd_garage] Registrando alvo global de veículo (ox_target) para apreensão.')
        exports.ox_target:addGlobalVehicle({
            {
                label    = TargetLabel,
                icon     = 'fas fa-car',
                groups   = TargetData.groups,
                onSelect = function(data)
                    impoundVehicle(data.entity)
                end,
                distance = 2.5
            }
        })
    elseif Config.Target == 'qb' then
        print('[rhd_garage] Registrando alvo de veículo (qb-target) para apreensão.')
        exports['qb-target']:AddTargetBone(bones, {
            options = {
                {
                    icon   = 'fas fa-car',
                    label  = TargetLabel,
                    action = function(veh)
                        impoundVehicle(veh)
                    end,
                    job      = TargetData.groups,
                    distance = 1.5
                }
            }
        })
    end
end

-------------------------------------------------
-- CRIAÇÃO DOS PEDS / BLIPS DO PÁTIO
-------------------------------------------------

local function createImpoundPeds()
    local impounds = Config.Impounds or {}
    if not next(impounds) then
        print('[rhd_garage] Nenhum Config.Impounds definido. Pátio não será criado.')
        return
    end

    for idx, loc in ipairs(impounds) do
        if loc.Visible then
            local model = type(loc.Model) == 'string' and joaat(loc.Model) or loc.Model

            RequestModel(model)
            while not HasModelLoaded(model) do
                Wait(0)
            end

            local ped = CreatePed(
                4,
                model,
                loc.PedPosition.x, loc.PedPosition.y, loc.PedPosition.z - 1.0,
                loc.PedPosition.w,
                false, true
            )

            SetBlockingOfNonTemporaryEvents(ped, true)
            SetEntityInvincible(ped, true)
            FreezeEntityPosition(ped, true)

            local label = loc.Label or 'Pátio do Detran'

            if Config.Target == 'ox' then
                exports.ox_target:addLocalEntity(ped, {
                    {
                        label    = label,
                        icon     = 'fas fa-warehouse',
                        onSelect = function()
                            openImpoundMenu(idx)
                        end,
                        distance = 2.5
                    }
                })
            elseif Config.Target == 'qb' then
                exports['qb-target']:AddTargetEntity(ped, {
                    options = {
                        {
                            icon   = 'fas fa-warehouse',
                            label  = label,
                            action = function()
                                openImpoundMenu(idx)
                            end
                        }
                    },
                    distance = 2.0
                })
            end

            -- Blip do pátio
            if loc.Position then
                local blip = AddBlipForCoord(loc.Position.x, loc.Position.y, loc.Position.z)
                SetBlipSprite(blip, 357)
                SetBlipScale(blip, 0.5)
                SetBlipColour(blip, 3)
                SetBlipDisplay(blip, 4)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentString(label)
                EndTextCommandSetBlipName(blip)
            end

            print(('[rhd_garage] Pátio criado (idx=%d, label="%s").'):format(idx, label))
        end
    end
end

-------------------------------------------------
-- THREAD PRINCIPAL
-------------------------------------------------

CreateThread(function()
    -- alvo de veículo para a polícia APREENDER
    setUpTarget()
    -- peds / blips para RETIRAR do pátio
    createImpoundPeds()
end)

-------------------------------------------------
-- EXPORT / LIMPEZA
-------------------------------------------------

exports('openImpoundMenu', openImpoundMenu)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        deletePreviewVehicle()
    end
end)
