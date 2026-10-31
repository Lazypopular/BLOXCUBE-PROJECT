--!strict
-- Shared Game Constants & Balance Configuration for BLOXCUBE

local GameConfig = {
    GameName = "BLOXCUBE",
    Version = "0.1.0",

    Classes = {
        "None",
        "Warrior",
        "Ranger",
        "Mage",
        "Rogue",
    },

    Movement = {
        WalkSpeed = 16,
        SprintSpeed = 25,
        JumpPower = 54,
        DodgeSpeed = 48,
        DodgeDuration = 0.38,
        DodgeCooldown = 0.75,
        DodgeIFrameDuration = 0.32,
    },

    Stamina = {
        MaxStamina = 100,
        SprintDrainPerSec = 18,
        DodgeCost = 25,
        RegenRatePerSec = 28,
        RegenDelayAfterUse = 0.85,
    },

    Stats = {
        BaseMaxHP = 120,
        BaseMaxMP = 100,
    },

    Camera = {
        DefaultFOV = 70,
        SprintFOV = 78,
        DefaultDistance = 12,
        MinDistance = 5,
        MaxDistance = 24,
        ZoomStep = 2,
        ShoulderOffset = Vector3.new(1.75, 1.85, 0),
        Sensitivity = 0.22,
        MinPitch = -65,
        MaxPitch = 65,
    },
}

return table.freeze(GameConfig)
