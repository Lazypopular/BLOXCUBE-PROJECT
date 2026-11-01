--!strict
-- BLOXCUBE Server Entry Point (Bootstrap Services & Handlers)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.network)
local CombatHandler = require(script.Parent.handlers.CombatHandler)
local InventoryHandler = require(script.Parent.handlers.InventoryHandler)
local MovementHandler = require(script.Parent.handlers.MovementHandler)
local ClassMasterService = require(script.Parent.services.ClassMasterService)
local LootService = require(script.Parent.services.LootService)
local MobService = require(script.Parent.services.MobService)
local PetService = require(script.Parent.services.PetService)
local PlayerService = require(script.Parent.services.PlayerService)
local WorldService = require(script.Parent.services.WorldService)

Network.init()
WorldService.init()
PlayerService.init()
LootService.init()
MobService.init()
PetService.init()
ClassMasterService.init()
MovementHandler.init()
CombatHandler.init()
InventoryHandler.init()

print("[BLOXCUBE] Server initialized (Phase 4: Voxel Pets & Mounts, Hang Glider, Persistence & Complete RPG Loop).")
