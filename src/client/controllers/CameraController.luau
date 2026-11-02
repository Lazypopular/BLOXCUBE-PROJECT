--!strict
-- CameraController: Cube World Style Over-The-Shoulder Action RPG Camera

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.configs.GameConfig)

local localPlayer = Players.LocalPlayer

local CameraController = {}

local yaw = 0
local pitch = -14
local targetDistance = GameConfig.Camera.DefaultDistance
local currentDistance = GameConfig.Camera.DefaultDistance
local currentFOV = GameConfig.Camera.DefaultFOV

local mouseLocked = true
local uiPanelOpen = false
local altHeld = false
local wasCreatingCharacter = false

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true

local function isCreatingCharacter(): boolean
    return localPlayer:GetAttribute("IsCreatingCharacter") == true
end

local function updateMouseLockState()
    local shouldLock = mouseLocked and not uiPanelOpen and not altHeld and not isCreatingCharacter()
    if shouldLock then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end
end

function CameraController.setUIPanelOpen(isOpen: boolean)
    uiPanelOpen = isOpen
    updateMouseLockState()
end

function CameraController.isMouseLocked(): boolean
    return mouseLocked and not uiPanelOpen and not altHeld and not isCreatingCharacter()
end

function CameraController.getLookVector(): Vector3
    local cam = Workspace.CurrentCamera
    if cam then
        return cam.CFrame.LookVector
    end
    return Vector3.new(0, 0, -1)
end

function CameraController.getFlatLookDirection(): Vector3
    local look = CameraController.getLookVector()
    local flat = Vector3.new(look.X, 0, look.Z)
    if flat.Magnitude > 0.001 then
        return flat.Unit
    end
    return Vector3.new(0, 0, -1)
end

function CameraController.init()
    updateMouseLockState()

    UserInputService.InputBegan:Connect(function(input: InputObject, _gameProcessed: boolean)
        if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
            altHeld = true
            updateMouseLockState()
            return
        end

        if UserInputService:GetFocusedTextBox() ~= nil then
            return
        end

        if input.KeyCode == Enum.KeyCode.V then
            mouseLocked = not mouseLocked
            updateMouseLockState()
        end
    end)

    UserInputService.InputEnded:Connect(function(input: InputObject)
        if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
            altHeld = false
            updateMouseLockState()
        end
    end)

    UserInputService.InputChanged:Connect(function(input: InputObject, gameProcessed: boolean)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            local canRotate = (mouseLocked and not uiPanelOpen and not altHeld)
                or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
            if canRotate then
                local delta = input.Delta
                yaw = (yaw - delta.X * GameConfig.Camera.Sensitivity) % 360
                pitch = math.clamp(
                    pitch - delta.Y * GameConfig.Camera.Sensitivity,
                    GameConfig.Camera.MinPitch,
                    GameConfig.Camera.MaxPitch
                )
            end
        elseif input.UserInputType == Enum.UserInputType.MouseWheel and not gameProcessed then
            targetDistance = math.clamp(
                targetDistance - input.Position.Z * GameConfig.Camera.ZoomStep,
                GameConfig.Camera.MinDistance,
                GameConfig.Camera.MaxDistance
            )
        end
    end)

    RunService:BindToRenderStep("BloxcubeActionCamera", Enum.RenderPriority.Camera.Value + 1, function(dt: number)
        local camera = Workspace.CurrentCamera
        local character = localPlayer.Character
        if not camera or not character then
            return
        end

        local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not rootPart or not humanoid then
            return
        end

        updateMouseLockState()
        camera.CameraType = Enum.CameraType.Scriptable

        -- Character Creation Stage Portrait Camera
        if isCreatingCharacter() then
            wasCreatingCharacter = true
            camera.FieldOfView = 55
            local lookAtTarget = rootPart.Position + Vector3.new(1.5, 0.55, 0)
            local camPos = rootPart.Position + Vector3.new(1.8, 1.45, 7.6)
            camera.CFrame = CFrame.lookAt(camPos, lookAtTarget)
            return
        elseif wasCreatingCharacter then
            wasCreatingCharacter = false
            yaw = 0
            pitch = -12
        end

        -- Smooth Zoom & Sprint FOV
        currentDistance = currentDistance + (targetDistance - currentDistance) * math.min(1, dt * 14)
        local isSprinting = localPlayer:GetAttribute("IsSprinting") == true and humanoid.MoveDirection.Magnitude > 0.1
        local goalFOV = if isSprinting then GameConfig.Camera.SprintFOV else GameConfig.Camera.DefaultFOV
        currentFOV = currentFOV + (goalFOV - currentFOV) * math.min(1, dt * 10)
        camera.FieldOfView = currentFOV

        local rotation = CFrame.fromOrientation(math.rad(pitch), math.rad(yaw), 0)
        local focusOrigin = rootPart.Position + Vector3.new(0, GameConfig.Camera.ShoulderOffset.Y, 0)
        local rightOffset = rotation.RightVector * GameConfig.Camera.ShoulderOffset.X
        local desiredCamPos = focusOrigin + rightOffset - (rotation.LookVector * currentDistance)

        -- Raycast Wall Collision Check
        raycastParams.FilterDescendantsInstances = { character }
        local rayDir = desiredCamPos - focusOrigin
        local rayResult = Workspace:Raycast(focusOrigin, rayDir, raycastParams)
        local finalCamPos = desiredCamPos
        if rayResult then
            local hitDist = (rayResult.Position - focusOrigin).Magnitude
            local safeDist = math.max(1.5, hitDist - 0.6)
            finalCamPos = focusOrigin + rayDir.Unit * safeDist
        end

        camera.CFrame = CFrame.lookAt(finalCamPos, finalCamPos + rotation.LookVector)

        -- Rotate Character Smoothly
        if humanoid.Health > 0 then
            local moveDir = humanoid.MoveDirection
            local targetFacing: Vector3? = nil
            if moveDir.Magnitude > 0.05 then
                targetFacing = Vector3.new(moveDir.X, 0, moveDir.Z).Unit
            elseif CameraController.isMouseLocked() then
                targetFacing = CameraController.getFlatLookDirection()
            end

            if targetFacing and targetFacing.Magnitude > 0.001 then
                local currentPos = rootPart.Position
                local goalCFrame = CFrame.lookAt(currentPos, currentPos + targetFacing)
                rootPart.CFrame = rootPart.CFrame:Lerp(goalCFrame, math.min(1, dt * 16))
            end
        end
    end)
end

return table.freeze(CameraController)
