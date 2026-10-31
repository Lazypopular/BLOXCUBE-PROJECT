--!strict
-- CombatHandler: Server-Side RemoteEvent Handler & Payload Sanitizer for Action Combat

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Validator = require(ReplicatedStorage.modules.Validator)
local Network = require(ReplicatedStorage.network)
local CombatService = require(script.Parent.Parent.services.CombatService)

local CombatHandler = {}

function CombatHandler.init()
    local requestAttack = Network.getEvent("RequestAttack")

    requestAttack.OnServerEvent:Connect(function(player: Player, attackKind: any, rawDirection: any)
        if attackKind ~= "LMB" and attackKind ~= "RMB" then
            return
        end
        if not Validator.isUnitOrZeroVector3(rawDirection) then
            return
        end

        local direction = rawDirection :: Vector3
        CombatService.performAttack(player, attackKind :: string, direction)
    end)
end

return table.freeze(CombatHandler)
