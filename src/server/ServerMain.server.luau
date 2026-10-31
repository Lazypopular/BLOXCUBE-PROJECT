--!strict
-- BLOXCUBE Server Entry Point (Bootstrap Services & Handlers)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.network)
local CombatHandler = require(script.Parent.handlers.CombatHandler)
local MovementHandler = require(script.Parent.handlers.MovementHandler)
local ClassMasterService = require(script.Parent.services.ClassMasterService)
local MobService = require(script.Parent.services.MobService)
local PlayerService = require(script.Parent.services.PlayerService)

Network.init()
PlayerService.init()
MobService.init()
ClassMasterService.init()
MovementHandler.init()
CombatHandler.init()

print("[BLOXCUBE] Server initialized (Phase 2: Action Combat, Class Masters & Mobs).")
