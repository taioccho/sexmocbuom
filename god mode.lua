-- God Mode Script - Blox Fruits
-- GUI có thể kéo được, có nút On/Off

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- ========================================
-- BIẾN CHÍNH
-- ========================================
local godModeEnabled = false
local godModeConnection = nil
local characterAddedConnection = nil
local loopHealConnection = nil
local antiVoidConnection = nil

-- ========================================
-- TẠO GUI
-- ========================================
if LocalPlayer.PlayerGui:FindFirstChild("GodModeGui") then
    LocalPlayer.PlayerGui.GodModeGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GodModeGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer.PlayerGui

-- ========================================
-- NÚT MỞ MENU (khi menu đóng)
-- ========================================
local OpenButton = Instance.new("TextButton")
OpenButton.Name = "OpenButton"
OpenButton.Size = UDim2.new(0, 100, 0, 40)
OpenButton.Position = UDim2.new(0, 10, 0.5, -20)
OpenButton.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
OpenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenButton.Text = "☰ Menu"
OpenButton.TextSize = 16
OpenButton.Font = Enum.Font.GothamBold
OpenButton.Parent = ScreenGui
OpenButton.Visible = false
OpenButton.ZIndex = 10

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(0, 8)
openCorner.Parent = OpenButton

local openStroke = Instance.new("UIStroke")
openStroke.Color = Color3.fromRGB(255, 170, 0)
openStroke.Thickness = 2
openStroke.Parent = OpenButton

-- Kéo được nút Open
local draggingOpen = false
local dragStartOpen, startPosOpen

OpenButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingOpen = true
        dragStartOpen = input.Position
        startPosOpen = OpenButton.Position
    end
end)

OpenButton.InputChanged:Connect(function(input)
    if draggingOpen and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStartOpen
        OpenButton.Position = UDim2.new(startPosOpen.X.Scale, startPosOpen.X.Offset + delta.X, startPosOpen.Y.Scale, startPosOpen.Y.Offset + delta.Y)
    end
end)

OpenButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingOpen = false
    end
end)

-- ========================================
-- MENU CHÍNH
-- ========================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 270, 0, 320)
MainFrame.Position = UDim2.new(0.5, -135, 0.5, -160)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BackgroundTransparency = 0.05
MainFrame.Parent = ScreenGui
MainFrame.Visible = true
MainFrame.ZIndex = 5

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = MainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(255, 170, 0)
mainStroke.Thickness = 2
mainStroke.Parent = MainFrame

-- ========================================
-- THANH TIÊU ĐỀ (KÉO ĐƯỢC)
-- ========================================
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 38)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 20, 0)
TitleBar.Parent = MainFrame
TitleBar.ZIndex = 6

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(0.75, 0, 1, 0)
TitleText.Position = UDim2.new(0, 12, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "⚔️ God Mode - Blox Fruits"
TitleText.TextColor3 = Color3.fromRGB(255, 200, 0)
TitleText.TextSize = 14
TitleText.Font = Enum.Font.GothamBold
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar
TitleText.ZIndex = 7

-- Nút đóng menu (X)
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -35, 0, 4)
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Text = "X"
CloseButton.TextSize = 14
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = TitleBar
CloseButton.ZIndex = 7

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = CloseButton

-- Kéo menu
local dragging = false
local dragStart, startPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ========================================
-- NỘI DUNG MENU
-- ========================================
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -20, 1, -55)
ContentFrame.Position = UDim2.new(0, 10, 0, 45)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame
ContentFrame.ZIndex = 6

-- Trạng thái God Mode
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 25)
StatusLabel.Position = UDim2.new(0, 0, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Trạng Thái: TẮT"
StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
StatusLabel.TextSize = 15
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.Parent = ContentFrame
StatusLabel.ZIndex = 7

-- Mô tả
local DescLabel = Instance.new("TextLabel")
DescLabel.Size = UDim2.new(1, 0, 0, 30)
DescLabel.Position = UDim2.new(0, 0, 0, 26)
DescLabel.BackgroundTransparency = 1
DescLabel.Text = "Bất tử - Không chết bởi NPC/Boss/Player"
DescLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
DescLabel.TextSize = 11
DescLabel.Font = Enum.Font.Gotham
DescLabel.TextWrapped = true
DescLabel.Parent = ContentFrame
DescLabel.ZIndex = 7

-- Nút God Mode ON
local GodOnButton = Instance.new("TextButton")
GodOnButton.Size = UDim2.new(1, 0, 0, 45)
GodOnButton.Position = UDim2.new(0, 0, 0, 62)
GodOnButton.BackgroundColor3 = Color3.fromRGB(0, 130, 0)
GodOnButton.TextColor3 = Color3.fromRGB(255, 255, 255)
GodOnButton.Text = "🛡️ BẬT GOD MODE"
GodOnButton.TextSize = 16
GodOnButton.Font = Enum.Font.GothamBold
GodOnButton.Parent = ContentFrame
GodOnButton.ZIndex = 7

local godOnCorner = Instance.new("UICorner")
godOnCorner.CornerRadius = UDim.new(0, 8)
godOnCorner.Parent = GodOnButton

-- Nút God Mode OFF
local GodOffButton = Instance.new("TextButton")
GodOffButton.Size = UDim2.new(1, 0, 0, 45)
GodOffButton.Position = UDim2.new(0, 0, 0, 117)
GodOffButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
GodOffButton.TextColor3 = Color3.fromRGB(255, 255, 255)
GodOffButton.Text = "💀 TẮT GOD MODE"
GodOffButton.TextSize = 16
GodOffButton.Font = Enum.Font.GothamBold
GodOffButton.Parent = ContentFrame
GodOffButton.ZIndex = 7

local godOffCorner = Instance.new("UICorner")
godOffCorner.CornerRadius = UDim.new(0, 8)
godOffCorner.Parent = GodOffButton

-- Separator
local Separator = Instance.new("Frame")
Separator.Size = UDim2.new(1, 0, 0, 1)
Separator.Position = UDim2.new(0, 0, 0, 172)
Separator.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
Separator.Parent = ContentFrame
Separator.ZIndex = 7

-- Thông tin thêm
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, 0, 0, 80)
InfoLabel.Position = UDim2.new(0, 0, 0, 180)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "💡 Tính năng:\n• Máu luôn đầy (Infinite Health)\n• Chống rơi void (Anti Void)\n• Tự heal khi bị damage\n• Hoạt động khi respawn"
InfoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
InfoLabel.TextSize = 11
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.TextWrapped = true
InfoLabel.TextYAlignment = Enum.TextYAlignment.Top
InfoLabel.Parent = ContentFrame
InfoLabel.ZIndex = 7

-- ========================================
-- CHỨC NĂNG GOD MODE CHO BLOX FRUITS
-- ========================================
local function applyGodMode(character)
    if not character then return end
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then return end
    
    -- Ngắt connection cũ
    if godModeConnection then
        godModeConnection:Disconnect()
        godModeConnection = nil
    end
    if loopHealConnection then
        loopHealConnection:Disconnect()
        loopHealConnection = nil
    end
    if antiVoidConnection then
        antiVoidConnection:Disconnect()
        antiVoidConnection = nil
    end
    
    -- Cách 1: Set max health
    humanoid.MaxHealth = math.huge
    humanoid.Health = math.huge
    
    -- Cách 2: Heal khi bị damage
    godModeConnection = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if godModeEnabled then
            humanoid.Health = humanoid.MaxHealth
        end
    end)
    
    -- Cách 3: Loop heal liên tục
    loopHealConnection = RunService.Heartbeat:Connect(function()
        if godModeEnabled then
            if humanoid and humanoid.Parent then
                humanoid.Health = humanoid.MaxHealth
            end
        end
    end)
    
    -- Anti Void (chống rơi xuống map)
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    if hrp then
        antiVoidConnection = RunService.Heartbeat:Connect(function()
            if godModeEnabled and hrp and hrp.Parent then
                if hrp.Position.Y < -200 then
                    hrp.CFrame = CFrame.new(hrp.Position.X, 100, hrp.Position.Z)
                    hrp.Velocity = Vector3.new(0, 0, 0)
                end
            end
        end)
    end
    
    -- Hook Death function (Blox Fruits specific)
    pcall(function()
        local deathModule = ReplicatedStorage:FindFirstChild("Effect")
        if deathModule then
            local container = deathModule:FindFirstChild("Container")
            if container then
                local death = container:FindFirstChild("Death")
                if death then
                    hookfunction(require(death), function() end)
                end
            end
        end
    end)
    
    -- Fire server heal (nếu game hỗ trợ)
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local commF = remotes:FindFirstChild("CommF_")
            if commF then
                -- Blox Fruits heal method
                commF:InvokeServer("Heal")
            end
        end
    end)
end

local function enableGodMode()
    godModeEnabled = true
    StatusLabel.Text = "Trạng Thái: BẬT 🛡️"
    StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    GodOnButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    
    -- Áp dụng cho nhân vật hiện tại
    local character = LocalPlayer.Character
    if character then
        applyGodMode(character)
    end
    
    -- Áp dụng khi respawn
    if characterAddedConnection then
        characterAddedConnection:Disconnect()
    end
    characterAddedConnection = LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(1.5)
        if godModeEnabled then
            applyGodMode(char)
        end
    end)
end

local function disableGodMode()
    godModeEnabled = false
    StatusLabel.Text = "Trạng Thái: TẮT 💀"
    StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    GodOnButton.BackgroundColor3 = Color3.fromRGB(0, 130, 0)
    
    -- Ngắt tất cả connection
    if godModeConnection then
        godModeConnection:Disconnect()
        godModeConnection = nil
    end
    if loopHealConnection then
        loopHealConnection:Disconnect()
        loopHealConnection = nil
    end
    if antiVoidConnection then
        antiVoidConnection:Disconnect()
        antiVoidConnection = nil
    end
    if characterAddedConnection then
        characterAddedConnection:Disconnect()
        characterAddedConnection = nil
    end
    
    -- Reset health về bình thường
    pcall(function()
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.MaxHealth = 100
                humanoid.Health = 100
            end
        end
    end)
end

-- ========================================
-- SỰ KIỆN NÚT
-- ========================================
GodOnButton.MouseButton1Click:Connect(function()
    enableGodMode()
end)

GodOffButton.MouseButton1Click:Connect(function()
    disableGodMode()
end)

-- Đóng menu
CloseButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    OpenButton.Visible = true
end)

-- Mở menu
OpenButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    OpenButton.Visible = false
end)

-- ========================================
-- HIỆU ỨNG VIỀN CẦU VỒNG
-- ========================================
task.spawn(function()
    local hue = 0
    while true do
        hue = (hue + 1) % 360
        local color = Color3.fromHSV(hue / 360, 1, 1)
        mainStroke.Color = color
        openStroke.Color = color
        task.wait(0.03)
    end
end)

-- ========================================
-- THÔNG BÁO
-- ========================================
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "⚔️ God Mode - Blox Fruits",
        Text = "Đã tải thành công! Bấm BẬT để bất tử.",
        Duration = 5
    })
end)

print("✅ God Mode Script - Blox Fruits đã tải thành công!")
