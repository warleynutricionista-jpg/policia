-- ============================================================
-- PS-FORENSICS — ox_target: Interações Forenses em Jogadores/Peds
-- client/backend/forensic_targets.lua
--
-- Adiciona opções contextuais ao mirar em:
--   • Jogadores → Coletar DNA, Testar GSR, Coletar Digital
--   • Peds mortos → Examinar corpo, Acondicionar em saco
--   • Veículos → Inspecionar vestígios, Coletar fragmentos
-- ============================================================

local resourceName = GetCurrentResourceName()

-- ============================================================
-- VERIFICAÇÃO DE ACESSO FORENSE
-- ============================================================
local function isForensicOfficer()
    if ForensicsAccess and ForensicsAccess.hasAccess then
        return ForensicsAccess.hasAccess()
    end
    return type(hasAccess) == 'function' and hasAccess() or false
end

local function hasItem(itemName)
    if GetResourceState('ox_inventory') ~= 'started' then return false end
    local count = exports.ox_inventory:Search('count', itemName)
    return count and count > 0
end

local function getActiveSceneIdAtCoords(coords)
    if type(IsWithinActiveCrimeScene) ~= 'function' then
        return nil
    end

    local inside, sceneId = IsWithinActiveCrimeScene(coords)
    if inside and sceneId then
        return sceneId
    end

    return nil
end

-- ============================================================
-- HELPER: Executar ação forense com animação + server callback
-- ============================================================
local function doForensicAction(itemName, serverCallback, data, consumeAction)
    -- Verificar luvas
    if itemName ~= 'disposable_gloves' and ForensicState.hasGloves and not ForensicState.hasGloves() then
        local glovesNeeded = {
            dna_swab = true, blood_reagent = true, fingerprint_powder = true,
            fingerprint_tape = true, forensic_tweezers = true, gsr_kit = true,
            drug_test_kit = true, evidence_bag = true, medical_exam_case = true, body_bag = true,
        }
        if glovesNeeded[itemName] then
            lib.notify({ title = 'Proteção Necessária', description = 'Calce as luvas antes.', type = 'error' })
            return false
        end
    end

    -- Verificar item no inventário
    if not hasItem(itemName) then
        lib.notify({ title = 'Item Necessário', description = ('Você precisa de: %s'):format(itemName), type = 'error' })
        return false
    end

    -- Animação contextual
    local propModel = nil
    local ItemProps = {
        dna_swab = 'prop_cs_mop_s', gsr_kit = 'prop_cs_box_clothes',
        forensic_camera = 'prop_pap_camera_01', forensic_tweezers = 'prop_pencil_01',
        blood_reagent = 'prop_cs_spray_can', drug_test_kit = 'prop_mp_drug_pack_blue',
        evidence_bag = 'prop_evidence_bag_01', body_bag = 'prop_ld_case_01',
        medical_exam_case = 'prop_ld_case_01', ballistic_kit = 'prop_idol_case_01',
    }
    propModel = ItemProps[itemName]

    if ForensicAnims and ForensicAnims.playItemAnimation then
        local duration = ({
            dna_swab = 2800, gsr_kit = 2800, forensic_camera = 1500,
            forensic_tweezers = 2000, blood_reagent = 2500, drug_test_kit = 2600,
            evidence_bag = 2200, body_bag = 3000, medical_exam_case = 3500,
            ballistic_kit = 2800,
        })[itemName] or 2500

        if not ForensicAnims.playItemAnimation(itemName, propModel, duration) then
            return false -- cancelled
        end
    end

    -- Consumir item server-side
    if consumeAction then
        local exec = lib.callback.await(resourceName .. ':server:executeItemUse', false, {
            itemName = itemName,
            action = consumeAction,
            coords = GetEntityCoords(PlayerPedId()),
        })
        if not exec or not exec.success then
            lib.notify({ title = 'Erro', description = exec and exec.error or 'Falha ao usar item.', type = 'error' })
            return false
        end
    end

    -- Chamar server callback
    if serverCallback then
        local result = lib.callback.await(resourceName .. ':server:' .. serverCallback, false, data)
        if result and result.success then
            lib.notify({ title = 'Sistema Forense', description = 'Ação registrada com sucesso.', type = 'success', duration = 4000 })

            -- Efeito visual de coleta
            if ForensicParticles and ForensicParticles.collectSuccess then
                ForensicParticles.collectSuccess(GetEntityCoords(PlayerPedId()))
            end

            return true, result
        else
            lib.notify({ title = 'Erro', description = result and result.error or 'Falha no servidor.', type = 'error' })
            return false
        end
    end

    return true
end

-- ============================================================
-- OBTER DADOS DO PLAYER-ALVO (citizenid, nome)
-- ============================================================
local function getTargetPlayerData(entity)
    if not DoesEntityExist(entity) then return nil end
    if not IsPedAPlayer(entity) then return nil end

    local serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
    if not serverId or serverId == 0 then return nil end

    local data = lib.callback.await(resourceName .. ':server:getTargetPlayerInfo', false, serverId)
    return data
end

-- ============================================================
-- REGISTRAR ox_target PARA JOGADORES (global player target)
-- ============================================================
CreateThread(function()
    Wait(3000) -- Aguardar inicialização completa

    -- ============================
    -- TARGET: Jogadores vivos
    -- ============================
    exports.ox_target:addGlobalPlayer({
        {
            name = 'psf_collect_dna_player',
            icon = 'fa-solid fa-dna',
            label = 'Coletar DNA',
            distance = 2.5,
            onSelect = function(data)
                local targetData = getTargetPlayerData(data.entity)
                if not targetData then
                    lib.notify({ title = 'Erro', description = 'Não foi possível identificar o alvo.', type = 'error' })
                    return
                end

                local ok, result = doForensicAction('dna_swab', 'collectDNASample', {
                    source_type = 'corpo_suspeito',
                    source_description = ('Coleta direta - %s'):format(targetData.name or 'Desconhecido'),
                    linked_citizenid = targetData.citizenid,
                    notes = 'Coleta via interação direta com pessoa',
                }, 'collect_biological')

                if ok and result then
                    lib.notify({
                        title = 'DNA Coletado',
                        description = ('Amostra de DNA coletada de %s. ID: %s'):format(targetData.name or '?', tostring(result.id or '?')),
                        type = 'success', duration = 5000,
                    })
                end
            end,
            canInteract = function()
                return isForensicOfficer() and hasItem('dna_swab') and ForensicState.hasGloves()
            end,
        },
        {
            name = 'psf_collect_fingerprint_player',
            icon = 'fa-solid fa-fingerprint',
            label = 'Coletar Impressão Digital',
            distance = 2.5,
            onSelect = function(data)
                local targetData = getTargetPlayerData(data.entity)
                if not targetData then
                    lib.notify({ title = 'Erro', description = 'Não foi possível identificar o alvo.', type = 'error' })
                    return
                end

                -- Registrar digital + coletar amostra
                local regResult = lib.callback.await(resourceName .. ':server:registerFingerprint', false, targetData.citizenid, targetData.name)

                if ForensicAnims and ForensicAnims.playItemAnimation then
                    ForensicAnims.playItemAnimation('fingerprint_tape', nil, 2000)
                end

                if regResult and regResult.success then
                    lib.notify({
                        title = 'Impressão Digital',
                        description = regResult.reused
                            and ('Digital já cadastrada para %s'):format(targetData.name or '?')
                            or ('Digital cadastrada: %s'):format(regResult.code or '?'),
                        type = 'success', duration = 5000,
                    })
                else
                    lib.notify({ title = 'Erro', description = regResult and regResult.error or 'Falha ao cadastrar digital.', type = 'error' })
                end
            end,
            canInteract = function()
                return isForensicOfficer() and hasItem('fingerprint_kit')
            end,
        },
        {
            name = 'psf_gsr_test_player',
            icon = 'fa-solid fa-gun',
            label = 'Testar Resíduo de Disparo (GSR)',
            distance = 2.5,
            onSelect = function(data)
                local targetData = getTargetPlayerData(data.entity)
                if not targetData then
                    lib.notify({ title = 'Erro', description = 'Não foi possível identificar o alvo.', type = 'error' })
                    return
                end

                if ForensicAnims and ForensicAnims.playItemAnimation then
                    if not ForensicAnims.playItemAnimation('gsr_kit', 'prop_cs_box_clothes', 2800) then return end
                end

                local exec = lib.callback.await(resourceName .. ':server:executeItemUse', false, {
                    itemName = 'gsr_kit',
                    action = 'run_gsr_test',
                    coords = GetEntityCoords(PlayerPedId()),
                })

                if not exec or not exec.success then
                    lib.notify({ title = 'Erro', description = exec and exec.error or 'Falha no teste GSR.', type = 'error' })
                    return
                end

                if ForensicParticles and ForensicParticles.gsrTest then
                    ForensicParticles.gsrTest(GetEntityCoords(data.entity))
                end

                -- Registrar como evidence
                local result = lib.callback.await(resourceName .. ':server:collectEvidence', false, {
                    category = 'quimica',
                    type = 'residuo_polvora',
                    description = ('Teste GSR em %s (%s)'):format(targetData.name or 'Desconhecido', targetData.citizenid or '?'),
                    linked_citizenid = targetData.citizenid,
                    x = GetEntityCoords(data.entity).x,
                    y = GetEntityCoords(data.entity).y,
                    z = GetEntityCoords(data.entity).z,
                    location_name = 'Teste GSR direto em pessoa',
                })

                if result and result.success then
                    lib.notify({
                        title = 'Teste GSR Concluído',
                        description = ('Resultado registrado para %s. Evidência: %s'):format(
                            targetData.name or '?', result.evidenceNumber or '?'),
                        type = 'success', duration = 6000,
                    })
                else
                    lib.notify({ title = 'Aviso', description = 'GSR executado mas falha ao registrar evidência.', type = 'warning' })
                end
            end,
            canInteract = function()
                return isForensicOfficer() and hasItem('gsr_kit') and ForensicState.hasGloves()
            end,
        },
        {
            name = 'psf_drug_test_player',
            icon = 'fa-solid fa-pills',
            label = 'Narcoteste em Pessoa',
            distance = 2.5,
            onSelect = function(data)
                local targetData = getTargetPlayerData(data.entity)
                if not targetData then
                    lib.notify({ title = 'Erro', description = 'Não foi possível identificar o alvo.', type = 'error' })
                    return
                end

                if ForensicAnims and ForensicAnims.playItemAnimation then
                    if not ForensicAnims.playItemAnimation('drug_test_kit', 'prop_mp_drug_pack_blue', 2600) then return end
                end

                local exec = lib.callback.await(resourceName .. ':server:executeItemUse', false, {
                    itemName = 'drug_test_kit',
                    action = 'run_drug_test',
                    coords = GetEntityCoords(PlayerPedId()),
                })

                if not exec or not exec.success then
                    lib.notify({ title = 'Erro', description = exec and exec.error or 'Falha no narcoteste.', type = 'error' })
                    return
                end

                local result = lib.callback.await(resourceName .. ':server:registerDrugAnalysis', false, {
                    sample_source = ('Pessoa: %s (%s)'):format(targetData.name or '?', targetData.citizenid or '?'),
                    linked_citizenid = targetData.citizenid,
                    test_type = 'presuntivo',
                    notes = 'Narcoteste direto em pessoa via interação',
                })

                if result and result.success then
                    lib.notify({
                        title = 'Narcoteste Registrado',
                        description = ('Análise de drogas registrada para %s.'):format(targetData.name or '?'),
                        type = 'success', duration = 5000,
                    })
                else
                    lib.notify({ title = 'Aviso', description = 'Teste executado mas falha ao registrar.', type = 'warning' })
                end
            end,
            canInteract = function()
                return isForensicOfficer() and hasItem('drug_test_kit') and ForensicState.hasGloves()
            end,
        },
    })

    -- ============================
    -- TARGET: Peds mortos (corpos)
    -- ============================
    exports.ox_target:addGlobalPed({
        {
            name = 'psf_examine_body',
            icon = 'fa-solid fa-stethoscope',
            label = 'Examinar Corpo (Perícia Médica)',
            distance = 2.5,
            onSelect = function(data)
                if not IsPedDeadOrDying(data.entity) then
                    lib.notify({ title = 'Aviso', description = 'Esta pessoa não está morta.', type = 'warning' })
                    return
                end

                if ForensicAnims and ForensicAnims.playItemAnimation then
                    if not ForensicAnims.playItemAnimation('medical_exam_case', 'prop_ld_case_01', 3500) then return end
                end

                local exec = lib.callback.await(resourceName .. ':server:executeItemUse', false, {
                    itemName = 'medical_exam_case',
                    action = 'autopsy_exam',
                    coords = GetEntityCoords(PlayerPedId()),
                })

                if not exec or not exec.success then
                    lib.notify({ title = 'Erro', description = exec and exec.error or 'Falha ao iniciar exame.', type = 'error' })
                    return
                end

                -- Abrir painel de necropsia
                OpenForensicsUI('analises')
            end,
            canInteract = function(entity)
                return isForensicOfficer() and hasItem('medical_exam_case') and IsPedDeadOrDying(entity)
            end,
        },
        {
            name = 'psf_body_bag',
            icon = 'fa-solid fa-box',
            label = 'Acondicionar em Saco Cadavérico',
            distance = 2.5,
            onSelect = function(data)
                if not IsPedDeadOrDying(data.entity) then
                    lib.notify({ title = 'Aviso', description = 'Esta pessoa não está morta.', type = 'warning' })
                    return
                end

                if ForensicAnims and ForensicAnims.playItemAnimation then
                    if not ForensicAnims.playItemAnimation('body_bag', 'prop_ld_case_01', 3000) then return end
                end

                local exec = lib.callback.await(resourceName .. ':server:executeItemUse', false, {
                    itemName = 'body_bag',
                    action = 'autopsy_exam',
                    coords = GetEntityCoords(PlayerPedId()),
                })

                if not exec or not exec.success then
                    lib.notify({ title = 'Erro', description = exec and exec.error or 'Falha ao acondicionar corpo.', type = 'error' })
                    return
                end

                lib.notify({
                    title = 'Corpo Acondicionado',
                    description = 'Corpo preservado em saco cadavérico. Registre a remoção no sistema.',
                    type = 'success', duration = 5000,
                })
            end,
            canInteract = function(entity)
                return isForensicOfficer() and hasItem('body_bag') and ForensicState.hasGloves() and IsPedDeadOrDying(entity)
            end,
        },
        {
            name = 'psf_collect_dna_ped',
            icon = 'fa-solid fa-dna',
            label = 'Coletar DNA de Corpo',
            distance = 2.5,
            onSelect = function(data)
                if not IsPedDeadOrDying(data.entity) then
                    lib.notify({ title = 'Aviso', description = 'Use o alvo em jogadores ou corpos.', type = 'warning' })
                    return
                end

                local ok, result = doForensicAction('dna_swab', 'collectDNASample', {
                    source_type = 'corpo_vitima',
                    source_description = 'Coleta de DNA em corpo',
                    notes = 'Coleta via interação direta com corpo/ped',
                }, 'collect_biological')

                if ok and result then
                    lib.notify({
                        title = 'DNA Coletado',
                        description = ('Amostra de DNA coletada do corpo. ID: %s'):format(tostring(result.id or '?')),
                        type = 'success', duration = 5000,
                    })
                end
            end,
            canInteract = function(entity)
                return isForensicOfficer() and hasItem('dna_swab') and ForensicState.hasGloves() and IsPedDeadOrDying(entity)
            end,
        },
        {
            name = 'psf_photo_ped',
            icon = 'fa-solid fa-camera',
            label = 'Fotografar Corpo/Evidência',
            distance = 3.0,
            onSelect = function(data)
                if ForensicAnims and ForensicAnims.playItemAnimation then
                    if not ForensicAnims.playItemAnimation('forensic_camera', 'prop_pap_camera_01', 1500) then return end
                end

                if ForensicParticles and ForensicParticles.cameraFlash then
                    ForensicParticles.cameraFlash()
                end

                lib.notify({
                    title = 'Foto Registrada',
                    description = 'Documentação fotográfica realizada. Registre no sistema forense.',
                    type = 'success', duration = 4000,
                })
            end,
            canInteract = function()
                return isForensicOfficer() and hasItem('forensic_camera')
            end,
        },
    })

    -- ============================
    -- TARGET: Veículos
    -- ============================
    exports.ox_target:addGlobalVehicle({
        {
            name = 'psf_inspect_vehicle',
            icon = 'fa-solid fa-magnifying-glass',
            label = 'Inspecionar Veículo (Perícia)',
            distance = 3.0,
            onSelect = function(data)
                local coords = GetEntityCoords(data.entity)
                local sceneId = getActiveSceneIdAtCoords(coords)
                if not sceneId then
                    lib.notify({
                        title = 'Cena Necessária',
                        description = 'Para coleta direta, esteja dentro de uma cena de crime ativa.',
                        type = 'error',
                    })
                    return
                end

                if ForensicAnims and ForensicAnims.playItemAnimation then
                    if not ForensicAnims.playItemAnimation('forensic_flashlight', nil, 800) then return end
                end

                local plate = GetVehicleNumberPlateText(data.entity)
                if plate then plate = plate:gsub('^%s*(.-)%s*$', '%1') end

                local exec = lib.callback.await(resourceName .. ':server:executeItemUse', false, {
                    itemName = 'evidence_bag',
                    action = 'collect_evidence',
                    coords = GetEntityCoords(PlayerPedId()),
                })
                if not exec or not exec.success then
                    lib.notify({
                        title = 'Erro',
                        description = exec and exec.error or 'Falha ao preparar coleta de evidência.',
                        type = 'error',
                    })
                    return
                end

                local result = lib.callback.await(resourceName .. ':server:collectEvidence', false, {
                    scene_id = sceneId,
                    category = 'veiculo',
                    type = 'veiculo_cena',
                    subtype = 'inspecao_veiculo',
                    description = ('Vestígio coletado em veículo placa %s via coleta direta da cena.'):format(plate or 'N/D'),
                    location_name = ('Veículo em cena ativa | Placa: %s'):format(plate or 'N/D'),
                    linked_vehicle_plate = plate,
                    x = coords.x,
                    y = coords.y,
                    z = coords.z,
                })

                if result and result.success then
                    lib.notify({
                        title = 'Coleta Registrada',
                        description = ('Evidência %s registrada automaticamente no sistema.'):format(result.evidenceNumber or 'N/D'),
                        type = 'success',
                        duration = 6000,
                    })
                else
                    lib.notify({
                        title = 'Erro',
                        description = result and result.error or 'Falha ao registrar evidência do veículo.',
                        type = 'error',
                    })
                end
            end,
            canInteract = function(entity, _, coords)
                local targetCoords = coords or (entity and GetEntityCoords(entity)) or nil
                local sceneId = targetCoords and getActiveSceneIdAtCoords(targetCoords) or nil
                return isForensicOfficer()
                    and sceneId ~= nil
                    and hasItem('forensic_kit')
                    and hasItem('evidence_bag')
            end,
        },
        {
            name = 'psf_collect_vehicle_fingerprint',
            icon = 'fa-solid fa-fingerprint',
            label = 'Coletar Digital do Veículo',
            distance = 2.5,
            onSelect = function(data)
                local plate = GetVehicleNumberPlateText(data.entity)
                if plate then plate = plate:gsub('^%s*(.-)%s*$', '%1') end

                if ForensicAnims and ForensicAnims.playItemAnimation then
                    if not ForensicAnims.playItemAnimation('fingerprint_powder', 'bkr_prop_coke_bakingsoda_o', 2500) then return end
                end

                local exec = lib.callback.await(resourceName .. ':server:executeItemUse', false, {
                    itemName = 'fingerprint_powder',
                    action = 'collect_fingerprint_sequence',
                    coords = GetEntityCoords(PlayerPedId()),
                })

                if not exec or not exec.success then
                    lib.notify({ title = 'Erro', description = exec and exec.error or 'Falha ao coletar digital.', type = 'error' })
                    return
                end

                local result = lib.callback.await(resourceName .. ':server:collectFingerprint', false, {
                    source_type = 'veiculo',
                    source_description = ('Veículo placa %s'):format(plate or 'N/D'),
                    quality = 'parcial',
                    notes = 'Coletada de veículo via interação',
                })

                if result and result.success then
                    if ForensicParticles and ForensicParticles.fingerprintPowder then
                        ForensicParticles.fingerprintPowder(GetEntityCoords(PlayerPedId()))
                    end
                    lib.notify({
                        title = 'Digital Coletada',
                        description = ('Impressão coletada do veículo %s. ID: %s'):format(plate or '?', tostring(result.id or '?')),
                        type = 'success', duration = 5000,
                    })
                else
                    lib.notify({ title = 'Erro', description = result and result.error or 'Falha ao registrar digital.', type = 'error' })
                end
            end,
            canInteract = function()
                return isForensicOfficer() and hasItem('fingerprint_kit') and hasItem('fingerprint_powder') and ForensicState.hasGloves()
            end,
        },
        {
            name = 'psf_collect_vehicle_blood',
            icon = 'fa-solid fa-droplet',
            label = 'Aplicar Reagente de Sangue',
            distance = 2.5,
            onSelect = function(data)
                local plate = GetVehicleNumberPlateText(data.entity)
                if plate then plate = plate:gsub('^%s*(.-)%s*$', '%1') end

                if ForensicAnims and ForensicAnims.playItemAnimation then
                    if not ForensicAnims.playItemAnimation('blood_reagent', 'prop_cs_spray_can', 2500) then return end
                end

                local exec = lib.callback.await(resourceName .. ':server:executeItemUse', false, {
                    itemName = 'blood_reagent',
                    action = 'run_blood_test',
                    coords = GetEntityCoords(PlayerPedId()),
                })

                if not exec or not exec.success then
                    lib.notify({ title = 'Erro', description = exec and exec.error or 'Falha ao aplicar reagente.', type = 'error' })
                    return
                end

                if ForensicParticles and ForensicParticles.bloodReagentReveal then
                    ForensicParticles.bloodReagentReveal(GetEntityCoords(data.entity))
                end

                lib.notify({
                    title = 'Reagente Aplicado',
                    description = ('Teste no veículo %s. Registre vestígios no sistema forense.'):format(plate or '?'),
                    type = 'success', duration = 5000,
                })
            end,
            canInteract = function()
                return isForensicOfficer() and hasItem('blood_reagent') and ForensicState.hasGloves()
            end,
        },
    })

    print(('[%s] ox_target: Interações forenses registradas (players, peds, veículos)'):format(resourceName))
end)
