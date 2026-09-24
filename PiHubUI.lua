--[[
    PiHub V5 :: Tokyo Night Edition
    ----------------------------------------------------------------
    Standalone single-file UI library for Roblox. Pure Luau, zero
    external web dependencies: no HttpGet, no loadstrings, no remote
    assets. The only image in the system is the built in Roblox hub
    logo on the floating mobile icon. Every other visual is composed
    from engine instances (Frame, TextButton, TextLabel, ImageButton,
    ScrollingFrame, UICorner, UIStroke, UIPadding, UIListLayout).

    Design system: authentic Tokyo Night palette
        Background        #1a1b26  deep canvas of the window
        Surface           #16161e  header, sidebar, floating icon
        Component         #24283b  cards at rest
        ComponentPressed  #292e42  pressed and hover state
        Border            #414868  structural strokes
        Accent            #7aa2f7  primary cyan blue, active state
        Purple            #bb9af7  secondary purple, sections, values
        Danger            #f7768e  dialog titles, destructive actions
        Text              #c0caf5  high contrast primary text
        Muted             #565f89  subtitles and idle labels
        SwitchOff         #1f2335  toggle off track, idle tab buttons

    Bottom-left corner clipping fix
        MainFrame owns a 12px corner radius. The Header is a separate
        solid surface: it keeps its own 12px radius on top and an
        invisible spacer frame squares off its bottom edge so the
        middle seam stays straight. The Sidebar is a ScrollingFrame
        with its own 12px UICorner attached directly to the instance,
        so its bottom-left corner conforms to the MainFrame radius
        instead of rendering as a 90 degree square.

    Interaction model
        One floating circular icon (52x52) floats above the game. It
        drags with touch or mouse, and a press that travels under 6
        pixels counts as a tap that toggles the window open or closed.
        The header drags the window. Every control accepts both touch
        and mouse through InputBegan, InputChanged, and InputEnded.

    Public API
        PiHub:MakeWindow({ Title = "PiHub V5", SubTitle = "", SaveFolder = "" })
        Window:MakeTab({ Name = "Tab", Icon = "" })
        Window:Dialog({ Title = "", Text = "", Options = { { "Label", fn } } })
        Window:Unload()
        Tab:AddSection("Title")
        Tab:AddButton({ Name = "", Callback = fn })
        Tab:AddToggle({ Name = "", Description = "", Default = false, Callback = fn })
        Tab:AddSlider({ Name = "", Min = 0, Max = 100, Increase = 1, Default = 0, Callback = fn })
        Tab:AddDropdown({ Name = "", Options = {}, Default = "", Callback = fn })

    Behavior notes
        A slider and a dropdown invoke Callback once at construction
        with the resolved default. A toggle does the same only when
        Default is true. Button callbacks run on click only.
        Window:Unload() destroys the ScreenGui and disconnects every
        tracked connection, leaving zero residue.
--]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local PiHub = {}
PiHub.Version = "5.4.0-tokyo"

local Theme = {
    Background = Color3.fromRGB(26, 27, 38),
    Surface = Color3.fromRGB(22, 22, 30),
    Component = Color3.fromRGB(36, 40, 59),
    ComponentPressed = Color3.fromRGB(41, 46, 66),
    Border = Color3.fromRGB(65, 72, 104),
    Accent = Color3.fromRGB(122, 162, 247),
    Purple = Color3.fromRGB(187, 154, 247),
    Danger = Color3.fromRGB(247, 118, 142),
    Text = Color3.fromRGB(192, 202, 245),
    Muted = Color3.fromRGB(86, 95, 137),
    SwitchOff = Color3.fromRGB(31, 35, 53),
    OnAccent = Color3.fromRGB(26, 27, 38),
}

local Fonts = {
    Title = Enum.Font.GothamBold,
    Label = Enum.Font.GothamMedium,
    Body = Enum.Font.Gotham,
}
local LOGO_ASSET = "rbxassetid://10723407389"
local WINDOW_SIZE = UDim2.fromOffset(530, 320)
local CLOSED_SIZE = UDim2.fromOffset(0, 0)
local HEADER_HEIGHT = 42
local SIDEBAR_WIDTH = 130
local ICON_SIZE = 52
local TAP_THRESHOLD = 6

local HOVER_TIME = 0.12
local PRESS_TIME = 0.08
local STATE_TIME = 0.15
local DROP_TIME = 0.18

local QUAD = Enum.EasingStyle.Quad
local QUINT = Enum.EasingStyle.Quint
local BACK = Enum.EasingStyle.Back
local OUT = Enum.EasingDirection.Out
local EASE_IN = Enum.EasingDirection.In

local ActiveWindow = nil

local function create(className, props, parent)
    local inst = Instance.new(className)
    for key, value in pairs(props) do
        inst[key] = value
    end
    if parent then
        inst.Parent = parent
    end
    return inst
end

local function addCorner(inst, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius) }, inst)
end

local function addStroke(inst, color, thickness)
    return create("UIStroke", {
        Color = color,
        Thickness = thickness,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, inst)
end

local function tween(inst, duration, props, style, direction)
    local handle = TweenService:Create(inst, TweenInfo.new(duration, style or QUAD, direction or OUT), props)
    handle:Play()
    return handle
end

local function makeRegistry()
    local connections = {}
    local registry = {}
    function registry:Connect(signal, fn)
        local connection = signal:Connect(fn)
        table.insert(connections, connection)
        return connection
    end
    function registry:Dispose()
        for _, connection in ipairs(connections) do
            pcall(function()
                connection:Disconnect()
            end)
        end
        table.clear(connections)
    end
    return registry
end

local function textWidth(text, size, font)
    local ok, bounds = pcall(function()
        return TextService:GetTextSize(text, size, font, Vector2.new(10000, 10000))
    end)
    if ok then
        return bounds.X
    end
    return #text * size * 0.55
end

local function viewportSize()
    local camera = workspace.CurrentCamera
    if camera then
        return camera.ViewportSize
    end
    return Vector2.new(1280, 720)
end

local function resolveMountParent()
    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and typeof(hui) == "Instance" then
            return hui
        end
    end
    local robloxGui = CoreGui:FindFirstChild("RobloxGui")
    if robloxGui then
        return robloxGui
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
end

function PiHub:MakeWindow(windowConfig)
    windowConfig = windowConfig or {}
    local windowTitle = tostring(windowConfig.Title or windowConfig[1] or "PiHub V5")
    local windowSubtitle = tostring(windowConfig.SubTitle or windowConfig[2] or "")
    -- SaveFolder is accepted for API compatibility and intentionally unused.

    if ActiveWindow then
        pcall(function()
            ActiveWindow:Unload()
        end)
        ActiveWindow = nil
    end

    local registry = makeRegistry()
    local WindowObj = {}

    local gui = create("ScreenGui", {
        Name = "PiHub_UI",
        ResetOnSpawn = false,
        DisplayOrder = 10,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    pcall(function()
        gui.IgnoreOnInset = true
    end)

    local windowRoot = create("Frame", {
        Name = "WindowRoot",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, gui)

    local mainFrame = create("Frame", {
        Name = "MainFrame",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = WINDOW_SIZE,
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, windowRoot)
    addCorner(mainFrame, 12)
    addStroke(mainFrame, Theme.Border, 1.2)

    local header = create("Frame", {
        Name = "Header",
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
    }, mainFrame)
    addCorner(header, 12)

    create("Frame", {
        Name = "HeaderSpacer",
        Position = UDim2.new(0, 0, 1, -12),
        Size = UDim2.new(1, 0, 0, 12),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
    }, header)

    local titleLabel = create("TextLabel", {
        Name = "Title",
        Position = UDim2.new(0, 14, 0, 11),
        Size = UDim2.new(0, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = windowTitle,
        TextColor3 = Theme.Accent,
        TextSize = 16,
        Font = Fonts.Title,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, header)
    local titleWidth = math.ceil(textWidth(windowTitle, 16, Fonts.Title))
    titleLabel.Size = UDim2.new(0, titleWidth + 2, 0, 20)

    create("TextLabel", {
        Name = "SubTitle",
        Position = UDim2.new(0, 14 + titleWidth + 10, 0, 13),
        Size = UDim2.new(1, -(14 + titleWidth + 58), 0, 16),
        BackgroundTransparency = 1,
        Text = windowSubtitle ~= "" and ("| " .. windowSubtitle) or "",
        TextColor3 = Theme.Muted,
        TextSize = 13,
        Font = Fonts.Body,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, header)

    local closeBtn = create("TextButton", {
        Name = "CloseBtn",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 6),
        Size = UDim2.fromOffset(30, 30),
        BackgroundColor3 = Theme.Component,
        BorderSizePixel = 0,
        Text = "\226\156\149",
        TextColor3 = Theme.Text,
        TextSize = 14,
        Font = Fonts.Title,
        AutoButtonColor = false,
    }, header)
    addCorner(closeBtn, 6)

    local sidebar = create("ScrollingFrame", {
        Name = "Sidebar",
        Position = UDim2.new(0, 0, 0, HEADER_HEIGHT),
        Size = UDim2.new(0, SIDEBAR_WIDTH, 1, -HEADER_HEIGHT),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, mainFrame)
    addCorner(sidebar, 12)

    local tabList = create("Frame", {
        Name = "TabList",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, sidebar)
    create("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 7),
        PaddingRight = UDim.new(0, 7),
    }, tabList)
    create("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, tabList)

    local contentContainer = create("Frame", {
        Name = "ContentContainer",
        Position = UDim2.new(0, SIDEBAR_WIDTH + 8, 0, HEADER_HEIGHT + 8),
        Size = UDim2.new(1, -(SIDEBAR_WIDTH + 16), 1, -(HEADER_HEIGHT + 16)),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, mainFrame)

    local floatIcon = create("ImageButton", {
        Name = "PiHub_FloatingBtn",
        AnchorPoint = Vector2.new(0, 0),
        Position = UDim2.new(0, 16, 0.5, -ICON_SIZE / 2),
        Size = UDim2.fromOffset(ICON_SIZE, ICON_SIZE),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Image = LOGO_ASSET,
        ScaleType = Enum.ScaleType.Fit,
        AutoButtonColor = false,
    }, gui)
    addCorner(floatIcon, 26)
    addStroke(floatIcon, Theme.Accent, 1.5)

    local windowOpen = true

    local function setWindowOpen(open)
        if open == windowOpen then
            return
        end
        windowOpen = open
        if open then
            mainFrame.Visible = true
            tween(mainFrame, 0.25, { Size = WINDOW_SIZE }, BACK, OUT)
        else
            local closeTween = tween(mainFrame, 0.2, { Size = CLOSED_SIZE }, QUAD, EASE_IN)
            local done
            done = closeTween.Completed:Connect(function(state)
                if state == Enum.PlaybackState.Completed then
                    done:Disconnect()
                    if not windowOpen then
                        mainFrame.Visible = false
                    end
                end
            end)
        end
    end

    local dragTarget = nil
    local dragStart = Vector3.zero
    local frameStart = UDim2.fromScale(0.5, 0.5)
    local iconStart = UDim2.new(0, 16, 0.5, -ICON_SIZE / 2)
    local iconMoved = false

    registry:Connect(header.InputBegan, function(input)
        if isPress(input) then
            dragTarget = "window"
            dragStart = input.Position
            frameStart = mainFrame.Position
        end
    end)

    registry:Connect(floatIcon.InputBegan, function(input)
        if isPress(input) then
            dragTarget = "icon"
            iconMoved = false
            dragStart = input.Position
            iconStart = floatIcon.Position
        end
    end)

    registry:Connect(UserInputService.InputChanged, function(input)
        if not dragTarget or not isMove(input) then
            return
        end
        local delta = input.Position - dragStart
        local view = viewportSize()
        if dragTarget == "window" then
            local centerX = math.clamp(view.X * frameStart.X.Scale + frameStart.X.Offset + delta.X, 80, view.X - 80)
            local centerY = math.clamp(view.Y * frameStart.Y.Scale + frameStart.Y.Offset + delta.Y, 50, view.Y - 50)
            mainFrame.Position = UDim2.new(frameStart.X.Scale, centerX - view.X * frameStart.X.Scale, frameStart.Y.Scale, centerY - view.Y * frameStart.Y.Scale)
        elseif dragTarget == "icon" and delta.Magnitude > TAP_THRESHOLD then
            iconMoved = true
            local x = math.clamp(view.X * iconStart.X.Scale + iconStart.X.Offset + delta.X, 0, view.X - ICON_SIZE)
            local y = math.clamp(view.Y * iconStart.Y.Scale + iconStart.Y.Offset + delta.Y, 0, view.Y - ICON_SIZE)
            floatIcon.Position = UDim2.new(0, x, 0, y)
        end
    end)

    registry:Connect(floatIcon.InputEnded, function(input)
        if isPress(input) and dragTarget == "icon" then
            if not iconMoved then
                setWindowOpen(not windowOpen)
            end
            dragTarget = nil
        end
    end)

    registry:Connect(UserInputService.InputEnded, function(input)
        if isPress(input) and dragTarget then
            if dragTarget == "icon" and not iconMoved then
                setWindowOpen(not windowOpen)
            end
            dragTarget = nil
        end
    end)

    local tabs = {}
    local selectedTab = nil

    local function selectTab(tab)
        if selectedTab == tab then
            return
        end
        selectedTab = tab
        for _, entry in ipairs(tabs) do
            local active = entry == tab
            entry.Content.Visible = active
            entry.Indicator.Visible = active
            tween(entry.Button, HOVER_TIME, { BackgroundColor3 = active and Theme.Component or Theme.SwitchOff })
            tween(entry.Label, HOVER_TIME, { TextColor3 = active and Theme.Text or Theme.Muted })
        end
    end

    function WindowObj:MakeTab(tabConfig)
        tabConfig = tabConfig or {}
        local tabName = tostring(tabConfig.Name or tabConfig[1] or ("Tab " .. (#tabs + 1)))
        -- The Icon field is accepted for API compatibility; this build
        -- draws text only and ships zero custom image assets.

        local tabButton = create("TextButton", {
            Name = tabName .. "_TabBtn",
            Size = UDim2.new(0, 116, 0, 36),
            BackgroundColor3 = Theme.SwitchOff,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
        }, tabList)
        addCorner(tabButton, 8)

        local indicator = create("Frame", {
            Name = "Indicator",
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 5, 0.5, 0),
            Size = UDim2.fromOffset(3, 16),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            Visible = false,
        }, tabButton)
        addCorner(indicator, 2)

        local tabLabel = create("TextLabel", {
            Name = "TabLabel",
            Position = UDim2.new(0, 15, 0, 0),
            Size = UDim2.new(1, -22, 1, 0),
            BackgroundTransparency = 1,
            Text = tabName,
            TextColor3 = Theme.Muted,
            TextSize = 13,
            Font = Fonts.Label,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, tabButton)

        local tabContent = create("ScrollingFrame", {
            Name = tabName .. "_Content",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Border,
            ScrollBarImageTransparency = 0.3,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
        }, contentContainer)
        create("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, tabContent)
        create("UIPadding", {
            PaddingTop = UDim.new(0, 2),
            PaddingBottom = UDim.new(0, 12),
            PaddingLeft = UDim.new(0, 2),
            PaddingRight = UDim.new(0, 2),
        }, tabContent)

        local tab = {
            Button = tabButton,
            Content = tabContent,
            Indicator = indicator,
            Label = tabLabel,
        }

        registry:Connect(tabButton.MouseButton1Click, function()
            selectTab(tab)
        end)
        registry:Connect(tabButton.MouseEnter, function()
            if selectedTab ~= tab then
                tween(tabLabel, HOVER_TIME, { TextColor3 = Theme.Text })
            end
        end)
        registry:Connect(tabButton.MouseLeave, function()
            if selectedTab ~= tab then
                tween(tabLabel, HOVER_TIME, { TextColor3 = Theme.Muted })
            end
        end)

        table.insert(tabs, tab)
        if #tabs == 1 then
            selectedTab = tab
            tabContent.Visible = true
            indicator.Visible = true
            tabButton.BackgroundColor3 = Theme.Component
            tabLabel.TextColor3 = Theme.Text
        end

        local TabObj = {}

        function TabObj:AddSection(sectionConfig)
            local sectionName = sectionConfig
            if typeof(sectionConfig) == "table" then
                sectionName = sectionConfig.Name or sectionConfig[1] or "Section"
            end
            sectionName = tostring(sectionName)

            local section = create("Frame", {
                Name = "Section_" .. sectionName,
                Size = UDim2.new(1, 0, 0, 26),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, tabContent)

            local labelWidth = math.ceil(textWidth(sectionName, 13, Fonts.Title))
            create("TextLabel", {
                Name = "SectionLabel",
                Position = UDim2.new(0, 2, 0, 0),
                Size = UDim2.new(0, labelWidth + 8, 1, 0),
                BackgroundTransparency = 1,
                Text = sectionName,
                TextColor3 = Theme.Purple,
                TextSize = 13,
                Font = Fonts.Title,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, section)
            create("Frame", {
                Name = "Separator",
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, labelWidth + 16, 0.5, 0),
                Size = UDim2.new(1, -(labelWidth + 20), 0, 1),
                BackgroundColor3 = Theme.Border,
                BackgroundTransparency = 0.35,
                BorderSizePixel = 0,
            }, section)
        end

        function TabObj:AddButton(buttonConfig)
            buttonConfig = buttonConfig or {}
            local buttonName = tostring(buttonConfig.Name or buttonConfig[1] or "Button")
            local callback = type(buttonConfig.Callback) == "function" and buttonConfig.Callback or function() end

            local row = create("TextButton", {
                Name = "Button_" .. buttonName,
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Theme.Component,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
            }, tabContent)
            addCorner(row, 8)
            addStroke(row, Theme.Border, 1)

            create("TextLabel", {
                Name = "Title",
                Position = UDim2.new(0, 14, 0, 0),
                Size = UDim2.new(1, -28, 1, 0),
                BackgroundTransparency = 1,
                Text = buttonName,
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Fonts.Label,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
            }, row)

            registry:Connect(row.MouseButton1Down, function()
                tween(row, PRESS_TIME, { BackgroundColor3 = Theme.ComponentPressed })
            end)
            registry:Connect(row.MouseButton1Up, function()
                tween(row, STATE_TIME, { BackgroundColor3 = Theme.Component })
            end)
            registry:Connect(row.MouseLeave, function()
                tween(row, STATE_TIME, { BackgroundColor3 = Theme.Component })
            end)
            registry:Connect(row.MouseButton1Click, function()
                callback()
            end)
        end

        function TabObj:AddToggle(toggleConfig)
            toggleConfig = toggleConfig or {}
            local toggleName = tostring(toggleConfig.Name or toggleConfig[1] or "Toggle")
            local description = toggleConfig.Description
            local hasDescription = type(description) == "string" and description ~= ""
            local state = toggleConfig.Default == true
            local callback = type(toggleConfig.Callback) == "function" and toggleConfig.Callback or function() end
            local rowHeight = hasDescription and 44 or 38

            local row = create("TextButton", {
                Name = "Toggle_" .. toggleName,
                Size = UDim2.new(1, 0, 0, rowHeight),
                BackgroundColor3 = Theme.Component,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
            }, tabContent)
            addCorner(row, 8)
            addStroke(row, Theme.Border, 1)

            create("TextLabel", {
                Name = "Title",
                Position = UDim2.new(0, 12, 0, hasDescription and 6 or 0),
                Size = UDim2.new(1, -70, 0, hasDescription and 16 or rowHeight),
                BackgroundTransparency = 1,
                Text = toggleName,
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Fonts.Label,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
            }, row)

            if hasDescription then
                create("TextLabel", {
                    Name = "Description",
                    Position = UDim2.new(0, 12, 0, 24),
                    Size = UDim2.new(1, -70, 0, 14),
                    BackgroundTransparency = 1,
                    Text = description,
                    TextColor3 = Theme.Muted,
                    TextSize = 11,
                    Font = Fonts.Body,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                }, row)
            end

            local track = create("Frame", {
                Name = "Track",
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(40, 20),
                BackgroundColor3 = Theme.SwitchOff,
                BorderSizePixel = 0,
            }, row)
            addCorner(track, 10)

            local thumb = create("Frame", {
                Name = "Thumb",
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 2, 0.5, 0),
                Size = UDim2.fromOffset(16, 16),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
            }, track)
            addCorner(thumb, 8)

            local function paint(animated)
                local trackColor = state and Theme.Accent or Theme.SwitchOff
                local thumbPos = state and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
                if animated then
                    tween(track, STATE_TIME, { BackgroundColor3 = trackColor })
                    tween(thumb, STATE_TIME, { Position = thumbPos })
                else
                    track.BackgroundColor3 = trackColor
                    thumb.Position = thumbPos
                end
            end

            paint(false)
            if state then
                callback(true)
            end

            registry:Connect(row.MouseButton1Click, function()
                state = not state
                paint(true)
                callback(state)
            end)
        end

        function TabObj:AddSlider(sliderConfig)
            sliderConfig = sliderConfig or {}
            local sliderName = tostring(sliderConfig.Name or sliderConfig[1] or "Slider")
            local minValue = tonumber(sliderConfig.Min) or 0
            local maxValue = tonumber(sliderConfig.Max) or 100
            if maxValue <= minValue then
                maxValue = minValue + 1
            end
            local step = tonumber(sliderConfig.Increase) or 1
            if step <= 0 then
                step = 1
            end
            local defaultValue = tonumber(sliderConfig.Default) or minValue
            local callback = type(sliderConfig.Callback) == "function" and sliderConfig.Callback or function() end

            local row = create("Frame", {
                Name = "Slider_" .. sliderName,
                Size = UDim2.new(1, 0, 0, 50),
                BackgroundColor3 = Theme.Component,
                BorderSizePixel = 0,
            }, tabContent)
            addCorner(row, 8)
            addStroke(row, Theme.Border, 1)

            create("TextLabel", {
                Name = "Title",
                Position = UDim2.new(0, 12, 0, 7),
                Size = UDim2.new(1, -84, 0, 16),
                BackgroundTransparency = 1,
                Text = sliderName,
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Fonts.Label,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
            }, row)

            local valueLabel = create("TextLabel", {
                Name = "Value",
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -12, 0, 7),
                Size = UDim2.new(0, 64, 0, 16),
                BackgroundTransparency = 1,
                Text = tostring(defaultValue),
                TextColor3 = Theme.Purple,
                TextSize = 12,
                Font = Fonts.Title,
                TextXAlignment = Enum.TextXAlignment.Right,
            }, row)

            local bar = create("Frame", {
                Name = "SliderBar",
                Position = UDim2.new(0, 12, 1, -20),
                Size = UDim2.new(1, -24, 0, 14),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Active = true,
            }, row)

            local track = create("Frame", {
                Name = "Track",
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(1, 0, 0, 6),
                BackgroundColor3 = Theme.SwitchOff,
                BorderSizePixel = 0,
            }, bar)
            addCorner(track, 3)

            local fill = create("Frame", {
                Name = "Fill",
                Size = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
            }, track)
            addCorner(fill, 3)

            local current = minValue
            local dragging = false

            local function snap(raw)
                local steps = math.floor((raw - minValue) / step + 0.5)
                local stepped = math.clamp(minValue + steps * step, minValue, maxValue)
                return math.floor(stepped * 1000 + 0.5) / 1000
            end

            local function paint(value)
                local fraction = (value - minValue) / (maxValue - minValue)
                fill.Size = UDim2.new(fraction, 0, 1, 0)
                valueLabel.Text = tostring(value)
            end

            local function setFromX(x)
                local fraction = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
                local stepped = snap(minValue + fraction * (maxValue - minValue))
                if stepped ~= current then
                    current = stepped
                    paint(current)
                    callback(current)
                end
            end

            registry:Connect(bar.InputBegan, function(input)
                if isPress(input) then
                    dragging = true
                    setFromX(input.Position.X)
                end
            end)
            registry:Connect(UserInputService.InputChanged, function(input)
                if dragging and isMove(input) then
                    setFromX(input.Position.X)
                end
            end)
            registry:Connect(UserInputService.InputEnded, function(input)
                if dragging and isPress(input) then
                    dragging = false
                end
            end)

            current = snap(defaultValue)
            paint(current)
            callback(current)
        end

        function TabObj:AddDropdown(dropdownConfig)
            dropdownConfig = dropdownConfig or {}
            local dropdownName = tostring(dropdownConfig.Name or dropdownConfig[1] or "Dropdown")
            local options = {}
            for _, option in ipairs(dropdownConfig.Options or {}) do
                table.insert(options, option)
            end
            local defaultOption = dropdownConfig.Default
            local callback = type(dropdownConfig.Callback) == "function" and dropdownConfig.Callback or function() end

            local COLLAPSED = 38
            local OPTION_HEIGHT = 30
            local MAX_VISIBLE = 6
            local visibleCount = math.max(1, math.min(#options, MAX_VISIBLE))
            local listHeight = visibleCount * OPTION_HEIGHT + 8
            local EXPANDED = COLLAPSED + 6 + listHeight

            local container = create("Frame", {
                Name = "Dropdown_" .. dropdownName,
                Size = UDim2.new(1, 0, 0, COLLAPSED),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ClipsDescendants = true,
            }, tabContent)

            local selector = create("TextButton", {
                Name = "Selector",
                Size = UDim2.new(1, 0, 0, COLLAPSED),
                BackgroundColor3 = Theme.Component,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
            }, container)
            addCorner(selector, 8)
            addStroke(selector, Theme.Border, 1)

            create("TextLabel", {
                Name = "Title",
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(0.4, -12, 1, 0),
                BackgroundTransparency = 1,
                Text = dropdownName,
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Fonts.Label,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
            }, selector)

            local selectedLabel = create("TextLabel", {
                Name = "Selected",
                Position = UDim2.new(0.4, 0, 0, 0),
                Size = UDim2.new(0.6, -34, 1, 0),
                BackgroundTransparency = 1,
                Text = "Select...",
                TextColor3 = Theme.Muted,
                TextSize = 12,
                Font = Fonts.Body,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextTruncate = Enum.TextTruncate.AtEnd,
            }, selector)

            create("TextLabel", {
                Name = "Chevron",
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(14, 14),
                BackgroundTransparency = 1,
                Text = "\226\150\190",
                TextColor3 = Theme.Muted,
                TextSize = 12,
                Font = Fonts.Body,
            }, selector)

            local optionsList = create("ScrollingFrame", {
                Name = "OptionsList",
                Position = UDim2.new(0, 0, 0, COLLAPSED + 6),
                Size = UDim2.new(1, 0, 0, listHeight),
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel = 0,
                ScrollBarThickness = 2,
                ScrollBarImageColor3 = Theme.Border,
                ScrollBarImageTransparency = 0.3,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                Visible = false,
            }, container)
            addCorner(optionsList, 8)
            addStroke(optionsList, Theme.Border, 1)
            create("UIPadding", {
                PaddingTop = UDim.new(0, 4),
                PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 4),
                PaddingRight = UDim.new(0, 4),
            }, optionsList)
            create("UIListLayout", {
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, optionsList)

            local isOpen = false
            local selected = nil
            local optionEntries = {}

            local function setOpen(open)
                if open == isOpen then
                    return
                end
                isOpen = open
                if open then
                    optionsList.Visible = true
                    tween(container, DROP_TIME, { Size = UDim2.new(1, 0, 0, EXPANDED) }, QUINT, OUT)
                else
                    local closeTween = tween(container, DROP_TIME, { Size = UDim2.new(1, 0, 0, COLLAPSED) }, QUINT, EASE_IN)
                    local done
                    done = closeTween.Completed:Connect(function(state)
                        if state == Enum.PlaybackState.Completed then
                            done:Disconnect()
                            if not isOpen then
                                optionsList.Visible = false
                            end
                        end
                    end)
                end
            end

            local function paintOptions()
                for _, entry in ipairs(optionEntries) do
                    entry.Label.TextColor3 = entry.Value == selected and Theme.Accent or Theme.Muted
                end
            end

            for index, option in ipairs(options) do
                local optionButton = create("TextButton", {
                    Name = "Option_" .. index,
                    Size = UDim2.new(1, 0, 0, OPTION_HEIGHT),
                    BackgroundColor3 = Theme.Component,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Text = "",
                    AutoButtonColor = false,
                    LayoutOrder = index,
                }, optionsList)
                addCorner(optionButton, 6)

                local optionLabel = create("TextLabel", {
                    Name = "Title",
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -20, 1, 0),
                    BackgroundTransparency = 1,
                    Text = tostring(option),
                    TextColor3 = Theme.Muted,
                    TextSize = 12,
                    Font = Fonts.Body,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                }, optionButton)

                table.insert(optionEntries, {
                    Button = optionButton,
                    Label = optionLabel,
                    Value = option,
                })

                registry:Connect(optionButton.MouseEnter, function()
                    if option ~= selected then
                        tween(optionButton, HOVER_TIME, { BackgroundTransparency = 0.5 })
                    end
                end)
                registry:Connect(optionButton.MouseLeave, function()
                    tween(optionButton, HOVER_TIME, { BackgroundTransparency = 1 })
                end)
                registry:Connect(optionButton.MouseButton1Click, function()
                    selected = option
                    selectedLabel.Text = tostring(option)
                    selectedLabel.TextColor3 = Theme.Accent
                    paintOptions()
                    setOpen(false)
                    callback(option)
                end)
            end

            registry:Connect(selector.MouseButton1Click, function()
                setOpen(not isOpen)
            end)

            if defaultOption ~= nil then
                selected = defaultOption
                selectedLabel.Text = tostring(defaultOption)
                selectedLabel.TextColor3 = Theme.Accent
            end
            paintOptions()

            if defaultOption ~= nil then
                callback(defaultOption)
            end
        end

        return TabObj
    end

    local activeDialog = nil

    function WindowObj:Dialog(dialogConfig)
        dialogConfig = dialogConfig or {}
        local dialogTitle = tostring(dialogConfig.Title or dialogConfig[1] or "Dialog")
        local dialogText = tostring(dialogConfig.Text or dialogConfig[2] or "")
        local optionList = dialogConfig.Options or { { "OK", function() end } }
        if #optionList == 0 then
            optionList = { { "OK", function() end } }
        end

        if activeDialog then
            pcall(function()
                activeDialog:Destroy()
            end)
            activeDialog = nil
        end

        local backdrop = create("TextButton", {
            Name = "ModalBackdrop",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 0.45,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 100,
        }, gui)

        local card = create("Frame", {
            Name = "DialogCard",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(0, 300, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Theme.Component,
            BorderSizePixel = 0,
            ZIndex = 101,
        }, backdrop)
        addCorner(card, 10)
        addStroke(card, Theme.Border, 1)
        create("UIPadding", {
            PaddingTop = UDim.new(0, 14),
            PaddingBottom = UDim.new(0, 14),
            PaddingLeft = UDim.new(0, 14),
            PaddingRight = UDim.new(0, 14),
        }, card)
        create("UIListLayout", {
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, card)

        create("TextLabel", {
            Name = "DialogTitle",
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            Text = dialogTitle,
            TextColor3 = Theme.Danger,
            TextSize = 15,
            Font = Fonts.Title,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 102,
            LayoutOrder = 1,
        }, card)

        create("TextLabel", {
            Name = "DialogText",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text = dialogText,
            TextColor3 = Theme.Text,
            TextSize = 13,
            Font = Fonts.Body,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            ZIndex = 102,
            LayoutOrder = 2,
        }, card)

        local buttonRow = create("Frame", {
            Name = "DialogButtons",
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = 3,
        }, card)
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, buttonRow)

        for index, option in ipairs(optionList) do
            local label
            local optionCallback
            if typeof(option) == "table" then
                label = tostring(option[1] or option.Name or ("Option " .. index))
                if type(option[2]) == "function" then
                    optionCallback = option[2]
                elseif type(option.Callback) == "function" then
                    optionCallback = option.Callback
                else
                    optionCallback = function() end
                end
            else
                label = tostring(option)
                optionCallback = function() end
            end

            local lowered = string.lower(label)
            local destructive = lowered:find("unload", 1, true) ~= nil
                or lowered:find("delete", 1, true) ~= nil
                or lowered:find("remove", 1, true) ~= nil
                or lowered:find("yes", 1, true) ~= nil
                or lowered:find("confirm", 1, true) ~= nil
                or lowered:find("quit", 1, true) ~= nil
            local isCancel = index == 1 and not destructive

            local width = math.max(72, math.ceil(textWidth(label, 13, Fonts.Label)) + 28)
            local button = create("TextButton", {
                Name = "DialogBtn" .. index,
                Size = UDim2.new(0, width, 1, 0),
                BackgroundColor3 = destructive and Theme.Danger or (isCancel and Theme.SwitchOff or Theme.Accent),
                BorderSizePixel = 0,
                Text = label,
                TextColor3 = isCancel and Theme.Muted or Theme.OnAccent,
                TextSize = 13,
                Font = destructive and Fonts.Title or Fonts.Label,
                AutoButtonColor = false,
                LayoutOrder = index,
                ZIndex = 102,
            }, buttonRow)
            addCorner(button, 8)

            registry:Connect(button.MouseButton1Click, function()
                if activeDialog == backdrop then
                    activeDialog = nil
                end
                pcall(function()
                    backdrop:Destroy()
                end)
                optionCallback()
            end)
        end

        activeDialog = backdrop
    end

    function WindowObj:Unload()
        print("[PiHub] Unloading UI completely...")
        registry:Dispose()
        pcall(function()
            gui:Destroy()
        end)
        if ActiveWindow == WindowObj then
            ActiveWindow = nil
        end
    end

    registry:Connect(closeBtn.MouseButton1Click, function()
        WindowObj:Dialog({
            Title = "Unload PiHub",
            Text = "Do you want to permanently unload the script?",
            Options = {
                { "Cancel", function() end },
                { "Unload", function()
                    WindowObj:Unload()
                end },
            },
        })
    end)

    gui.Parent = resolveMountParent()

    ActiveWindow = WindowObj
    return WindowObj
end

PiHub.Theme = Theme

return PiHub
