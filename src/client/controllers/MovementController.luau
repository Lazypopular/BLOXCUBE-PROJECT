--!strict
-- MovementController: Sprint, Dodge Roll, Pet Mount ([T]) & Voxel Hang Glider ([G]) Input + Physics

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local GameConfig = require(ReplicatedStorage.configs.GameConfig)
local PetConfig = require(ReplicatedStorage.configs.PetConfig)
local Network = require(ReplicatedStorage.network)
local CameraController = require(script.Parent.CameraController)

local localPlayer = Players.LocalPlayer

local MovementController = {}

local lastDodgeClientTime = 0
local lastGliderToggleTime = 0
local gliderActivatedAt = 0
local wasGlidingLastFrame = false
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

function MovementController.toggleGlider()
    local now = os.clock()
    if now - lastGliderToggleTime < 0.25 then
        return
    end
    lastGliderToggleTime = now

    local character = localPlayer.Character
    local rootPart = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
    local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
    local isCurrentlyGliding = localPlayer:GetAttribute("IsGliding") == true

    if not isCurrentlyGliding and rootPart and humanoid then
        -- If deploying from the ground, give a clean Cube World wind updraft hop so the player can glide right away
        if humanoid.FloorMaterial ~= Enum.Material.Air then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            local v = rootPart.AssemblyLinearVelocity
            rootPart.AssemblyLinearVelocity = Vector3.new(v.X, PetConfig.Glider.LaunchBoostY, v.Z)
        end
    end

    Network.getEvent("RequestToggleGlider"):FireServer(not isCurrentlyGliding)
end

function MovementController.init()
    local requestSprint = Network.getEvent("RequestSprint")
    local dodgePerformed = Network.getEvent("DodgePerformed")
    local requestToggleMount = Network.getEvent("RequestToggleMount")
    local requestToggleGlider = Network.getEvent("RequestToggleGlider")

    dodgePerformed.OnClientEvent:Connect(function(direction: Vector3)
        performClientDodgeBurst(direction)
    end)

    -- Glider Air-Physics Loop
    RunService.Heartbeat:Connect(function()
        local isGlidingNow = localPlayer:GetAttribute("IsGliding") == true
        if not isGlidingNow then
            wasGlidingLastFrame = false
            return
        end

        local character = localPlayer.Character
        local rootPart = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
        local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
        if not rootPart or not humanoid or humanoid.Health <= 0 then
            return
        end

        if not wasGlidingLastFrame then
            wasGlidingLastFrame = true
            gliderActivatedAt = os.clock()
            if humanoid.FloorMaterial ~= Enum.Material.Air then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                local v = rootPart.AssemblyLinearVelocity
                rootPart.AssemblyLinearVelocity = Vector3.new(v.X, PetConfig.Glider.LaunchBoostY, v.Z)
            end
        end

        -- Auto-stow glider if player lands back on ground after launch grace window
        if (os.clock() - gliderActivatedAt > 0.65) and humanoid.FloorMaterial ~= Enum.Material.Air then
            lastGliderToggleTime = os.clock()
            requestToggleGlider:FireServer(false)
            return
        end

        local glideDir = CameraController.getFlatLookDirection()
        if humanoid.MoveDirection.Magnitude > 0.05 then
            local m = Vector3.new(humanoid.MoveDirection.X, 0, humanoid.MoveDirection.Z)
            if m.Magnitude > 0.01 then
                glideDir = m.Unit
            end
        end

        local currentVel = rootPart.AssemblyLinearVelocity
        local targetY = math.max(currentVel.Y, PetConfig.Glider.SinkVelocity)
        local horiz = glideDir * PetConfig.Glider.ForwardSpeed
        rootPart.AssemblyLinearVelocity = Vector3.new(horiz.X, targetY, horiz.Z)
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
        elseif input.KeyCode == Enum.KeyCode.T then
            requestToggleMount:FireServer()
        elseif input.KeyCode == Enum.KeyCode.G then
            MovementController.toggleGlider()
        end
    end)

    UserInputService.InputEnded:Connect(function(input: InputObject)
        if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
            requestSprint:FireServer(false)
        end
    end)
end

return table.freeze(MovementController)
