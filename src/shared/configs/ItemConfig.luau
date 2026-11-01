--!strict
-- ItemConfig: Cube World Style Rarities (1-5 Stars), Spirit Cubes, Equipment & Consumables

local ItemConfig = {}

export type RarityInfo = {
    Key: string,
    Name: string,
    Stars: string,
    Color: Color3,
    StatMultiplier: number,
    Weight: number,
}

export type SpiritCubeSpec = {
    Id: string,
    Name: string,
    ShortName: string,
    Color: Color3,
    BonusATK: number,
    BonusHP: number,
    BonusCrit: number,
    Description: string,
}

export type EquipmentItem = {
    Uid: number,
    TemplateId: string,
    Name: string,
    ClassReq: string,
    Rarity: string,
    Stars: string,
    BonusATK: number,
    BonusHP: number,
    BonusCrit: number,
}

ItemConfig.MaxWeaponSpiritCubes = 12

ItemConfig.Potion = {
    Name = "Heartflower Potion",
    HealRatio = 0.45,
    Cooldown = 3.5,
    GoldCost = 15,
    StartCount = 3,
}

ItemConfig.Rarities = {
    Common = {
        Key = "Common",
        Name = "Common",
        Stars = "★",
        Color = Color3.fromRGB(220, 226, 238),
        StatMultiplier = 1.0,
        Weight = 45,
    },
    Uncommon = {
        Key = "Uncommon",
        Name = "Uncommon",
        Stars = "★★",
        Color = Color3.fromRGB(82, 224, 108),
        StatMultiplier = 1.35,
        Weight = 30,
    },
    Rare = {
        Key = "Rare",
        Name = "Rare",
        Stars = "★★★",
        Color = Color3.fromRGB(72, 168, 255),
        StatMultiplier = 1.75,
        Weight = 15,
    },
    Epic = {
        Key = "Epic",
        Name = "Epic",
        Stars = "★★★★",
        Color = Color3.fromRGB(186, 92, 255),
        StatMultiplier = 2.25,
        Weight = 7,
    },
    Legendary = {
        Key = "Legendary",
        Name = "Legendary",
        Stars = "★★★★★",
        Color = Color3.fromRGB(255, 204, 56),
        StatMultiplier = 3.0,
        Weight = 3,
    },
}

ItemConfig.RarityOrder = {
    "Common",
    "Uncommon",
    "Rare",
    "Epic",
    "Legendary",
}

ItemConfig.SpiritCubes = {
    FireCube = {
        Id = "FireCube",
        Name = "Fire Spirit Cube",
        ShortName = "Fire Cube",
        Color = Color3.fromRGB(255, 102, 42),
        BonusATK = 4,
        BonusHP = 0,
        BonusCrit = 0.01,
        Description = "+4 ATK, +1% Crit",
    },
    IceCube = {
        Id = "IceCube",
        Name = "Frost Spirit Cube",
        ShortName = "Frost Cube",
        Color = Color3.fromRGB(78, 214, 255),
        BonusATK = 3,
        BonusHP = 5,
        BonusCrit = 0.02,
        Description = "+3 ATK, +5 HP, +2% Crit",
    },
    EmeraldCube = {
        Id = "EmeraldCube",
        Name = "Emerald Spirit Cube",
        ShortName = "Emerald Cube",
        Color = Color3.fromRGB(72, 235, 124),
        BonusATK = 2,
        BonusHP = 18,
        BonusCrit = 0,
        Description = "+2 ATK, +18 MaxHP",
    },
    VoidCube = {
        Id = "VoidCube",
        Name = "Shadow Spirit Cube",
        ShortName = "Shadow Cube",
        Color = Color3.fromRGB(192, 78, 255),
        BonusATK = 5,
        BonusHP = 0,
        BonusCrit = 0.02,
        Description = "+5 ATK, +2% Crit",
    },
}

ItemConfig.SpiritCubeOrder = {
    "FireCube",
    "IceCube",
    "EmeraldCube",
    "VoidCube",
}

ItemConfig.WeaponTemplates = {
    {
        Id = "AdventurerBlade",
        Name = "Adventurer Voxel Blade",
        ClassReq = "Any",
        BaseATK = 6,
        BaseHP = 15,
        BaseCrit = 0.02,
    },
    {
        Id = "TitanGreatsword",
        Name = "Colossus Voxel Greatsword",
        ClassReq = "Warrior",
        BaseATK = 10,
        BaseHP = 25,
        BaseCrit = 0.02,
    },
    {
        Id = "WindrunnerBow",
        Name = "Windrunner Voxel Longbow",
        ClassReq = "Ranger",
        BaseATK = 9,
        BaseHP = 12,
        BaseCrit = 0.04,
    },
    {
        Id = "AstralStaff",
        Name = "Astral Archmage Staff",
        ClassReq = "Mage",
        BaseATK = 11,
        BaseHP = 10,
        BaseCrit = 0.03,
    },
    {
        Id = "NightfallDaggers",
        Name = "Nightfall Twin Blades",
        ClassReq = "Rogue",
        BaseATK = 8,
        BaseHP = 10,
        BaseCrit = 0.06,
    },
    {
        Id = "RoyalSlimeSovereign",
        Name = "Gelatus Sovereign Relic",
        ClassReq = "Any",
        BaseATK = 12,
        BaseHP = 35,
        BaseCrit = 0.04,
    },
}

return table.freeze(ItemConfig)
