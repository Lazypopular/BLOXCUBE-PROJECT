--!strict
-- VoxelAnimatorController: Procedural 60FPS Cube World Voxel Animation & VFX

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.configs.GameConfig)

local VoxelAnimatorController = {}

type RigAnimState = {
    WalkCycle: number,
    IdleTime: number,
    RollStartTime: number,
    LastDodgeSeq: number,
}

local animStates: { [Model]: RigAnimState } = {}

local function getOrCreateState(character: Model): RigAnimState
    local existing = animStates[character]
    if existing then
        return existing
    end

    local seq = (character:GetAttribute("DodgeRollSeq") :: number?) or 0
    local state: RigAnimState = {
        WalkCycle = 0,
        IdleTime = 0,
        RollStartTime = -10,
        LastDodgeSeq = seq,
    }
    animStates[character] = state
    return state
end

local function spawnVoxelDustBurst(rootPart: BasePart, count: number)
    for i = 1, count do
        local dust = Instance.new("Part")
        dust.Name = "VoxelDust"
        local sizeVal = 0.35 + (i % 3) * 0.12
        dust.Size = Vector3.new(sizeVal, sizeVal, sizeVal)
        dust.Color = Color3.fromRGB(228, 224, 212)
        dust.Material = Enum.Material.SmoothPlastic
        dust.Anchored = true
        dust.CanCollide = false
        dust.CanQuery = false
        dust.CanTouch = false
        dust.CastShadow = false

        local angle = (i / count) * math.pi * 2
        local spread = Vector3.new(math.cos(angle) * 1.2, -2.1, math.sin(angle) * 1.2)
        dust.CFrame = rootPart.CFrame * CFrame.new(spread)
        dust.Parent = Workspace

        local targetCFrame = dust.CFrame
            * CFrame.new(math.cos(angle) * 1.6, 0.9, math.sin(angle) * 1.6)
            * CFrame.Angles(1.2, 0.8, 0.5)

        local tween = TweenService:Create(dust, TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            CFrame = targetCFrame,
            Size = Vector3.new(0.05, 0.05, 0.05),
            Transparency = 1,
        })
        tween:Play()
        Debris:AddItem(dust, 0.42)
    end
end

local function animateCharacter(character: Model, dt: number, now: number)
    local rigModel = character:FindFirstChild("VoxelRig")
    local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not rigModel or not rootPart or not humanoid then
        return
    end

    local torso = rigModel:FindFirstChild("VoxelTorso") :: BasePart?
    if not torso then
        return
    end

    local rootJoint = rootPart:FindFirstChild("RootJoint") :: Motor6D?
    local neck = torso:FindFirstChild("Neck") :: Motor6D?
    local leftShoulder = torso:FindFirstChild("LeftShoulder") :: Motor6D?
    local rightShoulder = torso:FindFirstChild("RightShoulder") :: Motor6D?
    local leftHip = torso:FindFirstChild("LeftHip") :: Motor6D?
    local rightHip = torso:FindFirstChild("RightHip") :: Motor6D?

    if not (rootJoint and neck and leftShoulder and rightShoulder and leftHip and rightHip) then
        return
    end

    local rootBase = (rootJoint:GetAttribute("OriginalC0") :: CFrame?) or CFrame.new(0, -0.35, 0)
    local neckBase = (neck:GetAttribute("OriginalC0") :: CFrame?) or CFrame.new(0, 0.95, 0)
    local lShoulderBase = (leftShoulder:GetAttribute("OriginalC0") :: CFrame?) or CFrame.new(-1.28, 0.68, 0)
    local rShoulderBase = (rightShoulder:GetAttribute("OriginalC0") :: CFrame?) or CFrame.new(1.28, 0.68, 0)
    local lHipBase = (leftHip:GetAttribute("OriginalC0") :: CFrame?) or CFrame.new(-0.5, -0.95, 0)
    local rHipBase = (rightHip:GetAttribute("OriginalC0") :: CFrame?) or CFrame.new(0.5, -0.95, 0)

    local state = getOrCreateState(character)
    state.IdleTime += dt

    -- Detect Dodge Roll Trigger
    local currentDodgeSeq = (character:GetAttribute("DodgeRollSeq") :: number?) or 0
    if currentDodgeSeq ~= state.LastDodgeSeq then
        state.LastDodgeSeq = currentDodgeSeq
        state.RollStartTime = now
        spawnVoxelDustBurst(rootPart, 6)
    end

    local rollElapsed = now - state.RollStartTime
    local rollDuration = GameConfig.Movement.DodgeDuration

    if rollElapsed >= 0 and rollElapsed < rollDuration then
        -- 360-Degree Cube World Forward Somersault Roll
        local alpha = math.clamp(rollElapsed / rollDuration, 0, 1)
        local flipAngle = -alpha * math.pi * 2
        local hopHeight = math.sin(alpha * math.pi) * 0.85

        rootJoint.C0 = rootBase * CFrame.new(0, hopHeight, 0) * CFrame.Angles(flipAngle, 0, 0)
        neck.C0 = neckBase * CFrame.Angles(math.rad(-25), 0, 0)
        leftShoulder.C0 = lShoulderBase * CFrame.Angles(math.rad(75), 0, math.rad(15))
        rightShoulder.C0 = rShoulderBase * CFrame.Angles(math.rad(75), 0, math.rad(-15))
        leftHip.C0 = lHipBase * CFrame.Angles(math.rad(45), 0, 0)
        rightHip.C0 = rHipBase * CFrame.Angles(math.rad(45), 0, 0)
        return
    end

    local velocity = rootPart.AssemblyLinearVelocity
    local flatSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
    local isAirborne = humanoid.FloorMaterial == Enum.Material.Air
    local isSprinting = character:GetAttribute("IsSprinting") == true

    local lerpSpeed = math.min(1, dt * 16)

    if isAirborne then
        -- Airborne Jump / Fall Pose
        local rootGoal = rootBase * CFrame.new(0, 0.15, 0) * CFrame.Angles(math.rad(-8), 0, 0)
        local neckGoal = neckBase * CFrame.Angles(math.rad(10), 0, 0)
        local lArmGoal = lShoulderBase * CFrame.Angles(math.rad(135), 0, math.rad(-18))
        local rArmGoal = rShoulderBase * CFrame.Angles(math.rad(135), 0, math.rad(18))
        local lFootGoal = lHipBase * CFrame.new(0, 0.2, -0.15) * CFrame.Angles(math.rad(-28), 0, 0)
        local rFootGoal = rHipBase * CFrame.new(0, 0.1, 0.15) * CFrame.Angles(math.rad(22), 0, 0)

        rootJoint.C0 = rootJoint.C0:Lerp(rootGoal, lerpSpeed)
        neck.C0 = neck.C0:Lerp(neckGoal, lerpSpeed)
        leftShoulder.C0 = leftShoulder.C0:Lerp(lArmGoal, lerpSpeed)
        rightShoulder.C0 = rightShoulder.C0:Lerp(rArmGoal, lerpSpeed)
        leftHip.C0 = leftHip.C0:Lerp(lFootGoal, lerpSpeed)
        rightHip.C0 = rightHip.C0:Lerp(rFootGoal, lerpSpeed)
    elseif flatSpeed > 0.8 then
        -- Cube World Bouncy Voxel Walk / Sprint Cycle
        local cycleRate = if isSprinting then 13.5 else 9.5
        state.WalkCycle += dt * cycleRate

        local swingAmp = if isSprinting then math.rad(58) else math.rad(40)
        local armAmp = if isSprinting then math.rad(64) else math.rad(42)
        local bounce = math.abs(math.sin(state.WalkCycle)) * (if isSprinting then 0.34 else 0.2)
        local forwardLean = if isSprinting then math.rad(-16) else math.rad(-7)
        local torsoTwist = math.sin(state.WalkCycle) * math.rad(8)

        local s = math.sin(state.WalkCycle)
        local lFootLift = math.max(0, s) * 0.28
        local rFootLift = math.max(0, -s) * 0.28

        local rootGoal = rootBase * CFrame.new(0, bounce, 0) * CFrame.Angles(forwardLean, torsoTwist, 0)
        local neckGoal = neckBase * CFrame.Angles(-forwardLean * 0.6, -torsoTwist * 0.5, 0)
        local lArmGoal = lShoulderBase * CFrame.Angles(-s * armAmp, 0, math.rad(-6))
        local rArmGoal = rShoulderBase * CFrame.Angles(s * armAmp, 0, math.rad(6))
        local lFootGoal = lHipBase * CFrame.new(0, lFootLift, 0) * CFrame.Angles(s * swingAmp, 0, 0)
        local rFootGoal = rHipBase * CFrame.new(0, rFootLift, 0) * CFrame.Angles(-s * swingAmp, 0, 0)

        rootJoint.C0 = rootJoint.C0:Lerp(rootGoal, lerpSpeed)
        neck.C0 = neck.C0:Lerp(neckGoal, lerpSpeed)
        leftShoulder.C0 = leftShoulder.C0:Lerp(lArmGoal, lerpSpeed)
        rightShoulder.C0 = rightShoulder.C0:Lerp(rArmGoal, lerpSpeed)
        leftHip.C0 = leftHip.C0:Lerp(lFootGoal, lerpSpeed)
        rightHip.C0 = rightHip.C0:Lerp(rFootGoal, lerpSpeed)
    else
        -- Breathing Idle Pose
        local breath = math.sin(state.IdleTime * 2.6) * 0.06
        local armSway = math.sin(state.IdleTime * 2.6) * math.rad(4)

        local rootGoal = rootBase * CFrame.new(0, breath, 0)
        local neckGoal = neckBase * CFrame.Angles(math.sin(state.IdleTime * 1.5) * math.rad(2.5), 0, 0)
        local lArmGoal = lShoulderBase * CFrame.Angles(armSway, 0, math.rad(-5))
        local rArmGoal = rShoulderBase * CFrame.Angles(-armSway, 0, math.rad(5))

        rootJoint.C0 = rootJoint.C0:Lerp(rootGoal, lerpSpeed)
        neck.C0 = neck.C0:Lerp(neckGoal, lerpSpeed)
        leftShoulder.C0 = leftShoulder.C0:Lerp(lArmGoal, lerpSpeed)
        rightShoulder.C0 = rightShoulder.C0:Lerp(rArmGoal, lerpSpeed)
        leftHip.C0 = leftHip.C0:Lerp(lHipBase, lerpSpeed)
        rightHip.C0 = rightHip.C0:Lerp(rHipBase, lerpSpeed)
    end
end

function VoxelAnimatorController.init()
    RunService.RenderStepped:Connect(function(dt: number)
        local now = os.clock()
        for _, player in Players:GetPlayers() do
            local character = player.Character
            if character then
                animateCharacter(character, dt, now)
            end
        end
    end)
end

return table.freeze(VoxelAnimatorController)
