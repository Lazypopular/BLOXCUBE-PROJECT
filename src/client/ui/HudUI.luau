--!strict
-- HudUI: Cube World Status Bars, Quest Tracker, Combat Skill Bar & Character/Outfit Customizer

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local CharacterConfig = require(ReplicatedStorage.configs.CharacterConfig)
local CombatConfig = require(ReplicatedStorage.configs.CombatConfig)
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
    statusCard.Size = UDim2.new(0, 300, 0, 148)
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
    headerLabel.TextSize = 13
    headerLabel.TextColor3 = Color3.fromRGB(245, 208, 96)
    headerLabel.TextXAlignment = Enum.TextXAlignment.Left
    headerLabel.Text = "LV. 1  [Novice]   |   Gold: 0"
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
    questCard.Size = UDim2.new(0, 310, 0, 86)
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
    questProgLabel.Text = "Tip: Attack Dummies/Slimes with LMB to build MP!"
    questProgLabel.Parent = questCard

    -- 3. Top-Center Toast Notification Banner
    local toastBanner = Instance.new("Frame")
    toastBanner.Name = "ToastBanner"
    toastBanner.Size = UDim2.new(0, 420, 0, 58)
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
    bottomBar.Size = UDim2.new(0, 760, 0, 54)
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
    combatInfoText.Text = "[LMB] Combo Attack (+MP)   |   [RMB / F] Special Attack (35 MP)"
    combatInfoText.Parent = bottomBar

    local hintsText = Instance.new("TextLabel")
    hintsText.Size = UDim2.new(1, -16, 0, 20)
    hintsText.Position = UDim2.new(0, 8, 0, 28)
    hintsText.BackgroundTransparency = 1
    hintsText.Font = Enum.Font.GothamBold
    hintsText.TextSize = 11
    hintsText.TextColor3 = Color3.fromRGB(198, 208, 228)
    hintsText.Text =
        "[Shift] Sprint   |   [Q / Ctrl] Dodge Roll   |   [E] Talk to Class Master   |   [C] Appearance & Outfit   |   [Alt / V] Cursor"
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
        local exp = (localPlayer:GetAttribute("Exp") :: number?) or 0
        local maxExp = (localPlayer:GetAttribute("MaxExp") :: number?) or 100
        local gold = (localPlayer:GetAttribute("Gold") :: number?) or 0
        local jobClass = (localPlayer:GetAttribute("JobClass") :: string?) or "Novice"
        local isDodging = localPlayer:GetAttribute("IsDodging") == true

        local classEntry = CharacterConfig.JobClasses[jobClass] or CharacterConfig.JobClasses.Novice
        local combatSpec = CombatConfig.Classes[jobClass] or CombatConfig.Classes.Novice

        headerLabel.Text = string.format("LV. %d  [%s]   |   Gold: %d", level, classEntry.DisplayName, gold)
        dodgeBadge.Visible = isDodging
        crosshair.Visible = CameraController.isMouseLocked()

        combatInfoText.Text = string.format(
            "[LMB] %s (+%d MP)   |   [RMB / F] %s (%d MP)",
            combatSpec.WeaponName,
            combatSpec.MPGainPerHit,
            combatSpec.SpecialName,
            combatSpec.SpecialMPCost
        )

        local qTitle = (localPlayer:GetAttribute("QuestTitle") :: string?) or "Speak to a Class Master NPC"
        local qDesc = (localPlayer:GetAttribute("QuestDesc") :: string?) or ""
        local qProg = (localPlayer:GetAttribute("QuestProgress") :: number?) or 0
        local qReq = (localPlayer:GetAttribute("QuestRequired") :: number?) or 0

        questTitleLabel.Text = qTitle
        questDescLabel.Text = qDesc
        if qReq > 0 then
            questProgLabel.Text = string.format("Trial Progress:  %d / %d", qProg, qReq)
        else
            questProgLabel.Text = "Tip: Attack Dummies/Slimes (South) or Talk to Masters (North)"
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
