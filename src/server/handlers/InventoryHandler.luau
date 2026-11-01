--!strict
-- InventoryHandler: Server-Side RemoteEvent Handler & Payload Sanitizer for Potions, Loot & Spirit Cubes

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemConfig = require(ReplicatedStorage.configs.ItemConfig)
local Validator = require(ReplicatedStorage.modules.Validator)
local Network = require(ReplicatedStorage.network)
local PlayerService = require(script.Parent.Parent.services.PlayerService)

local InventoryHandler = {}

function InventoryHandler.init()
    local requestUsePotion = Network.getEvent("RequestUsePotion")
    local requestAttachCube = Network.getEvent("RequestAttachCube")
    local requestEquipItem = Network.getEvent("RequestEquipItem")
    local requestBuyPotion = Network.getEvent("RequestBuyPotion")

    requestUsePotion.OnServerEvent:Connect(function(player: Player)
        PlayerService.usePotion(player)
    end)

    requestAttachCube.OnServerEvent:Connect(function(player: Player, cubeType: any)
        if not Validator.isKeyInTable(cubeType, ItemConfig.SpiritCubes) then
            return
        end
        PlayerService.attachSpiritCube(player, cubeType :: string)
    end)

    requestEquipItem.OnServerEvent:Connect(function(player: Player, itemUid: any)
        if not Validator.isFiniteNumber(itemUid) then
            return
        end
        PlayerService.equipInventoryItem(player, math.floor(itemUid :: number))
    end)

    requestBuyPotion.OnServerEvent:Connect(function(player: Player)
        PlayerService.buyPotionWithGold(player)
    end)
end

return table.freeze(InventoryHandler)
