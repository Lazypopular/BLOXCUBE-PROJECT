--!strict
-- PlayerService: Server-Authoritative State, Stamina, MP, EXP, Equipment, Pets, Glider & Data Persistence

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CharacterConfig = require(ReplicatedStorage.configs.CharacterConfig)
local CombatConfig = require(ReplicatedStorage.configs.CombatConfig)
local GameConfig = require(ReplicatedStorage.configs.GameConfig)
local ItemConfig = require(ReplicatedStorage.configs.ItemConfig)
local PetConfig = require(ReplicatedStorage.configs.PetConfig)
local WorldConfig = require(ReplicatedStorage.configs.WorldConfig)
local Network = require(ReplicatedStorage.network)
local DataService = require(script.Parent.DataService)
local VoxelRigService = require(script.Parent.VoxelRigService)

type AppearanceData = CharacterConfig.AppearanceData
type EquipmentItem = ItemConfig.EquipmentItem

export type PlayerSession = {
    Player: Player,
    HasCreatedCharacter: boolean,
    Level: number,
    Exp: number,
    MaxExp: number,
    Gold: number,
    JobClass: string,
    HP: number,
    MaxHP: number,
    MP: number,
    MaxMP: number,
    Stamina: number,
    MaxStamina: number,
    IsSprinting: boolean,
    IsDodging: boolean,
    IsMounted: boolean,
    IsGliding: boolean,
    LastDodgeTime: number,
    LastStaminaUseTime: number,
    LastAppearanceUpdateTime: number,
    LastAttackTime: number,
    LastSpecialTime: number,
    LastPotionTime: number,
    ComboStep: number,
    ActiveQuestId: string,
    QuestTitle: string,
    QuestDesc: string,
    QuestObjectiveType: string,
    QuestProgress: number,
    QuestRequired: number,
    QuestTargetClass: string,
    Potions: number,
    SpiritCubes: { [string]: number },
    WeaponCubeCount: number,
    WeaponCubeType: string,
    CubeBonusATK: number,
    CubeBonusHP: number,
    CubeBonusCrit: number,
    EquippedItem: EquipmentItem?,
    ActivePetId: string,
    OwnedPets: { [string]: boolean },
    BonusATK: number,
    BonusHP: number,
    BonusCrit: number,
    Inventory: { EquipmentItem },
    Appearance: AppearanceData,
    Connections: { RBXScriptConnection },
}

local PlayerService = {}

local sessions: { [Player]: PlayerSession } = {}

local function cloneDefaultAppearance(): AppearanceData
    return {
        SkinTone = CharacterConfig.DefaultAppearance.SkinTone,
        EyeColor = CharacterConfig.DefaultAppearance.EyeColor,
        HairStyle = CharacterConfig.DefaultAppearance.HairStyle,
        HairColor = CharacterConfig.DefaultAppearance.HairColor,
        OutfitStyle = CharacterConfig.DefaultAppearance.OutfitStyle,
    }
end

local function serializeSession(session: PlayerSession): { [string]: any }
    return {
        HasCreatedCharacter = session.HasCreatedCharacter,
        Level = session.Level,
        Exp = session.Exp,
        MaxExp = session.MaxExp,
        Gold = session.Gold,
        JobClass = session.JobClass,
        Potions = session.Potions,
        SpiritCubes = table.clone(session.SpiritCubes),
        WeaponCubeCount = session.WeaponCubeCount,
        WeaponCubeType = session.WeaponCubeType,
        CubeBonusATK = session.CubeBonusATK,
        CubeBonusHP = session.CubeBonusHP,
        CubeBonusCrit = session.CubeBonusCrit,
        ActivePetId = session.ActivePetId,
        OwnedPets = table.clone(session.OwnedPets),
        Appearance = table.clone(session.Appearance),
    }
end

local function recalculateStats(session: PlayerSession)
    local eqATK = if session.EquippedItem then session.EquippedItem.BonusATK else 0
    local eqHP = if session.EquippedItem then session.EquippedItem.BonusHP else 0
    local eqCrit = if session.EquippedItem then session.EquippedItem.BonusCrit else 0

    local petSpec = PetConfig.Pets[session.ActivePetId] or PetConfig.Pets.SlimePet
    local petATK = petSpec.BonusATK
    local petHP = petSpec.BonusHP

    session.BonusATK = eqATK + session.CubeBonusATK + petATK
    session.BonusHP = eqHP + session.CubeBonusHP + petHP
    session.BonusCrit = eqCrit + session.CubeBonusCrit

    local baseHP = GameConfig.Stats.BaseMaxHP + (session.Level - 1) * 20
    local newMaxHP = baseHP + session.BonusHP
    local hpDelta = newMaxHP - session.MaxHP
    session.MaxHP = newMaxHP
    if hpDelta > 0 then
        session.HP = math.min(session.MaxHP, session.HP + hpDelta)
    else
        session.HP = math.min(session.MaxHP, session.HP)
    end

    local character = session.Player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 then
            humanoid.MaxHealth = session.MaxHP
            humanoid.Health = session.HP
        end
    end
end

local function syncInventoryToClient(session: PlayerSession)
    Network.getEvent("InventorySynced"):FireClient(session.Player, session.Inventory, session.EquippedItem)
end

local function syncAttributes(session: PlayerSession)
    local player = session.Player
    local classSpec = CombatConfig.Classes[session.JobClass] or CombatConfig.Classes.Novice
    local eqName = if session.EquippedItem then session.EquippedItem.Name else classSpec.WeaponName
    local eqRarity = if session.EquippedItem then session.EquippedItem.Rarity else "Common"
    local eqStars = if session.EquippedItem then session.EquippedItem.Stars else "★"

    player:SetAttribute("IsCreatingCharacter", not session.HasCreatedCharacter)
    player:SetAttribute("VillageName", WorldConfig.Village.Name)
    player:SetAttribute("Level", session.Level)
    player:SetAttribute("Exp", session.Exp)
    player:SetAttribute("MaxExp", session.MaxExp)
    player:SetAttribute("Gold", session.Gold)
    player:SetAttribute("JobClass", session.JobClass)
    player:SetAttribute("HP", math.floor(session.HP + 0.5))
    player:SetAttribute("MaxHP", session.MaxHP)
    player:SetAttribute("MP", math.floor(session.MP + 0.5))
    player:SetAttribute("MaxMP", session.MaxMP)
    player:SetAttribute("Stamina", math.floor(session.Stamina * 10) / 10)
    player:SetAttribute("MaxStamina", session.MaxStamina)
    player:SetAttribute("IsSprinting", session.IsSprinting)
    player:SetAttribute("IsDodging", session.IsDodging)
    player:SetAttribute("IsMounted", session.IsMounted)
    player:SetAttribute("IsGliding", session.IsGliding)
    player:SetAttribute("ActivePetId", session.ActivePetId)
    player:SetAttribute("SkinTone", session.Appearance.SkinTone)
    player:SetAttribute("EyeColor", session.Appearance.EyeColor)
    player:SetAttribute("HairStyle", session.Appearance.HairStyle)
    player:SetAttribute("HairColor", session.Appearance.HairColor)
    player:SetAttribute("OutfitStyle", session.Appearance.OutfitStyle)
    player:SetAttribute("QuestTitle", session.QuestTitle)
    player:SetAttribute("QuestDesc", session.QuestDesc)
    player:SetAttribute("QuestProgress", math.floor(session.QuestProgress))
    player:SetAttribute("QuestRequired", session.QuestRequired)
    player:SetAttribute("Potions", session.Potions)
    player:SetAttribute("WeaponCubeCount", session.WeaponCubeCount)
    player:SetAttribute("WeaponCubeType", session.WeaponCubeType)
    player:SetAttribute("BonusATK", session.BonusATK)
    player:SetAttribute("BonusHP", session.BonusHP)
    player:SetAttribute("BonusCrit", math.floor(session.BonusCrit * 100 + 0.5))
    player:SetAttribute("EquippedWeaponName", eqName)
    player:SetAttribute("EquippedWeaponRarity", eqRarity)
    player:SetAttribute("EquippedWeaponStars", eqStars)
    player:SetAttribute("FireCubeCount", session.SpiritCubes.FireCube or 0)
    player:SetAttribute("IceCubeCount", session.SpiritCubes.IceCube or 0)
    player:SetAttribute("EmeraldCubeCount", session.SpiritCubes.EmeraldCube or 0)
    player:SetAttribute("VoidCubeCount", session.SpiritCubes.VoidCube or 0)

    for _, petKey in PetConfig.PetOrder do
        player:SetAttribute("Owns_" .. petKey, session.OwnedPets[petKey] == true)
    end
end

local function updateCharacterWalkSpeed(session: PlayerSession)
    local character = session.Player.Character
    if not character then
        return
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return
    end

    if not session.HasCreatedCharacter then
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        return
    end

    humanoid.JumpPower = GameConfig.Movement.JumpPower
    if session.IsMounted then
        local petSpec = PetConfig.Pets[session.ActivePetId] or PetConfig.Pets.SlimePet
        humanoid.WalkSpeed = petSpec.MountSpeed
    elseif session.IsSprinting and session.Stamina > 0 then
        humanoid.WalkSpeed = GameConfig.Movement.SprintSpeed
    else
        humanoid.WalkSpeed = GameConfig.Movement.WalkSpeed
    end
end

local function onCharacterAdded(session: PlayerSession, character: Model)
    local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
    if not humanoid then
        return
    end

    recalculateStats(session)
    session.HP = session.MaxHP
    session.Stamina = session.MaxStamina
    session.IsSprinting = false
    session.IsDodging = false
    session.IsGliding = false

    humanoid.MaxHealth = session.MaxHP
    humanoid.Health = session.HP
    humanoid.UseJumpPower = true
    humanoid.JumpPower = GameConfig.Movement.JumpPower
    updateCharacterWalkSpeed(session)

    character:SetAttribute("IsDodging", false)
    character:SetAttribute("IsSprinting", false)
    character:SetAttribute("IsGliding", false)
    character:SetAttribute("DodgeRollSeq", 0)
    character:SetAttribute("AttackSeq", 0)
    character:SetAttribute("AttackComboStep", 1)
    character:SetAttribute("AttackKind", "LMB")
    character:SetAttribute("JobClass", session.JobClass)
    character:SetAttribute("WeaponCubeCount", session.WeaponCubeCount)
    character:SetAttribute("WeaponCubeType", session.WeaponCubeType)

    VoxelRigService.buildCharacterRig(character, session.Appearance, session.JobClass)
    syncAttributes(session)
    syncInventoryToClient(session)

    task.defer(function()
        if not character.Parent then
            return
        end
        if not session.HasCreatedCharacter then
            character:PivotTo(WorldConfig.getCreationStageCFrame())
        else
            character:PivotTo(WorldConfig.getVillageSpawnCFrame(session.Player.UserId))
        end
    end)

    local diedConn: RBXScriptConnection?
    diedConn = humanoid.Died:Connect(function()
        if diedConn then
            diedConn:Disconnect()
            diedConn = nil
        end
        session.IsSprinting = false
        session.IsDodging = false
        session.IsMounted = false
        session.IsGliding = false
        syncAttributes(session)
    end)
end

local function setupPlayer(player: Player)
    if sessions[player] then
        return
    end

    pcall(function()
        player.DevEnableMouseLock = false
    end)

    local saved = DataService.loadProfile(player)

    local session: PlayerSession = {
        Player = player,
        HasCreatedCharacter = if saved and type(saved.HasCreatedCharacter) == "boolean"
            then saved.HasCreatedCharacter
            else false,
        Level = if saved and type(saved.Level) == "number" then saved.Level else 1,
        Exp = if saved and type(saved.Exp) == "number" then saved.Exp else 0,
        MaxExp = if saved and type(saved.MaxExp) == "number" then saved.MaxExp else 100,
        Gold = if saved and type(saved.Gold) == "number" then saved.Gold else 45,
        JobClass = if saved
                and type(saved.JobClass) == "string"
                and CharacterConfig.JobClasses[saved.JobClass]
            then saved.JobClass
            else "Novice",
        HP = GameConfig.Stats.BaseMaxHP,
        MaxHP = GameConfig.Stats.BaseMaxHP,
        MP = 0,
        MaxMP = GameConfig.Stats.BaseMaxMP,
        Stamina = GameConfig.Stamina.MaxStamina,
        MaxStamina = GameConfig.Stamina.MaxStamina,
        IsSprinting = false,
        IsDodging = false,
        IsMounted = false,
        IsGliding = false,
        LastDodgeTime = 0,
        LastStaminaUseTime = 0,
        LastAppearanceUpdateTime = 0,
        LastAttackTime = 0,
        LastSpecialTime = 0,
        LastPotionTime = -10,
        ComboStep = 0,
        ActiveQuestId = "",
        QuestTitle = "Speak to a Class Master NPC",
        QuestDesc = "Walk North to the Guild Courtyard and press [E] on a Master to start your Class Trial",
        QuestObjectiveType = "",
        QuestProgress = 0,
        QuestRequired = 0,
        QuestTargetClass = "",
        Potions = if saved and type(saved.Potions) == "number" then saved.Potions else ItemConfig.Potion.StartCount,
        SpiritCubes = if saved and type(saved.SpiritCubes) == "table"
            then saved.SpiritCubes
            else {
                FireCube = 2,
                IceCube = 1,
                EmeraldCube = 1,
                VoidCube = 0,
            },
        WeaponCubeCount = if saved and type(saved.WeaponCubeCount) == "number" then saved.WeaponCubeCount else 0,
        WeaponCubeType = if saved and type(saved.WeaponCubeType) == "string" then saved.WeaponCubeType else "FireCube",
        CubeBonusATK = if saved and type(saved.CubeBonusATK) == "number" then saved.CubeBonusATK else 0,
        CubeBonusHP = if saved and type(saved.CubeBonusHP) == "number" then saved.CubeBonusHP else 0,
        CubeBonusCrit = if saved and type(saved.CubeBonusCrit) == "number" then saved.CubeBonusCrit else 0,
        EquippedItem = nil,
        ActivePetId = if saved
                and type(saved.ActivePetId) == "string"
                and PetConfig.Pets[saved.ActivePetId]
            then saved.ActivePetId
            else "SlimePet",
        OwnedPets = if saved and type(saved.OwnedPets) == "table"
            then saved.OwnedPets
            else {
                SlimePet = true,
            },
        BonusATK = 0,
        BonusHP = 0,
        BonusCrit = 0,
        Inventory = {},
        Appearance = if saved and type(saved.Appearance) == "table" then saved.Appearance else cloneDefaultAppearance(),
        Connections = {},
    }

    session.OwnedPets.SlimePet = true

    sessions[player] = session
    recalculateStats(session)
    session.HP = session.MaxHP
    syncAttributes(session)
    syncInventoryToClient(session)

    local charAddedConn = player.CharacterAdded:Connect(function(character)
        onCharacterAdded(session, character)
    end)
    table.insert(session.Connections, charAddedConn)

    if player.Character then
        task.spawn(onCharacterAdded, session, player.Character)
    end
end

local function cleanupPlayer(player: Player)
    local session = sessions[player]
    if not session then
        return
    end

    DataService.saveProfile(player, serializeSession(session), true)

    for _, conn in session.Connections do
        conn:Disconnect()
    end
    table.clear(session.Connections)
    sessions[player] = nil
end

function PlayerService.getSession(player: Player): PlayerSession?
    return sessions[player]
end

function PlayerService.setSprinting(player: Player, wantSprint: boolean)
    local session = sessions[player]
    if not session then
        return
    end

    if wantSprint and session.Stamina >= 5 and not session.IsDodging then
        session.IsSprinting = true
    else
        session.IsSprinting = false
    end

    local character = player.Character
    if character then
        character:SetAttribute("IsSprinting", session.IsSprinting)
    end

    updateCharacterWalkSpeed(session)
    player:SetAttribute("IsSprinting", session.IsSprinting)
end

function PlayerService.toggleMount(player: Player)
    local session = sessions[player]
    if not session or session.IsDodging then
        return
    end

    session.IsMounted = not session.IsMounted
    if session.IsMounted and session.IsGliding then
        session.IsGliding = false
        if player.Character then
            player.Character:SetAttribute("IsGliding", false)
            VoxelRigService.setGliderVisible(player.Character, false)
        end
    end

    updateCharacterWalkSpeed(session)
    syncAttributes(session)
end

function PlayerService.toggleGlider(player: Player, forceState: boolean?)
    local session = sessions[player]
    if not session or session.IsDodging then
        return
    end

    local nextState = if forceState ~= nil then forceState else not session.IsGliding
    session.IsGliding = nextState

    if session.IsGliding and session.IsMounted then
        session.IsMounted = false
        updateCharacterWalkSpeed(session)
    end

    if player.Character then
        player.Character:SetAttribute("IsGliding", session.IsGliding)
        VoxelRigService.setGliderVisible(player.Character, session.IsGliding)
    end
    syncAttributes(session)
end

function PlayerService.selectOrTamePet(player: Player, petId: string)
    local session = sessions[player]
    if not session then
        return
    end

    local spec = PetConfig.Pets[petId]
    if not spec then
        return
    end

    if not session.OwnedPets[petId] then
        if session.Gold < spec.GoldCost then
            Network.getEvent("QuestNotification"):FireClient(
                player,
                "NOT ENOUGH GOLD TO TAME",
                string.format("You need %d Gold to buy %s and tame %s!", spec.GoldCost, spec.FoodName, spec.Name),
                Color3.fromRGB(245, 92, 82)
            )
            return
        end
        session.Gold -= spec.GoldCost
        session.OwnedPets[petId] = true
    end

    session.ActivePetId = petId
    recalculateStats(session)
    updateCharacterWalkSpeed(session)
    syncAttributes(session)

    Network.getEvent("QuestNotification"):FireClient(
        player,
        "🐾 COMPANION ACTIVE: " .. string.upper(spec.Name),
        string.format("%s  |  Press [T] to Ride as Mount!", spec.Description),
        spec.BodyColor
    )
end

function PlayerService.tryDodge(player: Player, moveDirection: Vector3): boolean
    local session = sessions[player]
    if not session then
        return false
    end

    local character = player.Character
    if not character then
        return false
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not humanoid or not rootPart or humanoid.Health <= 0 then
        return false
    end

    local now = os.clock()
    if now - session.LastDodgeTime < GameConfig.Movement.DodgeCooldown then
        return false
    end

    if session.Stamina < GameConfig.Stamina.DodgeCost then
        return false
    end

    if session.IsGliding then
        PlayerService.toggleGlider(player, false)
    end

    session.LastDodgeTime = now
    session.LastStaminaUseTime = now
    session.Stamina = math.max(0, session.Stamina - GameConfig.Stamina.DodgeCost)
    session.IsDodging = true
    session.IsSprinting = false

    local rollSeq = ((character:GetAttribute("DodgeRollSeq") :: number?) or 0) + 1
    character:SetAttribute("IsDodging", true)
    character:SetAttribute("IsSprinting", false)
    character:SetAttribute("DodgeRollSeq", rollSeq)

    player:SetAttribute("Stamina", math.floor(session.Stamina * 10) / 10)
    player:SetAttribute("IsDodging", true)
    player:SetAttribute("IsSprinting", false)

    local dodgeDir = moveDirection
    if dodgeDir.Magnitude < 0.01 then
        local look = rootPart.CFrame.LookVector
        local flatLook = Vector3.new(look.X, 0, look.Z)
        dodgeDir = if flatLook.Magnitude > 0.01 then flatLook.Unit else Vector3.new(0, 0, -1)
    else
        dodgeDir = dodgeDir.Unit
    end

    Network.getEvent("DodgePerformed"):FireClient(player, dodgeDir)

    task.delay(GameConfig.Movement.DodgeIFrameDuration, function()
        local activeSession = sessions[player]
        if not activeSession then
            return
        end
        activeSession.IsDodging = false
        player:SetAttribute("IsDodging", false)
        if player.Character then
            player.Character:SetAttribute("IsDodging", false)
        end
        updateCharacterWalkSpeed(activeSession)
    end)

    return true
end

function PlayerService.updateAppearance(
    player: Player,
    skinTone: string,
    eyeColor: string,
    hairStyle: string,
    hairColor: string,
    outfitStyle: string
)
    local session = sessions[player]
    if not session then
        return
    end

    local now = os.clock()
    if now - session.LastAppearanceUpdateTime < 0.08 then
        return
    end
    session.LastAppearanceUpdateTime = now

    session.Appearance.SkinTone = skinTone
    session.Appearance.EyeColor = eyeColor
    session.Appearance.HairStyle = hairStyle
    session.Appearance.HairColor = hairColor
    session.Appearance.OutfitStyle = outfitStyle

    syncAttributes(session)

    if player.Character then
        VoxelRigService.updateAppearanceAndCostume(player.Character, session.Appearance, session.JobClass)
    end
end

function PlayerService.completeCharacterCreation(
    player: Player,
    skinTone: string,
    eyeColor: string,
    hairStyle: string,
    hairColor: string,
    outfitStyle: string
)
    local session = sessions[player]
    if not session then
        return
    end

    session.Appearance.SkinTone = skinTone
    session.Appearance.EyeColor = eyeColor
    session.Appearance.HairStyle = hairStyle
    session.Appearance.HairColor = hairColor
    session.Appearance.OutfitStyle = outfitStyle
    session.HasCreatedCharacter = true

    syncAttributes(session)

    local character = player.Character
    if character then
        VoxelRigService.updateAppearanceAndCostume(character, session.Appearance, session.JobClass)
        updateCharacterWalkSpeed(session)
        character:PivotTo(WorldConfig.getVillageSpawnCFrame(player.UserId))
    end

    Network.getEvent("QuestNotification"):FireClient(
        player,
        "🏡 WELCOME TO " .. string.upper(WorldConfig.Village.Name),
        WorldConfig.Village.Tagline .. "  •  Head North to the Guild Courtyard to choose a Class!",
        Color3.fromRGB(255, 214, 96)
    )
end

function PlayerService.setJobClass(player: Player, newClass: string)
    local session = sessions[player]
    if not session then
        return
    end
    if not CharacterConfig.JobClasses[newClass] then
        return
    end

    session.JobClass = newClass
    session.MP = 0
    syncAttributes(session)

    if player.Character then
        player.Character:SetAttribute("JobClass", newClass)
        VoxelRigService.updateAppearanceAndCostume(player.Character, session.Appearance, session.JobClass)
    end
end

function PlayerService.addMP(player: Player, amount: number)
    local session = sessions[player]
    if not session or amount <= 0 then
        return
    end
    session.MP = math.clamp(session.MP + amount, 0, session.MaxMP)
    player:SetAttribute("MP", math.floor(session.MP + 0.5))
end

function PlayerService.consumeMP(player: Player, cost: number): boolean
    local session = sessions[player]
    if not session then
        return false
    end
    if session.MP < cost then
        return false
    end
    session.MP = math.max(0, session.MP - cost)
    player:SetAttribute("MP", math.floor(session.MP + 0.5))
    return true
end

function PlayerService.addExpAndGold(player: Player, expGain: number, goldGain: number)
    local session = sessions[player]
    if not session then
        return
    end

    session.Exp += math.max(0, expGain)
    session.Gold += math.max(0, goldGain)

    local leveledUp = false
    while session.Exp >= session.MaxExp do
        session.Exp -= session.MaxExp
        session.Level += 1
        session.MaxExp = math.floor(session.MaxExp * 1.35)
        leveledUp = true
    end

    if leveledUp then
        recalculateStats(session)
        session.HP = session.MaxHP
        if player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.MaxHealth = session.MaxHP
                hum.Health = session.HP
            end
        end

        Network.getEvent("QuestNotification"):FireClient(
            player,
            string.format("LEVEL UP! (LV. %d)", session.Level),
            string.format("Max HP increased to %d and Combat Power boosted!", session.MaxHP),
            Color3.fromRGB(110, 235, 128)
        )
    end

    syncAttributes(session)
end

function PlayerService.damagePlayer(player: Player, rawDamage: number): boolean
    local session = sessions[player]
    if not session or rawDamage <= 0 then
        return false
    end

    local character = player.Character
    if not character then
        return false
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not humanoid or not rootPart or humanoid.Health <= 0 then
        return false
    end

    if session.IsDodging then
        Network.getEvent("DamageNumber")
            :FireAllClients(rootPart.Position + Vector3.new(0, 2.5, 0), 0, false, false, "DODGED!")
        return false
    end

    session.HP = math.max(0, session.HP - rawDamage)
    humanoid.Health = session.HP
    player:SetAttribute("HP", math.floor(session.HP + 0.5))

    Network.getEvent("DamageNumber")
        :FireAllClients(rootPart.Position + Vector3.new(0, 2.5, 0), rawDamage, false, false, "PLAYER_HIT")

    return true
end

function PlayerService.usePotion(player: Player): boolean
    local session = sessions[player]
    if not session then
        return false
    end

    local character = player.Character
    if not character then
        return false
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not humanoid or not rootPart or humanoid.Health <= 0 then
        return false
    end

    local now = os.clock()
    if now - session.LastPotionTime < ItemConfig.Potion.Cooldown then
        return false
    end

    if session.Potions <= 0 then
        Network.getEvent("DamageNumber")
            :FireClient(player, rootPart.Position + Vector3.new(0, 2.6, 0), 0, false, false, "NO POTIONS!")
        return false
    end

    if session.HP >= session.MaxHP then
        Network.getEvent("DamageNumber")
            :FireClient(player, rootPart.Position + Vector3.new(0, 2.6, 0), 0, false, false, "HP FULL!")
        return false
    end

    session.LastPotionTime = now
    session.Potions -= 1
    local healAmount = math.max(25, math.floor(session.MaxHP * ItemConfig.Potion.HealRatio + 0.5))
    session.HP = math.min(session.MaxHP, session.HP + healAmount)
    humanoid.Health = session.HP
    syncAttributes(session)

    Network.getEvent("DamageNumber"):FireAllClients(
        rootPart.Position + Vector3.new(0, 2.6, 0),
        healAmount,
        false,
        false,
        string.format("+%d HP", healAmount)
    )
    return true
end

function PlayerService.buyPotionWithGold(player: Player): boolean
    local session = sessions[player]
    if not session then
        return false
    end

    local cost = ItemConfig.Potion.GoldCost
    if session.Gold < cost then
        Network.getEvent("QuestNotification"):FireClient(
            player,
            "NOT ENOUGH GOLD",
            string.format("You need %d Gold to brew a Heartflower Potion!", cost),
            Color3.fromRGB(245, 92, 82)
        )
        return false
    end

    session.Gold -= cost
    session.Potions += 1
    syncAttributes(session)

    Network.getEvent("QuestNotification"):FireClient(
        player,
        "HEARTFLOWER POTION BREWED!",
        string.format("Potions carried: %d  (Press [1] in combat to heal)", session.Potions),
        Color3.fromRGB(98, 235, 128)
    )
    return true
end

function PlayerService.addPotion(player: Player, count: number)
    local session = sessions[player]
    if not session or count <= 0 then
        return
    end
    session.Potions += count
    syncAttributes(session)
end

function PlayerService.addSpiritCube(player: Player, cubeType: string, count: number)
    local session = sessions[player]
    if not session or count <= 0 then
        return
    end
    if not ItemConfig.SpiritCubes[cubeType] then
        return
    end
    session.SpiritCubes[cubeType] = (session.SpiritCubes[cubeType] or 0) + count
    syncAttributes(session)
end

function PlayerService.addLootItem(player: Player, item: EquipmentItem)
    local session = sessions[player]
    if not session then
        return
    end

    table.insert(session.Inventory, 1, item)
    while #session.Inventory > 12 do
        table.remove(session.Inventory)
    end

    if not session.EquippedItem then
        session.EquippedItem = item
        recalculateStats(session)
    end

    syncAttributes(session)
    syncInventoryToClient(session)
end

function PlayerService.equipInventoryItem(player: Player, itemUid: number)
    local session = sessions[player]
    if not session then
        return
    end

    for _, item in session.Inventory do
        if item.Uid == itemUid then
            if item.ClassReq ~= "Any" and item.ClassReq ~= session.JobClass then
                Network.getEvent("QuestNotification"):FireClient(
                    player,
                    "CLASS REQUIREMENT",
                    string.format("This weapon requires Class: %s!", item.ClassReq),
                    Color3.fromRGB(245, 108, 88)
                )
                return
            end

            session.EquippedItem = item
            recalculateStats(session)
            syncAttributes(session)
            syncInventoryToClient(session)

            local rarityEntry = ItemConfig.Rarities[item.Rarity] or ItemConfig.Rarities.Common
            Network.getEvent("QuestNotification"):FireClient(
                player,
                string.format("EQUIPPED: %s %s", item.Stars, item.Name),
                string.format("+%d ATK  |  +%d MaxHP", item.BonusATK, item.BonusHP),
                rarityEntry.Color
            )
            return
        end
    end
end

function PlayerService.attachSpiritCube(player: Player, cubeType: string)
    local session = sessions[player]
    if not session then
        return
    end

    local cubeSpec = ItemConfig.SpiritCubes[cubeType]
    if not cubeSpec then
        return
    end

    if session.WeaponCubeCount >= ItemConfig.MaxWeaponSpiritCubes then
        Network.getEvent("QuestNotification"):FireClient(
            player,
            "MAX SPIRIT CUBES REACHED",
            string.format("Your weapon already holds the maximum %d Spirit Cubes!", ItemConfig.MaxWeaponSpiritCubes),
            Color3.fromRGB(255, 196, 68)
        )
        return
    end

    local owned = session.SpiritCubes[cubeType] or 0
    if owned <= 0 then
        Network.getEvent("QuestNotification"):FireClient(
            player,
            "NO " .. string.upper(cubeSpec.ShortName) .. "S",
            "Defeat Slimes and Bosses in the field to loot more Spirit Cubes!",
            Color3.fromRGB(245, 102, 82)
        )
        return
    end

    session.SpiritCubes[cubeType] = owned - 1
    session.WeaponCubeCount += 1
    session.WeaponCubeType = cubeType
    session.CubeBonusATK += cubeSpec.BonusATK
    session.CubeBonusHP += cubeSpec.BonusHP
    session.CubeBonusCrit += cubeSpec.BonusCrit

    recalculateStats(session)
    syncAttributes(session)

    if player.Character then
        player.Character:SetAttribute("WeaponCubeCount", session.WeaponCubeCount)
        player.Character:SetAttribute("WeaponCubeType", session.WeaponCubeType)
        VoxelRigService.updateAppearanceAndCostume(player.Character, session.Appearance, session.JobClass)
    end

    Network.getEvent("QuestNotification"):FireClient(
        player,
        string.format("SPIRIT CUBE FORGED! (+%d/%d)", session.WeaponCubeCount, ItemConfig.MaxWeaponSpiritCubes),
        string.format("Attached %s (%s) to your 3D Voxel Weapon!", cubeSpec.Name, cubeSpec.Description),
        cubeSpec.Color
    )
end

function PlayerService.acceptClassQuest(player: Player, masterSpec: any)
    local session = sessions[player]
    if not session then
        return
    end

    if masterSpec.ObjectiveType == "Instant" then
        session.ActiveQuestId = ""
        session.QuestTitle = "Class: Novice Adventurer"
        session.QuestDesc = "Speak to any Class Master in the Guild Courtyard to begin a Class Trial"
        session.QuestObjectiveType = ""
        session.QuestProgress = 0
        session.QuestRequired = 0
        session.QuestTargetClass = ""
        PlayerService.setJobClass(player, masterSpec.TargetClass)
        Network.getEvent("QuestNotification"):FireClient(
            player,
            "RETURNED TO NOVICE",
            "You are now wearing your Novice Starter Outfit & Wooden Sword.",
            Color3.fromRGB(218, 192, 138)
        )
        return
    end

    if session.JobClass == masterSpec.TargetClass then
        Network.getEvent("QuestNotification"):FireClient(
            player,
            "ALREADY A " .. string.upper(masterSpec.TargetClass),
            "You have already mastered the " .. masterSpec.TargetClass .. " class!",
            Color3.fromRGB(120, 215, 255)
        )
        return
    end

    session.ActiveQuestId = masterSpec.Id
    session.QuestTitle = masterSpec.QuestTitle
    session.QuestDesc = masterSpec.QuestDesc
    session.QuestObjectiveType = masterSpec.ObjectiveType
    session.QuestProgress = 0
    session.QuestRequired = masterSpec.RequiredAmount
    session.QuestTargetClass = masterSpec.TargetClass
    syncAttributes(session)

    Network.getEvent("QuestNotification")
        :FireClient(
            player,
            "QUEST ACCEPTED: " .. masterSpec.QuestTitle,
            masterSpec.QuestDesc,
            Color3.fromRGB(255, 208, 74)
        )
end

function PlayerService.recordQuestProgress(player: Player, objectiveType: string, amount: number)
    local session = sessions[player]
    if not session or session.ActiveQuestId == "" then
        return
    end

    if session.QuestObjectiveType ~= objectiveType then
        return
    end

    session.QuestProgress = math.min(session.QuestRequired, session.QuestProgress + amount)
    player:SetAttribute("QuestProgress", math.floor(session.QuestProgress))

    if session.QuestProgress >= session.QuestRequired then
        local promotedClass = session.QuestTargetClass
        session.ActiveQuestId = ""
        session.QuestTitle = "Class Unlocked: " .. promotedClass
        session.QuestDesc = "Trial Complete! Defeat King Gelatus in the South Ruins for Rare Loot & Spirit Cubes!"
        session.QuestObjectiveType = ""
        session.QuestProgress = 0
        session.QuestRequired = 0
        session.QuestTargetClass = ""

        PlayerService.setJobClass(player, promotedClass)
        PlayerService.addExpAndGold(player, 60, 25)
        syncAttributes(session)

        local classEntry = CharacterConfig.JobClasses[promotedClass] or CharacterConfig.JobClasses.Novice
        Network.getEvent("QuestNotification"):FireClient(
            player,
            "CLASS PROMOTED: " .. string.upper(promotedClass) .. "!",
            "Trial completed! You have received the " .. promotedClass .. " costume and weapon!",
            classEntry.AccentColor
        )
    end
end

function PlayerService.init()
    Players.PlayerAdded:Connect(setupPlayer)
    Players.PlayerRemoving:Connect(cleanupPlayer)

    for _, player in Players:GetPlayers() do
        task.spawn(setupPlayer, player)
    end

    game:BindToClose(function()
        for player, session in sessions do
            DataService.saveProfile(player, serializeSession(session), true)
        end
    end)

    -- Periodic Auto-Save every 90 seconds
    task.spawn(function()
        while true do
            task.wait(90)
            for player, session in sessions do
                DataService.saveProfile(player, serializeSession(session), false)
            end
        end
    end)

    RunService.Heartbeat:Connect(function(dt: number)
        local now = os.clock()
        for player, session in sessions do
            local character = player.Character
            local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
            local isMoving = if humanoid then humanoid.MoveDirection.Magnitude > 0.1 else false

            -- Passive slow HP regen out of combat
            if session.HP > 0 and session.HP < session.MaxHP and now - session.LastAttackTime > 4.0 then
                session.HP = math.min(session.MaxHP, session.HP + 4 * dt)
                if humanoid then
                    humanoid.Health = session.HP
                end
                player:SetAttribute("HP", math.floor(session.HP + 0.5))
            end

            if session.IsSprinting and isMoving and not session.IsDodging and not session.IsMounted then
                session.Stamina = math.max(0, session.Stamina - GameConfig.Stamina.SprintDrainPerSec * dt)
                session.LastStaminaUseTime = now

                if session.Stamina <= 0 then
                    session.IsSprinting = false
                    if character then
                        character:SetAttribute("IsSprinting", false)
                    end
                    updateCharacterWalkSpeed(session)
                    player:SetAttribute("IsSprinting", false)
                end

                player:SetAttribute("Stamina", math.floor(session.Stamina * 10) / 10)
            elseif
                not session.IsDodging and (now - session.LastStaminaUseTime >= GameConfig.Stamina.RegenDelayAfterUse)
            then
                if session.Stamina < session.MaxStamina then
                    session.Stamina =
                        math.min(session.MaxStamina, session.Stamina + GameConfig.Stamina.RegenRatePerSec * dt)
                    player:SetAttribute("Stamina", math.floor(session.Stamina * 10) / 10)
                end
            end
        end
    end)
end

return table.freeze(PlayerService)
