lib.locale()

require "client.evidences.evidences"

require "client.evidences.registry.blood"
require "client.evidences.registry.fingerprint"
require "client.evidences.registry.magazine"

require "client.dui.handler"

require "client.biometrics.biometrics_taking"

require "client.scanner.scanner"

require "client.items"

local config <const> = require "config"

if config.wiretap.enabled and GetResourceState("pma-voice"):find("start") then
    require "client.wiretap.wiretap"
end

RegisterNetEvent("evidences:notify", function(translation, type, duration)
    config.notify(translation, type, duration)
end)

TriggerServerEvent("evidences:playerLoaded", cache.serverId)