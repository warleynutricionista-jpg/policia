if not Config.UsePoliceImpound then 
    return
end

---------------------------------------
-- FUNÇÃO AUXILIAR: DECODE SEGURO
-- (mantida caso queira salvar props/
--  deformações no futuro)
---------------------------------------
local function safeDecode(jsonStr, default)
    if type(jsonStr) ~= 'string' or jsonStr == '' then
        return default or {}
    end

    local ok, decoded = pcall(json.decode, jsonStr)
    if not ok or decoded == nil then
        return default or {}
    end

    return decoded
end

---------------------------------------
-- FUNÇÃO AUXILIAR: NORMALIZAR LABEL
---------------------------------------
local function normalizeGarageLabel(param)
    -- Pode vir: "Pátio do Detran"
    -- ou table: { label = "Pátio do Detran" } / { value = "Pátio do Detran" }
    if type(param) == 'table' then
        local lbl = param.label or param.value or ''
        lbl = lbl:match('^%s*(.-)%s*$') or ''
        return lbl
    elseif type(param) == 'string' then
        return (param:match('^%s*(.-)%s*$') or '')
    else
        return ''
    end
end

---------------------------------------
-- CALLBACK: LISTAR VEÍCULOS APREENDIDOS
-- TABELA: citizenid, plate, garage, paid, date, fine
---------------------------------------
lib.callback.register('rhd_garage:cb_server:policeImpound.getVehicle', function(_, garageParam)
    local dataToSend = {}

    local label = normalizeGarageLabel(garageParam)

    if label == '' then
        print('^3[rhd_garage] policeImpound.getVehicle sem label de garagem, buscando TODOS os veículos.^0')
    else
        print(('[rhd_garage] policeImpound.getVehicle | label recebido: "%s"'):format(label))
    end

    local query, params
    if label ~= '' then
        query  = 'SELECT citizenid, plate, garage, paid, date, fine FROM police_impound WHERE garage = ?'
        params = { label }
    else
        query  = 'SELECT citizenid, plate, garage, paid, date, fine FROM police_impound'
        params = {}
    end

    local result = MySQL.query.await(query, params) or {}

    if #result == 0 then
        print(('[rhd_garage] Nenhum veículo apreendido encontrado para a garagem "%s".'):format(label ~= '' and label or 'QUALQUER'))
        return dataToSend
    end

    for _, v in ipairs(result) do
        local plate  = v.plate or 'SEM PLACA'
        local fine   = tonumber(v.fine) or 0
        local paid   = tonumber(v.paid) or 0
        local garage = v.garage or 'N/D'
        local date   = v.date or 'N/D'

        print(('[rhd_garage]  - plate=%s | garage=%s | paid=%s | fine=%s | date=%s'):format(
            plate, garage, paid, fine, date
        ))

        -- Esses campos são usados só no menu.
        -- O spawn REAL pega os dados pelo callback getvehiclePropByPlate (client).
        dataToSend[#dataToSend + 1] = {
            citizenid   = v.citizenid,
            props       = {},               -- mantido vazio, só pra não quebrar o client
            deformation = {},
            plate       = plate,
            vehicle     = 'Veículo apreendido',
            owner       = v.citizenid or 'DESCONHECIDO',
            officer     = 'POLÍCIA',
            fine        = fine,
            paid        = paid,
            date        = date,
            garage      = garage,
        }
    end

    print(('[rhd_garage] policeImpound.getVehicle | enviando %d veículo(s) para o client.'):format(#dataToSend))
    return dataToSend
end)

---------------------------------------
-- CALLBACK: APREENDER VEÍCULO
-- USA AS COLUNAS: citizenid, plate, garage, paid, date, fine
---------------------------------------
lib.callback.register('rhd_garage:cb_server:policeImpound.impoundveh', function(_, impoundData)
    if not impoundData then
        print('^1[rhd_garage] impoundveh chamado sem dados.^0')
        return false
    end

    if not impoundData.plate then
        print('^1[rhd_garage] impoundveh com plate inválida.^0')
        return false
    end

    local garageLabel = normalizeGarageLabel(impoundData.garage)

    if garageLabel == '' then
        print('^1[rhd_garage] impoundveh chamado sem garage label válido.^0')
        return false
    end

    local dateString = os.date('%d/%m/%Y', impoundData.date or os.time())
    local fine       = impoundData.fine or 0

    print(('[rhd_garage] Inserindo na police_impound: citizenid=%s | plate=%s | garage=%s | date=%s | fine=%s'):format(
        tostring(impoundData.citizenid),
        tostring(impoundData.plate),
        tostring(garageLabel),
        tostring(dateString),
        tostring(fine)
    ))

    local insertId = MySQL.insert.await([[
        INSERT INTO police_impound
            (citizenid, plate, garage, paid, date, fine)
        VALUES
            (?,         ?,     ?,      ?,    ?,    ?)
    ]], {
        impoundData.citizenid,
        impoundData.plate,
        garageLabel,
        0,          -- paid = 0 (não pago)
        dateString,
        fine
    })

    if not insertId then
        print(('[rhd_garage] ^1Falha ao inserir veículo %s na tabela police_impound.^0'):format(impoundData.plate))
        return false
    end

    print(('[rhd_garage] Veículo %s inserido no police_impound (id interno %s).'):format(
        impoundData.plate, tostring(insertId))
    )

    -- Marca o veículo como "apreendido" no sistema principal (2 = impound, por exemplo)
    fw.uvspi(impoundData.plate, 2)

    return true
end)

---------------------------------------
-- CALLBACK: CHECAR DATA DE LIBERAÇÃO
---------------------------------------
lib.callback.register('rhd_garage:cb_server:policeImpound.cekDate', function(_, date)
    -- date esperado no formato "dd/mm/aaaa"
    if type(date) ~= 'string' then
        return true, 0
    end

    local d, m, y = date:match('(%d+)/(%d+)/(%d+)')
    d, m, y = tonumber(d), tonumber(m), tonumber(y)

    if not d or not m or not y then
        return true, 0
    end

    local target = os.time({
        year  = y,
        month = m,
        day   = d,
        hour  = 0,
        min   = 0,
        sec   = 0,
    })

    local now      = os.time()
    local diffDays = math.ceil((target - now) / (24 * 60 * 60))
    local canTake  = now >= target

    return canTake, diffDays
end)

---------------------------------------
-- EVENTO: REMOVER DO PÁTIO DA POLÍCIA
---------------------------------------
RegisterNetEvent('rhd_garage:server:removeFromPoliceImpound', function(plate)
    -- bloqueia chamadas de outros resources via TriggerEvent
    if GetInvokingResource() then return end
    if not plate then return end

    local affected = MySQL.update.await('DELETE FROM police_impound WHERE plate = ?', { plate })
    print(('[rhd_garage] Veículo %s removido do police_impound (linhas afetadas: %s).'):format(
        plate, tostring(affected))
    )

    -- Atualiza estado no sistema principal (0 = guardado/normal)
    fw.uvspi(plate, 0)
end)

---------------------------------------
-- EVENTO: MARCAR COMO PAGO (NOVO)
-- Chamado pelo client DEPOIS de cobrar
-- cash/banco com sucesso.
---------------------------------------
RegisterNetEvent('rhd_garage:server:policeImpound.markAsPaid', function(plate)
    -- bloqueia chamadas de outros resources via TriggerEvent
    if GetInvokingResource() then return end
    if not plate or plate == '' then return end

    local affected = MySQL.update.await(
        'UPDATE police_impound SET paid = 1 WHERE plate = ?',
        { plate }
    )

    print(('[rhd_garage] markAsPaid | plate=%s | linhas afetadas=%s'):format(
        tostring(plate), tostring(affected))
    )
end)

---------------------------------------
-- EVENTO ANTIGO DE MULTA (REMOVIDO)
--  (rhd_garage:server:policeImpound.sendBill)
-- O fluxo de pagamento agora é TODO
--  no client, com removeMoney + markAsPaid.
---------------------------------------
--[[
RegisterNetEvent('rhd_garage:server:policeImpound.sendBill', function(citizenid, fine, plate)
    -- REMOVIDO – não é mais utilizado com o novo client.
end)
]]
