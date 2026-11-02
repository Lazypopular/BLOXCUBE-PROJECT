--!strict
-- UITheme: BLOXCUBE Design System (Colors, Fonts, and Reusable UI Component Builders)
-- All HUD / Window UI should be built through these helpers so the look stays consistent.

local TweenService = game:GetService("TweenService")

local UITheme = {}

UITheme.Colors = {
    -- Surfaces
    Backdrop = Color3.fromRGB(6, 8, 14),
    Surface = Color3.fromRGB(16, 19, 30),
    SurfaceRaised = Color3.fromRGB(26, 31, 46),
    SurfaceSunken = Color3.fromRGB(10, 12, 20),
    SurfaceHover = Color3.fromRGB(36, 42, 62),
    Border = Color3.fromRGB(52, 60, 84),
    BorderSoft = Color3.fromRGB(36, 42, 60),
    Shadow = Color3.fromRGB(0, 0, 0),

    -- Text
    Text = Color3.fromRGB(244, 246, 252),
    TextMuted = Color3.fromRGB(164, 174, 202),
    TextDim = Color3.fromRGB(112, 122, 148),

    -- Accents
    Gold = Color3.fromRGB(255, 208, 88),
    GoldDeep = Color3.fromRGB(196, 134, 32),
    Primary = Color3.fromRGB(78, 164, 255),
    Success = Color3.fromRGB(86, 210, 120),
    Danger = Color3.fromRGB(236, 84, 92),
    Warning = Color3.fromRGB(255, 160, 64),

    -- Stat Bars
    HP = Color3.fromRGB(232, 64, 76),
    HPDeep = Color3.fromRGB(150, 28, 44),
    MP = Color3.fromRGB(70, 156, 255),
    MPDeep = Color3.fromRGB(34, 78, 186),
    Stamina = Color3.fromRGB(255, 196, 64),
    StaminaDeep = Color3.fromRGB(214, 122, 28),
    StaminaLow = Color3.fromRGB(236, 100, 52),
    EXP = Color3.fromRGB(140, 226, 92),
    EXPDeep = Color3.fromRGB(62, 160, 70),
}

UITheme.Fonts = {
    Display = Enum.Font.FredokaOne,
    Heavy = Enum.Font.GothamBlack,
    Bold = Enum.Font.GothamBold,
    Medium = Enum.Font.GothamMedium,
    Body = Enum.Font.Gotham,
}

UITheme.Radius = {
    Small = 4,
    Medium = 8,
    Large = 12,
}

local FAST_TWEEN = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function UITheme.tween(instance: Instance, info: TweenInfo, goals: { [string]: any }): Tween
    local tween = TweenService:Create(instance, info, goals)
    tween:Play()
    return tween
end

-- Generic instance constructor: UITheme.new("Frame", { Size = ..., Parent = ... })
function UITheme.new(className: string, props: { [string]: any }?): any
    local inst = Instance.new(className) :: any
    local parent: Instance? = nil
    if props then
        for key, value in props do
            if key == "Parent" then
                parent = value
            else
                inst[key] = value
            end
        end
    end
    if inst:IsA("GuiObject") and (props == nil or props.BorderSizePixel == nil) then
        inst.BorderSizePixel = 0
    end
    if parent then
        inst.Parent = parent
    end
    return inst
end

function UITheme.corner(parent: Instance, radius: number?): UICorner
    return UITheme.new("UICorner", {
        CornerRadius = UDim.new(0, radius or UITheme.Radius.Medium),
        Parent = parent,
    })
end

function UITheme.stroke(parent: Instance, color: Color3?, thickness: number?, transparency: number?): UIStroke
    return UITheme.new("UIStroke", {
        Color = color or UITheme.Colors.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

function UITheme.padding(parent: Instance, top: number, right: number?, bottom: number?, left: number?): UIPadding
    return UITheme.new("UIPadding", {
        PaddingTop = UDim.new(0, top),
        PaddingRight = UDim.new(0, right or top),
        PaddingBottom = UDim.new(0, bottom or top),
        PaddingLeft = UDim.new(0, left or right or top),
        Parent = parent,
    })
end

function UITheme.gradient(parent: Instance, top: Color3, bottom: Color3, rotation: number?): UIGradient
    return UITheme.new("UIGradient", {
        Color = ColorSequence.new(top, bottom),
        Rotation = rotation or 90,
        Parent = parent,
    })
end

function UITheme.listLayout(
    parent: Instance,
    direction: Enum.FillDirection,
    spacing: number,
    hAlign: Enum.HorizontalAlignment?,
    vAlign: Enum.VerticalAlignment?
): UIListLayout
    return UITheme.new("UIListLayout", {
        FillDirection = direction,
        Padding = UDim.new(0, spacing),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left,
        VerticalAlignment = vAlign or Enum.VerticalAlignment.Top,
        Parent = parent,
    })
end

-- Soft drop shadow placed behind a frame (same parent, lower ZIndex)
function UITheme.shadow(target: GuiObject, offset: number?, transparency: number?): Frame
    local off = offset or 4
    local shadow = UITheme.new("Frame", {
        Name = target.Name .. "Shadow",
        Size = target.Size,
        AnchorPoint = target.AnchorPoint,
        Position = target.Position + UDim2.fromOffset(0, off),
        BackgroundColor3 = UITheme.Colors.Shadow,
        BackgroundTransparency = transparency or 0.55,
        ZIndex = math.max(0, target.ZIndex - 1),
        Visible = target.Visible,
        Parent = target.Parent,
    })
    UITheme.corner(shadow, UITheme.Radius.Medium + 2)
    target:GetPropertyChangedSignal("Visible"):Connect(function()
        shadow.Visible = target.Visible
    end)
    target:GetPropertyChangedSignal("Position"):Connect(function()
        shadow.Position = target.Position + UDim2.fromOffset(0, off)
    end)
    target:GetPropertyChangedSignal("Size"):Connect(function()
        shadow.Size = target.Size
    end)
    return shadow
end

function UITheme.label(props: { [string]: any }): TextLabel
    local merged: { [string]: any } = {
        BackgroundTransparency = 1,
        Font = UITheme.Fonts.Bold,
        TextSize = 12,
        TextColor3 = UITheme.Colors.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Text = "",
    }
    for k, v in props do
        merged[k] = v
    end
    return UITheme.new("TextLabel", merged)
end

-- A raised panel card with rounded corners, border, and a subtle top-to-bottom gradient
function UITheme.panel(props: { [string]: any }, accent: Color3?): Frame
    local merged: { [string]: any } = {
        BackgroundColor3 = UITheme.Colors.Surface,
        BackgroundTransparency = 0.14,
    }
    for k, v in props do
        merged[k] = v
    end
    local frame = UITheme.new("Frame", merged)
    UITheme.corner(frame, UITheme.Radius.Medium + 2)
    UITheme.stroke(frame, accent or UITheme.Colors.BorderSoft, 1, 0.4)
    UITheme.gradient(frame, Color3.fromRGB(255, 255, 255), Color3.fromRGB(195, 200, 215), 90)
    return frame
end

export type ButtonStyle = "Primary" | "Secondary" | "Success" | "Danger" | "Gold" | "Ghost"

local BUTTON_COLORS: { [string]: { Base: Color3, Hover: Color3, Text: Color3 } } = {
    Primary = { Base = Color3.fromRGB(46, 112, 196), Hover = Color3.fromRGB(64, 136, 224), Text = UITheme.Colors.Text },
    Secondary = { Base = UITheme.Colors.SurfaceRaised, Hover = UITheme.Colors.SurfaceHover, Text = UITheme.Colors.Text },
    Success = { Base = Color3.fromRGB(44, 146, 84), Hover = Color3.fromRGB(58, 172, 102), Text = UITheme.Colors.Text },
    Danger = { Base = Color3.fromRGB(178, 52, 64), Hover = Color3.fromRGB(210, 70, 82), Text = UITheme.Colors.Text },
    Gold = {
        Base = Color3.fromRGB(204, 146, 40),
        Hover = Color3.fromRGB(232, 172, 56),
        Text = Color3.fromRGB(28, 20, 8),
    },
    Ghost = { Base = UITheme.Colors.Surface, Hover = UITheme.Colors.SurfaceRaised, Text = UITheme.Colors.TextMuted },
}

export type Button = {
    Instance: TextButton,
    SetStyle: (style: ButtonStyle) -> (),
    SetEnabled: (enabled: boolean) -> (),
    SetText: (text: string) -> (),
}

-- Animated button with hover/press feedback. Returns a small controller table.
function UITheme.button(props: { [string]: any }, style: ButtonStyle?, onClick: (() -> ())?): Button
    local currentStyle: string = style or "Secondary"
    local enabled = true

    local merged: { [string]: any } = {
        AutoButtonColor = false,
        Font = UITheme.Fonts.Heavy,
        TextSize = 12,
        Text = "",
        BackgroundColor3 = BUTTON_COLORS[currentStyle].Base,
        TextColor3 = BUTTON_COLORS[currentStyle].Text,
    }
    for k, v in props do
        merged[k] = v
    end

    local btn = UITheme.new("TextButton", merged) :: TextButton
    UITheme.corner(btn, UITheme.Radius.Small + 2)
    local stroke = UITheme.stroke(btn, Color3.fromRGB(255, 255, 255), 1, 0.88)
    local scale = UITheme.new("UIScale", { Scale = 1, Parent = btn }) :: UIScale

    local hovering = false

    local function refresh()
        local palette = BUTTON_COLORS[currentStyle]
        local base = if hovering and enabled then palette.Hover else palette.Base
        UITheme.tween(btn, FAST_TWEEN, {
            BackgroundColor3 = base,
            BackgroundTransparency = if enabled then 0 else 0.45,
            TextTransparency = if enabled then 0 else 0.45,
        })
        btn.TextColor3 = palette.Text
        stroke.Transparency = if hovering and enabled then 0.6 else 0.88
    end

    btn.MouseEnter:Connect(function()
        hovering = true
        refresh()
    end)
    btn.MouseLeave:Connect(function()
        hovering = false
        scale.Scale = 1
        refresh()
    end)
    btn.MouseButton1Down:Connect(function()
        if enabled then
            UITheme.tween(scale, FAST_TWEEN, { Scale = 0.95 })
        end
    end)
    btn.MouseButton1Up:Connect(function()
        UITheme.tween(scale, FAST_TWEEN, { Scale = 1 })
    end)
    if onClick then
        btn.MouseButton1Click:Connect(function()
            if enabled then
                onClick()
            end
        end)
    end

    local controller: Button = {
        Instance = btn,
        SetStyle = function(newStyle: ButtonStyle)
            if currentStyle ~= newStyle then
                currentStyle = newStyle
                refresh()
            end
        end,
        SetEnabled = function(isEnabled: boolean)
            if enabled ~= isEnabled then
                enabled = isEnabled
                refresh()
            end
        end,
        SetText = function(text: string)
            btn.Text = text
        end,
    }
    return controller
end

-- Small keyboard key-cap badge, e.g. [Q]
function UITheme.keycap(parent: Instance, keyText: string, props: { [string]: any }?): TextLabel
    local width = math.max(18, 8 + #keyText * 7)
    local merged: { [string]: any } = {
        Name = "Keycap",
        Size = UDim2.fromOffset(width, 18),
        BackgroundColor3 = Color3.fromRGB(236, 238, 246),
        BackgroundTransparency = 0,
        Font = UITheme.Fonts.Heavy,
        TextSize = 10,
        TextColor3 = Color3.fromRGB(24, 28, 40),
        TextXAlignment = Enum.TextXAlignment.Center,
        Text = keyText,
        Parent = parent,
    }
    if props then
        for k, v in props do
            merged[k] = v
        end
    end
    local cap = UITheme.label(merged)
    UITheme.corner(cap, 4)
    UITheme.stroke(cap, Color3.fromRGB(120, 128, 150), 1, 0.2)
    return cap
end

export type StatBar = {
    Container: Frame,
    Fill: Frame,
    Text: TextLabel,
    Set: (current: number, max: number, dt: number) -> (),
    SetColors: (top: Color3, bottom: Color3) -> (),
}

-- Stat bar with gradient fill and a trailing "damage ghost" bar that drains behind the real value
function UITheme.statBar(
    parent: Instance,
    props: {
        Name: string,
        Size: UDim2,
        Position: UDim2?,
        Top: Color3,
        Bottom: Color3,
        Label: string?,
        TextSize: number?,
        LayoutOrder: number?,
    }
): StatBar
    local container = UITheme.new("Frame", {
        Name = props.Name,
        Size = props.Size,
        Position = props.Position or UDim2.new(),
        BackgroundColor3 = UITheme.Colors.SurfaceSunken,
        LayoutOrder = props.LayoutOrder or 0,
        ClipsDescendants = true,
        Parent = parent,
    })
    UITheme.corner(container, UITheme.Radius.Small)
    UITheme.stroke(container, Color3.fromRGB(0, 0, 0), 1, 0.4)

    local ghost = UITheme.new("Frame", {
        Name = "Ghost",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(255, 244, 220),
        BackgroundTransparency = 0.35,
        Parent = container,
    })
    UITheme.corner(ghost, UITheme.Radius.Small)

    local fill = UITheme.new("Frame", {
        Name = "Fill",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Parent = container,
    })
    UITheme.corner(fill, UITheme.Radius.Small)
    local fillGradient = UITheme.gradient(fill, props.Top, props.Bottom, 90)

    UITheme.new("Frame", {
        Name = "Shine",
        Size = UDim2.new(1, 0, 0.4, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.8,
        Parent = fill,
    })

    local text = UITheme.label({
        Name = "Value",
        Size = UDim2.new(1, -12, 1, 0),
        Position = UDim2.fromOffset(6, 0),
        Font = UITheme.Fonts.Heavy,
        TextSize = props.TextSize or 11,
        TextStrokeTransparency = 0.5,
        ZIndex = 3,
        Text = props.Label or "",
        Parent = container,
    })

    local displayed = 1
    local ghostValue = 1

    local bar: StatBar = {
        Container = container,
        Fill = fill,
        Text = text,
        Set = function(current: number, max: number, dt: number)
            local ratio = math.clamp(current / math.max(1, max), 0, 1)
            displayed += (ratio - displayed) * math.min(1, dt * 16)
            if ratio >= ghostValue then
                ghostValue = displayed
            else
                ghostValue += (ratio - ghostValue) * math.min(1, dt * 3)
            end
            fill.Size = UDim2.fromScale(displayed, 1)
            ghost.Size = UDim2.fromScale(math.max(ghostValue, displayed), 1)
        end,
        SetColors = function(top: Color3, bottom: Color3)
            fillGradient.Color = ColorSequence.new(top, bottom)
        end,
    }
    return bar
end

export type Window = {
    Frame: Frame,
    Body: Frame,
    IsOpen: () -> boolean,
    Open: () -> (),
    Close: () -> (),
    Toggle: () -> (),
    OnVisibilityChanged: (callback: (isOpen: boolean) -> ()) -> (),
}

-- Standard window: title bar (icon + title + subtitle + hotkey + close), body content area, and pop-in animation
function UITheme.window(
    parent: Instance,
    props: {
        Name: string,
        Title: string,
        Subtitle: string?,
        Icon: string?,
        Hotkey: string?,
        Accent: Color3,
        Size: UDim2,
        AnchorPoint: Vector2?,
        Position: UDim2?,
    }
): Window
    local frame = UITheme.new("Frame", {
        Name = props.Name,
        Size = props.Size,
        AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
        Position = props.Position or UDim2.fromScale(0.5, 0.5),
        BackgroundColor3 = UITheme.Colors.Surface,
        BackgroundTransparency = 0.08,
        Visible = false,
        ZIndex = 20,
        Parent = parent,
    })
    UITheme.corner(frame, UITheme.Radius.Large)
    UITheme.stroke(frame, props.Accent, 1.5, 0.35)
    local popScale = UITheme.new("UIScale", { Scale = 1, Parent = frame }) :: UIScale

    -- Header strip
    local header = UITheme.new("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = UITheme.Colors.SurfaceRaised,
        ZIndex = 20,
        Parent = frame,
    })
    UITheme.corner(header, UITheme.Radius.Large)
    UITheme.gradient(header, props.Accent:Lerp(UITheme.Colors.SurfaceRaised, 0.72), UITheme.Colors.SurfaceRaised, 0)
    -- square off header bottom corners
    UITheme.new("Frame", {
        Size = UDim2.new(1, 0, 0, 12),
        Position = UDim2.new(0, 0, 1, -12),
        BackgroundColor3 = UITheme.Colors.SurfaceRaised,
        ZIndex = 20,
        Parent = header,
    })
    UITheme.new("Frame", {
        Name = "AccentLine",
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = props.Accent,
        BackgroundTransparency = 0.35,
        ZIndex = 21,
        Parent = header,
    })

    local iconBox = UITheme.new("Frame", {
        Size = UDim2.fromOffset(36, 36),
        Position = UDim2.fromOffset(12, 10),
        BackgroundColor3 = props.Accent,
        ZIndex = 21,
        Parent = header,
    })
    UITheme.corner(iconBox, UITheme.Radius.Medium)
    UITheme.gradient(iconBox, Color3.fromRGB(255, 255, 255), Color3.fromRGB(160, 160, 170), 90)
    UITheme.label({
        Size = UDim2.fromScale(1, 1),
        Font = UITheme.Fonts.Display,
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextColor3 = Color3.fromRGB(20, 22, 30),
        Text = props.Icon or "◆",
        ZIndex = 22,
        Parent = iconBox,
    })

    UITheme.label({
        Name = "Title",
        Size = UDim2.new(1, -150, 0, 22),
        Position = UDim2.fromOffset(58, 9),
        Font = UITheme.Fonts.Display,
        TextSize = 20,
        TextColor3 = UITheme.Colors.Text,
        Text = props.Title,
        ZIndex = 21,
        Parent = header,
    })
    UITheme.label({
        Name = "Subtitle",
        Size = UDim2.new(1, -150, 0, 16),
        Position = UDim2.fromOffset(58, 31),
        Font = UITheme.Fonts.Medium,
        TextSize = 11,
        TextColor3 = UITheme.Colors.TextMuted,
        Text = props.Subtitle or "",
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 21,
        Parent = header,
    })

    if props.Hotkey then
        UITheme.keycap(header, props.Hotkey, {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -52, 0.5, 0),
            ZIndex = 22,
        })
    end

    local body = UITheme.new("Frame", {
        Name = "Body",
        Size = UDim2.new(1, 0, 1, -58),
        Position = UDim2.fromOffset(0, 58),
        BackgroundTransparency = 1,
        ZIndex = 20,
        Parent = frame,
    })
    UITheme.padding(body, 12, 14, 14, 14)

    local listeners: { (boolean) -> () } = {}
    local isOpen = false

    local function setOpen(open: boolean)
        if isOpen == open then
            return
        end
        isOpen = open
        if open then
            frame.Visible = true
            popScale.Scale = 0.9
            UITheme.tween(popScale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
        else
            frame.Visible = false
        end
        for _, cb in listeners do
            cb(open)
        end
    end

    local closeBtn = UITheme.button(
        {
            Name = "CloseButton",
            Size = UDim2.fromOffset(30, 30),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -12, 0.5, 0),
            Text = "✕",
            TextSize = 14,
            ZIndex = 22,
            Parent = header,
        },
        "Ghost",
        function()
            setOpen(false)
        end
    )
    closeBtn.Instance.ZIndex = 22

    local window: Window = {
        Frame = frame,
        Body = body,
        IsOpen = function()
            return isOpen
        end,
        Open = function()
            setOpen(true)
        end,
        Close = function()
            setOpen(false)
        end,
        Toggle = function()
            setOpen(not isOpen)
        end,
        OnVisibilityChanged = function(callback: (boolean) -> ())
            table.insert(listeners, callback)
        end,
    }
    return window
end

-- Section heading inside windows: "TITLE ───────"
function UITheme.sectionHeader(parent: Instance, text: string, props: { [string]: any }?): Frame
    local merged: { [string]: any } = {
        Name = "Section_" .. text,
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        ZIndex = 21,
        Parent = parent,
    }
    if props then
        for k, v in props do
            merged[k] = v
        end
    end
    local row = UITheme.new("Frame", merged)
    local lbl = UITheme.label({
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Font = UITheme.Fonts.Heavy,
        TextSize = 10,
        TextColor3 = UITheme.Colors.TextMuted,
        Text = string.upper(text),
        ZIndex = 21,
        Parent = row,
    })
    local line = UITheme.new("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        BackgroundColor3 = UITheme.Colors.BorderSoft,
        ZIndex = 21,
        Parent = row,
    })
    local function relayout()
        local w = lbl.AbsoluteSize.X
        line.Position = UDim2.new(0, w + 8, 0.5, 0)
        line.Size = UDim2.new(1, -(w + 8), 0, 1)
    end
    lbl:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
    relayout()
    return row
end

return table.freeze(UITheme)
