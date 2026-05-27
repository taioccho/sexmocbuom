
if not getgenv().Config.Team or getgenv().Config.Team == "" then
    if game:GetService("Players").LocalPlayer.Team then
        getgenv().Config.Team = game:GetService("Players").LocalPlayer.Team.Name
    else
        getgenv().Config.Team = "Pirates"
    end
end

pcall(function()
    if getgenv().Config.Team == "Pirates" then
        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("SetTeam", "Pirates")
    elseif getgenv().Config.Team == "Marines" then
        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("SetTeam", "Marines")
    end
end)
EquipWeapon = function(text)
    if not text then return end
    if game:GetService("Players").LocalPlayer.Backpack:FindFirstChild(text) then
        
        if game:GetService("Players").LocalPlayer.Character and game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):EquipTool(game:GetService("Players").LocalPlayer.Backpack:FindFirstChild(text))
        end
    end
end

weaponSc = function(weapon)
    
    if game:GetService("Players").LocalPlayer.Character then
        for _, heldTool in pairs(game:GetService("Players").LocalPlayer.Character:GetChildren()) do
            if heldTool:IsA("Tool") and heldTool:FindFirstChild("ToolTip") and heldTool.ToolTip == weapon then
                return 
                end
        end
    end

    
    for __in, v in pairs(game:GetService("Players").LocalPlayer.Backpack:GetChildren()) do
        if v:IsA("Tool") then
            if v.ToolTip == weapon then 
                EquipWeapon(v.Name) 
                break 
            end
        end
    end
end

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            if getgenv().Config.Weapon and getgenv().Config.Weapon ~= "" then
                weaponSc(getgenv().Config.Weapon)
            end
        end)
    end
end)


local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
getgenv().AutoStoreFruit = true
getgenv().PirateRaid = true
getgenv().Factory = true
_G.Hopserver = false
local CHECK_CENTER = Vector3.new(-5556.43, 314.08, -2972.08)
local TELEPORT_STAGE_PIRATE = CFrame.new(-5018.92, 314.83, -3186.97)
local CHECK_RADIUS = 500
local BRING_RADIUS = 350
local TWEEN_SPEED = 325
local MAX_COOLDOWN = 5

local TARGET_POSITION = Vector3.new(428.35, 211.82, -429.03)
local TARGET_CFRAME = CFrame.new(428.35, 211.82, -429.03)
local TELEPORT_STAGE_FACTORY = CFrame.new(-287.39, 306.44, 607.50)

local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    hrp = newChar:WaitForChild("HumanoidRootPart")
end)

if not ScriptStorage then
    ScriptStorage = { Backpack = {} }
end

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

local currentTweenPirate = nil
local bodyVelocityPirate = nil
local bodyPositionPirate = nil
local lastTargetPos = nil
local cooldownTimer = 0
local isTweeningPirate = false

local currentTweenFactory = nil
local bodyVelocityFactory = nil
local bodyPositionFactory = nil
local isTweeningFactory = false

RunService.Stepped:Connect(function()
    if isTweeningPirate and character and hrp then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
        if not bodyVelocityPirate or bodyVelocityPirate.Parent ~= hrp then
            if bodyVelocityPirate then bodyVelocityPirate:Destroy() end
            bodyVelocityPirate = Instance.new("BodyVelocity")
            bodyVelocityPirate.Velocity = Vector3.new(0, 0, 0)
            bodyVelocityPirate.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bodyVelocityPirate.Parent = hrp
        end
        if not bodyPositionPirate or bodyPositionPirate.Parent ~= hrp then
            if bodyPositionPirate then bodyPositionPirate:Destroy() end
            bodyPositionPirate = Instance.new("BodyPosition")
            bodyPositionPirate.MaxForce = Vector3.new(0, 9e9, 0)
            bodyPositionPirate.Position = hrp.Position
            bodyPositionPirate.Parent = hrp
        end
    else
        if bodyVelocityPirate then bodyVelocityPirate:Destroy() bodyVelocityPirate = nil end
        if bodyPositionPirate then bodyPositionPirate:Destroy() bodyPositionPirate = nil end
    end

    if isTweeningFactory and character and hrp then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
        if not bodyVelocityFactory or bodyVelocityFactory.Parent ~= hrp then
            if bodyVelocityFactory then bodyVelocityFactory:Destroy() end
            bodyVelocityFactory = Instance.new("BodyVelocity")
            bodyVelocityFactory.Velocity = Vector3.new(0, 0, 0)
            bodyVelocityFactory.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bodyVelocityFactory.Parent = hrp
        end
        if not bodyPositionFactory or bodyPositionFactory.Parent ~= hrp then
            if bodyPositionFactory then bodyPositionFactory:Destroy() end
            bodyPositionFactory = Instance.new("BodyPosition")
            bodyPositionFactory.MaxForce = Vector3.new(0, 9e9, 0)
            bodyPositionFactory.Position = hrp.Position
            bodyPositionFactory.Parent = hrp
        end
    else
        if bodyVelocityFactory then bodyVelocityFactory:Destroy() bodyVelocityFactory = nil end
        if bodyPositionFactory then bodyPositionFactory:Destroy() bodyPositionFactory = nil end
    end
end)

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
                isTweeningPirate = true
                if currentTweenPirate then currentTweenPirate:Cancel() end
                hrp.CFrame = TELEPORT_STAGE_PIRATE
                task.wait(0.1)
            end
            local currentTargetPos = targetMob.HumanoidRootPart.Position + Vector3.new(0, 10, 0)
            if not lastTargetPos or (currentTargetPos - lastTargetPos).Magnitude > 3 then
                lastTargetPos = currentTargetPos
                local distance = (hrp.Position - currentTargetPos).Magnitude
                if distance > 4 then
                    isTweeningPirate = true
                    local duration = distance / TWEEN_SPEED
                    if currentTweenPirate then currentTweenPirate:Cancel() end
                    currentTweenPirate = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = CFrame.new(currentTargetPos)})
                    currentTweenPirate:Play()
                    currentTweenPirate.Completed:Connect(function()
                        isTweeningPirate = false
                    end)
                else
                    isTweeningPirate = false
                end
            end
            if isTweeningPirate and bodyPositionPirate then
                bodyPositionPirate.Position = currentTargetPos
            end
        end
    else
        if cooldownTimer > 0 then
            cooldownTimer = cooldownTimer - deltaTime
            isTweeningPirate = false
        else
            getgenv().PirateRaid = false
            lastTargetPos = nil
            isTweeningPirate = false
            if currentTweenPirate then currentTweenPirate:Cancel() currentTweenPirate = nil end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    local coreMob = nil
    if workspace:FindFirstChild("Enemies") then
        local core = workspace.Enemies:FindFirstChild("Core")
        if core and core:FindFirstChild("Humanoid") and core.Humanoid.Health > 0 then
            coreMob = core
        end
    end
    if coreMob then
        getgenv().Factory = true
        if hrp then
            local distanceToTarget = (hrp.Position - TARGET_POSITION).Magnitude
            if distanceToTarget > 1000 then
                isTweeningFactory = true
                if currentTweenFactory then currentTweenFactory:Cancel() end
                hrp.CFrame = TELEPORT_STAGE_FACTORY
                task.wait(0.1)
            end
            local currentDistance = (hrp.Position - TARGET_POSITION).Magnitude
            if currentDistance > 4 and not isTweeningFactory then
                isTweeningFactory = true
                local duration = currentDistance / TWEEN_SPEED
                if currentTweenFactory then currentTweenFactory:Cancel() end
                currentTweenFactory = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = TARGET_CFRAME})
                currentTweenFactory:Play()
                currentTweenFactory.Completed:Connect(function()
                    isTweeningFactory = false
                end)
            elseif currentDistance <= 4 then
                isTweeningFactory = false
            end
            if isTweeningFactory and bodyPositionFactory then
                bodyPositionFactory.Position = TARGET_POSITION
            end
        end
    else
        getgenv().Factory = false
        isTweeningFactory = false
        if currentTweenFactory then
            currentTweenFactory:Cancel()
            currentTweenFactory = nil
        end
    end
end)

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

local function sendFruitWebhook(fruitName)
    local cfg = getgenv().Config
    if not cfg or not cfg.WebhookUrl or cfg.WebhookUrl == "" then return end
    local time = os.date("%Y-%m-%d %H:%M:%S")
    local embedColor = 65280
    local embedTitle = "Webhook Stored Fruit"
    local pingMessage = ""
    if cfg.PingID and cfg.PingID ~= "" then
        pingMessage = "<@" .. cfg.PingID .. ">"
    end
    local data = {
        ["username"] = "NatAov Hub",
        ["avatar_url"] = "https://i.imgur.com/wEQNfK6.png",
        ["content"] = pingMessage,
        ["embeds"] = {{
            ["title"] = embedTitle,
            ["color"] = embedColor,
            ["thumbnail"] = {
                ["url"] = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"
            },
            ["fields"] = {
                {
                    ["name"] = "User Name",
                    ["value"] = "```" .. player.Name .. "```",
                    ["inline"] = true
                },
                {
                    ["name"] = "User ID",
                    ["value"] = "```" .. player.UserId .. "```",
                    ["inline"] = true
                },
                {
                    ["name"] = "Stored",
                    ["value"] = "```" .. fruitName .. "```",
                    ["inline"] = false
                }
            },
            ["footer"] = {
                ["text"] = "NatAov Hub " .. time
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    task.spawn(function()
        pcall(function()
            local requestFunc = (syn and syn.request) or
                              (request) or
                              (http and http.request) or
                              (http_request) or
                              (fluxus and fluxus.request) or
                              (Krnl and Krnl.request)
            if requestFunc then
                requestFunc({
                    Url = cfg.WebhookUrl,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = HttpService:JSONEncode(data)
                })
            end
        end)
    end)
end

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

_G.IsFarming = false
local emptyCheckCount = 0

local function scanAndStoreFruits()
    if _G.Hopserver == true then return end
    local char = player.Character
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    local detectedFruits = {}
    local fruitDataMap = {}
    for _, fruitData in ipairs(FruitsList) do
        local wsName = fruitData[1]
        local fruitObj = workspace:FindFirstChild(wsName)
        if fruitObj then
            table.insert(detectedFruits, fruitObj)
            fruitDataMap[wsName] = fruitData[2]
        end
    end
    TotalLabel.Text = "Fruit In Server: " .. #detectedFruits
    if #detectedFruits > 0 then
        TotalLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
        emptyCheckCount = 0
        if not _G.IsFarming then
            _G.IsFarming = true
            for _, fruit in ipairs(detectedFruits) do
                local backpack = player:FindFirstChild("Backpack")
                if fruit and fruit.Parent == workspace and char:FindFirstChild("HumanoidRootPart") and backpack then
                    local currentFruitName = fruit.Name
                    local storeName = fruitDataMap[currentFruitName]
                    StatusLabel.Text = "Status: Teleporting to [" .. currentFruitName .. "]"
                    StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
                    char.HumanoidRootPart.CFrame = (fruit:IsA("BasePart") and fruit.CFrame or fruit:GetPivot()) * CFrame.new(0, 1.5, 0)
                    task.wait(1)
                    if getgenv().AutoStoreFruit then
                        pcall(function()
                            local fruitTool = char:FindFirstChild(currentFruitName) or backpack:FindFirstChild(currentFruitName)
                            if fruitTool then
                                ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", storeName, fruitTool)
                                StatusLabel.Text = "Status: Stored [" .. currentFruitName .. "]"
                                sendFruitWebhook(currentFruitName)
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
        if not _G.IsFarming then
            StatusLabel.Text = "Status: Waiting / Checking Server..."
            StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            emptyCheckCount = emptyCheckCount + 1
            if emptyCheckCount >= 3 and getgenv().PirateRaid == false and getgenv().Factory == false then
                _G.Hopserver = true
            end
        end
    end
end

task.spawn(function()
    task.wait(2)
    while task.wait(0.3) do
        scanAndStoreFruits()
    end
end)
