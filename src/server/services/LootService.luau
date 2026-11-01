--!strict
-- LootService: Spawns & Manages 3D Voxel Loot Drops, Spirit Cubes & Rarity Equipment (Server-Side)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ItemConfig = require(ReplicatedStorage.configs.ItemConfig)
local Network = require(ReplicatedStorage.network)
local PlayerService = require(script.Parent.PlayerService)

type EquipmentItem = ItemConfig.EquipmentItem

type ActiveLootDrop = {
    Id: number,
    Model: Model,
    RootPart: Part,
    OriginPos: Vector3,
    SpawnTime: number,
    DropKind: string, -- "Equipment" | "SpiritCube" | "Potion"
    Equipment: EquipmentItem?,
    CubeType: string?,
    Collected: boolean,
}

local LootService = {}

local activeDrops: { ActiveLootDrop } = {}
local nextDropId = 1
local nextEquipmentUid = 100

local function rollRarity(isBoss: boolean): ItemConfig.RarityInfo
    if isBoss then
        local roll = math.random(1, 100)
        if roll <= 25 then
            return ItemConfig.Rarities.Legendary
        elseif roll <= 60 then
            return ItemConfig.Rarities.Epic
        else
            return ItemConfig.Rarities.Rare
        end
    end

    local totalWeight = 0
    for _, key in ItemConfig.RarityOrder do
        totalWeight += ItemConfig.Rarities[key].Weight
    end

    local pick = math.random(1, totalWeight)
    local accum = 0
    for _, key in ItemConfig.RarityOrder do
        local r = ItemConfig.Rarities[key]
        accum += r.Weight
        if pick <= accum then
            return r
        end
    end
    return ItemConfig.Rarities.Common
end

local function generateEquipment(killerClass: string, isBoss: boolean): EquipmentItem
    local rarity = rollRarity(isBoss)

    -- Prefer templates matching the player's current class or "Any"
    local candidates = {}
    for _, tpl in ItemConfig.WeaponTemplates do
        if tpl.ClassReq == killerClass or tpl.ClassReq == "Any" then
            table.insert(candidates, tpl)
        end
    end
    if #candidates == 0 then
        candidates = ItemConfig.WeaponTemplates
    end

    local chosen = candidates[math.random(1, #candidates)]
    nextEquipmentUid += 1

    local mult = rarity.StatMultiplier
    local bonusATK = math.max(2, math.floor(chosen.BaseATK * mult + 0.5))
    local bonusHP = math.max(5, math.floor(chosen.BaseHP * mult + 0.5))
    local bonusCrit = math.floor(chosen.BaseCrit * mult * 100) / 100

    return {
        Uid = nextEquipmentUid,
        TemplateId = chosen.Id,
        Name = chosen.Name,
        ClassReq = chosen.ClassReq,
        Rarity = rarity.Key,
        Stars = rarity.Stars,
        BonusATK = bonusATK,
        BonusHP = bonusHP,
        BonusCrit = bonusCrit,
    }
end

local function createVoxelPart(
    name: string,
    size: Vector3,
    color: Color3,
    cframe: CFrame,
    parent: Instance,
    material: Enum.Material?
): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Color = color
    part.CFrame = cframe
    part.Material = material or Enum.Material.SmoothPlastic
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.CastShadow = true
    part.Parent = parent
    return part
end

local function createDropVisual(
    pos: Vector3,
    titleText: string,
    subText: string,
    accentColor: Color3,
    dropKind: string,
    parentFolder: Folder
): (Model, Part)
    local model = Instance.new("Model")
    model.Name = "VoxelLootDrop"

    local baseCF = CFrame.new(pos + Vector3.new(0, 1.5, 0))
    local root = createVoxelPart("RootPart", Vector3.new(1.4, 1.4, 1.4), accentColor, baseCF, model)
    root.Transparency = 1
    model.PrimaryPart = root

    if dropKind == "Equipment" then
        -- Voxel Treasure Chest + Glowing Rarity Trim
        local woodColor = Color3.fromRGB(132, 82, 42)
        createVoxelPart("ChestBody", Vector3.new(1.5, 1.0, 1.15), woodColor, baseCF, model)
        createVoxelPart(
            "ChestTrim",
            Vector3.new(1.56, 0.24, 1.2),
            accentColor,
            baseCF * CFrame.new(0, 0.18, 0),
            model,
            Enum.Material.Neon
        )
        createVoxelPart(
            "ChestLatch",
            Vector3.new(0.32, 0.42, 0.16),
            Color3.fromRGB(255, 215, 75),
            baseCF * CFrame.new(0, 0.12, -0.58),
            model,
            Enum.Material.Metal
        )
    elseif dropKind == "SpiritCube" then
        -- Glowing Floating Spirit Cube with Core
        createVoxelPart("CubeCore", Vector3.new(0.95, 0.95, 0.95), accentColor, baseCF, model, Enum.Material.Neon)
        local shell = createVoxelPart(
            "CubeShell",
            Vector3.new(1.3, 1.3, 1.3),
            accentColor:Lerp(Color3.fromRGB(255, 255, 255), 0.35),
            baseCF,
            model
        )
        shell.Transparency = 0.45
    else
        -- Heartflower Potion Flask
        createVoxelPart(
            "FlaskBody",
            Vector3.new(0.85, 0.95, 0.85),
            Color3.fromRGB(235, 64, 92),
            baseCF,
            model,
            Enum.Material.Neon
        )
        createVoxelPart(
            "FlaskNeck",
            Vector3.new(0.42, 0.38, 0.42),
            Color3.fromRGB(218, 226, 238),
            baseCF * CFrame.new(0, 0.62, 0),
            model
        )
    end

    for _, child in model:GetChildren() do
        if child:IsA("BasePart") and child ~= root then
            child:SetAttribute("RelOffset", root.CFrame:ToObjectSpace(child.CFrame))
        end
    end

    -- Overhead Loot Label
    local bb = Instance.new("BillboardGui")
    bb.Name = "LootBillboard"
    bb.Adornee = root
    bb.Size = UDim2.new(0, 190, 0, 40)
    bb.StudsOffset = Vector3.new(0, 2.2, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 55
    bb.Parent = root

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 20)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 12
    title.TextColor3 = accentColor
    title.TextStrokeTransparency = 0.15
    title.Text = titleText
    title.Parent = bb

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, 0, 0, 16)
    sub.Position = UDim2.new(0, 0, 0, 19)
    sub.BackgroundTransparency = 1
    sub.Font = Enum.Font.GothamBold
    sub.TextSize = 10
    sub.TextColor3 = Color3.fromRGB(235, 240, 252)
    sub.TextStrokeTransparency = 0.25
    sub.Text = subText
    sub.Parent = bb

    model.Parent = parentFolder
    return model, root
end

local function updateDropCFrame(drop: ActiveLootDrop, cf: CFrame)
    drop.RootPart.CFrame = cf
    for _, child in drop.Model:GetChildren() do
        if child:IsA("BasePart") and child ~= drop.RootPart then
            local rel = child:GetAttribute("RelOffset") :: CFrame?
            if rel then
                child.CFrame = cf * rel
            end
        end
    end
end

local function collectDrop(drop: ActiveLootDrop, player: Player)
    if drop.Collected then
        return
    end
    drop.Collected = true

    if drop.DropKind == "Equipment" and drop.Equipment then
        local item = drop.Equipment
        PlayerService.addLootItem(player, item)
        local rarityInfo = ItemConfig.Rarities[item.Rarity] or ItemConfig.Rarities.Common
        Network.getEvent("QuestNotification"):FireClient(
            player,
            string.format("LOOTED: %s %s", item.Stars, item.Name),
            string.format("+%d ATK  |  +%d MaxHP  (Press [I] to Equip & Customize)", item.BonusATK, item.BonusHP),
            rarityInfo.Color
        )
    elseif drop.DropKind == "SpiritCube" and drop.CubeType then
        local cubeSpec = ItemConfig.SpiritCubes[drop.CubeType] or ItemConfig.SpiritCubes.FireCube
        PlayerService.addSpiritCube(player, drop.CubeType, 1)
        Network.getEvent("QuestNotification"):FireClient(
            player,
            "OBTAINED: " .. string.upper(cubeSpec.Name),
            string.format("%s — Press [I] or visit the Town Anvil to forge onto your weapon!", cubeSpec.Description),
            cubeSpec.Color
        )
    elseif drop.DropKind == "Potion" then
        PlayerService.addPotion(player, 1)
        Network.getEvent("DamageNumber")
            :FireClient(player, drop.OriginPos + Vector3.new(0, 2.2, 0), 0, false, false, "+1 POTION")
    end

    if drop.Model.Parent then
        drop.Model:Destroy()
    end
end

function LootService.spawnMobLoot(mobPosition: Vector3, killer: Player, isBoss: boolean)
    local folder = Workspace:FindFirstChild("BloxcubeLoot") :: Folder?
    if not folder then
        local f = Instance.new("Folder")
        f.Name = "BloxcubeLoot"
        f.Parent = Workspace
        folder = f
    end
    local targetFolder = folder :: Folder

    local session = PlayerService.getSession(killer)
    local killerClass = if session then session.JobClass else "Novice"
    local groundPos = Vector3.new(mobPosition.X, 0, mobPosition.Z)

    -- 1. Equipment Drop (100% on Boss, 55% on normal Slimes)
    if isBoss or math.random() <= 0.55 then
        local item = generateEquipment(killerClass, isBoss)
        local rarityInfo = ItemConfig.Rarities[item.Rarity] or ItemConfig.Rarities.Common
        local dropPos = groundPos + Vector3.new(math.random(-20, 20) / 10, 0, math.random(-20, 20) / 10)
        local model, root = createDropVisual(
            dropPos,
            string.format("%s %s", item.Stars, item.Name),
            string.format("[%s] +%d ATK", item.Rarity, item.BonusATK),
            rarityInfo.Color,
            "Equipment",
            targetFolder
        )

        table.insert(activeDrops, {
            Id = nextDropId,
            Model = model,
            RootPart = root,
            OriginPos = dropPos,
            SpawnTime = os.clock(),
            DropKind = "Equipment",
            Equipment = item,
            CubeType = nil,
            Collected = false,
        })
        nextDropId += 1
    end

    -- 2. Spirit Cube Drop (100% on Boss, 65% on normal Slimes)
    local cubeDropCount = if isBoss then 2 else (if math.random() <= 0.65 then 1 else 0)
    for i = 1, cubeDropCount do
        local cubeKey = ItemConfig.SpiritCubeOrder[math.random(1, #ItemConfig.SpiritCubeOrder)]
        local cubeSpec = ItemConfig.SpiritCubes[cubeKey]
        local angle = (i / math.max(1, cubeDropCount)) * math.pi * 2
        local dropPos = groundPos + Vector3.new(math.cos(angle) * 2.8, 0, math.sin(angle) * 2.8)
        local model, root = createDropVisual(
            dropPos,
            "❖ " .. cubeSpec.Name,
            cubeSpec.Description,
            cubeSpec.Color,
            "SpiritCube",
            targetFolder
        )

        table.insert(activeDrops, {
            Id = nextDropId,
            Model = model,
            RootPart = root,
            OriginPos = dropPos,
            SpawnTime = os.clock(),
            DropKind = "SpiritCube",
            Equipment = nil,
            CubeType = cubeKey,
            Collected = false,
        })
        nextDropId += 1
    end

    -- 3. Heartflower Potion Drop (45% chance)
    if isBoss or math.random() <= 0.45 then
        local dropPos = groundPos + Vector3.new(0, 0, 2.4)
        local model, root = createDropVisual(
            dropPos,
            "♥ Heartflower Potion",
            "Restores 45% HP [Key 1]",
            Color3.fromRGB(255, 92, 118),
            "Potion",
            targetFolder
        )

        table.insert(activeDrops, {
            Id = nextDropId,
            Model = model,
            RootPart = root,
            OriginPos = dropPos,
            SpawnTime = os.clock(),
            DropKind = "Potion",
            Equipment = nil,
            CubeType = nil,
            Collected = false,
        })
        nextDropId += 1
    end
end

function LootService.init()
    local existing = Workspace:FindFirstChild("BloxcubeLoot")
    if existing then
        existing:Destroy()
    end

    local folder = Instance.new("Folder")
    folder.Name = "BloxcubeLoot"
    folder.Parent = Workspace

    RunService.Heartbeat:Connect(function()
        local now = os.clock()
        for i = #activeDrops, 1, -1 do
            local drop = activeDrops[i]
            if drop.Collected or not drop.Model.Parent then
                table.remove(activeDrops, i)
                continue
            end

            local age = now - drop.SpawnTime
            if age > 60 then
                drop.Model:Destroy()
                table.remove(activeDrops, i)
                continue
            end

            -- Spin & bob animation
            local bob = math.sin(age * 3.5) * 0.35
            local cf = CFrame.new(drop.OriginPos + Vector3.new(0, 1.55 + bob, 0)) * CFrame.Angles(0, age * 2.2, 0)
            updateDropCFrame(drop, cf)

            -- Auto-pickup when a living player walks within 5.5 studs (after 0.45s spawn grace)
            if age >= 0.45 then
                for _, player in Players:GetPlayers() do
                    local char = player.Character
                    local root = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
                    local hum = if char then char:FindFirstChildOfClass("Humanoid") else nil
                    if root and hum and hum.Health > 0 then
                        local dist = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(
                            drop.OriginPos.X,
                            0,
                            drop.OriginPos.Z
                        )).Magnitude
                        if dist <= 5.5 then
                            collectDrop(drop, player)
                            break
                        end
                    end
                end
            end
        end
    end)
end

return table.freeze(LootService)
