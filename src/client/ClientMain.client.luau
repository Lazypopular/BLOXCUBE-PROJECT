--!strict
-- BLOXCUBE Client Entry Point (Bootstrap Controllers & UI)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.network)
local CameraController = require(script.Parent.controllers.CameraController)
local CombatController = require(script.Parent.controllers.CombatController)
local MovementController = require(script.Parent.controllers.MovementController)
local VoxelAnimatorController = require(script.Parent.controllers.VoxelAnimatorController)
local HudUI = require(script.Parent.ui.HudUI)

Network.init()
CameraController.init()
MovementController.init()
CombatController.init()
VoxelAnimatorController.init()
HudUI.init()

print("[BLOXCUBE] Client initialized (Phase 3: Action Combat, Spirit Cube Forge, Loot & Voxel HUD).")
