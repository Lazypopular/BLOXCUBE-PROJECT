--!strict
-- PlayerService: Server-Authoritative State, Stamina, MP, EXP, Class Quests & Character Lifecycle

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CharacterConfig = require(ReplicatedStorage.configs.CharacterConfig)
local GameConfig = require(ReplicatedStorage.configs.GameConfig)
local Network = require(ReplicatedStorage.network)
local VoxelRigService = require(script.Parent.VoxelRigService)

type AppearanceData = CharacterConfig.AppearanceData

export type PlayerSession = {
    Player: Player,
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
    LastDodgeTime: number,
    LastStaminaUseTime: number,
    LastAppearanceUpdateTime: number,
    LastAttackTime: number,
    LastSpecialTime: number,
    ComboStep: number,
    ActiveQuestId: string,
    QuestTitle: string,
    QuestDesc: string,
    QuestObjectiveType: string,
    QuestProgress: number,
    QuestRequired: number,
    QuestTargetClass: string,
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

local function syncAttributes(session: PlayerSession)
    local player = session.Player
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
    player:SetAttribute("SkinTone", session.Appearance.SkinTone)
    player:SetAttribute("EyeColor", session.Appearance.EyeColor)
    player:SetAttribute("HairStyle", session.Appearance.HairStyle)
    player:SetAttribute("HairColor", session.Appearance.HairColor)
    player:SetAttribute("OutfitStyle", session.Appearance.OutfitStyle)
    player:SetAttribute("QuestTitle", session.QuestTitle)
    player:SetAttribute("QuestDesc", session.QuestDesc)
    player:SetAttribute("QuestProgress", math.floor(session.QuestProgress))
    player:SetAttribute("QuestRequired", session.QuestRequired)
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

    if session.IsSprinting and session.Stamina > 0 then
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

    session.HP = session.MaxHP
    session.Stamina = session.MaxStamina
    session.IsSprinting = false
    session.IsDodging = false

    humanoid.MaxHealth = session.MaxHP
    humanoid.Health = session.HP
    humanoid.WalkSpeed = GameConfig.Movement.WalkSpeed
    humanoid.UseJumpPower = true
    humanoid.JumpPower = GameConfig.Movement.JumpPower

    character:SetAttribute("IsDodging", false)
    character:SetAttribute("IsSprinting", false)
    character:SetAttribute("DodgeRollSeq", 0)
    character:SetAttribute("AttackSeq", 0)
    character:SetAttribute("AttackComboStep", 1)
    character:SetAttribute("AttackKind", "LMB")
    character:SetAttribute("JobClass", session.JobClass)

    VoxelRigService.buildCharacterRig(character, session.Appearance, session.JobClass)
    syncAttributes(session)

    local diedConn: RBXScriptConnection?
    diedConn = humanoid.Died:Connect(function()
        if diedConn then
            diedConn:Disconnect()
            diedConn = nil
        end
        session.IsSprinting = false
        session.IsDodging = false
        syncAttributes(session)
    end)
end

local function setupPlayer(player: Player)
    if sessions[player] then
        return
    end

    local session: PlayerSession = {
        Player = player,
        Level = 1,
        Exp = 0,
        MaxExp = 100,
        Gold = 0,
        JobClass = "Novice",
        HP = GameConfig.Stats.BaseMaxHP,
        MaxHP = GameConfig.Stats.BaseMaxHP,
        MP = 0,
        MaxMP = GameConfig.Stats.BaseMaxMP,
        Stamina = GameConfig.Stamina.MaxStamina,
        MaxStamina = GameConfig.Stamina.MaxStamina,
        IsSprinting = false,
        IsDodging = false,
        LastDodgeTime = 0,
        LastStaminaUseTime = 0,
        LastAppearanceUpdateTime = 0,
        LastAttackTime = 0,
        LastSpecialTime = 0,
        ComboStep = 0,
        ActiveQuestId = "",
        QuestTitle = "Speak to a Class Master NPC",
        QuestDesc = "Walk North to the Guild Courtyard and press [E] on a Master to start your Class Trial",
        QuestObjectiveType = "",
        QuestProgress = 0,
        QuestRequired = 0,
        QuestTargetClass = "",
        Appearance = cloneDefaultAppearance(),
        Connections = {},
    }

    sessions[player] = session
    syncAttributes(session)

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

    session.Stamina = math.max(0, session.Stamina - GameConfig.Stamina.DodgeCost)
    session.LastDodgeTime = now
    session.LastStaminaUseTime = now
    session.IsDodging = true
    session.IsSprinting = false

    local seq = ((character:GetAttribute("DodgeRollSeq") :: number?) or 0) + 1
    character:SetAttribute("DodgeRollSeq", seq)
    character:SetAttribute("IsDodging", true)
    character:SetAttribute("IsSprinting", false)

    updateCharacterWalkSpeed(session)
    syncAttributes(session)

    local dodgeEvent = Network.getEvent("DodgePerformed")
    dodgeEvent:FireClient(player, moveDirection, session.Stamina)

    task.delay(GameConfig.Movement.DodgeIFrameDuration, function()
        if sessions[player] == session then
            session.IsDodging = false
            player:SetAttribute("IsDodging", false)
            if player.Character then
                player.Character:SetAttribute("IsDodging", false)
            end
        end
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
    if now - session.LastAppearanceUpdateTime < 0.12 then
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

function PlayerService.setJobClass(player: Player, newJobClass: string)
    local session = sessions[player]
    if not session or not CharacterConfig.JobClasses[newJobClass] then
        return
    end

    session.JobClass = newJobClass
    syncAttributes(session)

    if player.Character then
        player.Character:SetAttribute("JobClass", newJobClass)
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

function PlayerService.consumeMP(player: Player, amount: number): boolean
    local session = sessions[player]
    if not session or session.MP < amount then
        return false
    end
    session.MP = math.max(0, session.MP - amount)
    player:SetAttribute("MP", math.floor(session.MP + 0.5))
    return true
end

function PlayerService.addExpAndGold(player: Player, expAmount: number, goldAmount: number)
    local session = sessions[player]
    if not session then
        return
    end

    session.Exp += expAmount
    session.Gold += goldAmount

    while session.Exp >= session.MaxExp do
        session.Exp -= session.MaxExp
        session.Level += 1
        session.MaxExp = math.floor(session.MaxExp * 1.35 + 25)
        session.MaxHP += 20
        session.HP = session.MaxHP

        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                humanoid.MaxHealth = session.MaxHP
                humanoid.Health = session.HP
            end
        end

        Network.getEvent("QuestNotification"):FireClient(
            player,
            "LEVEL UP!  (LV. " .. tostring(session.Level) .. ")",
            "Max HP increased to " .. tostring(session.MaxHP) .. " and fully restored!",
            Color3.fromRGB(255, 215, 64)
        )
    end

    syncAttributes(session)
end

function PlayerService.damagePlayer(player: Player, damage: number): boolean
    local session = sessions[player]
    if not session or damage <= 0 then
        return false
    end

    if session.IsDodging then
        -- Dodged via I-Frame!
        local character = player.Character
        local rootPart = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
        if rootPart then
            Network.getEvent("DamageNumber")
                :FireAllClients(rootPart.Position + Vector3.new(0, 2.5, 0), 0, false, false, "DODGED!")
        end
        return false
    end

    local character = player.Character
    local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
    if not humanoid or humanoid.Health <= 0 then
        return false
    end

    session.HP = math.max(0, session.HP - damage)
    humanoid.Health = session.HP
    player:SetAttribute("HP", math.floor(session.HP + 0.5))

    local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if rootPart then
        Network.getEvent("DamageNumber")
            :FireAllClients(rootPart.Position + Vector3.new(0, 2.5, 0), damage, false, false, nil)
    end

    if session.HP <= 0 then
        task.delay(2.5, function()
            if player.Parent then
                player:LoadCharacter()
            end
        end)
    end

    return true
end

function PlayerService.acceptClassQuest(player: Player, masterSpec: any)
    local session = sessions[player]
    if not session then
        return
    end

    if masterSpec.ObjectiveType == "Instant" then
        PlayerService.setJobClass(player, masterSpec.TargetClass)
        session.ActiveQuestId = ""
        session.QuestTitle = "Class Reset to Novice"
        session.QuestDesc = "Speak to any Class Master to begin a new Class Trial"
        session.QuestObjectiveType = ""
        session.QuestProgress = 0
        session.QuestRequired = 0
        session.QuestTargetClass = ""
        syncAttributes(session)

        Network.getEvent("QuestNotification"):FireClient(
            player,
            "RETURNED TO NOVICE",
            "You are now a Novice Adventurer again.",
            Color3.fromRGB(205, 185, 135)
        )
        return
    end

    if session.JobClass == masterSpec.TargetClass then
        Network.getEvent("QuestNotification"):FireClient(
            player,
            masterSpec.Name,
            "You are already a " .. masterSpec.TargetClass .. "! Train hard out there.",
            Color3.fromRGB(120, 210, 255)
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
        session.QuestDesc = "Trial Complete! Speak to other Masters anytime to test other Classes."
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

            if session.IsSprinting and isMoving and not session.IsDodging then
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
            elseif now - session.LastStaminaUseTime >= GameConfig.Stamina.RegenDelayAfterUse then
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
