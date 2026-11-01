--!strict
-- Centralized Network Registry (RemoteEvents & RemoteFunctions)
-- All Client <-> Server communication must route through this module.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CONTAINER_NAME = "BloxcubeNetwork"

local EVENT_NAMES = {
    "RequestSprint",
    "RequestDodge",
    "DodgePerformed",
    "RequestUpdateAppearance",
    "StateSynced",
    "RequestAttack",
    "CombatVFX",
    "DamageNumber",
    "QuestNotification",
    "RequestUsePotion",
    "RequestAttachCube",
    "RequestEquipItem",
    "RequestBuyPotion",
    "InventorySynced",
    "OpenForgeUI",
}

local Network = {}

local function getOrCreateContainer(): Folder
    if RunService:IsServer() then
        local existing = ReplicatedStorage:FindFirstChild(CONTAINER_NAME)
        if existing and existing:IsA("Folder") then
            return existing
        end

        local folder = Instance.new("Folder")
        folder.Name = CONTAINER_NAME
        folder.Parent = ReplicatedStorage
        return folder
    else
        return ReplicatedStorage:WaitForChild(CONTAINER_NAME, 15) :: Folder
    end
end

function Network.init()
    local container = getOrCreateContainer()
    if RunService:IsServer() then
        for _, eventName in EVENT_NAMES do
            if not container:FindFirstChild(eventName) then
                local remote = Instance.new("RemoteEvent")
                remote.Name = eventName
                remote.Parent = container
            end
        end
    else
        for _, eventName in EVENT_NAMES do
            container:WaitForChild(eventName, 15)
        end
    end
end

function Network.getEvent(name: string): RemoteEvent
    local container = getOrCreateContainer()
    if RunService:IsServer() then
        local existing = container:FindFirstChild(name)
        if existing and existing:IsA("RemoteEvent") then
            return existing
        end
        local remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = container
        return remote
    else
        return container:WaitForChild(name, 15) :: RemoteEvent
    end
end

return table.freeze(Network)
