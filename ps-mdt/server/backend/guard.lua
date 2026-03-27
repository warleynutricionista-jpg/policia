-- Guard centralizado para verificação de autenticação e permissões
-- Uso: local denied = Guard.require(src, 'permissao'); if denied then return denied end

local Guard = {}

--- Verifica autenticação + permissão obrigatória.
--- Retorna nil se permitido, ou tabela de erro para retornar ao callback.
function Guard.require(src, permName)
    if not CheckAuth(src) then
        return { success = false, message = 'Não autorizado' }
    end
    if permName and not CheckPermission(src, permName) then
        return { success = false, message = 'Sem permissão: ' .. permName }
    end
    return nil
end

--- Verifica autenticação + pelo menos uma das permissões da lista.
--- Retorna nil se permitido, ou tabela de erro para retornar ao callback.
function Guard.requireAny(src, permNames)
    if not CheckAuth(src) then
        return { success = false, message = 'Não autorizado' }
    end
    for _, perm in ipairs(permNames) do
        if CheckPermission(src, perm) then return nil end
    end
    return { success = false, message = 'Sem permissão necessária' }
end

return Guard
