--!strict
-- HudUI: Cube World Status Bars, Quest Tracker, Spirit Cube Weapon Forge ([I]), & Appearance Customizer ([C])

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local CharacterConfig = require(ReplicatedStorage.configs.CharacterConfig)
local CombatConfig = require(ReplicatedStorage.configs.CombatConfig)
local GameConfig = require(ReplicatedStorage.configs.GameConfig)
local ItemConfig = require(ReplicatedStorage.configs.ItemConfig)
local PetConfig = require(ReplicatedStorage.configs.PetConfig)
local Network = require(ReplicatedStorage.network)
local CameraController = require(script.Parent.Parent.controllers.CameraController)

local localPlayer = Players.LocalPlayer

type EquipmentItem = ItemConfig.EquipmentItem

local HudUI = {}

local function createStroke(parent: Instance, color: Color3, thickness: number): UIStroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = thickness
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

local function createCorner(parent: Instance, radius: number): UICorner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

local function createStatBar(
    parent: Instance,
    name: string,
    labelPrefix: string,
    barColor: Color3,
    posY: number,
    height: number?
): (Frame, TextLabel)
    local barHeight = height or 20
    local container = Instance.new("Frame")
    container.Name = name .. "Container"
    container.Size = UDim2.new(1, -24, 0, barHeight)
    container.Position = UDim2.new(0, 12, 0, posY)
    container.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
    container.BorderSizePixel = 0
    container.Parent = parent
    createCorner(container, 4)
    createStroke(container, Color3.fromRGB(58, 66, 84), 1.5)

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(1, 0, 1, 0)
    fill.BackgroundColor3 = barColor
    fill.BorderSizePixel = 0
    fill.Parent = container
    createCorner(fill, 4)

    local shine = Instance.new("Frame")
    shine.Name = "TopHighlight"
    shine.Size = UDim2.new(1, 0, 0.35, 0)
    shine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    shine.BackgroundTransparency = 0.82
    shine.BorderSizePixel = 0
    shine.Parent = fill

    local text = Instance.new("TextLabel")
    text.Name = "ValueText"
    text.Size = UDim2.new(1, -12, 1, 0)
    text.Position = UDim2.new(0, 8, 0, 0)
    text.BackgroundTransparency = 1
    text.Font = Enum.Font.GothamBold
    text.TextSize = 11
    text.TextColor3 = Color3.fromRGB(248, 250, 255)
    text.TextStrokeTransparency = 0.35
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Text = labelPrefix
    text.ZIndex = 3
    text.Parent = container

    return fill, text
end

function HudUI.init()
    local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

    local existingGui = playerGui:FindFirstChild("BloxcubeHUD")
    if existingGui then
        existingGui:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BloxcubeHUD"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    -- 1. Top-Left Cube World Status Card
    local statusCard = Instance.new("Frame")
    statusCard.Name = "StatusCard"
    statusCard.Size = UDim2.new(0, 315, 0, 148)
    statusCard.Position = UDim2.new(0, 20, 0, 20)
    statusCard.BackgroundColor3 = Color3.fromRGB(16, 18, 26)
    statusCard.BackgroundTransparency = 0.12
    statusCard.BorderSizePixel = 0
    statusCard.Parent = screenGui
    createCorner(statusCard, 6)
    createStroke(statusCard, Color3.fromRGB(82, 94, 120), 2)

    local headerLabel = Instance.new("TextLabel")
    headerLabel.Name = "HeaderLabel"
    headerLabel.Size = UDim2.new(1, -24, 0, 22)
    headerLabel.Position = UDim2.new(0, 12, 0, 7)
    headerLabel.BackgroundTransparency = 1
    headerLabel.Font = Enum.Font.GothamBlack
    headerLabel.TextSize = 12
    headerLabel.TextColor3 = Color3.fromRGB(245, 208, 96)
    headerLabel.TextXAlignment = Enum.TextXAlignment.Left
    headerLabel.Text = "LV. 1  [Novice]   |   Gold: 30"
    headerLabel.Parent = statusCard

    local dodgeBadge = Instance.new("TextLabel")
    dodgeBadge.Name = "DodgeBadge"
    dodgeBadge.Size = UDim2.new(0, 68, 0, 18)
    dodgeBadge.Position = UDim2.new(1, -80, 0, 9)
    dodgeBadge.BackgroundColor3 = Color3.fromRGB(65, 195, 255)
    dodgeBadge.Font = Enum.Font.GothamBlack
    dodgeBadge.TextSize = 10
    dodgeBadge.TextColor3 = Color3.fromRGB(12, 16, 24)
    dodgeBadge.Text = "I-FRAME"
    dodgeBadge.Visible = false
    dodgeBadge.Parent = statusCard
    createCorner(dodgeBadge, 4)

    local hpFill, hpText = createStatBar(statusCard, "HP", "HP  120 / 120", Color3.fromRGB(220, 56, 64), 34, 20)
    local mpFill, mpText = createStatBar(statusCard, "MP", "MP  0 / 100", Color3.fromRGB(58, 148, 238), 60, 20)
    local stamFill, stamText =
        createStatBar(statusCard, "Stamina", "STA  100 / 100", Color3.fromRGB(238, 184, 48), 86, 20)
    local expFill, expText = createStatBar(statusCard, "EXP", "EXP  0 / 100", Color3.fromRGB(124, 218, 92), 114, 18)

    -- 2. Top-Right Class Trial / Quest Tracker Card
    local questCard = Instance.new("Frame")
    questCard.Name = "QuestCard"
    questCard.Size = UDim2.new(0, 320, 0, 88)
    questCard.AnchorPoint = Vector2.new(1, 0)
    questCard.Position = UDim2.new(1, -20, 0, 20)
    questCard.BackgroundColor3 = Color3.fromRGB(16, 18, 26)
    questCard.BackgroundTransparency = 0.14
    questCard.BorderSizePixel = 0
    questCard.Parent = screenGui
    createCorner(questCard, 6)
    createStroke(questCard, Color3.fromRGB(215, 175, 72), 1.8)

    local questTitleLabel = Instance.new("TextLabel")
    questTitleLabel.Size = UDim2.new(1, -20, 0, 20)
    questTitleLabel.Position = UDim2.new(0, 10, 0, 8)
    questTitleLabel.BackgroundTransparency = 1
    questTitleLabel.Font = Enum.Font.GothamBlack
    questTitleLabel.TextSize = 12
    questTitleLabel.TextColor3 = Color3.fromRGB(255, 214, 88)
    questTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    questTitleLabel.Text = "Speak to a Class Master NPC"
    questTitleLabel.Parent = questCard

    local questDescLabel = Instance.new("TextLabel")
    questDescLabel.Size = UDim2.new(1, -20, 0, 32)
    questDescLabel.Position = UDim2.new(0, 10, 0, 28)
    questDescLabel.BackgroundTransparency = 1
    questDescLabel.Font = Enum.Font.GothamMedium
    questDescLabel.TextSize = 11
    questDescLabel.TextColor3 = Color3.fromRGB(212, 220, 238)
    questDescLabel.TextWrapped = true
    questDescLabel.TextXAlignment = Enum.TextXAlignment.Left
    questDescLabel.TextYAlignment = Enum.TextYAlignment.Top
    questDescLabel.Text = "Walk North to the Guild Courtyard and press [E] on a Master to start your Class Trial"
    questDescLabel.Parent = questCard

    local questProgLabel = Instance.new("TextLabel")
    questProgLabel.Size = UDim2.new(1, -20, 0, 18)
    questProgLabel.Position = UDim2.new(0, 10, 0, 62)
    questProgLabel.BackgroundTransparency = 1
    questProgLabel.Font = Enum.Font.GothamBold
    questProgLabel.TextSize = 11
    questProgLabel.TextColor3 = Color3.fromRGB(115, 232, 138)
    questProgLabel.TextXAlignment = Enum.TextXAlignment.Left
    questProgLabel.Text = "Boss Arena (Far South)  |  Spirit Forge [I]"
    questProgLabel.Parent = questCard

    -- 3. Top-Center Toast Notification Banner
    local toastBanner = Instance.new("Frame")
    toastBanner.Name = "ToastBanner"
    toastBanner.Size = UDim2.new(0, 440, 0, 58)
    toastBanner.AnchorPoint = Vector2.new(0.5, 0)
    toastBanner.Position = UDim2.new(0.5, 0, 0, 22)
    toastBanner.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
    toastBanner.BackgroundTransparency = 0.06
    toastBanner.BorderSizePixel = 0
    toastBanner.Visible = false
    toastBanner.Parent = screenGui
    createCorner(toastBanner, 8)
    local toastStroke = createStroke(toastBanner, Color3.fromRGB(255, 208, 74), 2)

    local toastTitle = Instance.new("TextLabel")
    toastTitle.Size = UDim2.new(1, -20, 0, 22)
    toastTitle.Position = UDim2.new(0, 10, 0, 6)
    toastTitle.BackgroundTransparency = 1
    toastTitle.Font = Enum.Font.GothamBlack
    toastTitle.TextSize = 14
    toastTitle.TextColor3 = Color3.fromRGB(255, 218, 92)
    toastTitle.Text = ""
    toastTitle.Parent = toastBanner

    local toastSub = Instance.new("TextLabel")
    toastSub.Size = UDim2.new(1, -20, 0, 20)
    toastSub.Position = UDim2.new(0, 10, 0, 30)
    toastSub.BackgroundTransparency = 1
    toastSub.Font = Enum.Font.GothamMedium
    toastSub.TextSize = 12
    toastSub.TextColor3 = Color3.fromRGB(230, 236, 248)
    toastSub.Text = ""
    toastSub.Parent = toastBanner

    local toastToken = 0
    Network.getEvent("QuestNotification").OnClientEvent
        :Connect(function(title: string, message: string, accentColor: Color3)
            toastToken += 1
            local myToken = toastToken
            toastTitle.Text = title
            toastTitle.TextColor3 = accentColor
            toastSub.Text = message
            toastStroke.Color = accentColor
            toastBanner.Visible = true

            task.delay(4.2, function()
                if toastToken == myToken then
                    toastBanner.Visible = false
                end
            end)
        end)

    -- 4. Center Voxel Crosshair
    local crosshair = Instance.new("Frame")
    crosshair.Name = "Crosshair"
    crosshair.Size = UDim2.new(0, 6, 0, 6)
    crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
    crosshair.Position = UDim2.new(0.5, 0, 0.5, 0)
    crosshair.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    crosshair.BackgroundTransparency = 0.2
    crosshair.BorderSizePixel = 0
    crosshair.Parent = screenGui
    createCorner(crosshair, 2)
    createStroke(crosshair, Color3.fromRGB(20, 24, 32), 1)

    -- 5. Bottom Combat Action Bar & Controls
    local bottomBar = Instance.new("Frame")
    bottomBar.Name = "BottomHints"
    bottomBar.Size = UDim2.new(0, 820, 0, 54)
    bottomBar.AnchorPoint = Vector2.new(0.5, 1)
    bottomBar.Position = UDim2.new(0.5, 0, 1, -14)
    bottomBar.BackgroundColor3 = Color3.fromRGB(16, 18, 26)
    bottomBar.BackgroundTransparency = 0.14
    bottomBar.BorderSizePixel = 0
    bottomBar.Parent = screenGui
    createCorner(bottomBar, 6)
    createStroke(bottomBar, Color3.fromRGB(68, 78, 102), 1.5)

    local combatInfoText = Instance.new("TextLabel")
    combatInfoText.Size = UDim2.new(1, -16, 0, 24)
    combatInfoText.Position = UDim2.new(0, 8, 0, 4)
    combatInfoText.BackgroundTransparency = 1
    combatInfoText.Font = Enum.Font.GothamBlack
    combatInfoText.TextSize = 12
    combatInfoText.TextColor3 = Color3.fromRGB(255, 216, 102)
    combatInfoText.Text = "[LMB] Combo (+MP)   |   [RMB / F] Special (35 MP)   |   [1] Heartflower Potion (x3)"
    combatInfoText.Parent = bottomBar

    local hintsText = Instance.new("TextLabel")
    hintsText.Size = UDim2.new(1, -16, 0, 20)
    hintsText.Position = UDim2.new(0, 8, 0, 28)
    hintsText.BackgroundTransparency = 1
    hintsText.Font = Enum.Font.GothamBold
    hintsText.TextSize = 11
    hintsText.TextColor3 = Color3.fromRGB(198, 208, 228)
    hintsText.Text =
        "[Shift] Sprint | [Q] Dodge | [T] Ride Mount | [G] Hang Glider | [P] Pets | [I] Forge & Bag | [C] Appearance | [V] Cursor"
    hintsText.Parent = bottomBar

    -- 6. Character Appearance & Starter Outfit Customizer Panel ([C])
    local customPanel = Instance.new("Frame")
    customPanel.Name = "CustomizerPanel"
    customPanel.Size = UDim2.new(0, 340, 0, 310)
    customPanel.AnchorPoint = Vector2.new(1, 0.5)
    customPanel.Position = UDim2.new(1, -24, 0.5, 20)
    customPanel.BackgroundColor3 = Color3.fromRGB(18, 21, 30)
    customPanel.BackgroundTransparency = 0.06
    customPanel.BorderSizePixel = 0
    customPanel.Visible = false
    customPanel.Parent = screenGui
    createCorner(customPanel, 8)
    createStroke(customPanel, Color3.fromRGB(96, 112, 148), 2)

    local panelTitle = Instance.new("TextLabel")
    panelTitle.Size = UDim2.new(1, -24, 0, 26)
    panelTitle.Position = UDim2.new(0, 12, 0, 10)
    panelTitle.BackgroundTransparency = 1
    panelTitle.Font = Enum.Font.GothamBlack
    panelTitle.TextSize = 14
    panelTitle.TextColor3 = Color3.fromRGB(255, 214, 92)
    panelTitle.TextXAlignment = Enum.TextXAlignment.Left
    panelTitle.Text = "APPEARANCE & STARTER OUTFIT"
    panelTitle.Parent = customPanel

    local panelSub = Instance.new("TextLabel")
    panelSub.Size = UDim2.new(1, -24, 0, 16)
    panelSub.Position = UDim2.new(0, 12, 0, 32)
    panelSub.BackgroundTransparency = 1
    panelSub.Font = Enum.Font.GothamMedium
    panelSub.TextSize = 11
    panelSub.TextColor3 = Color3.fromRGB(165, 178, 205)
    panelSub.TextXAlignment = Enum.TextXAlignment.Left
    panelSub.Text = "Customize physical traits & Novice civilian clothes"
    panelSub.Parent = customPanel

    local skinIdx = 1
    local eyeIdx = 1
    local hairStyleIdx = 1
    local hairColorIdx = 1
    local outfitIdx = 1

    local skinList = CharacterConfig.SkinToneOrder
    local eyeList = CharacterConfig.EyeColorOrder
    local hairStyleList = CharacterConfig.HairStyles
    local hairColorList = CharacterConfig.HairColorOrder
    local outfitList = CharacterConfig.OutfitOrder

    local valueLabels: { [string]: TextLabel } = {}

    local function pushAppearanceUpdate()
        local skinKey = skinList[skinIdx]
        local eyeKey = eyeList[eyeIdx]
        local hairStyleKey = hairStyleList[hairStyleIdx]
        local hairColorKey = hairColorList[hairColorIdx]
        local outfitKey = outfitList[outfitIdx]

        valueLabels.SkinTone.Text = CharacterConfig.SkinTones[skinKey].Name
        valueLabels.EyeColor.Text = CharacterConfig.EyeColors[eyeKey].Name
        valueLabels.HairStyle.Text = hairStyleKey
        valueLabels.HairColor.Text = CharacterConfig.HairColors[hairColorKey].Name
        valueLabels.OutfitStyle.Text = CharacterConfig.StarterOutfits[outfitKey].Name

        Network.getEvent("RequestUpdateAppearance"):FireServer(skinKey, eyeKey, hairStyleKey, hairColorKey, outfitKey)
    end

    local function createSelectorRow(rowKey: string, titleText: string, posY: number, onStep: (delta: number) -> ())
        local row = Instance.new("Frame")
        row.Name = rowKey .. "Row"
        row.Size = UDim2.new(1, -24, 0, 38)
        row.Position = UDim2.new(0, 12, 0, posY)
        row.BackgroundColor3 = Color3.fromRGB(26, 30, 42)
        row.BorderSizePixel = 0
        row.Parent = customPanel
        createCorner(row, 6)
        createStroke(row, Color3.fromRGB(54, 62, 82), 1)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 95, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.TextSize = 12
        label.TextColor3 = Color3.fromRGB(210, 218, 235)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Text = titleText
        label.Parent = row

        local prevBtn = Instance.new("TextButton")
        prevBtn.Name = "PrevBtn"
        prevBtn.Size = UDim2.new(0, 28, 0, 26)
        prevBtn.Position = UDim2.new(0, 108, 0.5, -13)
        prevBtn.BackgroundColor3 = Color3.fromRGB(42, 48, 66)
        prevBtn.Font = Enum.Font.GothamBlack
        prevBtn.TextSize = 13
        prevBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        prevBtn.Text = "<"
        prevBtn.Parent = row
        createCorner(prevBtn, 4)

        local valText = Instance.new("TextLabel")
        valText.Name = "ValueLabel"
        valText.Size = UDim2.new(1, -180, 1, 0)
        valText.Position = UDim2.new(0, 140, 0, 0)
        valText.BackgroundTransparency = 1
        valText.Font = Enum.Font.GothamBold
        valText.TextSize = 12
        valText.TextColor3 = Color3.fromRGB(255, 224, 112)
        valText.Text = ""
        valText.Parent = row
        valueLabels[rowKey] = valText

        local nextBtn = Instance.new("TextButton")
        nextBtn.Name = "NextBtn"
        nextBtn.Size = UDim2.new(0, 28, 0, 26)
        nextBtn.Position = UDim2.new(1, -36, 0.5, -13)
        nextBtn.BackgroundColor3 = Color3.fromRGB(42, 48, 66)
        nextBtn.Font = Enum.Font.GothamBlack
        nextBtn.TextSize = 13
        nextBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        nextBtn.Text = ">"
        nextBtn.Parent = row
        createCorner(nextBtn, 4)

        prevBtn.MouseButton1Click:Connect(function()
            onStep(-1)
            pushAppearanceUpdate()
        end)

        nextBtn.MouseButton1Click:Connect(function()
            onStep(1)
            pushAppearanceUpdate()
        end)
    end

    createSelectorRow("SkinTone", "Race / Skin", 62, function(delta)
        skinIdx = ((skinIdx - 1 + delta) % #skinList) + 1
    end)
    createSelectorRow("EyeColor", "Eye Color", 106, function(delta)
        eyeIdx = ((eyeIdx - 1 + delta) % #eyeList) + 1
    end)
    createSelectorRow("HairStyle", "Hair Style", 150, function(delta)
        hairStyleIdx = ((hairStyleIdx - 1 + delta) % #hairStyleList) + 1
    end)
    createSelectorRow("HairColor", "Hair Color", 194, function(delta)
        hairColorIdx = ((hairColorIdx - 1 + delta) % #hairColorList) + 1
    end)
    createSelectorRow("OutfitStyle", "Outfit Style", 244, function(delta)
        outfitIdx = ((outfitIdx - 1 + delta) % #outfitList) + 1
    end)

    valueLabels.SkinTone.Text = CharacterConfig.SkinTones[skinList[skinIdx]].Name
    valueLabels.EyeColor.Text = CharacterConfig.EyeColors[eyeList[eyeIdx]].Name
    valueLabels.HairStyle.Text = hairStyleList[hairStyleIdx]
    valueLabels.HairColor.Text = CharacterConfig.HairColors[hairColorList[hairColorIdx]].Name
    valueLabels.OutfitStyle.Text = CharacterConfig.StarterOutfits[outfitList[outfitIdx]].Name

    -- 7. Cube World Spirit Cube Weapon Forge & Equipment Bag Panel ([I] or [B])
    local forgePanel = Instance.new("Frame")
    forgePanel.Name = "ForgePanel"
    forgePanel.Size = UDim2.new(0, 410, 0, 445)
    forgePanel.AnchorPoint = Vector2.new(0.5, 0.5)
    forgePanel.Position = UDim2.new(0.5, 0, 0.5, 0)
    forgePanel.BackgroundColor3 = Color3.fromRGB(16, 19, 28)
    forgePanel.BackgroundTransparency = 0.04
    forgePanel.BorderSizePixel = 0
    forgePanel.Visible = false
    forgePanel.Parent = screenGui
    createCorner(forgePanel, 8)
    createStroke(forgePanel, Color3.fromRGB(88, 198, 255), 2)

    local forgeHeader = Instance.new("TextLabel")
    forgeHeader.Size = UDim2.new(1, -60, 0, 24)
    forgeHeader.Position = UDim2.new(0, 14, 0, 10)
    forgeHeader.BackgroundTransparency = 1
    forgeHeader.Font = Enum.Font.GothamBlack
    forgeHeader.TextSize = 14
    forgeHeader.TextColor3 = Color3.fromRGB(98, 220, 255)
    forgeHeader.TextXAlignment = Enum.TextXAlignment.Left
    forgeHeader.Text = "⚒ SPIRIT CUBE WEAPON FORGE & LOOT BAG"
    forgeHeader.Parent = forgePanel

    local closeForgeBtn = Instance.new("TextButton")
    closeForgeBtn.Size = UDim2.new(0, 28, 0, 26)
    closeForgeBtn.Position = UDim2.new(1, -38, 0, 10)
    closeForgeBtn.BackgroundColor3 = Color3.fromRGB(185, 58, 68)
    closeForgeBtn.Font = Enum.Font.GothamBlack
    closeForgeBtn.TextSize = 12
    closeForgeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeForgeBtn.Text = "X"
    closeForgeBtn.Parent = forgePanel
    createCorner(closeForgeBtn, 4)

    local equippedSummary = Instance.new("TextLabel")
    equippedSummary.Name = "EquippedSummary"
    equippedSummary.Size = UDim2.new(1, -28, 0, 42)
    equippedSummary.Position = UDim2.new(0, 14, 0, 38)
    equippedSummary.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
    equippedSummary.Font = Enum.Font.GothamBold
    equippedSummary.TextSize = 12
    equippedSummary.TextColor3 = Color3.fromRGB(255, 224, 102)
    equippedSummary.TextWrapped = true
    equippedSummary.Text =
        "Weapon: ★ Wooden Practice Sword (+0/12 Cubes)\nTotal Bonus: +0 ATK  |  +0 MaxHP  |  +0% Crit"
    equippedSummary.Parent = forgePanel
    createCorner(equippedSummary, 6)
    createStroke(equippedSummary, Color3.fromRGB(64, 76, 102), 1)

    -- Spirit Cube Forge Buttons (4 Cube Types)
    local cubeCountLabels: { [string]: TextLabel } = {}
    for idx, cubeKey in ItemConfig.SpiritCubeOrder do
        local spec = ItemConfig.SpiritCubes[cubeKey]
        local rowY = 86 + (idx - 1) * 38

        local cubeRow = Instance.new("Frame")
        cubeRow.Size = UDim2.new(1, -28, 0, 34)
        cubeRow.Position = UDim2.new(0, 14, 0, rowY)
        cubeRow.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
        cubeRow.BorderSizePixel = 0
        cubeRow.Parent = forgePanel
        createCorner(cubeRow, 5)
        createStroke(cubeRow, spec.Color, 1)

        local cLabel = Instance.new("TextLabel")
        cLabel.Size = UDim2.new(1, -118, 1, 0)
        cLabel.Position = UDim2.new(0, 10, 0, 0)
        cLabel.BackgroundTransparency = 1
        cLabel.Font = Enum.Font.GothamBold
        cLabel.TextSize = 11
        cLabel.TextColor3 = spec.Color
        cLabel.TextXAlignment = Enum.TextXAlignment.Left
        cLabel.Text = string.format("❖ %s (%s) — x0", spec.ShortName, spec.Description)
        cLabel.Parent = cubeRow
        cubeCountLabels[cubeKey] = cLabel

        local attachBtn = Instance.new("TextButton")
        attachBtn.Size = UDim2.new(0, 96, 0, 24)
        attachBtn.Position = UDim2.new(1, -102, 0.5, -12)
        attachBtn.BackgroundColor3 = Color3.fromRGB(42, 92, 138)
        attachBtn.Font = Enum.Font.GothamBlack
        attachBtn.TextSize = 11
        attachBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        attachBtn.Text = "FORGE +1"
        attachBtn.Parent = cubeRow
        createCorner(attachBtn, 4)

        attachBtn.MouseButton1Click:Connect(function()
            Network.getEvent("RequestAttachCube"):FireServer(cubeKey)
        end)
    end

    -- Brew Potion Button inside Forge/Bag Panel
    local brewPotionBtn = Instance.new("TextButton")
    brewPotionBtn.Size = UDim2.new(1, -28, 0, 30)
    brewPotionBtn.Position = UDim2.new(0, 14, 0, 242)
    brewPotionBtn.BackgroundColor3 = Color3.fromRGB(168, 48, 72)
    brewPotionBtn.Font = Enum.Font.GothamBlack
    brewPotionBtn.TextSize = 12
    brewPotionBtn.TextColor3 = Color3.fromRGB(255, 240, 245)
    brewPotionBtn.Text = "♥ Brew Heartflower Potion (-15 Gold)   |   Press [1] to Heal"
    brewPotionBtn.Parent = forgePanel
    createCorner(brewPotionBtn, 5)

    brewPotionBtn.MouseButton1Click:Connect(function()
        Network.getEvent("RequestBuyPotion"):FireServer()
    end)

    local bagTitle = Instance.new("TextLabel")
    bagTitle.Size = UDim2.new(1, -28, 0, 20)
    bagTitle.Position = UDim2.new(0, 14, 0, 278)
    bagTitle.BackgroundTransparency = 1
    bagTitle.Font = Enum.Font.GothamBlack
    bagTitle.TextSize = 12
    bagTitle.TextColor3 = Color3.fromRGB(215, 224, 242)
    bagTitle.TextXAlignment = Enum.TextXAlignment.Left
    bagTitle.Text = "LOOTED WEAPONS & RELICS (Defeat Slimes & Boss):"
    bagTitle.Parent = forgePanel

    local bagContainer = Instance.new("Frame")
    bagContainer.Name = "BagContainer"
    bagContainer.Size = UDim2.new(1, -28, 0, 132)
    bagContainer.Position = UDim2.new(0, 14, 0, 300)
    bagContainer.BackgroundTransparency = 1
    bagContainer.Parent = forgePanel

    local function refreshBagUI(items: { EquipmentItem }, equippedItem: EquipmentItem?)
        bagContainer:ClearAllChildren()

        if #items == 0 then
            local emptyLabel = Instance.new("TextLabel")
            emptyLabel.Size = UDim2.new(1, 0, 0, 40)
            emptyLabel.BackgroundTransparency = 1
            emptyLabel.Font = Enum.Font.GothamMedium
            emptyLabel.TextSize = 11
            emptyLabel.TextColor3 = Color3.fromRGB(145, 155, 178)
            emptyLabel.Text = "No weapons looted yet. Defeat Slimes or King Gelatus (South) to pick up Loot Chests!"
            emptyLabel.TextWrapped = true
            emptyLabel.Parent = bagContainer
            return
        end

        local maxShow = math.min(#items, 4)
        for i = 1, maxShow do
            local item = items[i]
            local rarityInfo = ItemConfig.Rarities[item.Rarity] or ItemConfig.Rarities.Common
            local isEquipped = equippedItem ~= nil and equippedItem.Uid == item.Uid

            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 30)
            row.Position = UDim2.new(0, 0, 0, (i - 1) * 33)
            row.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
            row.BorderSizePixel = 0
            row.Parent = bagContainer
            createCorner(row, 4)
            createStroke(row, rarityInfo.Color, 1)

            local itemText = Instance.new("TextLabel")
            itemText.Size = UDim2.new(1, -90, 1, 0)
            itemText.Position = UDim2.new(0, 8, 0, 0)
            itemText.BackgroundTransparency = 1
            itemText.Font = Enum.Font.GothamBold
            itemText.TextSize = 11
            itemText.TextColor3 = rarityInfo.Color
            itemText.TextXAlignment = Enum.TextXAlignment.Left
            itemText.Text = string.format(
                "%s %s [%s] (+%d ATK, +%d HP)",
                item.Stars,
                item.Name,
                item.ClassReq,
                item.BonusATK,
                item.BonusHP
            )
            itemText.Parent = row

            local eqBtn = Instance.new("TextButton")
            eqBtn.Size = UDim2.new(0, 76, 0, 22)
            eqBtn.Position = UDim2.new(1, -82, 0.5, -11)
            eqBtn.BackgroundColor3 = if isEquipped then Color3.fromRGB(52, 148, 82) else Color3.fromRGB(58, 72, 104)
            eqBtn.Font = Enum.Font.GothamBlack
            eqBtn.TextSize = 10
            eqBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            eqBtn.Text = if isEquipped then "EQUIPPED" else "EQUIP"
            eqBtn.Parent = row
            createCorner(eqBtn, 4)

            eqBtn.MouseButton1Click:Connect(function()
                Network.getEvent("RequestEquipItem"):FireServer(item.Uid)
            end)
        end
    end

    refreshBagUI({}, nil)

    Network.getEvent("InventorySynced").OnClientEvent
        :Connect(function(items: { EquipmentItem }, equippedItem: EquipmentItem?)
            refreshBagUI(items, equippedItem)
        end)

    -- 8. Cube World Voxel Pets & Mounts Panel ([P])
    local petPanel = Instance.new("Frame")
    petPanel.Name = "PetPanel"
    petPanel.Size = UDim2.new(0, 390, 0, 315)
    petPanel.AnchorPoint = Vector2.new(0.5, 0.5)
    petPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
    petPanel.BackgroundColor3 = Color3.fromRGB(16, 19, 28)
    petPanel.BackgroundTransparency = 0.04
    petPanel.BorderSizePixel = 0
    petPanel.Visible = false
    petPanel.Parent = screenGui
    createCorner(petPanel, 8)
    createStroke(petPanel, Color3.fromRGB(128, 235, 165), 2)

    local petHeader = Instance.new("TextLabel")
    petHeader.Size = UDim2.new(1, -60, 0, 24)
    petHeader.Position = UDim2.new(0, 14, 0, 10)
    petHeader.BackgroundTransparency = 1
    petHeader.Font = Enum.Font.GothamBlack
    petHeader.TextSize = 14
    petHeader.TextColor3 = Color3.fromRGB(128, 235, 165)
    petHeader.TextXAlignment = Enum.TextXAlignment.Left
    petHeader.Text = "🐾 VOXEL COMPANIONS & MOUNTS [P]"
    petHeader.Parent = petPanel

    local closePetBtn = Instance.new("TextButton")
    closePetBtn.Size = UDim2.new(0, 28, 0, 26)
    closePetBtn.Position = UDim2.new(1, -38, 0, 10)
    closePetBtn.BackgroundColor3 = Color3.fromRGB(185, 58, 68)
    closePetBtn.Font = Enum.Font.GothamBlack
    closePetBtn.TextSize = 12
    closePetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closePetBtn.Text = "X"
    closePetBtn.Parent = petPanel
    createCorner(closePetBtn, 4)

    local petSub = Instance.new("TextLabel")
    petSub.Size = UDim2.new(1, -28, 0, 18)
    petSub.Position = UDim2.new(0, 14, 0, 34)
    petSub.BackgroundTransparency = 1
    petSub.Font = Enum.Font.GothamMedium
    petSub.TextSize = 11
    petSub.TextColor3 = Color3.fromRGB(190, 205, 228)
    petSub.TextXAlignment = Enum.TextXAlignment.Left
    petSub.Text = "Companions fight beside you! Press [T] to Ride or [G] to Glide."
    petSub.Parent = petPanel

    local petButtons: { [string]: TextButton } = {}
    for idx, petKey in PetConfig.PetOrder do
        local pSpec = PetConfig.Pets[petKey]
        local rowY = 58 + (idx - 1) * 48

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -28, 0, 42)
        row.Position = UDim2.new(0, 14, 0, rowY)
        row.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
        row.BorderSizePixel = 0
        row.Parent = petPanel
        createCorner(row, 6)
        createStroke(row, pSpec.BodyColor, 1)

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, -110, 0, 20)
        nameLbl.Position = UDim2.new(0, 10, 0, 3)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Font = Enum.Font.GothamBlack
        nameLbl.TextSize = 12
        nameLbl.TextColor3 = pSpec.BodyColor
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.Text = string.format("%s (DMG: %d)", pSpec.Name, pSpec.CombatDamage)
        nameLbl.Parent = row

        local descLbl = Instance.new("TextLabel")
        descLbl.Size = UDim2.new(1, -110, 0, 16)
        descLbl.Position = UDim2.new(0, 10, 0, 22)
        descLbl.BackgroundTransparency = 1
        descLbl.Font = Enum.Font.GothamBold
        descLbl.TextSize = 10
        descLbl.TextColor3 = Color3.fromRGB(205, 215, 232)
        descLbl.TextXAlignment = Enum.TextXAlignment.Left
        descLbl.Text = pSpec.Description
        descLbl.Parent = row

        local actionBtn = Instance.new("TextButton")
        actionBtn.Size = UDim2.new(0, 92, 0, 28)
        actionBtn.Position = UDim2.new(1, -98, 0.5, -14)
        actionBtn.BackgroundColor3 = Color3.fromRGB(48, 98, 142)
        actionBtn.Font = Enum.Font.GothamBlack
        actionBtn.TextSize = 10
        actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        actionBtn.Text = "SUMMON"
        actionBtn.Parent = row
        createCorner(actionBtn, 4)
        petButtons[petKey] = actionBtn

        actionBtn.MouseButton1Click:Connect(function()
            Network.getEvent("RequestSelectPet"):FireServer(petKey)
        end)
    end

    local mountToggleBtn = Instance.new("TextButton")
    mountToggleBtn.Size = UDim2.new(1, -28, 0, 34)
    mountToggleBtn.Position = UDim2.new(0, 14, 0, 262)
    mountToggleBtn.BackgroundColor3 = Color3.fromRGB(52, 142, 88)
    mountToggleBtn.Font = Enum.Font.GothamBlack
    mountToggleBtn.TextSize = 12
    mountToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    mountToggleBtn.Text = "🐎 [T] Toggle Mount Riding   |   🪂 [G] Deploy Voxel Hang Glider"
    mountToggleBtn.Parent = petPanel
    createCorner(mountToggleBtn, 5)

    mountToggleBtn.MouseButton1Click:Connect(function()
        Network.getEvent("RequestToggleMount"):FireServer()
    end)

    local function syncUIPanelCursorState()
        CameraController.setUIPanelOpen(customPanel.Visible or forgePanel.Visible or petPanel.Visible)
    end

    local function toggleCustomPanel()
        customPanel.Visible = not customPanel.Visible
        if customPanel.Visible then
            forgePanel.Visible = false
            petPanel.Visible = false
        end
        syncUIPanelCursorState()
    end

    local function toggleForgePanel(forceOpen: boolean?)
        if forceOpen ~= nil then
            forgePanel.Visible = forceOpen
        else
            forgePanel.Visible = not forgePanel.Visible
        end
        if forgePanel.Visible then
            customPanel.Visible = false
            petPanel.Visible = false
        end
        syncUIPanelCursorState()
    end

    local function togglePetPanel(forceOpen: boolean?)
        if forceOpen ~= nil then
            petPanel.Visible = forceOpen
        else
            petPanel.Visible = not petPanel.Visible
        end
        if petPanel.Visible then
            customPanel.Visible = false
            forgePanel.Visible = false
        end
        syncUIPanelCursorState()
    end

    closeForgeBtn.MouseButton1Click:Connect(function()
        toggleForgePanel(false)
    end)

    closePetBtn.MouseButton1Click:Connect(function()
        togglePetPanel(false)
    end)

    Network.getEvent("OpenForgeUI").OnClientEvent:Connect(function()
        toggleForgePanel(true)
    end)

    UserInputService.InputBegan:Connect(function(input: InputObject, _gameProcessed: boolean)
        if UserInputService:GetFocusedTextBox() ~= nil then
            return
        end
        if input.KeyCode == Enum.KeyCode.C then
            toggleCustomPanel()
        elseif input.KeyCode == Enum.KeyCode.I or input.KeyCode == Enum.KeyCode.B then
            toggleForgePanel()
        elseif input.KeyCode == Enum.KeyCode.P then
            togglePetPanel()
        end
    end)

    -- Real-Time HUD Bar Update Loop
    RunService.RenderStepped:Connect(function(dt: number)
        local hp = (localPlayer:GetAttribute("HP") :: number?) or GameConfig.Stats.BaseMaxHP
        local maxHp = (localPlayer:GetAttribute("MaxHP") :: number?) or GameConfig.Stats.BaseMaxHP
        local mp = (localPlayer:GetAttribute("MP") :: number?) or 0
        local maxMp = (localPlayer:GetAttribute("MaxMP") :: number?) or GameConfig.Stats.BaseMaxMP
        local stamina = (localPlayer:GetAttribute("Stamina") :: number?) or GameConfig.Stamina.MaxStamina
        local maxStamina = (localPlayer:GetAttribute("MaxStamina") :: number?) or GameConfig.Stamina.MaxStamina
        local level = (localPlayer:GetAttribute("Level") :: number?) or 1
        local exp = (localPlayer:GetAttribute("Exp") :: number?) or 0
        local maxExp = (localPlayer:GetAttribute("MaxExp") :: number?) or 100
        local gold = (localPlayer:GetAttribute("Gold") :: number?) or 0
        local potions = (localPlayer:GetAttribute("Potions") :: number?) or 0
        local bonusATK = (localPlayer:GetAttribute("BonusATK") :: number?) or 0
        local bonusHP = (localPlayer:GetAttribute("BonusHP") :: number?) or 0
        local bonusCrit = (localPlayer:GetAttribute("BonusCrit") :: number?) or 0
        local weaponCubes = (localPlayer:GetAttribute("WeaponCubeCount") :: number?) or 0
        local eqName = (localPlayer:GetAttribute("EquippedWeaponName") :: string?) or "Wooden Practice Sword"
        local eqStars = (localPlayer:GetAttribute("EquippedWeaponStars") :: string?) or "★"
        local jobClass = (localPlayer:GetAttribute("JobClass") :: string?) or "Novice"
        local isDodging = localPlayer:GetAttribute("IsDodging") == true

        local classEntry = CharacterConfig.JobClasses[jobClass] or CharacterConfig.JobClasses.Novice
        local combatSpec = CombatConfig.Classes[jobClass] or CombatConfig.Classes.Novice

        headerLabel.Text =
            string.format("LV. %d [%s]  |  Gold: %d  |  +%d ATK", level, classEntry.DisplayName, gold, bonusATK)
        dodgeBadge.Visible = isDodging
        crosshair.Visible = CameraController.isMouseLocked()

        combatInfoText.Text = string.format(
            "[LMB] %s (+%d MP)   |   [RMB / F] %s (%d MP)   |   [1] Potion (x%d)",
            combatSpec.WeaponName,
            combatSpec.MPGainPerHit,
            combatSpec.SpecialName,
            combatSpec.SpecialMPCost,
            potions
        )

        equippedSummary.Text = string.format(
            "Weapon: %s %s  [Spirit Cubes: +%d/%d]\nTotal Bonus: +%d ATK   |   +%d MaxHP   |   +%d%% Crit",
            eqStars,
            eqName,
            weaponCubes,
            ItemConfig.MaxWeaponSpiritCubes,
            bonusATK,
            bonusHP,
            bonusCrit
        )

        for _, cubeKey in ItemConfig.SpiritCubeOrder do
            local spec = ItemConfig.SpiritCubes[cubeKey]
            local countAttr = (localPlayer:GetAttribute(cubeKey .. "Count") :: number?) or 0
            local lbl = cubeCountLabels[cubeKey]
            if lbl then
                lbl.Text = string.format("❖ %s (%s) — Owned: x%d", spec.ShortName, spec.Description, countAttr)
            end
        end

        local activePetId = (localPlayer:GetAttribute("ActivePetId") :: string?) or "SlimePet"
        for _, petKey in PetConfig.PetOrder do
            local pSpec = PetConfig.Pets[petKey]
            local owns = localPlayer:GetAttribute("Owns_" .. petKey) == true or pSpec.GoldCost == 0
            local btn = petButtons[petKey]
            if btn then
                if activePetId == petKey then
                    btn.Text = "ACTIVE"
                    btn.BackgroundColor3 = Color3.fromRGB(52, 148, 82)
                elseif owns then
                    btn.Text = "SUMMON"
                    btn.BackgroundColor3 = Color3.fromRGB(48, 98, 142)
                else
                    btn.Text = string.format("TAME (%dG)", pSpec.GoldCost)
                    btn.BackgroundColor3 = Color3.fromRGB(168, 118, 42)
                end
            end
        end

        local qTitle = (localPlayer:GetAttribute("QuestTitle") :: string?) or "Speak to a Class Master NPC"
        local qDesc = (localPlayer:GetAttribute("QuestDesc") :: string?) or ""
        local qProg = (localPlayer:GetAttribute("QuestProgress") :: number?) or 0
        local qReq = (localPlayer:GetAttribute("QuestRequired") :: number?) or 0

        questTitleLabel.Text = qTitle
        questDescLabel.Text = qDesc
        if qReq > 0 then
            questProgLabel.Text = string.format("Trial Progress:  %d / %d", qProg, qReq)
        else
            questProgLabel.Text = "Boss Arena (South)  |  Press [I] for Spirit Cube Weapon Forge"
        end

        local hpRatio = math.clamp(hp / math.max(1, maxHp), 0, 1)
        local mpRatio = math.clamp(mp / math.max(1, maxMp), 0, 1)
        local stamRatio = math.clamp(stamina / math.max(1, maxStamina), 0, 1)
        local expRatio = math.clamp(exp / math.max(1, maxExp), 0, 1)

        local lerpFactor = math.min(1, dt * 18)
        hpFill.Size = hpFill.Size:Lerp(UDim2.new(hpRatio, 0, 1, 0), lerpFactor)
        mpFill.Size = mpFill.Size:Lerp(UDim2.new(mpRatio, 0, 1, 0), lerpFactor)
        stamFill.Size = stamFill.Size:Lerp(UDim2.new(stamRatio, 0, 1, 0), lerpFactor)
        expFill.Size = expFill.Size:Lerp(UDim2.new(expRatio, 0, 1, 0), lerpFactor)

        if stamina < GameConfig.Stamina.DodgeCost then
            stamFill.BackgroundColor3 = Color3.fromRGB(225, 96, 48)
        else
            stamFill.BackgroundColor3 = Color3.fromRGB(238, 184, 48)
        end

        hpText.Text = string.format("HP   %d / %d", math.floor(hp + 0.5), maxHp)
        mpText.Text = string.format("MP   %d / %d", math.floor(mp + 0.5), maxMp)
        stamText.Text = string.format("STA  %d / %d", math.floor(stamina + 0.5), maxStamina)
        expText.Text = string.format("EXP  %d / %d", math.floor(exp + 0.5), maxExp)
    end)
end

return table.freeze(HudUI)
