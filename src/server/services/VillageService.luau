--!strict
-- VillageService: Builds Emberleaf Village (starter village & spawn point) and the floating
-- "Hero's Dawn" Character Creation islet. Also moves the default SpawnLocation into the village plaza.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local WorldConfig = require(ReplicatedStorage.configs.WorldConfig)

local VillageService = {}

local VILLAGE = WorldConfig.Village

local COLORS = {
    Foundation = Color3.fromRGB(132, 134, 142),
    FoundationDark = Color3.fromRGB(104, 106, 116),
    Beam = Color3.fromRGB(116, 78, 48),
    BeamDark = Color3.fromRGB(88, 58, 36),
    Door = Color3.fromRGB(92, 60, 38),
    WindowGlow = Color3.fromRGB(255, 212, 138),
    Log = Color3.fromRGB(128, 88, 54),
    LogLight = Color3.fromRGB(150, 106, 66),
    LogTip = Color3.fromRGB(96, 64, 40),
    CobbleA = Color3.fromRGB(158, 156, 150),
    CobbleB = Color3.fromRGB(140, 138, 134),
    CobbleTrim = Color3.fromRGB(116, 114, 112),
    Water = Color3.fromRGB(96, 178, 232),
    LampGlow = Color3.fromRGB(255, 204, 120),
    LeafA = Color3.fromRGB(86, 170, 82),
    LeafB = Color3.fromRGB(104, 186, 90),
    Trunk = Color3.fromRGB(116, 76, 44),
    Grass = Color3.fromRGB(104, 178, 86),
    Dirt = Color3.fromRGB(134, 96, 62),
    Stone = Color3.fromRGB(118, 120, 130),
}

local HOUSE_STYLES = {
    { Wall = Color3.fromRGB(236, 222, 192), Roof = Color3.fromRGB(196, 82, 66) },
    { Wall = Color3.fromRGB(226, 200, 156), Roof = Color3.fromRGB(70, 140, 150) },
    { Wall = Color3.fromRGB(232, 214, 178), Roof = Color3.fromRGB(212, 132, 64) },
    { Wall = Color3.fromRGB(214, 210, 198), Roof = Color3.fromRGB(86, 112, 176) },
    { Wall = Color3.fromRGB(230, 206, 168), Roof = Color3.fromRGB(104, 152, 86) },
    { Wall = Color3.fromRGB(238, 226, 204), Roof = Color3.fromRGB(150, 98, 168) },
}

local function block(
    name: string,
    size: Vector3,
    color: Color3,
    cframe: CFrame,
    parent: Instance,
    material: Enum.Material?,
    canCollide: boolean?
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
    part.Parent = parent
    return part
end

local function addWarmLight(part: BasePart, range: number, brightness: number)
    local light = Instance.new("PointLight")
    light.Color = COLORS.LampGlow
    light.Range = range
    light.Brightness = brightness
    light.Shadows = false
    light.Parent = part
end

local function buildTree(origin: Vector3, scale: number, parent: Instance)
    local model = Instance.new("Model")
    model.Name = "VillageTree"
    local trunkH = 6 * scale
    block(
        "Trunk",
        Vector3.new(1.6 * scale, trunkH, 1.6 * scale),
        COLORS.Trunk,
        CFrame.new(origin + Vector3.new(0, trunkH / 2, 0)),
        model
    )
    block(
        "CanopyLow",
        Vector3.new(6 * scale, 2.8 * scale, 6 * scale),
        COLORS.LeafA,
        CFrame.new(origin + Vector3.new(0, trunkH + 0.9 * scale, 0)),
        model
    )
    block(
        "CanopyTop",
        Vector3.new(4 * scale, 2.4 * scale, 4 * scale),
        COLORS.LeafB,
        CFrame.new(origin + Vector3.new(0, trunkH + 3.2 * scale, 0)),
        model
    )
    model.Parent = parent
end

---------------------------------------------------------------------------
-- Cottage: door faces the CFrame LookVector (local -Z)
---------------------------------------------------------------------------
local function buildHouse(origin: Vector3, doorDirection: Vector3, styleIndex: number, parent: Instance)
    local style = HOUSE_STYLES[((styleIndex - 1) % #HOUSE_STYLES) + 1]
    local base = CFrame.lookAt(origin, origin + doorDirection)
    local model = Instance.new("Model")
    model.Name = "Cottage_" .. styleIndex

    local W, D, H = 10, 8, 6
    local function at(x: number, y: number, z: number): CFrame
        return base * CFrame.new(x, y, z)
    end

    block("Foundation", Vector3.new(W + 1, 1, D + 1), COLORS.Foundation, at(0, 0.5, 0), model)
    block("Walls", Vector3.new(W, H, D), style.Wall, at(0, 1 + H / 2, 0), model)

    for _, sx in { -1, 1 } do
        for _, sz in { -1, 1 } do
            block("CornerBeam", Vector3.new(0.8, H, 0.8), COLORS.Beam, at(sx * W / 2, 1 + H / 2, sz * D / 2), model)
        end
    end
    block("TopBand", Vector3.new(W + 0.4, 0.6, D + 0.4), COLORS.Beam, at(0, 1 + H - 0.3, 0), model)
    block("MidBand", Vector3.new(W + 0.2, 0.35, D + 0.2), COLORS.BeamDark, at(0, 1 + H * 0.45, 0), model)

    -- Front door, frame & step
    block("Door", Vector3.new(2.2, 3.6, 0.3), COLORS.Door, at(0, 2.8, -D / 2 - 0.12), model)
    block("DoorFrame", Vector3.new(3, 0.45, 0.4), COLORS.BeamDark, at(0, 4.75, -D / 2 - 0.15), model)
    block("DoorKnob", Vector3.new(0.25, 0.25, 0.2), Color3.fromRGB(230, 190, 90), at(0.7, 2.8, -D / 2 - 0.32), model)
    block("DoorStep", Vector3.new(3, 0.4, 1.4), COLORS.FoundationDark, at(0, 0.2, -D / 2 - 1.1), model)

    -- Glowing windows with flower boxes
    for _, sx in { -1, 1 } do
        local win = block(
            "Window",
            Vector3.new(1.6, 1.4, 0.2),
            COLORS.WindowGlow,
            at(sx * 3, 4.3, -D / 2 - 0.1),
            model,
            Enum.Material.Neon
        )
        win.CanCollide = false
        block("WindowSill", Vector3.new(2.1, 0.3, 0.5), COLORS.Beam, at(sx * 3, 3.45, -D / 2 - 0.25), model)
        block(
            "FlowerBox",
            Vector3.new(1.9, 0.35, 0.45),
            if sx < 0 then Color3.fromRGB(236, 116, 150) else Color3.fromRGB(246, 206, 88),
            at(sx * 3, 3.75, -D / 2 - 0.45),
            model
        )
        local side = block(
            "SideWindow",
            Vector3.new(0.2, 1.4, 1.6),
            COLORS.WindowGlow,
            at(sx * (W / 2 + 0.1), 4.3, 0),
            model,
            Enum.Material.Neon
        )
        side.CanCollide = false
    end

    -- Stepped voxel gable roof (ridge along local X)
    local tiers = 4
    for i = 1, tiers do
        local depth = D + 1.8 - (i - 1) * 2.5
        local tierColor = style.Roof:Lerp(Color3.fromRGB(255, 255, 255), (i - 1) * 0.05)
        block("Roof_" .. i, Vector3.new(W + 1.6, 1, depth), tierColor, at(0, 1 + H + (i - 0.5), 0), model)
    end
    block(
        "RoofRidge",
        Vector3.new(W + 1.9, 0.5, 1.4),
        style.Roof:Lerp(Color3.fromRGB(0, 0, 0), 0.2),
        at(0, 1 + H + tiers + 0.25, 0),
        model
    )

    -- Chimney
    block("Chimney", Vector3.new(1.4, 4.2, 1.4), COLORS.Foundation, at(W / 2 - 2, 1 + H + 2.4, D / 4), model)
    block("ChimneyCap", Vector3.new(1.7, 0.4, 1.7), COLORS.FoundationDark, at(W / 2 - 2, 1 + H + 4.7, D / 4), model)

    -- Barrel & crate decoration beside the door
    block("Barrel", Vector3.new(1.3, 1.6, 1.3), Color3.fromRGB(140, 94, 56), at(W / 2 - 0.6, 1.8, -D / 2 - 1.3), model)
    block(
        "BarrelBand",
        Vector3.new(1.4, 0.2, 1.4),
        Color3.fromRGB(84, 84, 92),
        at(W / 2 - 0.6, 2.1, -D / 2 - 1.3),
        model
    )
    block(
        "Crate",
        Vector3.new(1.2, 1.2, 1.2),
        Color3.fromRGB(176, 128, 78),
        at(-W / 2 + 0.8, 1.6, -D / 2 - 1.2) * CFrame.Angles(0, math.rad(18), 0),
        model
    )

    model.Parent = parent
end

---------------------------------------------------------------------------
-- Palisade wall, corner watchtowers & gates
---------------------------------------------------------------------------
local function buildWallRun(from: Vector3, to: Vector3, parent: Instance, seed: number)
    local delta = to - from
    local length = delta.Magnitude
    if length < 1 then
        return
    end
    local dir = delta.Unit
    local rng = Random.new(seed)
    local spacing = 2.2
    local count = math.max(1, math.floor(length / spacing))
    for i = 0, count do
        local pos = from + dir * math.min(length, i * spacing)
        local h = rng:NextNumber(4.4, 5.6)
        local color = if i % 3 == 0 then COLORS.LogLight else COLORS.Log
        block("Log", Vector3.new(1.6, h, 1.6), color, CFrame.new(pos + Vector3.new(0, h / 2, 0)), parent)
        block(
            "LogTip",
            Vector3.new(0.9, 0.7, 0.9),
            COLORS.LogTip,
            CFrame.new(pos + Vector3.new(0, h + 0.35, 0)),
            parent
        )
    end
    -- Inner support rail
    local mid = from + delta / 2
    local railCF = CFrame.lookAt(mid, mid + dir) * CFrame.new(0, 0, 0)
    for _, y in { 1.4, 3.4 } do
        block(
            "WallRail",
            Vector3.new(0.5, 0.45, length),
            COLORS.BeamDark,
            railCF + Vector3.new(0, y, 0) + (dir:Cross(Vector3.yAxis) * 0.9),
            parent,
            nil,
            false
        )
    end
end

local function buildWatchtower(pos: Vector3, parent: Instance)
    local model = Instance.new("Model")
    model.Name = "Watchtower"
    for _, sx in { -1, 1 } do
        for _, sz in { -1, 1 } do
            block(
                "Leg",
                Vector3.new(1, 9, 1),
                COLORS.Log,
                CFrame.new(pos + Vector3.new(sx * 1.8, 4.5, sz * 1.8)),
                model
            )
        end
    end
    block("Platform", Vector3.new(5.6, 0.6, 5.6), COLORS.Beam, CFrame.new(pos + Vector3.new(0, 9, 0)), model)
    for _, sx in { -1, 1 } do
        block(
            "RailX",
            Vector3.new(5.6, 1, 0.4),
            COLORS.BeamDark,
            CFrame.new(pos + Vector3.new(0, 9.8, sx * 2.6)),
            model
        )
        block(
            "RailZ",
            Vector3.new(0.4, 1, 5.6),
            COLORS.BeamDark,
            CFrame.new(pos + Vector3.new(sx * 2.6, 9.8, 0)),
            model
        )
    end
    block(
        "RoofLow",
        Vector3.new(6.4, 0.8, 6.4),
        Color3.fromRGB(176, 72, 60),
        CFrame.new(pos + Vector3.new(0, 13, 0)),
        model
    )
    block(
        "RoofTop",
        Vector3.new(4, 0.8, 4),
        Color3.fromRGB(196, 86, 70),
        CFrame.new(pos + Vector3.new(0, 13.8, 0)),
        model
    )
    for _, sx in { -1, 1 } do
        for _, sz in { -1, 1 } do
            block(
                "RoofPost",
                Vector3.new(0.5, 3.6, 0.5),
                COLORS.Log,
                CFrame.new(pos + Vector3.new(sx * 2.4, 11, sz * 2.4)),
                model
            )
        end
    end
    local lantern = block(
        "TowerLantern",
        Vector3.new(0.9, 1, 0.9),
        COLORS.LampGlow,
        CFrame.new(pos + Vector3.new(0, 11.8, 0)),
        model,
        Enum.Material.Neon,
        false
    )
    addWarmLight(lantern, 18, 1.2)
    model.Parent = parent
end

local function addSignText(part: BasePart, text: string, face: Enum.NormalId)
    local gui = Instance.new("SurfaceGui")
    gui.Face = face
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 40
    gui.LightInfluence = 0.3
    gui.Parent = part

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.FredokaOne
    label.TextScaled = true
    label.TextColor3 = Color3.fromRGB(255, 232, 170)
    label.TextStrokeColor3 = Color3.fromRGB(60, 36, 18)
    label.TextStrokeTransparency = 0.2
    label.Text = text
    label.Parent = gui

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0.14, 0)
    pad.PaddingBottom = UDim.new(0.14, 0)
    pad.PaddingLeft = UDim.new(0.05, 0)
    pad.PaddingRight = UDim.new(0.05, 0)
    pad.Parent = label
end

local function buildGate(center: Vector3, alongX: boolean, halfWidth: number, isMain: boolean, parent: Instance)
    local model = Instance.new("Model")
    model.Name = if isMain then "MainGate" else "SideGate"
    local pillarH = if isMain then 10 else 7.5
    local axis = if alongX then Vector3.xAxis else Vector3.zAxis

    for _, s in { -1, 1 } do
        local p = center + axis * s * (halfWidth + 1.3)
        block(
            "GatePillar",
            Vector3.new(2.6, pillarH, 2.6),
            COLORS.Log,
            CFrame.new(p + Vector3.new(0, pillarH / 2, 0)),
            model
        )
        block(
            "PillarCap",
            Vector3.new(3, 0.8, 3),
            COLORS.LogTip,
            CFrame.new(p + Vector3.new(0, pillarH + 0.4, 0)),
            model
        )
        local lantern = block(
            "GateLantern",
            Vector3.new(0.9, 1.1, 0.9),
            COLORS.LampGlow,
            CFrame.new(p + Vector3.new(0, pillarH - 2.2, 0) - (if alongX then Vector3.zAxis else Vector3.xAxis) * 1.6),
            model,
            Enum.Material.Neon,
            false
        )
        addWarmLight(lantern, 16, 1.4)
    end

    local beamLen = halfWidth * 2 + 5.4
    local beamSize = if alongX then Vector3.new(beamLen, 1.4, 1.8) else Vector3.new(1.8, 1.4, beamLen)
    block("GateBeam", beamSize, COLORS.Beam, CFrame.new(center + Vector3.new(0, pillarH - 0.7, 0)), model)

    if isMain then
        local signSize = if alongX then Vector3.new(11, 2.4, 0.4) else Vector3.new(0.4, 2.4, 11)
        local sign = block(
            "VillageSign",
            signSize,
            Color3.fromRGB(122, 82, 48),
            CFrame.new(center + Vector3.new(0, pillarH - 2.8, 0)),
            model
        )
        block(
            "SignBorder",
            signSize + Vector3.new(0.5, 0.5, -0.1),
            COLORS.BeamDark,
            CFrame.new(center + Vector3.new(0, pillarH - 2.8, 0)),
            model
        )
        local upper = string.upper(VILLAGE.Name)
        if alongX then
            addSignText(sign, upper, Enum.NormalId.Front)
            addSignText(sign, upper, Enum.NormalId.Back)
        else
            addSignText(sign, upper, Enum.NormalId.Left)
            addSignText(sign, upper, Enum.NormalId.Right)
        end
        -- Banners hanging from the beam
        for _, s in { -1, 1 } do
            local bannerPos = center + axis * s * (halfWidth - 0.8) + Vector3.new(0, pillarH - 3.2, 0)
            local bannerSize = if alongX then Vector3.new(1.4, 3.6, 0.2) else Vector3.new(0.2, 3.6, 1.4)
            block("Banner", bannerSize, Color3.fromRGB(196, 72, 60), CFrame.new(bannerPos), model, nil, false)
            block(
                "BannerEmblem",
                bannerSize * Vector3.new(0.55, 0.3, 1.2),
                Color3.fromRGB(255, 206, 96),
                CFrame.new(bannerPos + Vector3.new(0, 0.3, 0)),
                model,
                Enum.Material.Neon,
                false
            )
        end
    end

    model.Parent = parent
end

local function buildPalisade(parent: Instance)
    local wall = Instance.new("Model")
    wall.Name = "Palisade"
    local minX, maxX, minZ, maxZ = VILLAGE.MinX, VILLAGE.MaxX, VILLAGE.MinZ, VILLAGE.MaxZ
    local gw = VILLAGE.SouthGateHalfWidth
    local sz, sw = VILLAGE.SideGateZ, VILLAGE.SideGateHalfWidth

    -- North wall (solid)
    buildWallRun(Vector3.new(minX, 0, minZ), Vector3.new(maxX, 0, minZ), wall, 11)
    -- South wall with main gate gap
    buildWallRun(Vector3.new(minX, 0, maxZ), Vector3.new(-gw - 2.6, 0, maxZ), wall, 12)
    buildWallRun(Vector3.new(gw + 2.6, 0, maxZ), Vector3.new(maxX, 0, maxZ), wall, 13)
    -- West wall with side gate gap
    buildWallRun(Vector3.new(minX, 0, minZ), Vector3.new(minX, 0, sz - sw - 2.6), wall, 14)
    buildWallRun(Vector3.new(minX, 0, sz + sw + 2.6), Vector3.new(minX, 0, maxZ), wall, 15)
    -- East wall with side gate gap
    buildWallRun(Vector3.new(maxX, 0, minZ), Vector3.new(maxX, 0, sz - sw - 2.6), wall, 16)
    buildWallRun(Vector3.new(maxX, 0, sz + sw + 2.6), Vector3.new(maxX, 0, maxZ), wall, 17)

    for _, corner in
        {
            Vector3.new(minX, 0, minZ),
            Vector3.new(maxX, 0, minZ),
            Vector3.new(minX, 0, maxZ),
            Vector3.new(maxX, 0, maxZ),
        }
    do
        buildWatchtower(corner, wall)
    end

    buildGate(Vector3.new(0, 0, maxZ), true, gw, true, wall)
    buildGate(Vector3.new(minX, 0, sz), false, sw, false, wall)
    buildGate(Vector3.new(maxX, 0, sz), false, sw, false, wall)

    wall.Parent = parent
end

---------------------------------------------------------------------------
-- Plaza, fountain, roads, lamps, market & decor
---------------------------------------------------------------------------
local function buildPlaza(parent: Instance)
    local model = Instance.new("Model")
    model.Name = "VillagePlaza"

    local tile = 6
    for ix = -2, 2 do
        for iz = -2, 2 do
            local color = if (ix + iz) % 2 == 0 then COLORS.CobbleA else COLORS.CobbleB
            block(
                "PlazaTile",
                Vector3.new(tile, 0.3, tile),
                color,
                CFrame.new(ix * tile, 0.15, iz * tile),
                model,
                Enum.Material.Cobblestone
            )
        end
    end
    -- Plaza trim border
    for _, s in { -1, 1 } do
        block("PlazaTrimX", Vector3.new(31, 0.4, 0.8), COLORS.CobbleTrim, CFrame.new(0, 0.2, s * 15.2), model)
        block("PlazaTrimZ", Vector3.new(0.8, 0.4, 31), COLORS.CobbleTrim, CFrame.new(s * 15.2, 0.2, 0), model)
    end

    -- Roads: south to main gate, east & west to side gates, north to the Guild Courtyard
    local function road(from: Vector3, to: Vector3, width: number)
        local delta = to - from
        local len = delta.Magnitude
        local steps = math.max(1, math.floor(len / 4))
        for i = 0, steps - 1 do
            local t = (i + 0.5) / steps
            local pos = from + delta * t
            local size = if math.abs(delta.X) > math.abs(delta.Z)
                then Vector3.new(len / steps - 0.3, 0.26, width)
                else Vector3.new(width, 0.26, len / steps - 0.3)
            block(
                "RoadStone",
                size,
                if i % 2 == 0 then COLORS.CobbleA else COLORS.CobbleB,
                CFrame.new(pos.X, 0.13, pos.Z),
                model,
                Enum.Material.Cobblestone
            )
        end
    end
    road(Vector3.new(0, 0, 15.6), Vector3.new(0, 0, VILLAGE.MaxZ + 4), 6)
    road(Vector3.new(15.6, 0, VILLAGE.SideGateZ), Vector3.new(VILLAGE.MaxX + 3, 0, VILLAGE.SideGateZ), 4.5)
    road(Vector3.new(-15.6, 0, VILLAGE.SideGateZ), Vector3.new(VILLAGE.MinX - 3, 0, VILLAGE.SideGateZ), 4.5)
    road(Vector3.new(0, 0, -15.6), Vector3.new(0, 0, -34), 5)

    model.Parent = parent
end

local function buildFountain(parent: Instance)
    local model = Instance.new("Model")
    model.Name = "VillageFountain"
    local p = VILLAGE.FountainPosition

    block("BasinOuter", Vector3.new(9, 1.2, 9), COLORS.Stone, CFrame.new(p + Vector3.new(0, 0.6, 0)), model)
    block("BasinRim", Vector3.new(9.4, 0.4, 9.4), COLORS.FoundationDark, CFrame.new(p + Vector3.new(0, 1.3, 0)), model)
    local water = block(
        "Water",
        Vector3.new(7.6, 0.3, 7.6),
        COLORS.Water,
        CFrame.new(p + Vector3.new(0, 1.35, 0)),
        model,
        Enum.Material.Glass,
        false
    )
    water.Transparency = 0.25
    block("Pillar", Vector3.new(1.6, 3.4, 1.6), COLORS.Foundation, CFrame.new(p + Vector3.new(0, 2.6, 0)), model)
    block("UpperBowl", Vector3.new(3.6, 0.7, 3.6), COLORS.Stone, CFrame.new(p + Vector3.new(0, 4.4, 0)), model)
    local topWater = block(
        "UpperWater",
        Vector3.new(3, 0.25, 3),
        COLORS.Water,
        CFrame.new(p + Vector3.new(0, 4.8, 0)),
        model,
        Enum.Material.Glass,
        false
    )
    topWater.Transparency = 0.2
    local crystal = block(
        "SpiritCrystal",
        Vector3.new(0.9, 1.6, 0.9),
        Color3.fromRGB(120, 220, 255),
        CFrame.new(p + Vector3.new(0, 5.8, 0)) * CFrame.Angles(0, math.rad(45), 0),
        model,
        Enum.Material.Neon,
        false
    )
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(140, 220, 255)
    light.Range = 14
    light.Brightness = 1
    light.Parent = crystal

    local sparkle = Instance.new("ParticleEmitter")
    sparkle.Color = ColorSequence.new(Color3.fromRGB(200, 240, 255))
    sparkle.LightEmission = 0.8
    sparkle.Size = NumberSequence.new(0.25, 0)
    sparkle.Transparency = NumberSequence.new(0.2, 1)
    sparkle.Lifetime = NumberRange.new(0.8, 1.4)
    sparkle.Rate = 8
    sparkle.Speed = NumberRange.new(2, 4)
    sparkle.SpreadAngle = Vector2.new(35, 35)
    sparkle.Acceleration = Vector3.new(0, -6, 0)
    sparkle.Parent = crystal

    model.Parent = parent
end

local function buildLamp(pos: Vector3, parent: Instance)
    local model = Instance.new("Model")
    model.Name = "StreetLamp"
    block(
        "LampBase",
        Vector3.new(1.1, 0.6, 1.1),
        COLORS.FoundationDark,
        CFrame.new(pos + Vector3.new(0, 0.3, 0)),
        model
    )
    block("LampPost", Vector3.new(0.5, 5.4, 0.5), COLORS.BeamDark, CFrame.new(pos + Vector3.new(0, 3.3, 0)), model)
    block("LampCapTop", Vector3.new(1.3, 0.3, 1.3), COLORS.BeamDark, CFrame.new(pos + Vector3.new(0, 6.65, 0)), model)
    local glow = block(
        "LampGlow",
        Vector3.new(0.9, 0.9, 0.9),
        COLORS.LampGlow,
        CFrame.new(pos + Vector3.new(0, 6.05, 0)),
        model,
        Enum.Material.Neon,
        false
    )
    addWarmLight(glow, 16, 1.3)
    model.Parent = parent
end

local function buildMarketStall(pos: Vector3, facing: Vector3, stripe: Color3, parent: Instance)
    local model = Instance.new("Model")
    model.Name = "MarketStall"
    local base = CFrame.lookAt(pos, pos + facing)
    local function at(x: number, y: number, z: number): CFrame
        return base * CFrame.new(x, y, z)
    end

    block("Counter", Vector3.new(6, 1.3, 2), COLORS.Beam, at(0, 0.65, -0.6), model)
    block("CounterTop", Vector3.new(6.3, 0.25, 2.3), COLORS.LogLight, at(0, 1.42, -0.6), model)
    for _, sx in { -1, 1 } do
        for _, sz in { -1, 1 } do
            block("StallPost", Vector3.new(0.4, 3.8, 0.4), COLORS.BeamDark, at(sx * 2.9, 1.9, sz * 1.5), model)
        end
    end
    for i = 0, 3 do
        local color = if i % 2 == 0 then stripe else Color3.fromRGB(244, 236, 220)
        block("Awning", Vector3.new(1.55, 0.3, 4), color, at(-2.33 + i * 1.55, 3.95, 0), model)
        block("Valance", Vector3.new(1.55, 0.6, 0.2), color, at(-2.33 + i * 1.55, 3.55, -2.05), model)
    end
    -- Goods on the counter
    local goods = {
        { Color3.fromRGB(226, 76, 70), -2.2 },
        { Color3.fromRGB(246, 196, 72), -1.1 },
        { Color3.fromRGB(110, 196, 92), 0.1 },
        { Color3.fromRGB(226, 128, 60), 1.3 },
        { Color3.fromRGB(176, 120, 220), 2.3 },
    }
    for _, g in goods do
        block("Goods", Vector3.new(0.7, 0.7, 0.7), g[1], at(g[2], 1.9, -0.6), model)
    end
    block("Crate", Vector3.new(1.3, 1.3, 1.3), Color3.fromRGB(176, 128, 78), at(3.8, 0.65, -0.2), model)

    model.Parent = parent
end

local function buildFlowerBed(pos: Vector3, size: Vector3, parent: Instance, seed: number)
    local model = Instance.new("Model")
    model.Name = "FlowerBed"
    block("Bed", size, COLORS.Dirt, CFrame.new(pos + Vector3.new(0, size.Y / 2, 0)), model)
    block(
        "BedGrass",
        Vector3.new(size.X - 0.3, 0.2, size.Z - 0.3),
        COLORS.Grass,
        CFrame.new(pos + Vector3.new(0, size.Y + 0.1, 0)),
        model
    )
    local rng = Random.new(seed)
    local flowerColors = {
        Color3.fromRGB(244, 112, 140),
        Color3.fromRGB(250, 214, 92),
        Color3.fromRGB(176, 132, 236),
        Color3.fromRGB(255, 255, 255),
        Color3.fromRGB(255, 150, 80),
    }
    local count = math.floor(size.X * size.Z / 2.2)
    for _ = 1, count do
        local fx = rng:NextNumber(-size.X / 2 + 0.5, size.X / 2 - 0.5)
        local fz = rng:NextNumber(-size.Z / 2 + 0.5, size.Z / 2 - 0.5)
        block(
            "Flower",
            Vector3.new(0.45, 0.45, 0.45),
            flowerColors[rng:NextInteger(1, #flowerColors)],
            CFrame.new(pos + Vector3.new(fx, size.Y + 0.45, fz)),
            model,
            nil,
            false
        )
    end
    model.Parent = parent
end

local function buildHayBale(pos: Vector3, parent: Instance)
    block(
        "HayBale",
        Vector3.new(2.2, 1.4, 1.4),
        Color3.fromRGB(226, 196, 104),
        CFrame.new(pos + Vector3.new(0, 0.7, 0)),
        parent
    )
    block(
        "HayBand",
        Vector3.new(0.25, 1.45, 1.45),
        Color3.fromRGB(164, 118, 62),
        CFrame.new(pos + Vector3.new(0.5, 0.7, 0)),
        parent,
        nil,
        false
    )
end

---------------------------------------------------------------------------
-- Character Creation Islet ("Hero's Dawn")
---------------------------------------------------------------------------
local function buildCreationStage(parent: Instance)
    local model = Instance.new("Model")
    model.Name = "HerosDawnIslet"
    local p = WorldConfig.CreationStage.Position

    block("IsletGrass", Vector3.new(24, 1.4, 24), COLORS.Grass, CFrame.new(p + Vector3.new(0, -0.7, 0)), model)
    block("IsletDirt", Vector3.new(22, 3, 22), COLORS.Dirt, CFrame.new(p + Vector3.new(0, -2.9, 0)), model)
    block("IsletStone1", Vector3.new(17, 4, 17), COLORS.Stone, CFrame.new(p + Vector3.new(0, -6.4, 0)), model)
    block("IsletStone2", Vector3.new(11, 4, 11), COLORS.FoundationDark, CFrame.new(p + Vector3.new(0, -10.4, 0)), model)
    block("IsletStone3", Vector3.new(5, 3, 5), COLORS.Stone, CFrame.new(p + Vector3.new(0, -13.9, 0)), model)

    local rune = block(
        "HeroRune",
        Vector3.new(6.5, 0.12, 6.5),
        Color3.fromRGB(255, 214, 130),
        CFrame.new(p + Vector3.new(0, 0.06, 0)),
        model,
        Enum.Material.Neon,
        false
    )
    rune.Transparency = 0.35
    block("HeroRuneInner", Vector3.new(5, 0.16, 5), COLORS.Grass, CFrame.new(p + Vector3.new(0, 0.08, 0)), model)

    buildTree(p + Vector3.new(-7, 0, -6), 1.1, model)
    buildTree(p + Vector3.new(8, 0, -5), 0.9, model)
    buildTree(p + Vector3.new(-9, 0, 5), 0.75, model)
    buildFlowerBed(p + Vector3.new(5, 0, 6), Vector3.new(4, 0.4, 3), model, 91)
    buildFlowerBed(p + Vector3.new(-4, 0, -9), Vector3.new(5, 0.4, 2.5), model, 92)
    buildLamp(p + Vector3.new(4.5, 0, -3), model)
    buildLamp(p + Vector3.new(-4.5, 0, 3.5), model)

    model.Parent = parent
end

---------------------------------------------------------------------------
-- Spawn point
---------------------------------------------------------------------------
local function configureSpawnLocation()
    local spawnLoc = Workspace:FindFirstChildOfClass("SpawnLocation")
    if not spawnLoc then
        spawnLoc = Instance.new("SpawnLocation")
        spawnLoc.Parent = Workspace
    end
    assert(spawnLoc)
    for _, child in spawnLoc:GetChildren() do
        if child:IsA("Decal") or child:IsA("Texture") then
            child:Destroy()
        end
    end
    spawnLoc.Anchored = true
    spawnLoc.Size = Vector3.new(6, 0.2, 4)
    spawnLoc.CFrame = CFrame.new(VILLAGE.SpawnPosition.X, 0.2, VILLAGE.SpawnPosition.Z)
    spawnLoc.Transparency = 1
    spawnLoc.CanCollide = false
    spawnLoc.CanQuery = false
    spawnLoc.CanTouch = false
    spawnLoc.Neutral = true
    spawnLoc.Duration = 0
end

function VillageService.init()
    local existing = Workspace:FindFirstChild("BloxcubeVillage")
    if existing then
        existing:Destroy()
    end

    local folder = Instance.new("Folder")
    folder.Name = "BloxcubeVillage"
    folder.Parent = Workspace

    buildPlaza(folder)
    buildFountain(folder)
    buildPalisade(folder)

    -- Cottages (door faces the plaza / main roads)
    buildHouse(Vector3.new(-31, 0, -36), Vector3.new(0, 0, 1), 1, folder)
    buildHouse(Vector3.new(31, 0, -36), Vector3.new(0, 0, 1), 2, folder)
    buildHouse(Vector3.new(-31, 0, -8), Vector3.new(1, 0, 0), 3, folder)
    buildHouse(Vector3.new(31, 0, -8), Vector3.new(-1, 0, 0), 4, folder)
    buildHouse(Vector3.new(-31, 0, 15), Vector3.new(1, 0, 0), 5, folder)
    buildHouse(Vector3.new(31, 0, 15), Vector3.new(-1, 0, 0), 6, folder)

    -- Market stalls beside the plaza
    buildMarketStall(Vector3.new(-21, 0, -14), Vector3.new(0, 0, 1), Color3.fromRGB(206, 84, 72), folder)
    buildMarketStall(Vector3.new(21, 0, -14), Vector3.new(0, 0, 1), Color3.fromRGB(72, 140, 196), folder)

    -- Street lamps around the plaza & along the roads
    for _, lampPos in
        {
            Vector3.new(-13.5, 0, -13.5),
            Vector3.new(13.5, 0, -13.5),
            Vector3.new(-13.5, 0, 13.5),
            Vector3.new(13.5, 0, 13.5),
            Vector3.new(-4.5, 0, 21),
            Vector3.new(4.5, 0, 21),
            Vector3.new(-28, 0, 1),
            Vector3.new(28, 0, 1),
            Vector3.new(-4, 0, -32),
            Vector3.new(4, 0, -32),
        }
    do
        buildLamp(lampPos, folder)
    end

    -- Flower beds, hay & greenery
    buildFlowerBed(Vector3.new(-9, 0, 19.5), Vector3.new(5, 0.5, 2.5), folder, 1)
    buildFlowerBed(Vector3.new(9, 0, 19.5), Vector3.new(5, 0.5, 2.5), folder, 2)
    buildFlowerBed(Vector3.new(-20, 0, 10), Vector3.new(3, 0.5, 5), folder, 3)
    buildFlowerBed(Vector3.new(20, 0, 10), Vector3.new(3, 0.5, 5), folder, 4)
    buildFlowerBed(Vector3.new(-24, 0, -42.5), Vector3.new(6, 0.5, 2), folder, 5)
    buildFlowerBed(Vector3.new(24, 0, -42.5), Vector3.new(6, 0.5, 2), folder, 6)
    buildHayBale(Vector3.new(-39, 0, 21), folder)
    buildHayBale(Vector3.new(-36.5, 0, 22.5), folder)
    buildHayBale(Vector3.new(39, 0, -26), folder)
    buildTree(Vector3.new(-16, 0, -40), 1, folder)
    buildTree(Vector3.new(16, 0, -40), 1.05, folder)
    buildTree(Vector3.new(-40, 0, -28), 0.9, folder)
    buildTree(Vector3.new(40, 0, -30), 0.85, folder)

    buildCreationStage(folder)
    configureSpawnLocation()
end

return table.freeze(VillageService)
