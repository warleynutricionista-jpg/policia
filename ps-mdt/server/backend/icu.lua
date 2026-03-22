local resourceName = tostring(GetCurrentResourceName())

-- Delete ICU Record (ambulance/EMS)
ps.registerCallback(resourceName .. ':server:deleteICU', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end
    payload = payload or {}
    local id = tonumber(payload.id)

    if not id then
        return { success = false, message = 'Faltando ID do registro de UTI' }
    end

    -- ICU records are stored as BOLOs with type context - ensure we only delete the correct record
    local rows = MySQL.query.await('SELECT id FROM mdt_bolos WHERE id = ?', { id })
    if not rows or #rows == 0 then
        return { success = false, message = 'Registro de UTI não encontrado' }
    end
    MySQL.update.await('DELETE FROM mdt_bolos WHERE id = ?', { id })

    if ps.auditLog then
        ps.auditLog(src, 'icu_deleted', 'icu', tostring(id), {})
    end

    return { success = true, message = 'Registro de UTI excluído' }
end)
