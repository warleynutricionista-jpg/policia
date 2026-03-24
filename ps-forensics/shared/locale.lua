ForensicLocale = ForensicLocale or {}

local function deepMerge(base, override)
    if type(base) ~= 'table' then return override end
    local result = {}

    for key, value in pairs(base) do
        if type(value) == 'table' then
            result[key] = deepMerge(value, {})
        else
            result[key] = value
        end
    end

    if type(override) == 'table' then
        for key, value in pairs(override) do
            if type(value) == 'table' and type(result[key]) == 'table' then
                result[key] = deepMerge(result[key], value)
            else
                result[key] = value
            end
        end
    end

    return result
end

local function loadLocale(locale)
    local raw = LoadResourceFile(GetCurrentResourceName(), ('locales/%s.lua'):format(locale))
    if not raw then return nil end

    local chunk, err = load(raw, ('@@locales/%s.lua'):format(locale), 't', {})
    if not chunk then
        print(('[ps-forensics] ^1Locale parse error (%s): %s^0'):format(locale, tostring(err)))
        return nil
    end

    local ok, data = pcall(chunk)
    if not ok then
        print(('[ps-forensics] ^1Locale load error (%s): %s^0'):format(locale, tostring(data)))
        return nil
    end

    if type(data) ~= 'table' then
        print(('[ps-forensics] ^1Locale invalid format (%s).^0'):format(locale))
        return nil
    end

    return data
end

function ForensicLocale.Init()
    local fallback = Config and Config.Locale and Config.Locale.fallback or 'pt-BR'
    local current = Config and Config.Locale and Config.Locale.current or fallback

    local fallbackData = loadLocale(fallback) or {}
    local currentData = current == fallback and fallbackData or (loadLocale(current) or {})

    ForensicLocale.current = current
    ForensicLocale.fallback = fallback
    ForensicLocale.data = deepMerge(fallbackData, currentData)
end

function ForensicLocale.Get(path, ...)
    if not ForensicLocale.data then
        ForensicLocale.Init()
    end

    local node = ForensicLocale.data
    for key in tostring(path):gmatch('[^.]+') do
        if type(node) ~= 'table' then
            node = nil
            break
        end
        node = node[key]
    end

    if node == nil then
        return path
    end

    if select('#', ...) > 0 and type(node) == 'string' then
        return node:format(...)
    end

    return node
end

function L(path, ...)
    return ForensicLocale.Get(path, ...)
end
