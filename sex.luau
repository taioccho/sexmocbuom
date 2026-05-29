--[[
    ╔══════════════════════════════════════════════╗
    ║        AUTO CYBORG SCRIPT - OPTIMIZED        ║
    ║         This file create by Tuan_nat2026.            ║
    ╚══════════════════════════════════════════════╝
    Changelog:
    - Thêm UI hiển thị trạng thái real-time (draggable)
    - Đổi toàn bộ wait() → task.wait(), spawn() → task.spawn()
    - Xóa duplicate: startNoClip x2, HasFistOfDarkness + hasFistOfDarkness
    - Xóa biến global khai báo trùng lặp
    - Sửa getgenv().Setting chưa khởi tạo
    - Sửa unreachable code trong checkForCoreBrain()
    - Thêm bộ đếm rương và đồng hồ server
    - Tối ưu logic mainCycle, tránh spam notification
--]]

-- ─────────────────────────────────────────────────
--  WAIT FOR GAME LOAD
-- ─────────────────────────────────────────────────
repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer:FindFirstChild("DataLoaded")

-- ─────────────────────────────────────────────────
--  SERVICES
-- ─────────────────────────────────────────────────
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local TweenService   = game:GetService("TweenService")
local TeleportService= game:GetService("TeleportService")
local HttpService     = game:GetService("HttpService")
local StarterGui     = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser    = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer    = Players.LocalPlayer

-- ─────────────────────────────────────────────────
--  TEAM SELECTION
-- ─────────────────────────────────────────────────
if LocalPlayer.PlayerGui:FindFirstChild("Main (minimal)") then
    repeat
        task.wait()
        local remotes = ReplicatedStorage:WaitForChild("Remotes")
        remotes.CommF_:InvokeServer("SetTeam", getgenv().team)
        task.wait(3)
    until not LocalPlayer.PlayerGui:FindFirstChild("Main (minimal)")
end

-- ─────────────────────────────────────────────────
--  GLOBAL VARIABLES (khai báo 1 lần duy nhất)
-- ─────────────────────────────────────────────────
_G.AutoCollectChest     = true
_G.AutoRejoin           = true
_G.starthop             = true
_G.AutoHopEnabled       = true
_G.AutoJump             = true
_G.Antikick             = true
_G.AutoFightDarkbeard   = nil
_G.FightDarkbeardOnlyWithFist = nil
_G.IsFightingBoss       = false
_G.AutoCyborg           = nil
_G.IsFightingCyborgBoss = false
_G.NeedCoreBrain        = true
_G.HasCoreBrain         = false
_G.HasFistOfDarkness    = false
_G.IsChestFarming       = false
_G.IsCheckingForCoreBrain = false
_G.MicrochipPurchased   = false
_G.KeyDetected          = false
_G.FistDetected         = false
_G.StopTween            = false
_G.StopTween2           = false
_G.CancelTween2         = false
_G.LastPosition         = nil
_G.LastTimeChecked      = tick()
_G.LastChestCollectedTime = tick()
_G.MicrochipNotFound    = false
_G.ChestFarmingRunning  = false

-- UI tracking
_G.ChestCount           = 0
_G.StatusText           = "Khởi động..."
_G.ServerStartTime      = tick()

-- Khởi tạo Setting để tránh lỗi getgenv().Setting
if not getgenv().Setting then
    getgenv().Setting = { WhiteScreen = false }
end

TweenSpeed = 350

-- ─────────────────────────────────────────────────
--  STATUS UI (Draggable)
-- ─────────────────────────────────────────────────
local function CreateStatusUI()
    -- Xóa UI cũ nếu tồn tại
    if LocalPlayer.PlayerGui:FindFirstChild("AutoCyborgUI") then
        LocalPlayer.PlayerGui.AutoCyborgUI:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoCyborgUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = LocalPlayer.PlayerGui

    -- Main Frame
    local Frame = Instance.new("Frame")
    Frame.Name = "MainFrame"
    Frame.Size = UDim2.new(0, 220, 0, 270)
    Frame.Position = UDim2.new(0, 10, 0, 100)
    Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    Frame.BackgroundTransparency = 0.1
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = Frame

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(0, 200, 255)
    UIStroke.Thickness = 1.5
    UIStroke.Parent = Frame

    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 32)
    TitleBar.BackgroundColor3 = Color3.fromRGB(0, 150, 220)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = Frame

    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 10)
    TitleCorner.Parent = TitleBar

    local TitleFix = Instance.new("Frame")
    TitleFix.Size = UDim2.new(1, 0, 0.5, 0)
    TitleFix.Position = UDim2.new(0, 0, 0.5, 0)
    TitleFix.BackgroundColor3 = Color3.fromRGB(0, 150, 220)
    TitleFix.BorderSizePixel = 0
    TitleFix.Parent = TitleBar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Text = "🤖 AUTO CYBORG"
    TitleLabel.Size = UDim2.new(1, 0, 1, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 13
    TitleLabel.Parent = TitleBar

    -- Minimize Button
    local MinBtn = Instance.new("TextButton")
    MinBtn.Text = "─"
    MinBtn.Size = UDim2.new(0, 24, 0, 24)
    MinBtn.Position = UDim2.new(1, -28, 0, 4)
    MinBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
    MinBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextSize = 14
    MinBtn.BorderSizePixel = 0
    MinBtn.Parent = TitleBar
    local MinCorner = Instance.new("UICorner")
    MinCorner.CornerRadius = UDim.new(0, 5)
    MinCorner.Parent = MinBtn

    -- Content Area
    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, 0, 1, -32)
    Content.Position = UDim2.new(0, 0, 0, 32)
    Content.BackgroundTransparency = 1
    Content.Parent = Frame

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 2)
    Layout.Parent = Content

    local Padding = Instance.new("UIPadding")
    Padding.PaddingLeft = UDim.new(0, 8)
    Padding.PaddingRight = UDim.new(0, 8)
    Padding.PaddingTop = UDim.new(0, 6)
    Padding.Parent = Content

    -- Helper: create a row label
    local function MakeRow(name, defaultText, color)
        local lbl = Instance.new("TextLabel")
        lbl.Name = name
        lbl.Text = defaultText
        lbl.Size = UDim2.new(1, 0, 0, 20)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = color or Color3.fromRGB(200, 200, 200)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = Content
        return lbl
    end

    -- Helper: Divider
    local function MakeDivider()
        local div = Instance.new("Frame")
        div.Size = UDim2.new(1, 0, 0, 1)
        div.BackgroundColor3 = Color3.fromRGB(0, 150, 220)
        div.BackgroundTransparency = 0.5
        div.BorderSizePixel = 0
        div.Parent = Content
    end

    -- Status Row
    local StatusRow = MakeRow("StatusRow", "⚡ Status: Khởi động...", Color3.fromRGB(255, 220, 50))

    MakeDivider()

    -- Stats
    local ChestRow    = MakeRow("ChestRow",   "📦 Rương: 0",             Color3.fromRGB(100, 220, 100))
    local ServerRow   = MakeRow("ServerRow",  "⏱️ Server: --:--",         Color3.fromRGB(150, 180, 255))

    MakeDivider()

    -- Items
    MakeRow("ItemsTitle", "── VẬT PHẨM ──", Color3.fromRGB(0, 200, 255))
    local FistRow    = MakeRow("FistRow",    "🗡️ Fist of Darkness: ✗",  Color3.fromRGB(255, 100, 100))
    local CoreRow    = MakeRow("CoreRow",    "🧠 Core Brain: ✗",         Color3.fromRGB(255, 100, 100))
    local ChipRow    = MakeRow("ChipRow",    "💊 Microchip: ✗",          Color3.fromRGB(255, 100, 100))
    local CyborgRow  = MakeRow("CyborgRow",  "🤖 Cyborg Race: ✗",       Color3.fromRGB(255, 100, 100))

    MakeDivider()

    -- Flags
    MakeRow("FlagsTitle", "── TRẠNG THÁI ──", Color3.fromRGB(0, 200, 255))
    local HopRow    = MakeRow("HopRow",  "🔀 Auto Hop: ON",   Color3.fromRGB(100, 220, 100))
    local JumpRow   = MakeRow("JumpRow", "⬆️ Auto Jump: ON",  Color3.fromRGB(100, 220, 100))

    -- Dragging logic
    local dragging, dragStart, startPos
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = Frame.Position
        end
    end)
    TitleBar.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                         input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    TitleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- Minimize toggle
    local minimized = false
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        Content.Visible = not minimized
        Frame.Size = minimized and UDim2.new(0, 220, 0, 32) or UDim2.new(0, 220, 0, 270)
        MinBtn.Text = minimized and "+" or "─"
    end)

    -- Live update loop
    task.spawn(function()
        while task.wait(0.5) do
            pcall(function()
                -- Status
                StatusRow.Text = "⚡ " .. (_G.StatusText or "Đang chạy...")

                -- Chests
                ChestRow.Text = "📦 Rương: " .. (_G.ChestCount or 0)

                -- Server timer (15 min cycle)
                local elapsed = math.floor(tick() - _G.ServerStartTime)
                local limit   = 15 * 60
                local remain  = math.max(0, limit - elapsed)
                local mm      = math.floor(remain / 60)
                local ss      = remain % 60
                ServerRow.Text = string.format("⏱️ Server: %d:%02d còn lại", mm, ss)

                -- Items
                local hasFist = _G.HasFistOfDarkness
                local hasCore = _G.HasCoreBrain
                local hasChip = hasMicrochip and hasMicrochip() or false
                local hasCyb  = pcall(function()
                    return Players.LocalPlayer.Data.Race.Value == "Cyborg"
                end)
                local isCyb   = false
                pcall(function()
                    isCyb = Players.LocalPlayer.Data.Race.Value == "Cyborg"
                end)

                FistRow.Text   = "🗡️ Fist of Darkness: " .. (hasFist and "✓" or "✗")
                FistRow.TextColor3 = hasFist and Color3.fromRGB(100,220,100) or Color3.fromRGB(255,100,100)

                CoreRow.Text   = "🧠 Core Brain: " .. (hasCore and "✓" or "✗")
                CoreRow.TextColor3 = hasCore and Color3.fromRGB(100,220,100) or Color3.fromRGB(255,100,100)

                ChipRow.Text   = "💊 Microchip: " .. (hasChip and "✓" or "✗")
                ChipRow.TextColor3 = hasChip and Color3.fromRGB(100,220,100) or Color3.fromRGB(255,100,100)

                CyborgRow.Text = "🤖 Cyborg Race: " .. (isCyb and "✓" or "✗")
                CyborgRow.TextColor3 = isCyb and Color3.fromRGB(100,220,100) or Color3.fromRGB(255,100,100)

                -- Flags
                HopRow.Text   = "🔀 Auto Hop: " .. (_G.AutoHopEnabled and "ON" or "OFF")
                HopRow.TextColor3 = _G.AutoHopEnabled and Color3.fromRGB(100,220,100) or Color3.fromRGB(255,100,100)

                JumpRow.Text  = "⬆️ Auto Jump: " .. (_G.AutoJump and "ON" or "OFF")
                JumpRow.TextColor3 = _G.AutoJump and Color3.fromRGB(100,220,100) or Color3.fromRGB(255,100,100)
            end)
        end
    end)

    return ScreenGui
end

-- Tạo UI ngay
local StatusUI = CreateStatusUI()

-- Tạo lại UI khi respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(2)
    if not LocalPlayer.PlayerGui:FindFirstChild("AutoCyborgUI") then
        StatusUI = CreateStatusUI()
    end
end)

-- ─────────────────────────────────────────────────
--  HELPER: Update Status Text
-- ─────────────────────────────────────────────────
local function SetStatus(text)
    _G.StatusText = text
end

-- ─────────────────────────────────────────────────
--  EXTERNAL SCRIPTS
-- ─────────────────────────────────────────────────
task.spawn(function()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/mizuharasup/autobonuty/refs/heads/main/all.txt"))()
    end)
end)

task.spawn(function()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/mizuharasup/autobonuty/refs/heads/main/zder.lua"))()
    end)
end)

-- ─────────────────────────────────────────────────
--  FPS BOOST
-- ─────────────────────────────────────────────────
local function ApplyFPSBoost()
    pcall(function()
        for _, v in pairs(game:GetService("Lighting"):GetChildren()) do
            if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect")
                or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("Atmosphere") then
                v:Destroy()
            end
        end
    end)
    pcall(function()
        local l = game:GetService("Lighting")
        l.GlobalShadows = false
        l.FogEnd = 9e9
        l.Brightness = 0
    end)
    pcall(function() settings().Rendering.QualityLevel = "Level01" end)
    pcall(function() UserSettings():GetService("UserGameSettings").MasterVolume = 0 end)
    pcall(function()
        if workspace:FindFirstChild("Terrain") then
            local t = workspace.Terrain
            t.WaterWaveSize = 0
            t.WaterWaveSpeed = 0
            t.WaterReflectance = 0
            t.WaterTransparency = 0
        end
    end)
    local count = 0
    pcall(function()
        for _, v in pairs(game:GetDescendants()) do
            count += 1
            if count > 3000 then break end
            if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("CornerWedgePart") or v:IsA("TrussPart") then
                v.Material = Enum.Material.Plastic
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Lifetime = NumberRange.new(0)
                v.Enabled = false
            elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") then
                v.Enabled = false
            elseif v:IsA("MeshPart") then
                v.Material = Enum.Material.Plastic
                v.Reflectance = 0
            end
        end
    end)
end

ApplyFPSBoost()

task.spawn(function()
    while task.wait(60) do
        pcall(ApplyFPSBoost)
    end
end)

-- ─────────────────────────────────────────────────
--  WHITESCREEN TOGGLE
-- ─────────────────────────────────────────────────
function ToggleWhiteScreen(enable)
    getgenv().Setting.WhiteScreen = enable
    pcall(function()
        RunService:Set3dRenderingEnabled(not enable)
    end)
end

-- ─────────────────────────────────────────────────
--  NO COLLISION (Stepped)
-- ─────────────────────────────────────────────────
RunService.Stepped:Connect(function()
    if _G.AutoCollectChest or _G.IsFightingBoss or _G.IsFightingCyborgBoss then
        pcall(function()
            local character = LocalPlayer.Character
            if character then
                for _, p in pairs(character:GetDescendants()) do
                    if p:IsA("BasePart") then
                        p.CanCollide = false
                    end
                end
            end
        end)
    end
end)

-- ─────────────────────────────────────────────────
--  NOCLIP + ANTI-GRAVITY (consolidated, single function)
-- ─────────────────────────────────────────────────
local function EnableNoClip()
    pcall(function()
        local character = LocalPlayer.Character
        if not character then return end

        for _, p in pairs(character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end

        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            -- Xóa BodyVelocity cũ
            for _, c in pairs(hrp:GetChildren()) do
                if c:IsA("BodyVelocity") and (c.Name == "ChestFarmAntiGravity" or c.Name == "AntiGravity") then
                    c:Destroy()
                end
            end
            local bv = Instance.new("BodyVelocity")
            bv.Name = "ChestFarmAntiGravity"
            bv.MaxForce = Vector3.new(0, 9999, 0)
            bv.Velocity  = Vector3.new(0, 0.5, 0)
            bv.P = 1500
            bv.Parent = hrp
        end

        local hum = character:FindFirstChild("Humanoid")
        if hum then
            hum:ChangeState(11)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        end
    end)
end

-- ─────────────────────────────────────────────────
--  MOVEMENT FUNCTIONS
-- ─────────────────────────────────────────────────
function SafeTween(targetCF, speed)
    local ok, result = pcall(function()
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
        local dist = (targetCF.Position - character.HumanoidRootPart.Position).Magnitude
        local spd  = speed or TweenSpeed
        local info = TweenInfo.new(dist / spd, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(character.HumanoidRootPart, info, { CFrame = targetCF })
        tween:Play()
        return tween
    end)
    return ok and result or nil
end

function Tween(KG)
    pcall(function()
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        local dist = (KG.Position - character.HumanoidRootPart.Position).Magnitude
        local info = TweenInfo.new(dist / TweenSpeed, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(character.HumanoidRootPart, info, { CFrame = KG })
        tween:Play()
        if _G.StopTween then tween:Cancel() end
    end)
end

function Tween2(targetCFrame)
    EnableNoClip()
    pcall(function()
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        local dist = (targetCFrame.Position - character.HumanoidRootPart.Position).Magnitude
        local info = TweenInfo.new(dist / 350, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(character.HumanoidRootPart, info, { CFrame = targetCFrame })
        tween.Completed:Connect(function() EnableNoClip() end)
        tween:Play()
        task.wait(dist / 350 + 0.1)
    end)
end

function BKP(Point)
    pcall(function()
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            character.HumanoidRootPart.CFrame = Point
            task.wait()
            character.HumanoidRootPart.CFrame = Point
        end
    end)
end

function CancelTween()
    _G.StopTween = true
    task.wait()
    pcall(function() Tween(LocalPlayer.Character.HumanoidRootPart.CFrame) end)
    task.wait()
    _G.StopTween = false
end

-- ─────────────────────────────────────────────────
--  UTILITY
-- ─────────────────────────────────────────────────
function AutoHaki()
    pcall(function()
        local player = LocalPlayer
        if player.Character and not player.Character:FindFirstChild("HasBuso") then
            ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
        end
    end)
end

function equip(tooltip)
    local player = LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    for _, item in pairs(player.Backpack:GetChildren()) do
        if item:IsA("Tool") and item.ToolTip == tooltip then
            humanoid:EquipTool(item)
            return true
        end
    end
    for _, item in pairs(character:GetChildren()) do
        if item:IsA("Tool") and item.ToolTip == tooltip then return true end
    end
    return false
end

function isCyborg()
    local ok, result = pcall(function()
        return LocalPlayer.Data.Race.Value == "Cyborg"
    end)
    if ok and result then
        _G.AutoCyborg      = false
        _G.AutoCollectChest = false
        _G.IsChestFarming  = false
        _G.IsFightingBoss  = false
        _G.AutoJump        = false
        return true
    end
    return false
end

-- ─────────────────────────────────────────────────
--  ITEM CHECKS
-- ─────────────────────────────────────────────────
function hasCoreBrain()
    local player = LocalPlayer
    local function check(container)
        for _, item in pairs(container:GetChildren()) do
            if item.Name == "Core Brain" then
                _G.AutoCollectChest = false
                _G.IsChestFarming   = false
                _G.HasCoreBrain     = true
                _G.NeedCoreBrain    = false
                _G.AutoJump         = false
                return true
            end
        end
        return false
    end
    if check(player.Backpack) then return true end
    if player.Character and check(player.Character) then return true end
    return false
end

function equipCoreBrain()
    local player = LocalPlayer
    for _, item in pairs(player.Backpack:GetChildren()) do
        if item.Name == "Core Brain" then
            local char = player.Character or player.CharacterAdded:Wait()
            local hum  = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:EquipTool(item) end
            return true
        end
    end
    if player.Character then
        for _, item in pairs(player.Character:GetChildren()) do
            if item.Name == "Core Brain" then return true end
        end
    end
    return false
end

-- hasFistOfDarkness: single canonical function (lowercase)
function hasFistOfDarkness()
    local player = LocalPlayer
    local function check(container)
        for _, item in pairs(container:GetChildren()) do
            if item.Name == "Fist of Darkness" then
                if not _G.FistDetected then
                    _G.FistDetected      = true
                    _G.HasFistOfDarkness = true
                    _G.AutoJump          = false
                    _G.AutoCollectChest  = false
                    _G.IsChestFarming    = false
                    SetStatus("Tìm thấy Fist of Darkness!")
                    task.spawn(processFistOfDarkness)
                end
                return true
            end
        end
        return false
    end
    if check(player.Backpack) then return true end
    if player.Character and check(player.Character) then return true end
    return false
end

function hasMicrochip()
    local player = LocalPlayer
    for _, item in pairs(player.Backpack:GetChildren()) do
        if item.Name == "Microchip" then return true end
    end
    if player.Character then
        for _, item in pairs(player.Character:GetChildren()) do
            if item.Name == "Microchip" then return true end
        end
    end
    return false
end

function buyMicrochip()
    if hasMicrochip() then return true end
    if _G.MicrochipPurchased and not hasMicrochip() then
        _G.MicrochipPurchased = false
    end
    local args = { [1] = "BlackbeardReward", [2] = "Microchip", [3] = "2" }
    ReplicatedStorage.Remotes.CommF_:InvokeServer(unpack(args))
    _G.MicrochipPurchased = true
    task.wait(1)
    return hasMicrochip()
end

function buyCyborgRace()
    local args = { [1] = "CyborgTrainer", [2] = "Buy" }
    ReplicatedStorage.Remotes.CommF_:InvokeServer(unpack(args))
    task.wait(2)
    if isCyborg() then
        _G.AutoCyborg = false
        _G.AutoCollectChest = false
        SetStatus("✅ Đã mua Cyborg thành công!")
        StarterGui:SetCore("SendNotification", {
            Title = "Auto Cyborg",
            Text = "Đã mua thành công tộc Cyborg!",
            Duration = 10
        })
        return true
    end
    return false
end

-- ─────────────────────────────────────────────────
--  CLICK DETECTOR FUNCTIONS
-- ─────────────────────────────────────────────────
_G.LastClickTime = 0
_G.ClickCooldown = 2

function findClickDetector()
    local ok, result = pcall(function()
        local button = workspace:FindFirstChild("Map")
        button = button and button:FindFirstChild("CircleIsland")
        button = button and button:FindFirstChild("RaidSummon")
        button = button and button:FindFirstChild("Button")
        button = button and button:FindFirstChild("Main")
        if button then
            local det = button:FindFirstChild("ClickDetector")
            if det then return det, button.Position end
        end
        for _, v in pairs(workspace:GetDescendants()) do
            if v.Name == "ClickDetector" and v.Parent and v.Parent.Name == "Main"
                and v.Parent.Parent and v.Parent.Parent.Name == "Button"
                and v.Parent.Parent.Parent and v.Parent.Parent.Parent.Name == "RaidSummon" then
                return v, v.Parent.Position
            end
        end
        return nil, nil
    end)
    return ok and result or nil
end

function isPlayerCloseToButton(buttonPos)
    if not buttonPos then return false end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    return (buttonPos - char.HumanoidRootPart.Position).Magnitude <= 32
end

function teleportToButton(buttonPos)
    if not buttonPos then return false end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    pcall(function()
        char.HumanoidRootPart.CFrame = CFrame.new(buttonPos) + Vector3.new(0, 2, 0)
    end)
    task.wait(0.5)
    return true
end

function clickDetectorForNotification()
    local currentTime = tick()
    if currentTime - _G.LastClickTime < _G.ClickCooldown then return false end
    _G.LastClickTime = currentTime

    local detector, buttonPos = findClickDetector()
    if not detector then return false end

    if buttonPos and not isPlayerCloseToButton(buttonPos) then
        teleportToButton(buttonPos)
        task.wait(1)
    end

    pcall(function() fireclickdetector(detector) end)
    task.wait(0.3)
    pcall(function() fireclickdetector(detector) end)
    return true
end

-- ─────────────────────────────────────────────────
--  BOSS FUNCTIONS (Order/Cyborg)
-- ─────────────────────────────────────────────────
function bossExists()
    return workspace.Enemies:FindFirstChild("Order") ~= nil
end

function findBoss()
    for _, v in pairs(workspace.Enemies:GetChildren()) do
        if v.Name == "Order" and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
            return v
        end
    end
    return nil
end

function fightBoss()
    if _G.IsFightingBoss then return end
    _G.IsFightingBoss = true
    SetStatus("⚔️ Đang đánh Boss Order...")

    EnableNoClip()
    AutoHaki()
    equip("Melee")

    task.spawn(function()
        local attackCD = 0
        while _G.IsFightingBoss do
            AutoHaki()
            if tick() - attackCD > 2 then
                equip("Melee")
                attackCD = tick()
            end

            local boss = findBoss()
            if boss and boss:FindFirstChild("HumanoidRootPart") and
               boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 then

                local char = LocalPlayer.Character
                local hum  = char and char:FindFirstChild("Humanoid")
                local bpos = boss.HumanoidRootPart.Position

                if hum and hum.Health < 2000 then
                    -- Flee above boss
                    Tween(CFrame.new(bpos.X, bpos.Y + 100, bpos.Z))
                    while hum.Health < 5000 do
                        local b2 = findBoss()
                        if b2 and b2:FindFirstChild("HumanoidRootPart") then
                            local bp2 = b2.HumanoidRootPart.Position
                            Tween(CFrame.new(bp2.X, bp2.Y + 100, bp2.Z))
                        end
                        task.wait(0.5)
                    end
                else
                    Tween(CFrame.new(bpos.X, bpos.Y + 25, bpos.Z))
                    pcall(function()
                        if char and char:FindFirstChild("HumanoidRootPart") then
                            char.HumanoidRootPart.CFrame = CFrame.new(
                                char.HumanoidRootPart.Position,
                                Vector3.new(bpos.X, char.HumanoidRootPart.Position.Y, bpos.Z)
                            )
                        end
                    end)
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton1(Vector2.new(0, 0))
                end
            else
                -- Boss defeated
                _G.IsFightingBoss = false
                task.wait(1)

                if hasCoreBrain() then
                    SetStatus("🧠 Có Core Brain! Đang mua Cyborg...")
                    _G.HasCoreBrain  = true
                    _G.NeedCoreBrain = false
                    _G.AutoJump      = false
                    equipCoreBrain()
                    clickDetectorForNotification()
                    task.wait(5)
                    buyCyborgRace()
                    if not isCyborg() then
                        for i = 1, 3 do
                            clickDetectorForNotification()
                            task.wait(1)
                            buyCyborgRace()
                            task.wait(2)
                            if isCyborg() then break end
                        end
                    end
                else
                    _G.MicrochipPurchased = false
                    if hasFistOfDarkness() then
                        if not hasMicrochip() then buyMicrochip() end
                        if hasMicrochip() then
                            clickToSpawnBoss()
                        else
                            _G.AutoCollectChest = true
                            _G.IsChestFarming   = true
                            SetStatus("📦 Farm rương (không có Microchip)...")
                        end
                    else
                        _G.AutoCollectChest = true
                        _G.IsChestFarming   = true
                        SetStatus("📦 Farm rương...")
                    end
                end
                break
            end
            task.wait(0.1)
        end
    end)
end

function clickToSpawnBoss()
    if _G.IsFightingBoss then return end
    SetStatus("🔔 Spawn Boss Order...")

    if hasFistOfDarkness() and not _G.FistDetected then
        _G.FistDetected      = true
        _G.HasFistOfDarkness = true
        _G.AutoJump          = false
    end

    clickDetectorForNotification()
    task.wait(1)

    if not hasMicrochip() then
        buyMicrochip()
        task.wait(1)
    end

    if hasMicrochip() then
        local detector, buttonPos = findClickDetector()
        if detector then
            if buttonPos and not isPlayerCloseToButton(buttonPos) then
                teleportToButton(buttonPos)
                task.wait(1)
            end
            pcall(function() fireclickdetector(detector) end)
            task.wait(0.5)
            pcall(function() fireclickdetector(detector) end)
            task.wait(3)
            if bossExists() then fightBoss() end
        end
    else
        _G.AutoCollectChest = true
        _G.IsChestFarming   = true
        SetStatus("📦 Farm rương (thiếu Microchip)...")
    end
end

-- ─────────────────────────────────────────────────
--  DARKBEARD FUNCTIONS
-- ─────────────────────────────────────────────────
local function CheckBossAttack()
    local rep = ReplicatedStorage:FindFirstChild("Darkbeard")
    if rep then return rep end
    local enemies = workspace:FindFirstChild("Enemies")
    if enemies then
        local b = enemies:FindFirstChild("Darkbeard")
        if b then return b end
    end
    return workspace:FindFirstChild("Darkbeard")
end

local function DetectingPart(boss)
    if not boss then return false end
    if not boss:FindFirstChild("HumanoidRootPart") then return false end
    local hum = boss:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    return true
end

function checkDarkbeard()
    local boss = CheckBossAttack()
    return (boss and DetectingPart(boss)) and boss or nil
end

function HasFistOfDarkness() -- alias kept for backward compat
    return hasFistOfDarkness()
end

function HasGodsChalice()
    local player = LocalPlayer
    return player.Backpack:FindFirstChild("God's Chalice") or
           (player.Character and player.Character:FindFirstChild("God's Chalice"))
end

function FightDarkbeard()
    local boss = checkDarkbeard()
    if not boss then return end

    _G.IsFightingBoss   = true
    _G.AutoCollectChest = false
    _G.AutoHopEnabled   = false
    SetStatus("☠️ Đang đánh Darkbeard...")

    EnableNoClip()
    AutoHaki()
    equip("Melee")

    task.spawn(function()
        local attackCD = 0
        while _G.IsFightingBoss and boss do
            AutoHaki()
            if tick() - attackCD > 2 then
                equip("Melee")
                attackCD = tick()
            end

            local bossUp = checkDarkbeard()
            if bossUp and bossUp:FindFirstChild("HumanoidRootPart") and
               bossUp:FindFirstChild("Humanoid") and bossUp.Humanoid.Health > 0 then

                local char = LocalPlayer.Character
                local hum  = char and char:FindFirstChild("Humanoid")
                local bpos = bossUp.HumanoidRootPart.Position

                if hum and hum.Health < 2000 then
                    Tween(CFrame.new(bpos.X, bpos.Y + 100, bpos.Z))
                    while hum.Health < 5000 do
                        local cb = checkDarkbeard()
                        if cb and cb:FindFirstChild("HumanoidRootPart") then
                            local p = cb.HumanoidRootPart.Position
                            Tween(CFrame.new(p.X, p.Y + 100, p.Z))
                        end
                        task.wait(0.5)
                    end
                else
                    Tween(CFrame.new(bpos.X, bpos.Y + 25, bpos.Z))
                    pcall(function()
                        if char and char:FindFirstChild("HumanoidRootPart") then
                            char.HumanoidRootPart.CFrame = CFrame.new(
                                char.HumanoidRootPart.Position,
                                Vector3.new(bpos.X, char.HumanoidRootPart.Position.Y, bpos.Z)
                            )
                        end
                    end)
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton1(Vector2.new(0, 0))
                end
            else
                _G.IsFightingBoss = false
                if hasFistOfDarkness() then
                    SetStatus("✅ Darkbeard xong, có Fist!")
                else
                    _G.AutoCollectChest = true
                    _G.AutoHopEnabled   = true
                    SetStatus("📦 Farm rương...")
                end
                break
            end
            task.wait(0.1)
        end
    end)
end

function GoToDarkbeardGate()
    local darkbeardGate = CFrame.new(3779.50708, 15.0840397, -3500.45386,
        -0.998627782, 7.57007683e-08, 0.0523698553,
         7.95809925e-08, 1, 7.20074809e-08,
        -0.0523698553, 7.60763115e-08, -0.998627782)

    _G.AutoCollectChest = false
    SafeTween(darkbeardGate, 350)
    task.wait(1)

    if checkDarkbeard() then
        FightDarkbeard()
    else
        local detector, buttonPos = findClickDetector()
        if detector then
            if buttonPos and not isPlayerCloseToButton(buttonPos) then
                teleportToButton(buttonPos)
                task.wait(1)
            end
            pcall(function() fireclickdetector(detector) end)
            task.wait(0.5)
            pcall(function() fireclickdetector(detector) end)
            task.wait(3)
            if checkDarkbeard() then
                FightDarkbeard()
            else
                _G.AutoCollectChest = true
            end
        else
            _G.AutoCollectChest = true
        end
    end
end

-- Darkbeard watcher
task.spawn(function()
    while task.wait(1) do
        if _G.AutoFightDarkbeard then
            local boss = checkDarkbeard()
            if boss and not _G.IsFightingBoss then FightDarkbeard() end
        elseif _G.FightDarkbeardOnlyWithFist and hasFistOfDarkness() then
            local boss = checkDarkbeard()
            if boss and not _G.IsFightingBoss then
                FightDarkbeard()
            elseif not _G.IsFightingBoss then
                GoToDarkbeardGate()
                task.wait(5)
            end
        end
    end
end)

-- ─────────────────────────────────────────────────
--  PROCESS FIST OF DARKNESS
-- ─────────────────────────────────────────────────
function processFistOfDarkness()
    if isCyborg() then
        _G.AutoCyborg      = false
        _G.AutoCollectChest = false
        _G.IsChestFarming  = false
        return
    end

    ForceStopChestCollection()
    SetStatus("💊 Xử lý Fist of Darkness...")

    clickDetectorForNotification()
    task.wait(2)

    if hasCoreBrain() then
        _G.HasCoreBrain  = true
        _G.NeedCoreBrain = false
        SetStatus("🧠 Tìm thấy Core Brain! Mua Cyborg...")
        equipCoreBrain()
        clickDetectorForNotification()
        task.wait(5)
        buyCyborgRace()
        if not isCyborg() then
            for i = 1, 3 do
                clickDetectorForNotification()
                task.wait(1)
                buyCyborgRace()
                task.wait(2)
                if isCyborg() then break end
            end
        end
        return
    end

    if bossExists() then
        fightBoss()
        local t = 0
        while _G.IsFightingBoss and t < 300 do
            task.wait(1); t += 1
        end
        task.wait(3)
        if hasCoreBrain() then
            _G.HasCoreBrain  = true
            _G.NeedCoreBrain = false
            equipCoreBrain()
            clickDetectorForNotification()
            task.wait(5)
            buyCyborgRace()
        else
            _G.MicrochipPurchased = false
            if not hasMicrochip() then buyMicrochip() end
            if hasMicrochip() then
                clickDetectorForNotification()
                task.wait(3)
                if bossExists() then fightBoss() end
            else
                _G.AutoCollectChest = true
                _G.IsChestFarming   = true
                SetStatus("📦 Farm rương (không spawn được Boss)...")
            end
        end
        return
    end

    -- No boss yet: use Fist to spawn
    local detector, buttonPos = findClickDetector()
    if detector then
        if buttonPos and not isPlayerCloseToButton(buttonPos) then
            teleportToButton(buttonPos)
            task.wait(1)
        end
        pcall(function() fireclickdetector(detector) end)
        task.wait(0.5)
        pcall(function() fireclickdetector(detector) end)
        task.wait(2)
    end

    if not hasMicrochip() then
        SetStatus("💊 Mua Microchip...")
        if not buyMicrochip() then
            _G.AutoCollectChest = true
            _G.IsChestFarming   = true
            SetStatus("📦 Farm rương (không mua được Microchip)...")
            return
        end
    end

    if hasMicrochip() then
        local det2, bp2 = findClickDetector()
        if det2 then
            if bp2 and not isPlayerCloseToButton(bp2) then
                teleportToButton(bp2)
                task.wait(1)
            end
            pcall(function() fireclickdetector(det2) end)
            task.wait(0.5)
            pcall(function() fireclickdetector(det2) end)
            task.wait(3)
            if bossExists() then
                fightBoss()
                local t = 0
                while _G.IsFightingBoss and t < 300 do
                    task.wait(1); t += 1
                end
                task.wait(3)
                if hasCoreBrain() then
                    _G.HasCoreBrain  = true
                    _G.NeedCoreBrain = false
                    equipCoreBrain()
                    clickDetectorForNotification()
                    task.wait(5)
                    buyCyborgRace()
                else
                    _G.AutoCollectChest = true
                    _G.IsChestFarming   = true
                    SetStatus("📦 Farm rương tiếp...")
                end
            else
                _G.AutoCollectChest = true
                _G.IsChestFarming   = true
                SetStatus("📦 Farm rương (Boss không xuất hiện)...")
            end
        end
    end
end

-- ─────────────────────────────────────────────────
--  FORCE STOP CHEST COLLECTION
-- ─────────────────────────────────────────────────
function ForceStopChestCollection()
    _G.AutoCollectChest = false
    _G.IsChestFarming   = false
    _G.starthop         = false
    _G.AutoHopEnabled   = false
    _G.StopTween        = true
    _G.StopTween2       = true
    _G.CancelTween2     = false

    task.spawn(function()
        for i = 1, 5 do
            task.wait(i * 0.2)
            _G.AutoCollectChest = false
            _G.IsChestFarming   = false
        end
    end)
end

-- ─────────────────────────────────────────────────
--  NOTIFICATION HANDLER
-- ─────────────────────────────────────────────────
function handleNotifications(message)
    if string.find(message, "Microchip not found") then
        _G.MicrochipNotFound = true
        _G.AutoCollectChest  = true
        _G.IsChestFarming    = true
        _G.IsFightingBoss    = false
        _G.StopTween         = false
        _G.StopTween2        = false
        _G.CancelTween2      = false
        SetStatus("📦 Không có Microchip, farm tiếp...")
        task.spawn(function()
            task.wait(1)
            AutoChestCollect()
        end)
        return true
    elseif string.find(message, "Core Brain") then
        _G.AutoCollectChest = false
        _G.IsChestFarming   = false
        _G.HasCoreBrain     = true
        _G.NeedCoreBrain    = false
        _G.AutoJump         = false
        SetStatus("🧠 Core Brain! Mua Cyborg...")
        StarterGui:SetCore("SendNotification", {
            Title = "Core Brain",
            Text  = "Đang tiến hành mua tộc Cyborg",
            Duration = 5
        })
        equipCoreBrain()
        clickDetectorForNotification()
        task.wait(5)
        buyCyborgRace()
        if not isCyborg() then
            clickDetectorForNotification()
            task.wait(1)
            buyCyborgRace()
        end
        return true
    end
    return false
end

-- ─────────────────────────────────────────────────
--  GUI & CHAT MONITORING
-- ─────────────────────────────────────────────────
function setupChatMonitoring()
    pcall(function()
        if ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") then
            ReplicatedStorage.DefaultChatSystemChatEvents.OnMessageDoneFiltering.OnClientEvent:Connect(function(data)
                if data.Message then
                    handleNotifications(data.Message)
                end
            end)
        end
    end)
end

function setupGUIMonitoring()
    pcall(function()
        local function checkGUI(gui)
            if (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Visible and _G.AutoCyborg then
                if gui.Text then
                    handleNotifications(gui.Text)
                end
            end
        end

        for _, gui in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
            checkGUI(gui)
        end

        LocalPlayer.PlayerGui.DescendantAdded:Connect(function(desc)
            if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                checkGUI(desc)
                pcall(function()
                    desc:GetPropertyChangedSignal("Text"):Connect(function() checkGUI(desc) end)
                    desc:GetPropertyChangedSignal("Visible"):Connect(function() checkGUI(desc) end)
                end)
            end
        end)
    end)
end

-- ─────────────────────────────────────────────────
--  AUTO CHEST COLLECT
-- ─────────────────────────────────────────────────
GetChest = function()
    local minDist = math.huge
    local nearest = nil
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local hrp = char.HumanoidRootPart
    for _, v in pairs(workspace.Map:GetDescendants()) do
        if string.find(v.Name:lower(), "chest") and v:FindFirstChild("TouchInterest") then
            local d = (v.Position - hrp.Position).Magnitude
            if d < minDist then
                minDist = d
                nearest = v
            end
        end
    end
    return nearest
end

function AutoChestCollect()
    if _G.ChestFarmingRunning then return end
    _G.ChestFarmingRunning = true

    task.spawn(function()
        while task.wait(0.1) do
            -- Priority checks
            if hasCoreBrain() then
                _G.AutoCollectChest = false
                _G.IsChestFarming   = false
                _G.starthop         = false
                _G.AutoHopEnabled   = false
                SetStatus("🧠 Core Brain! Đang mua Cyborg...")
                equipCoreBrain()
                clickDetectorForNotification()
                task.wait(5)
                buyCyborgRace()
                _G.ChestFarmingRunning = false
                return
            end

            if isCyborg() then
                ForceStopChestCollection()
                _G.AutoCyborg = false
                SetStatus("✅ Đã có Cyborg! Script dừng.")
                _G.ChestFarmingRunning = false
                return
            end

            if not _G.AutoCollectChest or _G.IsFightingBoss then
                task.wait(1)
                continue
            end

            SetStatus("📦 Farm rương...")
            local chest = GetChest()
            if chest then
                pcall(function()
                    local char = LocalPlayer.Character
                    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

                    -- Fly to chest
                    local info = TweenInfo.new(
                        (chest.Position - char.HumanoidRootPart.Position).Magnitude / TweenSpeed,
                        Enum.EasingStyle.Linear
                    )
                    local tween = TweenService:Create(char.HumanoidRootPart, info, {
                        CFrame = CFrame.new(chest.Position)
                    })
                    tween:Play()
                    if _G.StopTween2 then tween:Cancel() return end

                    tween.Completed:Wait()
                    _G.ChestCount += 1
                    _G.LastChestCollectedTime = tick()

                    -- Touch chest
                    char.HumanoidRootPart.CFrame = CFrame.new(chest.Position)
                end)
            else
                task.wait(0.5)
            end
        end
    end)
end

-- ─────────────────────────────────────────────────
--  AUTO JUMP (prevents AFK kick)
-- ─────────────────────────────────────────────────
function AutoJump()
    task.spawn(function()
        while task.wait(0.1) do
            if not _G.AutoJump then task.wait(1); continue end
            pcall(function()
                local char = LocalPlayer.Character
                if not char then return end
                local hum = char:FindFirstChild("Humanoid")
                if not hum then return end

                if hasFistOfDarkness() and not _G.FistDetected then
                    _G.FistDetected      = true
                    _G.HasFistOfDarkness = true
                    _G.AutoJump          = false
                    clickDetectorForNotification()
                    task.wait(1)
                    clickDetectorForNotification()
                elseif _G.AutoJump then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        end
    end)
end

AutoJump()

-- ─────────────────────────────────────────────────
--  ANTI-KICK
-- ─────────────────────────────────────────────────
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local hrp = char.HumanoidRootPart
            -- Billboard tag
            local existing = hrp:FindFirstChild("EspBillboard")
            if not existing then
                local bb = Instance.new("BillboardGui", hrp)
                bb.Name = "EspBillboard"
                bb.ExtentsOffset = Vector3.new(0, 1, 0)
                bb.Size = UDim2.new(1, 300, 1, 50)
                bb.AlwaysOnTop = true
                local lbl = Instance.new("TextLabel", bb)
                lbl.Font = Enum.Font.Code
                lbl.TextSize = 14
                lbl.Size = UDim2.new(1, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.TextStrokeTransparency = 0.5
                lbl.TextColor3 = Color3.fromRGB(80, 245, 245)
                lbl.Text = "taphoamizu"
            end
            -- Micro movement to avoid kick
            if hrp.Velocity.Magnitude < 0.1 then
                hrp.CFrame = hrp.CFrame + Vector3.new(0, 0, 0.01)
            end
        end)
    end
end)

-- ─────────────────────────────────────────────────
--  STUN PREVENTION
-- ─────────────────────────────────────────────────
task.spawn(function()
    while task.wait() do
        pcall(function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Stun") then
                char.Stun.Value = 0
            end
        end)
    end
end)

-- ─────────────────────────────────────────────────
--  ABILITY ACTIVATION (Ken/T/Y/V3/V4)
-- ─────────────────────────────────────────────────
task.spawn(function()
    while task.wait() do
        if _G.IsFightingBoss or _G.IsFightingCyborgBoss then
            pcall(function()
                ReplicatedStorage.Remotes.CommE:FireServer("Ken", true)
                ReplicatedStorage.Remotes.CommE:FireServer("ActivateAbility")
                VirtualInputManager:SendKeyEvent(true, "Y", false, game)
                task.wait()
                VirtualInputManager:SendKeyEvent(false, "Y", false, game)

                if ReplicatedStorage.Remotes.CommF_:InvokeServer("AwakeningChanger", "Check") == true then
                    ReplicatedStorage.Remotes.CommF_:InvokeServer("AwakeningChanger", "Awaken")
                end

                for _, v in pairs(LocalPlayer.Backpack:GetChildren()) do
                    if v:IsA("Tool") and v.ToolTip == "Melee" then
                        LocalPlayer.Character.Humanoid:EquipTool(v)
                        break
                    end
                end

                if not LocalPlayer.Character:FindFirstChild("RaceTransformed") then
                    VirtualInputManager:SendKeyEvent(true, "E", false, game)
                    task.wait(0.1)
                    VirtualInputManager:SendKeyEvent(false, "E", false, game)
                end
            end)
        end
    end
end)

-- ─────────────────────────────────────────────────
--  EXTRA NOCLIP FOR BOSS FIGHTS
-- ─────────────────────────────────────────────────
task.spawn(function()
    while task.wait() do
        if _G.IsFightingBoss or _G.IsFightingCyborgBoss then
            pcall(function()
                local char = LocalPlayer.Character
                if not char then return end
                for _, p in pairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
                local hum = char:FindFirstChild("Humanoid")
                if hum then
                    hum:ChangeState(11)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                end
            end)
        end
    end
end)

-- ─────────────────────────────────────────────────
--  AUTO REJOIN
-- ─────────────────────────────────────────────────
task.spawn(function()
    while task.wait() do
        if _G.AutoRejoin then
            pcall(function()
                getgenv().rejoin = game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
                    if child.Name == "ErrorPrompt" and child:FindFirstChild("MessageArea") and
                       child.MessageArea:FindFirstChild("ErrorFrame") then
                        HopServer()
                    end
                end)
            end)
        end
    end
end)

-- ─────────────────────────────────────────────────
--  SERVER HOP (tìm server 4h±15p, 8h±15p, 12h±15p...)
-- ─────────────────────────────────────────────────
function HopServer()
    if not _G.AutoHopEnabled then return end

    -- Kiểm tra server hiện tại trước
    local uptime = workspace.DistributedGameTime
    local TARGET_HOURS = {4, 8, 12, 16, 20, 24}
    local MARGIN = 900 -- ±15 phút

    local function inTarget(t)
        for _, h in ipairs(TARGET_HOURS) do
            if math.abs(t - h*3600) <= MARGIN then return true end
        end
        return false
    end

    if inTarget(uptime) then
        SetStatus("✅ Server đúng target: " .. math.floor(uptime/3600) .. "h " .. math.floor((uptime%3600)/60) .. "m")
        return
    end

    SetStatus("🔀 Tìm server " .. table.concat(TARGET_HOURS, "h/") .. "h ±15p...")

    local PlaceID = game.PlaceId
    local JobID = game.JobId
    local HS = game:GetService("HttpService")
    local TeleportRemote = game:GetService("ReplicatedStorage"):WaitForChild("__ServerBrowser")
    local foundAnything = ""

    local function GetServerList()
        local url = "https://games.roblox.com/v1/games/"..PlaceID.."/servers/Public?sortOrder=Asc&limit=100"
        if foundAnything ~= "" then url = url.."&cursor="..foundAnything end
        local ok, result = pcall(function()
            return HS:JSONDecode(game:HttpGet(url))
        end)
        if ok and result and result.data then return result end
        return nil
    end

    pcall(function()
        while _G.AutoHopEnabled do
            local Site = GetServerList()
            if not Site then task.wait(5); continue end

            if Site.nextPageCursor and Site.nextPageCursor ~= "null" then
                foundAnything = Site.nextPageCursor
            else
                foundAnything = ""
            end

            for _, v in ipairs(Site.data) do
                local serverId = tostring(v.id)
                local playing = tonumber(v.playing)
                local maxPlayers = tonumber(v.maxPlayers)
                if playing < maxPlayers and serverId ~= JobID then
                    pcall(function()
                        TeleportRemote:InvokeServer("teleport", serverId)
                    end)
                    task.wait(0.5)
                end
            end

            task.wait(1)
        end
    end)
end

-- ─────────────────────────────────────────────────
--  CHECK FOR SPECIAL ITEMS LOOP (15 min server limit)
-- ─────────────────────────────────────────────────
local function CheckForSpecialItems()
    local startTime = tick()
    local TIME_LIMIT = 15 * 60

    task.spawn(function()
        while task.wait(1) do
            local now = tick()
            local player = LocalPlayer

            if hasCoreBrain() then
                _G.HasCoreBrain  = true
                _G.NeedCoreBrain = false
                _G.AutoJump      = false
                SetStatus("🧠 Core Brain! Mua Cyborg...")
                equipCoreBrain()
                clickDetectorForNotification()
                task.wait(5)
                buyCyborgRace()
                startTime = tick()
            elseif hasFistOfDarkness() and not _G.FistDetected then
                _G.FistDetected      = true
                _G.HasFistOfDarkness = true
                _G.AutoJump          = false
                clickDetectorForNotification()
                task.wait(1)
                clickDetectorForNotification()
                startTime = tick()
            elseif (now - startTime) > TIME_LIMIT then
                HopServer()
                startTime = tick()
                _G.ServerStartTime = tick()
            end

            -- Key check
            if workspace:FindFirstChild("Key") and not _G.KeyDetected then
                _G.KeyDetected = true
                _G.AutoJump    = false
                clickDetectorForNotification()
                task.wait(1)
                clickDetectorForNotification()
            end
        end
    end)
end

-- ─────────────────────────────────────────────────
--  CORE BRAIN DETECTION SETUP
-- ─────────────────────────────────────────────────
function setupCoreBrainDetection()
    setupChatMonitoring()

    pcall(function()
        workspace.ChildAdded:Connect(function(child)
            if child.Name == "Key" then
                _G.KeyDetected = true
                _G.AutoJump    = false
                clickDetectorForNotification()
                task.wait(1)
                clickDetectorForNotification()
            end
        end)
    end)

    pcall(function()
        LocalPlayer.Backpack.ChildAdded:Connect(function(item)
            if item.Name == "Fist of Darkness" and not _G.FistDetected then
                _G.FistDetected      = true
                _G.HasFistOfDarkness = true
                _G.AutoJump          = false
                clickDetectorForNotification()
                task.wait(1)
                clickDetectorForNotification()
            end
        end)
    end)

    pcall(function()
        if LocalPlayer.Character then
            LocalPlayer.Character.ChildAdded:Connect(function(item)
                if item.Name == "Fist of Darkness" and not _G.FistDetected then
                    _G.FistDetected      = true
                    _G.HasFistOfDarkness = true
                    _G.AutoJump          = false
                    clickDetectorForNotification()
                    task.wait(1)
                    clickDetectorForNotification()
                end
            end)
        end
    end)

    LocalPlayer.CharacterAdded:Connect(function(char)
        pcall(function()
            char.ChildAdded:Connect(function(item)
                if item.Name == "Fist of Darkness" and not _G.FistDetected then
                    _G.FistDetected      = true
                    _G.HasFistOfDarkness = true
                    _G.AutoJump          = false
                    clickDetectorForNotification()
                    task.wait(1)
                    clickDetectorForNotification()
                end
            end)
        end)
    end)
end

-- ─────────────────────────────────────────────────
--  CHARACTER DEATH HANDLER
-- ─────────────────────────────────────────────────
pcall(function()
    LocalPlayer.CharacterAdded:Connect(function()
        if _G.IsFightingBoss then
            task.wait(3)
            if bossExists() then
                fightBoss()
            else
                _G.IsFightingBoss = false
                if not isCyborg() and _G.AutoCyborg then
                    if hasCoreBrain() then
                        _G.HasCoreBrain  = true
                        _G.NeedCoreBrain = false
                        equipCoreBrain()
                        clickDetectorForNotification()
                        task.wait(5)
                        buyCyborgRace()
                    end
                end
            end
        end
        task.wait(1)
        if hasFistOfDarkness() and not _G.FistDetected then
            _G.FistDetected      = true
            _G.HasFistOfDarkness = true
            _G.AutoJump          = false
            clickDetectorForNotification()
            task.wait(1)
            clickDetectorForNotification()
        end
    end)
end)

-- ─────────────────────────────────────────────────
--  RACE CHANGE DETECTION
-- ─────────────────────────────────────────────────
pcall(function()
    LocalPlayer.Data.Race.Changed:Connect(function()
        if LocalPlayer.Data.Race.Value == "Cyborg" then
            _G.AutoCyborg      = false
            _G.AutoCollectChest = false
            _G.IsChestFarming  = false
            _G.IsFightingBoss  = false
            _G.AutoJump        = false
            SetStatus("✅ ĐÃ CÓ CYBORG RACE!")
            StarterGui:SetCore("SendNotification", {
                Title = "Auto Cyborg",
                Text  = "Đã nhận thành công tộc Cyborg!",
                Duration = 10
            })
        end
    end)
end)

-- ─────────────────────────────────────────────────
--  MAIN CYCLE
-- ─────────────────────────────────────────────────
local function mainCycle()
    if isCyborg() then
        ForceStopChestCollection()
        _G.AutoCyborg = false
        SetStatus("✅ Đã có Cyborg! Script dừng.")
        StarterGui:SetCore("SendNotification", {
            Title = "Auto Cyborg",
            Text  = "Bạn đã có tộc Cyborg! Script đã dừng.",
            Duration = 10
        })
        return
    end

    if hasCoreBrain() then
        ForceStopChestCollection()
        _G.HasCoreBrain  = true
        _G.NeedCoreBrain = false
        SetStatus("🧠 Core Brain! Đang mua Cyborg...")
        StarterGui:SetCore("SendNotification", {
            Title = "Core Brain",
            Text  = "Đang mua tộc Cyborg...",
            Duration = 5
        })
        equipCoreBrain()
        clickDetectorForNotification()
        task.wait(5)
        buyCyborgRace()
        if not isCyborg() then
            for i = 1, 3 do
                clickDetectorForNotification()
                task.wait(1)
                buyCyborgRace()
                task.wait(2)
                if isCyborg() then break end
            end
        end
        return
    end

    if hasFistOfDarkness() then
        SetStatus("🗡️ Có Fist! Xử lý...")
        task.spawn(processFistOfDarkness)
        return
    end

    -- Default: farm chest
    SetStatus("📦 Farm rương để tìm Fist of Darkness...")
    StarterGui:SetCore("SendNotification", {
        Title = "Auto Chest",
        Text  = "Bắt đầu farm rương để tìm Fist of Darkness...",
        Duration = 5
    })
    _G.AutoCollectChest = true
    _G.IsChestFarming   = true

    -- Continuous monitor loop
    task.spawn(function()
        while _G.AutoCyborg ~= false do
            task.wait(2)
            pcall(function()
                if isCyborg() then
                    ForceStopChestCollection()
                    _G.AutoCyborg = false
                    SetStatus("✅ ĐÃ CÓ CYBORG!")
                    return
                end

                if hasFistOfDarkness() and not _G.FistDetected then
                    ForceStopChestCollection()
                    _G.FistDetected      = true
                    _G.HasFistOfDarkness = true
                    _G.AutoJump          = false
                    clickDetectorForNotification()
                    task.wait(1)
                    if not hasMicrochip() then
                        for _ = 1, 3 do
                            buyMicrochip()
                            task.wait(1)
                            if hasMicrochip() then break end
                        end
                    end
                    if hasMicrochip() then clickToSpawnBoss() end
                end

                if hasCoreBrain() and not isCyborg() then
                    ForceStopChestCollection()
                    _G.HasCoreBrain  = true
                    _G.NeedCoreBrain = false
                    SetStatus("🧠 Core Brain! Mua Cyborg...")
                    equipCoreBrain()
                    clickDetectorForNotification()
                    task.wait(5)
                    buyCyborgRace()
                    if not isCyborg() then
                        for _ = 1, 3 do
                            clickDetectorForNotification()
                            task.wait(1)
                            buyCyborgRace()
                            task.wait(2)
                            if isCyborg() then break end
                        end
                    end
                end

                -- Key detection
                local key = workspace:FindFirstChild("Key")
                if key and not _G.KeyDetected then
                    _G.KeyDetected = true
                    _G.AutoJump    = false
                    clickDetectorForNotification()
                    task.wait(1)
                    clickDetectorForNotification()
                end

                if bossExists() and not _G.IsFightingBoss then
                    fightBoss()
                end
            end)
        end
    end)
end

-- ─────────────────────────────────────────────────
--  STARTUP INITIALIZATION
-- ─────────────────────────────────────────────────
task.spawn(function()
    task.wait(5)
    setupChatMonitoring()
    setupGUIMonitoring()
    if _G.AutoCollectChest then
        AutoChestCollect()
    end
end)

AutoChestCollect()
CheckForSpecialItems()
setupCoreBrainDetection()

task.spawn(function()
    task.wait(10)

    if isCyborg() then
        _G.AutoCyborg = false
        SetStatus("✅ Đã có Cyborg! Script dừng.")
        StarterGui:SetCore("SendNotification", {
            Title = "Auto Cyborg",
            Text  = "Bạn đã có tộc Cyborg!",
            Duration = 10
        })
        return
    end

    mainCycle()

    if hasFistOfDarkness() then
        _G.FistDetected      = true
        _G.HasFistOfDarkness = true
        _G.AutoJump          = false
        clickDetectorForNotification()
        task.wait(1)
        clickDetectorForNotification()
    end
end)

-- ─────────────────────────────────────────────────
--  SCRIPT STARTED NOTIFICATION
-- ─────────────────────────────────────────────────
SetStatus("🚀 Script khởi động thành công!")
StarterGui:SetCore("SendNotification", {
    Title    = "Auto Cyborg Script v4.0",
    Text     = "Script khởi động thành công! UI trạng thái đã hiện.",
    Duration = 8
})

-- END
