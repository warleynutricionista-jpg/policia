local resourceName = tostring(GetCurrentResourceName())

-- Camera viewing state
local currentCamera = nil
local isViewingCamera = false
local hiddenCameraEntity = nil
local currentCameraData = nil

-- Forward declarations
local startCameraControlThread
local updateCameraControls

-- Camera control settings (from Config with fallbacks)
local camCfg = Config.CameraViewer or {}
local cameraOptions = {
    rotationSpeed = camCfg.RotationSpeed or 0.15,
    zoomClamp = {min = camCfg.ZoomClamp and camCfg.ZoomClamp.min or 0.25, max = camCfg.ZoomClamp and camCfg.ZoomClamp.max or 10.0},
    startingZoom = camCfg.StartingZoom or 3.0,
    zoomStep = camCfg.ZoomStep or 0.1,
}

-- Camera placement system
local CameraPlacement = {}
local cameraModelsCache = nil

-- Camera Viewing ---------------------------------------

-- Stop camera view
local function stopCameraView(notifyServer)
    ps.debug('Stopping camera view, notifyServer:', notifyServer)

    if isViewingCamera and currentCamera then
        DoScreenFadeOut(250)
        while not IsScreenFadedOut() do
            Wait(0)
        end

        SetCamActive(currentCamera, false)
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(currentCamera, false)
        currentCamera = nil
        isViewingCamera = false

        if hiddenCameraEntity and DoesEntityExist(hiddenCameraEntity) then
            ps.debug('Restoring visibility of camera entity:', hiddenCameraEntity)
            SetEntityVisible(hiddenCameraEntity, true, false)
            hiddenCameraEntity = nil
        end

        ClearTimecycleModifier()

        ps.debug('Clearing focus area')
        ClearFocus()

        DoScreenFadeIn(250)

        if notifyServer then
            if currentCameraData and currentCameraData.isBodycam then
                local bodycamId = currentCameraData.targetSource and tostring(currentCameraData.targetSource) or 'unknown'
                ps.debug('Notifying server to deactivate bodycam:', bodycamId)
                TriggerServerEvent(resourceName .. ':server:deactivateBodycam', bodycamId)
            else
                ps.debug('Notifying server to deactivate regular camera')
                TriggerServerEvent(resourceName .. ':server:deactivateCamera', 'current')
            end
        end

        currentCameraData = nil

        ps.debug('Camera view stopped')
    else
        ps.debug('No active camera view to stop')
    end
end

-- Start camera view
RegisterNetEvent(resourceName..':client:startCameraView', function(cameraData)
    ps.debug('Starting camera view with data type:', type(cameraData))
    ps.debug('Starting camera view with data:', json.encode(cameraData or {}))

    -- Validate
    if not cameraData or type(cameraData) ~= 'table' then
        ps.error('Invalid camera data received - type: ' .. type(cameraData))
        return
    end

    if not cameraData.coords or not cameraData.rotation then
        ps.error('Camera data missing coords or rotation')
        return
    end

    ps.debug('Camera coords:', cameraData.coords)
    ps.debug('Camera rotation:', cameraData.rotation)

    -- Stop any existing camera view first
    if isViewingCamera and currentCamera then
        ps.debug('Stopping existing camera view first...')
        stopCameraView(true)
    end

    DoScreenFadeOut(250)
    while not IsScreenFadedOut() do
        Wait(0)
    end

    -- Set focus area to the camera coordinates to ensure the area is streamed
    ps.debug('Setting focus area to camera coordinates:', cameraData.coords.x, cameraData.coords.y, cameraData.coords.z)
    SetFocusPosAndVel(cameraData.coords.x, cameraData.coords.y, cameraData.coords.z, 0, 0, 0)
    -- Wait a moment for the focus area to take effect
    Wait(100)

    -- Create a camera that views from the entity coords
    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    ps.debug('CreateCam result:', cam, 'type:', type(cam))

    -- Hide the camera entity if it exists to avoid obscuring the view
    if cameraData.networkId then
        local cameraEntity = NetworkGetEntityFromNetworkId(cameraData.networkId)
        if cameraEntity and DoesEntityExist(cameraEntity) then
            ps.debug('Hiding camera entity:', cameraEntity, 'with network ID:', cameraData.networkId)
            SetEntityVisible(cameraEntity, false, false)
            hiddenCameraEntity = cameraEntity
        else
            ps.debug('Camera entity not found or does not exist for network ID:', cameraData.networkId)
        end
    end

    if cam and cam ~= 0 then
        -- Use the coords and rot from server
        local coords = cameraData.coords
        local rotation = cameraData.rotation
        ps.debug('Using coords from server data:', tostring(coords))
        ps.debug('Using rotation from server data:', tostring(rotation))

        -- Set camera pos and rot
        SetCamCoord(cam, coords.x, coords.y, coords.z)
        SetCamRot(cam, rotation.x, rotation.y, rotation.z, 2)
        SetCamFov(cam, 50.0)

        ps.debug('Camera properties set - Position:', tostring(coords), 'Rotation:', tostring(rotation))

        -- debug shit
        -- local camCoords = GetCamCoord(cam)
        -- local camRot = GetCamRot(cam, 2)
        -- ps.debug('Verified camera coords:', tostring(camCoords))
        -- ps.debug('Verified camera rotation:', tostring(camRot))

        SetCamActive(cam, true)
        ps.debug('Camera activated')
        RenderScriptCams(true, false, 0, true, true)
        currentCamera = cam
        isViewingCamera = true
        currentCameraData = cameraData

        SetTimecycleModifier('scanline_cam_cheap')
        SetTimecycleModifierStrength(1.0)

        DoScreenFadeIn(250)
        startCameraControlThread()

        ps.debug('Camera view activated at coordinates:', tostring(coords))
    else
        ps.error('Failed to create camera - CreateCam returned:', tostring(cam))

        if hiddenCameraEntity and DoesEntityExist(hiddenCameraEntity) then
            ps.debug('Restoring visibility of camera entity due to camera creation failure:', hiddenCameraEntity)
            SetEntityVisible(hiddenCameraEntity, true, false)
            hiddenCameraEntity = nil
        end

        ClearFocus() -- Clear focus area since we're exiting
        DoScreenFadeIn(250)
    end
end)

-- Stop camera view (from server)
RegisterNetEvent(resourceName..':client:stopCameraView', function()
    stopCameraView(false)
end)

-- Camera controls help text
local function ShowCameraHelpNotification(text)
    AddTextEntry('CameraHelpMsg', text)
    BeginTextCommandDisplayHelp('CameraHelpMsg')
    EndTextCommandDisplayHelp(0, false, true, -1)
end

-- Camera controls
updateCameraControls = function()
    if not isViewingCamera or not currentCamera then
        return
    end

    -- Handle zoom controls (adjust FOV instead of position for CCTV)
    local currentFov = GetCamFov(currentCamera)
    local fovStep = camCfg.FovStep or 2.0
    if IsDisabledControlPressed(2, 241) then -- Mouse wheel up (zoom in)
        currentFov = currentFov - fovStep
    end

    if IsDisabledControlPressed(2, 242) then -- Mouse wheel down (zoom out)
        currentFov = currentFov + fovStep
    end

    -- Clamp FOV values (lower FOV = more zoomed in)
    currentFov = math.max(camCfg.FovMin or 10.0, math.min(camCfg.FovMax or 100.0, currentFov))
    SetCamFov(currentCamera, currentFov)

    -- Handle mouse look controls for CCTV rotation
    local mouseX = GetDisabledControlNormal(0, 1) * cameraOptions.rotationSpeed
    local mouseY = GetDisabledControlNormal(0, 2) * cameraOptions.rotationSpeed

    -- Get current rotation and apply mouse input
    local currentRot = GetCamRot(currentCamera, 2)
    local newRotX = currentRot.x - mouseY * 30.0  -- Vertical look
    local newRotZ = currentRot.z - mouseX * 30.0  -- Horizontal look

    -- Limit vertical rotation
    newRotX = math.max(-45.0, math.min(45.0, newRotX))

    -- Apply new rotation while keeping camera at current position
    local currentCoords = GetCamCoord(currentCamera)
    SetCamCoord(currentCamera, currentCoords.x, currentCoords.y, currentCoords.z)
    SetCamRot(currentCamera, newRotX, currentRot.y, newRotZ, 2)

    -- Show help text
    ShowCameraHelpNotification(
        'Visualização da Câmera' ..
        '~n~Roda do Mouse: Aproximar/Afastar (FOV: ' .. string.format('%.0f', currentFov) .. ')' ..
        '~n~Mouse: Girar Visão da Câmera' ..
        '~n~Pressione ~INPUT_FRONTEND_PAUSE_ALTERNATE~ para Sair da Câmera'
    )
end

-- Camera control thread - spawned on demand, exits when camera view stops
local cameraControlThreadActive = false

startCameraControlThread = function()
    if cameraControlThreadActive then return end
    cameraControlThreadActive = true

    CreateThread(function()
        while isViewingCamera do
            -- Update camera controls
            updateCameraControls()

            -- Check for ESC key to exit camera view
            if IsControlJustPressed(0, 177) or IsControlJustPressed(0, 200) then
                stopCameraView(true)
                break
            end

            -- Disable player controls while viewing camera
            DisablePlayerFiring(PlayerPedId(), true)
            DisableControlAction(0, 1, true) -- LookLeftRight
            DisableControlAction(0, 2, true) -- LookUpDown
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 257, true) -- Attack2
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 263, true) -- Melee Attack 1
            DisableControlAction(0, 32, true) -- MoveUpOnly
            DisableControlAction(0, 33, true) -- MoveDownOnly
            DisableControlAction(0, 34, true) -- MoveLeftOnly
            DisableControlAction(0, 35, true) -- MoveRightOnly
            DisableControlAction(0, 30, true) -- MoveLeftRight
            DisableControlAction(0, 31, true) -- MoveUpDown
            DisableControlAction(0, 36, true) -- Duck
            DisableControlAction(0, 21, true) -- Sprint
            DisableControlAction(0, 22, true) -- Jump
            DisableControlAction(0, 23, true) -- Enter
            DisableControlAction(0, 75, true) -- Exit Vehicle
            DisableControlAction(27, 75, true) -- Exit Vehicle
            DisableControlAction(0, 26, true) -- Look Behind
            DisableControlAction(0, 73, true) -- Disable clearing wanted level
            DisableControlAction(2, 199, true) -- Disable pause menu
            DisableControlAction(2, 200, true) -- Disable pause menu

            Wait(0)
        end
        cameraControlThreadActive = false
    end)
end

-- Camera Placement ------------------------------------

-- Help func to validate and extract vector4 components
local function parseVector4(str)
    if not str or type(str) ~= 'string' then
        return nil
    end

    -- Remove all whitespace first
    str = str:gsub('%s+', '')

    -- Extract numbers from vector4(x, y, z, w) format
    local x, y, z, w = str:match("vector4%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)%)")
    if x and y and z and w then
        return tonumber(x), tonumber(y), tonumber(z), tonumber(w)
    end

    return nil
end

-- Format current position as vector4
local function getCurrentPositionVector4()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    return string.format('vector4(%.2f, %.2f, %.2f, %.0f)',
        coords.x,
        coords.y,
        coords.z,
        heading)
end

-- Get all available camera models from server
local function getCameraModels()
    -- Use cached version if available
    if cameraModelsCache then
        return cameraModelsCache
    end

    -- Fetch models from server
    local models = ps.callback('ps-mdt:server:getCameraModels')
    if models then
        cameraModelsCache = models -- Cache the result
        return models
    else
        -- Fallback in case callback fails
        ps.error('Failed to fetch camera models from server')
        return {
            { value = 'security_cam_03', label = 'Câmera de Segurança 03 (Padrão)' }
        }
    end
end

-- Function to clear camera models cache (useful if models are updated on server)
local function clearCameraModelsCache()
    cameraModelsCache = nil
    ps.debug('Camera models cache cleared')
end

-- Helper func to get the actual model name from the selected key
local function getModelNameFromKey(selectedKey)
    local models = getCameraModels()
    for _, model in ipairs(models) do
        if model.value == selectedKey then
            return model.model
        end
    end
    -- Fallback to a default model if not found
    ps.warn('Model key not found: ' .. tostring(selectedKey) .. ', using fallback')
    return 'prop_cctv_cam_06a'
end

-- Show camera placement menu
function CameraPlacement.showPlacementMenu()
    local input = lib.inputDialog('Sistema de Posicionamento de Câmeras', {
        {
            type = 'input',
            label = 'ID da Câmera',
            description = 'Identificador único desta câmera',
            required = true,
            placeholder = 'cam_001'
        },
        {
            type = 'input',
            label = 'Rótulo da Câmera',
            description = 'Nome de exibição desta câmera',
            required = true,
            placeholder = 'Entrada da Delegacia'
        },
        {
            type = 'select',
            label = 'Modelo da Câmera',
            description = 'Selecione o modelo da câmera para criar',
            required = true,
            options = getCameraModels(),
            default = 'security_cam_03'
        },
        {
            type = 'input',
            label = 'Posição (Vector4)',
            description = 'Posição e rotação da câmera como vector4(x, y, z, heading)',
            required = true,
            default = getCurrentPositionVector4(),
            placeholder = 'vector4(0, 0, 0, 0)'
        },
    })

    if not input then
        ps.info('Posicionamento da câmera cancelado')
        ps.notify('Posicionamento da câmera cancelado', 'info')
        return
    end

    -- Validate camera ID format
    if not tostring(input[1]):match("^[a-zA-Z0-9_%-]+$") then
        ps.warn('Invalid camera ID format', 'error')
        ps.notify('O ID da câmera só pode conter letras, números, underlines e hífens', 'error')
        return
    end

    -- Parse vector4 position input
    local positionStr = tostring(input[4])
    local x, y, z, heading = parseVector4(positionStr)

    if not x or not y or not z or not heading then
        ps.warn('Invalid vector4 format', 'error')
        ps.notify('Formato vector4 inválido. Use: vector4(x, y, z, heading)', 'error')
        return
    end

    -- Validate coordinate ranges
    if x < -4000 or x > 4000 or y < -4000 or y > 4000 or z < -100 or z > 1000 then
        ps.warn('Coordinates out of range', 'error')
        ps.notify('Coordenadas fora do limite. X,Y: -4000 a 4000, Z: -100 a 1000', 'error')
        return
    end

    -- Normalize heading to 0-360 range
    heading = heading % 360
    if heading < 0 then heading = heading + 360 end

    -- Validate camera model with server
    local modelValid = ps.callback('ps-mdt:server:validateCameraModel', tostring(input[3]))
    if not modelValid then
        ps.warn('Modelo de câmera selecionado inválido: ' .. tostring(input[3]))
        ps.notify('Modelo de câmera selecionado inválido', 'error')
        return
    end

    -- Prepare camera data
    local cameraData = {
        camId = tostring(input[1]),
        camLabel = tostring(input[2]),
        model = tostring(input[3]),
        coords = vector3(x, y, z),
        rotation = vector3(0.0, 0.0, heading),
    }

    -- Send to server for creation
    TriggerServerEvent(resourceName .. ':server:createStaticCamera', cameraData)
    ps.info('Camera placement request sent to server for:' .. cameraData.camId)
end

-- Get existing cams
function CameraPlacement.showManagementMenu()
    TriggerServerEvent(resourceName .. ':server:requestCameraList')
end

-- Handle camera list response from server
RegisterNetEvent(resourceName .. ':client:receiveCameraList', function(cameras)
    if not cameras or #cameras == 0 then
        ps.info('Nenhuma câmera encontrada')
        ps.notify('Nenhuma câmera encontrada', 'info')
        return
    end

    local options = {}

    for _, camera in ipairs(cameras) do
        table.insert(options, {
            title = camera.camLabel,
            description = string.format('ID: %s | Modelo: %s | Criada: %s | Visualizadores: %d',
                camera.camId, camera.model, camera.isSpawned and 'Sim' or 'Não', camera.viewerCount),
            metadata = {
                'ID da Câmera: ' .. camera.camId,
                'Coordenadas: ' .. string.format('%.2f, %.2f, %.2f', camera.coords.x, camera.coords.y, camera.coords.z),
            },
            onSelect = function()
                CameraPlacement.showCameraActions(camera)
            end
        })
    end

    lib.registerContext({
        id = 'camera_management',
        title = 'Gerenciamento de Câmeras',
        options = options
    })

    lib.showContext('camera_management')
end)

-- Show individual camera action menu
function CameraPlacement.showCameraActions(camera)
    local options = {
        {
            title = 'Ver Transmissão da Câmera',
            description = 'Começar a visualizar por esta câmera',
            icon = 'video',
            onSelect = function()
                TriggerServerEvent(resourceName .. ':server:activateCamera', camera.camId)
            end
        },
        {
            title = 'Editar Câmera',
            description = 'Modificar posição e configurações da câmera',
            icon = 'pencil',
            onSelect = function()
                CameraPlacement.showEditMenu(camera)
            end
        },
        {
            title = 'Editar Posição com Gizmo',
            description = 'Posicionar visualmente a câmera usando o gizmo 3D',
            icon = 'cube',
            onSelect = function()
                CameraPlacement.placeWithGizmo(camera)
            end
        }
    }

    if camera.isSpawned then
        table.insert(options, {
            title = 'Remover Câmera',
            description = 'Remover a câmera do mundo',
            icon = 'eye-slash',
            onSelect = function()
                TriggerServerEvent(resourceName .. ':server:despawnCamera', camera.camId)
            end
        })
    else
        table.insert(options, {
            title = 'Criar Câmera',
            description = 'Posicionar câmera no mundo',
            icon = 'eye',
            onSelect = function()
                TriggerServerEvent(resourceName .. ':server:spawnCamera', camera.camId)
            end
        })
    end

    table.insert(options, {
        title = 'Excluir Câmera',
        description = 'Excluir permanentemente esta câmera',
        icon = 'trash',
        onSelect = function()
            local alert = lib.alertDialog({
                header = 'Excluir Câmera',
                content = 'Tem certeza de que deseja excluir a câmera "' .. camera.camLabel .. '"?\n\nEsta ação não pode ser desfeita.',
                centered = true,
                cancel = true
            })

            if alert == 'confirm' then
                TriggerServerEvent(resourceName .. ':server:deleteCamera', camera.camId)
            end
        end
    })

    lib.registerContext({
        id = 'camera_actions',
        title = camera.camLabel .. ' - Ações',
        menu = 'camera_management',
        options = options
    })

    lib.showContext('camera_actions')
end

-- Show camera edit menu
function CameraPlacement.showEditMenu(camera)
    local currentPosition = string.format('vector4(%.2f, %.2f, %.2f, %.0f)',
        camera.coords.x, camera.coords.y, camera.coords.z, camera.rotation.z)

    local input = lib.inputDialog('Editar Câmera: ' .. camera.camLabel, {
        {
            type = 'input',
            label = 'Rótulo da Câmera',
            description = 'Nome de exibição desta câmera',
            required = true,
            default = camera.camLabel,
            placeholder = 'Entrada da Delegacia'
        },
        {
            type = 'select',
            label = 'Modelo da Câmera',
            description = 'Selecione o modelo da câmera para criar',
            required = true,
            options = getCameraModels(),
            default = camera.model
        },
        {
            type = 'input',
            label = 'Posição (Vector4)',
            description = 'Posição e rotação da câmera como vector4(x, y, z, heading)',
            required = true,
            default = currentPosition,
            placeholder = 'vector4(0, 0, 0, 0)'
        }
    })

    if not input then
        ps.info('Edição da câmera cancelada')
        ps.notify('Edição da câmera cancelada', 'info')
        return
    end

    -- Parse vector4 position input
    local positionStr = tostring(input[3])
    local x, y, z, heading = parseVector4(positionStr)

    if not x or not y or not z or not heading then
        ps.warn('Invalid vector4 format', 'error')
        ps.notify('Formato vector4 inválido. Use: vector4(x, y, z, heading)', 'error')
        return
    end

    -- Validate coordinate ranges
    if x < -4000 or x > 4000 or y < -4000 or y > 4000 or z < -100 or z > 1000 then
        ps.warn('Coordinates out of range', 'error')
        ps.notify('Coordenadas fora do limite. X,Y: -4000 a 4000, Z: -100 a 1000', 'error')
        return
    end

    -- Normalize heading to 0-360 range
    heading = heading % 360
    if heading < 0 then heading = heading + 360 end

    -- Validate camera model with server
    local modelValid = ps.callback('ps-mdt:server:validateCameraModel', tostring(input[2]))
    if not modelValid then
        ps.warn('Modelo de câmera selecionado inválido: ' .. tostring(input[2]))
        ps.notify('Modelo de câmera selecionado inválido', 'error')
        return
    end

    -- Prepare updated camera data
    local updateData = {
        camId = camera.camId,
        camLabel = tostring(input[1]),
        model = tostring(input[2]),
        coords = vector3(x, y, z),
        rotation = vector3(0.0, 0.0, heading)
    }

    -- Send to server for update
    local result = ps.callback(resourceName .. ':server:updateCamera', updateData)
    if result and result.success then
        ps.info('Camera update request sent to server for: ' .. camera.camId)
    else
        ps.warn('Falha ao atualizar a câmera for: ' .. camera.camId)
        ps.notify('Falha ao atualizar a câmera', 'error')
    end
end

-- Create camera with gizmo placement
function CameraPlacement.createWithGizmo()
    local input = lib.inputDialog('Criar Câmera com Gizmo', {
        {
            type = 'input',
            label = 'ID da Câmera',
            description = 'Identificador único desta câmera',
            required = true,
            placeholder = 'cam_001'
        },
        {
            type = 'input',
            label = 'Rótulo da Câmera',
            description = 'Nome de exibição desta câmera',
            required = true,
            placeholder = 'Entrada da Delegacia'
        },
        {
            type = 'select',
            label = 'Modelo da Câmera',
            description = 'Selecione o modelo da câmera para criar',
            required = true,
            options = getCameraModels(),
            default = 'security_cam_03'
        }
    })

    if not input then
        ps.info('Criação da câmera cancelada')
        ps.notify('Criação da câmera cancelada', 'info')
        return
    end

    -- Validate camera ID format
    if not tostring(input[1]):match("^[a-zA-Z0-9_%-]+$") then
        ps.warn('Invalid camera ID format', 'error')
        ps.notify('O ID da câmera só pode conter letras, números, underlines e hífens', 'error')
        return
    end

    -- Validate camera model with server
    local modelValid = ps.callback('ps-mdt:server:validateCameraModel', tostring(input[3]))
    if not modelValid then
        ps.warn('Modelo de câmera selecionado inválido: ' .. tostring(input[3]))
        ps.notify('Modelo de câmera selecionado inválido', 'error')
        return
    end

    -- Create a temporary prop to position with gizmo
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local forwardVector = GetEntityForwardVector(ped)
    local spawnCoords = coords + forwardVector * 3.0

    -- Request the selected camera model hash
    local selectedKey = tostring(input[3])
    local actualModelName = getModelNameFromKey(selectedKey)
    local modelHash = GetHashKey(actualModelName)

    ps.debug('Selected key: ' .. selectedKey .. ', Model name: ' .. actualModelName .. ', Hash: ' .. tostring(modelHash))
    lib.requestModel(modelHash)

    -- Create temporary object
    local tempObj = CreateObject(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z + 1.0, false, false, false)

    if not tempObj or tempObj == 0 then
        ps.error('Failed to create temporary camera object for placement')
        ps.notify('Falha ao criar o objeto de posicionamento', 'error')
        return
    end
    ps.debug('Created temporary object for gizmo placement')

    -- Use gizmo for placement
    ps.notify('Use o gizmo para posicionar a câmera e pressione ENTER quando terminar', 'info')
    local gizmoResult = exports[GetCurrentResourceName()]:useGizmo(tempObj)

    if not gizmoResult then
        ps.warn('Gizmo placement cancelled')
        ps.notify('Posicionamento da câmera cancelado', 'info')
        DeleteObject(tempObj)
        return
    end

    -- Get final position and rotation
    local finalCoords = gizmoResult.position
    local finalRotation = gizmoResult.rotation

    ps.debug('Gizmo final position: ' .. tostring(finalCoords))
    ps.debug('Final rotation: ' .. tostring(finalRotation))

    -- Clean up temporary object
    DeleteObject(tempObj)

    -- Prepare camera data
    local cameraData = {
        camId = tostring(input[1]),
        camLabel = tostring(input[2]),
        model = tostring(input[3]),
        coords = vector3(finalCoords.x, finalCoords.y, finalCoords.z),
        rotation = vector3(finalRotation.x, finalRotation.y, finalRotation.z),
    }

    ps.debug('Camera data being sent to server:')
    ps.debug('  coords: ' .. tostring(cameraData.coords))
    ps.debug('  rotation: ' .. tostring(cameraData.rotation))

    SetModelAsNoLongerNeeded(modelHash)

    -- Send to server for creation
    TriggerServerEvent(resourceName .. ':server:createStaticCamera', cameraData)
    ps.info('Camera placement request sent to server for: ' .. cameraData.camId)
    ps.notify('Câmera criada na posição: ' .. string.format('%.2f, %.2f, %.2f', finalCoords.x, finalCoords.y, finalCoords.z), 'success')
end

-- Position existing camera with gizmo
function CameraPlacement.placeWithGizmo(camera)
    -- Get the actual model name for the existing camera
    local actualModelName = getModelNameFromKey(camera.model)
    local modelHash = GetHashKey(actualModelName)

    ps.debug('Repositioning camera with key: ' .. camera.model .. ', Model name: ' .. actualModelName .. ', Hash: ' .. tostring(modelHash))
    lib.requestModel(modelHash)

    -- Create temporary object at current camera position
    local tempObj = CreateObject(modelHash, camera.coords.x, camera.coords.y, camera.coords.z, false, false, false)

    if not tempObj or tempObj == 0 then
        ps.error('Failed to create temporary camera object for placement')
        ps.notify('Falha ao criar o objeto de posicionamento', 'error')
        return
    end

    SetEntityRotation(tempObj, camera.rotation.x, camera.rotation.y, camera.rotation.z, 2, false)

    ps.debug('Created temporary object for gizmo repositioning')

    ps.notify('Use o gizmo para reposicionar a câmera "' .. camera.camLabel .. '", depois pressione ENTER quando terminar', 'info')

    local gizmoResult = exports[GetCurrentResourceName()]:useGizmo(tempObj)

    if not gizmoResult then
        ps.warn('Gizmo placement cancelled')
        ps.notify('Reposicionamento da câmera cancelado', 'info')
        DeleteObject(tempObj)
        return
    end

    -- Get final position and rotation directly from gizmo
    -- The gizmo result already represents where the user wants the entity to be
    local finalCoords = gizmoResult.position
    local finalRotation = gizmoResult.rotation

    ps.debug('Gizmo final position: ' .. tostring(finalCoords))
    ps.debug('Final rotation: ' .. tostring(finalRotation))

    -- Clean up temporary object
    DeleteObject(tempObj)
    SetModelAsNoLongerNeeded(modelHash)

    -- Prepare update data
    local updateData = {
        camId = camera.camId,
        coords = vector3(finalCoords.x, finalCoords.y, finalCoords.z),
        rotation = vector3(finalRotation.x, finalRotation.y, finalRotation.z)
    }

    -- Send to server for update
    local result = ps.callback(resourceName .. ':server:updateCamera', updateData)
    if not result or not result.success then
        ps.warn('Falha ao atualizar a câmera for: ' .. camera.camId)
        ps.notify('Falha ao atualizar a câmera', 'error')
    end
    ps.info('Camera repositioning request sent to server for: ' .. camera.camId)
    ps.notify('Câmera reposicionada em: ' .. string.format('%.2f, %.2f, %.2f', finalCoords.x, finalCoords.y, finalCoords.z), 'success')
end

-- Main camera menu
function CameraPlacement.showMainMenu()
    lib.registerContext({
        id = 'camera_main_menu',
        title = 'Sistema de Câmeras',
        options = {
            {
                title = 'Posicionar Nova Câmera',
                description = 'Criar uma nova câmera',
                icon = 'plus',
                onSelect = function()
                    CameraPlacement.showPlacementMenu()
                end
            },
            {
                title = 'Criar com Gizmo',
                description = 'Criar uma nova câmera usando Gizmo',
                icon = 'cube',
                onSelect = function()
                    CameraPlacement.createWithGizmo()
                end
            },
            {
                title = 'Gerenciar Câmeras',
                description = 'Ver e gerenciar câmeras existentes',
                icon = 'cog',
                onSelect = function()
                    CameraPlacement.showManagementMenu()
                end
            },
        }
    })

    lib.showContext('camera_main_menu')
end

-- Exports --------------------------------------

-- Check if currently viewing a camera
exports('isViewingCamera', function()
    return isViewingCamera
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if isViewingCamera and currentCamera then
        SetCamActive(currentCamera, false)
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(currentCamera, false)
        currentCamera = nil
        isViewingCamera = false
    end
    if hiddenCameraEntity and DoesEntityExist(hiddenCameraEntity) then
        SetEntityVisible(hiddenCameraEntity, true, false)
        hiddenCameraEntity = nil
    end
    ClearTimecycleModifier()
    ClearFocus()
    DoScreenFadeIn(0)
end)
