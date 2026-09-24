--[[
    PiHub V5 :: Tokyo Night Edition, rework
    ----------------------------------------------------------------
    Standalone single-file UI library for Roblox. No external assets,
    no HttpGet, engine instances only. Every glyph is text or a
    composed frame, so the library draws offline.

    Design read
        ENERGY 2 of 5: a calm instrument panel above the game.
        RHYTHM 2 of 5: one spacing scale (4, 8, 12, 16, 24) and one row
        language. Variation lives inside the controls, not the cards.
        MOTION 2 of 5: Quint at 0.12 to 0.25 seconds for state changes,
        one gentle Back ease reserved for the window and dialog
        entrance, and zero idle loops.

    Identity motif
        The notch: a 3px rounded accent bar. It marks the brand in the
        header, the selected tab, each section header, and the selected
        dropdown row. It is the only decorative element in the system.

    Color roles (Tokyo Night)
        Background     #1a1b26  window base
        Surface        #16161e  sunken areas (sidebar, option list)
        Component      #24283b  rows and controls at rest
        ComponentHover #292e42  one step lighter, hover only
        Border         #414868  window edge and resting tracks
        Accent         #7aa2f7  active or interactive state, nothing else
        Value          #bb9af7  numeric readouts only (slider counter)
        Danger         #f7768e  the destructive dialog action only
        DangerHover    #e56982  one step darker, hover on that action
        Text           #c0caf5  primary labels
        Muted          #565f89  secondary labels
        OnAccent       #090a10  text on filled accent or danger, shadow

    Public API (identical to V5)
        PiHub:MakeWindow({ Title = "PiHub", SubTitle = "Online V5" })
        Window:MakeTab({ "Tab Name" })
        Window:Dialog({ Title = "", Text = "", Options = { { "Label", fn } } })
        Window:Unload()
        Tab:AddSection({ "Section" })
        Tab:AddButton({ Name = "", Description = "", Callback = fn })
        Tab:AddToggle({ Name = "", Description = "", Default = false, Callback = fn })
        Tab:AddSlider({ Name = "", Min = 0, Max = 100, Increase = 1, Default = 0, Callback = fn })
        Tab:AddDropdown({ Name = "", Options = {}, Default = "", Callback = fn })

    Behavior kept from V5
        A slider and a dropdown invoke Callback once at construction
        with the resolved default. A toggle does the same when Default
        is true. Button callbacks run on click only. SaveFolder is
        accepted and intentionally unused.
--]]


local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local PiHub = {}
PiHub.Version = "5.2.0-tokyo"

local Theme = {
    Background = Color3.fromRGB(26, 27, 38),
    Surface = Color3.fromRGB(22, 22, 30),
    Component = Color3.fromRGB(36, 40, 59),
    ComponentHover = Color3.fromRGB(41, 46, 66),
    Border = Color3.fromRGB(65, 72, 104),
    Accent = Color3.fromRGB(122, 162, 247),
    Value = Color3.fromRGB(187, 154, 247),
    Danger = Color3.fromRGB(247, 118, 142),
    DangerHover = Color3.fromRGB(229, 105, 130),
    Text = Color3.fromRGB(192, 202, 245),
    Muted = Color3.fromRGB(86, 95, 137),
    OnAccent = Color3.fromRGB(9, 10, 16),
}
Theme.AccentSecondary = Theme.Value
Theme.TextMuted = Theme.Muted

local Fonts = {
    Title = Enum.Font.GothamBold,
    Label = Enum.Font.GothamMedium,
    Body = Enum.Font.Gotham,
}

local WINDOW_WIDTH = 540
local WINDOW_HEIGHT = 340
local HEADER_HEIGHT = 48
local SIDEBAR_WIDTH = 148
local MIN_UI_SCALE = 0.55

local HOVER_TIME = 0.12
local STATE_TIME = 0.18
local OPEN_TIME = 0.3

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

local function tween(inst, duration, props, style, direction)
    local handle = TweenService:Create(inst, TweenInfo.new(duration, style or QUINT, direction or OUT), props)
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

local function addNotch(parent, height)
    local bar = create("Frame", {
        Name = "Notch",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(3, height),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
    }, parent)
    addCorner(bar, 2)
    return bar
end

local function viewportSize()
    local camera = workspace.CurrentCamera
    if camera then
        return camera.ViewportSize
    end
    return Vector2.new(1280, 720)
end

local function getContainer()
    local ok, hui = pcall(function()
        return gethui()
    end)
    if ok and typeof(hui) == "Instance" then
        return hui
    end
    local okCore = pcall(function()
        local probe = Instance.new("Folder")
        probe.Parent = CoreGui
        probe:Destroy()
    end)
    if okCore then
        return CoreGui
    end
    return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function textWidth(text, size, font)
    local bounds = TextService:GetTextSize(text, size, font, Vector2.new(100000, 100))
    return bounds.X
end


function PiHub:MakeWindow(windowConfig)
    local config = windowConfig or {}
    local titleText = tostring(config.Title or "PiHub")
    local subTitleText = tostring(config.SubTitle or "")

    if ActiveWindow then
        pcall(function()
            ActiveWindow:Unload()
        end)
    end

    local registry = makeRegistry()

    local screenGui = create("ScreenGui", {
        Name = "PiHub_UI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
    }, getContainer())

    local WindowObj = { ScreenGui = screenGui }

    local windowRoot = create("Frame", {
        Name = "WindowRoot",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(WINDOW_WIDTH, WINDOW_HEIGHT),
        BackgroundTransparency = 1,
    }, screenGui)
    local rootScale = create("UIScale", { Name = "UIScale", Scale = 1 }, windowRoot)

    local shadow = create("Frame", {
        Name = "WindowShadow",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 10),
        Size = UDim2.new(1, -24, 1, -10),
        BackgroundColor3 = Theme.OnAccent,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
    }, windowRoot)
    addCorner(shadow, 14)

    local mainFrame = create("Frame", {
        Name = "MainFrame",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, windowRoot)
    addCorner(mainFrame, 12)
    create("UIStroke", {
        Color = Theme.Border,
        Thickness = 1,
        Transparency = 0.25,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, mainFrame)

    local header = create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
        BackgroundTransparency = 1,
    }, mainFrame)

    local headerNotch = addNotch(header, 15)
    headerNotch.Position = UDim2.new(0, 16, 0.5, 0)

    local titleGroup = create("Frame", {
        Name = "TitleGroup",
        Position = UDim2.new(0, 28, 0, 0),
        Size = UDim2.new(1, -92, 1, 0),
        BackgroundTransparency = 1,
    }, header)
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, titleGroup)

    create("TextLabel", {
        Name = "Title",
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromScale(0, 1),
        BackgroundTransparency = 1,
        Text = titleText,
        TextColor3 = Theme.Text,
        TextSize = 15,
        Font = Fonts.Title,
        LayoutOrder = 1,
    }, titleGroup)

    if subTitleText ~= "" then
        create("TextLabel", {
            Name = "SubTitle",
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromScale(0, 1),
            BackgroundTransparency = 1,
            Text = subTitleText,
            TextColor3 = Theme.Muted,
            TextSize = 11,
            Font = Fonts.Body,
            LayoutOrder = 2,
        }, titleGroup)
    end

    local closeButton = create("TextButton", {
        Name = "CloseBtn",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(28, 28),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
    }, header)

    local function makeCloseBar(name, rotation)
        local bar = create("Frame", {
            Name = name,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(13, 2),
            Rotation = rotation,
            BackgroundColor3 = Theme.Muted,
            BorderSizePixel = 0,
        }, closeButton)
        addCorner(bar, 1)
        return bar
    end
    local closeBarA = makeCloseBar("BarA", 45)
    local closeBarB = makeCloseBar("BarB", -45)

    create("Frame", {
        Name = "HeaderHairline",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Border,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
    }, header)


    local sidebar = create("Frame", {
        Name = "Sidebar",
        Position = UDim2.new(0, 0, 0, HEADER_HEIGHT + 1),
        Size = UDim2.new(0, SIDEBAR_WIDTH, 1, -(HEADER_HEIGHT + 1)),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
    }, mainFrame)

    local tabList = create("Frame", {
        Name = "TabList",
        Position = UDim2.new(0, 12, 0, 12),
        Size = UDim2.new(1, -24, 1, -58),
        BackgroundTransparency = 1,
    }, sidebar)
    create("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, tabList)

    create("TextLabel", {
        Name = "FooterLabel",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 16, 1, -12),
        Size = UDim2.new(1, -32, 0, 14),
        BackgroundTransparency = 1,
        Text = "v5.2 tokyo night",
        TextColor3 = Theme.Muted,
        TextSize = 10,
        Font = Fonts.Body,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, sidebar)

    local contentContainer = create("Frame", {
        Name = "ContentContainer",
        Position = UDim2.new(0, SIDEBAR_WIDTH, 0, HEADER_HEIGHT + 1),
        Size = UDim2.new(1, -SIDEBAR_WIDTH, 1, -(HEADER_HEIGHT + 1)),
        BackgroundTransparency = 1,
    }, mainFrame)

    local anchor = create("TextButton", {
        Name = "PiHub_FloatingBtn",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, -60, 0.5, 0),
        Size = UDim2.fromOffset(52, 52),
        BackgroundColor3 = Theme.Component,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 5,
    }, screenGui)
    addCorner(anchor, 26)
    create("UIStroke", {
        Color = Theme.Border,
        Thickness = 1,
        Transparency = 0.25,
    }, anchor)
    local anchorScale = create("UIScale", { Name = "UIScale", Scale = 1 }, anchor)

    create("TextLabel", {
        Name = "Monogram",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "P",
        TextColor3 = Theme.Accent,
        TextSize = 19,
        Font = Fonts.Title,
        ZIndex = 6,
    }, anchor)

    local baseScale = 1
    local windowOpen = true

    local function applyResponsiveScale()
        local size = viewportSize()
        baseScale = math.clamp(math.min((size.X - 32) / WINDOW_WIDTH, (size.Y - 32) / WINDOW_HEIGHT), MIN_UI_SCALE, 1)
        if windowOpen then
            rootScale.Scale = baseScale
        end
    end

    local function setWindowOpen(open)
        if open == windowOpen then
            return
        end
        windowOpen = open
        if open then
            windowRoot.Visible = true
            rootScale.Scale = baseScale * 0.94
            tween(rootScale, OPEN_TIME, { Scale = baseScale }, BACK, OUT)
        else
            local closeTween = tween(rootScale, 0.16, { Scale = baseScale * 0.94 }, QUINT, EASE_IN)
            closeTween.Completed:Connect(function()
                if not windowOpen then
                    windowRoot.Visible = false
                end
            end)
        end
    end


    local draggingWindow = false
    local draggingAnchor = false
    local anchorMoved = false
    local dragStartPosition = Vector2.zero
    local rootStartPosition = UDim2.fromScale(0, 0)
    local anchorStartCenter = Vector2.zero

    registry:Connect(header.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingWindow = true
            dragStartPosition = input.Position
            rootStartPosition = windowRoot.Position
        end
    end)

    registry:Connect(anchor.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingAnchor = true
            anchorMoved = false
            dragStartPosition = input.Position
            local size = viewportSize()
            anchorStartCenter = Vector2.new(
                size.X * anchor.Position.X.Scale + anchor.Position.X.Offset,
                size.Y * anchor.Position.Y.Scale + anchor.Position.Y.Offset
            )
        end
    end)

    registry:Connect(UserInputService.InputChanged, function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        local size = viewportSize()
        if draggingWindow then
            local delta = input.Position - dragStartPosition
            local scaleX = rootStartPosition.X.Scale
            local scaleY = rootStartPosition.Y.Scale
            local centerX = math.clamp(size.X * scaleX + rootStartPosition.X.Offset + delta.X, 60, size.X - 60)
            local centerY = math.clamp(size.Y * scaleY + rootStartPosition.Y.Offset + delta.Y, 40, size.Y - 40)
            windowRoot.Position = UDim2.new(scaleX, centerX - size.X * scaleX, scaleY, centerY - size.Y * scaleY)
        elseif draggingAnchor then
            local delta = input.Position - dragStartPosition
            if delta.Magnitude > 6 then
                anchorMoved = true
            end
            local x = math.clamp(anchorStartCenter.X + delta.X, 34, size.X - 34)
            local y = math.clamp(anchorStartCenter.Y + delta.Y, 34, size.Y - 34)
            anchor.Position = UDim2.fromOffset(x, y)
        end
    end)

    registry:Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingWindow = false
            draggingAnchor = false
        end
    end)

    registry:Connect(anchor.MouseButton1Down, function()
        tween(anchorScale, 0.08, { Scale = 0.9 })
    end)
    registry:Connect(anchor.MouseButton1Up, function()
        tween(anchorScale, 0.2, { Scale = 1 })
    end)
    registry:Connect(anchor.MouseButton1Click, function()
        if not anchorMoved then
            setWindowOpen(not windowOpen)
        end
    end)

    registry:Connect(closeButton.MouseEnter, function()
        tween(closeBarA, HOVER_TIME, { BackgroundColor3 = Theme.Text })
        tween(closeBarB, HOVER_TIME, { BackgroundColor3 = Theme.Text })
    end)
    registry:Connect(closeButton.MouseLeave, function()
        tween(closeBarA, HOVER_TIME, { BackgroundColor3 = Theme.Muted })
        tween(closeBarB, HOVER_TIME, { BackgroundColor3 = Theme.Muted })
    end)
    registry:Connect(closeButton.MouseButton1Click, function()
        WindowObj:Dialog({
            Title = "Unload PiHub?",
            Text = "This removes the interface and disconnects everything it created.",
            Options = {
                { "Cancel", function() end },
                { "Unload", function()
                    WindowObj:Unload()
                end },
            },
        })
    end)

    local camera = workspace.CurrentCamera
    if camera then
        registry:Connect(camera:GetPropertyChangedSignal("ViewportSize"), applyResponsiveScale)
    end


    local tabs = {}
    local selectedTab = nil

    local function selectTab(tab)
        if selectedTab == tab then
            return
        end
        selectedTab = tab
        for _, entry in ipairs(tabs) do
            local isSelected = entry == tab
            entry.Content.Visible = isSelected
            entry.Notch.Visible = isSelected
            tween(entry.Button, STATE_TIME, { BackgroundTransparency = isSelected and 0 or 1 })
            tween(entry.Label, STATE_TIME, { TextColor3 = isSelected and Theme.Text or Theme.Muted })
        end
    end

    local currentDialog = nil

    function WindowObj:Dialog(dialogConfig)
        local options = dialogConfig or {}
        local dialogTitle = tostring(options.Title or "Notice")
        local dialogText = tostring(options.Text or "")
        local optionList = options.Options or { { "OK", function() end } }

        if currentDialog then
            pcall(function()
                currentDialog:Destroy()
            end)
        end

        local backdrop = create("TextButton", {
            Name = "ModalBackdrop",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Theme.OnAccent,
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            Active = true,
            ZIndex = 50,
        }, screenGui)
        currentDialog = backdrop

        local card = create("Frame", {
            Name = "DialogCard",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(0, 340, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Theme.Background,
            BorderSizePixel = 0,
            ZIndex = 51,
        }, backdrop)
        addCorner(card, 12)
        create("UIStroke", {
            Color = Theme.Border,
            Thickness = 1,
            Transparency = 0.25,
        }, card)
        local cardScale = create("UIScale", { Name = "UIScale", Scale = 0.94 }, card)

        create("UIPadding", {
            PaddingTop = UDim.new(0, 18),
            PaddingBottom = UDim.new(0, 18),
            PaddingLeft = UDim.new(0, 20),
            PaddingRight = UDim.new(0, 20),
        }, card)
        create("UIListLayout", {
            Padding = UDim.new(0, 12),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, card)

        create("TextLabel", {
            Name = "DialogTitle",
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            Text = dialogTitle,
            TextColor3 = Theme.Text,
            TextSize = 15,
            Font = Fonts.Title,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 52,
            LayoutOrder = 1,
        }, card)

        create("TextLabel", {
            Name = "DialogText",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text = dialogText,
            TextColor3 = Theme.Muted,
            TextSize = 12,
            Font = Fonts.Body,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            ZIndex = 52,
            LayoutOrder = 2,
        }, card)

        local buttonRow = create("Frame", {
            Name = "DialogButtons",
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundTransparency = 1,
            LayoutOrder = 3,
        }, card)
        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, buttonRow)


        local optionCount = #optionList
        for index, option in ipairs(optionList) do
            local label
            local optionCallback
            if typeof(option) == "table" then
                label = tostring(option[1] or ("Option " .. index))
                optionCallback = typeof(option[2]) == "function" and option[2] or function() end
            else
                label = tostring(option)
                optionCallback = function() end
            end
            local isPrimary = index == optionCount
            local labelFont = isPrimary and Fonts.Title or Fonts.Label
            local width = math.max(64, math.ceil(textWidth(label, 13, labelFont)) + 30)

            local button = create("TextButton", {
                Name = "DialogBtn" .. index,
                Size = UDim2.new(0, width, 1, 0),
                BackgroundColor3 = isPrimary and Theme.Danger or Theme.Component,
                BackgroundTransparency = isPrimary and 0 or 1,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = index,
                ZIndex = 52,
            }, buttonRow)
            addCorner(button, 8)
            local buttonScale = create("UIScale", { Name = "UIScale", Scale = 1 }, button)

            local buttonLabel = create("TextLabel", {
                Name = "DialogBtnLabel",
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = label,
                TextColor3 = isPrimary and Theme.OnAccent or Theme.Muted,
                TextSize = 13,
                Font = labelFont,
                ZIndex = 53,
            }, button)

            registry:Connect(button.MouseEnter, function()
                if isPrimary then
                    tween(button, HOVER_TIME, { BackgroundColor3 = Theme.DangerHover })
                else
                    tween(button, HOVER_TIME, { BackgroundTransparency = 0.5 })
                    tween(buttonLabel, HOVER_TIME, { TextColor3 = Theme.Text })
                end
            end)
            registry:Connect(button.MouseLeave, function()
                if isPrimary then
                    tween(button, HOVER_TIME, { BackgroundColor3 = Theme.Danger })
                else
                    tween(button, HOVER_TIME, { BackgroundTransparency = 1 })
                    tween(buttonLabel, HOVER_TIME, { TextColor3 = Theme.Muted })
                end
            end)
            registry:Connect(button.MouseButton1Down, function()
                tween(buttonScale, 0.08, { Scale = 0.96 })
            end)
            registry:Connect(button.MouseButton1Up, function()
                tween(buttonScale, 0.2, { Scale = 1 })
            end)
            registry:Connect(button.MouseButton1Click, function()
                if currentDialog == backdrop then
                    currentDialog = nil
                end
                backdrop:Destroy()
                optionCallback()
            end)
        end

        tween(backdrop, 0.18, { BackgroundTransparency = 0.45 })
        tween(cardScale, OPEN_TIME, { Scale = 1 }, BACK, OUT)
    end

    function WindowObj:Unload()
        print("[PiHub] Unloading UI completely...")
        if ActiveWindow == WindowObj then
            ActiveWindow = nil
        end
        currentDialog = nil
        registry:Dispose()
        screenGui:Destroy()
    end


    function WindowObj:MakeTab(tabConfig)
        local tabOptions = tabConfig or {}
        local tabName = tostring(tabOptions[1] or tabOptions.Name or "Tab")

        local tabButton = create("TextButton", {
            Name = tabName .. "_TabBtn",
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = Theme.Component,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
        }, tabList)
        addCorner(tabButton, 6)

        local tabNotch = addNotch(tabButton, 14)
        tabNotch.Position = UDim2.new(0, 6, 0.5, 0)
        tabNotch.Visible = false

        local tabLabel = create("TextLabel", {
            Name = "TabLabel",
            Position = UDim2.new(0, 16, 0, 0),
            Size = UDim2.new(1, -24, 1, 0),
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
            ScrollBarImageTransparency = 0.4,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
        }, contentContainer)
        create("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, tabContent)
        create("UIPadding", {
            PaddingTop = UDim.new(0, 14),
            PaddingBottom = UDim.new(0, 16),
            PaddingLeft = UDim.new(0, 16),
            PaddingRight = UDim.new(0, 16),
        }, tabContent)

        local tab = {
            Button = tabButton,
            Content = tabContent,
            Notch = tabNotch,
            Label = tabLabel,
        }

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
        registry:Connect(tabButton.MouseButton1Click, function()
            selectTab(tab)
        end)

        table.insert(tabs, tab)
        if #tabs == 1 then
            selectedTab = tab
            tabContent.Visible = true
            tabNotch.Visible = true
            tabButton.BackgroundTransparency = 0
            tabLabel.TextColor3 = Theme.Text
        end

        local TabObj = {}

        function TabObj:AddSection(sectionConfig)
            local name = sectionConfig
            if typeof(sectionConfig) == "table" then
                name = sectionConfig[1] or sectionConfig.Name or "Section"
            end
            name = tostring(name or "Section")

            local section = create("Frame", {
                Name = "Section_" .. name,
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundTransparency = 1,
            }, tabContent)

            local sectionNotch = addNotch(section, 12)
            sectionNotch.AnchorPoint = Vector2.new(0, 1)
            sectionNotch.Position = UDim2.new(0, 2, 1, -4)

            create("TextLabel", {
                Name = "Title",
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.new(0, 12, 1, -2),
                Size = UDim2.new(1, -12, 0, 16),
                BackgroundTransparency = 1,
                Text = name,
                TextColor3 = Theme.Muted,
                TextSize = 12,
                Font = Fonts.Title,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
            }, section)

            return section
        end


        function TabObj:AddButton(buttonConfig)
            local buttonOptions = buttonConfig or {}
            local Name = buttonOptions.Name or buttonOptions[1] or "Button"
            local Description = buttonOptions.Description or ""
            local Callback = buttonOptions.Callback or function() end
            local hasDescription = Description ~= ""

            local row = create("TextButton", {
                Name = "Button_" .. tostring(Name),
                Size = UDim2.new(1, 0, 0, hasDescription and 52 or 38),
                BackgroundColor3 = Theme.Component,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
            }, tabContent)
            addCorner(row, 8)
            local rowScale = create("UIScale", { Name = "UIScale", Scale = 1 }, row)

            create("TextLabel", {
                Name = "Title",
                Position = UDim2.new(0, 14, 0, hasDescription and 9 or 0),
                Size = hasDescription and UDim2.new(1, -28, 0, 16) or UDim2.new(1, -28, 1, 0),
                BackgroundTransparency = 1,
                Text = tostring(Name),
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Fonts.Label,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
            }, row)

            if hasDescription then
                create("TextLabel", {
                    Name = "Description",
                    Position = UDim2.new(0, 14, 0, 27),
                    Size = UDim2.new(1, -28, 0, 14),
                    BackgroundTransparency = 1,
                    Text = Description,
                    TextColor3 = Theme.Muted,
                    TextSize = 11,
                    Font = Fonts.Body,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                }, row)
            end

            registry:Connect(row.MouseEnter, function()
                tween(row, HOVER_TIME, { BackgroundColor3 = Theme.ComponentHover })
            end)
            registry:Connect(row.MouseLeave, function()
                tween(row, HOVER_TIME, { BackgroundColor3 = Theme.Component })
            end)
            registry:Connect(row.MouseButton1Down, function()
                tween(rowScale, 0.08, { Scale = 0.98 })
            end)
            registry:Connect(row.MouseButton1Up, function()
                tween(rowScale, 0.2, { Scale = 1 })
            end)
            registry:Connect(row.MouseButton1Click, function()
                Callback()
            end)
        end


        function TabObj:AddToggle(toggleConfig)
            local toggleOptions = toggleConfig or {}
            local Name = toggleOptions.Name or toggleOptions[1] or "Toggle"
            local Description = toggleOptions.Description or ""
            local Default = toggleOptions.Default == true
            local Callback = toggleOptions.Callback or function() end
            local hasDescription = Description ~= ""

            local row = create("TextButton", {
                Name = "Toggle_" .. tostring(Name),
                Size = UDim2.new(1, 0, 0, hasDescription and 58 or 46),
                BackgroundColor3 = Theme.Component,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
            }, tabContent)
            addCorner(row, 8)

            create("TextLabel", {
                Name = "Title",
                Position = UDim2.new(0, 14, 0, hasDescription and 9 or 0),
                Size = hasDescription and UDim2.new(1, -96, 0, 16) or UDim2.new(1, -96, 1, 0),
                BackgroundTransparency = 1,
                Text = tostring(Name),
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Fonts.Label,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
            }, row)

            if hasDescription then
                create("TextLabel", {
                    Name = "Description",
                    Position = UDim2.new(0, 14, 0, 28),
                    Size = UDim2.new(1, -96, 0, 14),
                    BackgroundTransparency = 1,
                    Text = Description,
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
                Position = UDim2.new(1, -14, 0.5, 0),
                Size = UDim2.fromOffset(44, 24),
                BackgroundColor3 = Theme.Border,
                BorderSizePixel = 0,
            }, row)
            addCorner(track, 12)

            local thumb = create("Frame", {
                Name = "Thumb",
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 3, 0.5, 0),
                Size = UDim2.fromOffset(18, 18),
                BackgroundColor3 = Theme.Text,
                BorderSizePixel = 0,
            }, track)
            addCorner(thumb, 9)

            local state = false
            local onPosition = UDim2.new(1, -21, 0.5, 0)
            local offPosition = UDim2.new(0, 3, 0.5, 0)

            local function paint(instant)
                if instant then
                    track.BackgroundColor3 = state and Theme.Accent or Theme.Border
                    thumb.Position = state and onPosition or offPosition
                else
                    tween(track, STATE_TIME, { BackgroundColor3 = state and Theme.Accent or Theme.Border })
                    tween(thumb, STATE_TIME, { Position = state and onPosition or offPosition })
                end
            end

            registry:Connect(row.MouseEnter, function()
                tween(row, HOVER_TIME, { BackgroundColor3 = Theme.ComponentHover })
            end)
            registry:Connect(row.MouseLeave, function()
                tween(row, HOVER_TIME, { BackgroundColor3 = Theme.Component })
            end)
            registry:Connect(row.MouseButton1Click, function()
                state = not state
                paint(false)
                Callback(state)
            end)

            state = Default
            paint(true)
            if Default then
                Callback(true)
            end
        end


        function TabObj:AddSlider(sliderConfig)
            local sliderOptions = sliderConfig or {}
            local Name = sliderOptions.Name or sliderOptions[1] or "Slider"
            local Min = tonumber(sliderOptions.Min) or 0
            local Max = tonumber(sliderOptions.Max) or 100
            local Increase = tonumber(sliderOptions.Increase) or 1
            if Max <= Min then
                Max = Min + 1
            end
            if Increase <= 0 then
                Increase = 1
            end
            local Default = tonumber(sliderOptions.Default) or Min
            local Callback = sliderOptions.Callback or function() end

            local row = create("Frame", {
                Name = "Slider_" .. tostring(Name),
                Size = UDim2.new(1, 0, 0, 58),
                BackgroundColor3 = Theme.Component,
                BorderSizePixel = 0,
            }, tabContent)
            addCorner(row, 8)

            create("TextLabel", {
                Name = "Title",
                Position = UDim2.new(0, 14, 0, 10),
                Size = UDim2.new(1, -110, 0, 16),
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
                Size = UDim2.new(0, 80, 0, 16),
                BackgroundTransparency = 1,
                Text = "",
                TextColor3 = Theme.Value,
                TextSize = 13,
                Font = Fonts.Title,
                TextXAlignment = Enum.TextXAlignment.Right,
            }, row)

            local bar = create("Frame", {
                Name = "SliderBar",
                Position = UDim2.new(0, 14, 0, 32),
                Size = UDim2.new(1, -28, 0, 22),
                BackgroundTransparency = 1,
                Active = true,
            }, row)

            local track = create("Frame", {
                Name = "Track",
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(1, 0, 0, 6),
                BackgroundColor3 = Theme.Border,
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

            local handle = create("Frame", {
                Name = "Handle",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.fromOffset(14, 14),
                BackgroundColor3 = Theme.Text,
                BorderSizePixel = 0,
                ZIndex = 3,
            }, bar)
            addCorner(handle, 7)

            local current = Min
            local dragging = false

            local function snap(raw)
                local steps = math.floor((raw - Min) / Increase + 0.5)
                local stepped = math.clamp(Min + steps * Increase, Min, Max)
                return math.floor(stepped * 1000 + 0.5) / 1000
            end

            local function paint(value)
                local fraction = (value - Min) / (Max - Min)
                fill.Size = UDim2.new(fraction, 0, 1, 0)
                handle.Position = UDim2.new(fraction, 0, 0.5, 0)
                valueLabel.Text = tostring(value)
            end

            local function setFromX(x)
                local fraction = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
                local stepped = snap(Min + fraction * (Max - Min))
                if stepped ~= current then
                    current = stepped
                    paint(current)
                    Callback(current)
                end
            end

            registry:Connect(bar.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    tween(handle, 0.12, { Size = UDim2.fromOffset(16, 16) })
                    setFromX(input.Position.X)
                end
            end)
            registry:Connect(UserInputService.InputChanged, function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    setFromX(input.Position.X)
                end
            end)
            registry:Connect(UserInputService.InputEnded, function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                    dragging = false
                    tween(handle, 0.15, { Size = UDim2.fromOffset(14, 14) })
                end
            end)

            current = snap(Default)
            paint(current)
            Callback(current)
        end


        function TabObj:AddDropdown(dropdownConfig)
            local dropdownOptions = dropdownConfig or {}
            local Name = dropdownOptions.Name or dropdownOptions[1] or "Dropdown"
            local Options = dropdownOptions.Options or {}
            local Default = dropdownOptions.Default
            local Callback = dropdownOptions.Callback or function() end

            local COLLAPSED = 46
            local MAX_VISIBLE = 5
            local visibleCount = math.min(#Options, MAX_VISIBLE)
            local listHeight = visibleCount * 34 + 8
            local EXPANDED = COLLAPSED + 6 + listHeight

            local container = create("Frame", {
                Name = "Dropdown_" .. tostring(Name),
                Size = UDim2.new(1, 0, 0, COLLAPSED),
                BackgroundTransparency = 1,
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

            create("TextLabel", {
                Name = "Title",
                Position = UDim2.new(0, 14, 0, 0),
                Size = UDim2.new(0.45, -14, 1, 0),
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
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -34, 0.5, 0),
                Size = UDim2.new(0.45, -26, 0, 18),
                BackgroundTransparency = 1,
                Text = "",
                TextColor3 = Theme.Muted,
                TextSize = 13,
                Font = Fonts.Label,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextTruncate = Enum.TextTruncate.AtEnd,
            }, selector)

            local arrow = create("TextLabel", {
                Name = "Arrow",
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -12, 0.5, 0),
                Size = UDim2.fromOffset(14, 14),
                BackgroundTransparency = 1,
                Text = "v",
                TextColor3 = Theme.Muted,
                TextSize = 12,
                Font = Fonts.Title,
            }, selector)

            local optionsList = create("ScrollingFrame", {
                Name = "OptionsList",
                Position = UDim2.new(0, 0, 0, COLLAPSED + 6),
                Size = UDim2.new(1, 0, 0, listHeight),
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel = 0,
                ScrollBarThickness = 3,
                ScrollBarImageColor3 = Theme.Border,
                ScrollBarImageTransparency = 0.4,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                Visible = false,
                ClipsDescendants = true,
            }, container)
            addCorner(optionsList, 8)
            create("UIListLayout", {
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, optionsList)
            create("UIPadding", {
                PaddingTop = UDim.new(0, 5),
                PaddingBottom = UDim.new(0, 5),
                PaddingLeft = UDim.new(0, 5),
                PaddingRight = UDim.new(0, 5),
            }, optionsList)

            local optionEntries = {}
            local selected = nil
            local isOpen = false

            local function paintOptions()
                for _, entry in ipairs(optionEntries) do
                    local isSelected = entry.Value == selected
                    entry.Notch.BackgroundTransparency = isSelected and 0 or 1
                    entry.Label.TextColor3 = isSelected and Theme.Accent or Theme.Muted
                    entry.Label.Font = isSelected and Fonts.Title or Fonts.Body
                end
            end

            local function setOpen(open)
                if open == isOpen then
                    return
                end
                isOpen = open
                arrow.Text = open and "^" or "v"
                if open then
                    optionsList.Visible = true
                    tween(container, 0.22, { Size = UDim2.new(1, 0, 0, EXPANDED) })
                else
                    local closeTween = tween(container, 0.2, { Size = UDim2.new(1, 0, 0, COLLAPSED) })
                    closeTween.Completed:Connect(function()
                        if not isOpen then
                            optionsList.Visible = false
                        end
                    end)
                end
            end


            for index, option in ipairs(Options) do
                local optionButton = create("TextButton", {
                    Name = "Option_" .. index,
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundColor3 = Theme.Component,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Text = "",
                    AutoButtonColor = false,
                    LayoutOrder = index,
                }, optionsList)
                addCorner(optionButton, 6)

                local optionNotch = addNotch(optionButton, 12)
                optionNotch.Position = UDim2.new(0, 5, 0.5, 0)
                optionNotch.BackgroundTransparency = 1

                local optionLabel = create("TextLabel", {
                    Name = "Title",
                    Position = UDim2.new(0, 15, 0, 0),
                    Size = UDim2.new(1, -22, 1, 0),
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
                    Notch = optionNotch,
                    Value = option,
                })

                registry:Connect(optionButton.MouseEnter, function()
                    if option ~= selected then
                        tween(optionButton, HOVER_TIME, { BackgroundTransparency = 0.5 })
                        tween(optionLabel, HOVER_TIME, { TextColor3 = Theme.Text })
                    end
                end)
                registry:Connect(optionButton.MouseLeave, function()
                    if option ~= selected then
                        tween(optionButton, HOVER_TIME, { BackgroundTransparency = 1 })
                        tween(optionLabel, HOVER_TIME, { TextColor3 = Theme.Muted })
                    end
                end)
                registry:Connect(optionButton.MouseButton1Click, function()
                    selected = option
                    selectedLabel.Text = tostring(option)
                    selectedLabel.TextColor3 = Theme.Accent
                    paintOptions()
                    setOpen(false)
                    Callback(option)
                end)
            end

            registry:Connect(selector.MouseButton1Click, function()
                setOpen(not isOpen)
            end)
            registry:Connect(selector.MouseEnter, function()
                tween(selector, HOVER_TIME, { BackgroundColor3 = Theme.ComponentHover })
            end)
            registry:Connect(selector.MouseLeave, function()
                tween(selector, HOVER_TIME, { BackgroundColor3 = Theme.Component })
            end)

            if Default ~= nil then
                selected = Default
                selectedLabel.Text = tostring(Default)
                selectedLabel.TextColor3 = Theme.Accent
            end
            paintOptions()

            if Default ~= nil then
                Callback(Default)
            end
        end

        return TabObj
    end

    applyResponsiveScale()
    rootScale.Scale = baseScale * 0.94
    tween(rootScale, OPEN_TIME, { Scale = baseScale }, BACK, OUT)

    ActiveWindow = WindowObj
    return WindowObj
end

PiHub.Theme = Theme

return PiHub
