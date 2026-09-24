--[[
    PiHub V5 :: Tokyo Night Edition
    ----------------------------------------------------------------
    Standalone single-file UI library for Roblox.

    Palette (Tokyo Night)
        Background        #1a1b26   rgb(26, 27, 38)
        Surface           #16161e   rgb(22, 22, 30)
        Component         #24283b   rgb(36, 40, 59)
        ComponentHover    #292e42   rgb(41, 46, 66)
        Border            #414868   rgb(65, 72, 104)
        Accent            #7aa2f7   rgb(122, 162, 247)
        AccentSecondary   #bb9af7   rgb(187, 154, 247)
        Danger            #f7768e   rgb(247, 118, 142)
        Text              #c0caf5   rgb(192, 202, 245)
        TextMuted         #565f89   rgb(86, 95, 137)

    Public API (identical to V5)
        PiHub:MakeWindow({ Title = "PiHub", SubTitle = "Online V5" })
        Window:MakeTab({ "Tab Name" })
        Window:Dialog({ Title = "", Text = "", Options = { { "Label", fn }, ... } })
        Window:Unload()
        Tab:AddSection({ "Section" })
        Tab:AddButton({ Name = "", Description = "", Callback = fn })
        Tab:AddToggle({ Name = "", Description = "", Default = false, Callback = fn })
        Tab:AddSlider({ Name = "", Min = 0, Max = 100, Increase = 1, Default = 0, Callback = fn })
        Tab:AddDropdown({ Name = "", Options = {}, Default = "", Callback = fn })

    Behavior kept from V5
        A slider and a dropdown invoke Callback once at construction with the
        resolved default value. A toggle does the same when Default is true.
        Button callbacks run on click only.

    Constraints honored
        No external assets, no HttpGet, engine instances only. Every glyph is
        either text or a composed frame, so the library draws offline.
--]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local PiHub = {}
PiHub.__index = PiHub
PiHub.Version = "5.1.0-tokyo"

local Theme = {
    Background = Color3.fromRGB(26, 27, 38),
    Surface = Color3.fromRGB(22, 22, 30),
    Component = Color3.fromRGB(36, 40, 59),
    ComponentHover = Color3.fromRGB(41, 46, 66),
    Border = Color3.fromRGB(65, 72, 104),
    Accent = Color3.fromRGB(122, 162, 247),
    AccentSecondary = Color3.fromRGB(187, 154, 247),
    Danger = Color3.fromRGB(247, 118, 142),
    Text = Color3.fromRGB(192, 202, 245),
    TextMuted = Color3.fromRGB(86, 95, 137),
}

-- Derived shades used only to give gradients depth (one step off the palette).
local DangerDeep = Color3.fromRGB(206, 92, 118)
local ShadowColor = Color3.fromRGB(9, 10, 16)

local Fonts = {
    Title = Enum.Font.GothamBold,
    Label = Enum.Font.GothamMedium,
    Body = Enum.Font.Gotham,
}

local WINDOW_WIDTH = 540
local WINDOW_HEIGHT = 340
local HEADER_HEIGHT = 46
local SIDEBAR_WIDTH = 138
local FOOTER_HEIGHT = 34
local COMPONENT_HEIGHT = 40
local MIN_UI_SCALE = 0.55
local HOVER_TIME = 0.14
local PRESS_SCALE = 0.97
local EASE = Enum.EasingStyle.Quad
local SPRING = Enum.EasingStyle.Back
local OUT = Enum.EasingDirection.Out
local EASE_IN = Enum.EasingDirection.In

local ActiveWindow = nil

local function viewportSize()
    local camera = workspace.CurrentCamera
    if camera then
        return camera.ViewportSize
    end
    return Vector2.new(1920, 1080)
end

local function create(class, properties, parent)
    local instance = Instance.new(class)
    for key, value in pairs(properties or {}) do
        instance[key] = value
    end
    if parent then
        instance.Parent = parent
    end
    return instance
end

local function addCorner(parent, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function addStroke(parent, color, thickness, transparency)
    return create("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0.35,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function addGradient(parent, colorA, colorB, rotation, transparency)
    return create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, colorA),
            ColorSequenceKeypoint.new(1, colorB),
        }),
        Rotation = rotation or 90,
        Transparency = transparency or NumberSequence.new(0),
    }, parent)
end

local function tween(object, properties, duration, style, direction)
    local animation = TweenService:Create(
        object,
        TweenInfo.new(duration or 0.16, style or EASE, direction or OUT),
        properties
    )
    animation:Play()
    return animation
end

-- One shot breath. Reverses keeps the motion bounded, so nothing pulses
-- forever on an idle screen.
local function pulse(object, property, fromValue, toValue, duration)
    object[property] = fromValue
    local animation = TweenService:Create(
        object,
        TweenInfo.new(duration or 0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true, 0),
        { [property] = toValue }
    )
    animation:Play()
    return animation
end

local function drawCross(parent, size, color)
    local bars = {}
    local length = math.max(8, math.floor(size * 0.6))
    local rotations = { 45, -45 }
    for index = 1, 2 do
        local bar = create("Frame", {
            Name = index == 1 and "CrossA" or "CrossB",
            Size = UDim2.fromOffset(length, 2),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Rotation = rotations[index],
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            ZIndex = (parent.ZIndex or 1) + 1,
        }, parent)
        addCorner(bar, 1)
        table.insert(bars, bar)
    end
    return bars
end

local function makeRegistry()
    local registry = { Connections = {}, Tweens = {} }

    function registry:Connect(signal, handler)
        local connection = signal:Connect(handler)
        table.insert(self.Connections, connection)
        return connection
    end

    function registry:Tween(object, properties, duration, style, direction)
        local animation = tween(object, properties, duration, style, direction)
        table.insert(self.Tweens, animation)
        return animation
    end

    function registry:Dispose()
        for _, connection in ipairs(self.Connections) do
            pcall(function()
                connection:Disconnect()
            end)
        end
        table.clear(self.Connections)
        for _, animation in ipairs(self.Tweens) do
            pcall(function()
                animation:Cancel()
            end)
        end
        table.clear(self.Tweens)
    end

    return registry
end

function PiHub:MakeWindow(config)
    config = config or {}
    local Title = config.Title or "PiHub V5"
    local SubTitle = config.SubTitle or "Testing UI"

    local parentUI = nil
    if gethui then
        parentUI = gethui()
    end
    if not parentUI then
        parentUI = CoreGui:FindFirstChild("RobloxGui") or LocalPlayer:WaitForChild("PlayerGui")
    end

    -- Replace a previous instance of this library, connections included.
    if ActiveWindow then
        ActiveWindow:Dispose()
        ActiveWindow = nil
    end
    local previous = parentUI:FindFirstChild("PiHub_UI")
    if previous then
        previous:Destroy()
    end

    local registry = makeRegistry()
    local isMenuOpen = true
    local responsiveScale = 1

    local screenGui = create("ScreenGui", {
        Name = "PiHub_UI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        DisplayOrder = 10,
    }, parentUI)

    -- Elevation: one shadow for depth, one soft glow for the neon edge.
    local windowGlow = create("Frame", {
        Name = "WindowGlow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(WINDOW_WIDTH + 24, WINDOW_HEIGHT + 24),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.94,
        BorderSizePixel = 0,
        ZIndex = 1,
    }, screenGui)
    addCorner(windowGlow, 22)

    local windowShadow = create("Frame", {
        Name = "WindowShadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 9),
        Size = UDim2.fromOffset(WINDOW_WIDTH + 12, WINDOW_HEIGHT + 12),
        BackgroundColor3 = ShadowColor,
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        ZIndex = 1,
    }, screenGui)
    addCorner(windowShadow, 18)

    local mainFrame = create("Frame", {
        Name = "MainFrame",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(WINDOW_WIDTH, WINDOW_HEIGHT),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = true,
        ZIndex = 2,
    }, screenGui)
    addCorner(mainFrame, 12)
    addStroke(mainFrame, Theme.Border, 1.5, 0.15)

    local windowScale = create("UIScale", { Scale = 1 }, mainFrame)

    local function applyResponsiveScale()
        local viewport = viewportSize()
        local widthFit = (viewport.X - 28) / WINDOW_WIDTH
        local heightFit = (viewport.Y - 28) / WINDOW_HEIGHT
        responsiveScale = math.clamp(math.min(widthFit, heightFit), MIN_UI_SCALE, 1)
        if isMenuOpen then
            windowScale.Scale = responsiveScale
        end
    end
    applyResponsiveScale()

    local camera = workspace.CurrentCamera
    if camera then
        registry:Connect(camera:GetPropertyChangedSignal("ViewportSize"), applyResponsiveScale)
    end

    local WindowObj = {
        Tabs = {},
        CurrentTab = nil,
        ScreenGui = screenGui,
        MainFrame = mainFrame,
    }

    -- Header: a subtle top-down gradient, then a drawn hairline instead of a
    -- hard border so the chrome reads as glass rather than a box.
    local header = create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
        BackgroundColor3 = Theme.Component,
        BorderSizePixel = 0,
        ZIndex = 3,
    }, mainFrame)
    addGradient(header, Theme.ComponentHover, Theme.Surface, 90)

    create("Frame", {
        Name = "HeaderHairline",
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = Theme.Border,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        ZIndex = 3,
    }, header)

    local headerLeft = create("Frame", {
        Name = "HeaderLeft",
        Position = UDim2.fromOffset(16, 0),
        Size = UDim2.new(1, -64, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 3,
    }, header)
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 9),
    }, headerLeft)

    local headerBar = create("Frame", {
        Name = "AccentBar",
        Size = UDim2.fromOffset(3, 16),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        LayoutOrder = 1,
    }, headerLeft)
    addCorner(headerBar, 2)

    create("TextLabel", {
        Name = "Title",
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 20),
        BackgroundTransparency = 1,
        Text = Title,
        TextColor3 = Theme.Accent,
        TextSize = 16,
        Font = Fonts.Title,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 2,
    }, headerLeft)

    create("Frame", {
        Name = "TitleDivider",
        Size = UDim2.fromOffset(1, 14),
        BackgroundColor3 = Theme.Border,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        LayoutOrder = 3,
    }, headerLeft)

    create("TextLabel", {
        Name = "SubTitle",
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 18),
        BackgroundTransparency = 1,
        Text = SubTitle,
        TextColor3 = Theme.TextMuted,
        TextSize = 13,
        Font = Fonts.Body,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 4,
    }, headerLeft)

    local closeButton = create("TextButton", {
        Name = "CloseBtn",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(30, 30),
        BackgroundColor3 = Theme.Component,
        BackgroundTransparency = 0.35,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 4,
    }, header)
    addCorner(closeButton, 8)
    local closeStroke = addStroke(closeButton, Theme.Border, 1, 0.5)
    local closeBars = drawCross(closeButton, 30, Theme.TextMuted)

    registry:Connect(closeButton.MouseEnter, function()
        registry:Tween(closeButton, {
            BackgroundColor3 = Theme.ComponentHover,
            BackgroundTransparency = 0.12,
        }, HOVER_TIME)
        registry:Tween(closeStroke, { Color = Theme.Danger, Transparency = 0.2 }, HOVER_TIME)
        for _, bar in ipairs(closeBars) do
            registry:Tween(bar, { BackgroundColor3 = Theme.Danger }, HOVER_TIME)
        end
    end)

    registry:Connect(closeButton.MouseLeave, function()
        registry:Tween(closeButton, {
            BackgroundColor3 = Theme.Component,
            BackgroundTransparency = 0.35,
        }, HOVER_TIME)
        registry:Tween(closeStroke, { Color = Theme.Border, Transparency = 0.5 }, HOVER_TIME)
        for _, bar in ipairs(closeBars) do
            registry:Tween(bar, { BackgroundColor3 = Theme.TextMuted }, HOVER_TIME)
        end
    end)

    registry:Connect(closeButton.MouseButton1Click, function()
        WindowObj:Dialog({
            Title = "Unload PiHub?",
            Text = "Are you sure you want to unload the script? The menu and floating button will be removed.",
            Options = {
                { "Cancel", function()
                    print("[PiHub] Unload canceled.")
                end },
                { "Unload", function()
                    WindowObj:Unload()
                end },
            },
        })
    end)

    -- Floating mobile anchor: circular monogram, one accent ring, press scale.
    local anchor = create("TextButton", {
        Name = "PiHub_FloatingBtn",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 45, 0.5, 0),
        Size = UDim2.fromOffset(54, 54),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.06,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 50,
    }, screenGui)
    addCorner(anchor, 27)
    local anchorStroke = addStroke(anchor, Theme.Accent, 1.5, 0.2)

    local anchorScale = create("UIScale", { Scale = 1 }, anchor)

    local anchorRing = create("Frame", {
        Name = "Ring",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, -14, 1, -14),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.88,
        BorderSizePixel = 0,
        ZIndex = 51,
    }, anchor)
    addCorner(anchorRing, 20)

    create("TextLabel", {
        Name = "Monogram",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "P",
        TextColor3 = Theme.Text,
        TextSize = 20,
        Font = Fonts.Title,
        ZIndex = 52,
    }, anchor)

    local isDraggingAnchor = false
    local dragOrigin = nil
    local positionOrigin = nil
    local movedEnough = false

    registry:Connect(anchor.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingAnchor = true
            movedEnough = false
            dragOrigin = input.Position
            positionOrigin = anchor.Position
            registry:Tween(anchorScale, { Scale = 0.92 }, 0.1, EASE, OUT)
            registry:Connect(input.Changed, function()
                if input.UserInputState == Enum.UserInputState.End then
                    isDraggingAnchor = false
                    registry:Tween(anchorScale, { Scale = 1 }, 0.3, SPRING, OUT)
                end
            end)
        end
    end)

    registry:Connect(UserInputService.InputChanged, function(input)
        if isDraggingAnchor and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragOrigin
            if delta.Magnitude > 6 then
                movedEnough = true
            end
            local viewport = viewportSize()
            local halfWidth = anchor.AbsoluteSize.X / 2
            local halfHeight = anchor.AbsoluteSize.Y / 2
            local scaleX = positionOrigin.X.Scale
            local scaleY = positionOrigin.Y.Scale
            local limitX = viewport.X * scaleX
            local limitY = viewport.Y * scaleY
            local offsetX = math.clamp(positionOrigin.X.Offset + delta.X, halfWidth + 4 - limitX, viewport.X - halfWidth - 4 - limitX)
            local offsetY = math.clamp(positionOrigin.Y.Offset + delta.Y, halfHeight + 4 - limitY, viewport.Y - halfHeight - 4 - limitY)
            anchor.Position = UDim2.new(scaleX, offsetX, scaleY, offsetY)
        end
    end)

    registry:Connect(anchor.MouseEnter, function()
        registry:Tween(anchorStroke, { Transparency = 0.05, Thickness = 2 }, HOVER_TIME)
        registry:Tween(anchorRing, { BackgroundTransparency = 0.78 }, HOVER_TIME)
    end)

    registry:Connect(anchor.MouseLeave, function()
        registry:Tween(anchorStroke, { Transparency = 0.2, Thickness = 1.5 }, HOVER_TIME)
        registry:Tween(anchorRing, { BackgroundTransparency = isMenuOpen and 0.88 or 0.92 }, HOVER_TIME)
    end)

    local function setMenuVisible(visible, instant)
        if visible then
            isMenuOpen = true
            windowGlow.Visible = true
            windowShadow.Visible = true
            mainFrame.Visible = true
        end
        local target = visible and responsiveScale or responsiveScale * 0.02
        if instant then
            windowScale.Scale = target
            if not visible then
                mainFrame.Visible = false
                windowGlow.Visible = false
                windowShadow.Visible = false
            end
            return
        end
        local animation = registry:Tween(
            windowScale,
            { Scale = target },
            visible and 0.28 or 0.2,
            visible and SPRING or EASE,
            visible and OUT or EASE_IN
        )
        registry:Connect(animation.Completed, function(state)
            if state == Enum.PlaybackState.Completed and not isMenuOpen then
                mainFrame.Visible = false
                windowGlow.Visible = false
                windowShadow.Visible = false
            end
        end)
    end

    registry:Connect(anchor.MouseButton1Up, function()
        if movedEnough then
            return
        end
        isMenuOpen = not isMenuOpen
        setMenuVisible(isMenuOpen, false)
        pulse(anchorRing, "BackgroundTransparency", isMenuOpen and 0.88 or 0.92, isMenuOpen and 0.68 or 0.98, 0.42)
    end)

    -- Sidebar, footer and content frame.
    local sidebar = create("ScrollingFrame", {
        Name = "Sidebar",
        Position = UDim2.fromOffset(0, HEADER_HEIGHT),
        Size = UDim2.new(0, SIDEBAR_WIDTH, 1, -HEADER_HEIGHT - FOOTER_HEIGHT),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ZIndex = 3,
    }, mainFrame)
    local sidebarLayout = create("UIListLayout", {
        Padding = UDim.new(0, 6),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, sidebar)
    create("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
    }, sidebar)
    registry:Connect(sidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        sidebar.CanvasSize = UDim2.new(0, 0, 0, sidebarLayout.AbsoluteContentSize.Y + 20)
    end)

    create("Frame", {
        Name = "SidebarDivider",
        Position = UDim2.new(0, SIDEBAR_WIDTH, 0, HEADER_HEIGHT),
        Size = UDim2.new(0, 1, 1, -HEADER_HEIGHT - FOOTER_HEIGHT),
        BackgroundColor3 = Theme.Border,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ZIndex = 3,
    }, mainFrame)

    local footer = create("Frame", {
        Name = "SidebarFooter",
        Position = UDim2.new(0, 0, 1, -FOOTER_HEIGHT),
        Size = UDim2.new(0, SIDEBAR_WIDTH, 0, FOOTER_HEIGHT),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        ZIndex = 3,
    }, mainFrame)
    create("Frame", {
        Name = "FooterHairline",
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Border,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ZIndex = 3,
    }, footer)
    local footerDot = create("Frame", {
        Name = "FooterDot",
        Position = UDim2.new(0, 12, 0.5, -2),
        Size = UDim2.fromOffset(3, 3),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        ZIndex = 3,
    }, footer)
    addCorner(footerDot, 2)
    create("TextLabel", {
        Name = "FooterLabel",
        Position = UDim2.fromOffset(22, 0),
        Size = UDim2.new(1, -30, 1, 0),
        BackgroundTransparency = 1,
        Text = "V5 TOKYO NIGHT",
        TextColor3 = Theme.TextMuted,
        TextSize = 10,
        Font = Fonts.Title,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3,
    }, footer)

    local contentContainer = create("Frame", {
        Name = "ContentContainer",
        Position = UDim2.new(0, SIDEBAR_WIDTH, 0, HEADER_HEIGHT),
        Size = UDim2.new(1, -SIDEBAR_WIDTH, 1, -HEADER_HEIGHT),
        BackgroundTransparency = 1,
        ZIndex = 3,
    }, mainFrame)

    function WindowObj:Dispose()
        registry:Dispose()
        screenGui:Destroy()
    end

    function WindowObj:Unload()
        print("[PiHub] Unloading UI completely...")
        self:Dispose()
        if ActiveWindow == self then
            ActiveWindow = nil
        end
    end

    function WindowObj:Dialog(diagConfig)
        diagConfig = diagConfig or {}
        local dTitle = diagConfig.Title or "Notice"
        local dText = diagConfig.Text or ""
        local dOptions = diagConfig.Options or { { "OK", function() end } }

        local backdrop = create("Frame", {
            Name = "ModalBackdrop",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(10, 10, 16),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Active = true,
            ZIndex = 50,
        }, mainFrame)

        local card = create("Frame", {
            Name = "DialogCard",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(334, 176),
            BackgroundColor3 = Theme.Component,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = 51,
        }, backdrop)
        addCorner(card, 12)
        addStroke(card, Theme.Border, 1.2, 0.25)
        local cardScale = create("UIScale", { Scale = 0.94 }, card)

        create("Frame", {
            Name = "TopAccent",
            Size = UDim2.new(1, 0, 0, 3),
            BackgroundColor3 = Theme.Danger,
            BorderSizePixel = 0,
            ZIndex = 51,
        }, card)

        local titleBar = create("Frame", {
            Name = "DangerBar",
            Position = UDim2.fromOffset(18, 21),
            Size = UDim2.fromOffset(3, 14),
            BackgroundColor3 = Theme.Danger,
            BorderSizePixel = 0,
            ZIndex = 52,
        }, card)
        addCorner(titleBar, 2)

        create("TextLabel", {
            Name = "DialogTitle",
            Position = UDim2.fromOffset(29, 18),
            Size = UDim2.new(1, -48, 0, 20),
            BackgroundTransparency = 1,
            Text = dTitle,
            TextColor3 = Theme.Text,
            TextSize = 15,
            Font = Fonts.Title,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 52,
        }, card)

        create("TextLabel", {
            Name = "DialogText",
            Position = UDim2.fromOffset(29, 46),
            Size = UDim2.new(1, -50, 0, 62),
            BackgroundTransparency = 1,
            Text = dText,
            TextColor3 = Theme.TextMuted,
            TextSize = 12,
            Font = Fonts.Body,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 52,
        }, card)

        local buttonRow = create("Frame", {
            Name = "DialogButtons",
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -16, 1, -14),
            Size = UDim2.new(1, -32, 0, 34),
            BackgroundTransparency = 1,
            ZIndex = 52,
        }, card)
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
        }, buttonRow)

        for index, option in ipairs(dOptions) do
            local optionName = option[1] or "Action"
            local optionCallback = option[2] or function() end
            local isPrimary = index == #dOptions

            local button = create("TextButton", {
                Name = "DialogBtn" .. tostring(index),
                Size = UDim2.fromOffset(110, 34),
                BackgroundColor3 = isPrimary and Theme.Danger or Theme.Component,
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = index,
                ZIndex = 53,
            }, buttonRow)
            addCorner(button, 8)
            local buttonScale = create("UIScale", { Scale = 1 }, button)

            if isPrimary then
                addGradient(button, Theme.Danger, DangerDeep, 90)
                addStroke(button, Theme.Danger, 1, 0.1)
            else
                addStroke(button, Theme.Border, 1, 0.35)
            end

            create("TextLabel", {
                Name = "DialogBtnLabel",
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = optionName,
                TextColor3 = isPrimary and ShadowColor or Theme.Text,
                TextSize = 13,
                Font = Fonts.Title,
                ZIndex = 54,
            }, button)

            local restingColor = isPrimary and Theme.Danger or Theme.Component
            local hoverColor = isPrimary and Theme.Danger or Theme.ComponentHover
            local restingTransparency = isPrimary and 0.08 or 0

            button.BackgroundTransparency = restingTransparency

            registry:Connect(button.MouseEnter, function()
                registry:Tween(button, {
                    BackgroundColor3 = hoverColor,
                    BackgroundTransparency = 0,
                }, HOVER_TIME)
            end)
            registry:Connect(button.MouseLeave, function()
                registry:Tween(button, {
                    BackgroundColor3 = restingColor,
                    BackgroundTransparency = restingTransparency,
                }, HOVER_TIME)
            end)
            registry:Connect(button.MouseButton1Down, function()
                registry:Tween(buttonScale, { Scale = 0.96 }, 0.08, EASE, OUT)
            end)
            registry:Connect(button.MouseButton1Up, function()
                registry:Tween(buttonScale, { Scale = 1 }, 0.24, SPRING, OUT)
            end)
            registry:Connect(button.MouseButton1Click, function()
                backdrop:Destroy()
                optionCallback()
            end)
        end

        registry:Tween(backdrop, { BackgroundTransparency = 0.55 }, 0.18)
        registry:Tween(cardScale, { Scale = 1 }, 0.26, SPRING, OUT)
    end

    function WindowObj:MakeTab(tabConfig)
        tabConfig = tabConfig or {}
        local TabName = tabConfig[1] or tabConfig.Name or "Tab"

        local tabButton = create("TextButton", {
            Name = TabName .. "_TabBtn",
            Size = UDim2.new(1, -16, 0, 38),
            BackgroundColor3 = Theme.Component,
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
        }, sidebar)
        addCorner(tabButton, 8)
        local tabStroke = addStroke(tabButton, Theme.Accent, 1, 1)

        local tabIndicator = create("Frame", {
            Name = "Indicator",
            Position = UDim2.new(0, -6, 0.5, -8),
            Size = UDim2.fromOffset(3, 16),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            Visible = false,
        }, tabButton)
        addCorner(tabIndicator, 2)

        local tabLabel = create("TextLabel", {
            Name = "TabLabel",
            Position = UDim2.fromOffset(14, 0),
            Size = UDim2.new(1, -24, 1, 0),
            BackgroundTransparency = 1,
            Text = TabName,
            TextColor3 = Theme.TextMuted,
            TextSize = 13,
            Font = Fonts.Label,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, tabButton)

        local tabContent = create("ScrollingFrame", {
            Name = TabName .. "_Content",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Border,
            ScrollBarImageTransparency = 0.4,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Visible = false,
            ZIndex = 3,
        }, contentContainer)

        local contentLayout = create("UIListLayout", {
            Padding = UDim.new(0, 8),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, tabContent)

        create("UIPadding", {
            PaddingTop = UDim.new(0, 12),
            PaddingBottom = UDim.new(0, 16),
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
        }, tabContent)

        registry:Connect(contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            tabContent.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 24)
        end)

        local TabObj = {}

        local function activateTab()
            for _, entry in ipairs(WindowObj.Tabs) do
                entry.Button.BackgroundTransparency = 1
                entry.Label.TextColor3 = Theme.TextMuted
                entry.Stroke.Transparency = 1
                entry.Content.Visible = false
                if entry.Indicator.Visible then
                    entry.Indicator.Visible = false
                    entry.Indicator.Position = UDim2.new(0, -6, 0.5, -8)
                end
            end
            tabButton.BackgroundColor3 = Theme.ComponentHover
            tabButton.BackgroundTransparency = 0
            tabStroke.Transparency = 0.55
            tabLabel.TextColor3 = Theme.Accent
            tabContent.Visible = true
            tabIndicator.Visible = true
            tabIndicator.Position = UDim2.new(0, -6, 0.5, -8)
            registry:Tween(tabIndicator, { Position = UDim2.new(0, 0, 0.5, -8) }, 0.22, EASE, OUT)
            WindowObj.CurrentTab = TabObj
        end

        registry:Connect(tabButton.MouseButton1Click, activateTab)

        registry:Connect(tabButton.MouseEnter, function()
            if WindowObj.CurrentTab ~= TabObj then
                registry:Tween(tabButton, { BackgroundColor3 = Theme.Component, BackgroundTransparency = 0.4 }, HOVER_TIME)
                registry:Tween(tabLabel, { TextColor3 = Theme.Text }, HOVER_TIME)
            end
        end)

        registry:Connect(tabButton.MouseLeave, function()
            if WindowObj.CurrentTab ~= TabObj then
                registry:Tween(tabButton, { BackgroundTransparency = 1 }, HOVER_TIME)
                registry:Tween(tabLabel, { TextColor3 = Theme.TextMuted }, HOVER_TIME)
            end
        end)

        TabObj.Button = tabButton
        TabObj.Label = tabLabel
        TabObj.Stroke = tabStroke
        TabObj.Indicator = tabIndicator
        TabObj.Content = tabContent

        if #WindowObj.Tabs == 0 then
            activateTab()
        end
        table.insert(WindowObj.Tabs, TabObj)

        function TabObj:AddSection(secConfig)
            local SecTitle = type(secConfig) == "table" and secConfig[1] or secConfig
            if SecTitle == nil then
                SecTitle = "Section"
            end

            local section = create("Frame", {
                Name = "Section_" .. tostring(SecTitle),
                Size = UDim2.new(1, -6, 0, 28),
                BackgroundTransparency = 1,
            }, tabContent)

            local marker = create("Frame", {
                Name = "Marker",
                Position = UDim2.new(0, 4, 0.5, -6),
                Size = UDim2.fromOffset(3, 12),
                BackgroundColor3 = Theme.Accent,
                BackgroundTransparency = 0.2,
                BorderSizePixel = 0,
            }, section)
            addCorner(marker, 2)

            create("TextLabel", {
                Name = "Title",
                Position = UDim2.fromOffset(17, 0),
                Size = UDim2.new(1, -17, 1, 0),
                BackgroundTransparency = 1,
                Text = tostring(SecTitle),
                TextColor3 = Theme.TextMuted,
                TextSize = 12,
                Font = Fonts.Title,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, section)
        end

        function TabObj:AddButton(btnConfig)
            local config = btnConfig or {}
            local Name = config.Name or config[1] or "Button"
            local Description = config.Description or ""
            local Callback = config.Callback or function() end
            local hasDescription = Description ~= ""
            local height = hasDescription and (COMPONENT_HEIGHT + 14) or COMPONENT_HEIGHT

            local row = create("TextButton", {
                Name = "Button_" .. tostring(Name),
                Size = UDim2.new(1, -6, 0, height),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
            }, tabContent)

            local visual = create("Frame", {
                Name = "Visual",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Theme.Component,
                BorderSizePixel = 0,
            }, row)
            addCorner(visual, 8)
            local visualStroke = addStroke(visual, Theme.Border, 1, 0.45)
            local visualScale = create("UIScale", { Scale = 1 }, visual)

            local accentPill = create("Frame", {
                Name = "AccentPill",
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -14, 0.5, 0),
                Size = UDim2.fromOffset(3, 16),
                BackgroundColor3 = Theme.Accent,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, visual)
            addCorner(accentPill, 2)

            local label = create("TextLabel", {
                Name = "Title",
                Position = UDim2.fromOffset(14, hasDescription and 8 or 0),
                Size = UDim2.new(1, -44, hasDescription and 20 or 1),
                BackgroundTransparency = 1,
                Text = tostring(Name),
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Fonts.Label,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
            }, visual)

            if hasDescription then
                create("TextLabel", {
                    Name = "Description",
                    Position = UDim2.fromOffset(14, 26),
                    Size = UDim2.new(1, -44, 0, 16),
                    BackgroundTransparency = 1,
                    Text = Description,
                    TextColor3 = Theme.TextMuted,
                    TextSize = 11,
                    Font = Fonts.Body,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                }, visual)
            end

            registry:Connect(row.MouseEnter, function()
                registry:Tween(visual, { BackgroundColor3 = Theme.ComponentHover }, HOVER_TIME)
                registry:Tween(visualStroke, { Color = Theme.Accent, Transparency = 0.35 }, HOVER_TIME)
                registry:Tween(accentPill, { BackgroundTransparency = 0.1 }, HOVER_TIME)
            end)

            registry:Connect(row.MouseLeave, function()
                registry:Tween(visual, { BackgroundColor3 = Theme.Component }, HOVER_TIME)
                registry:Tween(visualStroke, { Color = Theme.Border, Transparency = 0.45 }, HOVER_TIME)
                registry:Tween(accentPill, { BackgroundTransparency = 1 }, HOVER_TIME)
            end)

            registry:Connect(row.MouseButton1Down, function()
                registry:Tween(visualScale, { Scale = PRESS_SCALE }, 0.08, EASE, OUT)
            end)

            registry:Connect(row.MouseButton1Up, function()
                registry:Tween(visualScale, { Scale = 1 }, 0.26, SPRING, OUT)
            end)

            registry:Connect(row.MouseButton1Click, function()
                Callback()
            end)
        end

        function TabObj:AddToggle(toggleConfig)
            local config = toggleConfig or {}
            local Name = config.Name or "Toggle"
            local Description = config.Description or ""
            local Default = config.Default or false
            local Callback = config.Callback or function() end
            local hasDescription = Description ~= ""
            local height = hasDescription and (COMPONENT_HEIGHT + 12) or (COMPONENT_HEIGHT + 4)

            local row = create("TextButton", {
                Name = "Toggle_" .. tostring(Name),
                Size = UDim2.new(1, -6, 0, height),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
            }, tabContent)

            local visual = create("Frame", {
                Name = "Visual",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Theme.Component,
                BorderSizePixel = 0,
            }, row)
            addCorner(visual, 8)
            addStroke(visual, Theme.Border, 1, 0.45)
            local visualScale = create("UIScale", { Scale = 1 }, visual)

            create("TextLabel", {
                Name = "Title",
                Position = UDim2.fromOffset(14, hasDescription and 8 or 0),
                Size = UDim2.new(1, -88, hasDescription and 20 or 1),
                BackgroundTransparency = 1,
                Text = tostring(Name),
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Fonts.Label,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
            }, visual)

            if hasDescription then
                create("TextLabel", {
                    Name = "Description",
                    Position = UDim2.fromOffset(14, 26),
                    Size = UDim2.new(1, -88, 0, 16),
                    BackgroundTransparency = 1,
                    Text = Description,
                    TextColor3 = Theme.TextMuted,
                    TextSize = 11,
                    Font = Fonts.Body,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                }, visual)
            end

            local track = create("Frame", {
                Name = "Track",
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -14, 0.5, 0),
                Size = UDim2.fromOffset(46, 26),
                BackgroundColor3 = Theme.Border,
                BorderSizePixel = 0,
            }, visual)
            addCorner(track, 13)
            local trackStroke = addStroke(track, Theme.Border, 1, 0.3)

            local thumb = create("Frame", {
                Name = "Thumb",
                Size = UDim2.fromOffset(20, 20),
                BackgroundColor3 = Theme.Text,
                BorderSizePixel = 0,
            }, track)
            addCorner(thumb, 10)
            addStroke(thumb, Theme.Border, 1, 0.8)

            local state = Default
            local offPosition = UDim2.new(0, 3, 0.5, -10)
            local onPosition = UDim2.new(1, -23, 0.5, -10)

            local function render(animated)
                local trackColor = state and Theme.Accent or Theme.Border
                local strokeColor = state and Theme.Accent or Theme.Border
                local strokeTransparency = state and 0.35 or 0.3
                local thumbTarget = state and onPosition or offPosition
                if animated then
                    registry:Tween(track, { BackgroundColor3 = trackColor }, 0.18)
                    registry:Tween(trackStroke, { Color = strokeColor, Transparency = strokeTransparency }, 0.18)
                    registry:Tween(thumb, { Position = thumbTarget }, 0.26, SPRING, OUT)
                else
                    track.BackgroundColor3 = trackColor
                    trackStroke.Color = strokeColor
                    trackStroke.Transparency = strokeTransparency
                    thumb.Position = thumbTarget
                end
            end

            local function setState(value, animated)
                state = value
                render(animated)
                Callback(state)
            end

            render(false)

            registry:Connect(row.MouseButton1Click, function()
                setState(not state, true)
            end)

            registry:Connect(row.MouseEnter, function()
                registry:Tween(visual, { BackgroundColor3 = Theme.ComponentHover }, HOVER_TIME)
            end)

            registry:Connect(row.MouseLeave, function()
                registry:Tween(visual, { BackgroundColor3 = Theme.Component }, HOVER_TIME)
            end)

            registry:Connect(row.MouseButton1Down, function()
                registry:Tween(visualScale, { Scale = 0.985 }, 0.08, EASE, OUT)
            end)

            registry:Connect(row.MouseButton1Up, function()
                registry:Tween(visualScale, { Scale = 1 }, 0.26, SPRING, OUT)
            end)

            if Default then
                Callback(Default)
            end
        end

        function TabObj:AddSlider(sliderConfig)
            local config = sliderConfig or {}
            local Name = config.Name or "Slider"
            local Min = config.Min or 0
            local Max = config.Max or 100
            local Increase = config.Increase or 1
            local Default = config.Default or Min
            local Callback = config.Callback or function() end

            if Increase <= 0 then
                Increase = 1
            end
            local span = Max - Min
            if span <= 0 then
                span = 1
            end

            local currentValue = Default

            local row = create("Frame", {
                Name = "Slider_" .. tostring(Name),
                Size = UDim2.new(1, -6, 0, 60),
                BackgroundColor3 = Theme.Component,
                BorderSizePixel = 0,
            }, tabContent)
            addCorner(row, 8)
            addStroke(row, Theme.Border, 1, 0.45)

            create("TextLabel", {
                Name = "Title",
                Position = UDim2.fromOffset(14, 10),
                Size = UDim2.new(0.65, -14, 0, 18),
                BackgroundTransparency = 1,
                Text = tostring(Name),
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Fonts.Label,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
            }, row)

            local valueLabel = create("TextLabel", {
                Name = "Value",
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -14, 0, 10),
                Size = UDim2.new(0.35, -14, 0, 18),
                BackgroundTransparency = 1,
                Text = tostring(currentValue),
                TextColor3 = Theme.AccentSecondary,
                TextSize = 13,
                Font = Fonts.Title,
                TextXAlignment = Enum.TextXAlignment.Right,
            }, row)

            local sliderBar = create("TextButton", {
                Name = "SliderBar",
                Position = UDim2.fromOffset(14, 30),
                Size = UDim2.new(1, -28, 0, 26),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
            }, row)

            local track = create("Frame", {
                Name = "Track",
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(1, 0, 0, 10),
                BackgroundColor3 = Theme.Border,
                BackgroundTransparency = 0.5,
                BorderSizePixel = 0,
                ClipsDescendants = true,
            }, sliderBar)
            addCorner(track, 5)

            local startRatio = (currentValue - Min) / span

            local fill = create("Frame", {
                Name = "Fill",
                Size = UDim2.new(startRatio, 0, 1, 0),
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
            }, track)
            addCorner(fill, 5)
            addGradient(fill, Theme.Accent, Theme.AccentSecondary, 0)

            local handle = create("Frame", {
                Name = "Handle",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(startRatio, 0, 0.5, 0),
                Size = UDim2.fromOffset(16, 24),
                BackgroundColor3 = Theme.Text,
                BorderSizePixel = 0,
            }, sliderBar)
            addCorner(handle, 8)
            addStroke(handle, Theme.Accent, 1.5, 0.1)

            local isSliding = false

            local function applyValue(ratio)
                local clamped = math.clamp(ratio, 0, 1)
                local exact = Min + (span * clamped)
                local stepped = math.floor((exact / Increase) + 0.5) * Increase
                stepped = math.clamp(stepped, Min, Max)
                currentValue = stepped
                valueLabel.Text = tostring(currentValue)
                local normalized = (currentValue - Min) / span
                fill.Size = UDim2.new(normalized, 0, 1, 0)
                handle.Position = UDim2.new(normalized, 0, 0.5, 0)
                Callback(currentValue)
            end

            local function updateFromInput(input)
                local barPosition = sliderBar.AbsolutePosition.X
                local barSize = sliderBar.AbsoluteSize.X
                if barSize <= 0 then
                    return
                end
                applyValue((input.Position.X - barPosition) / barSize)
            end

            registry:Connect(sliderBar.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isSliding = true
                    registry:Tween(handle, { Size = UDim2.fromOffset(18, 26) }, 0.12, EASE, OUT)
                    registry:Tween(track, { BackgroundTransparency = 0.32 }, 0.12)
                    updateFromInput(input)
                end
            end)

            registry:Connect(UserInputService.InputEnded, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    if isSliding then
                        isSliding = false
                        registry:Tween(handle, { Size = UDim2.fromOffset(16, 24) }, 0.2, SPRING, OUT)
                        registry:Tween(track, { BackgroundTransparency = 0.5 }, 0.2)
                    end
                end
            end)

            registry:Connect(UserInputService.InputChanged, function(input)
                if isSliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateFromInput(input)
                end
            end)

            if Default then
                Callback(Default)
            end
        end

        function TabObj:AddDropdown(ddConfig)
            local config = ddConfig or {}
            local Name = config.Name or "Dropdown"
            local Options = config.Options or {}
            local Default = config.Default or Options[1] or "None"
            local Callback = config.Callback or function() end

            local COLLAPSED = COMPONENT_HEIGHT
            local OPTION_HEIGHT = 32
            local ROW_PITCH = OPTION_HEIGHT + 4
            local MAX_VISIBLE = 5
            local visibleOptions = math.min(#Options, MAX_VISIBLE)
            local listHeight = visibleOptions > 0 and ((visibleOptions * ROW_PITCH) - 4) or 0
            local expandedHeight = 45 + listHeight + 6

            local isOpen = false
            local selected = Default

            local dropFrame = create("Frame", {
                Name = "Dropdown_" .. tostring(Name),
                Size = UDim2.new(1, -6, 0, COLLAPSED),
                BackgroundColor3 = Theme.Component,
                BorderSizePixel = 0,
                ClipsDescendants = true,
            }, tabContent)
            addCorner(dropFrame, 8)
            addStroke(dropFrame, Theme.Border, 1, 0.45)

            local selector = create("TextButton", {
                Name = "Selector",
                Size = UDim2.new(1, 0, 0, COLLAPSED),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
            }, dropFrame)

            create("TextLabel", {
                Name = "Title",
                Position = UDim2.fromOffset(14, 0),
                Size = UDim2.new(0.5, -20, 1, 0),
                BackgroundTransparency = 1,
                Text = tostring(Name),
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Fonts.Label,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
            }, selector)

            local selectedLabel = create("TextLabel", {
                Name = "SelectedValue",
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -34, 0, 0),
                Size = UDim2.new(0.5, -40, 1, 0),
                BackgroundTransparency = 1,
                Text = tostring(selected),
                TextColor3 = Theme.Accent,
                TextSize = 13,
                Font = Fonts.Title,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextTruncate = Enum.TextTruncate.AtEnd,
            }, selector)

            local arrow = create("TextLabel", {
                Name = "Arrow",
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -12, 0.5, 0),
                Size = UDim2.fromOffset(18, 18),
                BackgroundTransparency = 1,
                Text = "v",
                TextColor3 = Theme.TextMuted,
                TextSize = 12,
                Font = Fonts.Title,
            }, selector)

            local hairline = create("Frame", {
                Name = "Hairline",
                Position = UDim2.fromOffset(10, COLLAPSED - 1),
                Size = UDim2.new(1, -20, 0, 1),
                BackgroundColor3 = Theme.Border,
                BackgroundTransparency = 0.5,
                BorderSizePixel = 0,
                Visible = false,
            }, dropFrame)

            local optionsList = create("ScrollingFrame", {
                Name = "OptionsList",
                Position = UDim2.fromOffset(10, 45),
                Size = UDim2.new(1, -20, 0, listHeight),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 2,
                ScrollBarImageColor3 = Theme.Border,
                ScrollBarImageTransparency = 0.3,
                CanvasSize = UDim2.new(0, 0, 0, math.max(0, (#Options * ROW_PITCH) - 4)),
                Visible = false,
            }, dropFrame)
            create("UIListLayout", {
                Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, optionsList)

            local optionButtons = {}

            local function paintOptions()
                for _, entry in ipairs(optionButtons) do
                    local isSelected = entry.Value == selected
                    entry.Label.TextColor3 = isSelected and Theme.Accent or Theme.TextMuted
                    entry.Button.BackgroundTransparency = isSelected and 0 or 1
                    entry.Marker.BackgroundTransparency = isSelected and 0.1 or 1
                end
            end

            local function setOpen(open)
                isOpen = open
                if isOpen then
                    optionsList.Visible = true
                    hairline.Visible = true
                    arrow.Text = "^"
                    registry:Tween(arrow, { TextColor3 = Theme.Accent }, 0.18)
                    registry:Tween(dropFrame, { Size = UDim2.new(1, -6, 0, expandedHeight) }, 0.22, SPRING, OUT)
                else
                    arrow.Text = "v"
                    registry:Tween(arrow, { TextColor3 = Theme.TextMuted }, 0.18)
                    local animation = registry:Tween(dropFrame, { Size = UDim2.new(1, -6, 0, COLLAPSED) }, 0.16, EASE, EASE_IN)
                    registry:Connect(animation.Completed, function(state)
                        if state == Enum.PlaybackState.Completed and not isOpen then
                            optionsList.Visible = false
                            hairline.Visible = false
                        end
                    end)
                end
            end

            for index, option in ipairs(Options) do
                local optionButton = create("TextButton", {
                    Name = "Option_" .. tostring(option),
                    Size = UDim2.new(1, -2, 0, OPTION_HEIGHT),
                    BackgroundColor3 = Theme.ComponentHover,
                    BackgroundTransparency = 1,
                    Text = "",
                    AutoButtonColor = false,
                    LayoutOrder = index,
                }, optionsList)
                addCorner(optionButton, 6)

                local marker = create("Frame", {
                    Name = "Marker",
                    Position = UDim2.new(0, 6, 0.5, -7),
                    Size = UDim2.fromOffset(3, 14),
                    BackgroundColor3 = Theme.Accent,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                }, optionButton)
                addCorner(marker, 2)

                local optionLabel = create("TextLabel", {
                    Name = "Title",
                    Position = UDim2.fromOffset(17, 0),
                    Size = UDim2.new(1, -23, 1, 0),
                    BackgroundTransparency = 1,
                    Text = tostring(option),
                    TextColor3 = Theme.TextMuted,
                    TextSize = 12,
                    Font = Fonts.Body,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                }, optionButton)

                table.insert(optionButtons, {
                    Button = optionButton,
                    Label = optionLabel,
                    Marker = marker,
                    Value = option,
                })

                registry:Connect(optionButton.MouseEnter, function()
                    if option ~= selected then
                        registry:Tween(optionButton, { BackgroundTransparency = 0.45 }, HOVER_TIME)
                        registry:Tween(optionLabel, { TextColor3 = Theme.Text }, HOVER_TIME)
                    end
                end)

                registry:Connect(optionButton.MouseLeave, function()
                    if option ~= selected then
                        registry:Tween(optionButton, { BackgroundTransparency = 1 }, HOVER_TIME)
                        registry:Tween(optionLabel, { TextColor3 = Theme.TextMuted }, HOVER_TIME)
                    end
                end)

                registry:Connect(optionButton.MouseButton1Click, function()
                    selected = option
                    selectedLabel.Text = tostring(selected)
                    paintOptions()
                    setOpen(false)
                    Callback(selected)
                end)
            end

            registry:Connect(selector.MouseButton1Click, function()
                setOpen(not isOpen)
            end)

            registry:Connect(selector.MouseEnter, function()
                registry:Tween(dropFrame, { BackgroundColor3 = Theme.ComponentHover }, HOVER_TIME)
            end)

            registry:Connect(selector.MouseLeave, function()
                registry:Tween(dropFrame, { BackgroundColor3 = Theme.Component }, HOVER_TIME)
            end)

            paintOptions()
            optionsList.Visible = false

            if Default then
                Callback(Default)
            end
        end

        return TabObj
    end

    -- Entrance cue: one bounded breath on the anchor ring, then it rests.
    pulse(anchorRing, "BackgroundTransparency", 0.88, 0.7, 0.6)

    ActiveWindow = WindowObj
    return WindowObj
end

PiHub.Theme = Theme

return PiHub
