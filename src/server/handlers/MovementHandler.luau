--!strict
-- MovementHandler: Server-Side RemoteEvent Handler & Payload Sanitizer

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterConfig = require(ReplicatedStorage.configs.CharacterConfig)
local Validator = require(ReplicatedStorage.modules.Validator)
local Network = require(ReplicatedStorage.network)
local PlayerService = require(script.Parent.Parent.services.PlayerService)

local MovementHandler = {}

function MovementHandler.init()
    local requestSprint = Network.getEvent("RequestSprint")
    local requestDodge = Network.getEvent("RequestDodge")
    local requestUpdateAppearance = Network.getEvent("RequestUpdateAppearance")
    local requestCompleteCharacterCreation = Network.getEvent("RequestCompleteCharacterCreation")

    requestSprint.OnServerEvent:Connect(function(player: Player, wantSprint: any)
        if not Validator.isBoolean(wantSprint) then
            return
        end
        PlayerService.setSprinting(player, wantSprint)
    end)

    requestDodge.OnServerEvent:Connect(function(player: Player, rawDirection: any)
        if not Validator.isUnitOrZeroVector3(rawDirection) then
            return
        end
        local direction = rawDirection :: Vector3
        local flatDir = Vector3.new(direction.X, 0, direction.Z)
        if flatDir.Magnitude > 0.001 then
            flatDir = flatDir.Unit
        end
        PlayerService.tryDodge(player, flatDir)
    end)

    requestUpdateAppearance.OnServerEvent:Connect(
        function(player: Player, skinTone: any, eyeColor: any, hairStyle: any, hairColor: any, outfitStyle: any)
            if not Validator.isKeyInTable(skinTone, CharacterConfig.SkinTones) then
                return
            end
            if not Validator.isKeyInTable(eyeColor, CharacterConfig.EyeColors) then
                return
            end
            if not Validator.isInArray(hairStyle, CharacterConfig.HairStyles) then
                return
            end
            if not Validator.isKeyInTable(hairColor, CharacterConfig.HairColors) then
                return
            end
            if not Validator.isKeyInTable(outfitStyle, CharacterConfig.StarterOutfits) then
                return
            end

            PlayerService.updateAppearance(
                player,
                skinTone :: string,
                eyeColor :: string,
                hairStyle :: string,
                hairColor :: string,
                outfitStyle :: string
            )
        end
    )

    requestCompleteCharacterCreation.OnServerEvent:Connect(
        function(player: Player, skinTone: any, eyeColor: any, hairStyle: any, hairColor: any, outfitStyle: any)
            if not Validator.isKeyInTable(skinTone, CharacterConfig.SkinTones) then
                return
            end
            if not Validator.isKeyInTable(eyeColor, CharacterConfig.EyeColors) then
                return
            end
            if not Validator.isInArray(hairStyle, CharacterConfig.HairStyles) then
                return
            end
            if not Validator.isKeyInTable(hairColor, CharacterConfig.HairColors) then
                return
            end
            if not Validator.isKeyInTable(outfitStyle, CharacterConfig.StarterOutfits) then
                return
            end

            PlayerService.completeCharacterCreation(
                player,
                skinTone :: string,
                eyeColor :: string,
                hairStyle :: string,
                hairColor :: string,
                outfitStyle :: string
            )
        end
    )
end

return table.freeze(MovementHandler)
