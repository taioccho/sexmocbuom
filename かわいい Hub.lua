local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local MAX_DISTANCE = 1500
local localPlayer = Players.LocalPlayer

-- ── PLACE ID CHECK ──────────────────────────────────────────────────────────
local REQUIRED_PLACE_ID = 78724049937437
if game.PlaceId ~= REQUIRED_PLACE_ID then
    -- Thông báo game không được hỗ trợ
    local StarterGui = game:GetService("StarterGui")
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "かわいい Hub",
            Text = "Not support this game.",
            Duration = 5,
        })
    end)
    -- Dùng Fluent notify nếu có
    return
end

-- ── SCRIPT URL (dùng cho Auto Execute) ─────────────────────────────────────
local SCRIPT_URL = "https://raw.githubusercontent.com/taioccho/sexmocbuom/main/かわいい Hub.lua" -- thay bằng URL raw script của bạn

-- queueAutoExecute đã được thay bằng queue ngay khi load (xem bên dưới phần config)
-- Các nút Hop/Rejoin không cần gọi lại vì queue_on_teleport chỉ cần set 1 lần
local function queueAutoExecute() end -- giữ để tương thích, không làm gì nữa
game:GetService("Players").LocalPlayer.Idled:connect(function()
    game:GetService("VirtualUser"):Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    wait()
    game:GetService("VirtualUser"):Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

-- ── CONFIG SAVE / LOAD ──────────────────────────────────────────────────────
local CONFIG_FOLDER = "かわいい Hub"
local CONFIG_FILE   = CONFIG_FOLDER .. "/" .. localPlayer.Name .. ".json"

local function loadConfig()
    local ok, data = pcall(function()
        if isfolder and isfile and isfolder(CONFIG_FOLDER) and isfile(CONFIG_FILE) then
            return game:GetService("HttpService"):JSONDecode(readfile(CONFIG_FILE))
        end
    end)
    return (ok and type(data) == "table") and data or {}
end

local function saveConfig()
    pcall(function()
        if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
        writefile(CONFIG_FILE, game:GetService("HttpService"):JSONEncode({
            AutoSeeker    = _G.AutoSeeker,
            AutoHide      = _G.AutoHide,
            AutoTaunt     = _G.AutoTaunt,
            Noclip        = _G.Noclip,
            ESP           = _G.ESP,
            WalkSpeed     = _G.WalkSpeed,
            InfinityJump  = _G.InfinityJump,
            Fly           = _G.Fly,
            FlySpeed      = _G.FlySpeed,
            AutoExecute   = _G.AutoExecute,
        }))
    end)
end

local _savedCfg = loadConfig()

-- CẤU HÌNH BAN ĐẦU
_G.AutoSeeker = _G.AutoSeeker or (_savedCfg.AutoSeeker ~= nil and _savedCfg.AutoSeeker or false)
_G.AutoHide   = _G.AutoHide   or (_savedCfg.AutoHide   ~= nil and _savedCfg.AutoHide   or false)
_G.AutoTaunt  = _G.AutoTaunt  or (_savedCfg.AutoTaunt  ~= nil and _savedCfg.AutoTaunt  or false)
_G.Noclip     = _G.Noclip     or (_savedCfg.Noclip     ~= nil and _savedCfg.Noclip     or false)
_G.ESP        = _savedCfg.ESP        ~= nil and _savedCfg.ESP        or true  -- default true nếu chưa có config
_G.AutoExecute = _savedCfg.AutoExecute ~= nil and _savedCfg.AutoExecute or false
_G.FlySpeed   = _savedCfg.FlySpeed ~= nil and _savedCfg.FlySpeed or 65
_G.AttackRange = 7
_G.WalkSpeed  = _G.WalkSpeed  or (_savedCfg.WalkSpeed  ~= nil and _savedCfg.WalkSpeed  or 16)
_G.InfinityJump = _savedCfg.InfinityJump ~= nil and _savedCfg.InfinityJump or false
_G.Fly          = _savedCfg.Fly          ~= nil and _savedCfg.Fly          or false

-- ── AUTO EXECUTE KHI LOAD (queue ngay nếu toggle bật, bắt cả hop thủ công) ─
-- Chỉ queue 1 lần khi script khởi động. Khi player hop/rejoin bằng bất kỳ cách nào
-- (thủ công hoặc qua nút), queue_on_teleport sẽ tự chạy script ở server mới.
pcall(function()
    if _G.AutoExecute and queue_on_teleport then
        queue_on_teleport(('loadstring(game:HttpGet("%s"))()'):format(SCRIPT_URL))
    end
end)

-- CẤU HÌNH VỊ TRÍ TRỐN (AUTO HIDE POSITION)
local HIDE_POSITION = Vector3.new(407.31, 37.10, -75.39)

-- CẤU HÌNH VÙNG ĐẢO BỊ BỎ QUA (SAFE ZONE) - Không bay tới / không tự động tấn công player ở đây
-- Sử dụng tọa độ vùng cấm mở rộng do người dùng cung cấp (không check chiều cao Y)
local SAFE_ZONE_MIN = Vector3.new(312.91, 0, -182.18)
local SAFE_ZONE_MAX = Vector3.new(543.09, 0, -11.09)

local function isInsideSafeZone(pos)
    return (pos.X >= SAFE_ZONE_MIN.X and pos.X <= SAFE_ZONE_MAX.X) and
           (pos.Z >= SAFE_ZONE_MIN.Z and pos.Z <= SAFE_ZONE_MAX.Z)
end

local function clickTauntButton()
    local playerGui = localPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    
    for _, obj in ipairs(playerGui:GetDescendants()) do
        if (obj:IsA("TextButton") or obj:IsA("ImageButton")) and obj.Visible then
            local nameLower = obj.Name:lower()
            local isTaunt = nameLower:find("taunt")
            if not isTaunt then
                if obj:IsA("TextButton") and obj.Text:lower():find("taunt") then
                    isTaunt = true
                else
                    for _, child in ipairs(obj:GetDescendants()) do
                        if child:IsA("TextLabel") and child.Text:lower():find("taunt") then
                            isTaunt = true
                            break
                        end
                    end
                end
            end
            
            if isTaunt then
                pcall(function()
                    -- Kích hoạt tất cả các kết nối sự kiện (cả MouseButton1Click và Activated)
                    if getconnections then
                        for _, event in ipairs({obj.MouseButton1Click, obj.Activated}) do
                            if event then
                                for _, conn in ipairs(getconnections(event)) do
                                    conn:Fire()
                                end
                            end
                        end
                    end
                    -- Giả lập nhấp chuột vật lý dự phòng
                    local pos = obj.AbsolutePosition
                    local size = obj.AbsoluteSize
                    local clickX = pos.X + size.X / 2
                    local clickY = pos.Y + size.Y / 2
                    local vim = game:GetService("VirtualInputManager")
                    vim:SendMouseButtonEvent(clickX, clickY, 0, true, game, 1)
                    task.wait(0.01)
                    vim:SendMouseButtonEvent(clickX, clickY, 0, false, game, 1)
                end)
                return true
            end
        end
    end
    return false
end

local isFlying = false
local isFlyActive = false       -- Fly (Settings tab) riêng với isFlying (auto seeker/hide)
local flyConnection = nil
local jumpConnection = nil
local lastCapturedPos = nil
local lastWanderTarget = nil
local nextWanderTime = 0
local lastRole = nil
local roleChangedTime = 0
local lastTauntTime = 0
local nearestHider = nil
local lastAttack = 0
local ATTACK_COOLDOWN = 0.03

-- ── FLY & INFINITY JUMP LOGIC ───────────────────────────────────────────────
local UserInputService = game:GetService("UserInputService")

local function stopFly()
    isFlyActive = false
    if flyConnection then flyConnection:Disconnect() flyConnection = nil end
    local char = localPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hrp then
        local bv = hrp:FindFirstChild("FlyBodyVelocity")
        if bv then bv:Destroy() end
        local bg = hrp:FindFirstChild("FlyBodyGyro")
        if bg then bg:Destroy() end
    end
    if hum then hum.PlatformStand = false end
end

local function startFly()
    stopFly()
    isFlyActive = true
    local char = localPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    hum.PlatformStand = true

    local bv = Instance.new("BodyVelocity")
    bv.Name = "FlyBodyVelocity"
    bv.Velocity = Vector3.zero
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Parent = hrp

    local bg = Instance.new("BodyGyro")
    bg.Name = "FlyBodyGyro"
    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.P = 9e4
    bg.CFrame = hrp.CFrame
    bg.Parent = hrp

    flyConnection = RunService.Heartbeat:Connect(function()
        if not _G.Fly or not isFlyActive then stopFly() return end
        local c = localPlayer.Character
        local r = c and c:FindFirstChild("HumanoidRootPart")
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if not r or not h then stopFly() return end

        local cam   = workspace.CurrentCamera
        local speed = _G.FlySpeed or 65

        -- MoveDirection hoạt động cả PC lẫn mobile joystick
        local moveDir = h.MoveDirection
        local dir = Vector3.zero

        if moveDir.Magnitude > 0.1 then
            -- Project MoveDirection lên mặt phẳng ngang của camera
            local camFlat = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z).Unit
            local camRight = Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z).Unit
            local worldMove = moveDir
            local forward = camFlat * -worldMove.Z + camRight * worldMove.X
            dir = dir + forward
        end

        -- Lên/xuống: Space và LeftShift (PC), hoặc Jump button (mobile = Space)
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            dir = dir + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            dir = dir - Vector3.new(0, 1, 0)
        end

        local flyBv = r:FindFirstChild("FlyBodyVelocity")
        local flyBg = r:FindFirstChild("FlyBodyGyro")
        if flyBv then
            flyBv.Velocity = dir.Magnitude > 0.01 and dir.Unit * speed or Vector3.zero
        end
        if flyBg then
            flyBg.CFrame = cam.CFrame
        end
    end)
end

local function stopInfinityJump()
    if jumpConnection then jumpConnection:Disconnect() jumpConnection = nil end
end

local function startInfinityJump()
    stopInfinityJump()
    jumpConnection = UserInputService.JumpRequest:Connect(function()
        if not _G.InfinityJump then stopInfinityJump() return end
        local char = localPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

-- Áp dụng state từ config ngay khi load
if _G.InfinityJump then startInfinityJump() end
if _G.Fly then startFly() end

-- 1. DỌN DẸP ESP VÀ GUI CŨ NẾU CHẠY LẠI SCRIPT
local oldHolder = CoreGui:FindFirstChild("ESP_Holder")
if oldHolder then oldHolder:Destroy() end

local oldGui = CoreGui:FindFirstChild("SoiHelperGui")
if oldGui then oldGui:Destroy() end

if _G.SoiNoclipConnection then
    _G.SoiNoclipConnection:Disconnect()
    _G.SoiNoclipConnection = nil
end

local ESP_Holder = Instance.new("Folder")
ESP_Holder.Name = "ESP_Holder"

-- Đính kèm vào gethui() để tăng bảo mật, nếu không có thì dùng CoreGui
local success, parent = pcall(function() return gethui() end)
if not success or not parent then
    parent = CoreGui
end
ESP_Holder.Parent = parent

-- 2. HÀM TẠO/CẬP NHẬT ESP
local function createESP(player, character, distance, health, maxHealth, isSeeker)
    local head = character:FindFirstChild("Head")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not head or not hrp then return end

    local color, role
    if isSeeker == true then
        color = Color3.new(1, 0.1, 0.1)
        role = "Seeker"
    elseif isSeeker == false then
        color = Color3.new(0.1, 1, 0.3)
        role = "Hider"
    else
        color = Color3.new(1, 1, 0.3)
        role = "?"
    end

    -- BillboardGui (Hiển thị tên, vai trò, HP, khoảng cách)
    local bbName = player.Name .. "_ESP_BB"
    local bb = ESP_Holder:FindFirstChild(bbName)
    if not bb then
        bb = Instance.new("BillboardGui")
        bb.Name = bbName
        bb.Size = UDim2.new(0, 260, 0, 70)
        bb.StudsOffset = Vector3.new(0, 3.5, 0)
        bb.AlwaysOnTop = true
        bb.Parent = ESP_Holder

        local label = Instance.new("TextLabel")
        label.Name = "T"
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        label.TextStrokeTransparency = 0
        label.TextStrokeColor3 = Color3.new(0, 0, 0)
        label.Parent = bb
    end
    bb.Adornee = head

    local label = bb:FindFirstChild("T")
    if label then
        label.Text = string.format("%s [%s]\n%dm  HP:%d/%d",
            player.Name, role, math.floor(distance),
            math.floor(health), math.floor(maxHealth))
        label.TextColor3 = color
    end

    -- BoxHandleAdornment (Khung bao quanh nhân vật)
    local boxName = player.Name .. "_ESP_BX"
    local box = ESP_Holder:FindFirstChild(boxName)
    if not box then
        box = Instance.new("BoxHandleAdornment")
        box.Name = boxName
        box.AlwaysOnTop = true
        box.ZIndex = 10
        box.Transparency = 0.5
        box.Parent = ESP_Holder
    end
    box.Adornee = hrp
    box.Size = hrp.Size + Vector3.new(0.1, 0.1, 0.1)
    box.Color3 = color
end

-- 3. HÀM XÓA ESP CỦA MỘT PLAYER
local function removeESP(player)
    pcall(function()
        local bb = ESP_Holder:FindFirstChild(player.Name .. "_ESP_BB")
        if bb then bb:Destroy() end
        
        local box = ESP_Holder:FindFirstChild(player.Name .. "_ESP_BX")
        if box then box:Destroy() end
    end)
end

-- Tự động dọn dẹp khi người chơi thoát game
Players.PlayerRemoving:Connect(removeESP)

-- 4. TẠO GIAO DIỆN ĐIỀU KHIỂN (GUI) - FLUENT UI

-- Load Fluent UI Library
local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/taioccho/sexmocbuom/main/Fluent.lua"))()

-- Tạo Fluent Window
local Window = Fluent:CreateWindow({
    Title    = "かわいい Hub",
    SubTitle = "by No Name",
    TabWidth = 160,
    Size     = {480, 420},
    Acrylic  = false,
    Theme    = "Dark",
    KeyBehind = Enum.KeyCode.LeftControl,
    Image    = "logo roblox o day"
})

-- ── TABS ─────────────────────────────────────────────────────────────────
local Tab         = Window:AddTab({ Title = "Main",     Icon = "sword" })
local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "settings" })

-- ── STATUS PARAGRAPH (đầu tab Main) ─────────────────────────────────────
local statusParagraph = Tab:AddParagraph({
    Title   = "Status: Waiting for round...",
    Content = "",
})

local function setStatus(text)
    pcall(function()
        statusParagraph:SetTitle("Status: " .. text)
    end)
end

-- ── MAIN TAB ─────────────────────────────────────────────────────────────
local ToggleAutoSeeker = Tab:AddToggle("AutoSeeker", {
    Title       = "Auto Seeker",
    Description = "Auto Tween To Hider Then Attack if you are Hider",
    Default     = _G.AutoSeeker,
})
ToggleAutoSeeker:OnChanged(function(v)
    _G.AutoSeeker = v
    saveConfig()
end)

local ToggleAutoHide = Tab:AddToggle("AutoHide", {
    Title       = "Auto Hide",
    Description = "Auto Hide if you are Hider",
    Default     = _G.AutoHide,
})
ToggleAutoHide:OnChanged(function(v)
    _G.AutoHide = v
    saveConfig()
end)

local ToggleESP = Tab:AddToggle("ESP", {
    Title       = "Player ESP",
    Description = "Show hider positions when you are Seeker",
    Default     = _G.ESP,
})
ToggleESP:OnChanged(function(v)
    _G.ESP = v
    saveConfig()
end)

-- ── SETTINGS TAB ─────────────────────────────────────────────────────────
local ToggleNoclip = SettingsTab:AddToggle("Noclip", {
    Title       = "Noclip",
    Description = "Walk through walls",
    Default     = _G.Noclip,
})
ToggleNoclip:OnChanged(function(v)
    _G.Noclip = v
    saveConfig()
end)

local ToggleInfinityJump = SettingsTab:AddToggle("InfinityJump", {
    Title       = "Infinity Jump",
    Description = "",
    Default     = _G.InfinityJump,
})
ToggleInfinityJump:OnChanged(function(v)
    _G.InfinityJump = v
    if v then startInfinityJump() else stopInfinityJump() end
    saveConfig()
end)

local ToggleAutoExecute = SettingsTab:AddToggle("AutoExecute", {
    Title       = "Auto Execute",
    Description = "Auto Execute The Script When Hop/Rejoin Server",
    Default     = _G.AutoExecute or false,
})
ToggleAutoExecute:OnChanged(function(v)
    _G.AutoExecute = v
    -- Re-queue ngay khi bật toggle, để hop thủ công sau đó cũng hoạt động
    pcall(function()
        if v and queue_on_teleport then
            queue_on_teleport(('loadstring(game:HttpGet("%s"))()'):format(SCRIPT_URL))
        end
    end)
    saveConfig()
end)

local SliderWalkSpeed = SettingsTab:AddSlider("WalkSpeed", {
    Title    = "Walk Speed",
    Default  = _G.WalkSpeed,
    Min      = 0,
    Max      = 100,
    Rounding = 0,
})
SliderWalkSpeed:OnChanged(function(v)
    _G.WalkSpeed = v
    saveConfig()
end)

-- ── SERVER TAB ────────────────────────────────────────────────────────────
local ServerTab = Window:AddTab({ Title = "Server", Icon = "globe" })

local jobIdInput = ServerTab:AddInput("JobIdInput", {
    Title       = "Job ID",
    Placeholder = "Input Job Id Here.",
    Default     = "",
})

ServerTab:AddButton({
    Title       = "Join Job ID",
    Description = "",
    Callback    = function()
        local jobId = jobIdInput.Value
        if not jobId or jobId == "" then return end
        queueAutoExecute()
        local TS = game:GetService("TeleportService")
        pcall(function()
            TS:TeleportToPlaceInstance(game.PlaceId, jobId, localPlayer)
        end)
    end,
})

ServerTab:AddButton({
    Title       = "Copy Job ID",
    Description = "Copy current Job ID to Clipboard",
    Callback    = function()
        pcall(function() setclipboard(game.JobId) end)
    end,
})

ServerTab:AddButton({
    Title       = "Rejoin",
    Description = "",
    Callback    = function()
        queueAutoExecute()
        local TS = game:GetService("TeleportService")
        pcall(function()
            TS:TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer)
        end)
    end,
})

ServerTab:AddButton({
    Title       = "Hop Server",
    Description = "Hop Random Server",
    Callback    = function()
        queueAutoExecute()
        local TS  = game:GetService("TeleportService")
        local Http = game:GetService("HttpService")
        local ok, servers = pcall(function()
            local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
            local res = Http:JSONDecode(game:HttpGet(url))
            return res.data
        end)
        if ok and servers and #servers > 0 then
            -- Lọc bỏ server hiện tại
            local candidates = {}
            for _, s in ipairs(servers) do
                if s.id ~= game.JobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers then
                    table.insert(candidates, s)
                end
            end
            if #candidates > 0 then
                local pick = candidates[math.random(1, #candidates)]
                pcall(function()
                    TS:TeleportToPlaceInstance(game.PlaceId, pick.id, localPlayer)
                end)
                return
            end
        end
        -- Fallback: teleport thẳng không cần JobId
        pcall(function() TS:Teleport(game.PlaceId, localPlayer) end)
    end,
})

-- ── CLEANUP ON CLOSE ─────────────────────────────────────────────────────
pcall(function()
    Window:OnClose(function()
        if _G.SoiNoclipConnection then
            _G.SoiNoclipConnection:Disconnect()
            _G.SoiNoclipConnection = nil
        end
        stopFly()
        stopInfinityJump()
        if ESP_Holder then ESP_Holder:Destroy() end
    end)
end)


-- 5. VÒNG LẶP NOCLIP CHẠY TRÊN STEPPED (ĐỂ BỎ VA CHẠM KHÔNG BỊ TRỄ)
_G.SoiNoclipConnection = RunService.Stepped:Connect(function()
    local shouldNoclip = isFlying or isFlyActive or _G.Noclip
    if shouldNoclip and localPlayer.Character then
        for _, part in ipairs(localPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- 6. VÒNG LẶP CẬP NHẬT CHÍNH (HEARTBEAT)
RunService.Heartbeat:Connect(function(dt)
    local dt = dt or 0.016
    local myChar = localPlayer.Character
    if not myChar then 
        isFlying = false
        nearestHider = nil
        return 
    end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then 
        isFlying = false
        nearestHider = nil
        return 
    end

    -- Đảm bảo tắt cơ chế đứng thăng bằng vật lý của Humanoid khi đang bay/trốn để dễ dàng đi xuyên tường/sàn
    local hum = myChar:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.PlatformStand = isFlying
        if hum.WalkSpeed ~= _G.WalkSpeed then
            hum.WalkSpeed = _G.WalkSpeed
        end
    end

    -- Đếm Seeker và thu thập vai trò
    local seekerCount = 0
    local playerRoles = {}

    for _, p in ipairs(Players:GetPlayers()) do
        local isSeeker = false
        local char = p.Character
        if char then
            if char:FindFirstChild("SeekerHighlight_Local") then
                isSeeker = true
            else
                local tool = char:FindFirstChildOfClass("Tool") or p.Backpack:FindFirstChildOfClass("Tool")
                if tool then
                    local name = tool.Name:lower()
                    if name:find("knife") or name:find("tag") or name:find("catch") or name:find("seeker") then
                        isSeeker = true
                    end
                end
            end
        end
        if isSeeker then
            seekerCount = seekerCount + 1
            playerRoles[p] = true
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if playerRoles[p] == nil then
            if seekerCount > 0 then
                playerRoles[p] = false -- Hider
            else
                playerRoles[p] = nil -- Chưa rõ (lobby)
            end
        end
    end

    -- Cập nhật ESP cho từng player
    local myRole = playerRoles[localPlayer]
    
    -- Theo dõi sự thay đổi vai trò để bắt mốc thời gian vào map (tránh bị kẹt bắt tọa độ lúc đang ở Lobby)
    if myRole ~= lastRole then
        if myRole == false then
            roleChangedTime = os.clock()
        end
        lastRole = myRole
    end
    
    local minHiderDist = math.huge
    local currentNearest = nil

    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        local isHider = (playerRoles[player] == false)

        -- Chỉ vẽ ESP cho Hider khác khi bản thân mình đang là Seeker
        if _G.ESP and myRole == true and player ~= localPlayer and isHider and char then
            local hum = char:FindFirstChild("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")

            if hum and hrp then
                local dist = (myHRP.Position - hrp.Position).Magnitude

                -- Nếu chết, ở quá xa hoặc nằm trong vùng an toàn thì dọn dẹp/không hiện ESP
                if hum.Health <= 0 or dist > MAX_DISTANCE or isInsideSafeZone(hrp.Position) then
                    removeESP(player)
                else
                    createESP(player, char, dist, hum.Health, hum.MaxHealth, false) -- Chắc chắn là Hider (Xanh lục)
                    
                    -- Tìm Hider gần nhất còn sống
                    if hum.Health > 0 and dist < minHiderDist then
                        minHiderDist = dist
                        currentNearest = hrp
                    end
                end
            else
                removeESP(player)
            end
        else
            -- Nếu mình không phải Seeker, hoặc player đó không phải Hider -> Xóa ESP
            removeESP(player)
        end
    end

    nearestHider = currentNearest

    -- Xử lý Bay & Tấn công (Auto Seeker)
    if myRole == true then
        isFlying = _G.AutoSeeker and nearestHider ~= nil

        if nearestHider then
            local targetPos = nearestHider.Position
            local myPos = myHRP.Position
            local dir = targetPos - myPos
            local dist = dir.Magnitude

            -- Xử lý bay dịch chuyển (bay ra sau lưng mục tiêu 3.5 studs)
            if _G.AutoSeeker then
                local backOffset = nearestHider.CFrame.LookVector * 3.5 -- lùi ra sau lưng 3.5 studs
                local targetBackPos = targetPos - backOffset
                
                local dirToBack = targetBackPos - myPos
                local distToBack = dirToBack.Magnitude

                if distToBack > 1 then
                    local moveStep = math.min(distToBack, _G.FlySpeed * dt)
                    myHRP.CFrame = CFrame.new(myPos + dirToBack.Unit * moveStep, targetPos)
                else
                    -- Bám sát ngay sau lưng và mặt hướng về phía hider
                    myHRP.CFrame = CFrame.new(targetBackPos, targetPos)
                end
                -- Triệt tiêu lực vật lý tránh trượt / văng đi
                myHRP.AssemblyLinearVelocity = Vector3.zero
                myHRP.AssemblyAngularVelocity = Vector3.zero
                
                setStatus(string.format("Target: %s | Distance: %.1fm", nearestHider.Parent.Name, dist))
            else
                setStatus(string.format("Nearest target: %s | Distance: %.1fm", nearestHider.Parent.Name, dist))
            end

            -- Xử lý tự click chém + taunt khi gần (Auto Seeker tích hợp)
            if _G.AutoSeeker then
                local targetHrp = nearestHider
                if targetHrp and dist <= _G.AttackRange then
                    if os.clock() - lastAttack >= ATTACK_COOLDOWN then
                        -- 1. Tự động trang bị vũ khí từ Backpack nếu có
                        local tool = myChar:FindFirstChildOfClass("Tool")
                        if not tool then
                            local bpTool = localPlayer.Backpack:FindFirstChildOfClass("Tool")
                            if bpTool then
                                bpTool.Parent = myChar
                            end
                        end
                        
                        -- 2. Thực hiện click chuột trái thông thường
                        if mouse1click then
                            pcall(mouse1click)
                        elseif mouse1press and mouse1release then
                            pcall(function()
                                mouse1press()
                                task.wait(0.01)
                                mouse1release()
                            end)
                        else
                            pcall(function()
                                local vim = game:GetService("VirtualInputManager")
                                local mouse = localPlayer:GetMouse()
                                vim:SendMouseButtonEvent(mouse.X, mouse.Y, 0, true, game, 1)
                                task.wait(0.01)
                                vim:SendMouseButtonEvent(mouse.X, mouse.Y, 0, false, game, 1)
                            end)
                        end
                        
                        lastAttack = os.clock()
                    end
                end

                -- Auto Taunt tích hợp: taunt khi cách hider < 5 stud và mình là seeker
                if dist <= 5 then
                    if os.clock() - lastTauntTime >= 5 then
                        local tauntDone = false
                        pcall(function()
                            local hud = localPlayer.PlayerGui:FindFirstChild("Hud")
                            local gamepadTaunt = hud and hud:FindFirstChild("GamepadTauntControl")
                            if gamepadTaunt then
                                if gamepadTaunt:IsA("BindableEvent") then
                                    gamepadTaunt:Fire(); tauntDone = true
                                elseif gamepadTaunt:IsA("RemoteEvent") then
                                    gamepadTaunt:FireServer(); tauntDone = true
                                end
                            end
                        end)
                        if not tauntDone then
                            pcall(function()
                                if clickTauntButton() then tauntDone = true end
                            end)
                        end
                        if not tauntDone then
                            pcall(function()
                                local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("GameRemotes")
                                local manualTaunt = remotes and remotes:FindFirstChild("ManualTaunt")
                                if manualTaunt then manualTaunt:FireServer(); tauntDone = true end
                            end)
                        end
                        if not tauntDone then
                            pcall(function()
                                local vim = game:GetService("VirtualInputManager")
                                vim:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
                                task.wait(0.05)
                                vim:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
                            end)
                        end
                        lastTauntTime = os.clock()
                    end
                end
            end
        else
            isFlying = false
            setStatus("Seeker - No Hiders found")
        end
    else
        -- Khi là Hider
        nearestHider = nil
        
        if myRole == false and _G.AutoHide then
            -- Chờ 3.5 giây sau khi làm Hider để game hoàn tất dịch chuyển từ Lobby vào Map
            if os.clock() - roleChangedTime >= 3.5 then
                isFlying = true
                -- Tự động bắt tọa độ X, Z hiện tại và hạ chiều cao Y xuống 2
                if not lastCapturedPos then
                    local currentPos = myHRP.Position
                    lastCapturedPos = Vector3.new(currentPos.X, 2, currentPos.Z)
                end
                
                local targetPos = lastCapturedPos
                local myPos = myHRP.Position
                local dist = (targetPos - myPos).Magnitude
                
                if dist > 0.1 then
                    local moveStep = math.min(dist, _G.FlySpeed * dt)
                    myHRP.CFrame = CFrame.new(myPos + (targetPos - myPos).Unit * moveStep)
                else
                    myHRP.CFrame = CFrame.new(targetPos)
                end
                
                myHRP.AssemblyLinearVelocity = Vector3.zero
                myHRP.AssemblyAngularVelocity = Vector3.zero
                
                setStatus(string.format("Hider - Hiding at Y=2 | Distance: %.1fm", dist))
            else
                isFlying = false
                setStatus("Waiting for teleport...")
            end
        else
            isFlying = false
            lastCapturedPos = nil -- Reset để lần sau bật sẽ bắt lại tọa độ mới
            lastWanderTarget = nil
            nextWanderTime = 0
            if myRole == false then
                setStatus("Hider - Free movement")
            else
                setStatus("Waiting for round...")
            end
        end
    end
end)
Window:SelectTab(Tab)
-- かわいい Hub ĐANG HOẠT ĐỘNG