--!strict
-- CombatService: Server-Authoritative Action Combat, Combo Tracking, MP Gain & Hitbox Validation

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatConfig = require(ReplicatedStorage.configs.CombatConfig)
local Network = require(ReplicatedStorage.network)
local MobService = require(script.Parent.MobService)
local PlayerService = require(script.Parent.PlayerService)

local CombatService = {}

local COMBO_RESET_WINDOW = 1.35

function CombatService.performAttack(player: Player, attackKind: string, aimDirection: Vector3)
    local session = PlayerService.getSession(player)
    if not session then
        return
    end

    local character = player.Character
    if not character then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not humanoid or not rootPart or humanoid.Health <= 0 then
        return
    end

    local spec = CombatConfig.Classes[session.JobClass] or CombatConfig.Classes.Novice
    local now = os.clock()

    local isSpecial = attackKind == "RMB"
    if isSpecial then
        if now - session.LastSpecialTime < spec.SpecialCooldown * 0.9 then
            return
        end
        if not PlayerService.consumeMP(player, spec.SpecialMPCost) then
            return
        end
        session.LastSpecialTime = now
        session.LastAttackTime = now
        PlayerService.recordQuestProgress(player, "SpecialUsed", 1)
    else
        if now - session.LastAttackTime < spec.ComboCooldown * 0.88 then
            return
        end
        if now - session.LastAttackTime > COMBO_RESET_WINDOW then
            session.ComboStep = 1
        else
            session.ComboStep = (session.ComboStep % #spec.ComboDamage) + 1
        end
        session.LastAttackTime = now
    end

    local comboStep = if isSpecial then 3 else math.max(1, session.ComboStep)

    -- Replicate Attack Animation Trigger via Attributes
    local seq = ((character:GetAttribute("AttackSeq") :: number?) or 0) + 1
    character:SetAttribute("AttackComboStep", comboStep)
    character:SetAttribute("AttackKind", attackKind)
    character:SetAttribute("AttackSeq", seq)

    local origin = rootPart.Position
    local unitAim = if aimDirection.Magnitude > 0.001 then aimDirection.Unit else rootPart.CFrame.LookVector

    -- Rogue RMB Shadow Lunge forward step
    if isSpecial and session.JobClass == "Rogue" then
        local flatAim = Vector3.new(unitAim.X, 0, unitAim.Z)
        if flatAim.Magnitude > 0.01 then
            rootPart.CFrame = rootPart.CFrame + flatAim.Unit * 5.5
            origin = rootPart.Position
        end
    end

    -- Server Hitbox Detection
    local targets: { MobService.MobEntity } = {}
    if spec.AttackStyle == "Melee" then
        local range = if isSpecial then spec.SpecialRange else spec.ComboRange
        local isFullCircle = isSpecial and session.JobClass == "Warrior"
        targets = MobService.getTargetsInArc(origin, unitAim, range, spec.HitboxRadius, isFullCircle)
    else
        local range = if isSpecial then spec.SpecialRange else spec.ComboRange
        local radius = if isSpecial then spec.HitboxRadius * 1.45 else spec.HitboxRadius
        targets = MobService.getTargetsAlongRay(origin, unitAim, range, radius)
    end

    local baseDamage = if isSpecial then spec.SpecialDamage else (spec.ComboDamage[comboStep] or spec.ComboDamage[1])
    local levelBonus = (session.Level - 1) * 3

    local hitPositions: { Vector3 } = {}
    local gainedMP = false

    for _, mob in targets do
        local isCrit = math.random() < spec.CritChance
        local rawDmg = baseDamage + levelBonus
        local finalDmg = if isCrit then math.floor(rawDmg * spec.CritMultiplier + 0.5) else rawDmg

        table.insert(hitPositions, mob.RootPart.Position)
        MobService.applyDamage(mob, player, finalDmg, isCrit, isSpecial)

        if not isSpecial and not gainedMP then
            gainedMP = true
            PlayerService.addMP(player, spec.MPGainPerHit)
        end

        if not isSpecial then
            PlayerService.recordQuestProgress(player, "HitsLanded", 1)
        end
    end

    Network.getEvent("CombatVFX")
        :FireAllClients(character, session.JobClass, attackKind, comboStep, origin, unitAim, hitPositions)
end

return table.freeze(CombatService)
