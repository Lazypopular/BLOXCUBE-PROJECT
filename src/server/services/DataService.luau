--!strict
-- DataService: Server-Authoritative Persistent Profile Storage with Session-Locking (Anti-Dupe)

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local STORE_NAME = "BloxcubePlayerData_v1"
local SESSION_LOCK_EXPIRE_SEC = 1800

local DataService = {}

local dataStore: DataStore? = nil
local studioOfflineFallback = false
local memoryFallback: { [string]: any } = {}

local function getStore(): DataStore?
    if studioOfflineFallback then
        return nil
    end
    if dataStore then
        return dataStore
    end
    local ok, result = pcall(function()
        return DataStoreService:GetDataStore(STORE_NAME)
    end)
    if ok and result then
        dataStore = result
        return result
    end
    studioOfflineFallback = true
    return nil
end

local function getKey(userId: number): string
    return "Player_" .. tostring(userId)
end

function DataService.loadProfile(player: Player): { [string]: any }?
    local key = getKey(player.UserId)
    local store = getStore()
    if not store then
        return memoryFallback[key]
    end

    local loadedData: { [string]: any }? = nil
    local ok, err = pcall(function()
        store:UpdateAsync(key, function(existing: any)
            local data = if type(existing) == "table" then existing else {}
            local now = os.time()
            local currentJobId = if game.JobId ~= "" then game.JobId else "StudioSession"

            -- Session-Lock Check: only steal lock if expired or same server
            if
                data._LockJobId
                and data._LockJobId ~= currentJobId
                and type(data._LockTimestamp) == "number"
                and (now - data._LockTimestamp) < SESSION_LOCK_EXPIRE_SEC
                and not RunService:IsStudio()
            then
                return nil
            end

            data._LockJobId = currentJobId
            data._LockTimestamp = now
            loadedData = data
            return data
        end)
    end)

    if not ok then
        studioOfflineFallback = true
        warn("[BLOXCUBE DataService] Studio/Offline fallback active (" .. tostring(err) .. ")")
        return memoryFallback[key]
    end

    if loadedData then
        memoryFallback[key] = loadedData
    end
    return loadedData
end

function DataService.saveProfile(player: Player, payload: { [string]: any }, releaseLock: boolean)
    local key = getKey(player.UserId)
    memoryFallback[key] = payload

    local store = getStore()
    if not store then
        return
    end

    local currentJobId = if game.JobId ~= "" then game.JobId else "StudioSession"
    pcall(function()
        store:UpdateAsync(key, function(existing: any)
            if type(existing) == "table" and existing._LockJobId and existing._LockJobId ~= currentJobId then
                if not RunService:IsStudio() then
                    return nil
                end
            end

            local toSave = table.clone(payload)
            if releaseLock then
                toSave._LockJobId = nil
                toSave._LockTimestamp = os.time()
            else
                toSave._LockJobId = currentJobId
                toSave._LockTimestamp = os.time()
            end
            return toSave
        end)
    end)
end

return table.freeze(DataService)
