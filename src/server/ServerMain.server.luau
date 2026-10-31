--!strict
-- BLOXCUBE Server Entry Point (Bootstrap Services & Handlers)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.network)
local MovementHandler = require(script.Parent.handlers.MovementHandler)
local PlayerService = require(script.Parent.services.PlayerService)

Network.init()
PlayerService.init()
MovementHandler.init()

print("[BLOXCUBE] Server initialized (Phase 1: Modular Voxel Rig, Stamina & Movement).")
