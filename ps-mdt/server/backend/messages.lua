local resourceName = tostring(GetCurrentResourceName())

ps.registerCallback(resourceName .. ':server:getOfficerMessages', function(source)
    local src = source
    if not CheckAuth(src) then return { items = {} } end

    local citizenid = ps.getIdentifier(src)
    if not citizenid then
        return { items = {} }
    end

    local rows = MySQL.query.await([[
        SELECT id, sender_citizenid, sender_name, receiver_citizenid, receiver_name,
               subject, body, created_at, read_at
        FROM mdt_messages
        WHERE receiver_citizenid = ?
        ORDER BY created_at DESC
        LIMIT 50
    ]], { citizenid })

    return { items = rows or {} }
end)

ps.registerCallback(resourceName .. ':server:sendOfficerMessage', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, error = 'Não autorizado' } end

    payload = payload or {}
    local receiverId = payload.receiverCitizenId
    local subject = payload.subject and tostring(payload.subject) or ''
    local body = payload.body and tostring(payload.body) or ''

    if not receiverId or receiverId == '' then
        return { success = false, error = 'Destinatário ausente' }
    end

    if body == '' then
        return { success = false, error = 'O corpo da mensagem é obrigatório' }
    end

    local senderId = ps.getIdentifier(src)
    if not senderId then
        return { success = false, error = 'Remetente ausente' }
    end

    local senderName = ps.getPlayerName(src) or 'Desconhecido'
    local receiverName = ps.getPlayerNameByIdentifier(receiverId) or 'Desconhecido'

    local insertId = MySQL.insert.await([[
        INSERT INTO mdt_messages (sender_citizenid, sender_name, receiver_citizenid, receiver_name, subject, body)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], { senderId, senderName, receiverId, receiverName, subject, body })

    if not insertId then
        return { success = false, error = 'Falha ao enviar a mensagem' }
    end

    return { success = true, messageId = insertId }
end)

ps.registerCallback(resourceName .. ':server:markMessageRead', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, error = 'Não autorizado' } end

    payload = payload or {}
    local messageId = tonumber(payload.messageId)
    if not messageId then
        return { success = false, error = 'ID da mensagem ausente' }
    end

    local citizenid = ps.getIdentifier(src)
    if not citizenid then
        return { success = false, error = 'Destinatário ausente' }
    end

    local updated = MySQL.update.await([[
        UPDATE mdt_messages
        SET read_at = NOW()
        WHERE id = ? AND receiver_citizenid = ?
    ]], { messageId, citizenid })

    return { success = updated and updated > 0 }
end)
