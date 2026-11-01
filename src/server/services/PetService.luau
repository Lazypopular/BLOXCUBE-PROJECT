--!strict
-- PetService: Spawns & Animates 3D Voxel Companion Pets, Combat Assist & Mount Riding (Server-Side)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local PetConfig = require(ReplicatedStorage.configs.PetConfig)
local MobService = require(script.Parent.MobService)
local PlayerService = require(script.Parent.PlayerService)

type ActivePetEntity = {
    Owner: Player,
    PetId: string,
    Spec: PetConfig.PetSpec,
    Model: Model,
    RootPart: Part,
    CurrentPos: Vector3,
    LastAttackTime: number,
}

local PetService = {}

local activePets: { [Player]: ActivePetEntity } = {}

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

local function buildPetVisuals(
    owner: Player,
    spec: PetConfig.PetSpec,
    spawnPos: Vector3,
    parentFolder: Folder
): (Model, Part)
    local model = Instance.new("Model")
    model.Name = owner.Name .. "_VoxelPet"

    local s = spec.Scale
    local baseCF = CFrame.new(spawnPos)
    local root = createPart("RootPart", Vector3.new(1.8 * s, 1.6 * s, 2.0 * s), spec.BodyColor, baseCF, model, 1)
    model.PrimaryPart = root

    if spec.Id == "SlimePet" then
        createPart("SlimeOuter", Vector3.new(2.1 * s, 1.85 * s, 2.1 * s), spec.BodyColor, baseCF, model, 0.22)
        createPart("SlimeCore", Vector3.new(1.1 * s, 1.0 * s, 1.1 * s), spec.AccentColor, baseCF, model, 0)
        createPart(
            "EyeL",
            Vector3.new(0.32 * s, 0.36 * s, 0.14 * s),
            spec.EyeColor,
            baseCF * CFrame.new(-0.4 * s, 0.12 * s, -1.06 * s),
            model
        )
        createPart(
            "EyeR",
            Vector3.new(0.32 * s, 0.36 * s, 0.14 * s),
            spec.EyeColor,
            baseCF * CFrame.new(0.4 * s, 0.12 * s, -1.06 * s),
            model
        )
    else
        -- Quadruped Voxel Pet (Terrier / Turtle / Ember Wolf)
        createPart("PetTorso", Vector3.new(1.55 * s, 1.15 * s, 2.25 * s), spec.BodyColor, baseCF, model)
        if spec.Id == "TurtlePet" then
            createPart(
                "TurtleShell",
                Vector3.new(2.05 * s, 1.1 * s, 2.35 * s),
                spec.AccentColor,
                baseCF * CFrame.new(0, 0.35 * s, 0),
                model
            )
        else
            createPart(
                "PetBackStripe",
                Vector3.new(0.8 * s, 0.25 * s, 1.8 * s),
                spec.AccentColor,
                baseCF * CFrame.new(0, 0.58 * s, 0.1 * s),
                model
            )
        end

        createPart(
            "PetHead",
            Vector3.new(1.35 * s, 1.25 * s, 1.25 * s),
            spec.BodyColor,
            baseCF * CFrame.new(0, 0.65 * s, -1.25 * s),
            model
        )
        createPart(
            "PetSnout",
            Vector3.new(0.75 * s, 0.58 * s, 0.55 * s),
            spec.AccentColor,
            baseCF * CFrame.new(0, 0.45 * s, -1.95 * s),
            model
        )
        createPart(
            "EyeL",
            Vector3.new(0.24 * s, 0.28 * s, 0.12 * s),
            spec.EyeColor,
            baseCF * CFrame.new(-0.36 * s, 0.78 * s, -1.88 * s),
            model
        )
        createPart(
            "EyeR",
            Vector3.new(0.24 * s, 0.28 * s, 0.12 * s),
            spec.EyeColor,
            baseCF * CFrame.new(0.36 * s, 0.78 * s, -1.88 * s),
            model
        )

        if spec.Id ~= "TurtlePet" then
            createPart(
                "EarL",
                Vector3.new(0.36 * s, 0.48 * s, 0.32 * s),
                spec.AccentColor,
                baseCF * CFrame.new(-0.45 * s, 1.42 * s, -1.1 * s),
                model
            )
            createPart(
                "EarR",
                Vector3.new(0.36 * s, 0.48 * s, 0.32 * s),
                spec.AccentColor,
                baseCF * CFrame.new(0.45 * s, 1.42 * s, -1.1 * s),
                model
            )
            createPart(
                "Tail",
                Vector3.new(0.36 * s, 0.75 * s, 0.36 * s),
                spec.AccentColor,
                baseCF * CFrame.new(0, 0.65 * s, 1.28 * s) * CFrame.Angles(math.rad(-35), 0, 0),
                model
            )
        end

        -- 4 Little Voxel Paws
        createPart(
            "PawFL",
            Vector3.new(0.45 * s, 0.65 * s, 0.45 * s),
            spec.AccentColor,
            baseCF * CFrame.new(-0.52 * s, -0.75 * s, -0.75 * s),
            model
        )
        createPart(
            "PawFR",
            Vector3.new(0.45 * s, 0.65 * s, 0.45 * s),
            spec.AccentColor,
            baseCF * CFrame.new(0.52 * s, -0.75 * s, -0.75 * s),
            model
        )
        createPart(
            "PawBL",
            Vector3.new(0.45 * s, 0.65 * s, 0.45 * s),
            spec.AccentColor,
            baseCF * CFrame.new(-0.52 * s, -0.75 * s, 0.75 * s),
            model
        )
        createPart(
            "PawBR",
            Vector3.new(0.45 * s, 0.65 * s, 0.45 * s),
            spec.AccentColor,
            baseCF * CFrame.new(0.52 * s, -0.75 * s, 0.75 * s),
            model
        )
    end

    for _, child in model:GetChildren() do
        if child:IsA("BasePart") and child ~= root then
            child:SetAttribute("RelOffset", root.CFrame:ToObjectSpace(child.CFrame))
        end
    end

    -- Overhead Pet Tag
    local bb = Instance.new("BillboardGui")
    bb.Name = "PetTag"
    bb.Adornee = root
    bb.Size = UDim2.new(0, 152, 0, 28)
    bb.StudsOffset = Vector3.new(0, 2.3 * s, 0)
    bb.AlwaysOnTop = false
    bb.MaxDistance = 55
    bb.Parent = root

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 1, 0)
    card.BackgroundColor3 = Color3.fromRGB(14, 17, 26)
    card.BackgroundTransparency = 0.18
    card.BorderSizePixel = 0
    card.Parent = bb

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Color = spec.BodyColor
    stroke.Thickness = 1.4
    stroke.Transparency = 0.25
    stroke.Parent = card

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 1, 0)
    lbl.Position = UDim2.new(0, 6, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.FredokaOne
    lbl.TextSize = 12
    lbl.TextColor3 = spec.BodyColor:Lerp(Color3.fromRGB(255, 255, 255), 0.35)
    lbl.TextStrokeTransparency = 0.25
    lbl.TextTruncate = Enum.TextTruncate.AtEnd
    lbl.Text = "🐾 " .. spec.Name
    lbl.Parent = card

    model.Parent = parentFolder
    return model, root
end

local function updatePetCFrame(pet: ActivePetEntity, cf: CFrame)
    pet.RootPart.CFrame = cf
    for _, child in pet.Model:GetChildren() do
        if child:IsA("BasePart") and child ~= pet.RootPart then
            local rel = child:GetAttribute("RelOffset") :: CFrame?
            if rel then
                child.CFrame = cf * rel
            end
        end
    end
end

local function ensurePetForPlayer(player: Player, petId: string, folder: Folder)
    local existing = activePets[player]
    if existing and existing.PetId == petId and existing.Model.Parent then
        return
    end

    if existing and existing.Model.Parent then
        existing.Model:Destroy()
    end

    local spec = PetConfig.Pets[petId] or PetConfig.Pets.SlimePet
    local char = player.Character
    local root = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
    local startPos = if root then root.Position + Vector3.new(-3.5, -1.2, 2.5) else Vector3.new(0, 1.5, 0)

    local model, petRoot = buildPetVisuals(player, spec, startPos, folder)
    activePets[player] = {
        Owner = player,
        PetId = petId,
        Spec = spec,
        Model = model,
        RootPart = petRoot,
        CurrentPos = startPos,
        LastAttackTime = 0,
    }
end

function PetService.init()
    local existingFolder = Workspace:FindFirstChild("BloxcubePets")
    if existingFolder then
        existingFolder:Destroy()
    end

    local petsFolder = Instance.new("Folder")
    petsFolder.Name = "BloxcubePets"
    petsFolder.Parent = Workspace

    Players.PlayerRemoving:Connect(function(player)
        local pet = activePets[player]
        if pet then
            if pet.Model.Parent then
                pet.Model:Destroy()
            end
            activePets[player] = nil
        end
    end)

    RunService.Heartbeat:Connect(function(dt: number)
        local now = os.clock()

        for _, player in Players:GetPlayers() do
            local activePetId = (player:GetAttribute("ActivePetId") :: string?) or "SlimePet"
            ensurePetForPlayer(player, activePetId, petsFolder)

            local pet = activePets[player]
            local char = player.Character
            local ownerRoot = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
            local hum = if char then char:FindFirstChildOfClass("Humanoid") else nil
            if not pet or not ownerRoot or not hum or hum.Health <= 0 then
                continue
            end

            local isMounted = player:GetAttribute("IsMounted") == true
            local tag = pet.RootPart:FindFirstChild("PetTag") :: BillboardGui?
            if tag then
                tag.Enabled = not isMounted
            end

            if isMounted then
                -- Position Pet directly underneath the mounted player
                local mountPos = ownerRoot.Position - Vector3.new(0, 2.25, 0)
                local hop = if hum.MoveDirection.Magnitude > 0.1 then math.abs(math.sin(now * 11)) * 0.35 else 0
                pet.CurrentPos = mountPos
                local look = ownerRoot.CFrame.LookVector
                local flatLook = Vector3.new(look.X, 0, look.Z)
                local dir = if flatLook.Magnitude > 0.01 then flatLook.Unit else Vector3.new(0, 0, -1)
                updatePetCFrame(
                    pet,
                    CFrame.lookAt(mountPos + Vector3.new(0, hop, 0), mountPos + Vector3.new(0, hop, 0) + dir)
                )
                continue
            end

            -- Follow AI beside owner + Combat Assist against nearby hostile Mobs
            local desiredFollowPos = (ownerRoot.CFrame * CFrame.new(-3.6, -1.6, 2.2)).Position
            local nearestTargets =
                MobService.getTargetsInArc(ownerRoot.Position, ownerRoot.CFrame.LookVector, 15.0, 15.0, true)

            local targetMob = nil
            for _, m in nearestTargets do
                if m.Spec.MobType ~= "TrainingDummy" then
                    targetMob = m
                    break
                end
            end
            local session = PlayerService.getSession(player)
            local lastAttack = session and session.LastAttackTime or 0
            if not targetMob and #nearestTargets > 0 and (now - lastAttack) < 3.0 then
                targetMob = nearestTargets[1]
            end

            if targetMob then
                local mobPos =
                    Vector3.new(targetMob.RootPart.Position.X, desiredFollowPos.Y, targetMob.RootPart.Position.Z)
                local toMob = mobPos - pet.CurrentPos
                local flatToMob = Vector3.new(toMob.X, 0, toMob.Z)
                if flatToMob.Magnitude > 2.8 then
                    pet.CurrentPos = pet.CurrentPos:Lerp(mobPos - flatToMob.Unit * 2.2, math.min(1, dt * 8))
                end

                if now - pet.LastAttackTime >= pet.Spec.AttackInterval then
                    pet.LastAttackTime = now
                    MobService.applyDamage(targetMob, player, pet.Spec.CombatDamage, false, false)
                end

                local hop = math.abs(math.sin(now * 9.5)) * 0.85
                local lookDir = if flatToMob.Magnitude > 0.01 then flatToMob.Unit else Vector3.new(0, 0, -1)
                updatePetCFrame(
                    pet,
                    CFrame.lookAt(
                        pet.CurrentPos + Vector3.new(0, hop, 0),
                        pet.CurrentPos + Vector3.new(0, hop, 0) + lookDir
                    )
                )
            else
                pet.CurrentPos = pet.CurrentPos:Lerp(desiredFollowPos, math.min(1, dt * 7.5))
                local dist = (desiredFollowPos - pet.CurrentPos).Magnitude
                local hop = if dist > 0.35 or hum.MoveDirection.Magnitude > 0.1
                    then math.abs(math.sin(now * 8.5)) * 0.65
                    else math.abs(math.sin(now * 3.0)) * 0.18
                local look = ownerRoot.CFrame.LookVector
                local flatLook = Vector3.new(look.X, 0, look.Z)
                local dir = if flatLook.Magnitude > 0.01 then flatLook.Unit else Vector3.new(0, 0, -1)
                updatePetCFrame(
                    pet,
                    CFrame.lookAt(
                        pet.CurrentPos + Vector3.new(0, hop, 0),
                        pet.CurrentPos + Vector3.new(0, hop, 0) + dir
                    )
                )
            end
        end
    end)
end

return table.freeze(PetService)
