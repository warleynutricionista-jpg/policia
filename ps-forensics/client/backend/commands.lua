-- ============================================================
-- PS-FORENSICS - Registro de Comandos (Padrão Modular MDT)
-- Único ponto de entrada: /pericia
-- ============================================================

if not Config.Commands.Open.enabled then
    return
end

local cmd = Config.Commands.Open.command

RegisterCommand(cmd, function()
    OpenForensicsUI()
end, false)

TriggerEvent('chat:addSuggestion', '/' .. cmd, 'Abrir o Painel de Perícia Criminal')

RegisterKeyMapping(cmd, 'Abrir Painel de Perícia', 'keyboard', 'F10')
