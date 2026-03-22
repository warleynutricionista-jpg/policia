local resourceName = tostring(GetCurrentResourceName())
local ps = RequirePs('client/events.lua')

local function isAuthorizedJob(job)
    if not job then return false, nil end
    if job.type == Config.PoliceJobType then return true, 'leo' end
    if job.type == Config.MedicalJobType then return true, 'ems' end
    -- Also check by job name for QBox compatibility
    if Config.PoliceJobs then
        for _, policeJob in ipairs(Config.PoliceJobs) do
            if job.name == policeJob then return true, 'leo' end
        end
    end
    if Config.DojJobs then
        for _, dojJob in ipairs(Config.DojJobs) do
            if job.name == dojJob then return true, 'leo' end
        end
    end
    return false, nil
end

function NUIUpdateAuthWithData(jobData)
    local job = jobData or ps.getJob()
    local authorized, jobType = isAuthorizedJob(job)
    local onDuty = job and job.onduty or false

    SendNUI('updateAuth', {
        authorized = authorized and onDuty,
        playerData = ps.getPlayerData(),
        isLEO = authorized,
        onDuty = onDuty,
        jobType = jobType or 'leo'
    })
end

local function onJobUpdate(JobInfo)
    local job = JobInfo or ps.getJob()
    ps.debug('Updated job info:', job)

    if MDTOpen then
        local authorized = isAuthorizedJob(job)

        if not authorized then
            CloseMDT()
            ps.notify('MDT fechado - acesso revogado', 'error')
        else
            NUIUpdateAuthWithData(job)
        end
    end
end

local function onSetDuty(duty)
    if MDTOpen then
        local job = ps.getJob()
        if job then
            job.onduty = duty
            NUIUpdateAuthWithData(job)

            local authorized = isAuthorizedJob(job)
            if not authorized or not duty then
                CloseMDT()
                ps.notify('MDT fechado - fora de serviço', 'error')
            end
        end
    end
end

local function bindLocalFrameworkEvents()
    -- Framework job/duty updates are local/internal events. Listening with AddEventHandler
    -- avoids treating them as network events in newer QBox/QBCore setups.
    AddEventHandler('QBCore:Client:SetDuty', function(duty)
        ps.debug('SetDuty event received:', duty)
        onSetDuty(duty)
    end)

    AddEventHandler('QBCore:Client:OnJobUpdate', function(JobInfo)
        ps.debug('OnJobUpdate event received:', JobInfo)
        onJobUpdate(JobInfo)
    end)

    AddEventHandler('qbx_core:client:onJobUpdate', function(jobData)
        ps.debug('QBox onJobUpdate event received:', jobData)
        onJobUpdate(jobData)
    end)

    AddEventHandler('qbx_core:client:onSetDuty', function(duty)
        ps.debug('QBox onSetDuty event received:', duty)
        onSetDuty(duty)
    end)
end

local function bindLocalStateBagUpdates()
    local playerId = PlayerId()
    if playerId == -1 then return end

    local serverId = GetPlayerServerId(playerId)
    if not serverId then return end

    local bagName = ('player:%s'):format(serverId)

    AddStateBagChangeHandler('job', bagName, function(_, _, value)
        if type(value) ~= 'table' then return end
        ps.debug('State bag job update received:', value)
        onJobUpdate(value)
    end)

    AddStateBagChangeHandler('onduty', bagName, function(_, _, value)
        if type(value) ~= 'boolean' then return end
        ps.debug('State bag duty update received:', value)
        onSetDuty(value)
    end)
end

bindLocalFrameworkEvents()
CreateThread(function()
    while GetPlayerServerId(PlayerId()) <= 0 do
        Wait(250)
    end

    bindLocalStateBagUpdates()
end)

-- Send Profile Data
RegisterNetEvent(resourceName..':client:sendProfile', function(data)
    if MDTOpen then
        SendNUI('updateProfile', data)
    end
end)

-- Handle player death - close MDT for realism
if GetResourceState('baseevents') == 'started' then
    RegisterNetEvent('baseevents:onPlayerDied', function()
        if MDTOpen then
            ps.debug('Player died')
            CloseMDT()
        end
    end)
end

-- QBox death event
RegisterNetEvent('qbx_medical:client:onDeath', function()
    if MDTOpen then
        ps.debug('Player died (QBox)')
        CloseMDT()
    end
end)

-- Handle cuffed state - close MDT when player gets cuffed (realism)
RegisterNetEvent('police:client:GetCuffed', function()
    if MDTOpen then
        ps.debug('Player got cuffed - closing MDT')
        CloseMDT()
        ps.notify('MDT fechado - você está algemado', 'error')
    end
end)
