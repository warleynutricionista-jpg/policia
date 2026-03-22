-- Sound definitions
local MDTSounds = {
    open = {
        audioName = 'ATM_WINDOW',
        audioRef = 'HUD_FRONTEND_DEFAULT_SOUNDSET'
    },
    close = {
        audioName = 'BACK',
        audioRef = 'HUD_FRONTEND_DEFAULT_SOUNDSET'
    },
    buttonClick = {
        audioName = 'SELECT',
        audioRef = 'HUD_FRONTEND_DEFAULT_SOUNDSET'
    },
}

-- Play sound based on input
function PlayMDTSound(soundType)
    if not MDTSounds[soundType] then
        ps.debug('Unknown MDT sound type:', soundType)
        return
    end

    local sound = MDTSounds[soundType]
    local played = false

    if GetResourceState('ps_lib') == 'started' then
        local ok = pcall(function()
            exports.ps_lib:PlaySound({
                audioName = sound.audioName,
                audioRef = sound.audioRef
            })
        end)
        played = ok
    end

    if not played then
        PlaySoundFrontend(-1, sound.audioName, sound.audioRef, true)
    end

    ps.debug('Playing MDT sound:', soundType)
end
