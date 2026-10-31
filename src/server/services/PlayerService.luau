--!strict
-- PlayerService: Server-Authoritative State, Stamina, Movement Speed & Character Lifecycle

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

-- Server-only method for promoting a player's JobClass when completing a Class Master NPC Quest
function PlayerService.setJobClass(player: Player, newJobClass: string)
    local session = sessions[player]
    if not session or not CharacterConfig.JobClasses[newJobClass] then
        return
    end

    session.JobClass = newJobClass
    syncAttributes(session)

    if player.Character then
        VoxelRigService.updateAppearanceAndCostume(player.Character, session.Appearance, session.JobClass)
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
