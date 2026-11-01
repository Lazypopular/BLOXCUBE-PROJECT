--!strict
-- HudUI: BLOXCUBE HUD & Windows (built on the UITheme design system)
--   HUD:     Player Frame (HP/MP/STA), Status Chips, Quest Tracker, Toasts, Crosshair, Action Hotbar + EXP, Menu Dock
--   Windows: Appearance [C], Spirit Forge & Loot Bag [I]/[B], Companions & Mounts [P], Controls Guide [H]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local CharacterConfig = require(ReplicatedStorage.configs.CharacterConfig)
local CombatConfig = require(ReplicatedStorage.configs.CombatConfig)
local GameConfig = require(ReplicatedStorage.configs.GameConfig)
local ItemConfig = require(ReplicatedStorage.configs.ItemConfig)
local PetConfig = require(ReplicatedStorage.configs.PetConfig)
local Network = require(ReplicatedStorage.network)
local CameraController = require(script.Parent.Parent.controllers.CameraController)
local MovementController = require(script.Parent.Parent.controllers.MovementController)
local UITheme = require(script.Parent.UITheme)

local C = UITheme.Colors
local F = UITheme.Fonts

local localPlayer = Players.LocalPlayer

type EquipmentItem = ItemConfig.EquipmentItem
type Window = UITheme.Window
type Button = UITheme.Button

local HudUI = {}

local function getNumber(name: string, default: number): number
    local value = localPlayer:GetAttribute(name)
    return if type(value) == "number" then value else default
end

local function getString(name: string, default: string): string
    local value = localPlayer:GetAttribute(name)
    return if type(value) == "string" then value else default
end

local function getBool(name: string): boolean
    return localPlayer:GetAttribute(name) == true
end

local function indexOf(list: { string }, value: string?): number
    if value then
        for i, v in list do
            if v == value then
                return i
            end
        end
    end
    return 1
end

-- Small rounded "chip" label used for stats and status badges
local function makeChip(parent: Instance, text: string, color: Color3, props: { [string]: any }?): TextLabel
    local merged: { [string]: any } = {
        Size = UDim2.fromOffset(0, 18),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = color:Lerp(C.Surface, 0.75),
        BackgroundTransparency = 0,
        Font = F.Heavy,
        TextSize = 10,
        TextColor3 = color,
        TextXAlignment = Enum.TextXAlignment.Center,
        Text = text,
        ZIndex = 21,
        Parent = parent,
    }
    if props then
        for k, v in props do
            merged[k] = v
        end
    end
    local chip = UITheme.label(merged)
    UITheme.corner(chip, 9)
    UITheme.stroke(chip, color, 1, 0.55)
    UITheme.padding(chip, 0, 8, 0, 8)
    return chip
end

-- Little voxel "portrait" made from blocks (used for pets and cubes)
local function makeVoxelIcon(parent: Instance, size: number, body: Color3, accent: Color3, eyes: Color3?): Frame
    local box = UITheme.new("Frame", {
        Size = UDim2.fromOffset(size, size),
        BackgroundColor3 = body,
        ZIndex = 21,
        Parent = parent,
    })
    UITheme.corner(box, math.floor(size * 0.18))
    UITheme.gradient(box, Color3.fromRGB(255, 255, 255), Color3.fromRGB(175, 175, 185), 90)
    UITheme.stroke(box, Color3.fromRGB(0, 0, 0), 1.5, 0.45)
    UITheme.new("Frame", {
        Size = UDim2.new(1, 0, 0.26, 0),
        BackgroundColor3 = accent,
        ZIndex = 22,
        Parent = box,
    })
    if eyes then
        local eyeSize = math.max(3, math.floor(size * 0.13))
        for _, xScale in { 0.3, 0.7 } do
            UITheme.new("Frame", {
                Size = UDim2.fromOffset(eyeSize, eyeSize + 2),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(xScale, 0.52),
                BackgroundColor3 = eyes,
                ZIndex = 22,
                Parent = box,
            })
        end
    end
    return box
end

function HudUI.init()
    local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

    local existingGui = playerGui:FindFirstChild("BloxcubeHUD")
    if existingGui then
        existingGui:Destroy()
    end

    local screenGui = UITheme.new("ScreenGui", {
        Name = "BloxcubeHUD",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = playerGui,
    }) :: ScreenGui

    -- Responsive scaling: keep the HUD readable from 720p laptops up to 1440p monitors
    local uiScale = UITheme.new("UIScale", { Scale = 1, Parent = screenGui }) :: UIScale
    local function updateScale()
        local camera = Workspace.CurrentCamera
        if not camera then
            return
        end
        local vp = camera.ViewportSize
        uiScale.Scale = math.clamp(math.min(vp.X / 1366, vp.Y / 768), 0.7, 1.35)
    end
    updateScale()
    if Workspace.CurrentCamera then
        Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
    end

    ---------------------------------------------------------------------------
    -- 1. PLAYER FRAME (Top-Left)
    ---------------------------------------------------------------------------
    local playerFrame = UITheme.panel({
        Name = "PlayerFrame",
        Size = UDim2.fromOffset(330, 128),
        Position = UDim2.fromOffset(16, 16),
        Parent = screenGui,
    })
    UITheme.shadow(playerFrame)

    local levelBadge = UITheme.new("Frame", {
        Name = "LevelBadge",
        Size = UDim2.fromOffset(54, 54),
        Position = UDim2.fromOffset(10, 10),
        BackgroundColor3 = C.Gold,
        Parent = playerFrame,
    })
    UITheme.corner(levelBadge, UITheme.Radius.Medium)
    local levelBadgeGradient = UITheme.gradient(levelBadge, C.Gold, C.GoldDeep, 90)
    UITheme.stroke(levelBadge, Color3.fromRGB(0, 0, 0), 1.5, 0.4)
    UITheme.label({
        Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.fromOffset(0, 5),
        Font = F.Heavy,
        TextSize = 9,
        TextColor3 = Color3.fromRGB(40, 28, 10),
        TextXAlignment = Enum.TextXAlignment.Center,
        Text = "LEVEL",
        Parent = levelBadge,
    })
    local levelNumber = UITheme.label({
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.fromOffset(0, 18),
        Font = F.Display,
        TextSize = 26,
        TextColor3 = Color3.fromRGB(30, 20, 6),
        TextXAlignment = Enum.TextXAlignment.Center,
        Text = "1",
        Parent = levelBadge,
    })

    UITheme.label({
        Name = "PlayerName",
        Size = UDim2.new(1, -86, 0, 22),
        Position = UDim2.fromOffset(74, 9),
        Font = F.Display,
        TextSize = 19,
        Text = localPlayer.DisplayName,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = playerFrame,
    })

    local infoRow = UITheme.new("Frame", {
        Size = UDim2.new(1, -86, 0, 20),
        Position = UDim2.fromOffset(74, 36),
        BackgroundTransparency = 1,
        Parent = playerFrame,
    })
    UITheme.listLayout(infoRow, Enum.FillDirection.Horizontal, 6, nil, Enum.VerticalAlignment.Center)
    local classChip = makeChip(infoRow, "NOVICE", C.Gold, { LayoutOrder = 1, ZIndex = 1 })
    local goldChip = makeChip(infoRow, "● 0", C.Gold, { LayoutOrder = 2, ZIndex = 1 })
    local atkChip = makeChip(infoRow, "⚔ +0", C.Danger, { LayoutOrder = 3, ZIndex = 1 })

    local hpBar = UITheme.statBar(playerFrame, {
        Name = "HPBar",
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.fromOffset(10, 72),
        Top = C.HP,
        Bottom = C.HPDeep,
        Label = "HP",
        TextSize = 12,
    })
    local mpBar = UITheme.statBar(playerFrame, {
        Name = "MPBar",
        Size = UDim2.new(1, -20, 0, 14),
        Position = UDim2.fromOffset(10, 96),
        Top = C.MP,
        Bottom = C.MPDeep,
        Label = "MP",
        TextSize = 10,
    })
    local staminaBar = UITheme.statBar(playerFrame, {
        Name = "StaminaBar",
        Size = UDim2.new(1, -20, 0, 8),
        Position = UDim2.fromOffset(10, 114),
        Top = C.Stamina,
        Bottom = C.StaminaDeep,
        Label = "",
    })

    -- Status chips beneath the player frame (only visible while active)
    local statusRow = UITheme.new("Frame", {
        Name = "StatusChips",
        Size = UDim2.fromOffset(330, 20),
        Position = UDim2.fromOffset(16, 152),
        BackgroundTransparency = 1,
        Parent = screenGui,
    })
    UITheme.listLayout(statusRow, Enum.FillDirection.Horizontal, 6)
    local iframeChip =
        makeChip(statusRow, "✦ I-FRAME", Color3.fromRGB(110, 210, 255), { LayoutOrder = 1, ZIndex = 1 })
    local sprintChip = makeChip(statusRow, "» SPRINT", C.Stamina, { LayoutOrder = 2, ZIndex = 1 })
    local mountChip = makeChip(statusRow, "🐾 RIDING", C.Success, { LayoutOrder = 3, ZIndex = 1 })
    local glideChip = makeChip(statusRow, "✈ GLIDING", Color3.fromRGB(245, 236, 210), { LayoutOrder = 4, ZIndex = 1 })

    ---------------------------------------------------------------------------
    -- 2. QUEST TRACKER (Top-Right)
    ---------------------------------------------------------------------------
    local questCard = UITheme.panel({
        Name = "QuestTracker",
        Size = UDim2.fromOffset(300, 110),
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -16, 0, 16),
        Parent = screenGui,
    })
    UITheme.shadow(questCard)
    UITheme.new("Frame", {
        Name = "AccentStripe",
        Size = UDim2.new(0, 4, 1, -20),
        Position = UDim2.fromOffset(0, 10),
        BackgroundColor3 = C.Gold,
        Parent = questCard,
    })
    UITheme.label({
        Size = UDim2.new(1, -28, 0, 14),
        Position = UDim2.fromOffset(16, 10),
        Font = F.Heavy,
        TextSize = 10,
        TextColor3 = C.TextMuted,
        Text = "◆  CURRENT OBJECTIVE",
        Parent = questCard,
    })
    local questTitle = UITheme.label({
        Size = UDim2.new(1, -28, 0, 20),
        Position = UDim2.fromOffset(16, 26),
        Font = F.Display,
        TextSize = 16,
        TextColor3 = C.Gold,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = "Speak to a Class Master",
        Parent = questCard,
    })
    local questDesc = UITheme.label({
        Size = UDim2.new(1, -28, 0, 30),
        Position = UDim2.fromOffset(16, 48),
        Font = F.Medium,
        TextSize = 11,
        TextColor3 = C.TextMuted,
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        Text = "",
        Parent = questCard,
    })
    local questProgressBar = UITheme.statBar(questCard, {
        Name = "QuestProgress",
        Size = UDim2.new(1, -28, 0, 14),
        Position = UDim2.fromOffset(16, 84),
        Top = C.EXP,
        Bottom = C.EXPDeep,
        Label = "",
        TextSize = 10,
    })
    local questHint = UITheme.label({
        Size = UDim2.new(1, -28, 0, 14),
        Position = UDim2.fromOffset(16, 84),
        Font = F.Bold,
        TextSize = 10,
        TextColor3 = C.Success,
        Text = "Boss Arena lies to the South  •  Forge at the Anvil [E]",
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = questCard,
    })

    ---------------------------------------------------------------------------
    -- 3. TOAST NOTIFICATION (Top-Center, slides in)
    ---------------------------------------------------------------------------
    local TOAST_SHOWN = UDim2.new(0.5, 0, 0, 16)
    local TOAST_HIDDEN = UDim2.new(0.5, 0, 0, -90)
    local toast = UITheme.panel({
        Name = "Toast",
        Size = UDim2.fromOffset(440, 66),
        AnchorPoint = Vector2.new(0.5, 0),
        Position = TOAST_HIDDEN,
        Visible = false,
        ZIndex = 30,
        Parent = screenGui,
    })
    local toastStroke = toast:FindFirstChildOfClass("UIStroke") :: UIStroke
    local toastStripe = UITheme.new("Frame", {
        Size = UDim2.new(0, 6, 1, 0),
        BackgroundColor3 = C.Gold,
        Parent = toast,
    })
    UITheme.corner(toastStripe, UITheme.Radius.Medium)
    local toastTitle = UITheme.label({
        Size = UDim2.new(1, -36, 0, 24),
        Position = UDim2.fromOffset(22, 9),
        Font = F.Display,
        TextSize = 18,
        TextColor3 = C.Gold,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = toast,
    })
    local toastMessage = UITheme.label({
        Size = UDim2.new(1, -36, 0, 22),
        Position = UDim2.fromOffset(22, 34),
        Font = F.Medium,
        TextSize = 12,
        TextColor3 = C.Text,
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = toast,
    })

    local toastToken = 0
    Network.getEvent("QuestNotification").OnClientEvent
        :Connect(function(title: string, message: string, accentColor: Color3)
            toastToken += 1
            local myToken = toastToken
            local accent = if typeof(accentColor) == "Color3" then accentColor else C.Gold
            toastTitle.Text = title
            toastTitle.TextColor3 = accent
            toastMessage.Text = message
            toastStroke.Color = accent
            toastStripe.BackgroundColor3 = accent

            toast.Visible = true
            toast.Position = TOAST_HIDDEN
            UITheme.tween(
                toast,
                TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                { Position = TOAST_SHOWN }
            )

            task.delay(4.2, function()
                if toastToken ~= myToken then
                    return
                end
                local out = UITheme.tween(
                    toast,
                    TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                    { Position = TOAST_HIDDEN }
                )
                out.Completed:Once(function()
                    if toastToken == myToken then
                        toast.Visible = false
                    end
                end)
            end)
        end)

    ---------------------------------------------------------------------------
    -- 4. CROSSHAIR (Center)
    ---------------------------------------------------------------------------
    local crosshair = UITheme.new("Frame", {
        Name = "Crosshair",
        Size = UDim2.fromOffset(22, 22),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 1,
        Parent = screenGui,
    })
    local centerDot = UITheme.new("Frame", {
        Size = UDim2.fromOffset(4, 4),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Parent = crosshair,
    })
    UITheme.stroke(centerDot, Color3.fromRGB(0, 0, 0), 1, 0.4)
    for _, spec in
        {
            { Vector2.new(0.5, 0), UDim2.fromOffset(2, 6) },
            { Vector2.new(0.5, 1), UDim2.fromOffset(2, 6) },
            { Vector2.new(0, 0.5), UDim2.fromOffset(6, 2) },
            { Vector2.new(1, 0.5), UDim2.fromOffset(6, 2) },
        }
    do
        local tickMark = UITheme.new("Frame", {
            Size = spec[2],
            AnchorPoint = spec[1],
            Position = UDim2.fromScale(spec[1].X, spec[1].Y),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.15,
            Parent = crosshair,
        })
        UITheme.stroke(tickMark, Color3.fromRGB(0, 0, 0), 1, 0.5)
    end

    ---------------------------------------------------------------------------
    -- 5. ACTION HOTBAR + EXP BAR (Bottom-Center)
    ---------------------------------------------------------------------------
    local SLOT_SIZE = 58
    local SLOT_GAP = 8
    local SLOT_COUNT = 6
    local hotbarWidth = SLOT_COUNT * SLOT_SIZE + (SLOT_COUNT - 1) * SLOT_GAP + 20

    local hotbar = UITheme.panel({
        Name = "Hotbar",
        Size = UDim2.fromOffset(hotbarWidth, SLOT_SIZE + 20),
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -16),
        Parent = screenGui,
    })
    UITheme.shadow(hotbar)
    local slotRow = UITheme.new("Frame", {
        Size = UDim2.new(1, -20, 1, -20),
        Position = UDim2.fromOffset(10, 10),
        BackgroundTransparency = 1,
        Parent = hotbar,
    })
    UITheme.listLayout(slotRow, Enum.FillDirection.Horizontal, SLOT_GAP)

    type Slot = {
        Frame: Frame,
        Icon: TextLabel,
        Label: TextLabel,
        Badge: TextLabel,
        Cooldown: Frame,
        Stroke: UIStroke,
    }

    local function makeSlot(order: number, key: string, icon: string, labelText: string, accent: Color3): Slot
        local frame = UITheme.new("Frame", {
            Name = "Slot_" .. labelText,
            Size = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE),
            BackgroundColor3 = C.SurfaceRaised,
            LayoutOrder = order,
            ClipsDescendants = false,
            Parent = slotRow,
        })
        UITheme.corner(frame, UITheme.Radius.Medium)
        UITheme.gradient(frame, accent:Lerp(C.SurfaceRaised, 0.7), C.SurfaceSunken, 90)
        local stroke = UITheme.stroke(frame, accent, 1.5, 0.55)

        local iconLabel = UITheme.label({
            Size = UDim2.new(1, 0, 0, 30),
            Position = UDim2.fromOffset(0, 8),
            Font = F.Display,
            TextSize = 24,
            TextColor3 = accent,
            TextXAlignment = Enum.TextXAlignment.Center,
            Text = icon,
            Parent = frame,
        })
        local label = UITheme.label({
            Size = UDim2.new(1, -4, 0, 12),
            Position = UDim2.new(0, 2, 1, -15),
            Font = F.Heavy,
            TextSize = 9,
            TextColor3 = C.TextMuted,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = string.upper(labelText),
            Parent = frame,
        })

        local cooldown = UITheme.new("Frame", {
            Name = "Cooldown",
            Size = UDim2.fromScale(1, 0),
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.fromScale(0, 1),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 0.45,
            ZIndex = 3,
            Parent = frame,
        })
        UITheme.corner(cooldown, UITheme.Radius.Medium)

        UITheme.keycap(frame, key, {
            AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.fromOffset(-5, -7),
            ZIndex = 4,
        })

        local badge = makeChip(frame, "", C.Text, {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 5, 0, -7),
            Size = UDim2.fromOffset(0, 16),
            TextSize = 9,
            Visible = false,
            ZIndex = 4,
        })
        badge.BackgroundColor3 = C.SurfaceSunken

        return {
            Frame = frame,
            Icon = iconLabel,
            Label = label,
            Badge = badge,
            Cooldown = cooldown,
            Stroke = stroke,
        }
    end

    local attackSlot = makeSlot(1, "LMB", "⚔", "Combo", Color3.fromRGB(255, 214, 120))
    local specialSlot = makeSlot(2, "RMB", "✦", "Special", C.MP)
    local potionSlot = makeSlot(3, "1", "♥", "Potion", C.HP)
    local dodgeSlot = makeSlot(4, "Q", "↻", "Dodge", Color3.fromRGB(110, 210, 255))
    local mountSlot = makeSlot(5, "T", "🐾", "Mount", C.Success)
    local glideSlot = makeSlot(6, "G", "✈", "Glider", Color3.fromRGB(245, 236, 210))
    specialSlot.Badge.Visible = true
    potionSlot.Badge.Visible = true

    local expBar = UITheme.statBar(screenGui, {
        Name = "EXPBar",
        Size = UDim2.fromOffset(hotbarWidth, 14),
        Position = UDim2.new(0.5, -hotbarWidth / 2, 1, -(16 + SLOT_SIZE + 20 + 22)),
        Top = C.EXP,
        Bottom = C.EXPDeep,
        Label = "EXP",
        TextSize = 9,
    })
    expBar.Text.TextXAlignment = Enum.TextXAlignment.Center

    ---------------------------------------------------------------------------
    -- 6. WINDOWS
    ---------------------------------------------------------------------------
    local windows: { Window } = {}

    local function registerWindow(win: Window): Window
        table.insert(windows, win)
        win.OnVisibilityChanged(function(isOpen: boolean)
            if isOpen then
                for _, other in windows do
                    if other ~= win and other.IsOpen() then
                        other.Close()
                    end
                end
            end
            local anyOpen = false
            for _, w in windows do
                if w.IsOpen() then
                    anyOpen = true
                    break
                end
            end
            CameraController.setUIPanelOpen(anyOpen)
        end)
        return win
    end

    ---------------------------------------------------------------------------
    -- 6a. APPEARANCE WINDOW [C] (docked right so the character stays visible)
    ---------------------------------------------------------------------------
    local appearanceWin = registerWindow(UITheme.window(screenGui, {
        Name = "AppearanceWindow",
        Title = "Appearance",
        Subtitle = "Customize your look & starter outfit",
        Icon = "☺",
        Hotkey = "C",
        Accent = Color3.fromRGB(255, 176, 92),
        Size = UDim2.fromOffset(360, 470),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -20, 0.5, 0),
    }))
    local appearanceBody = appearanceWin.Body
    UITheme.listLayout(appearanceBody, Enum.FillDirection.Vertical, 8)

    local skinList = CharacterConfig.SkinToneOrder
    local eyeList = CharacterConfig.EyeColorOrder
    local hairStyleList = CharacterConfig.HairStyles
    local hairColorList = CharacterConfig.HairColorOrder
    local outfitList = CharacterConfig.OutfitOrder

    local skinIdx, eyeIdx, hairStyleIdx, hairColorIdx, outfitIdx = 1, 1, 1, 1, 1

    type SelectorRow = { Value: TextLabel, Swatch: Frame }
    local rows: { [string]: SelectorRow } = {}

    local function refreshAppearanceRows()
        local skin = CharacterConfig.SkinTones[skinList[skinIdx]]
        local eye = CharacterConfig.EyeColors[eyeList[eyeIdx]]
        local hairColor = CharacterConfig.HairColors[hairColorList[hairColorIdx]]
        local outfit = CharacterConfig.StarterOutfits[outfitList[outfitIdx]]

        rows.SkinTone.Value.Text = skin.Name
        rows.SkinTone.Swatch.BackgroundColor3 = skin.Color
        rows.EyeColor.Value.Text = eye.Name
        rows.EyeColor.Swatch.BackgroundColor3 = eye.Color
        rows.HairStyle.Value.Text = hairStyleList[hairStyleIdx]
        rows.HairStyle.Swatch.BackgroundColor3 = hairColor.Color
        rows.HairColor.Value.Text = hairColor.Name
        rows.HairColor.Swatch.BackgroundColor3 = hairColor.Color
        rows.OutfitStyle.Value.Text = outfit.Name
        rows.OutfitStyle.Swatch.BackgroundColor3 = outfit.ShirtColor
    end

    local function pushAppearanceUpdate()
        refreshAppearanceRows()
        Network.getEvent("RequestUpdateAppearance"):FireServer(
            skinList[skinIdx],
            eyeList[eyeIdx],
            hairStyleList[hairStyleIdx],
            hairColorList[hairColorIdx],
            outfitList[outfitIdx]
        )
    end

    -- Pull the saved look from server-replicated attributes (so persistence shows correctly)
    local function syncAppearanceFromAttributes()
        skinIdx = indexOf(skinList, localPlayer:GetAttribute("SkinTone") :: string?)
        eyeIdx = indexOf(eyeList, localPlayer:GetAttribute("EyeColor") :: string?)
        hairStyleIdx = indexOf(hairStyleList, localPlayer:GetAttribute("HairStyle") :: string?)
        hairColorIdx = indexOf(hairColorList, localPlayer:GetAttribute("HairColor") :: string?)
        outfitIdx = indexOf(outfitList, localPlayer:GetAttribute("OutfitStyle") :: string?)
        refreshAppearanceRows()
    end

    local function createSelectorRow(order: number, rowKey: string, title: string, onStep: (delta: number) -> ())
        local row = UITheme.new("Frame", {
            Name = rowKey .. "Row",
            Size = UDim2.new(1, 0, 0, 44),
            BackgroundColor3 = C.SurfaceRaised,
            LayoutOrder = order,
            ZIndex = 21,
            Parent = appearanceBody,
        })
        UITheme.corner(row, UITheme.Radius.Medium)
        UITheme.stroke(row, C.BorderSoft, 1)

        UITheme.label({
            Size = UDim2.fromOffset(92, 44),
            Position = UDim2.fromOffset(12, 0),
            Font = F.Heavy,
            TextSize = 10,
            TextColor3 = C.TextMuted,
            Text = string.upper(title),
            ZIndex = 22,
            Parent = row,
        })

        UITheme.button(
            {
                Size = UDim2.fromOffset(30, 30),
                Position = UDim2.new(0, 104, 0.5, -15),
                Text = "‹",
                TextSize = 18,
                ZIndex = 22,
                Parent = row,
            },
            "Secondary",
            function()
                onStep(-1)
                pushAppearanceUpdate()
            end
        )

        local swatch = UITheme.new("Frame", {
            Size = UDim2.fromOffset(14, 14),
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 142, 0.5, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            ZIndex = 22,
            Parent = row,
        })
        UITheme.corner(swatch, 4)
        UITheme.stroke(swatch, Color3.fromRGB(0, 0, 0), 1, 0.3)

        local value = UITheme.label({
            Size = UDim2.new(1, -206, 1, 0),
            Position = UDim2.fromOffset(162, 0),
            Font = F.Bold,
            TextSize = 12,
            TextColor3 = C.Text,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 22,
            Parent = row,
        })

        UITheme.button(
            {
                Size = UDim2.fromOffset(30, 30),
                Position = UDim2.new(1, -38, 0.5, -15),
                Text = "›",
                TextSize = 18,
                ZIndex = 22,
                Parent = row,
            },
            "Secondary",
            function()
                onStep(1)
                pushAppearanceUpdate()
            end
        )

        rows[rowKey] = { Value = value, Swatch = swatch }
    end

    local function wrap(i: number, delta: number, n: number): number
        return ((i - 1 + delta) % n) + 1
    end

    UITheme.sectionHeader(appearanceBody, "Body", { LayoutOrder = 0 })
    createSelectorRow(1, "SkinTone", "Race / Skin", function(d)
        skinIdx = wrap(skinIdx, d, #skinList)
    end)
    createSelectorRow(2, "EyeColor", "Eyes", function(d)
        eyeIdx = wrap(eyeIdx, d, #eyeList)
    end)
    createSelectorRow(3, "HairStyle", "Hair Style", function(d)
        hairStyleIdx = wrap(hairStyleIdx, d, #hairStyleList)
    end)
    createSelectorRow(4, "HairColor", "Hair Color", function(d)
        hairColorIdx = wrap(hairColorIdx, d, #hairColorList)
    end)
    UITheme.sectionHeader(appearanceBody, "Clothing", { LayoutOrder = 5 })
    createSelectorRow(6, "OutfitStyle", "Outfit", function(d)
        outfitIdx = wrap(outfitIdx, d, #outfitList)
    end)

    local appearanceFooter = UITheme.new("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        LayoutOrder = 7,
        ZIndex = 21,
        Parent = appearanceBody,
    })
    UITheme.button(
        {
            Size = UDim2.new(0.5, -4, 1, 0),
            Text = "🎲  RANDOMIZE",
            ZIndex = 22,
            Parent = appearanceFooter,
        },
        "Secondary",
        function()
            skinIdx = math.random(1, #skinList)
            eyeIdx = math.random(1, #eyeList)
            hairStyleIdx = math.random(1, #hairStyleList)
            hairColorIdx = math.random(1, #hairColorList)
            outfitIdx = math.random(1, #outfitList)
            pushAppearanceUpdate()
        end
    )
    UITheme.button(
        {
            Size = UDim2.new(0.5, -4, 1, 0),
            Position = UDim2.new(0.5, 4, 0, 0),
            Text = "✓  DONE",
            ZIndex = 22,
            Parent = appearanceFooter,
        },
        "Success",
        function()
            appearanceWin.Close()
        end
    )

    syncAppearanceFromAttributes()
    appearanceWin.OnVisibilityChanged(function(isOpen: boolean)
        if isOpen then
            syncAppearanceFromAttributes()
        end
    end)

    ---------------------------------------------------------------------------
    -- 6b. SPIRIT FORGE & LOOT BAG WINDOW [I] / [B]
    ---------------------------------------------------------------------------
    local forgeWin = registerWindow(UITheme.window(screenGui, {
        Name = "ForgeWindow",
        Title = "Spirit Forge & Bag",
        Subtitle = "Fuse Spirit Cubes into your weapon  •  Equip looted gear",
        Icon = "⚒",
        Hotkey = "I",
        Accent = Color3.fromRGB(88, 198, 255),
        Size = UDim2.fromOffset(700, 480),
    }))
    local forgeBody = forgeWin.Body

    local forgeLeft = UITheme.new("Frame", {
        Name = "Left",
        Size = UDim2.new(0, 380, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 21,
        Parent = forgeBody,
    })
    local forgeRight = UITheme.new("Frame", {
        Name = "Right",
        Size = UDim2.new(1, -394, 1, 0),
        Position = UDim2.new(0, 394, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 21,
        Parent = forgeBody,
    })

    -- Equipped weapon card
    local weaponCard = UITheme.new("Frame", {
        Name = "WeaponCard",
        Size = UDim2.new(1, 0, 0, 124),
        BackgroundColor3 = C.SurfaceRaised,
        ZIndex = 21,
        Parent = forgeLeft,
    })
    UITheme.corner(weaponCard, UITheme.Radius.Medium)
    local weaponCardStroke = UITheme.stroke(weaponCard, C.Border, 1.5, 0.3)
    local weaponStripe = UITheme.new("Frame", {
        Size = UDim2.new(0, 4, 1, -16),
        Position = UDim2.fromOffset(0, 8),
        BackgroundColor3 = C.Text,
        ZIndex = 22,
        Parent = weaponCard,
    })
    local weaponStars = UITheme.label({
        Size = UDim2.new(1, -24, 0, 14),
        Position = UDim2.fromOffset(14, 8),
        Font = F.Heavy,
        TextSize = 11,
        Text = "★",
        ZIndex = 22,
        Parent = weaponCard,
    })
    local weaponName = UITheme.label({
        Size = UDim2.new(1, -24, 0, 22),
        Position = UDim2.fromOffset(14, 22),
        Font = F.Display,
        TextSize = 17,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = "Wooden Practice Sword",
        ZIndex = 22,
        Parent = weaponCard,
    })
    local weaponSkills = UITheme.label({
        Size = UDim2.new(1, -24, 0, 14),
        Position = UDim2.fromOffset(14, 45),
        Font = F.Medium,
        TextSize = 10,
        TextColor3 = C.TextMuted,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 22,
        Parent = weaponCard,
    })

    local socketRow = UITheme.new("Frame", {
        Size = UDim2.new(1, -24, 0, 18),
        Position = UDim2.fromOffset(14, 66),
        BackgroundTransparency = 1,
        ZIndex = 22,
        Parent = weaponCard,
    })
    UITheme.listLayout(socketRow, Enum.FillDirection.Horizontal, 4, nil, Enum.VerticalAlignment.Center)
    local sockets: { Frame } = {}
    for i = 1, ItemConfig.MaxWeaponSpiritCubes do
        local socket = UITheme.new("Frame", {
            Size = UDim2.fromOffset(16, 16),
            BackgroundColor3 = C.SurfaceSunken,
            LayoutOrder = i,
            ZIndex = 22,
            Parent = socketRow,
        })
        UITheme.corner(socket, 3)
        UITheme.stroke(socket, C.BorderSoft, 1)
        sockets[i] = socket
    end
    local socketCount = UITheme.label({
        Size = UDim2.fromOffset(44, 18),
        Font = F.Heavy,
        TextSize = 10,
        TextColor3 = C.TextMuted,
        Text = "0/12",
        LayoutOrder = 99,
        ZIndex = 22,
        Parent = socketRow,
    })

    local weaponStatsRow = UITheme.new("Frame", {
        Size = UDim2.new(1, -24, 0, 18),
        Position = UDim2.fromOffset(14, 94),
        BackgroundTransparency = 1,
        ZIndex = 22,
        Parent = weaponCard,
    })
    UITheme.listLayout(weaponStatsRow, Enum.FillDirection.Horizontal, 6)
    local statAtk = makeChip(weaponStatsRow, "+0 ATK", C.Danger, { LayoutOrder = 1, ZIndex = 22 })
    local statHp = makeChip(weaponStatsRow, "+0 MAX HP", C.Success, { LayoutOrder = 2, ZIndex = 22 })
    local statCrit = makeChip(weaponStatsRow, "+0% CRIT", C.Gold, { LayoutOrder = 3, ZIndex = 22 })

    UITheme.sectionHeader(forgeLeft, "Spirit Cubes", { Position = UDim2.fromOffset(0, 134) })

    local cubeGrid = UITheme.new("Frame", {
        Size = UDim2.new(1, 0, 0, 160),
        Position = UDim2.fromOffset(0, 158),
        BackgroundTransparency = 1,
        ZIndex = 21,
        Parent = forgeLeft,
    })
    UITheme.new("UIGridLayout", {
        CellSize = UDim2.new(0.5, -4, 0, 76),
        CellPadding = UDim2.fromOffset(8, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = cubeGrid,
    })

    type CubeCard = { Owned: TextLabel, Button: Button }
    local cubeCards: { [string]: CubeCard } = {}
    for idx, cubeKey in ItemConfig.SpiritCubeOrder do
        local spec = ItemConfig.SpiritCubes[cubeKey]
        local card = UITheme.new("Frame", {
            Name = cubeKey,
            BackgroundColor3 = C.SurfaceRaised,
            LayoutOrder = idx,
            ZIndex = 21,
            Parent = cubeGrid,
        })
        UITheme.corner(card, UITheme.Radius.Medium)
        UITheme.stroke(card, spec.Color, 1, 0.55)

        local icon = makeVoxelIcon(card, 28, spec.Color, spec.Color:Lerp(Color3.fromRGB(255, 255, 255), 0.45), nil)
        icon.Position = UDim2.fromOffset(10, 10)

        UITheme.label({
            Size = UDim2.new(1, -52, 0, 16),
            Position = UDim2.fromOffset(46, 8),
            Font = F.Display,
            TextSize = 13,
            TextColor3 = spec.Color,
            Text = spec.ShortName,
            ZIndex = 22,
            Parent = card,
        })
        UITheme.label({
            Size = UDim2.new(1, -52, 0, 14),
            Position = UDim2.fromOffset(46, 25),
            Font = F.Medium,
            TextSize = 10,
            TextColor3 = C.TextMuted,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = spec.Description,
            ZIndex = 22,
            Parent = card,
        })
        local owned = UITheme.label({
            Size = UDim2.new(0.5, -10, 0, 24),
            Position = UDim2.new(0, 10, 1, -32),
            Font = F.Heavy,
            TextSize = 11,
            TextColor3 = C.Text,
            Text = "x0",
            ZIndex = 22,
            Parent = card,
        })
        local forgeBtn = UITheme.button(
            {
                Size = UDim2.new(0.5, -6, 0, 24),
                Position = UDim2.new(0.5, -4, 1, -32),
                Text = "FORGE",
                TextSize = 10,
                ZIndex = 22,
                Parent = card,
            },
            "Primary",
            function()
                Network.getEvent("RequestAttachCube"):FireServer(cubeKey)
            end
        )
        cubeCards[cubeKey] = { Owned = owned, Button = forgeBtn }
    end

    -- Potion brewing row
    local potionCard = UITheme.new("Frame", {
        Size = UDim2.new(1, 0, 0, 54),
        Position = UDim2.new(0, 0, 1, -54),
        BackgroundColor3 = C.SurfaceRaised,
        ZIndex = 21,
        Parent = forgeLeft,
    })
    UITheme.corner(potionCard, UITheme.Radius.Medium)
    UITheme.stroke(potionCard, C.HP, 1, 0.55)
    UITheme.label({
        Size = UDim2.fromOffset(36, 54),
        Position = UDim2.fromOffset(8, 0),
        Font = F.Display,
        TextSize = 24,
        TextColor3 = C.HP,
        TextXAlignment = Enum.TextXAlignment.Center,
        Text = "♥",
        ZIndex = 22,
        Parent = potionCard,
    })
    UITheme.label({
        Size = UDim2.new(1, -170, 0, 18),
        Position = UDim2.fromOffset(48, 9),
        Font = F.Display,
        TextSize = 13,
        Text = ItemConfig.Potion.Name,
        ZIndex = 22,
        Parent = potionCard,
    })
    local potionInfo = UITheme.label({
        Size = UDim2.new(1, -170, 0, 14),
        Position = UDim2.fromOffset(48, 29),
        Font = F.Medium,
        TextSize = 10,
        TextColor3 = C.TextMuted,
        Text = "",
        ZIndex = 22,
        Parent = potionCard,
    })
    local brewBtn = UITheme.button(
        {
            Size = UDim2.fromOffset(110, 30),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -12, 0.5, 0),
            Text = string.format("BREW  •  %dG", ItemConfig.Potion.GoldCost),
            TextSize = 11,
            ZIndex = 22,
            Parent = potionCard,
        },
        "Gold",
        function()
            Network.getEvent("RequestBuyPotion"):FireServer()
        end
    )

    -- Loot bag (right column)
    local bagHeader = UITheme.sectionHeader(forgeRight, "Loot Bag")
    local bagHeaderLabel = bagHeader:FindFirstChildOfClass("TextLabel") :: TextLabel

    local bagScroll = UITheme.new("ScrollingFrame", {
        Name = "BagScroll",
        Size = UDim2.new(1, 0, 1, -26),
        Position = UDim2.fromOffset(0, 26),
        BackgroundTransparency = 1,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = C.Border,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ZIndex = 21,
        Parent = forgeRight,
    }) :: ScrollingFrame

    local function refreshBagUI(items: { EquipmentItem }, equippedItem: EquipmentItem?)
        for _, child in bagScroll:GetChildren() do
            if child:IsA("GuiObject") or child:IsA("UIListLayout") or child:IsA("UIPadding") then
                child:Destroy()
            end
        end
        bagHeaderLabel.Text = string.format("LOOT BAG  (%d)", #items)

        if #items == 0 then
            local empty = UITheme.new("Frame", {
                Size = UDim2.new(1, -6, 0, 150),
                BackgroundColor3 = C.SurfaceSunken,
                ZIndex = 21,
                Parent = bagScroll,
            })
            UITheme.corner(empty, UITheme.Radius.Medium)
            UITheme.stroke(empty, C.BorderSoft, 1)
            UITheme.label({
                Size = UDim2.new(1, 0, 0, 40),
                Position = UDim2.fromOffset(0, 26),
                Font = F.Display,
                TextSize = 30,
                TextColor3 = C.TextDim,
                TextXAlignment = Enum.TextXAlignment.Center,
                Text = "⬚",
                ZIndex = 22,
                Parent = empty,
            })
            UITheme.label({
                Size = UDim2.new(1, -24, 0, 50),
                Position = UDim2.fromOffset(12, 72),
                Font = F.Medium,
                TextSize = 11,
                TextColor3 = C.TextMuted,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Top,
                Text = "Your bag is empty.\nDefeat Slimes or King Gelatus (South) to find Loot Chests!",
                ZIndex = 22,
                Parent = empty,
            })
            return
        end

        UITheme.listLayout(bagScroll, Enum.FillDirection.Vertical, 6)
        UITheme.padding(bagScroll, 0, 6, 4, 0)

        for i, item in items do
            local rarity = ItemConfig.Rarities[item.Rarity] or ItemConfig.Rarities.Common
            local isEquipped = equippedItem ~= nil and equippedItem.Uid == item.Uid

            local row = UITheme.new("Frame", {
                Size = UDim2.new(1, 0, 0, 54),
                BackgroundColor3 = if isEquipped then rarity.Color:Lerp(C.SurfaceRaised, 0.85) else C.SurfaceRaised,
                LayoutOrder = if isEquipped then 0 else i,
                ZIndex = 21,
                Parent = bagScroll,
            })
            UITheme.corner(row, UITheme.Radius.Medium)
            UITheme.stroke(row, rarity.Color, if isEquipped then 1.5 else 1, if isEquipped then 0.2 else 0.65)
            UITheme.new("Frame", {
                Size = UDim2.new(0, 3, 1, -14),
                Position = UDim2.fromOffset(0, 7),
                BackgroundColor3 = rarity.Color,
                ZIndex = 22,
                Parent = row,
            })
            UITheme.label({
                Size = UDim2.new(1, -110, 0, 18),
                Position = UDim2.fromOffset(12, 7),
                Font = F.Display,
                TextSize = 13,
                TextColor3 = rarity.Color,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Text = item.Name,
                ZIndex = 22,
                Parent = row,
            })
            UITheme.label({
                Size = UDim2.new(1, -110, 0, 14),
                Position = UDim2.fromOffset(12, 28),
                Font = F.Medium,
                TextSize = 10,
                TextColor3 = C.TextMuted,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Text = string.format(
                    "%s  •  %s  •  +%d ATK  +%d HP  +%d%% Crit",
                    rarity.Stars,
                    item.ClassReq,
                    item.BonusATK,
                    item.BonusHP,
                    math.floor(item.BonusCrit * 100 + 0.5)
                ),
                ZIndex = 22,
                Parent = row,
            })
            local equipBtn = UITheme.button(
                {
                    Size = UDim2.fromOffset(86, 28),
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Text = if isEquipped then "EQUIPPED" else "EQUIP",
                    TextSize = 10,
                    ZIndex = 22,
                    Parent = row,
                },
                if isEquipped then "Success" else "Secondary",
                function()
                    Network.getEvent("RequestEquipItem"):FireServer(item.Uid)
                end
            )
            if isEquipped then
                equipBtn.SetEnabled(false)
            end
        end
    end

    refreshBagUI({}, nil)
    Network.getEvent("InventorySynced").OnClientEvent
        :Connect(function(items: { EquipmentItem }, equippedItem: EquipmentItem?)
            refreshBagUI(items, equippedItem)
        end)

    Network.getEvent("OpenForgeUI").OnClientEvent:Connect(function()
        forgeWin.Open()
    end)

    ---------------------------------------------------------------------------
    -- 6c. COMPANIONS & MOUNTS WINDOW [P]
    ---------------------------------------------------------------------------
    local petWin = registerWindow(UITheme.window(screenGui, {
        Name = "PetWindow",
        Title = "Companions & Mounts",
        Subtitle = "Pets fight beside you and grant passive bonuses  •  Ride them with [T]",
        Icon = "🐾",
        Hotkey = "P",
        Accent = Color3.fromRGB(128, 235, 165),
        Size = UDim2.fromOffset(640, 440),
    }))
    local petBody = petWin.Body

    local petGrid = UITheme.new("Frame", {
        Size = UDim2.new(1, 0, 1, -54),
        BackgroundTransparency = 1,
        ZIndex = 21,
        Parent = petBody,
    })
    UITheme.new("UIGridLayout", {
        CellSize = UDim2.new(0.5, -5, 0.5, -5),
        CellPadding = UDim2.fromOffset(10, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = petGrid,
    })

    type PetCard = { Stroke: UIStroke, Button: Button, Status: TextLabel }
    local petCards: { [string]: PetCard } = {}
    for idx, petKey in PetConfig.PetOrder do
        local spec = PetConfig.Pets[petKey]
        local card = UITheme.new("Frame", {
            Name = petKey,
            BackgroundColor3 = C.SurfaceRaised,
            LayoutOrder = idx,
            ZIndex = 21,
            Parent = petGrid,
        })
        UITheme.corner(card, UITheme.Radius.Medium)
        local cardStroke = UITheme.stroke(card, spec.BodyColor, 1, 0.6)

        local icon = makeVoxelIcon(card, 54, spec.BodyColor, spec.AccentColor, spec.EyeColor)
        icon.Position = UDim2.fromOffset(12, 12)

        UITheme.label({
            Size = UDim2.new(1, -84, 0, 20),
            Position = UDim2.fromOffset(76, 12),
            Font = F.Display,
            TextSize = 15,
            TextColor3 = spec.BodyColor:Lerp(Color3.fromRGB(255, 255, 255), 0.25),
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = spec.Name,
            ZIndex = 22,
            Parent = card,
        })
        local status = UITheme.label({
            Size = UDim2.new(1, -84, 0, 14),
            Position = UDim2.fromOffset(76, 33),
            Font = F.Medium,
            TextSize = 10,
            TextColor3 = C.TextMuted,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = "Favorite food: " .. spec.FoodName,
            ZIndex = 22,
            Parent = card,
        })

        local chipRow = UITheme.new("Frame", {
            Size = UDim2.new(1, -84, 0, 18),
            Position = UDim2.fromOffset(76, 50),
            BackgroundTransparency = 1,
            ZIndex = 22,
            Parent = card,
        })
        UITheme.listLayout(chipRow, Enum.FillDirection.Horizontal, 4)
        makeChip(chipRow, string.format("+%d ATK", spec.BonusATK), C.Danger, { LayoutOrder = 1, ZIndex = 22 })
        makeChip(chipRow, string.format("+%d HP", spec.BonusHP), C.Success, { LayoutOrder = 2, ZIndex = 22 })
        makeChip(chipRow, string.format("SPD %d", spec.MountSpeed), C.Primary, { LayoutOrder = 3, ZIndex = 22 })

        UITheme.label({
            Size = UDim2.new(0.5, -12, 0, 30),
            Position = UDim2.new(0, 12, 1, -42),
            Font = F.Bold,
            TextSize = 10,
            TextColor3 = C.TextMuted,
            Text = string.format("Pet DMG %d  •  every %.1fs", spec.CombatDamage, spec.AttackInterval),
            ZIndex = 22,
            Parent = card,
        })

        local actionBtn = UITheme.button(
            {
                Size = UDim2.new(0.5, -18, 0, 30),
                Position = UDim2.new(0.5, 6, 1, -42),
                Text = "SUMMON",
                TextSize = 11,
                ZIndex = 22,
                Parent = card,
            },
            "Primary",
            function()
                Network.getEvent("RequestSelectPet"):FireServer(petKey)
            end
        )
        petCards[petKey] = { Stroke = cardStroke, Button = actionBtn, Status = status }
    end

    local petFooter = UITheme.new("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 1, -40),
        BackgroundTransparency = 1,
        ZIndex = 21,
        Parent = petBody,
    })
    local mountBtn = UITheme.button(
        {
            Size = UDim2.new(0.5, -5, 1, 0),
            Text = "🐾  RIDE MOUNT  [T]",
            ZIndex = 22,
            Parent = petFooter,
        },
        "Success",
        function()
            Network.getEvent("RequestToggleMount"):FireServer()
        end
    )
    local gliderBtn = UITheme.button(
        {
            Size = UDim2.new(0.5, -5, 1, 0),
            Position = UDim2.new(0.5, 5, 0, 0),
            Text = "✈  DEPLOY GLIDER  [G]",
            ZIndex = 22,
            Parent = petFooter,
        },
        "Secondary",
        function()
            MovementController.toggleGlider()
        end
    )

    ---------------------------------------------------------------------------
    -- 6d. CONTROLS GUIDE WINDOW [H]
    ---------------------------------------------------------------------------
    local helpWin = registerWindow(UITheme.window(screenGui, {
        Name = "ControlsWindow",
        Title = "Controls",
        Subtitle = "Keyboard & mouse reference",
        Icon = "?",
        Hotkey = "H",
        Accent = Color3.fromRGB(200, 170, 255),
        Size = UDim2.fromOffset(600, 400),
    }))
    local helpBody = helpWin.Body

    local CONTROL_GROUPS: { { Title: string, Binds: { { string } } } } = {
        {
            Title = "Movement",
            Binds = {
                { "W A S D", "Move" },
                { "Space", "Jump" },
                { "Shift", "Sprint (hold, uses Stamina)" },
                { "Q / Ctrl", "Dodge Roll + I-Frame" },
                { "T", "Ride / dismount pet" },
                { "G", "Deploy / stow glider" },
            },
        },
        {
            Title = "Combat",
            Binds = {
                { "LMB", "3-hit combo (+MP)" },
                { "RMB / F", "Class special (35 MP)" },
                { "1", "Drink Heartflower Potion" },
                { "E", "Talk to NPC / use Anvil" },
            },
        },
        {
            Title = "Menus",
            Binds = {
                { "C", "Appearance" },
                { "I / B", "Spirit Forge & Bag" },
                { "P", "Companions & Mounts" },
                { "H", "This guide" },
            },
        },
        {
            Title = "Camera",
            Binds = {
                { "Mouse", "Look around" },
                { "Wheel", "Zoom" },
                { "V", "Toggle mouse lock" },
                { "Alt", "Free cursor (hold)" },
            },
        },
    }

    for gIdx, group in CONTROL_GROUPS do
        local col = (gIdx - 1) % 2
        local rowIdx = math.floor((gIdx - 1) / 2)
        local groupFrame = UITheme.new("Frame", {
            Size = UDim2.new(0.5, -8, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Position = UDim2.new(col * 0.5, col * 8, 0, rowIdx * 178),
            BackgroundTransparency = 1,
            ZIndex = 21,
            Parent = helpBody,
        })
        UITheme.listLayout(groupFrame, Enum.FillDirection.Vertical, 5)
        UITheme.sectionHeader(groupFrame, group.Title, { LayoutOrder = 0 })
        for bIdx, bind in group.Binds do
            local line = UITheme.new("Frame", {
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                LayoutOrder = bIdx,
                ZIndex = 21,
                Parent = groupFrame,
            })
            local cap = UITheme.keycap(line, bind[1], { ZIndex = 22 })
            cap.Position = UDim2.fromOffset(0, 1)
            UITheme.label({
                Size = UDim2.new(1, -86, 1, 0),
                Position = UDim2.fromOffset(86, 0),
                Font = F.Medium,
                TextSize = 11,
                TextColor3 = C.Text,
                Text = bind[2],
                ZIndex = 22,
                Parent = line,
            })
        end
    end

    ---------------------------------------------------------------------------
    -- 7. MENU DOCK (Bottom-Right)
    ---------------------------------------------------------------------------
    local dock = UITheme.new("Frame", {
        Name = "MenuDock",
        Size = UDim2.fromOffset(4 * 50 + 3 * 8, 64),
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -16, 1, -16),
        BackgroundTransparency = 1,
        Parent = screenGui,
    })
    UITheme.listLayout(dock, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Right)

    local function makeDockButton(order: number, icon: string, key: string, labelText: string, win: Window)
        local holder = UITheme.new("Frame", {
            Size = UDim2.fromOffset(50, 64),
            BackgroundTransparency = 1,
            LayoutOrder = order,
            Parent = dock,
        })
        local btn = UITheme.button(
            {
                Size = UDim2.fromOffset(50, 50),
                Text = icon,
                Font = F.Display,
                TextSize = 22,
                Parent = holder,
            },
            "Secondary",
            function()
                win.Toggle()
            end
        )
        UITheme.keycap(btn.Instance, key, {
            Position = UDim2.fromOffset(-5, -7),
            ZIndex = 3,
        })
        UITheme.label({
            Size = UDim2.new(1, 8, 0, 12),
            Position = UDim2.new(0, -4, 1, -12),
            Font = F.Heavy,
            TextSize = 8,
            TextColor3 = C.TextMuted,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextStrokeTransparency = 0.6,
            Text = string.upper(labelText),
            Parent = holder,
        })
        win.OnVisibilityChanged(function(isOpen: boolean)
            btn.SetStyle(if isOpen then "Primary" else "Secondary")
        end)
    end

    makeDockButton(1, "☺", "C", "Look", appearanceWin)
    makeDockButton(2, "⚒", "I", "Forge", forgeWin)
    makeDockButton(3, "🐾", "P", "Pets", petWin)
    makeDockButton(4, "?", "H", "Help", helpWin)

    ---------------------------------------------------------------------------
    -- 8. HOTKEYS
    ---------------------------------------------------------------------------
    UserInputService.InputBegan:Connect(function(input: InputObject, _gameProcessed: boolean)
        if UserInputService:GetFocusedTextBox() ~= nil then
            return
        end
        local key = input.KeyCode
        if key == Enum.KeyCode.C then
            appearanceWin.Toggle()
        elseif key == Enum.KeyCode.I or key == Enum.KeyCode.B then
            forgeWin.Toggle()
        elseif key == Enum.KeyCode.P then
            petWin.Toggle()
        elseif key == Enum.KeyCode.H then
            helpWin.Toggle()
        end
    end)

    ---------------------------------------------------------------------------
    -- 9. REAL-TIME UPDATE LOOP
    ---------------------------------------------------------------------------
    local dodgeCooldownEnd = 0
    local potionCooldownEnd = 0
    local wasDodging = false
    local lastPotions = getNumber("Potions", 0)
    local lastLevel = getNumber("Level", 1)

    local function setCooldown(slot: Slot, remaining: number, total: number)
        local ratio = if total > 0 then math.clamp(remaining / total, 0, 1) else 0
        slot.Cooldown.Size = UDim2.fromScale(1, ratio)
    end

    local function setSlotActive(slot: Slot, active: boolean, accent: Color3)
        slot.Stroke.Transparency = if active then 0 else 0.55
        slot.Stroke.Thickness = if active then 2.5 else 1.5
        slot.Frame.BackgroundColor3 = if active then accent:Lerp(C.SurfaceRaised, 0.55) else C.SurfaceRaised
    end

    local function setSlotUsable(slot: Slot, usable: boolean)
        slot.Icon.TextTransparency = if usable then 0 else 0.6
    end

    RunService.RenderStepped:Connect(function(dt: number)
        local now = os.clock()
        local hp = getNumber("HP", GameConfig.Stats.BaseMaxHP)
        local maxHp = getNumber("MaxHP", GameConfig.Stats.BaseMaxHP)
        local mp = getNumber("MP", 0)
        local maxMp = getNumber("MaxMP", GameConfig.Stats.BaseMaxMP)
        local stamina = getNumber("Stamina", GameConfig.Stamina.MaxStamina)
        local maxStamina = getNumber("MaxStamina", GameConfig.Stamina.MaxStamina)
        local level = getNumber("Level", 1)
        local exp = getNumber("Exp", 0)
        local maxExp = getNumber("MaxExp", 100)
        local gold = getNumber("Gold", 0)
        local potions = getNumber("Potions", 0)
        local bonusATK = getNumber("BonusATK", 0)
        local bonusHP = getNumber("BonusHP", 0)
        local bonusCrit = getNumber("BonusCrit", 0)
        local weaponCubes = getNumber("WeaponCubeCount", 0)
        local weaponCubeType = getString("WeaponCubeType", "FireCube")
        local eqName = getString("EquippedWeaponName", "Wooden Practice Sword")
        local eqRarityKey = getString("EquippedWeaponRarity", "Common")
        local jobClass = getString("JobClass", "Novice")
        local isDodging = getBool("IsDodging")
        local isSprinting = getBool("IsSprinting")
        local isMounted = getBool("IsMounted")
        local isGliding = getBool("IsGliding")
        local activePetId = getString("ActivePetId", "SlimePet")

        local classEntry = CharacterConfig.JobClasses[jobClass] or CharacterConfig.JobClasses.Novice
        local combatSpec = CombatConfig.Classes[jobClass] or CombatConfig.Classes.Novice
        local rarity = ItemConfig.Rarities[eqRarityKey] or ItemConfig.Rarities.Common

        -- Player frame
        levelNumber.Text = tostring(level)
        if level ~= lastLevel then
            lastLevel = level
            levelBadge.Size = UDim2.fromOffset(62, 62)
            levelBadge.Position = UDim2.fromOffset(6, 6)
            UITheme.tween(
                levelBadge,
                TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                { Size = UDim2.fromOffset(54, 54), Position = UDim2.fromOffset(10, 10) }
            )
        end
        local classColor = if jobClass == "Novice" then C.Gold else classEntry.AccentColor
        levelBadgeGradient.Color = ColorSequence.new(classColor, classColor:Lerp(Color3.fromRGB(0, 0, 0), 0.35))
        classChip.Text = string.upper(classEntry.DisplayName)
        classChip.TextColor3 = classColor
        goldChip.Text = string.format("● %d", gold)
        atkChip.Text = string.format("⚔ +%d", bonusATK)

        hpBar.Set(hp, maxHp, dt)
        hpBar.Text.Text = string.format("HP  %d / %d", math.floor(hp + 0.5), maxHp)
        mpBar.Set(mp, maxMp, dt)
        mpBar.Text.Text = string.format("MP  %d / %d", math.floor(mp + 0.5), maxMp)
        staminaBar.Set(stamina, maxStamina, dt)
        if stamina < GameConfig.Stamina.DodgeCost then
            staminaBar.SetColors(C.StaminaLow, C.HPDeep)
        else
            staminaBar.SetColors(C.Stamina, C.StaminaDeep)
        end

        iframeChip.Visible = isDodging
        sprintChip.Visible = isSprinting and not isMounted
        mountChip.Visible = isMounted
        glideChip.Visible = isGliding

        -- Quest tracker
        local qTitle = getString("QuestTitle", "Speak to a Class Master")
        local qDesc = getString("QuestDesc", "Find the Class Masters in the Guild Courtyard and press [E].")
        local qProg = getNumber("QuestProgress", 0)
        local qReq = getNumber("QuestRequired", 0)
        questTitle.Text = qTitle
        questDesc.Text = if qDesc ~= "" then qDesc else "Explore the Emerald Plains and grow stronger."
        local hasProgress = qReq > 0
        questProgressBar.Container.Visible = hasProgress
        questHint.Visible = not hasProgress
        if hasProgress then
            questProgressBar.Set(qProg, qReq, dt)
            questProgressBar.Text.Text = string.format("%d / %d", qProg, qReq)
            questProgressBar.Text.TextXAlignment = Enum.TextXAlignment.Center
        end

        -- Crosshair
        crosshair.Visible = CameraController.isMouseLocked()

        -- Hotbar
        attackSlot.Label.Text = "COMBO"
        local canSpecial = mp >= combatSpec.SpecialMPCost
        specialSlot.Badge.Text = string.format("%d MP", combatSpec.SpecialMPCost)
        specialSlot.Badge.TextColor3 = if canSpecial then C.MP else C.TextDim
        setSlotUsable(specialSlot, canSpecial)
        setSlotActive(specialSlot, canSpecial, C.MP)

        potionSlot.Badge.Text = string.format("x%d", potions)
        potionSlot.Badge.TextColor3 = if potions > 0 then C.Text else C.Danger
        if potions < lastPotions then
            potionCooldownEnd = now + ItemConfig.Potion.Cooldown
        end
        lastPotions = potions
        setSlotUsable(potionSlot, potions > 0)
        setCooldown(potionSlot, potionCooldownEnd - now, ItemConfig.Potion.Cooldown)

        if isDodging and not wasDodging then
            dodgeCooldownEnd = now + GameConfig.Movement.DodgeCooldown
        end
        wasDodging = isDodging
        setSlotUsable(dodgeSlot, stamina >= GameConfig.Stamina.DodgeCost)
        setCooldown(dodgeSlot, dodgeCooldownEnd - now, GameConfig.Movement.DodgeCooldown)

        setSlotActive(mountSlot, isMounted, C.Success)
        setSlotActive(glideSlot, isGliding, Color3.fromRGB(245, 236, 210))

        expBar.Set(exp, maxExp, dt)
        expBar.Text.Text = string.format("LV %d   •   %d / %d EXP", level, math.floor(exp + 0.5), maxExp)

        -- Forge window (only update while visible)
        if forgeWin.IsOpen() then
            weaponStars.Text = string.format("%s  %s", rarity.Stars, string.upper(rarity.Name))
            weaponStars.TextColor3 = rarity.Color
            weaponName.Text = eqName
            weaponName.TextColor3 = rarity.Color:Lerp(Color3.fromRGB(255, 255, 255), 0.2)
            weaponStripe.BackgroundColor3 = rarity.Color
            weaponCardStroke.Color = rarity.Color
            weaponSkills.Text = string.format(
                "%s class  •  [LMB] %s  •  [RMB] %s",
                classEntry.DisplayName,
                combatSpec.WeaponName,
                combatSpec.SpecialName
            )
            local cubeSpec = ItemConfig.SpiritCubes[weaponCubeType]
            local cubeColor = if cubeSpec then cubeSpec.Color else C.Primary
            for i, socket in sockets do
                socket.BackgroundColor3 = if i <= weaponCubes then cubeColor else C.SurfaceSunken
            end
            socketCount.Text = string.format("%d/%d", weaponCubes, ItemConfig.MaxWeaponSpiritCubes)
            statAtk.Text = string.format("+%d ATK", bonusATK)
            statHp.Text = string.format("+%d MAX HP", bonusHP)
            statCrit.Text = string.format("+%d%% CRIT", bonusCrit)

            local maxed = weaponCubes >= ItemConfig.MaxWeaponSpiritCubes
            for cubeKey, card in cubeCards do
                local count = getNumber(cubeKey .. "Count", 0)
                card.Owned.Text = string.format("Owned  x%d", count)
                card.Owned.TextColor3 = if count > 0 then C.Text else C.TextDim
                card.Button.SetEnabled(count > 0 and not maxed)
                card.Button.SetText(if maxed then "MAXED" else "FORGE +1")
            end

            potionInfo.Text = string.format(
                "Heals %d%% HP  •  You have x%d  •  Gold %d",
                math.floor(ItemConfig.Potion.HealRatio * 100),
                potions,
                gold
            )
            brewBtn.SetEnabled(gold >= ItemConfig.Potion.GoldCost)
        end

        -- Pet window (only update while visible)
        if petWin.IsOpen() then
            for _, petKey in PetConfig.PetOrder do
                local spec = PetConfig.Pets[petKey]
                local card = petCards[petKey]
                local owns = getBool("Owns_" .. petKey) or spec.GoldCost == 0
                if activePetId == petKey then
                    card.Button.SetText("✓ ACTIVE")
                    card.Button.SetStyle("Success")
                    card.Button.SetEnabled(false)
                    card.Stroke.Transparency = 0.1
                    card.Stroke.Thickness = 2
                    card.Status.Text = if isMounted then "Currently riding" else "Following you"
                elseif owns then
                    card.Button.SetText("SUMMON")
                    card.Button.SetStyle("Primary")
                    card.Button.SetEnabled(true)
                    card.Stroke.Transparency = 0.6
                    card.Stroke.Thickness = 1
                    card.Status.Text = "Tamed  •  Favorite food: " .. spec.FoodName
                else
                    card.Button.SetText(string.format("TAME  •  %dG", spec.GoldCost))
                    card.Button.SetStyle("Gold")
                    card.Button.SetEnabled(gold >= spec.GoldCost)
                    card.Stroke.Transparency = 0.6
                    card.Stroke.Thickness = 1
                    card.Status.Text = "Wild  •  Needs " .. spec.FoodName
                end
            end
            mountBtn.SetText(if isMounted then "🐾  DISMOUNT  [T]" else "🐾  RIDE MOUNT  [T]")
            mountBtn.SetStyle(if isMounted then "Danger" else "Success")
            gliderBtn.SetText(if isGliding then "✈  STOW GLIDER  [G]" else "✈  DEPLOY GLIDER  [G]")
            gliderBtn.SetStyle(if isGliding then "Danger" else "Secondary")
        end
    end)
end

return table.freeze(HudUI)
