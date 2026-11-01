--!strict
-- PetConfig: Cube World Style Voxel Companions, Mount Speeds, Taming & Hang Glider Constants

local PetConfig = {}

export type PetSpec = {
    Id: string,
    Name: string,
    FoodName: string,
    GoldCost: number,
    BodyColor: Color3,
    AccentColor: Color3,
    EyeColor: Color3,
    Scale: number,
    CombatDamage: number,
    AttackInterval: number,
    BonusATK: number,
    BonusHP: number,
    MountSpeed: number,
    Description: string,
}

PetConfig.Glider = {
    ForwardSpeed = 34,
    SinkVelocity = -8.5,
    LaunchBoostY = 26,
    WoodColor = Color3.fromRGB(138, 88, 46),
    WingPrimary = Color3.fromRGB(245, 238, 215),
    WingAccent = Color3.fromRGB(228, 78, 64),
}

PetConfig.Pets = {
    SlimePet = {
        Id = "SlimePet",
        Name = "Pink Jelly Slime",
        FoodName = "Pink Jelly",
        GoldCost = 0,
        BodyColor = Color3.fromRGB(248, 118, 172),
        AccentColor = Color3.fromRGB(255, 182, 215),
        EyeColor = Color3.fromRGB(36, 24, 34),
        Scale = 0.85,
        CombatDamage = 10,
        AttackInterval = 1.6,
        BonusATK = 2,
        BonusHP = 15,
        MountSpeed = 30,
        Description = "+2 ATK, +15 MaxHP | Mount Speed: 30",
    },
    TerrierPet = {
        Id = "TerrierPet",
        Name = "Voxel Highland Terrier",
        FoodName = "Meat Bone",
        GoldCost = 25,
        BodyColor = Color3.fromRGB(168, 118, 76),
        AccentColor = Color3.fromRGB(112, 74, 44),
        EyeColor = Color3.fromRGB(28, 26, 24),
        Scale = 0.9,
        CombatDamage = 16,
        AttackInterval = 1.35,
        BonusATK = 6,
        BonusHP = 10,
        MountSpeed = 33,
        Description = "+6 ATK, +10 MaxHP | Mount Speed: 33",
    },
    TurtlePet = {
        Id = "TurtlePet",
        Name = "Emerald Shell Turtle",
        FoodName = "Cinnamon Roll",
        GoldCost = 45,
        BodyColor = Color3.fromRGB(82, 184, 108),
        AccentColor = Color3.fromRGB(54, 122, 68),
        EyeColor = Color3.fromRGB(24, 38, 28),
        Scale = 1.0,
        CombatDamage = 14,
        AttackInterval = 1.7,
        BonusATK = 3,
        BonusHP = 45,
        MountSpeed = 29,
        Description = "+3 ATK, +45 MaxHP | Mount Speed: 29",
    },
    EmberWolf = {
        Id = "EmberWolf",
        Name = "Crimson Ember Wolf",
        FoodName = "lollipop / Prime Meat",
        GoldCost = 80,
        BodyColor = Color3.fromRGB(196, 58, 54),
        AccentColor = Color3.fromRGB(255, 156, 52),
        EyeColor = Color3.fromRGB(255, 218, 68),
        Scale = 1.05,
        CombatDamage = 24,
        AttackInterval = 1.25,
        BonusATK = 10,
        BonusHP = 25,
        MountSpeed = 36,
        Description = "+10 ATK, +25 MaxHP | Mount Speed: 36",
    },
}

PetConfig.PetOrder = {
    "SlimePet",
    "TerrierPet",
    "TurtlePet",
    "EmberWolf",
}

return table.freeze(PetConfig)
