-- Chờ game load xong hoàn toàn
if not game:IsLoaded() then game.Loaded:Wait() end
-- Khởi tạo biến toàn cục mặc định để check trạng thái Raid
getgenv().PirateRaid = true
getgenv().Factory = true
-- ==========================================
-- CẤU HÌNH (Tọa độ, Bán kính, Tốc độ)
-- ==========================================
local CHECK_CENTER = Vector3.new(-5556.43, 314.08, -2972.08)
local TELEPORT_STAGE = CFrame.new(-5018.92, 314.83, -3186.97) -- Tọa độ trung chuyển
local CHECK_RADIUS = 500
local BRING_RADIUS = 350
local TWEEN_SPEED = 325
local MAX_COOLDOWN = 5

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(newChar)
	character = newChar
	hrp = newChar:WaitForChild("HumanoidRootPart")
end)

-- Biến quản lý trạng thái bay ngầm
local currentTween = nil
local bodyVelocity = nil
local bodyPosition = nil
local noclipConnection = nil
local lastTargetPos = nil
local cooldownTimer = 0
local isTweening = false -- Biến kiểm tra xem có đang tween hay không

-- Khởi tạo cấu trúc hòm đồ toàn cục nếu chưa có
if not ScriptStorage then
    ScriptStorage = { Backpack = {} }
end

-- ==========================================
-- LOGIC CHECK VALKYRIE HELM
-- ==========================================
local function RefreshInventory()
    ScriptStorage.Backpack2 = {}
    local CommF = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_")
    if CommF then
        local inv = CommF:InvokeServer('getInventory')
        if inv then
            for _, item in pairs(inv) do 
                ScriptStorage.Backpack2[item.Name] = item 
            end
        end
    end
    ScriptStorage.Backpack = ScriptStorage.Backpack2
end

local function HasValkyrieHelm()
    local success = pcall(RefreshInventory)
    if not success then return false end
    if ScriptStorage.Backpack and ScriptStorage.Backpack["Valkyrie Helm"] then
        return true
    end
    return false
end

-- ==========================================
-- HỆ THỐNG ANTI FALL & NOCLIP (CHỈ CHẠY KHI ĐANG TWEEN)
-- ==========================================
RunService.Stepped:Connect(function()
	if isTweening and character and hrp then
		-- Bật NoClip xuyên tường khi đang bay
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") then part.CanCollide = false end
		end
		
		-- Bật Anti Fall khóa cứng trọng lực khi đang bay
		if not bodyVelocity or bodyVelocity.Parent ~= hrp then
			if bodyVelocity then bodyVelocity:Destroy() end
			bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.Velocity = Vector3.new(0, 0, 0)
			bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
			bodyVelocity.Parent = hrp
		end
		
		if not bodyPosition or bodyPosition.Parent ~= hrp then
			if bodyPosition then bodyPosition:Destroy() end
			bodyPosition = Instance.new("BodyPosition")
			bodyPosition.MaxForce = Vector3.new(0, 9e9, 0)
			bodyPosition.Position = hrp.Position
			bodyPosition.Parent = hrp
		end
	else
		-- Dọn dẹp, tắt Anti-Fall khi dừng bay để nhân vật hoạt động bình thường
		if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
		if bodyPosition then bodyPosition:Destroy() bodyPosition = nil end
	end
end)

-- ==========================================
-- CHỨC NĂNG BRING MOB (GOM QUÁI MỖI 2 GIÂY)
-- ==========================================
task.spawn(function()
	while task.wait(2) do
		if hrp and getgenv().PirateRaid == true and workspace:FindFirstChild("Enemies") then
			for _, v in pairs(workspace.Enemies:GetChildren()) do
				if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
					if v.Humanoid.Health > 0 then
						local distToPlayer = (v.HumanoidRootPart.Position - hrp.Position).Magnitude
						if distToPlayer <= BRING_RADIUS then
							v.HumanoidRootPart.CFrame = hrp.CFrame * CFrame.new(0, -4, 0)
						end
					end
				end
			end
		end
	end
end)

-- ==========================================
-- CORE: QUÉT TRONG Workspace.Enemies & XỬ LÝ DI CHUYỂN
-- ==========================================
RunService.Heartbeat:Connect(function(deltaTime)
	local targetMob = nil
	
	if workspace:FindFirstChild("Enemies") then
		for _, v in pairs(workspace.Enemies:GetChildren()) do
			if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
				if v.Humanoid.Health > 0 then 
					local distanceToCenter = (v.HumanoidRootPart.Position - CHECK_CENTER).Magnitude
					if distanceToCenter <= CHECK_RADIUS then
						targetMob = v
						break
					end
				end
			end
		end
	end
	
	if targetMob then
		cooldownTimer = MAX_COOLDOWN 
		getgenv().PirateRaid = true
		
		if hrp then
			local distanceFromCastle = (hrp.Position - CHECK_CENTER).Magnitude
			if distanceFromCastle > 1000 and HasValkyrieHelm() then
				isTweening = true -- Kích hoạt trạng thái để bật tạm thời Anti-Fall khi dịch chuyển
				if currentTween then currentTween:Cancel() end 
				hrp.CFrame = TELEPORT_STAGE 
				task.wait(0.1) 
			end
			
			local currentTargetPos = targetMob.HumanoidRootPart.Position + Vector3.new(0, 10, 0)
			
			if not lastTargetPos or (currentTargetPos - lastTargetPos).Magnitude > 3 then
				lastTargetPos = currentTargetPos
				local distance = (hrp.Position - currentTargetPos).Magnitude
				
				if distance > 4 then
					isTweening = true -- Xác nhận đang thực hiện hành trình bay -> Bật Anti-Fall
					local duration = distance / TWEEN_SPEED
					if currentTween then currentTween:Cancel() end
					
					currentTween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = CFrame.new(currentTargetPos)})
					currentTween:Play()
					
					-- Khi bay xong đến đích thì tắt trạng thái tweening
					currentTween.Completed:Connect(function()
						isTweening = false
					end)
				else
					isTweening = false -- Ở quá gần sát quái rồi thì không cần tính là đang tween nữa
				end
			end
			
			-- Cập nhật tọa độ giữ chân liên tục theo đầu quái nếu vẫn đang bay
			if isTweening and bodyPosition then
				bodyPosition.Position = currentTargetPos
			end
		end
	else
		-- Khi quái chết/chưa hồi sinh, bắt đầu đếm ngược 5 giây
		if cooldownTimer > 0 then
			cooldownTimer = cooldownTimer - deltaTime
			isTweening = false -- Ngừng tween, tắt ngay Anti-Fall để người chơi tự do di chuyển
		else
			getgenv().PirateRaid = false
			lastTargetPos = nil
			isTweening = false
			if currentTween then currentTween:Cancel() currentTween = nil end
		end
	end
end)

print("Script Đã Cập Nhật: Chỉ bật Anti-Fall và NoClip trong lúc di chuyển Tween!")
local TARGET_POSITION = Vector3.new(428.35, 211.82, -429.03) -- Tọa độ gốc Factory
local TARGET_CFRAME = CFrame.new(428.35, 211.82, -429.03)
local TELEPORT_STAGE = CFrame.new(-287.39, 306.44, 607.50)  -- Trạm trung chuyển
local TWEEN_SPEED = 325

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(newChar)
	character = newChar
	hrp = newChar:WaitForChild("HumanoidRootPart")
end)

-- Biến quản lý trạng thái di chuyển ngầm
local currentTween = nil
local bodyVelocity = nil
local bodyPosition = nil
local isTweening = false

-- ==========================================
-- HỆ THỐNG ANTI FALL & NOCLIP (CHỈ CHẠY KHI ĐANG TWEEN)
-- ==========================================
RunService.Stepped:Connect(function()
	if isTweening and character and hrp then
		-- Bật NoClip xuyên tường khi đang bay
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") then part.CanCollide = false end
		end
		
		-- Bật Anti Fall khóa cứng trọng lực khi đang bay
		if not bodyVelocity or bodyVelocity.Parent ~= hrp then
			if bodyVelocity then bodyVelocity:Destroy() end
			bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.Velocity = Vector3.new(0, 0, 0)
			bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
			bodyVelocity.Parent = hrp
		end
		
		if not bodyPosition or bodyPosition.Parent ~= hrp then
			if bodyPosition then bodyPosition:Destroy() end
			bodyPosition = Instance.new("BodyPosition")
			bodyPosition.MaxForce = Vector3.new(0, 9e9, 0)
			bodyPosition.Position = hrp.Position
			bodyPosition.Parent = hrp
		end
	else
		-- Tắt và dọn dẹp Anti-Fall khi không còn bay để nhân vật hoạt động bình thường
		if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
		if bodyPosition then bodyPosition:Destroy() bodyPosition = nil end
	end
end)

-- ==========================================
-- CORE: CHECK CORE TRONG Workspace.Enemies & ĐIỀU HƯỚNG TWEEN
-- ==========================================
RunService.Heartbeat:Connect(function()
	local coreMob = nil
	
	-- Quét tìm quái tên "Core" trong Workspace.Enemies
	if workspace:FindFirstChild("Enemies") then
		local core = workspace.Enemies:FindFirstChild("Core")
		if core and core:FindFirstChild("Humanoid") and core.Humanoid.Health > 0 then
			coreMob = core
		end
	end
	
	-- Xử lý Logic khi Core xuất hiện và còn sống
	if coreMob then
		getgenv().Factory = true -- Kích hoạt trạng thái True
		
		if hrp then
			-- 🛠️ KIỂM TRA KHOẢNG CÁCH: Nếu cách xa tọa độ gốc quá 1000 studs -> Set CFrame trước
			local distanceToTarget = (hrp.Position - TARGET_POSITION).Magnitude
			if distanceToTarget > 1000 then
				isTweening = true -- Kích hoạt bật tạm Anti-Fall để giữ an toàn khi nhảy vị trí
				if currentTween then currentTween:Cancel() end -- Hủy hành trình cũ nếu có
				hrp.CFrame = TELEPORT_STAGE
				task.wait(0.1) -- Khựng nhẹ 0.1s để game đồng bộ map ổn định
			end
			
			-- Tiến hành chạy Tween Service đến tọa độ Factory với tốc độ 325
			local currentDistance = (hrp.Position - TARGET_POSITION).Magnitude
			if currentDistance > 4 and not isTweening then
				isTweening = true -- Xác nhận đang bay -> Bật Anti-Fall và NoClip
				local duration = currentDistance / TWEEN_SPEED
				if currentTween then currentTween:Cancel() end
				
				currentTween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = TARGET_CFRAME})
				currentTween:Play()
				
				-- Khi bay xong đến đích an toàn thì tắt trạng thái tweening
				currentTween.Completed:Connect(function()
					isTweening = false
				end)
			elseif currentDistance <= 4 then
				isTweening = false -- Đã đến nơi sát nút, giải phóng Anti-Fall để farm tự do
			end
			
			-- Giữ mốc độ cao đứng vững tại tọa độ gốc nếu đang trong trạng thái tween/đứng đợi
			if isTweening and bodyPosition then
				bodyPosition.Position = TARGET_POSITION
			end
		end
	else
		-- ❌ HỦY NGAY KHI KHÔNG CÒN ENEMIES CORE (Hoặc Core đã chết)
		getgenv().Factory = false
		isTweening = false
		
		if currentTween then 
			currentTween:Cancel() 
			currentTween = nil 
		end
	end
end)

print("Script Auto Factory Tối Ưu Mới: getgenv().Factory + Chỉ Anti-Fall khi Tween đã kích hoạt!")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local player = Players.LocalPlayer

-- Bật các tính năng cấu hình toàn cục
getgenv().AutoStoreFruit = true
_G.Hopserver = false -- Khởi tạo ban đầu bằng false

-- ==========================================
-- BƯỚC 1: TỰ ĐỘNG CHỌN ĐỘI (CHOOSE TEAM PIRATES)
-- ==========================================
task.spawn(function()
    pcall(function()
        if player.Team == nil then
            ReplicatedStorage.Remotes.CommF_:InvokeServer("SetTeam", "Pirates")
        end
    end)
end)

-- ==========================================
-- BƯỚC 2: DANH SÁCH FRUIT UPDATE RENAME MỚI NHẤT
-- ==========================================
local FruitsList = {
    {"Rocket Fruit", "Rocket-Rocket"},
    {"Spin Fruit", "Spin-Spin"},
    {"Blade Fruit", "Blade-Blade"},
    {"Spring Fruit", "Spring-Spring"},
    {"Bomb Fruit", "Bomb-Bomb"},
    {"Smoke Fruit", "Smoke-Smoke"},
    {"Spike Fruit", "Spike-Spike"},
    {"Flame Fruit", "Flame-Flame"},
    {"Eagle Fruit", "Eagle-Eagle"},
    {"Ice Fruit", "Ice-Ice"},
    {"Sand Fruit", "Sand-Sand"},
    {"Dark Fruit", "Dark-Dark"},
    {"Diamond Fruit", "Diamond-Diamond"},
    {"Light Fruit", "Light-Light"},
    {"Rubber Fruit", "Rubber-Rubber"},
    {"Creation Fruit", "Creation-Creation"},
    {"Ghost Fruit", "Ghost-Ghost"},
    {"Magma Fruit", "Magma-Magma"},
    {"Quake Fruit", "Quake-Quake"},
    {"Buddha Fruit", "Buddha-Buddha"},
    {"Love Fruit", "Love-Love"},
    {"Spider Fruit", "Spider-Spider"},
    {"Sound Fruit", "Sound-Sound"},
    {"Phoenix Fruit", "Phoenix-Phoenix"}, 
    {"Portal Fruit", "Portal-Portal"}, 
    {"Lightning Fruit", "Rumble-Rumble"},
    {"Pain Fruit", "Pain-Pain"}, 
    {"Blizzard Fruit", "Blizzard-Blizzard"},
    {"Gravity Fruit", "Gravity-Gravity"}, 
    {"Mammoth Fruit", "Mammoth-Mammoth"}, 
    {"T-Rex Fruit", "T-Rex-T-Rex"}, 
    {"Dough Fruit", "Dough-Dough"}, 
    {"Shadow Fruit", "Shadow-Shadow"}, 
    {"Venom Fruit", "Venom-Venom"}, 
    {"Control Fruit", "Control-Control"}, 
    {"Spirit Fruit", "Spirit-Spirit"}, 
    {"Leopard Fruit", "Leopard-Leopard"}, 
    {"Gas Fruit", "Gas-Gas"},
    {"Yeti Fruit", "Yeti-Yeti"},
    {"Kitsune Fruit", "Kitsune-Kitsune"}, 
    {"Dragon Fruit", "Dragon-Dragon"},
    {"Tiger Fruit", "Tiger-Tiger"}
}

-- ==========================================
-- BƯỚC 3: GIAO DIỆN UI STATUS (BẢNG TRẠNG THÁI GỌN GÀNG)
-- ==========================================
local playerGui = player:WaitForChild("PlayerGui")
local targetGui = CoreGui or playerGui

if targetGui:FindFirstChild("FruitStatusUI") then targetGui.FruitStatusUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FruitStatusUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = targetGui

local StatusFrame = Instance.new("Frame")
StatusFrame.Size = UDim2.new(0, 240, 0, 75)
StatusFrame.Position = UDim2.new(0, 15, 0, 15)
StatusFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
StatusFrame.BackgroundTransparency = 0.2
StatusFrame.Active = true
StatusFrame.Draggable = true
StatusFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = StatusFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(0, 255, 150)
UIStroke.Thickness = 1.5
UIStroke.Parent = StatusFrame

local TotalLabel = Instance.new("TextLabel", StatusFrame)
TotalLabel.Size = UDim2.new(1, -10, 0, 30)
TotalLabel.Position = UDim2.new(0, 10, 0, 5)
TotalLabel.Text = "Fruit In Server: Checking..."
TotalLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TotalLabel.Font = Enum.Font.SourceSansBold
TotalLabel.TextSize = 16
TotalLabel.TextXAlignment = Enum.TextXAlignment.Left
TotalLabel.BackgroundTransparency = 1

local StatusLabel = Instance.new("TextLabel", StatusFrame)
StatusLabel.Size = UDim2.new(1, -10, 0, 30)
StatusLabel.Position = UDim2.new(0, 10, 0, 35)
StatusLabel.Text = "Status: Initializing"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.TextSize = 14
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.BackgroundTransparency = 1

-- ==========================================
-- BƯỚC 4: LUỒNG HOP SERVER GỐC CỦA BẠN (Chờ _G.Hopserver == true)
-- ==========================================
local ServerBrowser = ReplicatedStorage:WaitForChild("__ServerBrowser")

task.spawn(function()
    while task.wait() do
        if _G.Hopserver == true then
            StatusLabel.Text = "Status: Server Empty! Hopping..."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            
            local currentJobId = game.JobId
            local found = false

            local success, serverList = pcall(function()
                return ServerBrowser:InvokeServer("getservers")
            end)

            if success and type(serverList) == "table" then
                for _, server in pairs(serverList) do
                    local id = server.Id or server.id or server.JobId
                    if id and id ~= currentJobId then
                        ServerBrowser:InvokeServer("teleport", id)
                        found = true
                        break
                    end
                end
            end

            if not found then
                local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
                local apiSuccess, result = pcall(function()
                    return HttpService:JSONDecode(game:HttpGet(url))
                end)
                
                if apiSuccess and result and result.data then
                    for _, server in ipairs(result.data) do
                        if server.id ~= currentJobId then
                            ServerBrowser:InvokeServer("teleport", server.id)
                            found = true
                            break
                        end
                    end
                end
            end
            
            if found then
                task.wait(1)
            end
        end
    end
end)

-- ==========================================
-- BƯỚC 5: LUỒNG QUÉT CHÍNH VÀ ĐIỀU KHIỂN LOGIC
-- ==========================================
_G.IsFarming = false
local emptyCheckCount = 0

local function scanAndStoreFruits()
    -- Nếu đã bật nhảy server thì ngừng hoàn toàn logic quét
    if _G.Hopserver == true then return end

    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local detectedFruits = {}
    local fruitDataMap = {}

    -- Quét nhanh Workspace tìm trái cây bằng tên chuẩn mới
    for _, fruitData in ipairs(FruitsList) do
        local wsName = fruitData[1]
        local fruitObj = workspace:FindFirstChild(wsName)
        
        if fruitObj then
            table.insert(detectedFruits, fruitObj)
            fruitDataMap[wsName] = fruitData[2]
        end
    end

    -- Cập nhật giao diện UI Status
    TotalLabel.Text = "Fruit In Server: " .. #detectedFruits
    
    if #detectedFruits > 0 then
        TotalLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
        emptyCheckCount = 0 -- Reset bộ đếm khi thấy fruit
        
        if not _G.IsFarming then
            _G.IsFarming = true
            
            for _, fruit in ipairs(detectedFruits) do
                local backpack = player:FindFirstChild("Backpack")
                if fruit and fruit.Parent == workspace and character:FindFirstChild("HumanoidRootPart") and backpack then
                    local currentFruitName = fruit.Name
                    local storeName = fruitDataMap[currentFruitName]
                    
                    StatusLabel.Text = "Status: Teleporting to [" .. currentFruitName .. "]"
                    StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
                    
                    -- 1. Dịch chuyển thẳng đến tọa độ trái cây
                    character.HumanoidRootPart.CFrame = (fruit:IsA("BasePart") and fruit.CFrame or fruit:GetPivot()) * CFrame.new(0, 1.5, 0)
                    task.wait(1) -- Chờ game hút trái cây vào túi
                    
                    -- 2. Kích hoạt Remote cất kho
                    if getgenv().AutoStoreFruit then
                        pcall(function()
                            local fruitTool = character:FindFirstChild(currentFruitName) or backpack:FindFirstChild(currentFruitName)
                            if fruitTool then
                                ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", storeName, fruitTool)
                                StatusLabel.Text = "Status: Stored [" .. currentFruitName .. "]"
                            end
                        end)
                    end
                    task.wait(0.5)
                end
            end
            _G.IsFarming = false
        end
    else
        TotalLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
       if not _G.IsFarming and getgenv().PirateRaid == false and getgenv().Factory == false then
            StatusLabel.Text = "Status: Waiting / Checking Server..."
            StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            
            emptyCheckCount = emptyCheckCount + 1
            -- Kiểm tra liên tiếp 3 lần trống thực sự để tránh lag ảo, sau đó bật biến Hopserver
            if emptyCheckCount >= 3 and getgenv().Factory == false and getgenv().PirateRaid == false then
                _G.Hopserver = true -- KÍCH HOẠT BIẾN THÀNH TRUE KHI HẾT FRUIT
            end
        end
    end
end

-- Khởi động vòng lặp kiểm tra
task.spawn(function()
    task.wait(2) -- Chờ 2 giây đầu để map ổn định và chọn phe xong
    while task.wait(0.3) do
        scanAndStoreFruits()
    end
end)
