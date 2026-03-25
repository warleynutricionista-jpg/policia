
local resourceName = tostring(GetCurrentResourceName())
local WEAPON_DIRECTORY_CACHE_KEY = 'weapons:directory'
local WEAPON_DIRECTORY_TTL = 12
local ps = RequirePs('server/backend/weapons.lua')

local class = {
    -- pistol
    weapon_pistol                ={type = 'pistol', class  = 1},
	weapon_pistol_mk2            ={type = 'pistol', class  = 1},
	weapon_combatpistol          ={type = 'pistol', class  = 1},
	weapon_appistol              ={type = 'pistol', class  = 1},
	weapon_stungun               ={type = 'pistol', class  = 1},
	weapon_pistol50              ={type = 'pistol', class  = 1},
	weapon_snspistol             ={type = 'pistol', class  = 1},
	weapon_snspistol_mk2         ={type = 'pistol', class  = 1},
	weapon_heavypistol           ={type = 'pistol', class  = 1},
	weapon_vintagepistol         ={type = 'pistol', class  = 1},
	weapon_flaregun              ={type = 'pistol', class  = 1},
	weapon_marksmanpistol        ={type = 'pistol', class  = 1},
	weapon_revolver              ={type = 'pistol', class  = 1},
	weapon_revolver_mk2          ={type = 'pistol', class  = 1},
	weapon_doubleaction          ={type = 'pistol', class  = 1},
	weapon_raypistol             ={type = 'pistol', class  = 1},
	weapon_ceramicpistol         ={type = 'pistol', class  = 1},
	weapon_navyrevolver          ={type = 'pistol', class  = 1},
	weapon_gadgetpistol          ={type = 'pistol', class  = 1},
	weapon_stungun_mp            ={type = 'pistol', class  = 1},
	weapon_pistolxm3             ={type = 'pistol', class  = 1},
    -- SMG
    weapon_microsmg              ={type = 'smg', class  = 2},
	weapon_smg                   ={type = 'smg', class  = 2},
	weapon_smg_mk2               ={type = 'smg', class  = 2},
	weapon_assaultsmg            ={type = 'smg', class  = 2},
	weapon_combatpdw             ={type = 'smg', class  = 2},
	weapon_machinepistol         ={type = 'smg', class  = 2},
	weapon_minismg               ={type = 'smg', class  = 2},
	weapon_raycarbine            ={type = 'smg', class  = 2},
    -- shotguns
    weapon_pumpshotgun           ={type = 'shotgun', class  = 3},
	weapon_pumpshotgun_mk2       ={type = 'shotgun', class  = 3},
	weapon_sawnoffshotgun        ={type = 'shotgun', class  = 3},
	weapon_assaultshotgun        ={type = 'shotgun', class  = 3},
	weapon_bullpupshotgun        ={type = 'shotgun', class  = 3},
	weapon_musket                ={type = 'shotgun', class  = 3},
	weapon_heavyshotgun          ={type = 'shotgun', class  = 3},
	weapon_dbshotgun             ={type = 'shotgun', class  = 3},
	weapon_autoshotgun           ={type = 'shotgun', class  = 3},
	weapon_combatshotgun         ={type = 'shotgun', class  = 3},
    -- assault rifles
    weapon_assaultrifle          ={type = 'assault', class  = 4},
	weapon_assaultrifle_mk2      ={type = 'assault', class  = 4},
	weapon_carbinerifle          ={type = 'assault', class  = 4},
	weapon_carbinerifle_mk2      ={type = 'assault', class  = 4},
	weapon_advancedrifle         ={type = 'assault', class  = 4},
	weapon_specialcarbine        ={type = 'assault', class  = 4},
	weapon_specialcarbine_mk2   = {type = 'assault', class  = 4},
	weapon_bullpuprifle         = {type = 'assault', class  = 4},
	weapon_bullpuprifle_mk2     = {type = 'assault', class  = 4},
	weapon_compactrifle         = {type = 'assault', class  = 4},
	weapon_militaryrifle        = {type = 'assault', class  = 4},
	weapon_heavyrifle           = {type = 'assault', class  = 4},
    -- light machine guns
    weapon_mg                    ={type = 'lmg', class  = 5},
    weapon_combatmg              ={type = 'lmg', class  = 5},
    weapon_combatmg_mk2          ={type = 'lmg', class  = 5},
    weapon_gusenberg             ={type = 'lmg', class  = 5},
    --- sniper rifles
    weapon_sniperrifle           ={type = 'sniper', class  = 6},
    weapon_heavysniper           ={type = 'sniper', class  = 6},
    weapon_heavysniper_mk2       ={type = 'sniper', class  = 6},
    weapon_marksmanrifle         ={type = 'sniper', class  = 6},
    weapon_marksmanrifle_mk2     ={type = 'sniper', class  = 6},
    weapon_precisionrifle        ={type = 'sniper', class  = 6},
    -- heavy
    weapon_rpg                   ={type = 'heavy', class  = 7},
    weapon_grenadelauncher       ={type = 'heavy', class  = 7},
    weapon_grenadelauncher_smoke ={type = 'heavy', class  = 7},
    weapon_minigun               ={type = 'heavy', class  = 7},
    weapon_firework              ={type = 'heavy', class  = 7},
    weapon_railgun               ={type = 'heavy', class  = 7},
    weapon_hominglauncher        ={type = 'heavy', class  = 7},
    weapon_compactlauncher       ={type = 'heavy', class  = 7},
    weapon_rayminigun            ={type = 'heavy', class  = 7},
}
-- QBox-first core object resolution
local QBCore = nil
do
    local okQbx, qbx = pcall(function() return exports['qbx_core']:GetCoreObject() end)
    if okQbx and qbx then
        QBCore = qbx
    else
        local okQb, qb = pcall(function() return exports['qb-core']:GetCoreObject() end)
        if okQb and qb then QBCore = qb end
    end
end

local defaultWeaponRegistrationConfig = {
    RegisterWeaponsAutomatically = true,
    RegisterCreatedWeapons = false,
}

local weaponConfigWarningShown = false

local function getWeaponRegistrationConfig()
    local configRef = rawget(_G, 'Config')
    if type(configRef) ~= 'table' then
        if not weaponConfigWarningShown then
            weaponConfigWarningShown = true
            ps.warn('Config global is unavailable in server/backend/weapons.lua; using safe weapon registration defaults until config loads')
        end

        return defaultWeaponRegistrationConfig
    end

    return {
        RegisterWeaponsAutomatically = configRef.RegisterWeaponsAutomatically ~= false,
        RegisterCreatedWeapons = configRef.RegisterCreatedWeapons == true,
    }
end

local function registerWeapon(citizenid, weaponName, serial, info)
    -- Ensure profile exists so owner name can be resolved later
    if citizenid and citizenid ~= '' then
        EnsureProfileExists(citizenid)
    end

    -- Normalize weapon model to lowercase for class table lookup
    local modelLower = weaponName and string.lower(weaponName) or ''
    local weaponClass = class[modelLower] and class[modelLower].class or 1

    Cache.invalidate(WEAPON_DIRECTORY_CACHE_KEY)
    MySQL.query.await('INSERT INTO mdt_weapons (serial, scratched, owner, information, weaponClass, weaponModel) VALUES (?, ?, ?, ?, ?, ?)', {
        serial, false, citizenid, info or '', weaponClass, weaponName
    })
    MySQL.insert.await([[
        INSERT INTO mdt_weapon_ownership_history (serial, owner, weapon_model, weapon_class, information, changed_by, reason)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        serial,
        citizenid,
        weaponName,
        weaponClass,
        info or '',
        citizenid,
        'register'
    })
end

exports('registerWeapon', registerWeapon)


local function paginateRows(rows, page, limit)
    local safeLimit = math.max(1, tonumber(limit) or (Config.Pagination and Config.Pagination.Weapons) or 25)
    safeLimit = math.min(safeLimit, 100)
    local safePage = math.max(1, tonumber(page) or 1)
    local total = #rows
    local offset = (safePage - 1) * safeLimit
    local out = {}
    for i = offset + 1, math.min(total, offset + safeLimit) do
        out[#out + 1] = rows[i]
    end
    return out, total, safePage, safeLimit, (offset + safeLimit) < total
end

local function buildWeaponDirectory()
    return Cache.getOrSet(WEAPON_DIRECTORY_CACHE_KEY, WEAPON_DIRECTORY_TTL, function()
        local weapons = MySQL.query.await('SELECT * FROM mdt_weapons ORDER BY id DESC') or {}
        local ownerIds = {}
        for _, v in pairs(weapons) do
            if v.owner and v.owner ~= '' then
                ownerIds[v.owner] = true
            end
        end

        local ownerNames = {}
        local ownerList = {}
        for cid in pairs(ownerIds) do
            ownerList[#ownerList + 1] = cid
        end
        if #ownerList > 0 then
            local placeholders = string.rep('?,', #ownerList):sub(1, -2)
            local ownerRows = MySQL.query.await(('SELECT citizenid, fullname FROM mdt_profiles WHERE citizenid IN (%s)'):format(placeholders), ownerList) or {}
            for _, row in ipairs(ownerRows) do
                if row.fullname and row.fullname ~= '' then
                    ownerNames[row.citizenid] = row.fullname
                end
            end
        end

        local mapped = {}
        for _, v in pairs(weapons) do
            local ownerName = 'Desconhecido'
            if v.owner and v.owner ~= '' then
                ownerName = ownerNames[v.owner] or ps.getPlayerNameByIdentifier(v.owner) or 'Desconhecido'
            end

            local modelLower = v.weaponModel and string.lower(v.weaponModel) or ''
            mapped[#mapped + 1] = {
                id = v.id,
                serial = v.serial,
                scratched = v.scratched == 1,
                owner = ownerName,
                ownerCitizenId = v.owner,
                information = v.information,
                weaponClass = v.weaponClass,
                weaponModel = v.weaponModel,
                name = (QBCore and QBCore.Shared and QBCore.Shared.Weapons and QBCore.Shared.Weapons[GetHashKey(v.weaponModel)] and QBCore.Shared.Weapons[GetHashKey(v.weaponModel)].label) or v.weaponModel,
                image = 'https://docs.fivem.net/weapons/' .. v.weaponModel:upper() .. '.png',
                type = class[modelLower] and class[modelLower].type or 'unknown',
            }
        end
        return mapped
    end) or {}
end

ps.registerCallback('ps-mdt:server:getWeapons', function(source, payload)
    if not CheckAuth(source) then return { weapons = {}, bolos = {}, page = 1, limit = 25, total = 0, hasMore = false } end
    payload = payload or {}
    local page = payload.page or payload.currentPage or 1
    local limit = payload.limit

    local pagedWeapons, total, safePage, safeLimit, hasMore = paginateRows(buildWeaponDirectory(), page, limit)
    local weaponBolo = {}
    local weaponBolos = MySQL.query.await('SELECT * FROM mdt_bolos WHERE type = ? AND status = ?', {'weapon', 'active'})
    for _, v in pairs(weaponBolos or {}) do
        weaponBolo[#weaponBolo + 1] = {
            id = v.id,
            reportId = v.reportId and tostring(v.reportId) or 'N/A',
            name = v.subject_name or 'Unknown Weapon',
            type = v.type,
            notes = v.notes or '',
            status = v.status,
            serial = v.subject_id or 'Desconhecido',
        }
    end
    return { weapons = pagedWeapons, bolos = weaponBolo, page = safePage, limit = safeLimit, total = total, hasMore = hasMore }
end)

ps.registerCallback(resourceName .. ':server:searchWeapons', function(source, payload)
    if not CheckAuth(source) then return { weapons = {}, bolos = {}, page = 1, limit = 25, total = 0, hasMore = false } end

    if type(payload) ~= 'table' then
        payload = { query = payload }
    end

    local query = tostring(payload.query or '')
    local needle = query:match('^%s*(.-)%s*$'):lower()
    local compact = needle:gsub('%s+', '')
    if needle == '' then
        return { weapons = {}, bolos = {}, page = 1, limit = payload.limit or 25, total = 0, hasMore = false }
    end

    local filtered = {}
    for _, weapon in ipairs(buildWeaponDirectory()) do
        local haystacks = {
            weapon.serial or '',
            weapon.owner or '',
            weapon.ownerCitizenId or '',
            weapon.information or '',
            weapon.weaponModel or '',
            weapon.name or '',
        }
        for i = 1, #haystacks do
            local value = tostring(haystacks[i]):lower()
            if value:find(needle, 1, true) or value:gsub('%s+', ''):find(compact, 1, true) then
                filtered[#filtered + 1] = weapon
                break
            end
        end
    end

    local pagedWeapons, total, safePage, safeLimit, hasMore = paginateRows(filtered, payload.page or 1, payload.limit)
    return { weapons = pagedWeapons, bolos = {}, page = safePage, limit = safeLimit, total = total, hasMore = hasMore }
end)

ps.registerCallback(resourceName .. ':server:getWeaponOwnershipHistory', function(source, serial)
    local src = source
    if not CheckAuth(src) then return end
    if not serial or serial == '' then return {} end

    local rows = MySQL.query.await([[
        SELECT id, serial, owner, weapon_model, weapon_class, information, changed_by, reason, created_at
        FROM mdt_weapon_ownership_history
        WHERE serial = ?
        ORDER BY created_at DESC
    ]], { serial })
    return rows or {}
end)

ps.registerCallback(resourceName .. ':server:getWeapon', function(source, serial)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end
    if not serial or serial == '' then
        return { success = false, message = 'Faltando número de série' }
    end

    local v = MySQL.single.await('SELECT * FROM mdt_weapons WHERE serial = ? LIMIT 1', { serial })
    if not v then
        return { success = false, message = 'Arma não encontrada' }
    end

    local ownerName = 'Desconhecido'
    if v.owner and v.owner ~= '' then
        local profile = MySQL.single.await('SELECT fullname FROM mdt_profiles WHERE citizenid = ?', { v.owner })
        if profile and profile.fullname and profile.fullname ~= '' then
            ownerName = profile.fullname
        else
            ownerName = ps.getPlayerNameByIdentifier(v.owner) or 'Desconhecido'
        end
    end

    local modelLower = v.weaponModel and string.lower(v.weaponModel) or ''
    return {
        success = true,
        weapon = {
            id = v.id,
            serial = v.serial,
            scratched = v.scratched == 1,
            owner = ownerName,
            ownerCitizenId = v.owner,
            information = v.information,
            weaponClass = v.weaponClass,
            weaponModel = v.weaponModel,
            name = (QBCore and QBCore.Shared and QBCore.Shared.Weapons and QBCore.Shared.Weapons[GetHashKey(v.weaponModel)] and QBCore.Shared.Weapons[GetHashKey(v.weaponModel)].label) or v.weaponModel,
            image = 'https://docs.fivem.net/weapons/' .. v.weaponModel:upper() .. '.png',
            type = class[modelLower] and class[modelLower].type or 'unknown',
        }
    }
end)

-- Save/Edit Weapon Info (from NUI)
ps.registerCallback(resourceName .. ':server:saveWeaponInfo', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end

    payload = payload or {}
    local serial = payload.serial
    local notes = payload.notes or ''
    local imageurl = payload.imageurl or ''
    local owner = payload.owner or ''
    local weapClass = tonumber(payload.weapClass) or 1
    local weapModel = payload.weapModel or ''

    if not serial or serial == '' then
        return { success = false, message = 'Faltando número de série' }
    end

    local existing = MySQL.single.await('SELECT id FROM mdt_weapons WHERE serial = ? LIMIT 1', { serial })

    if existing then
        Cache.invalidate(WEAPON_DIRECTORY_CACHE_KEY)
        MySQL.update.await([[
            UPDATE mdt_weapons
            SET information = ?, owner = ?, weaponClass = ?, weaponModel = ?
            WHERE serial = ?
        ]], { notes, owner, weapClass, weapModel, serial })
    else
        Cache.invalidate(WEAPON_DIRECTORY_CACHE_KEY)
        MySQL.insert.await([[
            INSERT INTO mdt_weapons (serial, scratched, owner, information, weaponClass, weaponModel)
            VALUES (?, 0, ?, ?, ?, ?)
        ]], { serial, owner, notes, weapClass, weapModel })

        MySQL.insert.await([[
            INSERT INTO mdt_weapon_ownership_history (serial, owner, weapon_model, weapon_class, information, changed_by, reason)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ]], { serial, owner, weapModel, weapClass, notes, ps.getIdentifier(src), 'manual_entry' })
    end

    if ps.auditLog then
        ps.auditLog(src, existing and 'weapon_updated' or 'weapon_created', 'weapon', serial, {
            owner = owner,
            model = weapModel,
        })
    end

    return { success = true, message = existing and 'Weapon info updated' or 'Weapon info created' }
end)

-- Delete Weapon Record
ps.registerCallback(resourceName .. ':server:deleteWeapon', function(source, payload)
    local src = source
    if not CheckAuth(src) then return { success = false, message = 'Não autorizado' } end

    payload = payload or {}
    local id = tonumber(payload.id)
    local serial = payload.serial

    if not id and not serial then
        return { success = false, message = 'Faltando ID da arma ou série' }
    end

    local deleted = 0
    if id then
        local wep = MySQL.single.await('SELECT serial FROM mdt_weapons WHERE id = ?', { id })
        serial = wep and wep.serial or serial
        Cache.invalidate(WEAPON_DIRECTORY_CACHE_KEY)
        deleted = MySQL.update.await('DELETE FROM mdt_weapons WHERE id = ?', { id })
    elseif serial then
        Cache.invalidate(WEAPON_DIRECTORY_CACHE_KEY)
        deleted = MySQL.update.await('DELETE FROM mdt_weapons WHERE serial = ?', { serial })
    end

    if deleted and deleted > 0 and ps.auditLog then
        ps.auditLog(src, 'weapon_deleted', 'weapon', serial or tostring(id), {})
    end

    return { success = deleted and deleted > 0, message = deleted > 0 and 'Weapon deleted' or 'Weapon not found' }
end)

-- Scan player inventory for weapons (for self-register)
ps.registerCallback(resourceName .. ':server:getWeaponInfo', function(source)
    local src = source
    if not QBCore then return {} end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return {} end

    local weaponInfos = {}

    if GetResourceState('ox_inventory') == 'started' then
        local success, inv = pcall(function()
            return exports.ox_inventory:GetInventoryItems(src)
        end)
        if success and inv then
            for _, item in pairs(inv) do
                if item.name and string.find(item.name, 'WEAPON_') then
                    local invImage = ('https://cfx-nui-ox_inventory/web/images/%s.png'):format(item.name)
                    weaponInfos[#weaponInfos + 1] = {
                        serialnumber = item.metadata and item.metadata.serial or 'Desconhecido',
                        owner = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                        weaponmodel = (QBCore.Shared.Items[string.lower(item.name)] and QBCore.Shared.Items[string.lower(item.name)].label) or item.name,
                        weaponurl = invImage,
                        notes = 'Self Registered',
                        weapClass = 1,
                    }
                end
            end
        end
    else
        if Player.PlayerData.items then
            for _, item in pairs(Player.PlayerData.items) do
                if item.type == 'weapon' then
                    weaponInfos[#weaponInfos + 1] = {
                        serialnumber = item.info and item.info.serie or 'Desconhecido',
                        owner = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                        weaponmodel = (QBCore.Shared.Items[item.name] and QBCore.Shared.Items[item.name].label) or item.name,
                        weaponurl = item.image or '',
                        notes = 'Self Registered',
                        weapClass = 1,
                    }
                end
            end
        end
    end

    return weaponInfos
end)

-- ox_inventory weapon auto-registration hooks
CreateThread(function()
    Wait(2000)

    if GetResourceState('ox_inventory') ~= 'started' then return end

    local weaponConfig = getWeaponRegistrationConfig()
    if not weaponConfig.RegisterWeaponsAutomatically then return end

    exports.ox_inventory:registerHook('buyItem', function(payload)
        if not payload.itemName or not string.find(payload.itemName, 'WEAPON_') then return true end
        CreateThread(function()
            if not QBCore then return end
            local Player = QBCore.Functions.GetPlayer(payload.source)
            if not Player then return end
            local owner = Player.PlayerData.citizenid
            if not owner or not payload.metadata or not payload.metadata.serial then return end

            local success, err = pcall(function()
                exports[resourceName]:registerWeapon(owner, payload.itemName, payload.metadata.serial, 'Purchased from shop')
            end)
            if not success then
                ps.warn('Error auto-registering weapon: ' .. tostring(err))
            end
        end)
        return true
    end, {
        typeFilter = { ['player'] = true }
    })

    if weaponConfig.RegisterCreatedWeapons then
        exports.ox_inventory:registerHook('createItem', function(payload)
            if not payload.item or not payload.item.name or not string.find(payload.item.name, 'WEAPON_') then return true end
            CreateThread(function()
                if not QBCore then return end
                local Player = QBCore.Functions.GetPlayer(payload.inventoryId)
                if not Player then return end
                local owner = Player.PlayerData.citizenid
                if not owner or not payload.metadata or not payload.metadata.serial then return end

                local success, err = pcall(function()
                    exports[resourceName]:registerWeapon(owner, payload.item.name, payload.metadata.serial, 'Purchased from shop')
                end)
                if not success then
                    ps.warn('Error auto-registering created weapon: ' .. tostring(err))
                end
            end)
            return true
        end, {
            typeFilter = { ['player'] = true }
        })
    end
end)

-- Legacy qb-inventory fallback without relying on QBCore:Player:SetPlayerData.
-- Some modern QBox/QBCore bases warn when that event path is treated as a net
-- update, so we reconcile the server-side inventory snapshot for online players.
do
    local weaponConfig = getWeaponRegistrationConfig()
    if not weaponConfig.RegisterWeaponsAutomatically then return end

    local knownSerials = {} -- [citizenid] = { [serial] = true }

    --- Build a set of weapon serials from a player's items table
    local function getWeaponSerials(items)
        local serials = {}
        if not items then return serials end
        for _, item in pairs(items) do
            if item.name and string.find(string.upper(item.name), 'WEAPON_') then
                local serial = item.info and (item.info.serie or item.info.serial) or nil
                if serial then
                    serials[serial] = item.name
                end
            end
        end
        return serials
    end

    local function reconcilePlayerWeapons(src, seedOnly)
        if not QBCore then return end
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player or not Player.PlayerData or not Player.PlayerData.citizenid then return end

        local playerData = Player.PlayerData
        local citizenid = playerData.citizenid
        local currentSerials = getWeaponSerials(playerData.items)

        if not knownSerials[citizenid] then
            knownSerials[citizenid] = {}
            for serial, _ in pairs(currentSerials) do
                knownSerials[citizenid][serial] = true
            end
            return
        end

        if seedOnly then
            return
        end

        for serial, itemName in pairs(currentSerials) do
            if not knownSerials[citizenid][serial] then
                knownSerials[citizenid][serial] = true
                local _cid = citizenid
                local _serial = serial
                local _model = string.upper(itemName)
                CreateThread(function()
                    local existing = MySQL.single.await('SELECT id FROM mdt_weapons WHERE serial = ? LIMIT 1', { _serial })
                    if existing then return end
                    local ok, err = pcall(function()
                        exports[resourceName]:registerWeapon(_cid, _model, _serial, 'Purchased from shop')
                    end)
                    if not ok then
                        ps.warn('Auto-register weapon failed: ' .. tostring(err))
                    end
                end)
            end
        end
    end

    CreateThread(function()
        if GetResourceState('ox_inventory') == 'started' then
            return
        end

        Wait(2000)

        for _, playerId in ipairs(GetPlayers()) do
            reconcilePlayerWeapons(tonumber(playerId), true)
        end

        while true do
            Wait(30000)
            for _, playerId in ipairs(GetPlayers()) do
                reconcilePlayerWeapons(tonumber(playerId), false)
            end
        end
    end)

    -- Clean up tracking when player drops
    AddEventHandler('playerDropped', function()
        local src = source
        if not QBCore then return end
        local Player = QBCore.Functions.GetPlayer(src)
        if Player and Player.PlayerData and Player.PlayerData.citizenid then
            knownSerials[Player.PlayerData.citizenid] = nil
        end
    end)
end

-- Weapon Self-Register (server event from 3rd eye)
RegisterNetEvent(resourceName .. ':server:selfRegisterWeapon')
AddEventHandler(resourceName .. ':server:selfRegisterWeapon', function(serial, imageurl, notes, owner, weapClass, weapModel)
    local src = source
    if not serial then return end

    local success, err = pcall(function()
        exports[resourceName]:registerWeapon(owner or ps.getIdentifier(src), weapModel or 'unknown', serial, notes or 'Self Registered')
    end)

    if success then
        ps.notify(src, 'Arma registrada no banco de dados policial', 'success')
    end
end)
