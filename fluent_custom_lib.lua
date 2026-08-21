--[[ 
    Custom Fluent UI Library
    Features: Search Bar + Slider with Input Box
    Author: Custom Build
]]

local Fluent = {}
Fluent.Version = "2.0.0"
Fluent.Options = {}
Fluent.OpenFrames = {}

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
-- UTILITY
-- ============================================================
local function CreateInstance(className, props, children)
    local instance = Instance.new(className)
    if props then
        for k, v in pairs(props) do
            if k ~= "Parent" then
                instance[k] = v
            end
        end
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = instance
        end
    end
    if props and props.Parent then
        instance.Parent = props.Parent
    end
    return instance
end

local function Lerp(a, b, t)
    return a + (b - a) * t
end

local function Round(value, decimals)
    if decimals == 0 then return math.floor(value) end
    local multiplier = 10 ^ decimals
    return math.floor(value * multiplier + 0.5) / multiplier
end

-- ============================================================
-- WINDOW
-- ============================================================
function Fluent:CreateWindow(config)
    if self.Window then
        warn("Window already exists")
        return
    end
    
    config = config or {}
    local title = config.Title or "Fluent"
    local size = config.Size or UDim2.fromOffset(600, 400)
    
    local screenGui = CreateInstance("ScreenGui", {
        Name = "FluentUI",
        ResetOnSpawn = false,
        DisplayOrder = 999,
        Parent = PlayerGui
    })
    
    -- Main Window Frame
    local windowFrame = CreateInstance("Frame", {
        Name = "Window",
        Size = size,
        Position = UDim2.fromOffset(100, 100),
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        BorderSizePixel = 0,
        Parent = screenGui
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8)}),
        CreateInstance("UIStroke", {Color = Color3.fromRGB(60, 60, 60), Thickness = 1})
    })
    
    -- Title Bar
    local titleBar = CreateInstance("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Color3.fromRGB(25, 25, 25),
        BorderSizePixel = 0,
        Parent = windowFrame
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8)}),
        CreateInstance("TextLabel", {
            Text = title,
            Size = UDim2.new(1, -20, 1, 0),
            Position = UDim2.fromOffset(10, 0),
            BackgroundTransparency = 1,
            TextColor3 = Color3.fromRGB(240, 240, 240),
            TextSize = 16,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left
        })
    })
    
    -- Tab Bar
    local tabBar = CreateInstance("ScrollingFrame", {
        Name = "TabBar",
        Size = UDim2.new(0, 150, 1, -50),
        Position = UDim2.fromOffset(0, 45),
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        BottomImage = "rbxasset://textures/ui/chat_main_image.png",
        MidImage = "rbxasset://textures/ui/chat_main_image.png",
        TopImage = "rbxasset://textures/ui/chat_main_image.png",
        Parent = windowFrame
    }, {
        CreateInstance("UIListLayout", {
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
            FillDirection = Enum.FillDirection.Vertical
        })
    })
    
    -- Search Bar (above tab bar)
    local searchContainer = CreateInstance("Frame", {
        Name = "SearchContainer",
        Size = UDim2.new(0, 150, 0, 35),
        Position = UDim2.fromOffset(0, 45),
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        BorderSizePixel = 0,
        Parent = windowFrame
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4)})
    })
    
    local searchInput = CreateInstance("TextBox", {
        Name = "SearchInput",
        Size = UDim2.new(1, -10, 1, -8),
        Position = UDim2.fromOffset(5, 4),
        BackgroundColor3 = Color3.fromRGB(35, 35, 35),
        TextColor3 = Color3.fromRGB(200, 200, 200),
        PlaceholderColor3 = Color3.fromRGB(100, 100, 100),
        PlaceholderText = "Search...",
        TextSize = 12,
        Font = Enum.Font.GothamSSM,
        BorderSizePixel = 0,
        Parent = searchContainer
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4)}),
        CreateInstance("UIStroke", {Color = Color3.fromRGB(60, 60, 60), Thickness = 1})
    })
    
    tabBar.Position = UDim2.fromOffset(0, 82)
    tabBar.Size = UDim2.new(0, 150, 1, -127)
    
    -- Content Area
    local contentFrame = CreateInstance("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -160, 1, -50),
        Position = UDim2.fromOffset(155, 45),
        BackgroundColor3 = Color3.fromRGB(25, 25, 25),
        BorderSizePixel = 0,
        Parent = windowFrame
    })
    
    local contentScroll = CreateInstance("ScrollingFrame", {
        Name = "ContentScroll",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        BottomImage = "rbxasset://textures/ui/chat_main_image.png",
        MidImage = "rbxasset://textures/ui/chat_main_image.png",
        TopImage = "rbxasset://textures/ui/chat_main_image.png",
        Parent = contentFrame
    }, {
        CreateInstance("UIListLayout", {
            Padding = UDim.new(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder,
            FillDirection = Enum.FillDirection.Vertical
        })
    })
    
    self.Window = {
        ScreenGui = screenGui,
        Frame = windowFrame,
        TabBar = tabBar,
        SearchInput = searchInput,
        ContentFrame = contentFrame,
        ContentScroll = contentScroll,
        SearchContainer = searchContainer,
        TitleBar = titleBar,
        Tabs = {},
        Elements = {}
    }
    
    -- Search functionality
    local filteredElements = {}
    
    local function updateSearch()
        local query = searchInput.Text:lower()
        
        for _, element in ipairs(self.Window.Elements) do
            if element.Frame then
                element.Frame.Visible = query == "" or (element.Title and element.Title:lower():find(query, 1, true))
            end
        end
        
        for _, tab in ipairs(self.Window.Tabs) do
            if tab.Button then
                tab.Button.Visible = query == "" or (tab.Name and tab.Name:lower():find(query, 1, true))
            end
        end
    end
    
    searchInput.Changed:Connect(function()
        updateSearch()
    end)
    
    return self.Window
end

-- ============================================================
-- TAB
-- ============================================================
function Fluent:AddTab(config)
    if not self.Window then
        warn("Window not created")
        return
    end
    
    config = config or {}
    local tabName = config.Title or "Tab"
    
    -- Tab Button
    local tabButton = CreateInstance("TextButton", {
        Name = tabName,
        Size = UDim2.new(1, -8, 0, 30),
        Text = tabName,
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextSize = 12,
        Font = Enum.Font.GothamSSM,
        BorderSizePixel = 0,
        Parent = self.Window.TabBar
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4)}),
        CreateInstance("UIStroke", {Color = Color3.fromRGB(60, 60, 60), Thickness = 1})
    })
    
    -- Tab Container
    local container = CreateInstance("Frame", {
        Name = "TabContainer",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = self.Window.ContentScroll
    }, {
        CreateInstance("UIListLayout", {
            Padding = UDim.new(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder,
            FillDirection = Enum.FillDirection.Vertical
        })
    })
    
    local tab = {
        Name = tabName,
        Button = tabButton,
        Container = container,
        Elements = {}
    }
    
    table.insert(self.Window.Tabs, tab)
    
    tabButton.MouseButton1Click:Connect(function()
        for _, t in ipairs(self.Window.Tabs) do
            if t.Container then
                t.Container.Visible = (t == tab)
            end
            if t.Button then
                t.Button.BackgroundColor3 = (t == tab) and Color3.fromRGB(60, 60, 60) or Color3.fromRGB(40, 40, 40)
            end
        end
    end)
    
    return tab
end

-- ============================================================
-- SLIDER WITH INPUT
-- ============================================================
function Fluent:AddSliderWithInput(tab, config)
    config = config or {}
    local title = config.Title or "Slider"
    local min = config.Min or 0
    local max = config.Max or 100
    local default = config.Default or min
    local rounding = config.Rounding or 0
    local callback = config.Callback or function() end
    
    -- Main Container (Title + Input)
    local mainContainer = CreateInstance("Frame", {
        Size = UDim2.new(1, -10, 0, 28),
        BackgroundTransparency = 1,
        Parent = tab.Container
    })
    
    -- Title
    local titleLabel = CreateInstance("TextLabel", {
        Text = title,
        Size = UDim2.new(0.6, 0, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextSize = 12,
        Font = Enum.Font.GothamSSM,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = mainContainer
    })
    
    -- Input Box
    local inputBox = CreateInstance("TextBox", {
        Size = UDim2.new(0.35, -5, 1, 0),
        Position = UDim2.new(0.65, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(45, 45, 45),
        TextColor3 = Color3.fromRGB(200, 200, 200),
        PlaceholderColor3 = Color3.fromRGB(100, 100, 100),
        TextSize = 11,
        Font = Enum.Font.GothamSSM,
        BorderSizePixel = 0,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = mainContainer
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 3)}),
        CreateInstance("UIStroke", {Color = Color3.fromRGB(60, 60, 60), Thickness = 1})
    })
    
    -- Slider Container (below main)
    local sliderContainer = CreateInstance("Frame", {
        Size = UDim2.new(1, -10, 0, 16),
        Position = UDim2.fromOffset(0, 33),
        BackgroundTransparency = 1,
        Parent = tab.Container
    })
    
    -- Slider Background
    local sliderBg = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 0.5, -3),
        BackgroundColor3 = Color3.fromRGB(50, 50, 50),
        BorderSizePixel = 0,
        Parent = sliderContainer
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 3)})
    })
    
    -- Slider Fill
    local sliderFill = CreateInstance("Frame", {
        Size = UDim2.fromScale(0, 1),
        BackgroundColor3 = Color3.fromRGB(96, 205, 255),
        BorderSizePixel = 0,
        Parent = sliderBg
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 3)})
    })
    
    -- Slider Thumb (easier to drag)
    local sliderThumb = CreateInstance("Frame", {
        Size = UDim2.fromOffset(16, 16),
        Position = UDim2.new(0, -8, 0.5, -8),
        BackgroundColor3 = Color3.fromRGB(96, 205, 255),
        BorderSizePixel = 0,
        Parent = sliderBg
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8)}),
        CreateInstance("UIStroke", {Color = Color3.fromRGB(70, 170, 255), Thickness = 2})
    })
    
    local state = {
        Value = default,
        Min = min,
        Max = max,
        Rounding = rounding,
        Dragging = false
    }
    
    local function updateUI()
        local percent = (state.Value - state.Min) / (state.Max - state.Min)
        sliderFill.Size = UDim2.fromScale(percent, 1)
        sliderThumb.Position = UDim2.new(percent, -8, 0.5, -8)
        inputBox.Text = tostring(Round(state.Value, state.Rounding))
    end
    
    local function setValue(value)
        value = math.clamp(value, state.Min, state.Max)
        state.Value = Round(value, state.Rounding)
        updateUI()
        callback(state.Value)
    end
    
    -- Slider drag
    sliderThumb.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            state.Dragging = true
            
            local function onMouseMove()
                if not state.Dragging then return end
                local mousePos = UserInputService:GetMouseLocation().X
                local bgPos = sliderBg.AbsolutePosition.X
                local bgSize = sliderBg.AbsoluteSize.X
                
                local relativePos = math.clamp(mousePos - bgPos, 0, bgSize)
                local percent = relativePos / bgSize
                local newValue = state.Min + (state.Max - state.Min) * percent
                
                setValue(newValue)
            end
            
            local function onMouseUp()
                state.Dragging = false
                UserInputService.InputChanged:Disconnect()
                UserInputService.InputEnded:Disconnect()
            end
            
            UserInputService.InputChanged:Connect(onMouseMove)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    onMouseUp()
                end
            end)
        end
    end)
    
    -- Input box edit
    inputBox.FocusLost:Connect(function()
        local text = inputBox.Text:gsub(",", ".") -- Convert comma to dot
        local num = tonumber(text)
        
        if num then
            setValue(num)
        else
            updateUI() -- Reset to current value
        end
    end)
    
    -- Allow numeric input only
    inputBox.InputFilter:Connect(function(input)
        if not input:match("^[0-9,.-]*$") then
            inputBox.Text = inputBox.Text:sub(1, -2)
        end
    end)
    
    updateUI()
    
    local element = {
        Title = title,
        Frame = mainContainer,
        SliderContainer = sliderContainer,
        GetValue = function() return state.Value end,
        SetValue = setValue,
        Type = "Slider"
    }
    
    table.insert(self.Window.Elements, element)
    table.insert(tab.Elements, element)
    
    return element
end

-- ============================================================
-- TOGGLE
-- ============================================================
function Fluent:AddToggle(tab, config)
    config = config or {}
    local title = config.Title or "Toggle"
    local default = config.Default or false
    local callback = config.Callback or function() end
    
    local container = CreateInstance("Frame", {
        Size = UDim2.new(1, -10, 0, 30),
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        BorderSizePixel = 0,
        Parent = tab.Container
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4)}),
        CreateInstance("UIStroke", {Color = Color3.fromRGB(60, 60, 60), Thickness = 1})
    })
    
    local label = CreateInstance("TextLabel", {
        Text = title,
        Size = UDim2.new(0.7, 0, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextSize = 12,
        Font = Enum.Font.GothamSSM,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    local toggleButton = CreateInstance("TextButton", {
        Size = UDim2.fromOffset(40, 20),
        Position = UDim2.new(1, -50, 0.5, -10),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = default and Color3.fromRGB(96, 205, 255) or Color3.fromRGB(60, 60, 60),
        Text = "",
        BorderSizePixel = 0,
        Parent = container
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 10)})
    })
    
    local state = { Value = default }
    
    local function toggle()
        state.Value = not state.Value
        toggleButton.BackgroundColor3 = state.Value and Color3.fromRGB(96, 205, 255) or Color3.fromRGB(60, 60, 60)
        callback(state.Value)
    end
    
    toggleButton.MouseButton1Click:Connect(toggle)
    
    local element = {
        Title = title,
        Frame = container,
        GetValue = function() return state.Value end,
        SetValue = function(v) state.Value = v; toggleButton.BackgroundColor3 = v and Color3.fromRGB(96, 205, 255) or Color3.fromRGB(60, 60, 60) end,
        Type = "Toggle"
    }
    
    table.insert(self.Window.Elements, element)
    table.insert(tab.Elements, element)
    
    return element
end

-- ============================================================
-- DROPDOWN
-- ============================================================
function Fluent:AddDropdown(tab, config)
    config = config or {}
    local title = config.Title or "Dropdown"
    local options = config.Options or {}
    local default = config.Default or options[1]
    local callback = config.Callback or function() end
    
    local container = CreateInstance("Frame", {
        Size = UDim2.new(1, -10, 0, 30),
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        BorderSizePixel = 0,
        Parent = tab.Container
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4)}),
        CreateInstance("UIStroke", {Color = Color3.fromRGB(60, 60, 60), Thickness = 1})
    })
    
    local label = CreateInstance("TextLabel", {
        Text = title,
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextSize = 12,
        Font = Enum.Font.GothamSSM,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    local state = { Value = default }
    
    local dropButton = CreateInstance("TextButton", {
        Size = UDim2.new(0.4, -10, 0.7, 0),
        Position = UDim2.new(0.55, 5, 0.15, 0),
        BackgroundColor3 = Color3.fromRGB(50, 50, 50),
        TextColor3 = Color3.fromRGB(200, 200, 200),
        Text = tostring(state.Value),
        TextSize = 11,
        Font = Enum.Font.GothamSSM,
        BorderSizePixel = 0,
        Parent = container
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 3)}),
        CreateInstance("UIStroke", {Color = Color3.fromRGB(60, 60, 60), Thickness = 1})
    })
    
    local element = {
        Title = title,
        Frame = container,
        GetValue = function() return state.Value end,
        SetValue = function(v) state.Value = v; dropButton.Text = tostring(v) end,
        Type = "Dropdown"
    }
    
    table.insert(self.Window.Elements, element)
    table.insert(tab.Elements, element)
    
    return element
end

-- ============================================================
-- INPUT
-- ============================================================
function Fluent:AddInput(tab, config)
    config = config or {}
    local title = config.Title or "Input"
    local default = config.Default or ""
    local callback = config.Callback or function() end
    
    local container = CreateInstance("Frame", {
        Size = UDim2.new(1, -10, 0, 30),
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        BorderSizePixel = 0,
        Parent = tab.Container
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4)}),
        CreateInstance("UIStroke", {Color = Color3.fromRGB(60, 60, 60), Thickness = 1})
    })
    
    local label = CreateInstance("TextLabel", {
        Text = title,
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextSize = 12,
        Font = Enum.Font.GothamSSM,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    local state = { Value = default }
    
    local inputBox = CreateInstance("TextBox", {
        Size = UDim2.new(0.4, -10, 0.7, 0),
        Position = UDim2.new(0.55, 5, 0.15, 0),
        BackgroundColor3 = Color3.fromRGB(50, 50, 50),
        TextColor3 = Color3.fromRGB(200, 200, 200),
        PlaceholderColor3 = Color3.fromRGB(100, 100, 100),
        Text = default,
        TextSize = 11,
        Font = Enum.Font.GothamSSM,
        BorderSizePixel = 0,
        Parent = container
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 3)}),
        CreateInstance("UIStroke", {Color = Color3.fromRGB(60, 60, 60), Thickness = 1})
    })
    
    inputBox.Changed:Connect(function()
        state.Value = inputBox.Text
        callback(state.Value)
    end)
    
    local element = {
        Title = title,
        Frame = container,
        GetValue = function() return state.Value end,
        SetValue = function(v) state.Value = v; inputBox.Text = v end,
        Type = "Input"
    }
    
    table.insert(self.Window.Elements, element)
    table.insert(tab.Elements, element)
    
    return element
end

-- ============================================================
-- BUTTON
-- ============================================================
function Fluent:AddButton(tab, config)
    config = config or {}
    local title = config.Title or "Button"
    local callback = config.Callback or function() end
    
    local button = CreateInstance("TextButton", {
        Size = UDim2.new(1, -10, 0, 30),
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        TextColor3 = Color3.fromRGB(200, 200, 200),
        Text = title,
        TextSize = 12,
        Font = Enum.Font.GothamSSM,
        BorderSizePixel = 0,
        Parent = tab.Container
    }, {
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4)}),
        CreateInstance("UIStroke", {Color = Color3.fromRGB(60, 60, 60), Thickness = 1})
    })
    
    button.MouseButton1Click:Connect(callback)
    
    local element = {
        Title = title,
        Frame = button,
        Type = "Button"
    }
    
    table.insert(self.Window.Elements, element)
    table.insert(tab.Elements, element)
    
    return element
end

return Fluent
