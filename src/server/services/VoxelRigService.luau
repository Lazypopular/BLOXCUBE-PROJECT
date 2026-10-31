--!strict
-- VoxelRigService: Builds and updates the 3-Layer Modular Voxel Character Rig + Held Voxel Weapons (Server-Side)
-- Layer 1: Base Voxel Body & Joints
-- Layer 2: Player Customizable Appearance (Skin, Face/Eyes, Hair Style & Color)
-- Layer 3: Starter Outfit (Novice Civilian Clothing) or Class Costume + Held Voxel Weapon

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterConfig = require(ReplicatedStorage.configs.CharacterConfig)

type AppearanceData = CharacterConfig.AppearanceData

local VoxelRigService = {}

local function createVoxelPart(
    name: string,
    size: Vector3,
    color: Color3,
    parent: Instance,
    material: Enum.Material?
): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Massless = true
    part.Anchored = false
    part.CastShadow = true
    part.Parent = parent
    return part
end

local function weldParts(part0: BasePart, part1: BasePart, offsetCFrame: CFrame): Weld
    local weld = Instance.new("Weld")
    weld.Name = part1.Name .. "_Weld"
    weld.Part0 = part0
    weld.Part1 = part1
    weld.C0 = offsetCFrame
    weld.Parent = part1
    return weld
end

local function attachVoxelBlock(
    name: string,
    size: Vector3,
    color: Color3,
    hostLimb: BasePart,
    offset: CFrame,
    container: Instance,
    material: Enum.Material?
): Part
    local block = createVoxelPart(name, size, color, container, material)
    weldParts(hostLimb, block, offset)
    return block
end

local function stripDefaultAppearance(character: Model)
    local animateScript = character:FindFirstChild("Animate")
    if animateScript then
        animateScript:Destroy()
    end

    for _, child in character:GetDescendants() do
        if child:IsA("BasePart") then
            if child.Name ~= "HumanoidRootPart" then
                child.Transparency = 1
                child.CanCollide = false
                child.CanQuery = false
                child.CanTouch = false
                child.CastShadow = false
                child.Massless = true
            else
                child.Transparency = 1
            end
        elseif
            child:IsA("Decal")
            or child:IsA("Texture")
            or child:IsA("Shirt")
            or child:IsA("Pants")
            or child:IsA("ShirtGraphic")
            or child:IsA("CharacterMesh")
            or child:IsA("SpecialMesh")
            or child:IsA("Accessory")
        then
            child:Destroy()
        end
    end
end

local function buildAppearanceLayer(rigModel: Model, appearance: AppearanceData)
    local existingLayer = rigModel:FindFirstChild("AppearanceLayer")
    if existingLayer then
        existingLayer:Destroy()
    end

    local layer = Instance.new("Folder")
    layer.Name = "AppearanceLayer"
    layer.Parent = rigModel

    local head = rigModel:FindFirstChild("VoxelHead") :: BasePart?
    local torso = rigModel:FindFirstChild("VoxelTorso") :: BasePart?
    local leftArm = rigModel:FindFirstChild("VoxelLeftArm") :: BasePart?
    local rightArm = rigModel:FindFirstChild("VoxelRightArm") :: BasePart?
    local leftFoot = rigModel:FindFirstChild("VoxelLeftFoot") :: BasePart?
    local rightFoot = rigModel:FindFirstChild("VoxelRightFoot") :: BasePart?

    if not (head and torso and leftArm and rightArm and leftFoot and rightFoot) then
        return
    end

    local skinEntry = CharacterConfig.SkinTones[appearance.SkinTone] or CharacterConfig.SkinTones.HumanLight
    local eyeEntry = CharacterConfig.EyeColors[appearance.EyeColor] or CharacterConfig.EyeColors.SkyBlue
    local hairEntry = CharacterConfig.HairColors[appearance.HairColor] or CharacterConfig.HairColors.Chestnut

    local skinColor = skinEntry.Color
    local eyeColor = eyeEntry.Color
    local hairColor = hairEntry.Color

    head.Color = skinColor
    torso.Color = skinColor
    leftArm.Color = skinColor
    rightArm.Color = skinColor
    leftFoot.Color = skinColor
    rightFoot.Color = skinColor

    local isPointedEar = appearance.SkinTone == "ElfPale" or appearance.SkinTone == "OrcGreen"
    local earWidth = if isPointedEar then 0.55 else 0.28
    local earOffsetX = if isPointedEar then 1.25 else 1.14

    attachVoxelBlock("NoseVoxel", Vector3.new(0.32, 0.32, 0.22), skinColor, head, CFrame.new(0, -0.12, -1.06), layer)
    attachVoxelBlock(
        "LeftEarVoxel",
        Vector3.new(earWidth, 0.45, 0.35),
        skinColor,
        head,
        CFrame.new(-earOffsetX, -0.05, 0),
        layer
    )
    attachVoxelBlock(
        "RightEarVoxel",
        Vector3.new(earWidth, 0.45, 0.35),
        skinColor,
        head,
        CFrame.new(earOffsetX, -0.05, 0),
        layer
    )

    local whiteColor = Color3.fromRGB(248, 250, 252)
    local browColor = hairColor:Lerp(Color3.fromRGB(20, 20, 25), 0.35)

    attachVoxelBlock(
        "LeftEyeWhite",
        Vector3.new(0.46, 0.42, 0.08),
        whiteColor,
        head,
        CFrame.new(-0.48, -0.02, -0.98),
        layer
    )
    attachVoxelBlock(
        "RightEyeWhite",
        Vector3.new(0.46, 0.42, 0.08),
        whiteColor,
        head,
        CFrame.new(0.48, -0.02, -0.98),
        layer
    )

    attachVoxelBlock("LeftPupil", Vector3.new(0.28, 0.34, 0.1), eyeColor, head, CFrame.new(-0.44, -0.03, -1.0), layer)
    attachVoxelBlock("RightPupil", Vector3.new(0.28, 0.34, 0.1), eyeColor, head, CFrame.new(0.44, -0.03, -1.0), layer)

    attachVoxelBlock(
        "LeftEyeHighlight",
        Vector3.new(0.11, 0.11, 0.12),
        whiteColor,
        head,
        CFrame.new(-0.5, 0.06, -1.01),
        layer
    )
    attachVoxelBlock(
        "RightEyeHighlight",
        Vector3.new(0.11, 0.11, 0.12),
        whiteColor,
        head,
        CFrame.new(0.4, 0.06, -1.01),
        layer
    )

    attachVoxelBlock("LeftBrow", Vector3.new(0.52, 0.14, 0.12), browColor, head, CFrame.new(-0.48, 0.3, -1.0), layer)
    attachVoxelBlock("RightBrow", Vector3.new(0.52, 0.14, 0.12), browColor, head, CFrame.new(0.48, 0.3, -1.0), layer)

    local style = appearance.HairStyle
    if style == "Spiky" then
        attachVoxelBlock("HairTop", Vector3.new(2.26, 0.48, 2.24), hairColor, head, CFrame.new(0, 0.96, 0.04), layer)
        attachVoxelBlock("HairCrown", Vector3.new(1.85, 0.36, 1.85), hairColor, head, CFrame.new(0, 1.28, 0.08), layer)
        attachVoxelBlock("HairBack", Vector3.new(2.22, 1.45, 0.42), hairColor, head, CFrame.new(0, 0.22, 0.96), layer)
        attachVoxelBlock(
            "HairSideL",
            Vector3.new(0.32, 1.15, 1.85),
            hairColor,
            head,
            CFrame.new(-1.05, 0.38, 0.12),
            layer
        )
        attachVoxelBlock(
            "HairSideR",
            Vector3.new(0.32, 1.15, 1.85),
            hairColor,
            head,
            CFrame.new(1.05, 0.38, 0.12),
            layer
        )
        attachVoxelBlock("HairBangC", Vector3.new(0.65, 0.52, 0.32), hairColor, head, CFrame.new(0, 0.68, -0.98), layer)
        attachVoxelBlock(
            "HairBangL",
            Vector3.new(0.58, 0.44, 0.28),
            hairColor,
            head,
            CFrame.new(-0.66, 0.72, -0.95),
            layer
        )
        attachVoxelBlock(
            "HairBangR",
            Vector3.new(0.58, 0.44, 0.28),
            hairColor,
            head,
            CFrame.new(0.66, 0.72, -0.95),
            layer
        )
        attachVoxelBlock(
            "HairSpike1",
            Vector3.new(0.55, 0.45, 0.55),
            hairColor,
            head,
            CFrame.new(-0.45, 1.45, -0.25),
            layer
        )
        attachVoxelBlock(
            "HairSpike2",
            Vector3.new(0.55, 0.52, 0.55),
            hairColor,
            head,
            CFrame.new(0.35, 1.5, 0.15),
            layer
        )
    elseif style == "Adventurer" then
        attachVoxelBlock("HairTop", Vector3.new(2.24, 0.46, 2.22), hairColor, head, CFrame.new(0, 0.95, 0.02), layer)
        attachVoxelBlock("HairBack", Vector3.new(2.2, 1.55, 0.45), hairColor, head, CFrame.new(0, 0.15, 0.96), layer)
        attachVoxelBlock(
            "HairSideL",
            Vector3.new(0.34, 1.25, 1.9),
            hairColor,
            head,
            CFrame.new(-1.05, 0.3, 0.08),
            layer
        )
        attachVoxelBlock("HairSideR", Vector3.new(0.34, 1.25, 1.9), hairColor, head, CFrame.new(1.05, 0.3, 0.08), layer)
        attachVoxelBlock(
            "HairSweep",
            Vector3.new(1.45, 0.45, 0.3),
            hairColor,
            head,
            CFrame.new(0.32, 0.7, -0.96),
            layer
        )
    elseif style == "Long" then
        attachVoxelBlock("HairTop", Vector3.new(2.28, 0.5, 2.26), hairColor, head, CFrame.new(0, 0.96, 0.04), layer)
        attachVoxelBlock(
            "HairBackUpper",
            Vector3.new(2.24, 2.1, 0.48),
            hairColor,
            head,
            CFrame.new(0, -0.1, 0.98),
            layer
        )
        attachVoxelBlock(
            "HairBackLower",
            Vector3.new(1.88, 1.15, 0.44),
            hairColor,
            head,
            CFrame.new(0, -1.35, 1.02),
            layer
        )
        attachVoxelBlock(
            "HairLockL",
            Vector3.new(0.38, 1.85, 0.52),
            hairColor,
            head,
            CFrame.new(-0.98, -0.15, -0.78),
            layer
        )
        attachVoxelBlock(
            "HairLockR",
            Vector3.new(0.38, 1.85, 0.52),
            hairColor,
            head,
            CFrame.new(0.98, -0.15, -0.78),
            layer
        )
        attachVoxelBlock("HairFringe", Vector3.new(1.9, 0.4, 0.28), hairColor, head, CFrame.new(0, 0.76, -0.96), layer)
    elseif style == "Mohawk" then
        attachVoxelBlock(
            "MohawkCrest1",
            Vector3.new(0.52, 0.75, 2.35),
            hairColor,
            head,
            CFrame.new(0, 1.22, -0.05),
            layer
        )
        attachVoxelBlock(
            "MohawkCrest2",
            Vector3.new(0.46, 0.55, 1.65),
            hairColor,
            head,
            CFrame.new(0, 1.62, 0.05),
            layer
        )
        attachVoxelBlock("MohawkBack", Vector3.new(0.48, 1.35, 0.48), hairColor, head, CFrame.new(0, 0.35, 1.05), layer)
    end
end

local function buildWeaponInHands(rigModel: Model, jobClassName: string, layer: Instance)
    local leftArm = rigModel:FindFirstChild("VoxelLeftArm") :: BasePart?
    local rightArm = rigModel:FindFirstChild("VoxelRightArm") :: BasePart?
    if not (leftArm and rightArm) then
        return
    end

    if jobClassName == "Novice" then
        -- Voxel Wooden Training Sword in Right Hand
        local woodDark = Color3.fromRGB(115, 76, 44)
        local woodLight = Color3.fromRGB(186, 138, 86)
        attachVoxelBlock(
            "SwordGrip",
            Vector3.new(0.24, 0.24, 0.85),
            woodDark,
            rightArm,
            CFrame.new(0, -0.68, -0.2),
            layer
        )
        attachVoxelBlock(
            "SwordGuard",
            Vector3.new(0.75, 0.26, 0.24),
            woodDark,
            rightArm,
            CFrame.new(0, -0.68, -0.62),
            layer
        )
        attachVoxelBlock(
            "SwordBlade",
            Vector3.new(0.32, 0.18, 2.15),
            woodLight,
            rightArm,
            CFrame.new(0, -0.68, -1.78),
            layer
        )
    elseif jobClassName == "Warrior" then
        -- Voxel Iron Greatsword in Right Hand
        local hiltColor = Color3.fromRGB(92, 54, 36)
        local goldColor = Color3.fromRGB(238, 188, 64)
        local bladeSteel = Color3.fromRGB(218, 226, 238)
        attachVoxelBlock(
            "GreatswordGrip",
            Vector3.new(0.26, 0.26, 1.05),
            hiltColor,
            rightArm,
            CFrame.new(0, -0.68, -0.15),
            layer
        )
        attachVoxelBlock(
            "GreatswordCrossguard",
            Vector3.new(1.15, 0.32, 0.28),
            goldColor,
            rightArm,
            CFrame.new(0, -0.68, -0.72),
            layer,
            Enum.Material.Metal
        )
        attachVoxelBlock(
            "GreatswordBlade",
            Vector3.new(0.52, 0.2, 2.85),
            bladeSteel,
            rightArm,
            CFrame.new(0, -0.68, -2.22),
            layer,
            Enum.Material.Metal
        )
        attachVoxelBlock(
            "GreatswordCore",
            Vector3.new(0.22, 0.24, 2.2),
            Color3.fromRGB(178, 52, 48),
            rightArm,
            CFrame.new(0, -0.68, -2.0),
            layer
        )
    elseif jobClassName == "Ranger" then
        -- Voxel Hunter Bow in Left Hand
        local bowWood = Color3.fromRGB(134, 86, 46)
        local bowTrim = Color3.fromRGB(64, 152, 76)
        local bowString = Color3.fromRGB(235, 240, 245)
        attachVoxelBlock("BowGrip", Vector3.new(0.26, 0.95, 0.28), bowTrim, leftArm, CFrame.new(0, -0.68, -0.55), layer)
        attachVoxelBlock(
            "BowLimbUpper",
            Vector3.new(0.24, 1.15, 0.24),
            bowWood,
            leftArm,
            CFrame.new(0, 0.18, -0.35) * CFrame.Angles(math.rad(24), 0, 0),
            layer
        )
        attachVoxelBlock(
            "BowLimbLower",
            Vector3.new(0.24, 1.15, 0.24),
            bowWood,
            leftArm,
            CFrame.new(0, -1.54, -0.35) * CFrame.Angles(math.rad(-24), 0, 0),
            layer
        )
        attachVoxelBlock(
            "BowString",
            Vector3.new(0.08, 2.45, 0.08),
            bowString,
            leftArm,
            CFrame.new(0, -0.68, -0.12),
            layer
        )
    elseif jobClassName == "Mage" then
        -- Voxel Arcane Crystal Staff in Right Hand
        local staffWood = Color3.fromRGB(108, 68, 42)
        local staffGold = Color3.fromRGB(235, 192, 78)
        local crystalCyan = Color3.fromRGB(98, 224, 255)
        attachVoxelBlock(
            "StaffShaft",
            Vector3.new(0.24, 0.24, 3.2),
            staffWood,
            rightArm,
            CFrame.new(0, -0.68, -0.95),
            layer
        )
        attachVoxelBlock(
            "StaffCrown",
            Vector3.new(0.56, 0.42, 0.36),
            staffGold,
            rightArm,
            CFrame.new(0, -0.68, -2.58),
            layer,
            Enum.Material.Metal
        )
        attachVoxelBlock(
            "StaffCrystal",
            Vector3.new(0.46, 0.46, 0.46),
            crystalCyan,
            rightArm,
            CFrame.new(0, -0.68, -2.98) * CFrame.Angles(math.rad(45), math.rad(45), 0),
            layer,
            Enum.Material.Neon
        )
    elseif jobClassName == "Rogue" then
        -- Twin Voxel Daggers in Both Hands
        local gripDark = Color3.fromRGB(42, 44, 54)
        local guardCrimson = Color3.fromRGB(185, 42, 68)
        local bladeSteel = Color3.fromRGB(210, 218, 232)

        attachVoxelBlock(
            "RightDaggerGrip",
            Vector3.new(0.22, 0.22, 0.65),
            gripDark,
            rightArm,
            CFrame.new(0, -0.68, -0.15),
            layer
        )
        attachVoxelBlock(
            "RightDaggerGuard",
            Vector3.new(0.58, 0.22, 0.2),
            guardCrimson,
            rightArm,
            CFrame.new(0, -0.68, -0.48),
            layer
        )
        attachVoxelBlock(
            "RightDaggerBlade",
            Vector3.new(0.26, 0.14, 1.45),
            bladeSteel,
            rightArm,
            CFrame.new(0, -0.68, -1.25),
            layer,
            Enum.Material.Metal
        )

        attachVoxelBlock(
            "LeftDaggerGrip",
            Vector3.new(0.22, 0.22, 0.65),
            gripDark,
            leftArm,
            CFrame.new(0, -0.68, -0.15),
            layer
        )
        attachVoxelBlock(
            "LeftDaggerGuard",
            Vector3.new(0.58, 0.22, 0.2),
            guardCrimson,
            leftArm,
            CFrame.new(0, -0.68, -0.48),
            layer
        )
        attachVoxelBlock(
            "LeftDaggerBlade",
            Vector3.new(0.26, 0.14, 1.45),
            bladeSteel,
            leftArm,
            CFrame.new(0, -0.68, -1.25),
            layer,
            Enum.Material.Metal
        )
    end
end

local function buildCostumeLayer(rigModel: Model, appearance: AppearanceData, jobClassName: string)
    local existingLayer = rigModel:FindFirstChild("CostumeLayer")
    if existingLayer then
        existingLayer:Destroy()
    end

    local layer = Instance.new("Folder")
    layer.Name = "CostumeLayer"
    layer.Parent = rigModel

    local head = rigModel:FindFirstChild("VoxelHead") :: BasePart?
    local torso = rigModel:FindFirstChild("VoxelTorso") :: BasePart?
    local leftArm = rigModel:FindFirstChild("VoxelLeftArm") :: BasePart?
    local rightArm = rigModel:FindFirstChild("VoxelRightArm") :: BasePart?
    local leftFoot = rigModel:FindFirstChild("VoxelLeftFoot") :: BasePart?
    local rightFoot = rigModel:FindFirstChild("VoxelRightFoot") :: BasePart?

    if not (head and torso and leftArm and rightArm and leftFoot and rightFoot) then
        return
    end

    -- Attach Held 3D Voxel Weapon in Hands
    buildWeaponInHands(rigModel, jobClassName, layer)

    if jobClassName == "Novice" then
        local outfit = CharacterConfig.StarterOutfits[appearance.OutfitStyle]
            or CharacterConfig.StarterOutfits.TravelerVest

        attachVoxelBlock(
            "ShirtTorso",
            Vector3.new(1.88, 1.52, 1.18),
            outfit.ShirtColor,
            torso,
            CFrame.new(0, 0.12, 0),
            layer
        )
        attachVoxelBlock(
            "PantsWaist",
            Vector3.new(1.86, 0.52, 1.16),
            outfit.PantsColor,
            torso,
            CFrame.new(0, -0.72, 0),
            layer
        )
        attachVoxelBlock(
            "BeltStrap",
            Vector3.new(1.94, 0.24, 1.24),
            outfit.BootColor,
            torso,
            CFrame.new(0, -0.46, 0),
            layer
        )
        attachVoxelBlock(
            "BeltBuckle",
            Vector3.new(0.4, 0.3, 0.14),
            outfit.AccentColor,
            torso,
            CFrame.new(0, -0.46, -0.62),
            layer
        )

        attachVoxelBlock(
            "LeftSleeve",
            Vector3.new(0.84, 0.68, 0.84),
            outfit.ShirtColor,
            leftArm,
            CFrame.new(0, 0.44, 0),
            layer
        )
        attachVoxelBlock(
            "RightSleeve",
            Vector3.new(0.84, 0.68, 0.84),
            outfit.ShirtColor,
            rightArm,
            CFrame.new(0, 0.44, 0),
            layer
        )

        attachVoxelBlock(
            "LeftBoot",
            Vector3.new(0.86, 0.76, 1.22),
            outfit.BootColor,
            leftFoot,
            CFrame.new(0, -0.2, 0),
            layer
        )
        attachVoxelBlock(
            "RightBoot",
            Vector3.new(0.86, 0.76, 1.22),
            outfit.BootColor,
            rightFoot,
            CFrame.new(0, -0.2, 0),
            layer
        )

        if outfit.HasVest then
            attachVoxelBlock(
                "VestPanelL",
                Vector3.new(0.62, 1.38, 1.24),
                outfit.VestColor,
                torso,
                CFrame.new(-0.62, 0.16, 0),
                layer
            )
            attachVoxelBlock(
                "VestPanelR",
                Vector3.new(0.62, 1.38, 1.24),
                outfit.VestColor,
                torso,
                CFrame.new(0.62, 0.16, 0),
                layer
            )
            attachVoxelBlock(
                "VestBack",
                Vector3.new(1.9, 1.38, 0.16),
                outfit.VestColor,
                torso,
                CFrame.new(0, 0.16, 0.56),
                layer
            )
        end

        if outfit.HasStrap then
            attachVoxelBlock(
                "ShoulderStrap",
                Vector3.new(0.28, 1.72, 1.26),
                outfit.BootColor,
                torso,
                CFrame.new(0, 0.1, 0) * CFrame.Angles(0, 0, math.rad(32)),
                layer
            )
        end

        if outfit.HasScarf then
            attachVoxelBlock(
                "NeckCollar",
                Vector3.new(1.55, 0.24, 1.32),
                outfit.AccentColor,
                torso,
                CFrame.new(0, 0.88, 0),
                layer
            )
        end

        return
    end

    local costume = CharacterConfig.JobClasses[jobClassName] or CharacterConfig.JobClasses.Novice
    local primary = costume.PrimaryColor
    local secondary = costume.SecondaryColor
    local accent = costume.AccentColor
    local bootColor = costume.BootColor

    attachVoxelBlock("ChestTunic", Vector3.new(1.88, 1.55, 1.18), primary, torso, CFrame.new(0, 0.12, 0), layer)
    attachVoxelBlock("PantsWaist", Vector3.new(1.86, 0.52, 1.16), secondary, torso, CFrame.new(0, -0.72, 0), layer)
    attachVoxelBlock("BeltStrap", Vector3.new(1.94, 0.26, 1.24), bootColor, torso, CFrame.new(0, -0.46, 0), layer)
    attachVoxelBlock("BeltBuckle", Vector3.new(0.42, 0.32, 0.14), accent, torso, CFrame.new(0, -0.46, -0.62), layer)

    attachVoxelBlock("LeftSleeve", Vector3.new(0.84, 0.72, 0.84), primary, leftArm, CFrame.new(0, 0.42, 0), layer)
    attachVoxelBlock("RightSleeve", Vector3.new(0.84, 0.72, 0.84), primary, rightArm, CFrame.new(0, 0.42, 0), layer)

    attachVoxelBlock("LeftBoot", Vector3.new(0.86, 0.78, 1.22), bootColor, leftFoot, CFrame.new(0, -0.2, 0), layer)
    attachVoxelBlock("RightBoot", Vector3.new(0.86, 0.78, 1.22), bootColor, rightFoot, CFrame.new(0, -0.2, 0), layer)

    if jobClassName == "Warrior" then
        attachVoxelBlock(
            "ChestPlate",
            Vector3.new(1.52, 1.05, 0.16),
            secondary,
            torso,
            CFrame.new(0, 0.24, -0.58),
            layer,
            Enum.Material.Metal
        )
        attachVoxelBlock(
            "LeftPauldron",
            Vector3.new(0.98, 0.55, 0.98),
            secondary,
            leftArm,
            CFrame.new(-0.06, 0.66, 0),
            layer,
            Enum.Material.Metal
        )
        attachVoxelBlock(
            "RightPauldron",
            Vector3.new(0.98, 0.55, 0.98),
            secondary,
            rightArm,
            CFrame.new(0.06, 0.66, 0),
            layer,
            Enum.Material.Metal
        )
        attachVoxelBlock(
            "WarriorCape",
            Vector3.new(1.65, 1.75, 0.16),
            primary,
            torso,
            CFrame.new(0, -0.05, 0.66),
            layer
        )
        attachVoxelBlock("WarriorHeadband", Vector3.new(2.18, 0.24, 2.12), accent, head, CFrame.new(0, 0.54, 0), layer)
    elseif jobClassName == "Ranger" then
        attachVoxelBlock(
            "RangerStrap",
            Vector3.new(0.32, 1.75, 1.24),
            secondary,
            torso,
            CFrame.new(0, 0.1, 0) * CFrame.Angles(0, 0, math.rad(32)),
            layer
        )
        attachVoxelBlock("RangerBandana", Vector3.new(2.16, 0.24, 2.1), primary, head, CFrame.new(0, 0.54, 0), layer)
        attachVoxelBlock(
            "RangerFeather",
            Vector3.new(0.18, 0.65, 0.35),
            accent,
            head,
            CFrame.new(0.98, 0.85, 0.25),
            layer
        )
        attachVoxelBlock(
            "QuiverTube",
            Vector3.new(0.55, 1.45, 0.45),
            secondary,
            torso,
            CFrame.new(0.42, 0.25, 0.78),
            layer
        )
        attachVoxelBlock(
            "QuiverFletching",
            Vector3.new(0.38, 0.35, 0.32),
            Color3.fromRGB(235, 240, 245),
            torso,
            CFrame.new(0.42, 1.08, 0.78),
            layer
        )
    elseif jobClassName == "Mage" then
        attachVoxelBlock(
            "MageRobeTrim",
            Vector3.new(1.25, 1.48, 0.14),
            secondary,
            torso,
            CFrame.new(0, 0.1, -0.56),
            layer
        )
        attachVoxelBlock(
            "ArcaneCore",
            Vector3.new(0.36, 0.36, 0.18),
            accent,
            torso,
            CFrame.new(0, 0.42, -0.62),
            layer,
            Enum.Material.Neon
        )
        attachVoxelBlock("MageCirclet", Vector3.new(2.16, 0.2, 2.1), secondary, head, CFrame.new(0, 0.54, 0), layer)
        attachVoxelBlock(
            "MageCircletGem",
            Vector3.new(0.28, 0.32, 0.16),
            accent,
            head,
            CFrame.new(0, 0.56, -1.04),
            layer,
            Enum.Material.Neon
        )
    elseif jobClassName == "Rogue" then
        attachVoxelBlock("RogueScarf", Vector3.new(2.16, 0.55, 2.12), secondary, head, CFrame.new(0, -0.68, 0), layer)
        attachVoxelBlock(
            "RogueScarfTail",
            Vector3.new(0.48, 1.25, 0.24),
            secondary,
            torso,
            CFrame.new(0.45, 0.32, 0.68),
            layer
        )
    end
end

function VoxelRigService.buildCharacterRig(character: Model, appearance: AppearanceData, jobClass: string?)
    local rootPart = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
    local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
    if not rootPart or not humanoid then
        return
    end

    humanoid.RequiresNeck = false
    humanoid.BreakJointsOnDeath = false
    humanoid.AutoRotate = false

    stripDefaultAppearance(character)

    local existingRig = character:FindFirstChild("VoxelRig")
    if existingRig then
        existingRig:Destroy()
    end

    local rigModel = Instance.new("Model")
    rigModel.Name = "VoxelRig"
    rigModel.Parent = character

    local skinEntry = CharacterConfig.SkinTones[appearance.SkinTone] or CharacterConfig.SkinTones.HumanLight
    local skinColor = skinEntry.Color

    local torso = createVoxelPart("VoxelTorso", Vector3.new(1.8, 1.85, 1.1), skinColor, rigModel)
    local head = createVoxelPart("VoxelHead", Vector3.new(2.08, 1.96, 1.96), skinColor, rigModel)
    local leftArm = createVoxelPart("VoxelLeftArm", Vector3.new(0.74, 1.62, 0.74), skinColor, rigModel)
    local rightArm = createVoxelPart("VoxelRightArm", Vector3.new(0.74, 1.62, 0.74), skinColor, rigModel)
    local leftFoot = createVoxelPart("VoxelLeftFoot", Vector3.new(0.78, 1.12, 1.14), skinColor, rigModel)
    local rightFoot = createVoxelPart("VoxelRightFoot", Vector3.new(0.78, 1.12, 1.14), skinColor, rigModel)

    rigModel.PrimaryPart = torso

    local function createJoint(name: string, part0: BasePart, part1: BasePart, c0: CFrame, c1: CFrame): Motor6D
        local motor = Instance.new("Motor6D")
        motor.Name = name
        motor.Part0 = part0
        motor.Part1 = part1
        motor.C0 = c0
        motor.C1 = c1
        motor:SetAttribute("OriginalC0", c0)
        motor:SetAttribute("OriginalC1", c1)
        motor.Parent = part0
        return motor
    end

    createJoint("RootJoint", rootPart, torso, CFrame.new(0, -0.35, 0), CFrame.new(0, 0, 0))
    createJoint("Neck", torso, head, CFrame.new(0, 0.95, 0), CFrame.new(0, -0.95, 0))
    createJoint("LeftShoulder", torso, leftArm, CFrame.new(-1.28, 0.68, 0), CFrame.new(0, 0.56, 0))
    createJoint("RightShoulder", torso, rightArm, CFrame.new(1.28, 0.68, 0), CFrame.new(0, 0.56, 0))
    createJoint("LeftHip", torso, leftFoot, CFrame.new(-0.5, -0.95, 0), CFrame.new(0, 0.52, 0.12))
    createJoint("RightHip", torso, rightFoot, CFrame.new(0.5, -0.95, 0), CFrame.new(0, 0.52, 0.12))

    local activeClass = jobClass or "Novice"
    buildAppearanceLayer(rigModel, appearance)
    buildCostumeLayer(rigModel, appearance, activeClass)

    character.DescendantAdded:Connect(function(descendant)
        if descendant:IsDescendantOf(rigModel) then
            return
        end
        if descendant:IsA("Accessory") then
            task.defer(function()
                if descendant.Parent then
                    descendant:Destroy()
                end
            end)
        elseif descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
            descendant.Transparency = 1
            descendant.CanCollide = false
        end
    end)
end

function VoxelRigService.updateAppearanceAndCostume(character: Model, appearance: AppearanceData, jobClass: string?)
    local rigModel = character:FindFirstChild("VoxelRig")
    local activeClass = jobClass or "Novice"
    if not rigModel or not rigModel:IsA("Model") then
        VoxelRigService.buildCharacterRig(character, appearance, activeClass)
        return
    end

    buildAppearanceLayer(rigModel, appearance)
    buildCostumeLayer(rigModel, appearance, activeClass)
end

return table.freeze(VoxelRigService)
