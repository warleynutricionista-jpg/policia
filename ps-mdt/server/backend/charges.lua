
local resourceName = tostring(GetCurrentResourceName())

ps.registerCallback('ps-mdt:getChargeList', function(source)
    if not CheckAuth(source) then return {} end

    local rows = MySQL.query.await([[
        SELECT
            code,
            label,
            charge_class AS type,
            description,
            months AS time,
            fine,
            CASE
                WHEN charge_class = 'felony' THEN 'Offenses Against Persons'
                WHEN charge_class = 'misdemeanor' THEN 'Offenses Against Public Order'
                WHEN charge_class = 'infraction' THEN 'Offenses Against Public Safety'
                ELSE 'Uncategorized'
            END AS category
        FROM mdt_penal_codes
        ORDER BY charge_class, label
    ]], {})
    ps.debug('[getChargeList] rows', rows and #rows or 0)
    if Config and Config.Debug and rows and rows[1] then
        ps.debug('[getChargeList] sample', rows[1])
    end
    return rows
end)

-- Process a fine - deduct money from citizen's bank account
-- Ported from ps-mdt v1 (mdt:server:removeMoney)
local fineAntiSpam = false
ps.registerCallback(resourceName .. ':server:processFine', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end

    payload = payload or {}
    local citizenId = payload.citizenid
    local fine = tonumber(payload.fine)
    local reportId = payload.reportId

    local jfConfig = GetJailFinesConfig and GetJailFinesConfig() or {}
    local maxFine = jfConfig.maxFineAmount or (Config and Config.Fines and Config.Fines.MaxAmount) or 100000
    if not citizenId or not fine or fine <= 0 then
        return { success = false, message = 'Faltando ID do cidadão ou valor de multa inválido' }
    end
    if fine > maxFine then
        return { success = false, message = 'O valor da multa excede o máximo de $' .. maxFine }
    end

    if fineAntiSpam then
        return { success = false, message = 'Processamento de multa em tempo de espera' }
    end

    -- Try to get online player first
    local Player = ps.getPlayerByIdentifier(citizenId)
    if not Player then
        return { success = false, message = 'O jogador precisa estar online para processar a multa' }
    end

    -- Remove money from bank
    local removed = ps.removeMoney(Player.source or Player.PlayerData.source, 'bank', fine, 'mdt-fine')
    if removed then
        ps.notify(Player.source or Player.PlayerData.source, '$' .. fine .. ' de multa foi descontada da sua conta bancária', 'error')

        -- Anti-spam cooldown
        fineAntiSpam = true
        local cooldown = (Config and Config.Fines and Config.Fines.CooldownMs) or 30000
        SetTimeout(cooldown, function()
            fineAntiSpam = false
        end)

        if ps.auditLog then
            local officerName = ps.getPlayerName(src) or 'Unknown Officer'
            ps.auditLog(src, 'fine_processed', 'fine', reportId and tostring(reportId) or nil, {
                citizenid = citizenId,
                fine = fine,
                officer = officerName,
            })
        end

        return { success = true, message = 'Multa de $' .. fine .. ' processada' }
    else
        return { success = false, message = 'Falha ao remover o dinheiro - fundos insuficientes?' }
    end
end)

ps.registerCallback(resourceName .. ':server:updateCharge', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end
    if not CheckPermission(src, 'charges_edit') then
        return { success = false, message = 'Você não tem permissão para editar acusações' }
    end

    payload = payload or {}
    if not payload.code then
        return { success = false, message = 'Faltando código da acusação' }
    end

    local penalUpdates = {}
    local penalValues = {}
    if payload.fine ~= nil then
        penalUpdates[#penalUpdates + 1] = 'fine = ?'
        penalValues[#penalValues + 1] = math.max(0, tonumber(payload.fine) or 0)
    end
    if payload.time ~= nil then
        penalUpdates[#penalUpdates + 1] = 'months = ?'
        penalValues[#penalValues + 1] = math.max(0, tonumber(payload.time) or 0)
    end
    if payload.label ~= nil and type(payload.label) == 'string' and payload.label ~= '' then
        penalUpdates[#penalUpdates + 1] = 'label = ?'
        penalValues[#penalValues + 1] = payload.label
    end
    if payload.description ~= nil and type(payload.description) == 'string' then
        penalUpdates[#penalUpdates + 1] = 'description = ?'
        penalValues[#penalValues + 1] = payload.description
    end

    if #penalUpdates == 0 then
        return { success = true }
    end

    penalValues[#penalValues + 1] = payload.code
    local penalUpdated = MySQL.update.await(([[
        UPDATE mdt_penal_codes
        SET %s
        WHERE code = ?
    ]]):format(table.concat(penalUpdates, ', ')), penalValues)

    if penalUpdated and penalUpdated > 0 and ps.auditLog then
        ps.auditLog(src, 'charge_updated', 'charge', payload.code, {
            label = payload.label,
            fine = payload.fine,
            time = payload.time,
            description = payload.description
        })
    end
    return { success = penalUpdated and penalUpdated > 0 }
end)

ps.registerCallback(resourceName .. ':server:addCharge', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end
    if not CheckPermission(src, 'charges_edit') then
        return { success = false, message = 'Você não tem permissão para criar infrações' }
    end

    payload = payload or {}
    local code = tostring(payload.code or ''):match('^%s*(.-)%s*$')
    local label = tostring(payload.label or ''):match('^%s*(.-)%s*$')
    local chargeClass = tostring(payload.type or payload.charge_class or 'infraction'):lower()
    local description = tostring(payload.description or '')
    local fine = math.max(0, tonumber(payload.fine) or 0)
    local months = math.max(0, tonumber(payload.time or payload.months) or 0)
    local color = tostring(payload.color or '#6b7280')

    if code == '' or label == '' then
        return { success = false, message = 'Código e nome da infração são obrigatórios' }
    end

    if chargeClass ~= 'felony' and chargeClass ~= 'misdemeanor' and chargeClass ~= 'infraction' then
        chargeClass = 'infraction'
    end

    local existing = MySQL.scalar.await('SELECT code FROM mdt_penal_codes WHERE code = ? LIMIT 1', { code })
    if existing then
        return { success = false, message = 'Já existe uma infração com esse código' }
    end

    local inserted = MySQL.insert.await([[
        INSERT INTO mdt_penal_codes (code, label, charge_class, months, fine, color, description)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], { code, label, chargeClass, months, fine, color, description })

    if inserted and ps.auditLog then
        ps.auditLog(src, 'charge_created', 'charge', code, {
            code = code,
            label = label,
            type = chargeClass,
            fine = fine,
            time = months
        })
    end

    return { success = inserted ~= nil and inserted ~= false }
end)

ps.registerCallback(resourceName .. ':server:deleteCharge', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end
    if not CheckPermission(src, 'charges_edit') then
        return { success = false, message = 'Você não tem permissão para excluir infrações' }
    end

    payload = payload or {}
    local code = tostring(payload.code or ''):match('^%s*(.-)%s*$')
    if code == '' then
        return { success = false, message = 'Código da infração inválido' }
    end

    local deleted = MySQL.update.await('DELETE FROM mdt_penal_codes WHERE code = ?', { code })
    if deleted and deleted > 0 and ps.auditLog then
        ps.auditLog(src, 'charge_deleted', 'charge', code, { code = code })
    end

    return { success = deleted and deleted > 0 }
end)
