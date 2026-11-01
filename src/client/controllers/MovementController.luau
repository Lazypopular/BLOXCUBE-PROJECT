--!strict
-- MovementController: Sprint & Dodge Roll Input + Physics Impulse

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local GameConfig = require(ReplicatedStorage.configs.GameConfig)
local Network = require(ReplicatedStorage.network)
local CameraController = require(script.Parent.CameraController)

local localPlayer = Players.LocalPlayer

local MovementController = {}

local lastDodgeClientTime = 0
local activeDodgeConn: RBXScriptConnection? = nil

local function getDesiredDodgeDirection(): Vector3
    local character = localPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.MoveDirection.Magnitude > 0.05 then
            local dir = Vector3.new(humanoid.MoveDirection.X, 0, humanoid.MoveDirection.Z)
            if dir.Magnitude > 0.001 then
                return dir.Unit
            end
        end
    end
    return CameraController.getFlatLookDirection()
end

local function performClientDodgeBurst(direction: Vector3)
    local character = localPlayer.Character
    if not character then
        return
    end

    local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not rootPart or not humanoid or humanoid.Health <= 0 then
        return
    end

    local burstDir = direction
    if burstDir.Magnitude < 0.01 then
        burstDir = CameraController.getFlatLookDirection()
    else
        burstDir = burstDir.Unit
    end

    -- Snap character facing to dodge direction
    local pos = rootPart.Position
    rootPart.CFrame = CFrame.lookAt(pos, pos + burstDir)

    if activeDodgeConn then
        activeDodgeConn:Disconnect()
        activeDodgeConn = nil
    end

    local startTime = os.clock()
    local duration = GameConfig.Movement.DodgeDuration

    activeDodgeConn = RunService.Heartbeat:Connect(function()
        local elapsed = os.clock() - startTime
        if elapsed >= duration or not rootPart.Parent or humanoid.Health <= 0 then
            if activeDodgeConn then
                activeDodgeConn:Disconnect()
                activeDodgeConn = nil
            end
            return
        end

        -- Smooth velocity curve (fast burst -> smooth deceleration)
        local t = elapsed / duration
        local speedFactor = 1 - (t * t * 0.45)
        local horizontalVel = burstDir * (GameConfig.Movement.DodgeSpeed * speedFactor)
        local currentVel = rootPart.AssemblyLinearVelocity
        rootPart.AssemblyLinearVelocity = Vector3.new(horizontalVel.X, currentVel.Y, horizontalVel.Z)
    end)
end

function MovementController.requestDodge()
    local now = os.clock()
    if now - lastDodgeClientTime < GameConfig.Movement.DodgeCooldown * 0.9 then
        return
    end

    local stamina = (localPlayer:GetAttribute("Stamina") :: number?) or 0
    if stamina < GameConfig.Stamina.DodgeCost then
        return
    end

    lastDodgeClientTime = now
    local dir = getDesiredDodgeDirection()
    Network.getEvent("RequestDodge"):FireServer(dir)
end

function MovementController.init()
    local requestSprint = Network.getEvent("RequestSprint")
    local dodgePerformed = Network.getEvent("DodgePerformed")

    dodgePerformed.OnClientEvent:Connect(function(direction: Vector3)
        performClientDodgeBurst(direction)
    end)

    UserInputService.InputBegan:Connect(function(input: InputObject, _gameProcessed: boolean)
        if UserInputService:GetFocusedTextBox() ~= nil then
            return
        end

        if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
            requestSprint:FireServer(true)
        elseif
            input.KeyCode == Enum.KeyCode.Q
            or input.KeyCode == Enum.KeyCode.LeftControl
            or input.UserInputType == Enum.UserInputType.MouseButton3
        then
            MovementController.requestDodge()
        end
    end)

    UserInputService.InputEnded:Connect(function(input: InputObject)
        if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
            requestSprint:FireServer(false)
        end
    end)
end

return table.freeze(MovementController)
