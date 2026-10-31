--!strict
-- Shared Game Constants & Balance Configuration for BLOXCUBE

local GameConfig = {
    GameName = "BLOXCUBE",
    Version = "0.1.0",
    Classes = {
        "Warrior",
        "Ranger",
        "Mage",
        "Rogue",
    },
}

return table.freeze(GameConfig)
