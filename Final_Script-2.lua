-- ============================================================
--               SERVICES & LOCAL VARIABLES
-- ============================================================

local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = game.Players.LocalPlayer
local isSpamming = false
local keyOrder = {"Z", "X", "C", "V", "F"}

-- ============================================================
--               FLUENT UI LOADER
-- ============================================================

local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/taioccho/sexmocbuom/refs/heads/main/Fluent.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Auto Spam Skill",
    SubTitle = "Custom Multi-Skills",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 520),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

task.wait(0.5)

-- ============================================================
--               TAB 1: SELECT SKILL (Pasted Content)
-- ============================================================

local MainTab = Window:AddTab({
    Title = "Select Skill",
    Icon = "sword"
})

local Options = Fluent.Options

-- Helper: Equip weapon by name
local function EquipWeapon(weaponName)
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local tool = LocalPlayer.Backpack:FindFirstChild(weaponName)
        if tool then
            humanoid:EquipTool(tool)
        end
    end
end

-- Helper: Find weapon by ToolTip
local function weaponSc(weaponToolTip)
    for _, v in pairs(LocalPlayer.Backpack:GetChildren()) do
        if v:IsA("Tool") and v.ToolTip == weaponToolTip then
            EquipWeapon(v.Name)
            return v.Name
        end
    end
    for _, v in pairs(LocalPlayer.Character:GetChildren()) do
        if v:IsA("Tool") and v.ToolTip == weaponToolTip then
            return v.Name
        end
    end
    return nil
end

-- Helper: Press a key
local function pressKey(key)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game)
end

-- Main spam loop (isSpamming replaces getgenv().SeaSkill)
task.spawn(function()
    while true do
        if isSpamming then
            local selectedWeapons = Options.MultiWeapons.Value
            local weaponList = {}

            for weapon, active in pairs(selectedWeapons) do
                if active then
                    table.insert(weaponList, weapon)
                end
            end

            if #weaponList > 0 then
                for _, weaponType in ipairs(weaponList) do
                    if not isSpamming then break end

                    local targetSkills = {}
                    if weaponType == "Melee" then
                        targetSkills = Options.MeleeSkills.Value
                    elseif weaponType == "Blox Fruit" then
                        targetSkills = Options.FruitSkills.Value
                    elseif weaponType == "Sword" then
                        targetSkills = Options.SwordSkills.Value
                    elseif weaponType == "Gun" then
                        targetSkills = Options.GunSkills.Value
                    end

                    local keyList = {}
                    for _, key in ipairs(keyOrder) do
                        if targetSkills[key] then
                            table.insert(keyList, key)
                        end
                    end

                    if #keyList > 0 then
                        weaponSc(weaponType)
                        task.wait(0.15)
                        for _, key in ipairs(keyList) do
                            if not isSpamming then break end
                            pressKey(key)
                            task.wait(0.15)
                        end
                    end
                end
            else
                task.wait(0.5)
            end
        end
        task.wait(0.1)
    end
end)

-- UI Elements for Select Skill Tab
local WeaponDropdown = MainTab:AddDropdown("MultiWeapons", {
    Title = "Select Weapons to Spam",
    Values = {"Melee", "Blox Fruit", "Sword", "Gun"},
    Multi = true,
    Default = {"Melee"}
})

local MeleeSkills = MainTab:AddDropdown("MeleeSkills", {
    Title = "Melee Skills",
    Values = {"Z", "X", "C"},
    Multi = true,
    Default = {"Z", "X", "C"}
})

local FruitSkills = MainTab:AddDropdown("FruitSkills", {
    Title = "Blox Fruit Skills",
    Values = {"Z", "X", "C", "V", "F"},
    Multi = true,
    Default = {"Z", "X", "C", "V", "F"}
})

local SwordSkills = MainTab:AddDropdown("SwordSkills", {
    Title = "Sword Skills",
    Values = {"Z", "X"},
    Multi = true,
    Default = {"Z", "X"}
})

local GunSkills = MainTab:AddDropdown("GunSkills", {
    Title = "Gun Skills",
    Values = {"Z", "X"},
    Multi = true,
    Default = {"Z", "X"}
})

-- ============================================================
--               TAB 2: SEA EVENT
-- ============================================================

local Tabs = { Sea = Window:AddTab({ Title = "Sea Event", Icon = "ship" }) }

-- ============================================================
--            ZONE DROPDOWN
-- ============================================================

local ListSeaZone = {'Zone 1','Zone 2','Zone 3','Zone 4','Zone 5','Zone 6'}
local zoneselect = Tabs.Sea:AddDropdown('zoneselect', {
    Title = 'Select Zone',
    Values = ListSeaZone,
    Multi = false,
    Default = false,
})
zoneselect:OnChanged(function(p771)
    getgenv().SelectedZone = p771
end)

-- ============================================================
--            BOAT DROPDOWN
-- ============================================================

local ListSeaBoat = {
    'Guardian','PirateGrandBrigade','MarineGrandBrigade',
    'PirateBrigade','MarineBrigade','PirateSloop','MarineSloop','BeastHunter',
}
local selectthuyen = Tabs.Sea:AddDropdown('selectthuyen', {
    Title = 'Select Boat',
    Values = ListSeaBoat,
    Multi = false,
    Default = false,
})
selectthuyen:OnChanged(function(p772)
    getgenv().SelectedBoat = p772
end)

-- ============================================================
--            SEA EVENT DROPDOWN
-- ============================================================

local ListSeaEvent = {
    'Ghost Ship','Pirate Brigade','Pirate Grand Brigade',
    'Terror Shark','Sea Beast','Leviathan','Kitsune',
}
local seaeventselect = Tabs.Sea:AddDropdown('seaeventselect', {
    Title = 'Select Sea Event',
    Values = ListSeaEvent,
    Multi = false,
    Default = false,
})
seaeventselect:OnChanged(function(val)
    getgenv().SelectedSeaEvent = val
end)

-- ============================================================
--            AUTO SEA EVENT TOGGLE (Start Farm)
-- ============================================================

Tabs.Sea:AddToggle('Toggle', {
    Title = 'Auto Sea Event',
    Default = false,
}):OnChanged(function(p791)
    getgenv().SailBoat = p791
    StopTween(getgenv().SailBoat)
end)

-- ============================================================
--            ZONE CFRAME UPDATER LOOP (Speed fixed = 325)
-- ============================================================

getgenv().SpeedBoat = 325  -- Fixed boat tween speed

spawn(function()
    pcall(function()
        while wait() do
            local z = getgenv().SelectedZone
            if z == 'Zone 1' then
                CFrameSelectedZone = CFrame.new(-21998.375, 30.0006084, -682.309143, 0.120013528, 0.00690158736, 0.99274826, -0.0574118942, 0.998350561, -2.365092e-10, -0.991110802, -0.0569955558, 0.120211802)
            elseif z == 'Zone 2' then
                CFrameSelectedZone = CFrame.new(-26779.5215, 30.0005474, -822.858032, 0.307457417, 0.019647358, 0.951358974, -0.0637726262, 0.997964442, -4.15334017e-10, -0.949422479, -0.0606706589, 0.308084518)
            elseif z == 'Zone 3' then
                CFrameSelectedZone = CFrame.new(-31171.957, 30.0001011, -2256.93774, 0.37637493, 0.0150483791, 0.926345229, -0.0399504974, 0.999201655, 2.70896673e-11, -0.925605655, -0.0370079502, 0.376675636)
            elseif z == 'Zone 4' then
                CFrameSelectedZone = CFrame.new(-34054.6875, 30.2187767, -2560.12012, 0.0935864747, -0.00122954219, 0.995610416, 0.0624034069, 0.998040259, -0.00463332096, -0.993653536, 0.062563099, 0.0934797972)
            elseif z == 'Zone 5' then
                CFrameSelectedZone = CFrame.new(-38887.5547, 30.0004578, -2162.99023, -0.188895494, -0.00704088295, 0.981971979, -0.0372481011, 0.999306023, -1.39882339e-9, -0.981290519, -0.0365765914, -0.189026669)
            elseif z == 'Zone 6' then
                CFrameSelectedZone = CFrame.new(-44541.7617, 30.0003204, -1244.8584, -0.0844199061, -0.00553312758, 0.9964149, -0.0654025897, 0.997858942, 2.02319411e-10, -0.99428153, -0.0651681125, -0.0846010372)
            end
        end
    end)
end)

-- ============================================================
--            TWEEN BOAT FUNCTION (Speed 310, Anti-Fall, NoClip)
-- ============================================================

local TweenService = game:GetService("TweenService")

-- NoClip loop (active while SailBoat)
spawn(function()
    while task.wait(0.1) do
        if getgenv().SailBoat then
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end
    end
end)

-- Anti-Fall: keep player on boat seat while sailing
spawn(function()
    while task.wait(0.5) do
        if getgenv().SailBoat then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and hrp.Position.Y < 20 then
                    hrp.CFrame = hrp.CFrame * CFrame.new(0, 10, 0)
                end
            end)
        end
    end
end)

-- TPB: Tween Boat to Position at fixed speed 310
function TPB(targetCFrame, vehicleSeat)
    local boat = vehicleSeat and vehicleSeat.Parent
    if not boat then return end
    local distance = (targetCFrame.Position - vehicleSeat.CFrame.Position).Magnitude
    local speed = 310
    local time = distance / speed
    local tween = TweenService:Create(vehicleSeat, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
    tween:Play()
    return tween
end

-- topos: Tween player HRP to CFrame
function topos(cf)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local distance = (cf.Position - hrp.Position).Magnitude
    local tween = TweenService:Create(hrp, TweenInfo.new(distance / 310, Enum.EasingStyle.Linear), {CFrame = cf})
    tween:Play()
    return tween
end

-- fastpos: Instant teleport
function fastpos(cf)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = cf end
end

-- StopTween helper
function StopTween(active)
    if not active then
        if stopboat then pcall(function() stopboat:Stop() end) end
        if stoppos then pcall(function() stoppos:Stop() end) end
    end
end

-- ============================================================
--            BOAT / ESP / UTILITY FUNCTIONS
-- ============================================================

function CheckBoat()
    local _Boats = game:GetService('Workspace'):FindFirstChild('Boats')
    local _SelectedBoat = getgenv().SelectedBoat
    if not (_Boats and _SelectedBoat) then return false end
    for _, v in pairs(_Boats:GetChildren()) do
        if v.Name == _SelectedBoat and v:FindFirstChild('MyBoatEsp') then
            return v
        end
    end
    return false
end

function CheckSeaBeast()
    local _SeaBeasts = game:GetService('Workspace'):FindFirstChild('SeaBeasts')
    if not _SeaBeasts then return false end
    for _, v in ipairs(_SeaBeasts:GetChildren()) do
        local h = v:FindFirstChild('Humanoid')
        if h and v:FindFirstChild('HumanoidRootPart') and h.Health > 0 then
            return true
        end
    end
    return false
end

function CheckShark()
    local Enemies = game:GetService('Workspace'):FindFirstChild('Enemies')
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    if not (Enemies and hrp) then return false end
    for _, v in pairs(Enemies:GetChildren()) do
        local h = v:FindFirstChild('Humanoid')
        local r = v:FindFirstChild('HumanoidRootPart')
        if v.Name == 'Shark' and h and r and h.Health > 0 and (r.Position - hrp.Position).Magnitude <= 200 then
            return true
        end
    end
    return false
end

function CheckPiranha()
    local Enemies = game:GetService('Workspace'):FindFirstChild('Enemies')
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    if not (Enemies and hrp) then return false end
    for _, v in pairs(Enemies:GetChildren()) do
        local h = v:FindFirstChild('Humanoid')
        local r = v:FindFirstChild('HumanoidRootPart')
        if v.Name == 'Piranha' and h and r and h.Health > 0 and (r.Position - hrp.Position).Magnitude <= 200 then
            return true
        end
    end
    return false
end

function AddEsp(name, parent)
    if parent and parent:IsA('Instance') then
        local bg = Instance.new('BillboardGui')
        local tl = Instance.new('TextLabel')
        bg.Name = name
        bg.Parent = parent
        bg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        bg.AlwaysOnTop = true
        bg.Size = UDim2.new(0, 200, 0, 50)
        bg.StudsOffset = Vector3.new(0, 2.5, 0)
        tl.Parent = bg
        tl.BackgroundTransparency = 1
        tl.Size = UDim2.new(1, 0, 1, 0)
        tl.Font = Enum.Font.GothamBold
        tl.TextColor3 = Color3.new(1, 1, 1)
        tl.TextSize = 15
        tl.Text = 'YOUR BOAT IS HERE\u{2193}'
        return bg
    end
end

function GetCountMaterials(name)
    local inv = game:GetService('ReplicatedStorage').Remotes.CommF_:InvokeServer('getInventory')
    for _, v in pairs(inv) do
        if v.Name == name then return v.Count end
    end
    return 0
end

local function u903(key, hold)
    game:service('VirtualInputManager'):SendKeyEvent(true, key, false, game)
    task.wait(hold or 0.1)
    game:service('VirtualInputManager'):SendKeyEvent(false, key, false, game)
end

-- ============================================================
--            SKILLAIMBOT (from Banana Cat Hub Free)
-- ============================================================

Skillaimbot = false
AimBotSkillPosition = nil

local v962 = getrawmetatable(game)
local ___namecall = v962.__namecall
setreadonly(v962, false)

v962.__namecall = newcclosure(function(...)
    local v964 = getnamecallmethod()
    local v965 = {...}
    if tostring(v964) ~= 'FireServer' or
       tostring(v965[1]) ~= 'RemoteEvent' or
       tostring(v965[2]) == 'true' or
       tostring(v965[2]) == 'false' or
       not Skillaimbot then
        return ___namecall(...)
    end
    v965[2] = AimBotSkillPosition
    return ___namecall(unpack(v965))
end)

-- ============================================================
--            MAIN SAIL LOOP
-- ============================================================

spawn(function()
    while wait(0.2) do
        pcall(function()
            if not getgenv().SailBoat then return end
            local Enemies = game:GetService('Workspace').Enemies
            local function anyEnemy()
                return (CheckShark() and getgenv().AutoKillShark)
                    or (Enemies:FindFirstChild('Terrorshark') and getgenv().AutoTerrorshark)
                    or (CheckPiranha() and getgenv().AutoKillPiranha)
                    or (Enemies:FindFirstChild('Fish Crew Member') and getgenv().AutoKillFishCrew)
                    or (Enemies:FindFirstChild('FishBoat') and getgenv().RelzFishBoat)
                    or (Enemies:FindFirstChild('PirateBrigade') and getgenv().RelzPirateBrigade)
                    or (Enemies:FindFirstChild('PirateGrandBrigade') and getgenv().RelzPirateGrandBrigade)
                    or (CheckSeaBeast() and getgenv().AutoSeaBest)
            end

            if CheckBoat() then
                for _, v822 in pairs(game:GetService('Workspace').Boats:GetChildren()) do
                    if v822.Name == getgenv().SelectedBoat and v822:FindFirstChild('MyBoatEsp') then
                        local hum = LocalPlayer.Character:WaitForChild('Humanoid')
                        if hum.Sit ~= false then
                            repeat
                                wait()
                                stopboat = TPB(CFrameSelectedZone, v822.VehicleSeat)
                            until anyEnemy() or hum.Sit == false or not getgenv().SailBoat
                            if stopboat then stopboat:Stop() end
                            game:GetService('VirtualInputManager'):SendKeyEvent(true, 32, false, game)
                            wait(0.1)
                            game:GetService('VirtualInputManager'):SendKeyEvent(false, 32, false, game)
                        elseif anyEnemy() then
                            if stoppos then stoppos:Stop() end
                        else
                            stoppos = topos(v822.VehicleSeat.CFrame * CFrame.new(0, 1, 0))
                        end
                    end
                end
            else
                local BuyBoatCFrame = CFrame.new(-16927.451171875, 9.0863618850708, 433.8642883300781)
                if (BuyBoatCFrame.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 1000 then
                    local buyb = topos(BuyBoatCFrame)
                else
                    topos(CFrame.new(-16224, 9, 439))
                end
                if (BuyBoatCFrame.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 10 then
                    if buyb then buyb:Stop() end
                    game:GetService('ReplicatedStorage').Remotes.CommF_:InvokeServer('BuyBoat', getgenv().SelectedBoat)
                    for _, v826 in pairs(game:GetService('Workspace').Boats:GetChildren()) do
                        if v826.Name == getgenv().SelectedBoat and (v826.VehicleSeat.CFrame.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 100 then
                            AddEsp('MyBoatEsp', v826)
                        end
                    end
                end
            end
        end)
    end
end)

-- Exit boat when enemy detected
spawn(function()
    pcall(function()
        while task.wait(0.2) do
            if getgenv().SailBoat then
                local Enemies = game:GetService('Workspace').Enemies
                local function anyEnemy()
                    return (CheckShark() and getgenv().AutoKillShark)
                        or (Enemies:FindFirstChild('Terrorshark') and getgenv().AutoTerrorshark)
                        or (CheckPiranha() and getgenv().AutoKillPiranha)
                        or (Enemies:FindFirstChild('Fish Crew Member') and getgenv().AutoKillFishCrew)
                        or (Enemies:FindFirstChild('FishBoat') and getgenv().RelzFishBoat)
                        or (Enemies:FindFirstChild('PirateBrigade') and getgenv().RelzPirateBrigade)
                        or (Enemies:FindFirstChild('PirateGrandBrigade') and getgenv().RelzPirateGrandBrigade)
                        or (CheckSeaBeast() and getgenv().AutoSeaBest)
                end
                if anyEnemy() then
                    local hum = LocalPlayer.Character:FindFirstChild('Humanoid')
                    if hum and hum.Sit then
                        game:GetService('VirtualInputManager'):SendKeyEvent(true, 32, false, game)
                        task.wait(0.1)
                        game:GetService('VirtualInputManager'):SendKeyEvent(false, 32, false, game)
                    end
                end
            end
        end
    end)
end)

-- ============================================================
--            TOGGLES: SHARK / PIRANHA / FISH CREW
-- ============================================================

Tabs.Sea:AddToggle('Toggle', {
    Title = 'Auto Shark',
    Default = false,
}):OnChanged(function(p853)
    getgenv().AutoKillShark = p853
    StopTween(getgenv().AutoKillShark)
end)
Tabs.Sea:AddToggle('Toggle', {
    Title = 'Auto Piranha',
    Default = false,
}):OnChanged(function(p854)
    getgenv().AutoKillPiranha = p854
    StopTween(getgenv().AutoKillPiranha)
end)
Tabs.Sea:AddToggle('Toggle', {
    Title = 'Auto Fish Crew',
    Default = false,
}):OnChanged(function(p855)
    getgenv().AutoKillFishCrew = p855
    StopTween(getgenv().AutoKillFishCrew)
end)

-- Shark / Piranha / Fish Crew kill loop
spawn(function()
    while task.wait(0.1) do
        pcall(function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
            if not hrp then return end
            local enemies = game:GetService('Workspace').Enemies:GetChildren()
            local Pos = CFrame.new(0, -2, 3.5)

            if getgenv().AutoKillShark and World3 then
                for _, v in pairs(enemies) do
                    if v.Name == 'Shark' and v:FindFirstChild('Humanoid') and v:FindFirstChild('HumanoidRootPart') and v.Humanoid.Health > 0 and (v.HumanoidRootPart.Position - hrp.Position).Magnitude <= 500 then
                        repeat
                            task.wait(0.1)
                            v.HumanoidRootPart.Size = Vector3.new(50,50,50)
                            v.HumanoidRootPart.CanCollide = false
                            topos(v.HumanoidRootPart.CFrame * Pos)
                        until not getgenv().AutoKillShark or not v.Parent or v.Humanoid.Health <= 0
                    end
                end
            end

            if getgenv().AutoKillPiranha and World3 then
                for _, v in pairs(enemies) do
                    if v.Name == 'Piranha' and v:FindFirstChild('Humanoid') and v:FindFirstChild('HumanoidRootPart') and v.Humanoid.Health > 0 and (v.HumanoidRootPart.Position - hrp.Position).Magnitude <= 500 then
                        repeat
                            task.wait(0.1)
                            v.HumanoidRootPart.Size = Vector3.new(50,50,50)
                            v.HumanoidRootPart.CanCollide = false
                            topos(v.HumanoidRootPart.CFrame * Pos)
                        until not getgenv().AutoKillPiranha or not v.Parent or v.Humanoid.Health <= 0
                    end
                end
            end

            if getgenv().AutoKillFishCrew and World3 then
                for _, v in pairs(enemies) do
                    if v.Name == 'Fish Crew Member' and v:FindFirstChild('Humanoid') and v:FindFirstChild('HumanoidRootPart') and v.Humanoid.Health > 0 and (v.HumanoidRootPart.Position - hrp.Position).Magnitude <= 500 then
                        repeat
                            task.wait(0.1)
                            v.HumanoidRootPart.Size = Vector3.new(50,50,50)
                            v.HumanoidRootPart.CanCollide = false
                            topos(v.HumanoidRootPart.CFrame * Pos)
                        until not getgenv().AutoKillFishCrew or not v.Parent or v.Humanoid.Health <= 0
                    end
                end
            end
        end)
    end
end)

-- ============================================================
--            TOGGLES: GHOST SHIP / PIRATE BRIGADE / SEA BEAST
-- ============================================================

Tabs.Sea:AddToggle('Toggle', {
    Title = 'Auto Ghost Ship',
    Default = false,
}):OnChanged(function(p878)
    getgenv().RelzFishBoat = p878
    StopTween(getgenv().RelzFishBoat)
    if not getgenv().RelzFishBoat then
        isSpamming = false
        Skillaimbot = false
    end
end)

Tabs.Sea:AddToggle('Toggle', {
    Title = 'Auto Pirate Brigade',
    Default = false,
}):OnChanged(function(p879)
    getgenv().RelzPirateBrigade = p879
    StopTween(getgenv().RelzPirateBrigade)
end)

Tabs.Sea:AddToggle('Toggle', {
    Title = 'Auto Pirate Grand Brigade',
    Default = false,
}):OnChanged(function(p880)
    getgenv().RelzPirateGrandBrigade = p880
    StopTween(getgenv().RelzPirateGrandBrigade)
end)

-- Ghost Ship (FishBoat) attack loop
spawn(function()
    while task.wait(0.1) do
        pcall(function()
            if not getgenv().RelzFishBoat then return end
            for _, v884 in pairs(game:GetService('Workspace').Enemies:GetChildren()) do
                if v884.Name == 'FishBoat' and v884:FindFirstChild('Engine') then
                    repeat
                        task.wait(0.1)
                        local target = v884.Engine.CFrame * CFrame.new(0, 10, 0)
                        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
                        if hrp and (v884.Engine.Position - hrp.Position).Magnitude <= 50 then
                            isSpamming = true
                        else
                            isSpamming = false
                        end
                        if hrp and (hrp.Position - target.Position).Magnitude > 2 then
                            topos(target)
                        end
                        Skillaimbot = true
                        AimBotSkillPosition = v884.Engine.Position
                    until not v884.Parent or v884.Health.Value <= 0 or not (game:GetService('Workspace').Enemies:FindFirstChild('FishBoat') and v884:FindFirstChild('Engine') and getgenv().RelzFishBoat)
                    Skillaimbot = false
                    isSpamming = false
                end
            end
        end)
    end
end)

Tabs.Sea:AddToggle('Toggle', {
    Title = 'Auto Terror Shark',
    Default = false,
}):OnChanged(function(p887)
    getgenv().AutoTerrorshark = p887
    StopTween(getgenv().AutoTerrorshark)
end)

Tabs.Sea:AddToggle('Toggle', {
    Title = 'Auto Sea Beast',
    Default = false,
}):OnChanged(function(p888)
    getgenv().AutoSeaBest = p888
    StopTween(getgenv().AutoSeaBest)
    if not getgenv().AutoSeaBest then
        isSpamming = false
        Skillaimbot = false
    end
end)

-- Sea Beast attack loop
task.spawn(function()
    while task.wait(0.5) do
        if getgenv().AutoSeaBest then
            pcall(function()
                local ws = game:GetService('Workspace')
                if not ws:FindFirstChild('SeaBeasts') then return end
                Skillaimbot = false
                isSpamming = false
                for _, v900 in pairs(ws.SeaBeasts:GetChildren()) do
                    if v900:FindFirstChild('HumanoidRootPart') and v900:FindFirstChild('Humanoid') and v900.Humanoid.Health > 0 then
                        local CFrameSeaBeast = v900.HumanoidRootPart.CFrame * CFrame.new(0, 400, 0)
                        local hrp = LocalPlayer.Character.HumanoidRootPart
                        if (CFrameSeaBeast.Position - hrp.CFrame.Position).Magnitude > 50 then
                            isSpamming = false
                        else
                            isSpamming = true
                        end
                        Skillaimbot = true
                        AimBotSkillPosition = v900.HumanoidRootPart.CFrame.Position
                        topos(CFrameSeaBeast)
                        break
                    end
                end
            end)
        end
    end
end)

-- ============================================================
--            SEA SKILL HANDLER LOOP (isSpamming → triggers Tab 1 spam)
-- ============================================================

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            if isSpamming then
                local _LP = LocalPlayer
                local _BP = _LP.Backpack
                local DoneSkillFruit, DoneSkillMelee, DoneSkillSword, DoneSkillGun = false, false, false, false

                if getgenv().UseSeaFruitSkill and not DoneSkillFruit then
                    for _, v in pairs(_BP:GetChildren()) do
                        if v:IsA('Tool') and v.ToolTip == 'Blox Fruit' then
                            _LP.Character.Humanoid:EquipTool(v)
                        end
                    end
                    if getgenv().SkillFruitZ then u903('Z', getgenv().SeaHoldSKillZ or 0) end
                    if getgenv().SkillFruitX then u903('X', getgenv().SeaHoldSKillX or 0) end
                    if getgenv().SkillFruitC then u903('C', getgenv().SeaHoldSKillC or 0) end
                    if getgenv().SkillFruitV then u903('V', getgenv().SeaHoldSKillV or 0) end
                    if getgenv().SkillFruitF then u903('F', getgenv().SeaHoldSKillF or 0) end
                    DoneSkillFruit = true
                end

                if getgenv().UseSeaMeleeSkill and not DoneSkillMelee then
                    for _, v in pairs(_BP:GetChildren()) do
                        if v:IsA('Tool') and v.ToolTip == 'Melee' then
                            _LP.Character.Humanoid:EquipTool(v)
                        end
                    end
                    if getgenv().SkillMeleeZ then u903('Z', 0) end
                    if getgenv().SkillMeleeX then u903('X', 0) end
                    if getgenv().SkillMeleeC then u903('C', 0) end
                    DoneSkillMelee = true
                end

                if getgenv().UseSeaSwordSkill and not DoneSkillSword then
                    for _, v in pairs(_BP:GetChildren()) do
                        if v:IsA('Tool') and v.ToolTip == 'Sword' then
                            _LP.Character.Humanoid:EquipTool(v)
                        end
                    end
                    if getgenv().SkillSwordZ then u903('Z', 0) end
                    if getgenv().SkillSwordX then u903('X', 0) end
                    DoneSkillSword = true
                end

                if getgenv().UseSeaGunSkill and not DoneSkillGun then
                    for _, v in pairs(_BP:GetChildren()) do
                        if v:IsA('Tool') and v.ToolTip == 'Gun' then
                            _LP.Character.Humanoid:EquipTool(v)
                        end
                    end
                    if getgenv().SkillGunZ then u903('Z', 0.1) end
                    if getgenv().SkillGunX then u903('X', 0.1) end
                    DoneSkillGun = true
                end

                task.wait(0.5)
            end
        end)
    end
end)

-- ============================================================
--            ROCK PENETRATION LOOP
-- ============================================================

spawn(function()
    while task.wait(1) do
        if getgenv().SailBoat then
            pcall(function()
                for _, boat in ipairs(game:GetService('Workspace').Boats:GetChildren()) do
                    for _, part in ipairs(boat:GetDescendants()) do
                        if part:IsA('BasePart') then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end
    end
end)

-- ============================================================
--            SECTION: KITSUNE
-- ============================================================

Tabs.Sea:AddParagraph({
    Title = 'Kitsune Event',
    Content = string.rep('-', 21),
})

Tabs.Sea:AddToggle('Toggle', {
    Title = 'Teleport To Kitsune Island',
    Default = false,
}):OnChanged(function(p922)
    getgenv().TweenToKitsune = p922
    StopTween(getgenv().TweenToKitsune)
end)
spawn(function()
    while wait() do
        local v923 = getgenv().TweenToKitsune and game:GetService('Workspace').Map:FindFirstChild('KitsuneIsland')
        if v923 then
            local _NeonShrinePart = v923.ShrineActive.NeonShrinePart
            topos(_NeonShrinePart.CFrame * CFrame.new(0, 0, 10))
        end
    end
end)

Tabs.Sea:AddToggle('Toggle', {
    Title = 'Auto Summon Soul Ember',
    Default = false,
}):OnChanged(function(p925)
    getgenv().SummonKitsume = p925
end)
spawn(function()
    while task.wait(0.6) do
        if getgenv().SummonKitsume and World3 then
            pcall(function()
                local rs = game:GetService('ReplicatedStorage')
                local rf = rs:FindFirstChild('Modules') and rs.Modules:FindFirstChild('Net') and rs.Modules.Net:FindFirstChild('RF/KitsuneStatuePray')
                if rf then rf:InvokeServer() end
            end)
        end
    end
end)

Tabs.Sea:AddToggle('Toggle', {
    Title = 'Auto Collect Azure Wisp',
    Default = false,
}):OnChanged(function(p928)
    getgenv().CollectAzure = p928
    StopTween(getgenv().CollectAzure)
end)
task.spawn(function()
    while task.wait(1) do
        if getgenv().CollectAzure then
            pcall(function()
                local ws = game:GetService('Workspace')
                local _AttachedAzureEmber = ws:FindFirstChild('AttachedAzureEmber')
                local _EmberTemplate = ws:FindFirstChild('EmberTemplate')
                if _AttachedAzureEmber and _EmberTemplate then
                    local _Part = _EmberTemplate:FindFirstChild('Part')
                    if _Part and (LocalPlayer.Character.HumanoidRootPart.Position - _Part.Position).Magnitude > 10 then
                        fastpos(_Part.CFrame)
                    end
                end
            end)
        end
    end
end)

Tabs.Sea:AddSlider('Slider', {
    Title = 'Set Azure Ember',
    Default = 20,
    Min = 0,
    Max = 25,
    Rounding = 5,
    Callback = function(p932)
        getgenv().SetToTradeAureEmber = p932
    end,
})

Tabs.Sea:AddToggle('Toggle', {
    Title = 'Auto Trade Azure Ember',
    Default = false,
    Callback = function(p933)
        getgenv().TradeAureEmber = p933
    end,
})
task.spawn(function()
    while task.wait(3) do
        if getgenv().TradeAureEmber then
            pcall(function()
                if GetCountMaterials('Azure Ember') >= getgenv().SetToTradeAureEmber then
                    game:GetService('ReplicatedStorage').Modules.Net:FindFirstChild('RF/KitsuneStatuePray'):InvokeServer()
                    game:GetService('ReplicatedStorage').Remotes.CommF_:InvokeServer('KitsuneStatuePray')
                    task.wait(5)
                end
            end)
        end
    end
end)

Tabs.Sea:AddButton({
    Title = 'Trade Azure Wisp',
    Callback = function()
        game:GetService('ReplicatedStorage'):WaitForChild('Modules'):WaitForChild('Net'):WaitForChild('RF/KitsuneStatuePray'):InvokeServer()
    end,
})

-- ============================================================
--            SECTION: LEVIATHAN
-- ============================================================

Tabs.Sea:AddParagraph({
    Title = 'Leviathan Event',
    Content = string.rep('-', 21),
})

Tabs.Sea:AddButton({
    Title = 'Buy Spy',
    Callback = function()
        game:GetService('ReplicatedStorage').Remotes.CommF_:InvokeServer('InfoLeviathan', '2')
    end,
})

Tabs.Sea:AddToggle('Toggle', {
    Title = 'Teleport To Frozen Dimension',
    Default = false,
}):OnChanged(function(p940)
    getgenv().AutoFrozenDimension = p940
end)
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local v941 = getgenv().AutoFrozenDimension and World3 and game:GetService('Workspace').Map:FindFirstChild('FrozenDimension')
            if v941 then
                local pos = v941.Center.Position
                if (LocalPlayer.Character.HumanoidRootPart.Position - Vector3.new(pos.X, 500, pos.Z)).Magnitude > 10 then
                    topos(CFrame.new(pos.X, 500, pos.Z))
                end
            end
        end)
    end
end)

Tabs.Sea:AddToggle('Toggle', {
    Title = 'Auto Attack Leviathan',
    Default = false,
}):OnChanged(function(p943)
    getgenv().KillLevi = p943
end)
task.spawn(function()
    while task.wait(0.5) do
        if getgenv().KillLevi and World3 then
            pcall(function()
                for _, v947 in pairs(game:GetService('Workspace').SeaBeasts:GetChildren()) do
                    if v947.Name == 'Leviathan' and v947:FindFirstChild('HumanoidRootPart') then
                        task.wait(0.2)
                        if (LocalPlayer.Character.HumanoidRootPart.Position - v947.HumanoidRootPart.Position).Magnitude > 10 then
                            topos(v947.HumanoidRootPart.CFrame * CFrame.new(0, 500, 0))
                        end
                        -- Trigger skillaimbot on Leviathan
                        isSpamming = true
                        AimBotSkillPosition = v947.HumanoidRootPart
                        Skillaimbot = true
                        task.wait(0.5)
                        isSpamming = false
                        Skillaimbot = false
                    end
                end
            end)
        end
    end
end)
