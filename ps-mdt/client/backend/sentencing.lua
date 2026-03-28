local resourceName = tostring(GetCurrentResourceName())

-- ============================================================
-- ANIMAÇÃO DE ENTREGA DE CITAÇÃO
-- Clipboard + animação de preenchimento de documento
-- ============================================================
local function playCitationDeliveryAnim()
    local dict = 'amb@world_human_clipboard@male@base'
    local clip = 'base'
    local propModel = 'prop_notepad_01'

    lib.requestAnimDict(dict)

    return lib.progressBar({
        duration     = 3000,
        label        = 'Emitindo citação...',
        useWhileDead = false,
        canCancel    = true,
        disable      = { move = false, car = true, combat = true },
        anim         = { dict = dict, clip = clip, flag = 49 },
        prop         = {
            model = propModel,
            bone  = 60309,
            pos   = vec3(0.03, 0.03, 0.02),
            rot   = vec3(30.0, 10.0, 140.0),
        },
    })
end

-- Send to Jail
RegisterNUICallback('sendToJail', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    if type(data) ~= 'table' or not data.citizenId or not data.sentence then
        cb({ success = false, message = 'Faltando ID do cidadão ou sentença' })
        return
    end

    local result = ps.callback(resourceName .. ':server:sendToJail', data)
    cb(result or { success = false, message = 'Falha ao enviar para a prisão' })
end)

-- Give Citation
RegisterNUICallback('giveCitation', function(data, cb)
    if not MDTOpen then
        cb({ success = false, message = 'O MDT não está aberto' })
        return
    end

    if type(data) ~= 'table' or not data.citizenId then
        cb({ success = false, message = 'Faltando ID do cidadão' })
        return
    end

    -- Fecha o NUI temporariamente para a animação ser visível
    SetNuiFocus(false, false)

    if not playCitationDeliveryAnim() then
        -- Cancelado pelo jogador — reabre o MDT
        SetNuiFocus(true, true)
        cb({ success = false, message = 'Emissão cancelada' })
        return
    end

    -- Reabre o painel após a animação
    SetNuiFocus(true, true)

    -- Notificação de entrega presencial
    lib.notify({
        title       = 'Citação Emitida',
        description = 'Documento entregue. Registro adicionado ao sistema.',
        type        = 'success',
        duration    = 5000,
    })

    local result = ps.callback(resourceName .. ':server:giveCitation', data)
    cb(result or { success = false, message = 'Falha ao aplicar a citação' })
end)
