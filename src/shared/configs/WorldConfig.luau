--!strict
-- WorldConfig: Starter Village layout, player spawn point & Character Creation stage

local WorldConfig = {}

-- Emberleaf Village: the walled starter village every new hero awakens in.
-- Coordinates match the existing world: Guild Courtyard (north, -Z), Slime Meadow & Boss Ruins (south, +Z).
WorldConfig.Village = {
    Name = "Emberleaf Village",
    Tagline = "A peaceful voxel hamlet at the edge of the Emerald Plains",

    -- Palisade wall bounds (X/Z, inclusive) and gate gaps
    MinX = -44,
    MaxX = 44,
    MinZ = -46,
    MaxZ = 26,
    SouthGateHalfWidth = 6, -- main gate towards the Slime Meadow
    SideGateZ = -4, -- small east / west gates
    SideGateHalfWidth = 4,

    -- Where heroes appear (on the plaza, facing the fountain & Guild Courtyard to the north)
    SpawnPosition = Vector3.new(0, 3, 9),
    SpawnLookAt = Vector3.new(0, 3, -10),
    SpawnScatter = 3.5,

    FountainPosition = Vector3.new(0, 0, -3),
}

-- Floating "Hero's Dawn" islet where new players create their character, far from gameplay
WorldConfig.CreationStage = {
    Position = Vector3.new(0, 160, -420),
    -- Character faces +Z so the creation camera (placed at +Z) sees the front of the hero
    FacingDirection = Vector3.new(0, 0, 1),
}

function WorldConfig.getVillageSpawnCFrame(scatterSeed: number?): CFrame
    local village = WorldConfig.Village
    local rng = Random.new(scatterSeed or os.clock() * 1000)
    local offset = Vector3.new(
        rng:NextNumber(-village.SpawnScatter, village.SpawnScatter),
        0,
        rng:NextNumber(-village.SpawnScatter * 0.5, village.SpawnScatter * 0.5)
    )
    local pos = village.SpawnPosition + offset
    return CFrame.lookAt(pos, Vector3.new(village.SpawnLookAt.X, pos.Y, village.SpawnLookAt.Z))
end

function WorldConfig.getCreationStageCFrame(): CFrame
    local stage = WorldConfig.CreationStage
    local standPos = stage.Position + Vector3.new(0, 3, 0)
    return CFrame.lookAt(standPos, standPos + stage.FacingDirection)
end

return table.freeze(WorldConfig)
