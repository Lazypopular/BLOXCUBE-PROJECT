--!strict
-- MobService: Spawns & Manages Voxel Training Dummies and Cube World Style Voxel Slimes (Server-Side)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local CombatConfig = require(ReplicatedStorage.configs.CombatConfig)
local Network = require(ReplicatedStorage.network)
local LootService = require(script.Parent.LootService)
local PlayerService = require(script.Parent.PlayerService)

export type MobEntity = {
    Id: number,
    Spec: any,
    Model: Model,
    RootPart: Part,
    HP: number,
    MaxHP: number,
    IsDead: boolean,
    SpawnPosition: Vector3,
    LastHopTime: number,
    LastAttackTime: number,
    HitTiltTime: number,
    HPFillFrame: Frame,
    HPTextLabel: TextLabel,
}

local MobService = {}

local activeMobs: { MobEntity } = {}
local nextMobId = 1

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

local function createPart(
    name: string,
    size: Vector3,
    color: Color3,
    cframe: CFrame,
    parent: Instance,
    transparency: number?
): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Color = color
    p.CFrame = cframe
    p.Transparency = transparency or 0
    p.Material = Enum.Material.SmoothPlastic
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Anchored = true
    p.CanCollide = false
    p.CanQuery = false
    p.CanTouch = false
    p.CastShadow = true
    p.Parent = parent
    return p
end

local function createOverheadBillboard(adornee: BasePart, nameText: string, maxHp: number): (Frame, TextLabel)
    local bb = Instance.new("BillboardGui")
    bb.Name = "MobBillboard"
    bb.Adornee = adornee
    bb.Size = UDim2.new(0, 140, 0, 42)
    bb.StudsOffset = Vector3.new(0, 3.6, 0)
    bb.AlwaysOnTop = false
    bb.MaxDistance = 75
    bb.Parent = adornee

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 18)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 12
    title.TextColor3 = Color3.fromRGB(255, 240, 185)
    title.TextStrokeTransparency = 0.25
    title.Text = nameText
    title.Parent = bb

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, -10, 0, 14)
    barBg.Position = UDim2.new(0, 5, 0, 20)
    barBg.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
    barBg.BorderSizePixel = 0
    barBg.Parent = bb

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = barBg

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(68, 76, 98)
    stroke.Thickness = 1.5
    stroke.Parent = barBg

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(1, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(235, 68, 68)
    fill.BorderSizePixel = 0
    fill.Parent = barBg

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = fill

    local hpLabel = Instance.new("TextLabel")
    hpLabel.Size = UDim2.new(1, 0, 1, 0)
    hpLabel.BackgroundTransparency = 1
    hpLabel.Font = Enum.Font.GothamBold
    hpLabel.TextSize = 10
    hpLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    hpLabel.TextStrokeTransparency = 0.3
    hpLabel.Text = string.format("%d / %d", maxHp, maxHp)
    hpLabel.Parent = barBg

    return fill, hpLabel
end

local function buildMobVisuals(spec: any, groundPos: Vector3, parentFolder: Folder): (Model, Part, Frame, TextLabel)
    local model = Instance.new("Model")
    model.Name = spec.Name

    local scale = spec.SizeScale or 1.0
    local rootCFrame = CFrame.new(groundPos + Vector3.new(0, 2.0 * scale, 0))
    local rootPart =
        createPart("RootPart", Vector3.new(2.4 * scale, 2.8 * scale, 2.4 * scale), spec.Color, rootCFrame, model, 1)
    rootPart.CanCollide = true
    model.PrimaryPart = rootPart

    if spec.MobType == "TrainingDummy" then
        -- Voxel Wooden Training Dummy
        local woodPost = Color3.fromRGB(122, 82, 46)
        local strawBody = spec.Color
        local targetRed = Color3.fromRGB(208, 58, 58)
        createPart("BaseStand", Vector3.new(2.6, 0.35, 2.6), woodPost, rootCFrame * CFrame.new(0, -1.8, 0), model)
        createPart("CenterPole", Vector3.new(0.65, 3.8, 0.65), woodPost, rootCFrame * CFrame.new(0, -0.1, 0), model)
        createPart("StrawTorso", Vector3.new(1.85, 2.0, 1.35), strawBody, rootCFrame * CFrame.new(0, 0.15, 0), model)
        createPart("CrossArm", Vector3.new(3.4, 0.52, 0.52), woodPost, rootCFrame * CFrame.new(0, 0.65, 0), model)
        createPart("DummyHead", Vector3.new(1.65, 1.65, 1.65), strawBody, rootCFrame * CFrame.new(0, 1.95, 0), model)
        createPart("Bullseye", Vector3.new(0.75, 0.75, 0.12), targetRed, rootCFrame * CFrame.new(0, 0.2, -0.7), model)
    else
        -- Cube World Style Translucent Voxel Slime (Outer Gel + Inner Core + Voxel Eyes)
        local outerSize = Vector3.new(2.7 * scale, 2.4 * scale, 2.7 * scale)
        local coreSize = Vector3.new(1.45 * scale, 1.35 * scale, 1.45 * scale)
        createPart("SlimeOuter", outerSize, spec.Color, rootCFrame, model, 0.25)
        createPart("SlimeCore", coreSize, spec.Color:Lerp(Color3.fromRGB(255, 255, 255), 0.35), rootCFrame, model, 0)
        createPart(
            "LeftEye",
            Vector3.new(0.38 * scale, 0.44 * scale, 0.16 * scale),
            spec.EyeColor,
            rootCFrame * CFrame.new(-0.52 * scale, 0.18 * scale, -1.36 * scale),
            model
        )
        createPart(
            "RightEye",
            Vector3.new(0.38 * scale, 0.44 * scale, 0.16 * scale),
            spec.EyeColor,
            rootCFrame * CFrame.new(0.52 * scale, 0.18 * scale, -1.36 * scale),
            model
        )

        if spec.IsBoss then
            -- Royal Gold Voxel Crown & Ruby Gem for King Gelatus
            local crownGold = Color3.fromRGB(255, 206, 58)
            local rubyRed = Color3.fromRGB(245, 42, 68)
            createPart(
                "BossCrownBase",
                Vector3.new(1.5 * scale, 0.35 * scale, 1.5 * scale),
                crownGold,
                rootCFrame * CFrame.new(0, 1.38 * scale, 0),
                model
            )
            createPart(
                "BossCrownGem",
                Vector3.new(0.42 * scale, 0.42 * scale, 0.2 * scale),
                rubyRed,
                rootCFrame * CFrame.new(0, 1.42 * scale, -0.78 * scale),
                model
            )
        end
    end

    -- Record relative offsets to RootPart so moving RootPart moves all child parts cleanly
    for _, part in model:GetChildren() do
        if part:IsA("BasePart") and part ~= rootPart then
            local relOffset = rootPart.CFrame:ToObjectSpace(part.CFrame)
            part:SetAttribute("RelOffset", relOffset)
        end
    end

    local hpFill, hpText = createOverheadBillboard(rootPart, spec.Name, spec.MaxHP)
    model.Parent = parentFolder
    return model, rootPart, hpFill, hpText
end

local function updateModelCFrame(mob: MobEntity, newRootCFrame: CFrame)
    mob.RootPart.CFrame = newRootCFrame
    for _, part in mob.Model:GetChildren() do
        if part:IsA("BasePart") and part ~= mob.RootPart then
            local relOffset = part:GetAttribute("RelOffset") :: CFrame?
            if relOffset then
                part.CFrame = newRootCFrame * relOffset
            end
        end
    end
end

local function setMobVisible(mob: MobEntity, visible: boolean)
    for _, part in mob.Model:GetChildren() do
        if part:IsA("BasePart") and part ~= mob.RootPart then
            if visible then
                part.Transparency = if part.Name == "SlimeOuter" then 0.25 else 0
            else
                part.Transparency = 1
            end
        end
    end
    local bb = mob.RootPart:FindFirstChild("MobBillboard") :: BillboardGui?
    if bb then
        bb.Enabled = visible
    end
end

local function updateMobHPBar(mob: MobEntity)
    local ratio = math.clamp(mob.HP / math.max(1, mob.MaxHP), 0, 1)
    mob.HPFillFrame.Size = UDim2.new(ratio, 0, 1, 0)
    mob.HPTextLabel.Text = string.format("%d / %d", math.floor(mob.HP + 0.5), mob.MaxHP)
end

function MobService.applyDamage(mob: MobEntity, attacker: Player, amount: number, isCrit: boolean, isSpecial: boolean)
    if mob.IsDead or amount <= 0 then
        return
    end

    mob.HP = math.max(0, mob.HP - amount)
    mob.HitTiltTime = os.clock()
    updateMobHPBar(mob)

    -- Knockback for Slimes
    if mob.Spec.MobType ~= "TrainingDummy" and attacker.Character then
        local attackerRoot = attacker.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
        if attackerRoot then
            local away = mob.RootPart.Position - attackerRoot.Position
            local flatAway = Vector3.new(away.X, 0, away.Z)
            if flatAway.Magnitude > 0.01 then
                local kbDist = if isSpecial then 3.5 else 1.6
                local newPos = mob.RootPart.Position + flatAway.Unit * kbDist
                updateModelCFrame(mob, CFrame.new(newPos) * mob.RootPart.CFrame.Rotation)
            end
        end
    end

    Network.getEvent("DamageNumber")
        :FireAllClients(mob.RootPart.Position + Vector3.new(0, 2.4, 0), amount, isCrit, isSpecial, nil)

    PlayerService.recordQuestProgress(attacker, "DamageDealt", amount)

    if mob.HP <= 0 then
        mob.IsDead = true
        setMobVisible(mob, false)

        PlayerService.addExpAndGold(attacker, mob.Spec.ExpReward, mob.Spec.GoldReward)
        PlayerService.recordQuestProgress(attacker, "MobsDefeated", 1)

        if mob.Spec.MobType ~= "TrainingDummy" then
            LootService.spawnMobLoot(mob.RootPart.Position, attacker, mob.Spec.IsBoss == true)
        end

        task.delay(mob.Spec.RespawnTime, function()
            mob.HP = mob.MaxHP
            mob.IsDead = false
            updateMobHPBar(mob)
            local scale = mob.Spec.SizeScale or 1.0
            updateModelCFrame(mob, CFrame.new(mob.SpawnPosition + Vector3.new(0, 2.0 * scale, 0)))
            setMobVisible(mob, true)
        end)
    end
end

function MobService.getTargetsInArc(
    origin: Vector3,
    forwardDir: Vector3,
    maxRange: number,
    radius: number,
    isFullCircle: boolean
): { MobEntity }
    local hits: { MobEntity } = {}
    local flatForward = Vector3.new(forwardDir.X, 0, forwardDir.Z)
    if flatForward.Magnitude > 0.001 then
        flatForward = flatForward.Unit
    else
        flatForward = Vector3.new(0, 0, -1)
    end

    for _, mob in activeMobs do
        if not mob.IsDead then
            local toMob = mob.RootPart.Position - origin
            local flatToMob = Vector3.new(toMob.X, 0, toMob.Z)
            local dist = flatToMob.Magnitude

            if dist <= maxRange then
                if isFullCircle or dist <= radius * 0.75 then
                    table.insert(hits, mob)
                else
                    local dot = flatForward:Dot(flatToMob.Unit)
                    if dot >= 0.15 then
                        table.insert(hits, mob)
                    end
                end
            end
        end
    end

    return hits
end

function MobService.getTargetsAlongRay(
    origin: Vector3,
    direction: Vector3,
    maxRange: number,
    hitRadius: number
): { MobEntity }
    local hits: { MobEntity } = {}
    local unitDir = if direction.Magnitude > 0.001 then direction.Unit else Vector3.new(0, 0, -1)

    for _, mob in activeMobs do
        if not mob.IsDead then
            local toMob = mob.RootPart.Position - origin
            local proj = toMob:Dot(unitDir)
            if proj >= -2.0 and proj <= maxRange then
                local closestPoint = origin + unitDir * math.clamp(proj, 0, maxRange)
                local perpDist = (mob.RootPart.Position - closestPoint).Magnitude
                if perpDist <= hitRadius then
                    table.insert(hits, mob)
                end
            end
        end
    end

    return hits
end

function MobService.init()
    local existing = Workspace:FindFirstChild("BloxcubeEntities")
    if existing then
        existing:Destroy()
    end

    local folder = Instance.new("Folder")
    folder.Name = "BloxcubeEntities"
    folder.Parent = Workspace

    for _, spec in CombatConfig.MobSpawns do
        local groundPos = getGroundPosition(spec.SpawnOffset)
        local model, rootPart, hpFill, hpText = buildMobVisuals(spec, groundPos, folder)

        local entity: MobEntity = {
            Id = nextMobId,
            Spec = spec,
            Model = model,
            RootPart = rootPart,
            HP = spec.MaxHP,
            MaxHP = spec.MaxHP,
            IsDead = false,
            SpawnPosition = groundPos,
            LastHopTime = os.clock() + (nextMobId * 0.35),
            LastAttackTime = 0,
            HitTiltTime = -10,
            HPFillFrame = hpFill,
            HPTextLabel = hpText,
        }
        nextMobId += 1
        table.insert(activeMobs, entity)
    end

    -- Server AI & Procedural Animation Loop for Mobs
    RunService.Heartbeat:Connect(function(dt: number)
        local now = os.clock()
        for _, mob in activeMobs do
            if mob.IsDead then
                continue
            end

            local scale = mob.Spec.SizeScale or 1.0
            local baseY = mob.SpawnPosition.Y + 2.0 * scale

            if mob.Spec.MobType == "TrainingDummy" then
                -- Rock back and forth when struck
                local hitAge = now - mob.HitTiltTime
                if hitAge < 0.45 then
                    local sway = math.sin(hitAge * 28) * math.rad(18) * (1 - hitAge / 0.45)
                    local baseCF = CFrame.new(mob.SpawnPosition.X, baseY, mob.SpawnPosition.Z)
                        * CFrame.Angles(sway, 0, sway * 0.5)
                    updateModelCFrame(mob, baseCF)
                end
                continue
            end

            -- Slime AI: Find nearest living player within AggroRange
            local nearestPlayer: Player? = nil
            local nearestRoot: BasePart? = nil
            local nearestDist = mob.Spec.AggroRange

            for _, player in Players:GetPlayers() do
                local char = player.Character
                local root = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
                local hum = if char then char:FindFirstChildOfClass("Humanoid") else nil
                if root and hum and hum.Health > 0 then
                    local dist = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(
                        mob.RootPart.Position.X,
                        0,
                        mob.RootPart.Position.Z
                    )).Magnitude
                    if dist < nearestDist then
                        nearestDist = dist
                        nearestPlayer = player
                        nearestRoot = root
                    end
                end
            end

            local currentPos = Vector3.new(mob.RootPart.Position.X, baseY, mob.RootPart.Position.Z)
            local hopWave = math.abs(math.sin((now - mob.LastHopTime) * 5.2))
            local hopOffset = hopWave * 1.15 * scale

            if nearestPlayer and nearestRoot then
                local toTarget =
                    Vector3.new(nearestRoot.Position.X - currentPos.X, 0, nearestRoot.Position.Z - currentPos.Z)
                local dist = toTarget.Magnitude
                local lookDir = if dist > 0.05 then toTarget.Unit else Vector3.new(0, 0, -1)

                if dist > mob.Spec.AttackRange * 0.75 then
                    local step = lookDir * (mob.Spec.WalkSpeed * dt)
                    currentPos = currentPos + step
                end

                if dist <= mob.Spec.AttackRange and now - mob.LastAttackTime >= 1.45 then
                    mob.LastAttackTime = now
                    PlayerService.damagePlayer(nearestPlayer, mob.Spec.Damage)
                end

                local cf = CFrame.lookAt(
                    currentPos + Vector3.new(0, hopOffset, 0),
                    currentPos + Vector3.new(0, hopOffset, 0) + lookDir
                )
                updateModelCFrame(mob, cf)
            else
                -- Return slowly toward SpawnPosition & idle bounce
                local toSpawn = Vector3.new(mob.SpawnPosition.X - currentPos.X, 0, mob.SpawnPosition.Z - currentPos.Z)
                if toSpawn.Magnitude > 1.0 then
                    local dir = toSpawn.Unit
                    currentPos = currentPos + dir * (mob.Spec.WalkSpeed * 0.6 * dt)
                    local cf = CFrame.lookAt(
                        currentPos + Vector3.new(0, hopOffset * 0.5, 0),
                        currentPos + Vector3.new(0, hopOffset * 0.5, 0) + dir
                    )
                    updateModelCFrame(mob, cf)
                else
                    local idleBob = math.abs(math.sin((now - mob.LastHopTime) * 3.0)) * 0.45 * scale
                    updateModelCFrame(mob, CFrame.new(currentPos + Vector3.new(0, idleBob, 0)))
                end
            end
        end
    end)
end

return table.freeze(MobService)
