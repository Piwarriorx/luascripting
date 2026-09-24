local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ParentUI = (gethui and gethui()) or game:GetService("CoreGui"):FindFirstChild("RobloxGui") or LocalPlayer:WaitForChild("PlayerGui")

local PiHub = {}
PiHub.__index = PiHub

local function createCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

local function createStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(45, 45, 50)
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

local function tween(object, properties, duration, style, dir)
    local info = TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    local t = TweenService:Create(object, info, properties)
    t:Play()
    return t
end

function PiHub:MakeWindow(config)
    config = config or {}
    local Title = config.Title or "PiHub V5"
    local SubTitle = config.SubTitle or "Testing UI"

    -- Remove any old UI instance
    if ParentUI:FindFirstChild("PiHub_UI") then
        ParentUI:FindFirstChild("PiHub_UI"):Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "PiHub_UI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = ParentUI

    -- FLOATING TOUCH BUTTON
    local ToggleBtn = Instance.new("ImageButton")
    ToggleBtn.Name = "PiHub_FloatingBtn"
    ToggleBtn.Size = UDim2.new(0, 52, 0, 52)
    ToggleBtn.Position = UDim2.new(0, 20, 0.5, -26)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    ToggleBtn.Image = "rbxassetid://10723407389"
    ToggleBtn.ImageColor3 = Color3.fromRGB(255, 65, 65)
    ToggleBtn.AutoButtonColor = false
    ToggleBtn.ZIndex = 100
    ToggleBtn.Parent = ScreenGui

    createCorner(ToggleBtn, 26)
    createStroke(ToggleBtn, Color3.fromRGB(255, 65, 65), 1.5)

    local isDraggingIcon = false
    local dragStartPos = nil
    local startIconPos = nil
    local hasMovedSignificant = false

    ToggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingIcon = true
            hasMovedSignificant = false
            dragStartPos = input.Position
            startIconPos = ToggleBtn.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isDraggingIcon = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDraggingIcon and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStartPos
            if (Vector2.new(delta.X, delta.Y)).Magnitude > 6 then
                hasMovedSignificant = true
            end
            ToggleBtn.Position = UDim2.new(
                startIconPos.X.Scale,
                startIconPos.X.Offset + delta.X,
                startIconPos.Y.Scale,
                startIconPos.Y.Offset + delta.Y
            )
        end
    end)

    -- MAIN WINDOW
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 530, 0, 320)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    MainFrame.ClipsDescendants = true
    MainFrame.Visible = true
    MainFrame.Parent = ScreenGui

    createCorner(MainFrame, 12)
    createStroke(MainFrame, Color3.fromRGB(38, 38, 44), 1.2)

    local isMenuOpen = true
    ToggleBtn.MouseButton1Up:Connect(function()
        if not hasMovedSignificant then
            isMenuOpen = not isMenuOpen
            if isMenuOpen then
                MainFrame.Visible = true
                tween(MainFrame, {Size = UDim2.new(0, 530, 0, 320)}, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                tween(ToggleBtn, {ImageColor3 = Color3.fromRGB(255, 65, 65)}, 0.2)
            else
                local closeTween = tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                closeTween.Completed:Connect(function()
                    if not isMenuOpen then
                        MainFrame.Visible = false
                    end
                end)
                tween(ToggleBtn, {ImageColor3 = Color3.fromRGB(180, 180, 180)}, 0.2)
            end
        end
    end)

    -- HEADER
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 42)
    Header.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    Header.BorderSizePixel = 0
    Header.Parent = MainFrame

    local HeaderTitle = Instance.new("TextLabel")
    HeaderTitle.Name = "Title"
    HeaderTitle.Size = UDim2.new(0, 120, 1, 0)
    HeaderTitle.Position = UDim2.new(0, 14, 0, 0)
    HeaderTitle.BackgroundTransparency = 1
    HeaderTitle.Text = Title
    HeaderTitle.TextColor3 = Color3.fromRGB(255, 65, 65)
    HeaderTitle.TextSize = 16
    HeaderTitle.Font = Enum.Font.GothamBold
    HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
    HeaderTitle.Parent = Header

    local HeaderSubTitle = Instance.new("TextLabel")
    HeaderSubTitle.Name = "SubTitle"
    HeaderSubTitle.Size = UDim2.new(0, 200, 1, 0)
    HeaderSubTitle.Position = UDim2.new(0, 85, 0, 0)
    HeaderSubTitle.BackgroundTransparency = 1
    HeaderSubTitle.Text = "|  " .. SubTitle
    HeaderSubTitle.TextColor3 = Color3.fromRGB(140, 140, 150)
    HeaderSubTitle.TextSize = 13
    HeaderSubTitle.Font = Enum.Font.Gotham
    HeaderSubTitle.TextXAlignment = Enum.TextXAlignment.Left
    HeaderSubTitle.Parent = Header

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseBtn"
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -36, 0, 6)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
    CloseBtn.TextSize = 13
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.AutoButtonColor = false
    CloseBtn.Parent = Header

    createCorner(CloseBtn, 6)

    -- SIDEBAR
    local Sidebar = Instance.new("ScrollingFrame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 130, 1, -42)
    Sidebar.Position = UDim2.new(0, 0, 0, 42)
    Sidebar.BackgroundColor3 = Color3.fromRGB(17, 17, 21)
    Sidebar.BorderSizePixel = 0
    Sidebar.ScrollBarThickness = 0
    Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
    Sidebar.Parent = MainFrame

    local SidebarLayout = Instance.new("UIListLayout")
    SidebarLayout.Padding = UDim.new(0, 5)
    SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SidebarLayout.Parent = Sidebar

    local SidebarPadding = Instance.new("UIPadding")
    SidebarPadding.PaddingTop = UDim.new(0, 8)
    SidebarPadding.PaddingBottom = UDim.new(0, 8)
    SidebarPadding.Parent = Sidebar

    SidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Sidebar.CanvasSize = UDim2.new(0, 0, 0, SidebarLayout.AbsoluteContentSize.Y + 16)
    end)

    -- CONTENT CONTAINER
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, -130, 1, -42)
    ContentContainer.Position = UDim2.new(0, 130, 0, 42)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Parent = MainFrame

    local WindowObj = {
        Tabs = {},
        CurrentTab = nil,
        ScreenGui = ScreenGui,
        MainFrame = MainFrame
    }

    function WindowObj:Unload()
        print("[PiHub] Unloading UI completely...")
        ScreenGui:Destroy()
    end

    function WindowObj:Dialog(diagConfig)
        diagConfig = diagConfig or {}
        local dTitle = diagConfig.Title or "Notice"
        local dText = diagConfig.Text or ""
        local dOptions = diagConfig.Options or {{"OK", function() end}}

        local ModalBackdrop = Instance.new("Frame")
        ModalBackdrop.Name = "ModalBackdrop"
        ModalBackdrop.Size = UDim2.new(1, 0, 1, 0)
        ModalBackdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        ModalBackdrop.BackgroundTransparency = 0.5
        ModalBackdrop.ZIndex = 50
        ModalBackdrop.Parent = MainFrame

        local ModalBox = Instance.new("Frame")
        ModalBox.Size = UDim2.new(0, 300, 0, 145)
        ModalBox.Position = UDim2.new(0.5, 0, 0.5, 0)
        ModalBox.AnchorPoint = Vector2.new(0.5, 0.5)
        ModalBox.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
        ModalBox.ZIndex = 51
        ModalBox.Parent = ModalBackdrop

        createCorner(ModalBox, 10)
        createStroke(ModalBox, Color3.fromRGB(255, 65, 65), 1)

        local TitleL = Instance.new("TextLabel")
        TitleL.Size = UDim2.new(1, -20, 0, 24)
        TitleL.Position = UDim2.new(0, 10, 0, 10)
        TitleL.BackgroundTransparency = 1
        TitleL.Text = dTitle
        TitleL.TextColor3 = Color3.fromRGB(255, 65, 65)
        TitleL.TextSize = 14
        TitleL.Font = Enum.Font.GothamBold
        TitleL.ZIndex = 52
        TitleL.Parent = ModalBox

        local MsgL = Instance.new("TextLabel")
        MsgL.Size = UDim2.new(1, -20, 0, 48)
        MsgL.Position = UDim2.new(0, 10, 0, 36)
        MsgL.BackgroundTransparency = 1
        MsgL.Text = dText
        MsgL.TextColor3 = Color3.fromRGB(200, 200, 200)
        MsgL.TextSize = 12
        MsgL.Font = Enum.Font.Gotham
        MsgL.TextWrapped = true
        MsgL.ZIndex = 52
        MsgL.Parent = ModalBox

        local ButtonContainer = Instance.new("Frame")
        ButtonContainer.Size = UDim2.new(1, -24, 0, 32)
        ButtonContainer.Position = UDim2.new(0, 12, 1, -42)
        ButtonContainer.BackgroundTransparency = 1
        ButtonContainer.ZIndex = 52
        ButtonContainer.Parent = ModalBox

        local BtnLayout = Instance.new("UIListLayout")
        BtnLayout.FillDirection = Enum.FillDirection.Horizontal
        BtnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        BtnLayout.Padding = UDim.new(0, 8)
        BtnLayout.SortOrder = Enum.SortOrder.LayoutOrder
        BtnLayout.Parent = ButtonContainer

        for idx, option in ipairs(dOptions) do
            local optName = option[1] or "Action"
            local optCallback = option[2] or function() end
            local isPrimary = (idx == #dOptions)

            local ActionBtn = Instance.new("TextButton")
            ActionBtn.Size = UDim2.new(0, 95, 1, 0)
            ActionBtn.BackgroundColor3 = isPrimary and Color3.fromRGB(255, 65, 65) or Color3.fromRGB(35, 35, 42)
            ActionBtn.Text = optName
            ActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            ActionBtn.TextSize = 12
            ActionBtn.Font = Enum.Font.GothamBold
            ActionBtn.ZIndex = 53
            ActionBtn.AutoButtonColor = false
            ActionBtn.Parent = ButtonContainer

            createCorner(ActionBtn, 6)
            if not isPrimary then
                createStroke(ActionBtn, Color3.fromRGB(50, 50, 60), 1)
            end

            ActionBtn.MouseButton1Click:Connect(function()
                ModalBackdrop:Destroy()
                optCallback()
            end)
        end
    end

    CloseBtn.MouseButton1Click:Connect(function()
        WindowObj:Dialog({
            Title = "Unload PiHub?",
            Text = "Are you sure you want to unload the script? The menu and floating button will be removed.",
            Options = {
                {"Cancel", function()
                    print("[PiHub] Unload canceled.")
                end},
                {"Unload", function()
                    WindowObj:Unload()
                end}
            }
        })
    end)

    function WindowObj:MakeTab(tabConfig)
        tabConfig = tabConfig or {}
        local TabName = tabConfig[1] or tabConfig.Name or "Tab"

        local TabButton = Instance.new("TextButton")
        TabButton.Name = TabName .. "_TabBtn"
        TabButton.Size = UDim2.new(0, 116, 0, 36)
        TabButton.BackgroundColor3 = Color3.fromRGB(22, 22, 27)
        TabButton.Text = "   " .. TabName
        TabButton.TextColor3 = Color3.fromRGB(160, 160, 170)
        TabButton.TextSize = 13
        TabButton.Font = Enum.Font.GothamMedium
        TabButton.TextXAlignment = Enum.TextXAlignment.Left
        TabButton.AutoButtonColor = false
        TabButton.Parent = Sidebar

        createCorner(TabButton, 8)

        local TabIndicator = Instance.new("Frame")
        TabIndicator.Name = "Indicator"
        TabIndicator.Size = UDim2.new(0, 3, 0, 16)
        TabIndicator.Position = UDim2.new(0, 0, 0.5, -8)
        TabIndicator.BackgroundColor3 = Color3.fromRGB(255, 65, 65)
        TabIndicator.Visible = false
        TabIndicator.Parent = TabButton
        createCorner(TabIndicator, 2)

        local TabContent = Instance.new("ScrollingFrame")
        TabContent.Name = TabName .. "_Content"
        TabContent.Size = UDim2.new(1, 0, 1, 0)
        TabContent.BackgroundTransparency = 1
        TabContent.BorderSizePixel = 0
        TabContent.ScrollBarThickness = 3
        TabContent.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 60)
        TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
        TabContent.Visible = false
        TabContent.Parent = ContentContainer

        local ContentLayout = Instance.new("UIListLayout")
        ContentLayout.Padding = UDim.new(0, 7)
        ContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ContentLayout.Parent = TabContent

        local ContentPadding = Instance.new("UIPadding")
        ContentPadding.PaddingTop = UDim.new(0, 10)
        ContentPadding.PaddingBottom = UDim.new(0, 10)
        ContentPadding.PaddingLeft = UDim.new(0, 10)
        ContentPadding.PaddingRight = UDim.new(0, 10)
        ContentPadding.Parent = TabContent

        ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 20)
        end)

        local TabObj = {}

        local function activateTab()
            for _, t in pairs(WindowObj.Tabs) do
                t.Button.TextColor3 = Color3.fromRGB(160, 160, 170)
                t.Button.BackgroundColor3 = Color3.fromRGB(22, 22, 27)
                t.Indicator.Visible = false
                t.Content.Visible = false
            end
            TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            TabButton.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
            TabIndicator.Visible = true
            TabContent.Visible = true
            WindowObj.CurrentTab = TabObj
        end

        TabButton.MouseButton1Click:Connect(activateTab)

        if #WindowObj.Tabs == 0 then
            activateTab()
        end

        TabObj.Button = TabButton
        TabObj.Indicator = TabIndicator
        TabObj.Content = TabContent
        table.insert(WindowObj.Tabs, TabObj)

        function TabObj:AddSection(secConfig)
            local SecTitle = type(secConfig) == "table" and secConfig[1] or secConfig

            local SecFrame = Instance.new("Frame")
            SecFrame.Name = "Section_" .. SecTitle
            SecFrame.Size = UDim2.new(1, -6, 0, 26)
            SecFrame.BackgroundTransparency = 1
            SecFrame.Parent = TabContent

            local SecLabel = Instance.new("TextLabel")
            SecLabel.Size = UDim2.new(1, 0, 1, 0)
            SecLabel.BackgroundTransparency = 1
            SecLabel.Text = SecTitle
            SecLabel.TextColor3 = Color3.fromRGB(255, 65, 65)
            SecLabel.TextSize = 13
            SecLabel.Font = Enum.Font.GothamBold
            SecLabel.TextXAlignment = Enum.TextXAlignment.Left
            SecLabel.Parent = SecFrame
        end

        function TabObj:AddButton(btnConfig)
            local Name = btnConfig.Name or btnConfig[1] or "Button"
            local Callback = btnConfig.Callback or function() end

            local BtnFrame = Instance.new("TextButton")
            BtnFrame.Name = "Button_" .. Name
            BtnFrame.Size = UDim2.new(1, -6, 0, 36)
            BtnFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 27)
            BtnFrame.Text = ""
            BtnFrame.AutoButtonColor = false
            BtnFrame.Parent = TabContent

            createCorner(BtnFrame, 8)
            createStroke(BtnFrame, Color3.fromRGB(36, 36, 42), 1)

            local BtnLabel = Instance.new("TextLabel")
            BtnLabel.Size = UDim2.new(1, -20, 1, 0)
            BtnLabel.Position = UDim2.new(0, 12, 0, 0)
            BtnLabel.BackgroundTransparency = 1
            BtnLabel.Text = Name
            BtnLabel.TextColor3 = Color3.fromRGB(230, 230, 235)
            BtnLabel.TextSize = 13
            BtnLabel.Font = Enum.Font.GothamMedium
            BtnLabel.TextXAlignment = Enum.TextXAlignment.Left
            BtnLabel.Parent = BtnFrame

            local ClickIcon = Instance.new("ImageLabel")
            ClickIcon.Size = UDim2.new(0, 16, 0, 16)
            ClickIcon.Position = UDim2.new(1, -26, 0.5, -8)
            ClickIcon.BackgroundTransparency = 1
            ClickIcon.Image = "rbxassetid://10723407389"
            ClickIcon.ImageColor3 = Color3.fromRGB(150, 150, 160)
            ClickIcon.Parent = BtnFrame

            BtnFrame.MouseButton1Click:Connect(function()
                tween(BtnFrame, {BackgroundColor3 = Color3.fromRGB(35, 35, 45)}, 0.1).Completed:Connect(function()
                    tween(BtnFrame, {BackgroundColor3 = Color3.fromRGB(22, 22, 27)}, 0.15)
                end)
                Callback()
            end)
        end

        function TabObj:AddToggle(toggleConfig)
            local Name = toggleConfig.Name or "Toggle"
            local Description = toggleConfig.Description or ""
            local Default = toggleConfig.Default or false
            local Callback = toggleConfig.Callback or function() end

            local state = Default

            local ToggleFrame = Instance.new("TextButton")
            ToggleFrame.Name = "Toggle_" .. Name
            ToggleFrame.Size = UDim2.new(1, -6, 0, (Description ~= "" and 44 or 38))
            ToggleFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 27)
            ToggleFrame.Text = ""
            ToggleFrame.AutoButtonColor = false
            ToggleFrame.Parent = TabContent

            createCorner(ToggleFrame, 8)
            createStroke(ToggleFrame, Color3.fromRGB(36, 36, 42), 1)

            local TitleLabel = Instance.new("TextLabel")
            TitleLabel.Size = UDim2.new(1, -70, 0, 20)
            TitleLabel.Position = UDim2.new(0, 12, 0, (Description ~= "" and 5 or 9))
            TitleLabel.BackgroundTransparency = 1
            TitleLabel.Text = Name
            TitleLabel.TextColor3 = Color3.fromRGB(230, 230, 235)
            TitleLabel.TextSize = 13
            TitleLabel.Font = Enum.Font.GothamMedium
            TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            TitleLabel.Parent = ToggleFrame

            if Description ~= "" then
                local DescLabel = Instance.new("TextLabel")
                DescLabel.Size = UDim2.new(1, -70, 0, 14)
                DescLabel.Position = UDim2.new(0, 12, 0, 24)
                DescLabel.BackgroundTransparency = 1
                DescLabel.Text = Description
                DescLabel.TextColor3 = Color3.fromRGB(130, 130, 140)
                DescLabel.TextSize = 11
                DescLabel.Font = Enum.Font.Gotham
                DescLabel.TextXAlignment = Enum.TextXAlignment.Left
                DescLabel.Parent = ToggleFrame
            end

            local SwitchTrack = Instance.new("Frame")
            SwitchTrack.Name = "Track"
            SwitchTrack.Size = UDim2.new(0, 40, 0, 20)
            SwitchTrack.Position = UDim2.new(1, -50, 0.5, -10)
            SwitchTrack.BackgroundColor3 = state and Color3.fromRGB(255, 65, 65) or Color3.fromRGB(40, 40, 48)
            SwitchTrack.Parent = ToggleFrame
            createCorner(SwitchTrack, 10)

            local SwitchThumb = Instance.new("Frame")
            SwitchThumb.Name = "Thumb"
            SwitchThumb.Size = UDim2.new(0, 16, 0, 16)
            SwitchThumb.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            SwitchThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            SwitchThumb.Parent = SwitchTrack
            createCorner(SwitchThumb, 8)

            local function updateToggle(val)
                state = val
                if state then
                    tween(SwitchTrack, {BackgroundColor3 = Color3.fromRGB(255, 65, 65)}, 0.15)
                    tween(SwitchThumb, {Position = UDim2.new(1, -18, 0.5, -8)}, 0.15)
                else
                    tween(SwitchTrack, {BackgroundColor3 = Color3.fromRGB(40, 40, 48)}, 0.15)
                    tween(SwitchThumb, {Position = UDim2.new(0, 2, 0.5, -8)}, 0.15)
                end
                Callback(state)
            end

            ToggleFrame.MouseButton1Click:Connect(function()
                updateToggle(not state)
            end)

            if Default then
                Callback(Default)
            end
        end

        function TabObj:AddSlider(sliderConfig)
            local Name = sliderConfig.Name or "Slider"
            local Min = sliderConfig.Min or 0
            local Max = sliderConfig.Max or 100
            local Increase = sliderConfig.Increase or 1
            local Default = sliderConfig.Default or Min
            local Callback = sliderConfig.Callback or function() end

            local currentValue = Default

            local SliderFrame = Instance.new("Frame")
            SliderFrame.Name = "Slider_" .. Name
            SliderFrame.Size = UDim2.new(1, -6, 0, 50)
            SliderFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 27)
            SliderFrame.Parent = TabContent

            createCorner(SliderFrame, 8)
            createStroke(SliderFrame, Color3.fromRGB(36, 36, 42), 1)

            local NameLabel = Instance.new("TextLabel")
            NameLabel.Size = UDim2.new(0.7, 0, 0, 20)
            NameLabel.Position = UDim2.new(0, 12, 0, 6)
            NameLabel.BackgroundTransparency = 1
            NameLabel.Text = Name
            NameLabel.TextColor3 = Color3.fromRGB(230, 230, 235)
            NameLabel.TextSize = 13
            NameLabel.Font = Enum.Font.GothamMedium
            NameLabel.TextXAlignment = Enum.TextXAlignment.Left
            NameLabel.Parent = SliderFrame

            local ValLabel = Instance.new("TextLabel")
            ValLabel.Size = UDim2.new(0.3, -20, 0, 20)
            ValLabel.Position = UDim2.new(0.7, 8, 0, 6)
            ValLabel.BackgroundTransparency = 1
            ValLabel.Text = tostring(currentValue)
            ValLabel.TextColor3 = Color3.fromRGB(255, 65, 65)
            ValLabel.TextSize = 13
            ValLabel.Font = Enum.Font.GothamBold
            ValLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValLabel.Parent = SliderFrame

            local SliderBar = Instance.new("TextButton")
            SliderBar.Name = "SliderBar"
            SliderBar.Size = UDim2.new(1, -24, 0, 8)
            SliderBar.Position = UDim2.new(0, 12, 0, 32)
            SliderBar.BackgroundColor3 = Color3.fromRGB(36, 36, 44)
            SliderBar.Text = ""
            SliderBar.AutoButtonColor = false
            SliderBar.Parent = SliderFrame
            createCorner(SliderBar, 4)

            local FillBar = Instance.new("Frame")
            FillBar.Name = "Fill"
            FillBar.Size = UDim2.new((Default - Min) / (Max - Min), 0, 1, 0)
            FillBar.BackgroundColor3 = Color3.fromRGB(255, 65, 65)
            FillBar.Parent = SliderBar
            createCorner(FillBar, 4)

            local isSliding = false

            local function updateSliderFromInput(input)
                local barAbsPos = SliderBar.AbsolutePosition.X
                local barAbsSize = SliderBar.AbsoluteSize.X
                local ratio = math.clamp((input.Position.X - barAbsPos) / barAbsSize, 0, 1)
                local exactVal = Min + ((Max - Min) * ratio)
                local steppedVal = math.floor((exactVal / Increase) + 0.5) * Increase
                steppedVal = math.clamp(steppedVal, Min, Max)

                currentValue = steppedVal
                ValLabel.Text = tostring(currentValue)
                FillBar.Size = UDim2.new((currentValue - Min) / (Max - Min), 0, 1, 0)
                Callback(currentValue)
            end

            SliderBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isSliding = true
                    updateSliderFromInput(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isSliding = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if isSliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateSliderFromInput(input)
                end
            end)

            if Default then
                Callback(Default)
            end
        end

        function TabObj:AddDropdown(ddConfig)
            local Name = ddConfig.Name or "Dropdown"
            local Options = ddConfig.Options or {}
            local Default = ddConfig.Default or Options[1] or "None"
            local Callback = ddConfig.Callback or function() end

            local isOpen = false
            local selected = Default

            local DropFrame = Instance.new("Frame")
            DropFrame.Name = "Dropdown_" .. Name
            DropFrame.Size = UDim2.new(1, -6, 0, 38)
            DropFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 27)
            DropFrame.ClipsDescendants = true
            DropFrame.Parent = TabContent

            createCorner(DropFrame, 8)
            createStroke(DropFrame, Color3.fromRGB(36, 36, 42), 1)

            local TopBtn = Instance.new("TextButton")
            TopBtn.Size = UDim2.new(1, 0, 0, 38)
            TopBtn.BackgroundTransparency = 1
            TopBtn.Text = ""
            TopBtn.AutoButtonColor = false
            TopBtn.Parent = DropFrame

            local TitleLabel = Instance.new("TextLabel")
            TitleLabel.Size = UDim2.new(0.5, 0, 1, 0)
            TitleLabel.Position = UDim2.new(0, 12, 0, 0)
            TitleLabel.BackgroundTransparency = 1
            TitleLabel.Text = Name
            TitleLabel.TextColor3 = Color3.fromRGB(230, 230, 235)
            TitleLabel.TextSize = 13
            TitleLabel.Font = Enum.Font.GothamMedium
            TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            TitleLabel.Parent = TopBtn

            local SelectedLabel = Instance.new("TextLabel")
            SelectedLabel.Size = UDim2.new(0.5, -36, 1, 0)
            SelectedLabel.Position = UDim2.new(0.5, 0, 0, 0)
            SelectedLabel.BackgroundTransparency = 1
            SelectedLabel.Text = tostring(selected)
            SelectedLabel.TextColor3 = Color3.fromRGB(255, 65, 65)
            SelectedLabel.TextSize = 13
            SelectedLabel.Font = Enum.Font.GothamBold
            SelectedLabel.TextXAlignment = Enum.TextXAlignment.Right
            SelectedLabel.Parent = TopBtn

            local ArrowIcon = Instance.new("TextLabel")
            ArrowIcon.Size = UDim2.new(0, 20, 1, 0)
            ArrowIcon.Position = UDim2.new(1, -26, 0, 0)
            ArrowIcon.BackgroundTransparency = 1
            ArrowIcon.Text = "▼"
            ArrowIcon.TextColor3 = Color3.fromRGB(150, 150, 160)
            ArrowIcon.TextSize = 11
            ArrowIcon.Parent = TopBtn

            local OptContainer = Instance.new("Frame")
            OptContainer.Name = "OptionsList"
            OptContainer.Size = UDim2.new(1, -16, 0, #Options * 28)
            OptContainer.Position = UDim2.new(0, 8, 0, 38)
            OptContainer.BackgroundTransparency = 1
            OptContainer.Parent = DropFrame

            local OptLayout = Instance.new("UIListLayout")
            OptLayout.Padding = UDim.new(0, 3)
            OptLayout.SortOrder = Enum.SortOrder.LayoutOrder
            OptLayout.Parent = OptContainer

            for _, opt in ipairs(Options) do
                local OptBtn = Instance.new("TextButton")
                OptBtn.Size = UDim2.new(1, 0, 0, 26)
                OptBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
                OptBtn.Text = "  " .. tostring(opt)
                OptBtn.TextColor3 = (opt == selected) and Color3.fromRGB(255, 65, 65) or Color3.fromRGB(180, 180, 190)
                OptBtn.TextSize = 12
                OptBtn.Font = Enum.Font.Gotham
                OptBtn.TextXAlignment = Enum.TextXAlignment.Left
                OptBtn.AutoButtonColor = false
                OptBtn.Parent = OptContainer
                createCorner(OptBtn, 6)

                OptBtn.MouseButton1Click:Connect(function()
                    selected = opt
                    SelectedLabel.Text = tostring(selected)
                    for _, b in pairs(OptContainer:GetChildren()) do
                        if b:IsA("TextButton") then
                            b.TextColor3 = Color3.fromRGB(180, 180, 190)
                        end
                    end
                    OptBtn.TextColor3 = Color3.fromRGB(255, 65, 65)
                    isOpen = false
                    tween(DropFrame, {Size = UDim2.new(1, -6, 0, 38)}, 0.15)
                    ArrowIcon.Text = "▼"
                    Callback(selected)
                end)
            end

            TopBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    local fullHeight = 44 + (#Options * 29)
                    tween(DropFrame, {Size = UDim2.new(1, -6, 0, fullHeight)}, 0.2)
                    ArrowIcon.Text = "▲"
                else
                    tween(DropFrame, {Size = UDim2.new(1, -6, 0, 38)}, 0.15)
                    ArrowIcon.Text = "▼"
                end
            end)

            if Default then
                Callback(Default)
            end
        end

        return TabObj
    end

    return WindowObj
end

return PiHub
