--!strict
-- WorldService: Builds the Cube World Style Voxel Biome, Spirit Cube Anvil, Campfire & Boss Ruin Arena

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Network = require(ReplicatedStorage.network)
local PlayerService = require(script.Parent.PlayerService)

local WorldService = {}

local function createBlock(
    name: string,
    size: Vector3,
    color: Color3,
    cframe: CFrame,
    parent: Instance,
    canCollide: boolean?,
    material: Enum.Material?
): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Color = color
    part.CFrame = cframe
    part.Anchored = true
    part.CanCollide = if canCollide == nil then true else canCollide
    part.Material = material or Enum.Material.SmoothPlastic
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.CastShadow = true
    part.Parent = parent
    return part
end

local function createStationBillboard(adornee: BasePart, titleText: string, subText: string, accentColor: Color3)
    local bb = Instance.new("BillboardGui")
    bb.Name = "StationBillboard"
    bb.Adornee = adornee
    bb.Size = UDim2.new(0, 210, 0, 44)
    bb.StudsOffset = Vector3.new(0, 3.8, 0)
    bb.AlwaysOnTop = false
    bb.MaxDistance = 65
    bb.Parent = adornee

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 22)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 13
    title.TextColor3 = accentColor
    title.TextStrokeTransparency = 0.2
    title.Text = titleText
    title.Parent = bb

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, 0, 0, 18)
    sub.Position = UDim2.new(0, 0, 0, 21)
    sub.BackgroundTransparency = 1
    sub.Font = Enum.Font.GothamBold
    sub.TextSize = 11
    sub.TextColor3 = Color3.fromRGB(235, 240, 250)
    sub.TextStrokeTransparency = 0.25
    sub.Text = subText
    sub.Parent = bb
end

local function buildVoxelTree(origin: Vector3, scale: number, leafColor: Color3, parent: Instance)
    local model = Instance.new("Model")
    model.Name = "VoxelTree"

    local trunkColor = Color3.fromRGB(116, 76, 44)
    local trunkH = 7.5 * scale
    local trunkW = 2.0 * scale

    createBlock(
        "Trunk",
        Vector3.new(trunkW, trunkH, trunkW),
        trunkColor,
        CFrame.new(origin + Vector3.new(0, trunkH * 0.5, 0)),
        model,
        true
    )

    -- Stepped Cube World Leafy Canopy (3 Voxel Tiers)
    local tier1H = 3.2 * scale
    local tier2H = 2.8 * scale
    local tier3H = 2.2 * scale
    local topLight = leafColor:Lerp(Color3.fromRGB(255, 255, 220), 0.14)

    createBlock(
        "CanopyLow",
        Vector3.new(7.2 * scale, tier1H, 7.2 * scale),
        leafColor,
        CFrame.new(origin + Vector3.new(0, trunkH + tier1H * 0.3, 0)),
        model,
        true
    )
    createBlock(
        "CanopyMid",
        Vector3.new(5.4 * scale, tier2H, 5.4 * scale),
        topLight,
        CFrame.new(origin + Vector3.new(0, trunkH + tier1H * 0.8 + tier2H * 0.4, 0)),
        model,
        true
    )
    createBlock(
        "CanopyTop",
        Vector3.new(3.4 * scale, tier3H, 3.4 * scale),
        topLight,
        CFrame.new(origin + Vector3.new(0, trunkH + tier1H + tier2H * 0.75 + tier3H * 0.4, 0)),
        model,
        true
    )

    model.Parent = parent
end

local function buildSteppedHill(origin: Vector3, width: number, depth: number, tiers: number, parent: Instance)
    local model = Instance.new("Model")
    model.Name = "VoxelHill"

    local grassBase = Color3.fromRGB(88, 168, 74)
    local dirtEdge = Color3.fromRGB(134, 96, 62)

    for i = 1, tiers do
        local ratio = 1 - (i - 1) * (0.22 / math.max(1, tiers - 1))
        local w = width * ratio
        local d = depth * ratio
        local h = 3.2
        local y = (i - 0.5) * h
        local tierColor = grassBase:Lerp(Color3.fromRGB(122, 202, 92), (i - 1) / math.max(1, tiers))

        createBlock(
            "HillDirt_" .. i,
            Vector3.new(w, h * 0.7, d),
            dirtEdge,
            CFrame.new(origin + Vector3.new(0, y - h * 0.15, 0)),
            model,
            true
        )
        createBlock(
            "HillGrass_" .. i,
            Vector3.new(w + 0.4, h * 0.35, d + 0.4),
            tierColor,
            CFrame.new(origin + Vector3.new(0, y + h * 0.35, 0)),
            model,
            true
        )
    end

    model.Parent = parent
end

local function buildCraftingStations(parent: Instance)
    -- 1. Voxel Spirit Cube Weapon Forge & Anvil (East of Spawn)
    local forgeOrigin = Vector3.new(15, 0, -4)
    local forgeModel = Instance.new("Model")
    forgeModel.Name = "SpiritCubeForge"

    local stoneBase = Color3.fromRGB(92, 98, 114)
    local darkIron = Color3.fromRGB(52, 56, 68)
    local emberNeon = Color3.fromRGB(255, 118, 42)
    local crystalBlue = Color3.fromRGB(78, 208, 255)

    createBlock(
        "ForgePlatform",
        Vector3.new(7.5, 0.6, 6.5),
        stoneBase,
        CFrame.new(forgeOrigin + Vector3.new(0, 0.3, 0)),
        forgeModel,
        true
    )
    local anvilBase = createBlock(
        "AnvilBase",
        Vector3.new(2.2, 1.4, 1.6),
        darkIron,
        CFrame.new(forgeOrigin + Vector3.new(-1.2, 1.3, 0)),
        forgeModel,
        true,
        Enum.Material.Metal
    )
    createBlock(
        "AnvilTop",
        Vector3.new(3.2, 0.9, 1.8),
        darkIron,
        CFrame.new(forgeOrigin + Vector3.new(-1.2, 2.35, 0)),
        forgeModel,
        true,
        Enum.Material.Metal
    )
    createBlock(
        "SpiritPedestal",
        Vector3.new(1.8, 2.2, 1.8),
        stoneBase,
        CFrame.new(forgeOrigin + Vector3.new(1.6, 1.7, 0)),
        forgeModel,
        true
    )
    createBlock(
        "FloatingSpiritCube",
        Vector3.new(1.1, 1.1, 1.1),
        crystalBlue,
        CFrame.new(forgeOrigin + Vector3.new(1.6, 3.6, 0)) * CFrame.Angles(math.rad(35), math.rad(45), 0),
        forgeModel,
        false,
        Enum.Material.Neon
    )
    createBlock(
        "ForgeEmber",
        Vector3.new(1.2, 0.4, 1.2),
        emberNeon,
        CFrame.new(forgeOrigin + Vector3.new(-1.2, 0.7, 1.6)),
        forgeModel,
        false,
        Enum.Material.Neon
    )

    createStationBillboard(
        anvilBase,
        "⚒ SPIRIT CUBE WEAPON FORGE",
        "Press [E] or [I] to Upgrade Weapon & Equip Loot",
        Color3.fromRGB(98, 220, 255)
    )

    local forgePrompt = Instance.new("ProximityPrompt")
    forgePrompt.ObjectText = "Voxel Weapon Customization"
    forgePrompt.ActionText = "Open Spirit Cube Forge [I]"
    forgePrompt.HoldDuration = 0
    forgePrompt.MaxActivationDistance = 12
    forgePrompt.RequiresLineOfSight = false
    forgePrompt.Parent = anvilBase

    forgePrompt.Triggered:Connect(function(player: Player)
        Network.getEvent("OpenForgeUI"):FireClient(player)
    end)

    forgeModel.Parent = parent

    -- 2. Voxel Heartflower Campfire & Alchemy Cauldron (West of Spawn)
    local campOrigin = Vector3.new(-15, 0, -4)
    local campModel = Instance.new("Model")
    campModel.Name = "HeartflowerCampfire"

    local woodLog = Color3.fromRGB(118, 76, 42)
    local fireOrange = Color3.fromRGB(255, 142, 42)
    local potionPink = Color3.fromRGB(245, 76, 108)

    createBlock(
        "CampStoneRing",
        Vector3.new(6.5, 0.5, 6.5),
        stoneBase,
        CFrame.new(campOrigin + Vector3.new(0, 0.25, 0)),
        campModel,
        true
    )
    createBlock(
        "Log1",
        Vector3.new(3.2, 0.55, 0.65),
        woodLog,
        CFrame.new(campOrigin + Vector3.new(-1.0, 0.7, 0)) * CFrame.Angles(0, math.rad(30), 0),
        campModel,
        false
    )
    createBlock(
        "Log2",
        Vector3.new(3.2, 0.55, 0.65),
        woodLog,
        CFrame.new(campOrigin + Vector3.new(-1.0, 0.7, 0)) * CFrame.Angles(0, math.rad(-60), 0),
        campModel,
        false
    )
    createBlock(
        "FlameCore",
        Vector3.new(1.3, 1.6, 1.3),
        fireOrange,
        CFrame.new(campOrigin + Vector3.new(-1.0, 1.4, 0)),
        campModel,
        false,
        Enum.Material.Neon
    )

    local cauldron = createBlock(
        "AlchemyCauldron",
        Vector3.new(2.2, 1.8, 2.2),
        darkIron,
        CFrame.new(campOrigin + Vector3.new(1.6, 1.3, 0)),
        campModel,
        true,
        Enum.Material.Metal
    )
    createBlock(
        "CauldronBrew",
        Vector3.new(1.8, 0.3, 1.8),
        potionPink,
        CFrame.new(campOrigin + Vector3.new(1.6, 2.15, 0)),
        campModel,
        false,
        Enum.Material.Neon
    )

    createStationBillboard(
        cauldron,
        "♥ HEARTFLOWER ALCHEMY CAMP",
        "Press [E] to Brew Potion (15 Gold) | [1] Drink",
        Color3.fromRGB(255, 112, 138)
    )

    local brewPrompt = Instance.new("ProximityPrompt")
    brewPrompt.ObjectText = "Heartflower Cauldron (15 Gold)"
    brewPrompt.ActionText = "Brew Heartflower Potion (+1)"
    brewPrompt.HoldDuration = 0
    brewPrompt.MaxActivationDistance = 12
    brewPrompt.RequiresLineOfSight = false
    brewPrompt.Parent = cauldron

    brewPrompt.Triggered:Connect(function(player: Player)
        PlayerService.buyPotionWithGold(player)
    end)

    campModel.Parent = parent
end

local function buildBossRuinArena(parent: Instance)
    local arenaOrigin = Vector3.new(0, 0, 82)
    local arena = Instance.new("Model")
    arena.Name = "BossRuinArena"

    local ruinStone = Color3.fromRGB(112, 118, 132)
    local mossGreen = Color3.fromRGB(78, 148, 82)
    local goldRune = Color3.fromRGB(255, 202, 68)

    createBlock(
        "ArenaFloorOuter",
        Vector3.new(36, 0.5, 36),
        ruinStone,
        CFrame.new(arenaOrigin + Vector3.new(0, 0.25, 0)),
        arena,
        true
    )
    createBlock(
        "ArenaFloorInner",
        Vector3.new(26, 0.65, 26),
        Color3.fromRGB(88, 94, 108),
        CFrame.new(arenaOrigin + Vector3.new(0, 0.32, 0)),
        arena,
        true
    )
    createBlock(
        "ArenaRuneRing",
        Vector3.new(14, 0.7, 14),
        goldRune,
        CFrame.new(arenaOrigin + Vector3.new(0, 0.36, 0)),
        arena,
        true,
        Enum.Material.Neon
    )
    createBlock(
        "ArenaRuneCenter",
        Vector3.new(12, 0.75, 12),
        Color3.fromRGB(72, 78, 92),
        CFrame.new(arenaOrigin + Vector3.new(0, 0.38, 0)),
        arena,
        true
    )

    local pillarOffsets = {
        Vector3.new(-15, 0, -15),
        Vector3.new(15, 0, -15),
        Vector3.new(-15, 0, 15),
        Vector3.new(15, 0, 15),
    }

    for idx, offset in pillarOffsets do
        local pPos = arenaOrigin + offset
        local h = if idx % 2 == 0 then 11 else 8.5
        createBlock(
            "PillarBase_" .. idx,
            Vector3.new(3.6, 1.4, 3.6),
            ruinStone,
            CFrame.new(pPos + Vector3.new(0, 0.7, 0)),
            arena,
            true
        )
        createBlock(
            "PillarShaft_" .. idx,
            Vector3.new(2.6, h, 2.6),
            ruinStone,
            CFrame.new(pPos + Vector3.new(0, h * 0.5 + 1.2, 0)),
            arena,
            true
        )
        createBlock(
            "PillarMoss_" .. idx,
            Vector3.new(2.8, 1.2, 2.8),
            mossGreen,
            CFrame.new(pPos + Vector3.new(0, h + 1.2, 0)),
            arena,
            true
        )
    end

    arena.Parent = parent
end

function WorldService.init()
    local existing = Workspace:FindFirstChild("BloxcubeWorld")
    if existing then
        existing:Destroy()
    end

    local worldFolder = Instance.new("Folder")
    worldFolder.Name = "BloxcubeWorld"
    worldFolder.Parent = Workspace

    -- Style Baseplate into Cube World Emerald Meadow Grass
    local baseplate = Workspace:FindFirstChild("Baseplate")
    if baseplate and baseplate:IsA("BasePart") then
        baseplate.Color = Color3.fromRGB(92, 168, 78)
        baseplate.Material = Enum.Material.SmoothPlastic
    end

    -- Stone Pathways connecting North Guild Courtyard -> Spawn Plaza -> South Slime & Boss Ruins
    local pathStone = Color3.fromRGB(154, 158, 168)
    createBlock("CenterPlaza", Vector3.new(20, 0.25, 20), pathStone, CFrame.new(0, 0.12, 0), worldFolder, true)
    for z = -22, 62, 7 do
        createBlock("RoadTile_" .. z, Vector3.new(7.5, 0.22, 5.2), pathStone, CFrame.new(0, 0.11, z), worldFolder, true)
    end

    -- Build Crafting Stations (Spirit Cube Forge & Heartflower Campfire)
    buildCraftingStations(worldFolder)

    -- Build South Ancient Boss Ruin Arena
    buildBossRuinArena(worldFolder)

    -- Build Cube World Voxel Trees
    local treeConfigs = {
        { Pos = Vector3.new(-34, 0, -18), Scale = 1.15, Color = Color3.fromRGB(68, 168, 76) },
        { Pos = Vector3.new(34, 0, -18), Scale = 1.1, Color = Color3.fromRGB(78, 182, 82) },
        { Pos = Vector3.new(-38, 0, 12), Scale = 1.25, Color = Color3.fromRGB(64, 158, 72) },
        { Pos = Vector3.new(38, 0, 12), Scale = 1.2, Color = Color3.fromRGB(86, 188, 78) },
        { Pos = Vector3.new(-36, 0, 44), Scale = 1.1, Color = Color3.fromRGB(72, 174, 84) },
        { Pos = Vector3.new(36, 0, 44), Scale = 1.3, Color = Color3.fromRGB(64, 158, 72) },
        { Pos = Vector3.new(-32, 0, 76), Scale = 1.2, Color = Color3.fromRGB(58, 148, 68) },
        { Pos = Vector3.new(32, 0, 76), Scale = 1.2, Color = Color3.fromRGB(58, 148, 68) },
    }
    for _, tc in treeConfigs do
        buildVoxelTree(tc.Pos, tc.Scale, tc.Color, worldFolder)
    end

    -- Build Stepped Voxel Hills around the perimeter
    buildSteppedHill(Vector3.new(-62, 0, -28), 32, 28, 3, worldFolder)
    buildSteppedHill(Vector3.new(62, 0, -28), 32, 28, 3, worldFolder)
    buildSteppedHill(Vector3.new(-66, 0, 38), 36, 34, 4, worldFolder)
    buildSteppedHill(Vector3.new(66, 0, 38), 36, 34, 4, worldFolder)
    buildSteppedHill(Vector3.new(0, 0, -58), 54, 24, 3, worldFolder)
    buildSteppedHill(Vector3.new(0, 0, 122), 58, 26, 4, worldFolder)
end

return table.freeze(WorldService)
