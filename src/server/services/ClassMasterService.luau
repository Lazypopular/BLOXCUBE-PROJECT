--!strict
-- ClassMasterService: Spawns Voxel Class Master NPCs & Handles Server-Validated Quest Acceptance

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CharacterConfig = require(ReplicatedStorage.configs.CharacterConfig)
local CombatConfig = require(ReplicatedStorage.configs.CombatConfig)
local PlayerService = require(script.Parent.PlayerService)
local VoxelRigService = require(script.Parent.VoxelRigService)

local ClassMasterService = {}

local MAX_INTERACT_DISTANCE = 14

local function getGroundPosition(offset: Vector3): Vector3
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Include
    local filterList = {}
    local baseplate = Workspace:FindFirstChild("Baseplate")
    if baseplate then
        table.insert(filterList, baseplate)
    end
    rayParams.FilterDescendantsInstances = filterList

    local origin = Vector3.new(offset.X, 60, offset.Z)
    local result = Workspace:Raycast(origin, Vector3.new(0, -120, 0), rayParams)
    if result then
        return result.Position
    end
    return Vector3.new(offset.X, 0, offset.Z)
end

local function createNPCBillboard(adornee: BasePart, nameText: string, titleText: string, accentColor: Color3)
    local bb = Instance.new("BillboardGui")
    bb.Name = "MasterBillboard"
    bb.Adornee = adornee
    bb.Size = UDim2.new(0, 200, 0, 48)
    bb.StudsOffset = Vector3.new(0, 4.2, 0)
    bb.AlwaysOnTop = false
    bb.MaxDistance = 85
    bb.Parent = adornee

    local roleLabel = Instance.new("TextLabel")
    roleLabel.Size = UDim2.new(1, 0, 0, 18)
    roleLabel.BackgroundTransparency = 1
    roleLabel.Font = Enum.Font.GothamBlack
    roleLabel.TextSize = 11
    roleLabel.TextColor3 = accentColor
    roleLabel.TextStrokeTransparency = 0.2
    roleLabel.Text = "[" .. string.upper(titleText) .. "]"
    roleLabel.Parent = bb

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 22)
    nameLabel.Position = UDim2.new(0, 0, 0, 18)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBlack
    nameLabel.TextSize = 14
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0.15
    nameLabel.Text = nameText
    nameLabel.Parent = bb
end

local function spawnClassMasterNPC(spec: any, parentFolder: Folder)
    local groundPos = getGroundPosition(spec.SpawnOffset)
    local classInfo = CharacterConfig.JobClasses[spec.TargetClass] or CharacterConfig.JobClasses.Novice

    -- Build a Voxel Stone Guild Pedestal under the Master
    local pedestal = Instance.new("Part")
    pedestal.Name = spec.Id .. "_Pedestal"
    pedestal.Size = Vector3.new(5.2, 0.8, 5.2)
    pedestal.Color = Color3.fromRGB(68, 74, 88)
    pedestal.Material = Enum.Material.SmoothPlastic
    pedestal.TopSurface = Enum.SurfaceType.Smooth
    pedestal.BottomSurface = Enum.SurfaceType.Smooth
    pedestal.Anchored = true
    pedestal.CFrame = CFrame.new(groundPos + Vector3.new(0, 0.4, 0))
    pedestal.Parent = parentFolder

    local trim = Instance.new("Part")
    trim.Name = spec.Id .. "_Trim"
    trim.Size = Vector3.new(4.4, 0.2, 4.4)
    trim.Color = classInfo.AccentColor
    trim.Material = Enum.Material.Neon
    trim.Anchored = true
    trim.CanCollide = false
    trim.CFrame = CFrame.new(groundPos + Vector3.new(0, 0.85, 0))
    trim.Parent = parentFolder

    -- Create Dummy Character Model for VoxelRigService
    local npcModel = Instance.new("Model")
    npcModel.Name = spec.Name

    local rootPart = Instance.new("Part")
    rootPart.Name = "HumanoidRootPart"
    rootPart.Size = Vector3.new(2, 2, 1)
    rootPart.Transparency = 1
    rootPart.Anchored = true
    rootPart.CanCollide = true
    -- Face towards the player spawn at (0, 0, 0)
    local npcPos = groundPos + Vector3.new(0, 3.3, 0)
    local lookTarget = Vector3.new(0, npcPos.Y, 0)
    rootPart.CFrame = CFrame.lookAt(npcPos, lookTarget)
    rootPart.Parent = npcModel

    local humanoid = Instance.new("Humanoid")
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.Parent = npcModel

    npcModel.PrimaryPart = rootPart
    npcModel.Parent = parentFolder

    VoxelRigService.buildCharacterRig(npcModel, spec.Appearance, spec.TargetClass)
    createNPCBillboard(rootPart, spec.Name, spec.Title, classInfo.AccentColor)

    local prompt = Instance.new("ProximityPrompt")
    prompt.ObjectText = spec.Name .. " (" .. spec.Title .. ")"
    prompt.ActionText = if spec.TargetClass == "Novice"
        then "Reset to Novice"
        else "Start " .. spec.TargetClass .. " Trial"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 10
    prompt.RequiresLineOfSight = false
    prompt.Parent = rootPart

    prompt.Triggered:Connect(function(player: Player)
        local char = player.Character
        local playerRoot = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
        if not playerRoot then
            return
        end

        -- Server Sanity Distance Check
        local dist = (playerRoot.Position - rootPart.Position).Magnitude
        if dist > MAX_INTERACT_DISTANCE then
            return
        end

        PlayerService.acceptClassQuest(player, spec)
    end)
end

function ClassMasterService.init()
    local existing = Workspace:FindFirstChild("BloxcubeClassMasters")
    if existing then
        existing:Destroy()
    end

    local folder = Instance.new("Folder")
    folder.Name = "BloxcubeClassMasters"
    folder.Parent = Workspace

    for _, masterSpec in CombatConfig.ClassMasters do
        spawnClassMasterNPC(masterSpec, folder)
    end
end

return table.freeze(ClassMasterService)
