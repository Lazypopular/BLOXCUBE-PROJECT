--!strict
-- InventoryHandler: Server-Side RemoteEvent Handler & Payload Sanitizer for Potions, Loot, Spirit Cubes & Pets

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemConfig = require(ReplicatedStorage.configs.ItemConfig)
local PetConfig = require(ReplicatedStorage.configs.PetConfig)
local Validator = require(ReplicatedStorage.modules.Validator)
local Network = require(ReplicatedStorage.network)
local PlayerService = require(script.Parent.Parent.services.PlayerService)

local InventoryHandler = {}

function InventoryHandler.init()
    local requestUsePotion = Network.getEvent("RequestUsePotion")
    local requestAttachCube = Network.getEvent("RequestAttachCube")
    local requestEquipItem = Network.getEvent("RequestEquipItem")
    local requestBuyPotion = Network.getEvent("RequestBuyPotion")
    local requestSelectPet = Network.getEvent("RequestSelectPet")
    local requestToggleMount = Network.getEvent("RequestToggleMount")
    local requestToggleGlider = Network.getEvent("RequestToggleGlider")

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

    requestSelectPet.OnServerEvent:Connect(function(player: Player, petId: any)
        if not Validator.isKeyInTable(petId, PetConfig.Pets) then
            return
        end
        PlayerService.selectOrTamePet(player, petId :: string)
    end)

    requestToggleMount.OnServerEvent:Connect(function(player: Player)
        PlayerService.toggleMount(player)
    end)

    requestToggleGlider.OnServerEvent:Connect(function(player: Player, wantGlide: any)
        if wantGlide ~= nil and not Validator.isBoolean(wantGlide) then
            return
        end
        PlayerService.toggleGlider(player, wantGlide :: boolean?)
    end)
end

return table.freeze(InventoryHandler)
