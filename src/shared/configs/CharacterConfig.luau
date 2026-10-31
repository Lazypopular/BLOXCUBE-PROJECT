--!strict
-- Modular Character Customization, Starter Outfits & Job Class Configuration for BLOXCUBE

export type AppearanceData = {
    SkinTone: string,
    EyeColor: string,
    HairStyle: string,
    HairColor: string,
    OutfitStyle: string,
}

local CharacterConfig = {}

CharacterConfig.SkinTones = {
    HumanLight = {
        Name = "Human (Fair)",
        Color = Color3.fromRGB(245, 205, 172),
    },
    HumanTan = {
        Name = "Human (Tan)",
        Color = Color3.fromRGB(212, 158, 118),
    },
    HumanDark = {
        Name = "Human (Deep)",
        Color = Color3.fromRGB(130, 88, 60),
    },
    ElfPale = {
        Name = "Elf (Moonlit)",
        Color = Color3.fromRGB(250, 224, 205),
    },
    OrcGreen = {
        Name = "Goblin / Orc",
        Color = Color3.fromRGB(118, 175, 92),
    },
    FrogTeal = {
        Name = "Frogman",
        Color = Color3.fromRGB(78, 178, 154),
    },
    UndeadAsh = {
        Name = "Undead",
        Color = Color3.fromRGB(156, 166, 178),
    },
}

CharacterConfig.EyeColors = {
    SkyBlue = {
        Name = "Sky Blue",
        Color = Color3.fromRGB(55, 150, 245),
    },
    Emerald = {
        Name = "Emerald",
        Color = Color3.fromRGB(48, 190, 98),
    },
    Crimson = {
        Name = "Crimson",
        Color = Color3.fromRGB(220, 58, 68),
    },
    Amber = {
        Name = "Amber Gold",
        Color = Color3.fromRGB(235, 168, 42),
    },
    Amethyst = {
        Name = "Amethyst",
        Color = Color3.fromRGB(162, 84, 232),
    },
    Charcoal = {
        Name = "Obsidian",
        Color = Color3.fromRGB(42, 46, 54),
    },
}

CharacterConfig.HairColors = {
    Chestnut = {
        Name = "Chestnut Brown",
        Color = Color3.fromRGB(108, 64, 38),
    },
    Raven = {
        Name = "Raven Black",
        Color = Color3.fromRGB(36, 38, 46),
    },
    Golden = {
        Name = "Sun Blonde",
        Color = Color3.fromRGB(235, 192, 76),
    },
    FlameRed = {
        Name = "Flame Red",
        Color = Color3.fromRGB(196, 62, 48),
    },
    Silver = {
        Name = "Silver Frost",
        Color = Color3.fromRGB(220, 226, 238),
    },
    Cobalt = {
        Name = "Cobalt Blue",
        Color = Color3.fromRGB(58, 112, 210),
    },
}

CharacterConfig.HairStyles = {
    "Spiky",
    "Adventurer",
    "Long",
    "Mohawk",
    "Bald",
}

-- Starter Outfits for Novice / Civilian Customization (Layer 3 Base Clothing)
CharacterConfig.StarterOutfits = {
    VillagerTunic = {
        Name = "Villager Tunic",
        ShirtColor = Color3.fromRGB(132, 114, 88),
        VestColor = Color3.fromRGB(94, 72, 50),
        PantsColor = Color3.fromRGB(74, 62, 52),
        AccentColor = Color3.fromRGB(205, 175, 115),
        BootColor = Color3.fromRGB(82, 56, 38),
        HasVest = false,
        HasStrap = false,
        HasScarf = false,
    },
    TravelerVest = {
        Name = "Traveler Vest",
        ShirtColor = Color3.fromRGB(218, 212, 198),
        VestColor = Color3.fromRGB(72, 98, 134),
        PantsColor = Color3.fromRGB(68, 76, 92),
        AccentColor = Color3.fromRGB(218, 182, 98),
        BootColor = Color3.fromRGB(88, 60, 40),
        HasVest = true,
        HasStrap = false,
        HasScarf = true,
    },
    LinenShirt = {
        Name = "Simple Linen",
        ShirtColor = Color3.fromRGB(228, 224, 212),
        VestColor = Color3.fromRGB(168, 152, 128),
        PantsColor = Color3.fromRGB(82, 88, 98),
        AccentColor = Color3.fromRGB(192, 168, 124),
        BootColor = Color3.fromRGB(74, 54, 42),
        HasVest = false,
        HasStrap = false,
        HasScarf = false,
    },
    WoodsmanGarb = {
        Name = "Woodsman Garb",
        ShirtColor = Color3.fromRGB(88, 118, 76),
        VestColor = Color3.fromRGB(116, 78, 48),
        PantsColor = Color3.fromRGB(68, 58, 46),
        AccentColor = Color3.fromRGB(198, 166, 94),
        BootColor = Color3.fromRGB(76, 52, 34),
        HasVest = true,
        HasStrap = true,
        HasScarf = false,
    },
    TownfolkCoat = {
        Name = "Townfolk Coat",
        ShirtColor = Color3.fromRGB(148, 58, 58),
        VestColor = Color3.fromRGB(58, 48, 56),
        PantsColor = Color3.fromRGB(52, 50, 60),
        AccentColor = Color3.fromRGB(228, 188, 86),
        BootColor = Color3.fromRGB(48, 42, 46),
        HasVest = true,
        HasStrap = false,
        HasScarf = true,
    },
}

-- Job Classes (Unlocked later via Class Master NPC Quests)
CharacterConfig.JobClasses = {
    Novice = {
        DisplayName = "Novice",
        PrimaryColor = Color3.fromRGB(132, 114, 88),
        SecondaryColor = Color3.fromRGB(94, 72, 50),
        AccentColor = Color3.fromRGB(205, 175, 115),
        BootColor = Color3.fromRGB(82, 56, 38),
    },
    Warrior = {
        DisplayName = "Warrior",
        PrimaryColor = Color3.fromRGB(178, 52, 48),
        SecondaryColor = Color3.fromRGB(192, 198, 210),
        AccentColor = Color3.fromRGB(235, 186, 64),
        BootColor = Color3.fromRGB(82, 86, 96),
    },
    Ranger = {
        DisplayName = "Ranger",
        PrimaryColor = Color3.fromRGB(64, 138, 72),
        SecondaryColor = Color3.fromRGB(122, 84, 52),
        AccentColor = Color3.fromRGB(214, 178, 92),
        BootColor = Color3.fromRGB(88, 58, 36),
    },
    Mage = {
        DisplayName = "Mage",
        PrimaryColor = Color3.fromRGB(68, 92, 196),
        SecondaryColor = Color3.fromRGB(138, 78, 204),
        AccentColor = Color3.fromRGB(110, 220, 250),
        BootColor = Color3.fromRGB(54, 46, 92),
    },
    Rogue = {
        DisplayName = "Rogue",
        PrimaryColor = Color3.fromRGB(52, 54, 68),
        SecondaryColor = Color3.fromRGB(148, 42, 62),
        AccentColor = Color3.fromRGB(185, 190, 205),
        BootColor = Color3.fromRGB(36, 38, 48),
    },
}

CharacterConfig.DefaultAppearance = {
    SkinTone = "HumanLight",
    EyeColor = "SkyBlue",
    HairStyle = "Spiky",
    HairColor = "Chestnut",
    OutfitStyle = "TravelerVest",
}

CharacterConfig.SkinToneOrder = {
    "HumanLight",
    "HumanTan",
    "HumanDark",
    "ElfPale",
    "OrcGreen",
    "FrogTeal",
    "UndeadAsh",
}

CharacterConfig.EyeColorOrder = {
    "SkyBlue",
    "Emerald",
    "Crimson",
    "Amber",
    "Amethyst",
    "Charcoal",
}

CharacterConfig.HairColorOrder = {
    "Chestnut",
    "Raven",
    "Golden",
    "FlameRed",
    "Silver",
    "Cobalt",
}

CharacterConfig.OutfitOrder = {
    "TravelerVest",
    "VillagerTunic",
    "LinenShirt",
    "WoodsmanGarb",
    "TownfolkCoat",
}

return table.freeze(CharacterConfig)
