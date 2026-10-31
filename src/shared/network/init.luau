--!strict
-- Centralized Network Remote Registry for BLOXCUBE

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Network = {}

local FOLDER_NAME = "BloxcubeNetwork"

local REMOTE_EVENTS = {
    "RequestSprint",
    "RequestDodge",
    "DodgePerformed",
    "RequestUpdateAppearance",
    "StateSynced",
}

local networkFolder: Folder? = nil

local function getOrCreateFolder(): Folder
    if networkFolder and networkFolder.Parent then
        return networkFolder
    end

    if RunService:IsServer() then
        local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
        if existing and existing:IsA("Folder") then
            networkFolder = existing
            return existing
        end

        local folder = Instance.new("Folder")
        folder.Name = FOLDER_NAME
        folder.Parent = ReplicatedStorage

        for _, eventName in REMOTE_EVENTS do
            local remote = Instance.new("RemoteEvent")
            remote.Name = eventName
            remote.Parent = folder
        end

        networkFolder = folder
        return folder
    else
        local folder = ReplicatedStorage:WaitForChild(FOLDER_NAME, 15) :: Folder
        networkFolder = folder
        return folder
    end
end

function Network.init()
    getOrCreateFolder()
end

function Network.getEvent(name: string): RemoteEvent
    local folder = getOrCreateFolder()
    if RunService:IsServer() then
        local remote = folder:FindFirstChild(name)
        if remote and remote:IsA("RemoteEvent") then
            return remote
        end
        local created = Instance.new("RemoteEvent")
        created.Name = name
        created.Parent = folder
        return created
    else
        return folder:WaitForChild(name, 10) :: RemoteEvent
    end
end

return table.freeze(Network)
