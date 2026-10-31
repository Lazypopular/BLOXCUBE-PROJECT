--!strict
-- CombatController: Client Combat Input (LMB Combo / RMB Special), 3D Voxel VFX & Floating Damage Numbers

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local CombatConfig = require(ReplicatedStorage.configs.CombatConfig)
local Network = require(ReplicatedStorage.network)
local CameraController = require(script.Parent.CameraController)

local localPlayer = Players.LocalPlayer

local CombatController = {}

local lastClientAttackTime = 0

local function createVFXPart(size: Vector3, color: Color3, cframe: CFrame, material: Enum.Material?): Part
    local p = Instance.new("Part")
    p.Name = "CombatVoxelVFX"
    p.Size = size
    p.Color = color
    p.Material = material or Enum.Material.Neon
    p.CFrame = cframe
    p.Anchored = true
    p.CanCollide = false
    p.CanQuery = false
    p.CanTouch = false
    p.CastShadow = false
    p.Parent = Workspace
    return p
end

local function spawnImpactSparks(position: Vector3, color: Color3, count: number)
    for i = 1, count do
        local angle = (i / count) * math.pi * 2
        local spark =
            createVFXPart(Vector3.new(0.42, 0.42, 0.42), color, CFrame.new(position) * CFrame.Angles(i * 0.7, angle, 0))

        local offset = Vector3.new(math.cos(angle) * 2.8, 1.4 + (i % 2) * 0.8, math.sin(angle) * 2.8)
        local tween = TweenService:Create(spark, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            CFrame = CFrame.new(position + offset) * CFrame.Angles(angle * 2, i, 1.5),
            Size = Vector3.new(0.05, 0.05, 0.05),
            Transparency = 1,
        })
        tween:Play()
        Debris:AddItem(spark, 0.32)
    end
end

local function spawnMeleeSlashVFX(
    origin: Vector3,
    direction: Vector3,
    color: Color3,
    isSpecial: boolean,
    comboStep: number
)
    local flatDir = Vector3.new(direction.X, 0, direction.Z)
    local lookDir = if flatDir.Magnitude > 0.01 then flatDir.Unit else Vector3.new(0, 0, -1)
    local baseCF = CFrame.lookAt(origin, origin + lookDir)

    local segmentCount = if isSpecial then 10 else 6
    local arcAngle = if isSpecial then math.pi * 1.8 else math.rad(115)
    local radius = if isSpecial then 6.2 else 4.6
    local flipSign = if comboStep == 2 then -1 else 1

    for i = 1, segmentCount do
        local alpha = (i - 1) / math.max(1, segmentCount - 1) - 0.5
        local theta = alpha * arcAngle * flipSign
        local segCF = baseCF * CFrame.Angles(0, theta, 0) * CFrame.new(0, 0.2, -radius)
        local blockSize = if isSpecial then Vector3.new(1.1, 0.35, 1.4) else Vector3.new(0.75, 0.24, 1.05)

        local vfx = createVFXPart(blockSize, color, segCF)
        local tween = TweenService:Create(vfx, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            CFrame = segCF * CFrame.new(0, 0, -1.2),
            Size = Vector3.new(0.1, 0.05, 0.2),
            Transparency = 1,
        })
        tween:Play()
        Debris:AddItem(vfx, 0.25)
    end
end

local function spawnProjectileVFX(
    jobClass: string,
    origin: Vector3,
    direction: Vector3,
    color: Color3,
    isSpecial: boolean
)
    local unitDir = if direction.Magnitude > 0.01 then direction.Unit else Vector3.new(0, 0, -1)
    local startPos = origin + Vector3.new(0, 0.5, 0) + unitDir * 2.0
    local travelDist = if isSpecial then 44 else 38
    local endPos = startPos + unitDir * travelDist

    local projectileSize = if jobClass == "Ranger" then Vector3.new(0.22, 0.22, 2.2) else Vector3.new(0.75, 0.75, 0.75)

    local count = if isSpecial and jobClass == "Ranger" then 3 else 1
    for i = 1, count do
        local spreadAngle = if count == 1 then 0 else (i - 2) * math.rad(10)
        local shotCF = CFrame.lookAt(startPos, endPos) * CFrame.Angles(0, spreadAngle, 0)
        local targetPos = (shotCF * CFrame.new(0, 0, -travelDist)).Position

        local proj = createVFXPart(projectileSize, color, shotCF)
        local tween = TweenService:Create(proj, TweenInfo.new(0.24, Enum.EasingStyle.Linear), {
            CFrame = CFrame.lookAt(targetPos, targetPos + shotCF.LookVector),
        })
        tween:Play()
        Debris:AddItem(proj, 0.26)
    end

    if isSpecial and jobClass == "Mage" then
        task.delay(0.18, function()
            local burstCenter = startPos + unitDir * 18
            spawnImpactSparks(burstCenter, color, 10)
        end)
    end
end

local function spawnFloatingDamageNumber(
    worldPosition: Vector3,
    amount: number,
    isCrit: boolean,
    isSpecial: boolean,
    textOverride: string?
)
    local anchor = Instance.new("Part")
    anchor.Name = "DamageNumberAnchor"
    anchor.Size = Vector3.new(0.2, 0.2, 0.2)
    anchor.Transparency = 1
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.CanQuery = false
    anchor.CanTouch = false
    local jitter = Vector3.new((math.random() - 0.5) * 1.6, 0, (math.random() - 0.5) * 1.6)
    anchor.Position = worldPosition + jitter
    anchor.Parent = Workspace

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 120, 0, 40)
    bb.AlwaysOnTop = true
    bb.Parent = anchor

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBlack
    label.TextStrokeTransparency = 0.15

    if textOverride then
        label.Text = textOverride
        label.TextSize = 16
        label.TextColor3 = Color3.fromRGB(95, 225, 255)
    elseif isCrit then
        label.Text = tostring(amount) .. " CRIT!"
        label.TextSize = 20
        label.TextColor3 = Color3.fromRGB(255, 215, 55)
    elseif isSpecial then
        label.Text = tostring(amount) .. "!"
        label.TextSize = 18
        label.TextColor3 = Color3.fromRGB(255, 138, 65)
    else
        label.Text = tostring(amount)
        label.TextSize = 15
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
    end

    label.Parent = bb

    local tween = TweenService:Create(anchor, TweenInfo.new(0.65, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = anchor.Position + Vector3.new(0, 3.2, 0),
    })
    local fadeTween = TweenService:Create(label, TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        TextTransparency = 1,
        TextStrokeTransparency = 1,
    })

    tween:Play()
    fadeTween:Play()
    Debris:AddItem(anchor, 0.7)
end

function CombatController.tryAttack(attackKind: string)
    if not CameraController.isMouseLocked() and attackKind == "LMB" then
        return
    end

    local jobClass = (localPlayer:GetAttribute("JobClass") :: string?) or "Novice"
    local spec = CombatConfig.Classes[jobClass] or CombatConfig.Classes.Novice
    local now = os.clock()

    if attackKind == "RMB" then
        local mp = (localPlayer:GetAttribute("MP") :: number?) or 0
        if mp < spec.SpecialMPCost then
            local char = localPlayer.Character
            local root = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
            if root then
                spawnFloatingDamageNumber(
                    root.Position + Vector3.new(0, 2.8, 0),
                    0,
                    false,
                    false,
                    "NEED " .. tostring(spec.SpecialMPCost) .. " MP!"
                )
            end
            return
        end
    end

    if now - lastClientAttackTime < spec.ComboCooldown * 0.85 then
        return
    end
    lastClientAttackTime = now

    local aimDir = CameraController.getLookVector()
    Network.getEvent("RequestAttack"):FireServer(attackKind, aimDir)
end

function CombatController.init()
    local combatVFX = Network.getEvent("CombatVFX")
    local damageNumber = Network.getEvent("DamageNumber")

    combatVFX.OnClientEvent:Connect(
        function(
            _attackerCharacter: Model,
            jobClass: string,
            attackKind: string,
            comboStep: number,
            origin: Vector3,
            direction: Vector3,
            hitPositions: { Vector3 }
        )
            local spec = CombatConfig.Classes[jobClass] or CombatConfig.Classes.Novice
            local isSpecial = attackKind == "RMB"
            local vfxColor = if isSpecial then spec.SpecialColor else spec.SwingColor

            if spec.AttackStyle == "Melee" then
                spawnMeleeSlashVFX(origin, direction, vfxColor, isSpecial, comboStep)
            else
                spawnProjectileVFX(jobClass, origin, direction, vfxColor, isSpecial)
            end

            for _, hitPos in hitPositions do
                spawnImpactSparks(hitPos, vfxColor, if isSpecial then 8 else 5)
            end
        end
    )

    damageNumber.OnClientEvent:Connect(
        function(worldPosition: Vector3, amount: number, isCrit: boolean, isSpecial: boolean, textOverride: string?)
            spawnFloatingDamageNumber(worldPosition, amount, isCrit, isSpecial, textOverride)
        end
    )

    UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
        if gameProcessed then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            CombatController.tryAttack("LMB")
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 or input.KeyCode == Enum.KeyCode.F then
            CombatController.tryAttack("RMB")
        end
    end)
end

return table.freeze(CombatController)
