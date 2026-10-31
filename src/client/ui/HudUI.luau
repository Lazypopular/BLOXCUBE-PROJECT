--!strict
-- HudUI: Cube World Style Status Bars (HP, MP, Stamina), Crosshair & Character/Outfit Customizer

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local CharacterConfig = require(ReplicatedStorage.configs.CharacterConfig)
local GameConfig = require(ReplicatedStorage.configs.GameConfig)
local Network = require(ReplicatedStorage.network)
local CameraController = require(script.Parent.Parent.controllers.CameraController)

local localPlayer = Players.LocalPlayer

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
    posY: number
): (Frame, TextLabel)
    local container = Instance.new("Frame")
    container.Name = name .. "Container"
    container.Size = UDim2.new(1, -24, 0, 22)
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
    text.TextSize = 12
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
    statusCard.Size = UDim2.new(0, 286, 0, 128)
    statusCard.Position = UDim2.new(0, 20, 0, 20)
    statusCard.BackgroundColor3 = Color3.fromRGB(16, 18, 26)
    statusCard.BackgroundTransparency = 0.12
    statusCard.BorderSizePixel = 0
    statusCard.Parent = screenGui
    createCorner(statusCard, 6)
    createStroke(statusCard, Color3.fromRGB(82, 94, 120), 2)

    local headerLabel = Instance.new("TextLabel")
    headerLabel.Name = "HeaderLabel"
    headerLabel.Size = UDim2.new(1, -24, 0, 24)
    headerLabel.Position = UDim2.new(0, 12, 0, 8)
    headerLabel.BackgroundTransparency = 1
    headerLabel.Font = Enum.Font.GothamBlack
    headerLabel.TextSize = 14
    headerLabel.TextColor3 = Color3.fromRGB(245, 208, 96)
    headerLabel.TextXAlignment = Enum.TextXAlignment.Left
    headerLabel.Text = "BLOXCUBE  |  LV. 1  [Novice]"
    headerLabel.Parent = statusCard

    local dodgeBadge = Instance.new("TextLabel")
    dodgeBadge.Name = "DodgeBadge"
    dodgeBadge.Size = UDim2.new(0, 68, 0, 18)
    dodgeBadge.Position = UDim2.new(1, -80, 0, 11)
    dodgeBadge.BackgroundColor3 = Color3.fromRGB(65, 195, 255)
    dodgeBadge.Font = Enum.Font.GothamBlack
    dodgeBadge.TextSize = 10
    dodgeBadge.TextColor3 = Color3.fromRGB(12, 16, 24)
    dodgeBadge.Text = "I-FRAME"
    dodgeBadge.Visible = false
    dodgeBadge.Parent = statusCard
    createCorner(dodgeBadge, 4)

    local hpFill, hpText = createStatBar(statusCard, "HP", "HP  120 / 120", Color3.fromRGB(220, 56, 64), 36)
    local mpFill, mpText = createStatBar(statusCard, "MP", "MP  0 / 100", Color3.fromRGB(58, 148, 238), 64)
    local stamFill, stamText = createStatBar(statusCard, "Stamina", "STA  100 / 100", Color3.fromRGB(238, 184, 48), 92)

    -- 2. Center Voxel Crosshair
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

    -- 3. Bottom Controls & Customization Toggle Bar
    local bottomBar = Instance.new("Frame")
    bottomBar.Name = "BottomHints"
    bottomBar.Size = UDim2.new(0, 640, 0, 34)
    bottomBar.AnchorPoint = Vector2.new(0.5, 1)
    bottomBar.Position = UDim2.new(0.5, 0, 1, -16)
    bottomBar.BackgroundColor3 = Color3.fromRGB(16, 18, 26)
    bottomBar.BackgroundTransparency = 0.18
    bottomBar.BorderSizePixel = 0
    bottomBar.Parent = screenGui
    createCorner(bottomBar, 6)
    createStroke(bottomBar, Color3.fromRGB(68, 78, 102), 1.5)

    local hintsText = Instance.new("TextLabel")
    hintsText.Size = UDim2.new(1, -16, 1, 0)
    hintsText.Position = UDim2.new(0, 8, 0, 0)
    hintsText.BackgroundTransparency = 1
    hintsText.Font = Enum.Font.GothamBold
    hintsText.TextSize = 12
    hintsText.TextColor3 = Color3.fromRGB(220, 228, 242)
    hintsText.Text =
        "[Shift] Sprint   |   [Q / Ctrl] Dodge Roll   |   [C] Appearance & Outfit   |   [Alt / V] Mouse Cursor"
    hintsText.Parent = bottomBar

    -- 4. Character Appearance & Starter Outfit Customizer Panel ([C])
    local customPanel = Instance.new("Frame")
    customPanel.Name = "CustomizerPanel"
    customPanel.Size = UDim2.new(0, 340, 0, 310)
    customPanel.AnchorPoint = Vector2.new(1, 0.5)
    customPanel.Position = UDim2.new(1, -24, 0.5, 0)
    customPanel.BackgroundColor3 = Color3.fromRGB(18, 21, 30)
    customPanel.BackgroundTransparency = 0.06
    customPanel.BorderSizePixel = 0
    customPanel.Visible = false
    customPanel.Parent = screenGui
    createCorner(customPanel, 8)
    createStroke(customPanel, Color3.fromRGB(238, 184, 48), 2)

    local panelTitle = Instance.new("TextLabel")
    panelTitle.Size = UDim2.new(1, -24, 0, 28)
    panelTitle.Position = UDim2.new(0, 12, 0, 10)
    panelTitle.BackgroundTransparency = 1
    panelTitle.Font = Enum.Font.GothamBlack
    panelTitle.TextSize = 15
    panelTitle.TextColor3 = Color3.fromRGB(245, 208, 96)
    panelTitle.TextXAlignment = Enum.TextXAlignment.Left
    panelTitle.Text = "CHARACTER & OUTFIT CUSTOMIZER"
    panelTitle.Parent = customPanel

    local panelSub = Instance.new("TextLabel")
    panelSub.Size = UDim2.new(1, -24, 0, 18)
    panelSub.Position = UDim2.new(0, 12, 0, 34)
    panelSub.BackgroundTransparency = 1
    panelSub.Font = Enum.Font.GothamMedium
    panelSub.TextSize = 11
    panelSub.TextColor3 = Color3.fromRGB(165, 176, 198)
    panelSub.TextXAlignment = Enum.TextXAlignment.Left
    panelSub.Text = "Customize Appearance & Novice Starter Outfit"
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

    local function syncAppearanceToServer()
        Network.getEvent("RequestUpdateAppearance"):FireServer(
            skinList[skinIdx],
            eyeList[eyeIdx],
            hairStyleList[hairStyleIdx],
            hairColorList[hairColorIdx],
            outfitList[outfitIdx]
        )
    end

    local function createSelectorRow(
        rowTitle: string,
        posY: number,
        getDisplayValue: () -> string,
        onStep: (delta: number) -> ()
    )
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -24, 0, 38)
        row.Position = UDim2.new(0, 12, 0, posY)
        row.BackgroundColor3 = Color3.fromRGB(28, 33, 46)
        row.BorderSizePixel = 0
        row.Parent = customPanel
        createCorner(row, 6)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 108, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.TextSize = 12
        label.TextColor3 = Color3.fromRGB(205, 214, 232)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Text = rowTitle
        label.Parent = row

        local valLabel = Instance.new("TextLabel")
        valLabel.Size = UDim2.new(0, 132, 1, 0)
        valLabel.Position = UDim2.new(0, 146, 0, 0)
        valLabel.BackgroundTransparency = 1
        valLabel.Font = Enum.Font.GothamBold
        valLabel.TextSize = 12
        valLabel.TextColor3 = Color3.fromRGB(255, 230, 128)
        valLabel.Text = getDisplayValue()
        valLabel.Parent = row

        local prevBtn = Instance.new("TextButton")
        prevBtn.Size = UDim2.new(0, 26, 0, 26)
        prevBtn.Position = UDim2.new(0, 116, 0.5, -13)
        prevBtn.BackgroundColor3 = Color3.fromRGB(48, 56, 76)
        prevBtn.Font = Enum.Font.GothamBlack
        prevBtn.TextSize = 14
        prevBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        prevBtn.Text = "<"
        prevBtn.Parent = row
        createCorner(prevBtn, 4)

        local nextBtn = Instance.new("TextButton")
        nextBtn.Size = UDim2.new(0, 26, 0, 26)
        nextBtn.Position = UDim2.new(1, -34, 0.5, -13)
        nextBtn.BackgroundColor3 = Color3.fromRGB(48, 56, 76)
        nextBtn.Font = Enum.Font.GothamBlack
        nextBtn.TextSize = 14
        nextBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        nextBtn.Text = ">"
        nextBtn.Parent = row
        createCorner(nextBtn, 4)

        prevBtn.Activated:Connect(function()
            onStep(-1)
            valLabel.Text = getDisplayValue()
            syncAppearanceToServer()
        end)

        nextBtn.Activated:Connect(function()
            onStep(1)
            valLabel.Text = getDisplayValue()
            syncAppearanceToServer()
        end)
    end

    createSelectorRow("Race / Skin", 62, function()
        local key = skinList[skinIdx]
        return CharacterConfig.SkinTones[key].Name
    end, function(delta)
        skinIdx = ((skinIdx - 1 + delta) % #skinList) + 1
    end)

    createSelectorRow("Eye Color", 106, function()
        local key = eyeList[eyeIdx]
        return CharacterConfig.EyeColors[key].Name
    end, function(delta)
        eyeIdx = ((eyeIdx - 1 + delta) % #eyeList) + 1
    end)

    createSelectorRow("Hair Style", 150, function()
        return hairStyleList[hairStyleIdx]
    end, function(delta)
        hairStyleIdx = ((hairStyleIdx - 1 + delta) % #hairStyleList) + 1
    end)

    createSelectorRow("Hair Color", 194, function()
        local key = hairColorList[hairColorIdx]
        return CharacterConfig.HairColors[key].Name
    end, function(delta)
        hairColorIdx = ((hairColorIdx - 1 + delta) % #hairColorList) + 1
    end)

    createSelectorRow("Outfit Style", 244, function()
        local key = outfitList[outfitIdx]
        return CharacterConfig.StarterOutfits[key].Name
    end, function(delta)
        outfitIdx = ((outfitIdx - 1 + delta) % #outfitList) + 1
    end)

    local function toggleCustomPanel()
        customPanel.Visible = not customPanel.Visible
        CameraController.setUIPanelOpen(customPanel.Visible)
    end

    UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
        if gameProcessed then
            return
        end
        if input.KeyCode == Enum.KeyCode.C then
            toggleCustomPanel()
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
        local jobClass = (localPlayer:GetAttribute("JobClass") :: string?) or "Novice"
        local isDodging = localPlayer:GetAttribute("IsDodging") == true

        local classEntry = CharacterConfig.JobClasses[jobClass] or CharacterConfig.JobClasses.Novice
        headerLabel.Text = string.format("BLOXCUBE  |  LV. %d  [%s]", level, classEntry.DisplayName)
        dodgeBadge.Visible = isDodging
        crosshair.Visible = CameraController.isMouseLocked()

        local hpRatio = math.clamp(hp / math.max(1, maxHp), 0, 1)
        local mpRatio = math.clamp(mp / math.max(1, maxMp), 0, 1)
        local stamRatio = math.clamp(stamina / math.max(1, maxStamina), 0, 1)

        local lerpFactor = math.min(1, dt * 18)
        hpFill.Size = hpFill.Size:Lerp(UDim2.new(hpRatio, 0, 1, 0), lerpFactor)
        mpFill.Size = mpFill.Size:Lerp(UDim2.new(mpRatio, 0, 1, 0), lerpFactor)
        stamFill.Size = stamFill.Size:Lerp(UDim2.new(stamRatio, 0, 1, 0), lerpFactor)

        if stamina < GameConfig.Stamina.DodgeCost then
            stamFill.BackgroundColor3 = Color3.fromRGB(225, 96, 48)
        else
            stamFill.BackgroundColor3 = Color3.fromRGB(238, 184, 48)
        end

        hpText.Text = string.format("HP   %d / %d", math.floor(hp + 0.5), maxHp)
        mpText.Text = string.format("MP   %d / %d", math.floor(mp + 0.5), maxMp)
        stamText.Text = string.format("STA  %d / %d", math.floor(stamina + 0.5), maxStamina)
    end)
end

return table.freeze(HudUI)
