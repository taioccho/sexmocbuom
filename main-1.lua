--[[
    Fluent UI - Rebuilt
    Slider: có Name, Description, ô Input chỉ nhận số
    Dropdown: có Search bar, không phân biệt hoa thường
    API giữ nguyên như bản gốc dawid/Fluent
--]]

local Fluent = {}
Fluent.__index = Fluent

-- ─── Services ─────────────────────────────────────────────────────────────────
local Players         = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local RunService      = game:GetService("RunService")
local CoreGui         = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

-- ─── Theme ────────────────────────────────────────────────────────────────────
local Themes = {
    Dark = {
        Accent        = Color3.fromRGB(96, 205, 255),
        Background    = Color3.fromRGB(30, 30, 30),
        Panel         = Color3.fromRGB(37, 37, 37),
        Element       = Color3.fromRGB(120, 120, 120),
        ElementBorder = Color3.fromRGB(35, 35, 35),
        InBorder      = Color3.fromRGB(90, 90, 90),
        ElemTransp    = 0.87,
        DropHolder    = Color3.fromRGB(45, 45, 45),
        DropBorder    = Color3.fromRGB(35, 35, 35),
        SliderRail    = Color3.fromRGB(120, 120, 120),
        Text          = Color3.fromRGB(240, 240, 240),
        SubText       = Color3.fromRGB(170, 170, 170),
        Input         = Color3.fromRGB(160, 160, 160),
        InputFocused  = Color3.fromRGB(10, 10, 10),
        TitleBar      = Color3.fromRGB(32, 32, 32),
        TitleLine     = Color3.fromRGB(75, 75, 75),
        Tab           = Color3.fromRGB(120, 120, 120),
        Hover         = Color3.fromRGB(120, 120, 120),
        HoverChange   = 0.07,
    },
}

-- Active theme (default Dark)
local T = Themes.Dark

-- ─── Helpers ──────────────────────────────────────────────────────────────────
local function New(class, props, children)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    for _, child in ipairs(children or {}) do
        child.Parent = obj
    end
    return obj
end

local function Tween(obj, info, props)
    TweenService:Create(obj, info, props):Play()
end

local function Round(n, dec)
    if dec == 0 then return math.floor(n + 0.5) end
    local m = 10 ^ dec
    return math.floor(n * m + 0.5) / m
end

-- ─── GUI Root ─────────────────────────────────────────────────────────────────
local ScreenGui = New("ScreenGui", {
    Name            = "FluentUI",
    ResetOnSpawn    = false,
    ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
})
if syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
elseif not RunService:IsStudio() then
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

Fluent.GUI       = ScreenGui
Fluent.Options   = {}
Fluent.Unloaded  = false

-- ─── SafeCallback ─────────────────────────────────────────────────────────────
function Fluent:SafeCallback(fn, ...)
    if not fn then return end
    local ok, err = pcall(fn, ...)
    if not ok then warn("[Fluent] Callback error: " .. tostring(err)) end
end

-- ─────────────────────────────────────────────────────────────────────────────
--  CreateWindow
-- ─────────────────────────────────────────────────────────────────────────────
function Fluent:CreateWindow(cfg)
    assert(cfg.Title, "Window - Missing Title")
    cfg.Size     = cfg.Size     or UDim2.fromOffset(520, 420)
    cfg.TabWidth = cfg.TabWidth or 140

    -- ── Root frame ──
    local WinFrame = New("Frame", {
        Name            = "FluentWindow",
        Size            = cfg.Size,
        Position        = UDim2.new(0.5, -cfg.Size.X.Offset/2, 0.5, -cfg.Size.Y.Offset/2),
        BackgroundColor3 = T.Background,
        BorderSizePixel = 0,
        Parent          = ScreenGui,
    }, {
        New("UICorner",  { CornerRadius = UDim.new(0, 10) }),
        New("UIStroke",  { Color = T.ElementBorder, Transparency = 0.5, Thickness = 1 }),
    })

    -- ── Title bar ──
    local TitleBar = New("Frame", {
        Size             = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = T.TitleBar,
        BorderSizePixel  = 0,
        Parent           = WinFrame,
    }, {
        New("UICorner", { CornerRadius = UDim.new(0, 10) }),
        New("Frame", { -- bottom filler so corners only on top
            Size             = UDim2.new(1, 0, 0, 10),
            Position         = UDim2.new(0, 0, 1, -10),
            BackgroundColor3 = T.TitleBar,
            BorderSizePixel  = 0,
        }),
        New("TextLabel", {
            Text             = cfg.Title,
            Font             = Enum.Font.GothamSemibold,
            TextSize         = 14,
            TextColor3       = T.Text,
            TextXAlignment   = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Size             = UDim2.new(1, -16, 1, 0),
            Position         = UDim2.fromOffset(16, 0),
        }),
    })
    if cfg.SubTitle then
        New("TextLabel", {
            Text             = cfg.SubTitle,
            Font             = Enum.Font.Gotham,
            TextSize         = 11,
            TextColor3       = T.SubText,
            TextXAlignment   = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Size             = UDim2.new(0, 200, 1, 0),
            Position         = UDim2.new(0, 16 + 90, 0, 0),
            Parent           = TitleBar,
        })
    end
    -- Separator
    New("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = T.TitleLine,
        BorderSizePixel  = 0,
        Parent           = TitleBar,
    })

    -- ── Sidebar ──
    local Sidebar = New("Frame", {
        Size             = UDim2.new(0, cfg.TabWidth, 1, -42),
        Position         = UDim2.new(0, 0, 0, 42),
        BackgroundColor3 = T.Background,
        BorderSizePixel  = 0,
        Parent           = WinFrame,
    })
    local TabHolder = New("ScrollingFrame", {
        Size                  = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness    = 0,
        BorderSizePixel       = 0,
        CanvasSize            = UDim2.fromScale(0, 0),
        Parent                = Sidebar,
    }, {
        New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
        New("UIPadding",    { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
    })
    TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabHolder.CanvasSize = UDim2.new(0, 0, 0, TabHolder.UIListLayout.AbsoluteContentSize.Y + 16)
    end)

    -- Sidebar right border
    New("Frame", {
        Size             = UDim2.new(0, 1, 1, 0),
        Position         = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = T.TitleLine,
        BorderSizePixel  = 0,
        Parent           = Sidebar,
    })

    -- ── Tab label (top of content) ──
    local TabLabel = New("TextLabel", {
        Text             = "",
        Font             = Enum.Font.GothamBold,
        TextSize         = 20,
        TextColor3       = T.Text,
        TextXAlignment   = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, -cfg.TabWidth - 32, 0, 28),
        Position         = UDim2.fromOffset(cfg.TabWidth + 20, 52),
        Parent           = WinFrame,
    })

    -- ── Container holder ──
    local ContainerHolder = New("CanvasGroup", {
        Size             = UDim2.new(1, -cfg.TabWidth - 32, 1, -102),
        Position         = UDim2.fromOffset(cfg.TabWidth + 16, 90),
        BackgroundTransparency = 1,
        Parent           = WinFrame,
    })

    -- ── Dragging ──
    local dragging, dragStart, startPos = false, nil, nil
    TitleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = inp.Position
            startPos  = WinFrame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = inp.Position - dragStart
            WinFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    -- ──────────────────────────────────────────────────────────
    --  Window object
    -- ──────────────────────────────────────────────────────────
    local Window    = { Frame = WinFrame, Tabs = {}, TabCount = 0, SelectedTab = nil }
    local TabFrames = {}

    -- ── Selector bar (left accent) ──
    local Selector = New("Frame", {
        Size             = UDim2.fromOffset(4, 0),
        Position         = UDim2.fromOffset(0, 0),
        BackgroundColor3 = T.Accent,
        BorderSizePixel  = 0,
        Parent           = TabHolder,
    }, { New("UICorner", { CornerRadius = UDim.new(0, 2) }) })

    local function SelectTab(index)
        Window.SelectedTab = index
        for i, tab in ipairs(Window.Tabs) do
            TabFrames[i].Visible = (i == index)
            Tween(tab.Button, TweenInfo.new(0.15), {
                BackgroundTransparency = (i == index) and 0.89 or 1
            })
        end
        local btn = Window.Tabs[index].Button
        TabLabel.Text = Window.Tabs[index].Name
        -- move selector
        Tween(Selector, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            Position = UDim2.fromOffset(-8, btn.AbsolutePosition.Y - TabHolder.AbsolutePosition.Y + 10),
            Size     = UDim2.fromOffset(4, 14),
        })
    end

    -- ── AddTab ──
    function Window:AddTab(cfg2)
        Window.TabCount = Window.TabCount + 1
        local idx = Window.TabCount

        -- Tab button
        local btn = New("TextButton", {
            Size             = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = T.Tab,
            BackgroundTransparency = 1,
            Text             = "",
            Parent           = TabHolder,
        }, {
            New("UICorner", { CornerRadius = UDim.new(0, 6) }),
            New("TextLabel", {
                Text             = cfg2.Title,
                Font             = Enum.Font.Gotham,
                TextSize         = 12,
                TextColor3       = T.Text,
                TextXAlignment   = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                Size             = UDim2.new(1, -12, 1, 0),
                Position         = UDim2.fromOffset(12, 0),
            }),
        })

        btn.MouseEnter:Connect(function()
            if Window.SelectedTab ~= idx then
                Tween(btn, TweenInfo.new(0.12), { BackgroundTransparency = 0.93 })
            end
        end)
        btn.MouseLeave:Connect(function()
            if Window.SelectedTab ~= idx then
                Tween(btn, TweenInfo.new(0.12), { BackgroundTransparency = 1 })
            end
        end)
        btn.MouseButton1Click:Connect(function() SelectTab(idx) end)

        -- Content scroll frame
        local layout   = New("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder })
        local scrollFrame = New("ScrollingFrame", {
            Size                  = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel       = 0,
            CanvasSize            = UDim2.fromScale(0, 0),
            ScrollBarThickness    = 3,
            ScrollBarImageColor3  = Color3.fromRGB(255, 255, 255),
            ScrollBarImageTransparency = 0.85,
            BottomImage           = "rbxassetid://6889812791",
            MidImage              = "rbxassetid://6889812721",
            TopImage              = "rbxassetid://6276641225",
            ScrollingDirection    = Enum.ScrollingDirection.Y,
            Visible               = false,
            Parent                = ContainerHolder,
        }, {
            layout,
            New("UIPadding", {
                PaddingLeft   = UDim.new(0, 1),
                PaddingRight  = UDim.new(0, 10),
                PaddingTop    = UDim.new(0, 1),
                PaddingBottom = UDim.new(0, 4),
            }),
        })

        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 6)
        end)

        local tabObj = {
            Name        = cfg2.Title,
            Button      = btn,
            Container   = scrollFrame,
            ScrollFrame = scrollFrame,
        }
        Window.Tabs[idx]  = tabObj
        TabFrames[idx]    = scrollFrame

        -- First tab auto-select
        if idx == 1 then SelectTab(1) end

        -- ── Elements API ──────────────────────────────────────────────────────

        -- Helper: create the base element frame
        local function MakeElement(title, description, height)
            height = height or 44
            local frame = New("Frame", {
                Size             = UDim2.new(1, 0, 0, height),
                BackgroundColor3 = T.Element,
                BackgroundTransparency = T.ElemTransp,
                BorderSizePixel  = 0,
                Parent           = scrollFrame,
            }, {
                New("UICorner", { CornerRadius = UDim.new(0, 4) }),
                New("UIStroke", {
                    Color        = T.ElementBorder,
                    Transparency = 0.5,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                }),
            })
            local titleLabel = New("TextLabel", {
                Text             = title,
                Font             = Enum.Font.GothamMedium,
                TextSize         = 13,
                TextColor3       = T.Text,
                TextXAlignment   = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                Size             = UDim2.new(0.6, 0, 0, 14),
                Position         = UDim2.fromOffset(10, 0),
                AnchorPoint      = Vector2.new(0, 0.5),
                Parent           = frame,
            })
            local descLabel
            if description and description ~= "" then
                titleLabel.Position = UDim2.new(0, 10, 0, 12)
                titleLabel.AnchorPoint = Vector2.zero
                descLabel = New("TextLabel", {
                    Text             = description,
                    Font             = Enum.Font.Gotham,
                    TextSize         = 11,
                    TextColor3       = T.SubText,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    TextWrapped      = true,
                    BackgroundTransparency = 1,
                    Size             = UDim2.new(0.55, 0, 0, 13),
                    Position         = UDim2.fromOffset(10, 26),
                    Parent           = frame,
                })
            end
            return frame, titleLabel, descLabel
        end

        -- ── AddSection ───────────────────────────────────────────────────────
        function tabObj:AddSection(sectionName)
            New("TextLabel", {
                Text             = sectionName,
                Font             = Enum.Font.GothamBold,
                TextSize         = 11,
                TextColor3       = T.SubText,
                TextXAlignment   = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                Size             = UDim2.new(1, 0, 0, 18),
                Parent           = scrollFrame,
            })
            return tabObj
        end

        -- ── AddButton ────────────────────────────────────────────────────────
        function tabObj:AddButton(cfg3)
            assert(cfg3.Title, "Button - Missing Title")
            cfg3.Callback = cfg3.Callback or function() end
            local frame = MakeElement(cfg3.Title, cfg3.Description)
            -- Arrow icon
            New("ImageLabel", {
                Image            = "rbxassetid://10709791437",
                Size             = UDim2.fromOffset(16, 16),
                AnchorPoint      = Vector2.new(1, 0.5),
                Position         = UDim2.new(1, -10, 0.5, 0),
                BackgroundTransparency = 1,
                ImageColor3      = T.SubText,
                Parent           = frame,
            })
            local btn = New("TextButton", {
                Size             = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text             = "",
                Parent           = frame,
            })
            btn.MouseButton1Click:Connect(function()
                Fluent:SafeCallback(cfg3.Callback)
            end)
            btn.MouseEnter:Connect(function()
                Tween(frame, TweenInfo.new(0.1), { BackgroundTransparency = T.ElemTransp - T.HoverChange })
            end)
            btn.MouseLeave:Connect(function()
                Tween(frame, TweenInfo.new(0.1), { BackgroundTransparency = T.ElemTransp })
            end)
        end

        -- ── AddToggle ────────────────────────────────────────────────────────
        function tabObj:AddToggle(key, cfg3)
            assert(cfg3.Title, "Toggle - Missing Title")
            cfg3.Default  = cfg3.Default  or false
            cfg3.Callback = cfg3.Callback or function() end

            local state = cfg3.Default
            local frame = MakeElement(cfg3.Title, cfg3.Description)

            local track = New("Frame", {
                Size             = UDim2.fromOffset(36, 18),
                AnchorPoint      = Vector2.new(1, 0.5),
                Position         = UDim2.new(1, -10, 0.5, 0),
                BackgroundColor3 = state and T.Accent or T.Element,
                BackgroundTransparency = state and 0 or 0.7,
                BorderSizePixel  = 0,
                Parent           = frame,
            }, {
                New("UICorner", { CornerRadius = UDim.new(0, 9) }),
                New("UIStroke", { Color = T.InBorder, Transparency = 0.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
            })
            local thumb = New("ImageLabel", {
                Image            = "http://www.roblox.com/asset/?id=12266946128",
                Size             = UDim2.fromOffset(14, 14),
                AnchorPoint      = Vector2.new(0, 0.5),
                Position         = state and UDim2.new(0, 19, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
                BackgroundTransparency = 1,
                ImageColor3      = state and Color3.new(0,0,0) or T.Element,
                ImageTransparency = state and 0 or 0.5,
                Parent           = track,
            })

            local toggleObj = { Value = state }

            local function Apply(v)
                state = v
                toggleObj.Value = v
                Tween(track, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                    BackgroundColor3     = v and T.Accent or T.Element,
                    BackgroundTransparency = v and 0 or 0.7,
                })
                Tween(thumb, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                    Position      = v and UDim2.new(0, 19, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
                    ImageColor3   = v and Color3.new(0,0,0) or T.Element,
                    ImageTransparency = v and 0 or 0.5,
                })
                Fluent:SafeCallback(cfg3.Callback, v)
                if toggleObj.Changed then Fluent:SafeCallback(toggleObj.Changed, v) end
            end

            local btn = New("TextButton", {
                Size             = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text             = "",
                Parent           = frame,
            })
            btn.MouseButton1Click:Connect(function() Apply(not state) end)
            btn.MouseEnter:Connect(function()
                Tween(frame, TweenInfo.new(0.1), { BackgroundTransparency = T.ElemTransp - T.HoverChange })
            end)
            btn.MouseLeave:Connect(function()
                Tween(frame, TweenInfo.new(0.1), { BackgroundTransparency = T.ElemTransp })
            end)

            function toggleObj:SetValue(v) Apply(v) end
            function toggleObj:OnChanged(fn) self.Changed = fn fn(state) end
            function toggleObj:Destroy() frame:Destroy() Fluent.Options[key] = nil end

            Fluent.Options[key] = toggleObj
            return toggleObj
        end

        -- ── AddSlider ────────────────────────────────────────────────────────
        -- Cải tiến: có Name, Description, ô input số bên phải
        function tabObj:AddSlider(key, cfg3)
            assert(cfg3.Title,   "Slider - Missing Title")
            assert(cfg3.Min,     "Slider - Missing Min")
            assert(cfg3.Max,     "Slider - Missing Max")
            assert(cfg3.Default ~= nil, "Slider - Missing Default")
            cfg3.Rounding = cfg3.Rounding or 0
            cfg3.Callback = cfg3.Callback or function() end

            -- Chiều cao lớn hơn vì có description + rail
            local hasDesc   = cfg3.Description and cfg3.Description ~= ""
            local elemHeight = hasDesc and 70 or 58

            local frame = New("Frame", {
                Size             = UDim2.new(1, 0, 0, elemHeight),
                BackgroundColor3 = T.Element,
                BackgroundTransparency = T.ElemTransp,
                BorderSizePixel  = 0,
                Parent           = scrollFrame,
            }, {
                New("UICorner", { CornerRadius = UDim.new(0, 4) }),
                New("UIStroke", {
                    Color        = T.ElementBorder,
                    Transparency = 0.5,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                }),
            })

            -- Title
            New("TextLabel", {
                Text             = cfg3.Title,
                Font             = Enum.Font.GothamMedium,
                TextSize         = 13,
                TextColor3       = T.Text,
                TextXAlignment   = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                Size             = UDim2.new(0.55, 0, 0, 14),
                Position         = UDim2.fromOffset(10, 10),
                Parent           = frame,
            })

            -- Description
            if hasDesc then
                New("TextLabel", {
                    Text             = cfg3.Description,
                    Font             = Enum.Font.Gotham,
                    TextSize         = 11,
                    TextColor3       = T.SubText,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    TextWrapped      = true,
                    BackgroundTransparency = 1,
                    Size             = UDim2.new(0.55, 0, 0, 13),
                    Position         = UDim2.fromOffset(10, 25),
                    Parent           = frame,
                })
            end

            -- ── Number Input Box ──────────────────────────────────────────────
            local inputBg = New("Frame", {
                Size             = UDim2.fromOffset(62, 26),
                AnchorPoint      = Vector2.new(1, 0),
                Position         = UDim2.new(1, -10, 0, 8),
                BackgroundColor3 = T.InputFocused,
                BackgroundTransparency = 0.3,
                BorderSizePixel  = 0,
                Parent           = frame,
            }, {
                New("UICorner", { CornerRadius = UDim.new(0, 4) }),
                New("UIStroke", {
                    Color        = T.InBorder,
                    Transparency = 0.5,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                }),
            })

            local inputBox = New("TextBox", {
                Text             = tostring(cfg3.Default),
                Font             = Enum.Font.Gotham,
                TextSize         = 12,
                TextColor3       = T.Text,
                PlaceholderColor3 = T.SubText,
                TextXAlignment   = Enum.TextXAlignment.Right,
                BackgroundTransparency = 1,
                ClearTextOnFocus = false,
                Size             = UDim2.new(1, -8, 1, 0),
                Position         = UDim2.fromOffset(4, 0),
                Parent           = inputBg,
            })

            -- ── Rail ──────────────────────────────────────────────────────────
            local railY    = hasDesc and 52 or 40
            local rail = New("Frame", {
                Size             = UDim2.new(1, -20, 0, 4),
                Position         = UDim2.new(0, 10, 0, railY),
                BackgroundColor3 = T.SliderRail,
                BackgroundTransparency = 0.6,
                BorderSizePixel  = 0,
                Parent           = frame,
            }, {
                New("UICorner", { CornerRadius = UDim.new(1, 0) }),
            })

            local fill = New("Frame", {
                Size             = UDim2.fromScale(0, 1),
                BackgroundColor3 = T.Accent,
                BorderSizePixel  = 0,
                Parent           = rail,
            }, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) })

            local thumb = New("ImageLabel", {
                Image            = "http://www.roblox.com/asset/?id=12266946128",
                Size             = UDim2.fromOffset(14, 14),
                AnchorPoint      = Vector2.new(0.5, 0.5),
                Position         = UDim2.new(0, 0, 0.5, 0),
                BackgroundTransparency = 1,
                ImageColor3      = T.Accent,
                Parent           = rail,
            })

            -- ── Slider logic ──────────────────────────────────────────────────
            local sliderObj   = { Value = cfg3.Default, Min = cfg3.Min, Max = cfg3.Max }
            local draggingSlider = false

            local function SetValue(v, skipCallback)
                v = Round(math.clamp(v, cfg3.Min, cfg3.Max), cfg3.Rounding)
                sliderObj.Value = v
                local pct = (v - cfg3.Min) / (cfg3.Max - cfg3.Min)
                fill.Size         = UDim2.fromScale(pct, 1)
                thumb.Position    = UDim2.new(pct, 0, 0.5, 0)
                inputBox.Text     = tostring(v)
                if not skipCallback then
                    Fluent:SafeCallback(cfg3.Callback, v)
                    if sliderObj.Changed then Fluent:SafeCallback(sliderObj.Changed, v) end
                end
            end

            local function UpdateFromMouse()
                local railPos = rail.AbsolutePosition
                local railSz  = rail.AbsoluteSize
                local ratio   = math.clamp((Mouse.X - railPos.X) / railSz.X, 0, 1)
                SetValue(cfg3.Min + ratio * (cfg3.Max - cfg3.Min))
            end

            thumb.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingSlider = true
                end
            end)
            rail.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingSlider = true
                    UpdateFromMouse()
                end
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingSlider = false
                end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if draggingSlider and inp.UserInputType == Enum.UserInputType.MouseMovement then
                    UpdateFromMouse()
                end
            end)

            -- ── Input box: chỉ nhận số ─────────────────────────────────────
            inputBox:GetPropertyChangedSignal("Text"):Connect(function()
                -- Lọc ký tự không phải số, dấu chấm, dấu trừ
                local raw = inputBox.Text
                local filtered = raw:gsub("[^%d%.%-]", "")
                if filtered ~= raw then
                    inputBox.Text = filtered
                end
            end)

            inputBox.FocusLost:Connect(function(enterPressed)
                local n = tonumber(inputBox.Text)
                if n then
                    SetValue(n)
                else
                    inputBox.Text = tostring(sliderObj.Value)
                end
            end)

            -- Focus border highlight
            inputBox.Focused:Connect(function()
                Tween(inputBg, TweenInfo.new(0.15), { BackgroundTransparency = 0.1 })
                inputBg.UIStroke.Color = T.Accent
            end)
            inputBox.FocusLost:Connect(function()
                Tween(inputBg, TweenInfo.new(0.15), { BackgroundTransparency = 0.3 })
                inputBg.UIStroke.Color = T.InBorder
            end)

            -- Set initial
            SetValue(cfg3.Default, true)

            function sliderObj:SetValue(v) SetValue(v) end
            function sliderObj:OnChanged(fn) self.Changed = fn fn(sliderObj.Value) end
            function sliderObj:Destroy() frame:Destroy() Fluent.Options[key] = nil end

            Fluent.Options[key] = sliderObj
            return sliderObj
        end

        -- ── AddDropdown ───────────────────────────────────────────────────────
        -- Cải tiến: có Search bar, tìm kiếm không phân biệt hoa thường
        function tabObj:AddDropdown(key, cfg3)
            assert(cfg3.Title,  "Dropdown - Missing Title")
            cfg3.Values   = cfg3.Values   or {}
            cfg3.Callback = cfg3.Callback or function() end
            cfg3.Multi    = cfg3.Multi    or false

            local dropObj = {
                Value  = cfg3.Multi and {} or cfg3.Default,
                Values = cfg3.Values,
                Multi  = cfg3.Multi,
                Opened = false,
            }

            local frame, _, _ = MakeElement(cfg3.Title, cfg3.Description)

            -- ── Display button ────────────────────────────────────────────────
            local dispBg = New("Frame", {
                Size             = UDim2.fromOffset(160, 28),
                AnchorPoint      = Vector2.new(1, 0.5),
                Position         = UDim2.new(1, -10, 0.5, 0),
                BackgroundColor3 = T.Input,
                BackgroundTransparency = 0.9,
                BorderSizePixel  = 0,
                Parent           = frame,
            }, {
                New("UICorner", { CornerRadius = UDim.new(0, 5) }),
                New("UIStroke", {
                    Color        = T.InBorder,
                    Transparency = 0.5,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                }),
            })

            local dispText = New("TextLabel", {
                Text             = "--",
                Font             = Enum.Font.Gotham,
                TextSize         = 13,
                TextColor3       = T.Text,
                TextXAlignment   = Enum.TextXAlignment.Left,
                TextTruncate     = Enum.TextTruncate.AtEnd,
                BackgroundTransparency = 1,
                Size             = UDim2.new(1, -26, 1, 0),
                Position         = UDim2.fromOffset(8, 0),
                Parent           = dispBg,
            })

            local chevron = New("ImageLabel", {
                Image            = "rbxassetid://10709790948",
                Size             = UDim2.fromOffset(14, 14),
                AnchorPoint      = Vector2.new(1, 0.5),
                Position         = UDim2.new(1, -6, 0.5, 0),
                BackgroundTransparency = 1,
                ImageColor3      = T.SubText,
                Parent           = dispBg,
            })

            local dispBtn = New("TextButton", {
                Size             = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text             = "",
                Parent           = dispBg,
            })

            -- ── Popup ─────────────────────────────────────────────────────────
            local popup = New("Frame", {
                Size             = UDim2.fromOffset(220, 0), -- height set dynamically
                BackgroundColor3 = T.DropHolder,
                BorderSizePixel  = 0,
                Visible          = false,
                ZIndex           = 50,
                Parent           = Fluent.GUI,
            }, {
                New("UICorner", { CornerRadius = UDim.new(0, 7) }),
                New("UIStroke", {
                    Color        = T.DropBorder,
                    Transparency = 0.35,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                }),
            })

            -- Search row
            local searchBg = New("Frame", {
                Size             = UDim2.new(1, -10, 0, 28),
                Position         = UDim2.fromOffset(5, 5),
                BackgroundColor3 = T.InputFocused,
                BackgroundTransparency = 0.4,
                BorderSizePixel  = 0,
                ZIndex           = 51,
                Parent           = popup,
            }, {
                New("UICorner", { CornerRadius = UDim.new(0, 5) }),
                New("UIStroke", {
                    Color        = T.InBorder,
                    Transparency = 0.5,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                }),
            })

            -- Search icon (magnifying glass drawn with text)
            New("TextLabel", {
                Text             = "🔍",
                TextSize         = 12,
                BackgroundTransparency = 1,
                Size             = UDim2.fromOffset(20, 20),
                Position         = UDim2.fromOffset(5, 0),
                AnchorPoint      = Vector2.new(0, 0.5),
                TextYAlignment   = Enum.TextYAlignment.Center,
                ZIndex           = 52,
                Parent           = searchBg,
            })

            local searchBox = New("TextBox", {
                PlaceholderText  = "Search...",
                Text             = "",
                Font             = Enum.Font.Gotham,
                TextSize         = 12,
                TextColor3       = T.Text,
                PlaceholderColor3 = T.SubText,
                TextXAlignment   = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                ClearTextOnFocus = false,
                Size             = UDim2.new(1, -28, 1, 0),
                Position         = UDim2.fromOffset(24, 0),
                ZIndex           = 52,
                Parent           = searchBg,
            })

            -- List scroll
            local listScroll = New("ScrollingFrame", {
                Size                  = UDim2.new(1, -10, 0, 0),
                Position              = UDim2.fromOffset(5, 38),
                BackgroundTransparency = 1,
                BorderSizePixel       = 0,
                ScrollBarThickness    = 3,
                ScrollBarImageColor3  = Color3.fromRGB(255, 255, 255),
                ScrollBarImageTransparency = 0.8,
                BottomImage           = "rbxassetid://6889812791",
                MidImage              = "rbxassetid://6889812721",
                TopImage              = "rbxassetid://6276641225",
                CanvasSize            = UDim2.fromScale(0, 0),
                ZIndex                = 51,
                Parent                = popup,
            }, {
                New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
                New("UIPadding",    { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2) }),
            })
            local listLayout = listScroll:FindFirstChildWhichIsA("UIListLayout")

            -- Empty label
            local emptyLabel = New("TextLabel", {
                Text             = "Không tìm thấy kết quả",
                Font             = Enum.Font.Gotham,
                TextSize         = 12,
                TextColor3       = T.SubText,
                BackgroundTransparency = 1,
                Size             = UDim2.new(1, 0, 0, 32),
                TextXAlignment   = Enum.TextXAlignment.Center,
                Visible          = false,
                ZIndex           = 52,
                Parent           = listScroll,
            })

            local optionButtons = {}

            -- ── Build list ────────────────────────────────────────────────────
            local function UpdateDisplay()
                if cfg3.Multi then
                    local parts = {}
                    for _, v in ipairs(dropObj.Values) do
                        if dropObj.Value[v] then table.insert(parts, v) end
                    end
                    dispText.Text = #parts > 0 and table.concat(parts, ", ") or "--"
                else
                    dispText.Text = dropObj.Value or "--"
                end
            end

            local function RebuildList(filter)
                filter = (filter or ""):lower()
                for _, btn2 in pairs(optionButtons) do btn2:Destroy() end
                optionButtons = {}

                local count = 0
                for _, val in ipairs(dropObj.Values) do
                    -- Case-insensitive search: tìm filter ở bất kỳ vị trí nào trong val
                    if filter == "" or val:lower():find(filter, 1, true) then
                        count = count + 1
                        local isSelected = cfg3.Multi and dropObj.Value[val] or (dropObj.Value == val)

                        local optBtn = New("TextButton", {
                            Size             = UDim2.new(1, 0, 0, 30),
                            BackgroundColor3 = T.DropHolder,
                            BackgroundTransparency = isSelected and 0.85 or 1,
                            Text             = "",
                            ZIndex           = 52,
                            Parent           = listScroll,
                        }, {
                            New("UICorner", { CornerRadius = UDim.new(0, 5) }),
                        })

                        -- Accent bar
                        local accentBar = New("Frame", {
                            Size             = UDim2.fromOffset(4, isSelected and 14 or 6),
                            Position         = UDim2.fromOffset(-1, 8),
                            AnchorPoint      = Vector2.new(0, 0),
                            BackgroundColor3 = T.Accent,
                            BackgroundTransparency = isSelected and 0 or 1,
                            BorderSizePixel  = 0,
                            ZIndex           = 53,
                            Parent           = optBtn,
                        }, { New("UICorner", { CornerRadius = UDim.new(0, 2) }) })

                        New("TextLabel", {
                            Text             = val,
                            Font             = Enum.Font.Gotham,
                            TextSize         = 13,
                            TextColor3       = T.Text,
                            TextXAlignment   = Enum.TextXAlignment.Left,
                            BackgroundTransparency = 1,
                            Size             = UDim2.new(1, -16, 1, 0),
                            Position         = UDim2.fromOffset(10, 0),
                            ZIndex           = 53,
                            Parent           = optBtn,
                        })

                        optBtn.MouseEnter:Connect(function()
                            if not (not cfg3.Multi and dropObj.Value == val) then
                                Tween(optBtn, TweenInfo.new(0.1), { BackgroundTransparency = 0.9 })
                            end
                        end)
                        optBtn.MouseLeave:Connect(function()
                            local sel = cfg3.Multi and dropObj.Value[val] or (dropObj.Value == val)
                            Tween(optBtn, TweenInfo.new(0.1), { BackgroundTransparency = sel and 0.85 or 1 })
                        end)

                        optBtn.MouseButton1Click:Connect(function()
                            if cfg3.Multi then
                                dropObj.Value[val] = not dropObj.Value[val] or nil
                            else
                                dropObj.Value = (dropObj.Value == val) and nil or val
                                -- Close on single select
                                popup.Visible = false
                                dropObj.Opened = false
                                Tween(chevron, TweenInfo.new(0.2), { Rotation = 0 })
                                searchBox.Text = ""
                            end
                            UpdateDisplay()
                            Fluent:SafeCallback(cfg3.Callback, dropObj.Value)
                            if dropObj.Changed then Fluent:SafeCallback(dropObj.Changed, dropObj.Value) end
                            -- Rebuild với filter hiện tại để cập nhật highlight
                            RebuildList(searchBox.Text)
                        end)

                        table.insert(optionButtons, optBtn)
                    end
                end

                emptyLabel.Visible = (count == 0)
                -- Update canvas
                task.wait()
                local listH = math.min(listLayout.AbsoluteContentSize.Y + 4, 200)
                listScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 4)
                listScroll.Size       = UDim2.new(1, -10, 0, listH)
                popup.Size            = UDim2.fromOffset(220, listH + 44)
            end

            -- Search listener
            searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                RebuildList(searchBox.Text)
            end)

            -- Initial build
            RebuildList("")
            UpdateDisplay()

            -- ── Open / Close popup ────────────────────────────────────────────
            local function PositionPopup()
                local absPos = dispBg.AbsolutePosition
                local absSize = dispBg.AbsoluteSize
                popup.Position = UDim2.fromOffset(
                    absPos.X,
                    absPos.Y + absSize.Y + 4
                )
            end

            local function OpenPopup()
                dropObj.Opened = true
                PositionPopup()
                RebuildList("")
                searchBox.Text = ""
                popup.Visible  = true
                Tween(chevron, TweenInfo.new(0.2), { Rotation = 180 })
                task.defer(function() searchBox:CaptureFocus() end)
            end

            local function ClosePopup()
                dropObj.Opened = false
                popup.Visible  = false
                Tween(chevron, TweenInfo.new(0.2), { Rotation = 0 })
                searchBox.Text = ""
            end

            dispBtn.MouseButton1Click:Connect(function()
                if dropObj.Opened then ClosePopup() else OpenPopup() end
            end)

            -- Close when clicking outside
            UserInputService.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 and dropObj.Opened then
                    local popAbs  = popup.AbsolutePosition
                    local popSize = popup.AbsoluteSize
                    local dispAbs = dispBg.AbsolutePosition
                    local dispSz  = dispBg.AbsoluteSize
                    local mx, my  = Mouse.X, Mouse.Y
                    local inPopup = mx >= popAbs.X and mx <= popAbs.X + popSize.X
                                and my >= popAbs.Y and my <= popAbs.Y + popSize.Y
                    local inBtn   = mx >= dispAbs.X and mx <= dispAbs.X + dispSz.X
                                and my >= dispAbs.Y and my <= dispAbs.Y + dispSz.Y
                    if not inPopup and not inBtn then
                        ClosePopup()
                    end
                end
            end)

            -- Set default
            if cfg3.Default then
                if cfg3.Multi and type(cfg3.Default) == "table" then
                    for _, v in ipairs(cfg3.Default) do dropObj.Value[v] = true end
                elseif type(cfg3.Default) == "string" then
                    if table.find(cfg3.Values, cfg3.Default) then
                        dropObj.Value = cfg3.Default
                    end
                end
                UpdateDisplay()
                RebuildList("")
            end

            function dropObj:SetValues(vals)
                dropObj.Values = vals
                RebuildList(searchBox.Text)
                UpdateDisplay()
            end
            function dropObj:SetValue(v)
                if cfg3.Multi then
                    dropObj.Value = {}
                    if type(v) == "table" then
                        for _, x in ipairs(v) do dropObj.Value[x] = true end
                    end
                else
                    dropObj.Value = (type(v) == "string" and table.find(dropObj.Values, v)) and v or nil
                end
                UpdateDisplay()
                RebuildList(searchBox.Text)
                Fluent:SafeCallback(cfg3.Callback, dropObj.Value)
            end
            function dropObj:OnChanged(fn) self.Changed = fn fn(dropObj.Value) end
            function dropObj:Destroy()
                popup:Destroy()
                frame:Destroy()
                Fluent.Options[key] = nil
            end

            Fluent.Options[key] = dropObj
            return dropObj
        end

        -- ── AddInput ─────────────────────────────────────────────────────────
        function tabObj:AddInput(key, cfg3)
            assert(cfg3.Title, "Input - Missing Title")
            cfg3.Callback = cfg3.Callback or function() end

            local inputObj = { Value = cfg3.Default or "" }
            local frame    = MakeElement(cfg3.Title, cfg3.Description)

            local inputBg = New("Frame", {
                Size             = UDim2.fromOffset(160, 28),
                AnchorPoint      = Vector2.new(1, 0.5),
                Position         = UDim2.new(1, -10, 0.5, 0),
                BackgroundColor3 = T.Input,
                BackgroundTransparency = 0.9,
                BorderSizePixel  = 0,
                Parent           = frame,
            }, {
                New("UICorner", { CornerRadius = UDim.new(0, 5) }),
                New("UIStroke", {
                    Color        = T.InBorder,
                    Transparency = 0.5,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                }),
                New("Frame", {
                    Size             = UDim2.new(1, -4, 0, 1),
                    Position         = UDim2.new(0, 2, 1, 0),
                    AnchorPoint      = Vector2.new(0, 1),
                    BackgroundColor3 = T.InBorder,
                    BackgroundTransparency = 0.5,
                    BorderSizePixel  = 0,
                }),
            })

            local inputBox = New("TextBox", {
                PlaceholderText  = cfg3.Placeholder or "",
                Text             = cfg3.Default or "",
                Font             = Enum.Font.Gotham,
                TextSize         = 12,
                TextColor3       = T.Text,
                PlaceholderColor3 = T.SubText,
                TextXAlignment   = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                ClearTextOnFocus = false,
                Size             = UDim2.new(1, -12, 1, 0),
                Position         = UDim2.fromOffset(8, 0),
                Parent           = inputBg,
            })

            inputBox:GetPropertyChangedSignal("Text"):Connect(function()
                local v = inputBox.Text
                if cfg3.Numeric then
                    local filtered = v:gsub("[^%d%.%-]", "")
                    if filtered ~= v then inputBox.Text = filtered; return end
                end
                if cfg3.MaxLength and #v > cfg3.MaxLength then
                    inputBox.Text = v:sub(1, cfg3.MaxLength); return
                end
                inputObj.Value = v
                if not cfg3.Finished then
                    Fluent:SafeCallback(cfg3.Callback, v)
                    if inputObj.Changed then Fluent:SafeCallback(inputObj.Changed, v) end
                end
            end)
            if cfg3.Finished then
                inputBox.FocusLost:Connect(function(enter)
                    if not enter then return end
                    inputObj.Value = inputBox.Text
                    Fluent:SafeCallback(cfg3.Callback, inputObj.Value)
                    if inputObj.Changed then Fluent:SafeCallback(inputObj.Changed, inputObj.Value) end
                end)
            end

            inputBox.Focused:Connect(function()
                Tween(inputBg, TweenInfo.new(0.15), { BackgroundTransparency = 0.6 })
                inputBg.UIStroke.Color = T.Accent
            end)
            inputBox.FocusLost:Connect(function()
                Tween(inputBg, TweenInfo.new(0.15), { BackgroundTransparency = 0.9 })
                inputBg.UIStroke.Color = T.InBorder
            end)

            function inputObj:SetValue(v) inputBox.Text = v; inputObj.Value = v end
            function inputObj:OnChanged(fn) self.Changed = fn fn(inputObj.Value) end
            function inputObj:Destroy() frame:Destroy() Fluent.Options[key] = nil end

            Fluent.Options[key] = inputObj
            return inputObj
        end

        -- ── AddParagraph ──────────────────────────────────────────────────────
        function tabObj:AddParagraph(cfg3)
            assert(cfg3.Title, "Paragraph - Missing Title")
            cfg3.Content = cfg3.Content or ""
            local frame  = MakeElement(cfg3.Title, cfg3.Content)
            frame.BackgroundTransparency = 0.92
        end

        -- ── AddKeybind ────────────────────────────────────────────────────────
        function tabObj:AddKeybind(key, cfg3)
            assert(cfg3.Title,   "Keybind - Missing Title")
            assert(cfg3.Default, "Keybind - Missing Default")
            cfg3.Callback = cfg3.Callback or function() end
            cfg3.Mode     = cfg3.Mode or "Toggle"

            local kbObj   = { Value = cfg3.Default, Toggled = false }
            local frame   = MakeElement(cfg3.Title, cfg3.Description)
            local listening = false

            local kbBg = New("Frame", {
                Size             = UDim2.fromOffset(0, 28),
                AnchorPoint      = Vector2.new(1, 0.5),
                Position         = UDim2.new(1, -10, 0.5, 0),
                BackgroundColor3 = T.Input,
                BackgroundTransparency = 0.9,
                AutomaticSize    = Enum.AutomaticSize.X,
                BorderSizePixel  = 0,
                Parent           = frame,
            }, {
                New("UICorner", { CornerRadius = UDim.new(0, 5) }),
                New("UIStroke", { Color = T.InBorder, Transparency = 0.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
                New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
            })
            local kbLabel = New("TextLabel", {
                Text             = tostring(cfg3.Default),
                Font             = Enum.Font.Gotham,
                TextSize         = 12,
                TextColor3       = T.Text,
                BackgroundTransparency = 1,
                Size             = UDim2.fromScale(0, 1),
                AutomaticSize    = Enum.AutomaticSize.X,
                Parent           = kbBg,
            })

            local kbBtn = New("TextButton", {
                Size             = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text             = "",
                Parent           = kbBg,
            })

            kbBtn.MouseButton1Click:Connect(function()
                if listening then return end
                listening      = true
                kbLabel.Text   = "..."
                local conn
                conn = UserInputService.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.Keyboard then
                        kbObj.Value  = inp.KeyCode.Name
                        kbLabel.Text = inp.KeyCode.Name
                        listening    = false
                        conn:Disconnect()
                    end
                end)
            end)

            UserInputService.InputBegan:Connect(function(inp)
                if listening then return end
                if inp.UserInputType == Enum.UserInputType.Keyboard then
                    if inp.KeyCode.Name == kbObj.Value then
                        if cfg3.Mode == "Toggle" then
                            kbObj.Toggled = not kbObj.Toggled
                            Fluent:SafeCallback(cfg3.Callback, kbObj.Toggled)
                        elseif cfg3.Mode == "Always" then
                            Fluent:SafeCallback(cfg3.Callback, true)
                        end
                    end
                end
            end)

            function kbObj:SetValue(v) kbObj.Value = v; kbLabel.Text = v end
            function kbObj:GetState()
                if cfg3.Mode == "Always" then return true end
                if cfg3.Mode == "Hold" then return UserInputService:IsKeyDown(Enum.KeyCode[kbObj.Value]) end
                return kbObj.Toggled
            end
            function kbObj:Destroy() frame:Destroy() Fluent.Options[key] = nil end

            Fluent.Options[key] = kbObj
            return kbObj
        end

        return tabObj
    end

    -- ── Dialog ──
    function Window:Dialog(cfg2)
        local overlay = New("TextButton", {
            Size             = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.6,
            Text             = "",
            ZIndex           = 100,
            Parent           = Fluent.GUI,
        })
        local dlgFrame = New("Frame", {
            Size             = UDim2.fromOffset(300, 165),
            AnchorPoint      = Vector2.new(0.5, 0.5),
            Position         = UDim2.fromScale(0.5, 0.5),
            BackgroundColor3 = T.DropHolder,
            BorderSizePixel  = 0,
            ZIndex           = 101,
            Parent           = overlay,
        }, {
            New("UICorner", { CornerRadius = UDim.new(0, 8) }),
            New("UIStroke", { Color = T.DropBorder, Transparency = 0.3, Thickness = 1 }),
        })
        New("TextLabel", {
            Text             = cfg2.Title or "Dialog",
            Font             = Enum.Font.GothamSemibold,
            TextSize         = 18,
            TextColor3       = T.Text,
            TextXAlignment   = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Size             = UDim2.new(1, -40, 0, 22),
            Position         = UDim2.fromOffset(20, 20),
            ZIndex           = 102,
            Parent           = dlgFrame,
        })
        New("TextLabel", {
            Text             = cfg2.Content or "",
            Font             = Enum.Font.Gotham,
            TextSize         = 13,
            TextColor3       = T.Text,
            TextXAlignment   = Enum.TextXAlignment.Left,
            TextWrapped      = true,
            BackgroundTransparency = 1,
            Size             = UDim2.new(1, -40, 0, 60),
            Position         = UDim2.fromOffset(20, 50),
            ZIndex           = 102,
            Parent           = dlgFrame,
        })
        local btnHolder = New("Frame", {
            Size             = UDim2.new(1, -40, 0, 32),
            Position         = UDim2.new(0, 20, 1, -50),
            BackgroundTransparency = 1,
            ZIndex           = 102,
            Parent           = dlgFrame,
        }, {
            New("UIListLayout", {
                FillDirection        = Enum.FillDirection.Horizontal,
                HorizontalAlignment  = Enum.HorizontalAlignment.Right,
                Padding              = UDim.new(0, 8),
            }),
        })
        for _, btnCfg in ipairs(cfg2.Buttons or {}) do
            local b = New("TextButton", {
                Size             = UDim2.fromOffset(80, 30),
                BackgroundColor3 = T.DropHolder,
                BackgroundTransparency = 0.6,
                Text             = btnCfg.Title or "OK",
                Font             = Enum.Font.Gotham,
                TextSize         = 13,
                TextColor3       = T.Text,
                ZIndex           = 103,
                Parent           = btnHolder,
            }, {
                New("UICorner", { CornerRadius = UDim.new(0, 4) }),
                New("UIStroke", { Color = T.InBorder, Transparency = 0.5, Thickness = 1 }),
            })
            b.MouseButton1Click:Connect(function()
                Fluent:SafeCallback(btnCfg.Callback)
                overlay:Destroy()
            end)
        end
    end

    -- ── Minimize (toggle visibility) ──
    function Window:Minimize()
        WinFrame.Visible = not WinFrame.Visible
    end

    -- ── Destroy ──
    function Window:Destroy()
        Fluent.Unloaded = true
        ScreenGui:Destroy()
    end

    -- ── SelectTab shortcut ──
    function Window:SelectTab(index)
        SelectTab(index)
    end

    return Window
end

-- ─── Notify ──────────────────────────────────────────────────────────────────
function Fluent:Notify(cfg)
    cfg.Title    = cfg.Title    or "Notice"
    cfg.Content  = cfg.Content  or ""
    cfg.Duration = cfg.Duration or 4

    -- Holder (bottom-right corner)
    if not self._notifyHolder then
        self._notifyHolder = New("Frame", {
            Size             = UDim2.fromOffset(310, 0),
            Position         = UDim2.new(1, -330, 1, -20),
            AnchorPoint      = Vector2.new(0, 1),
            BackgroundTransparency = 1,
            Parent           = ScreenGui,
        }, {
            New("UIListLayout", {
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment   = Enum.VerticalAlignment.Bottom,
                SortOrder           = Enum.SortOrder.LayoutOrder,
                Padding             = UDim.new(0, 8),
            }),
        })
    end

    local notifFrame = New("Frame", {
        Size             = UDim2.new(1, 0, 0, 72),
        BackgroundColor3 = T.DropHolder,
        BackgroundTransparency = 0.1,
        BorderSizePixel  = 0,
        ClipsDescendants = false,
        Parent           = self._notifyHolder,
    }, {
        New("UICorner", { CornerRadius = UDim.new(0, 8) }),
        New("UIStroke", { Color = T.DropBorder, Transparency = 0.3 }),
        New("TextLabel", {
            Text             = cfg.Title,
            Font             = Enum.Font.GothamSemibold,
            TextSize         = 13,
            TextColor3       = T.Text,
            TextXAlignment   = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Size             = UDim2.new(1, -20, 0, 14),
            Position         = UDim2.fromOffset(14, 14),
        }),
        New("TextLabel", {
            Text             = cfg.Content,
            Font             = Enum.Font.Gotham,
            TextSize         = 12,
            TextColor3       = T.SubText,
            TextXAlignment   = Enum.TextXAlignment.Left,
            TextWrapped      = true,
            BackgroundTransparency = 1,
            Size             = UDim2.new(1, -20, 0, 28),
            Position         = UDim2.fromOffset(14, 32),
        }),
    })

    task.delay(cfg.Duration, function()
        Tween(notifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { BackgroundTransparency = 1 })
        task.wait(0.3)
        notifFrame:Destroy()
    end)
end

-- ─── getgenv export ──────────────────────────────────────────────────────────
if getgenv then
    getgenv().Fluent = Fluent
end

return Fluent

--[[ ═══════════════════════════════════════════════════════════════
  EXAMPLE USAGE  (xóa phần này khi dùng thật)
  ═══════════════════════════════════════════════════════════════ ]]--[[

local Fluent = loadstring(game:HttpGet("..."))()

local Window = Fluent:CreateWindow({
    Title    = "My Script",
    SubTitle = "v1.0",
    Theme    = "Dark",
    Size     = UDim2.fromOffset(520, 420),
    TabWidth = 140,
})

-- Tab 1
local Main = Window:AddTab({ Title = "Main" })

Main:AddSection("Combat")

-- Slider với Name, Description và ô Input số
local KillAt = Main:AddSlider("KillAt", {
    Title       = "Kill At",
    Description = "Mức máu để kill enemy",
    Min         = 0,
    Max         = 100,
    Default     = 100,
    Rounding    = 0,
    Callback    = function(v)
        print("Kill At:", v)
    end,
})

-- Dropdown với Search bar (case-insensitive)
local TargetPart = Main:AddDropdown("TargetPart", {
    Title       = "Target Part",
    Description = "Chọn part để nhắm",
    Values      = { "Head", "Torso", "Cailon", "HumanoidRootPart", "LeftArm", "RightArm" },
    Default     = "Head",
    Callback    = function(v)
        print("Target:", v)
    end,
})

-- Toggle
local AutoFarm = Main:AddToggle("AutoFarm", {
    Title    = "Auto Farm",
    Default  = false,
    Callback = function(v) print("AutoFarm:", v) end,
})

-- Tab 2
local Settings = Window:AddTab({ Title = "Settings" })

Settings:AddSlider("WalkSpeed", {
    Title       = "Walk Speed",
    Description = "Tốc độ di chuyển",
    Min         = 0,
    Max         = 100,
    Default     = 16,
    Rounding    = 0,
    Callback    = function(v)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v
    end,
})

Settings:AddDropdown("Theme", {
    Title   = "Theme",
    Values  = { "Dark", "Darker", "Light", "Aqua", "Amethyst", "Rose" },
    Default = "Dark",
    Callback = function(v) print("Theme:", v) end,
})

-- Chọn tab đầu tiên
Window:SelectTab(1)

Fluent:Notify({
    Title   = "Loaded",
    Content = "Script đã load xong!",
    Duration = 4,
})

]]
