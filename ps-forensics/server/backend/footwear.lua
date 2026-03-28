local resourceName = GetCurrentResourceName()

local function normalizeCitizenId(citizenid)
    if not citizenid then return nil end
    local value = tostring(citizenid):match('^%s*(.-)%s*$')
    if value == '' then return nil end
    return value
end

lib.callback.register(resourceName .. ':server:registerSuspectFootwearProfile', function(source, payload)
    local src = source
    if not CheckForensicAuth(src) then return { success = false, error = L('scene.errors.not_authorized') } end
    if not CheckForensicPermission(src, 'canCollectEvidence') then
        return { success = false, error = 'Sem permissão para coletar perfis de calçado.' }
    end

    payload = type(payload) == 'table' and payload or {}
    local citizenid = normalizeCitizenId(payload.citizenid)
    local shoeModel = payload.shoe_model and tonumber(payload.shoe_model) or nil
    local imageUrl = payload.image_url and tostring(payload.image_url) or nil
    local notes = payload.notes and tostring(payload.notes):sub(1, 1000) or nil

    if not citizenid then
        return { success = false, error = 'Citizen ID é obrigatório para registrar o calçado do suspeito.' }
    end

    local actor = GetPlayerData(src)
    if not actor then
        return { success = false, error = L('scene.errors.player_data_unavailable') }
    end

    local insertedId = MySQL.insert.await([[
        INSERT INTO forensic_footwear_profiles
        (citizenid, shoe_model, image_url, notes, created_by)
        VALUES (?, ?, ?, ?, ?)
    ]], { citizenid, shoeModel, imageUrl, notes, actor.citizenid })

    if not insertedId then
        return { success = false, error = 'Falha ao salvar perfil de calçado do suspeito.' }
    end

    ForensicAuditLog(src, 'suspect_footwear_profile_registered', 'footwear_profile', insertedId, {
        citizenid = citizenid,
        shoeModel = shoeModel,
    })

    return { success = true, id = insertedId }
end)

lib.callback.register(resourceName .. ':server:compareFootwearWithEvidence', function(source, citizenid)
    local src = source
    if not CheckForensicAuth(src) then return { success = false, error = L('scene.errors.not_authorized') } end

    citizenid = normalizeCitizenId(citizenid)
    if not citizenid then
        return { success = false, error = 'Citizen ID inválido para comparação de pegadas.' }
    end

    local profiles = MySQL.query.await([[
        SELECT id, citizenid, shoe_model, image_url, notes, created_at
        FROM forensic_footwear_profiles
        WHERE citizenid = ?
        ORDER BY created_at DESC
        LIMIT 20
    ]], { citizenid }) or {}

    if #profiles == 0 then
        return { success = true, data = { profiles = {}, matches = {} } }
    end

    local shoeModels = {}
    local seen = {}
    for _, profile in ipairs(profiles) do
        local model = profile.shoe_model and tonumber(profile.shoe_model) or nil
        if model and not seen[model] then
            seen[model] = true
            shoeModels[#shoeModels + 1] = model
        end
    end

    local matches = {}
    if #shoeModels > 0 then
        local placeholders = table.concat((function()
            local t = {}
            for _ = 1, #shoeModels do t[#t + 1] = '?' end
            return t
        end)(), ',')

        local params = {}
        for _, model in ipairs(shoeModels) do
            params[#params + 1] = tostring(model)
        end

        matches = MySQL.query.await(([[
            SELECT id, evidence_number, case_id, report_id, type, subtype, description, collection_location, created_at
            FROM forensic_evidence
            WHERE type = 'pegada'
              AND subtype IN (%s)
            ORDER BY created_at DESC
            LIMIT 200
        ]]):format(placeholders), params) or {}
    end

    return {
        success = true,
        data = {
            profiles = profiles,
            matches = matches,
        }
    }
end)

lib.callback.register(resourceName .. ':server:getEvidenceCrossMatchForPrisoner', function(source, citizenid)
    local src = source
    if not CheckForensicAuth(src) then return { success = false, error = L('scene.errors.not_authorized') } end

    citizenid = normalizeCitizenId(citizenid)
    if not citizenid then
        return { success = false, error = 'Citizen ID inválido para cruzamento.' }
    end

    local dnaProfiles = MySQL.query.await('SELECT id, profile_code, full_name, created_at FROM forensic_dna_profiles WHERE citizenid = ? ORDER BY created_at DESC LIMIT 50', { citizenid }) or {}
    local dnaMatches = MySQL.query.await('SELECT id, sample_code, evidence_id, match_confidence, result, created_at FROM forensic_dna_samples WHERE matched_citizenid = ? ORDER BY created_at DESC LIMIT 100', { citizenid }) or {}

    local fingerprintProfiles = MySQL.query.await('SELECT id, profile_code, full_name, quality, created_at FROM forensic_fingerprint_profiles WHERE citizenid = ? ORDER BY created_at DESC LIMIT 50', { citizenid }) or {}
    local fingerprintMatches = MySQL.query.await('SELECT id, evidence_id, sequence_quality, result, match_confidence, created_at FROM forensic_fingerprints_collected WHERE matched_citizenid = ? ORDER BY created_at DESC LIMIT 100', { citizenid }) or {}

    local footwearProfiles = MySQL.query.await('SELECT id, shoe_model, image_url, notes, created_at FROM forensic_footwear_profiles WHERE citizenid = ? ORDER BY created_at DESC LIMIT 50', { citizenid }) or {}

    local footprintEvidence = {}
    if #footwearProfiles > 0 then
        local placeholders = {}
        local params = {}
        local seen = {}
        for _, profile in ipairs(footwearProfiles) do
            local shoeModel = profile.shoe_model and tonumber(profile.shoe_model) or nil
            if shoeModel and not seen[shoeModel] then
                seen[shoeModel] = true
                placeholders[#placeholders + 1] = '?'
                params[#params + 1] = tostring(shoeModel)
            end
        end

        if #placeholders > 0 then
            footprintEvidence = MySQL.query.await(([[
                SELECT id, evidence_number, case_id, report_id, subtype, description, collection_location, created_at
                FROM forensic_evidence
                WHERE type = 'pegada' AND subtype IN (%s)
                ORDER BY created_at DESC
                LIMIT 200
            ]]):format(table.concat(placeholders, ',')), params) or {}
        end
    end

    local prisonRecords = MySQL.query.await([[
        SELECT id, reason, sentence, reduction, amount, created_at, officer, new_timer
        FROM mdt_arrests
        WHERE citizenid = ?
        ORDER BY created_at DESC
        LIMIT 25
    ]], { citizenid }) or {}

    return {
        success = true,
        data = {
            citizenid = citizenid,
            dna_profiles = dnaProfiles,
            dna_matches = dnaMatches,
            fingerprint_profiles = fingerprintProfiles,
            fingerprint_matches = fingerprintMatches,
            footwear_profiles = footwearProfiles,
            footprint_evidence = footprintEvidence,
            prison_records = prisonRecords,
        }
    }
end)
