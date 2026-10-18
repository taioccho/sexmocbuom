Settings = Settings or {}
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local FolderName = "Taigen Hub"
local SaveFileNameGame = "-KaitunLevi.json"
local SaveFileName = LocalPlayer.Name .. SaveFileNameGame

function SaveSettings(b, t, A)
	if A ~= nil then
		Settings[b] = Settings[b] or {}
		Settings[b][t] = A
	elseif b ~= nil then
		Settings[b] = t
	end
	if not isfolder(FolderName) then
		makefolder(FolderName)
	end
	writefile(FolderName .. "/" .. SaveFileName, HttpService:JSONEncode(Settings))
end

if getgenv().Config then
	Settings = getgenv().Config
	SaveSettings()
end

function ReadSetting()
	local b, t = pcall(function()
		if not isfolder(FolderName) then
			makefolder(FolderName)
		end
		return HttpService:JSONDecode(readfile(FolderName .. "/" .. SaveFileName))
	end)
	if b then
		return t
	else
		SaveSettings()
		return ReadSetting()
	end
end

Settings = ReadSetting()
getgenv().Settings = Settings

local h = false
local lastJumpTick = 0

local function pressJump()
	local vim = VirtualInputManager
	vim:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
	task.wait(0.05)
	vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
end

getgenv().IsPlayerDead = function()
	local y = LocalPlayer
	if not y.Character or not y.Character:FindFirstChild("Humanoid") or y.Character.Humanoid.Health <= 0 then
		return true
	end
	return false
end

-- SetNoClip mới: bật/tắt noclip đúng cách, restore CanCollide khi tắt
function SetNoClip(enabled)
	getgenv().noclip = enabled
	local char = Players.LocalPlayer.Character
	if not char then return end
	local hrp  = char:FindFirstChild("HumanoidRootPart")
	local hum  = char:FindFirstChildOfClass("Humanoid")
	if enabled then
		-- Tắt collision toàn body
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	else
		-- Bật lại collision toàn body
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = true
			end
		end
		if hum then
			hum.PlatformStand = false
		end
		-- Xoá FloatForce nếu không còn cần (không đang tween)
		if hrp and hrp:FindFirstChild("FloatForce") then
			if not getgenv().Tween or getgenv().Tween.PlaybackState ~= Enum.PlaybackState.Playing then
				hrp.FloatForce:Destroy()
			end
		end
	end
end

-- Wrapper nội bộ dùng trong toTarget (giữ tên cũ để không vỡ chỗ khác)
local function setNoclip(char, value)
	SetNoClip(value)
end

function toTarget(targetCF, noOffset, NoTp)
	if typeof(targetCF) ~= "CFrame" then return end
	if tick() < lastJumpTick then return end

	local y = LocalPlayer
	local char = y.Character

	if IsPlayerDead() then
		if getgenv().Tween then
			getgenv().Tween:Pause()
			getgenv().Tween:Cancel()
		end
		repeat
			task.wait()
			if getgenv().Tween then
				getgenv().Tween:Pause()
				getgenv().Tween:Cancel()
			end
		until char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0
		task.wait(3)
		return
	end

	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp or hum.Health <= 0 then return end

	-- Reset về spawn gần hơn nếu có điểm spawn ngắn hơn đường hiện tại + 1000 stud buffer
	pcall(function()
		local spawnName = y.Data and y.Data:FindFirstChild("LastSpawnPoint")
			and y.Data.LastSpawnPoint.Value
		if not spawnName then return end
		local marines = workspace:FindFirstChild("_WorldOrigin")
			and workspace._WorldOrigin:FindFirstChild("PlayerSpawns")
			and workspace._WorldOrigin.PlayerSpawns:FindFirstChild("Marines")
		if not marines then return end
		local spawnPart = marines:FindFirstChild(spawnName)
		if not spawnPart then return end
		local distCurrentToTarget = (targetCF.Position - hrp.Position).Magnitude
		local distSpawnToTarget   = (targetCF.Position - spawnPart.Position).Magnitude
		if distSpawnToTarget < distCurrentToTarget - 1000 then
			hum.Health = 0
		end
	end)
	if hum.Health <= 0 then return end

	if hum.Sit then
		if getgenv().Tween then
			getgenv().Tween:Pause()
			getgenv().Tween:Cancel()
		end

		-- Tắt noclip và FloatForce để thoát ghế đúng cách
		setNoclip(char, false)
		if hrp:FindFirstChild("FloatForce") then
			hrp.FloatForce:Destroy()
		end
		if hrp:FindFirstChild("EffectsSY") then
			hrp.EffectsSY:Destroy()
		end

		-- Block loop StartHunt trong suốt 2s thoát ghế
		lastJumpTick = tick() + 2

		-- Nhảy lần 1
		pressJump()
		task.wait(1)
		-- Nhảy lần 2
		pressJump()
		task.wait(1)
		return
	end

	if not hrp:FindFirstChild("FloatForce") then
		local bv = Instance.new("BodyVelocity")
		bv.Name = "FloatForce"
		bv.Velocity = Vector3.new(0, 0, 0)
		bv.MaxForce = Vector3.new(100000, 100000, 100000)
		bv.P = 10000
		bv.Parent = hrp
	end

	local hpPercent = hum.Health / hum.MaxHealth
	if hpPercent < 0.4 then
		h = true
	elseif hpPercent > 0.6 then
		h = false
	end

	local dist = (targetCF.Position - hrp.Position).Magnitude

	if not NoTp and dist <= 150 and not h and not ReadyToDodge then
		if getgenv().Tween then
			getgenv().Tween:Pause()
			getgenv().Tween:Cancel()
		end
		hrp.CFrame = targetCF
		setNoclip(char, true)
		return
	end

	if dist <= 3 and not h and not ReadyToDodge then
		if getgenv().Tween then
			getgenv().Tween:Pause()
			getgenv().Tween:Cancel()
		end
		hrp.CFrame = targetCF
		setNoclip(char, true)
		return
	end

	local Z = 200
	local tweenInfo = TweenInfo.new(dist / Z, Enum.EasingStyle.Linear)

	local offsetCF = CFrame.new(0, 0, 0)
	if not noOffset then
		if ReadyToDodge then
			offsetCF = CFrame.new(0, 200, 0)
		elseif h then
			offsetCF = CFrame.new(0, 800, 0)
		end
	end

	if (Vector3.new(0, hrp.Position.Y, 0) - Vector3.new(0, -60, 0)).Magnitude <= 60 then
		hrp.CFrame = hrp.CFrame * CFrame.new(0, 20, 0)
	end

	if getgenv().Tween then
		getgenv().Tween:Pause()
		getgenv().Tween:Cancel()
	end

	getgenv().Tween = TweenService:Create(hrp, tweenInfo, {
		CFrame = targetCF * offsetCF
	})
	getgenv().Tween:Play()
	setNoclip(char, true)
end

local function getPlayerList()
	local list = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		table.insert(list, plr.Name)
	end
	return list
end

local function getBoatByOwner(ownerName)
	local boatsFolder = workspace:FindFirstChild("Boats")
	if not boatsFolder or not ownerName then
		return nil
	end
	for _, b in ipairs(boatsFolder:GetChildren()) do
		if b:IsA("Model") then
			local owner = b:FindFirstChild("Owner")
			local boatHum = b:FindFirstChild("Humanoid")
			if owner and tostring(owner.Value) == ownerName and boatHum and boatHum.Value > 0 then
				return b
			end
		end
	end
	return nil
end

local function getCannonStats(boat)
	if not boat then
		return 0, 0
	end
	local occupied = 0
	local total = 0
	for _, v in ipairs(boat:GetChildren()) do
		if v.Name == "Cannon" and v:FindFirstChild("Seat") then
			total = total + 1
			if v.Seat:FindFirstChild("SeatWeld") then
				occupied = occupied + 1
			end
		end
	end
	return occupied, total
end

local boatNoclipConnection = nil
local boatNoclipConn2 = nil

local function stopBoatTween()
	if getgenv().TweenBoat then
		pcall(function()
			getgenv().TweenBoat:Pause()
			getgenv().TweenBoat:Cancel()
			getgenv().TweenBoat:Destroy()
		end)
		getgenv().TweenBoat = nil
	end
	if boatNoclipConnection then
		boatNoclipConnection:Disconnect()
		boatNoclipConnection = nil
	end
end
function TweenBoat(TargetCF, Speed)
    if typeof(TargetCF) ~= "CFrame" then return end

    -- Cancel tween cũ
    if getgenv().TweenBoat then
        pcall(function()
            getgenv().TweenBoat:Pause()
            getgenv().TweenBoat:Cancel()
            getgenv().TweenBoat:Destroy()
        end)
        getgenv().TweenBoat = nil
    end

    local lp = Players.LocalPlayer
    local char = lp.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    local seat = hum.SeatPart
    if not seat or not seat:IsA("VehicleSeat") then return end

    local boatModel = seat:FindFirstAncestorOfClass("Model")
    if not boatModel then return end

    if boatNoclipConnection then
        boatNoclipConnection:Disconnect()
        boatNoclipConnection = nil
    end
    boatNoclipConnection = RunService.Stepped:Connect(function()
        if boatModel and boatModel.Parent then
            for _, part in ipairs(boatModel:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
        if char and char.Parent then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)

    local speedVal = tonumber(Speed) or 300
    local dist = (TargetCF.Position - seat.Position).Magnitude
    local tweenTime = dist / speedVal

    local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(seat, tweenInfo, { CFrame = TargetCF })
    getgenv().TweenBoat = tween
    tween:Play()
    -- Không Completed:Wait()
end

function FindLeviathan(speed)
    local locations = workspace:FindFirstChild("_WorldOrigin")
        and workspace._WorldOrigin:FindFirstChild("Locations")
    if locations and locations:FindFirstChild("Frozen Dimension") then
        stopBoatTween()
        return
    end

    local lp = Players.LocalPlayer
    local char = lp.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    local seat = hum.SeatPart
    if not seat or not seat:IsA("VehicleSeat") then return end

    local interval = 0.1
    local speedVal = speed or 300

    while task.wait(interval) do
        -- BREAK: tắt Start Hunt hoặc tắt Account Buy Boat → dừng ngay
        if not Settings["Start Hunt"] or not Settings["Account Buy Boat"] then
            stopBoatTween()
            break
        end

        local locs = workspace:FindFirstChild("_WorldOrigin")
            and workspace._WorldOrigin:FindFirstChild("Locations")
        if locs and locs:FindFirstChild("Frozen Dimension") then
            stopBoatTween()
            break
        end

        local curSeat = hum and hum.SeatPart
        if not curSeat or not curSeat:IsA("VehicleSeat") then
            stopBoatTween()
            break
        end

        -- Tính lại mỗi tick theo vị trí hiện tại của seat
        local targetCF = CFrame.new(
            curSeat.Position.X,
            curSeat.Position.Y,
            curSeat.Position.Z + (speedVal * interval)
        )

        TweenBoat(targetCF, speedVal)
    end
end

local function stopBoatTween2()
	if getgenv().TweenBoat2 then
		pcall(function()
			getgenv().TweenBoat2:Pause()
			getgenv().TweenBoat2:Cancel()
			getgenv().TweenBoat2:Destroy()
		end)
		getgenv().TweenBoat2 = nil
	end

	if boatNoclipConn2 then
		boatNoclipConn2:Disconnect()
		boatNoclipConn2 = nil
	end
end

function TweenBoat2(TargetCF, Speed)
	if typeof(TargetCF) ~= "CFrame" then return end

	stopBoatTween2()

	local lp = Players.LocalPlayer
	local char = lp.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end

	local seat = hum.SeatPart
	if not seat or not seat:IsA("VehicleSeat") then return end

	local boatModel = seat:FindFirstAncestorOfClass("Model")
	if not boatModel then return end

	boatNoclipConn2 = RunService.Stepped:Connect(function()
		if boatModel and boatModel.Parent then
			for _, part in ipairs(boatModel:GetDescendants()) do
				if part:IsA("BasePart") and part.CanCollide then
					part.CanCollide = false
				end
			end
		end
		if char and char.Parent then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") and part.CanCollide then
					part.CanCollide = false
				end
			end
		end
	end)

	local dist = (TargetCF.Position - seat.Position).Magnitude
	if dist <= 3 then
		seat.CFrame = TargetCF
		stopBoatTween2()
		return
	end

	local speedVal = tonumber(Speed) or 150
	local tweenTime = dist / speedVal
	local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(seat, tweenInfo, { CFrame = TargetCF })

	getgenv().TweenBoat2 = tween
	tween:Play()

	tween.Completed:Wait()

	if getgenv().TweenBoat2 == tween then
		stopBoatTween2()
	end
end

local function resolveAimVector()
    local aim = getgenv().AimPos
    if not aim then return nil end

    local t = typeof(aim)
    if t == "Vector3" then
        return aim
    elseif t == "CFrame" then
        return aim.Position
    elseif t == "Instance" then
        if aim:IsA("BasePart") then
            return aim.Position
        elseif aim:IsA("Model") then
            return aim:GetPivot().Position
        end
    end
    return nil
end

local function fixMobileTable(t, targetVec)
    for k, v in pairs(t) do
        local vt = typeof(v)
        if vt == "Vector3" then
            t[k] = targetVec
        elseif vt == "vector" then
            t[k] = vector.create(targetVec.X, targetVec.Y, targetVec.Z)
        elseif vt == "CFrame" then
            t[k] = CFrame.new(targetVec) * v.Rotation
        elseif vt == "table" then
            fixMobileTable(v, targetVec)
        end
    end
end

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local targetVec = resolveAimVector()

    if targetVec then
        if method == "FireServer" and typeof(self) == "Instance" and self.ClassName == "RemoteEvent" then
            if self.Name == "OnAnalyticsUpdate" or self.Name == "MessageDone" then 
                return oldNamecall(self, ...) 
            end

            local args = {...}
            local arg1str = tostring(args[1])
            
            if arg1str ~= "true" and arg1str ~= "false" then
                local t1 = typeof(args[1])
                if t1 == "vector" then
                    args[1] = vector.create(targetVec.X, targetVec.Y, targetVec.Z)
                elseif t1 == "Vector3" then
                    args[1] = targetVec
                elseif t1 == "CFrame" then
                    args[1] = CFrame.new(targetVec) * args[1].Rotation
                elseif t1 == "table" then
                    fixMobileTable(args[1], targetVec)
                end
                return oldNamecall(self, unpack(args))
            end

        elseif method == "InvokeServer" and typeof(self) == "Instance" and self.ClassName == "RemoteFunction" then
            local args = {...}
            local skill = args[1]
            if skill == "X" or skill == "Z" or skill == "C" or skill == "V" or skill == "F" then
                args[2] = targetVec
                if skill == "X" and getgenv().AimTarget then 
                    args[3] = getgenv().AimTarget 
                end
                return oldNamecall(self, unpack(args))
            end
        end
    end

    return oldNamecall(self, ...)
end)

local function equiptool(g)
    if g and (LocalPlayer:FindFirstChild("Backpack")) and (LocalPlayer.Backpack:FindFirstChild(g)) and not LocalPlayer.Character.Humanoid.Sit then
        LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild(g))
    end
end

local function NameWeapon(g, G)
    local function m(E)
        if not E then return nil end
        local l, Q, d = next, E:GetChildren()
        for E, E in l, Q, d do
            if E:IsA("Tool") and E.ToolTip == g then
                return G and E or E.Name
            end
        end
    end
    return m(LocalPlayer.Backpack) or (m(LocalPlayer.Character))
end

local function CheckCDSkillTransformation(V, H)
    if not V or not H then return nil end
    local mainGui = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("Main")
    local skillsGui = mainGui and mainGui:FindFirstChild("Skills")
    local toolSkills = skillsGui and skillsGui:FindFirstChild(V.Name)

    if not toolSkills then return nil end

    local B, C, J = next, toolSkills:GetChildren()
    for F, F in B, C, J do
        if F:IsA("Frame") then
            local isKeySelected = false
            if H[F.Name] == true then
                isKeySelected = true
            elseif type(H) == "table" then
                for _, keyName in pairs(H) do
                    if keyName == F.Name then
                        isKeySelected = true
                        break
                    end
                end
            end

            if
                F.Name ~= "Template"
                and not string.find(F.Title.Text, "Transformation")
                and isKeySelected
                and F.Title.TextColor3 == Color3.new(1, 1, 1)
                and (F.Cooldown.Size == UDim2.new(0, 0, 1, -1) or F.Cooldown.Size == UDim2.new(1, 0, 1, -1))
            then
                local holdValue = tonumber(Settings["Skill " .. F.Name .. " " .. V.ToolTip]) or 0.5
                return F, holdValue
            end
        end
    end
    return nil
end

local isCastingSkill = false

function UseSkill(weaponType)
    if isCastingSkill then return false end

    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Stun") and char.Stun.Value ~= 0 then return false end

    local weapon = NameWeapon(weaponType, true)
    if not weapon then return false end

    local skillsGui = LocalPlayer.PlayerGui:FindFirstChild("Main") and LocalPlayer.PlayerGui.Main:FindFirstChild("Skills")
    if not skillsGui then return false end

    if not skillsGui:FindFirstChild(weapon.Name) then
        equiptool(weapon.Name)
        return false
    end

    local skillFrame, holdDuration = CheckCDSkillTransformation(weapon, Settings["Select Skills " .. weapon.ToolTip])
    if skillFrame then
        local toolName = skillFrame.Parent.Name
        equiptool(toolName)

        if char and char:FindFirstChild(toolName) then
            local skillKey = skillFrame.Name
            local cooldownFrame = skillFrame:FindFirstChild("Cooldown")

            isCastingSkill = true

            task.spawn(function()
                VirtualInputManager:SendKeyEvent(true, skillKey, false, game)

                if Settings["Use skill fast dont hold"] then
                    task.wait(0.05)
                else
                    local targetHold = tonumber(holdDuration) or 0.5
                    local startTime = os.clock()
                    while (os.clock() - startTime) < targetHold do
                        task.wait(0.03)
                        if cooldownFrame and cooldownFrame.Size ~= UDim2.new(0, 0, 1, -1) and cooldownFrame.Size ~= UDim2.new(1, 0, 1, -1) then
                            break
                        end
                    end
                end

                VirtualInputManager:SendKeyEvent(false, skillKey, false, game)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                task.wait(0.02)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                task.wait(0.15)

                isCastingSkill = false
            end)

            return true
        end
    end
    return false
end

function AutoAllSkill()
    if isCastingSkill then return end
    local weaponOrder = {"Melee", "Sword", "Blox Fruit", "Gun"}
    for _, wType in ipairs(weaponOrder) do
        local used = UseSkill(wType)
        if used then break end
    end
end

function DetectLeviathan(seaBeastsFolder)
    local children = seaBeastsFolder:GetChildren()

    for _, part in ipairs(children) do
        if part.Name == "Leviathan Segment" and part.Health.Value > 0 then
            return part
        end
    end

    for _, part in ipairs(children) do
        if part.Name == "Leviathan Tail" and part:GetAttribute("HealthEnabled") and part.Health.Value > 0 then
            return part
        end
    end

    for _, part in ipairs(children) do
        if part.Name == "Leviathan" and not part:GetAttribute("Armored") and part.Health.Value > 0 then
            return part
        end
    end

    return nil
end

function AttackLeviathan()
    local seaBeasts = workspace:FindFirstChild("SeaBeasts")
    if not seaBeasts then
        return
    end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local target = DetectLeviathan(seaBeasts)

    if target and target.Parent and target:FindFirstChild("Health") and target.Health.Value > 0 then
        local aimTarget = target:FindFirstChild("Hitbox11") or target:FindFirstChild("HumanoidRootPart") or target
        getgenv().AimPos = aimTarget.CFrame

        local rootPos = target:FindFirstChild("HumanoidRootPart") and target.HumanoidRootPart.Position or target:GetPivot().Position
        local targetHeight = target.Name == "Leviathan" and 140 or 142
        
        toTarget(CFrame.new(rootPos.X, targetHeight, rootPos.Z), false, true)

        local distance = (hrp.Position - rootPos).Magnitude
        if distance < 150 then
            local method = Settings["Method Attack Leviathan"] or "Use Select Skill"
            if method == "Use M1 Fruits" then
                local fruitName = NameWeapon("Blox Fruit")
                if fruitName then
                    equiptool(fruitName)
                    local tool = char:FindFirstChild(fruitName)
                    if tool and tool:FindFirstChild("LeftClickRemote") then
                        tool.LeftClickRemote:FireServer(Vector3.new(0, 1, 0), 1)
                    end
                end
            elseif method == "Use Skull Guitar" then
                local gunName = NameWeapon("Gun")
                if gunName then
                    equiptool(gunName)
                    local guitar = char:FindFirstChild("Skull Guitar")
                    local hitPart = target:FindFirstChild("Hitbox11") or target:FindFirstChild("HumanoidRootPart") or target
                    if guitar and guitar:FindFirstChild("RemoteEvent") and hitPart then
                        guitar.RemoteEvent:FireServer("TAP", hitPart.Position)
                    else 
                        ReplicatedStorage.Remotes.CommF_:InvokeServer("LoadItem", "Skull Guitar") 
                    end
                    UseSkill("Gun")
                end
            else
                AutoAllSkill()
            end
        end
    else
        getgenv().AimPos = nil
    end
end

local lastBuyBoatTick = 0
local BUY_BOAT_NPC_CF = CFrame.new(-16204.0810546875, 9.0863618850708, 479.2259521484375)


function StartHunt()
	local lp = Players.LocalPlayer
	local char = lp.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp or hum.Health <= 0 then
		return
	end

	local map = workspace:FindFirstChild("Map")
	local frozenHeart = map and map:FindFirstChild("FrozenHeart")
	local hasCube = frozenHeart and frozenHeart:FindFirstChild("Cube")
	
	local seaBeasts = workspace:FindFirstChild("SeaBeasts")
	local hasLevi = seaBeasts and seaBeasts:FindFirstChild("Leviathan")

	if hasLevi then
		stopBoatTween()
		if stopBoatTween2 then
			stopBoatTween2()
		end

		AttackLeviathan()
		return
	end

	if hasCube then
		stopBoatTween()
        stopBoatTween2()
		if not Settings["Account Buy Boat"] then
			toTarget(frozenHeart.Cube.CFrame, true, false)
			return
		end

		if frozenHeart:FindFirstChild("Inside") and frozenHeart.Inside:GetAttribute("Harpooned") then
			return
		end

		local myBoat = getBoatByOwner(lp.Name)
		if not myBoat or not myBoat:FindFirstChild("VehicleSeat") then
			return
		end

		for _, part in ipairs(myBoat:GetDescendants()) do
			if part:IsA("BasePart") and part.CanCollide then
				part.CanCollide = false
			end
		end

		local heartPos = frozenHeart.Cube.Position
		local targetBoatCF = CFrame.new(heartPos.X, myBoat.WorldPivot.Y, heartPos.Z) * CFrame.new(0, 0, 300)

		if (targetBoatCF.Position - myBoat.VehicleSeat.Position).Magnitude > 5 then
			if hum.SeatPart and hum.SeatPart == myBoat.VehicleSeat then
				TweenBoat2(targetBoatCF, 150)
				task.wait(0.5)
			else
				toTarget(myBoat.VehicleSeat.CFrame, true, false)
			end
		elseif hum.SeatPart and hum.SeatPart.Parent and hum.SeatPart.Parent.Name == "Harpoon" then
			local shootArgs = {
				[1] = "FireHarpoon",
				[2] = 0.7853981633974483,
				[3] = 4.4342573293783646E-4,
				[4] = hum.SeatPart.Parent,
				[5] = workspace:GetServerTimeNow(),
			}
			ReplicatedStorage.Remotes.CommF_:InvokeServer(unpack(shootArgs))
			task.wait(1)
		else
			local harpoon = myBoat:FindFirstChild("Harpoon")
			local harpoonSeat = harpoon and harpoon:FindFirstChild("Seat")
			if harpoonSeat then
				toTarget(harpoonSeat.CFrame, true, false)
			end
		end
		return
	end

	if Settings["Account Buy Boat"] then
		local myBoat = getBoatByOwner(lp.Name)

		if not myBoat or not myBoat:FindFirstChild("VehicleSeat") then
			local distToNpc = (BUY_BOAT_NPC_CF.Position - hrp.Position).Magnitude

			-- Kiểm tra có nên reset để respawn gần hơn không
			local shouldReset = false
			pcall(function()
				local spawnName = lp.Data and lp.Data:FindFirstChild("LastSpawnPoint")
					and lp.Data.LastSpawnPoint.Value
				if spawnName then
					local marines = workspace:FindFirstChild("_WorldOrigin")
						and workspace._WorldOrigin:FindFirstChild("PlayerSpawns")
						and workspace._WorldOrigin.PlayerSpawns:FindFirstChild("Marines")
					if marines then
						local spawnPart = marines:FindFirstChild(spawnName)
						if spawnPart then
							local distSpawnToTarget = (BUY_BOAT_NPC_CF.Position - spawnPart.Position).Magnitude
							local distCurrentToTarget = (BUY_BOAT_NPC_CF.Position - hrp.Position).Magnitude
							-- Reset nếu từ spawn đến target ngắn hơn từ hiện tại + 1000 stud buffer
							if distSpawnToTarget < distCurrentToTarget - 1000 then
								shouldReset = true
							end
						end
					end
				end
			end)

			if shouldReset then
				hum.Health = 0
				return
			end

			if distToNpc > 8 then
				toTarget(BUY_BOAT_NPC_CF, true, false)
			else
				if tick() - lastBuyBoatTick >= 3 then
					lastBuyBoatTick = tick()
					pcall(function()
						ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyBoat", "Beast Hunter")
					end)
				end
			end
			return
		end

		-- Có thuyền rồi → lên ghế lái
		if hum.Sit then
			if hum.SeatPart ~= myBoat.VehicleSeat then
				toTarget(myBoat.VehicleSeat.CFrame, true, false)
			else
				local occupied, total = getCannonStats(myBoat)
				if occupied >= 0 then
					FindLeviathan(300)
				end
			end
		else
			toTarget(myBoat.VehicleSeat.CFrame, true, false)
		end
	else
		local selectedPlr = Settings["Select Player"]
		if selectedPlr then
			local targetBoat = getBoatByOwner(selectedPlr)
			if targetBoat then
				local isSittingCorrect = false
				if hum.Sit and hum.SeatPart then
					local seatParent = hum.SeatPart.Parent
					if seatParent and seatParent.Name == "Cannon" and seatParent.Parent == targetBoat then
						isSittingCorrect = true
					end
				end

				if hum.Sit then
					if not isSittingCorrect then
						toTarget(targetBoat.WorldPivot, true, false)
					end
				else
					local emptySeat = nil
					for _, v in ipairs(targetBoat:GetChildren()) do
						if v.Name == "Cannon" and v:FindFirstChild("Seat") and not v.Seat:FindFirstChild("SeatWeld") then
							emptySeat = v.Seat
							break
						end
					end
					if emptySeat then
						toTarget(emptySeat.CFrame, true, false)
					end
				end
			end
		end
	end
end

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
	Title = "Taigen Hub - Kaitun Leviathan",
	SubTitle = "by lon ma may",
	TabWidth = 160,
	Size = UDim2.fromOffset(580, 460),
	Acrylic = false,
	Theme = "Dark",
	MinimizeKey = Enum.KeyCode.LeftControl,
})

local Tabs = {
	Main = Window:AddTab({ Title = "Tab Setup Hunt\nLeviathan" }),
	Skills = Window:AddTab({ Title = "Setting Hold and\nSelect Skill" })
}

local PlayerDropdown = Tabs.Main:AddDropdown("PlayerSelect", {
	Title = "Select Player",
	Values = getPlayerList(),
	Multi = false,
	Default = Settings["Select Player"] or nil,
	Callback = function(val)
		SaveSettings("Select Player", val)
	end,
})

Tabs.Main:AddButton({
	Title = "Refresh Player List",
	Callback = function()
		local list = getPlayerList()
		PlayerDropdown:SetValues(list)
		if #list > 0 then
			PlayerDropdown:SetValue(list[1])
			SaveSettings("Select Player", list[1])
		end
	end,
})

Tabs.Main:AddToggle("BuyBoatToggle", {
	Title = "Account Buy Boat",
	Default = Settings["Account Buy Boat"] or false,
	Callback = function(val)
		SaveSettings("Account Buy Boat", val)
	end,
})

Tabs.Main:AddDropdown("MethodAttackLeviDropdown", {
    Title = "Method Attack Leviathan",
    Values = {"Use Select Skill", "Use Skull Guitar", "Use M1 Fruits"},
    Default = Settings["Method Attack Leviathan"] or "Use Select Skill",
    Multi = false,
    Callback = function(Value)
        Settings["Method Attack Leviathan"] = Value
        SaveSettings("Method Attack Leviathan", Value)
    end
})

Tabs.Main:AddToggle("StartToggle", {
	Title = "Start",
	Default = Settings["Start Hunt"] or false,
	Callback = function(val)
		SaveSettings("Start Hunt", val)
		if val then
			task.spawn(function()
				while Settings["Start Hunt"] do
					task.wait(0.1)
					pcall(StartHunt)
				end
				-- Thoát loop → dọn hết
				pcall(function() getgenv().Tween:Pause() end)
				pcall(function() getgenv().Tween:Cancel() end)
				stopBoatTween()
				stopBoatTween2()
				SetNoClip(false)
			end)
		else
			-- Tắt toggle → cancel mọi thứ ngay lập tức
			pcall(function()
				getgenv().Tween:Pause()
				getgenv().Tween:Cancel()
			end)
			stopBoatTween()
			stopBoatTween2()
			SetNoClip(false)
		end
	end,
})
Tabs.Skills:AddToggle("FastSkillToggle", {
    Title = "Use skill fast dont hold",
    Default = Settings["Use skill fast dont hold"] or false,
    Callback = function(val)
        SaveSettings("Use skill fast dont hold", val)
    end
})

Tabs.Skills:AddDropdown("MeleeDropdown", {
    Title = "Select Skill Melee",
    Values = {"Z", "X", "C"},
    Multi = true,
    Default = Settings["Select Skills Melee"] or {"Z", "X", "C"},
    Callback = function(val)
        SaveSettings("Select Skills Melee", val)
    end
})

for _, key in ipairs({"Z", "X", "C"}) do
    Tabs.Skills:AddSlider("MeleeHold_" .. key, {
        Title = "Hold Time " .. key,
        Min = 0,
        Max = 5,
        Default = tonumber(Settings["Skill " .. key .. " Melee"]) or 0.5,
        Rounding = 2,
        Callback = function(val)
            SaveSettings("Skill " .. key .. " Melee", tonumber(val) or 0.5)
        end
    })
end

Tabs.Skills:AddDropdown("SwordDropdown", {
    Title = "Select Skill Sword",
    Values = {"Z", "X"},
    Multi = true,
    Default = Settings["Select Skills Sword"] or {"Z", "X"},
    Callback = function(val)
        SaveSettings("Select Skills Sword", val)
    end
})

for _, key in ipairs({"Z", "X"}) do
    Tabs.Skills:AddSlider("SwordHold_" .. key, {
        Title = "Hold Time " .. key,
        Min = 0,
        Max = 5,
        Default = tonumber(Settings["Skill " .. key .. " Sword"]) or 0.5,
        Rounding = 2,
        Callback = function(val)
            SaveSettings("Skill " .. key .. " Sword", tonumber(val) or 0.5)
        end
    })
end

Tabs.Skills:AddDropdown("GunDropdown", {
    Title = "Select Skill Gun",
    Values = {"Z", "X"},
    Multi = true,
    Default = Settings["Select Skills Gun"] or {"Z", "X"},
    Callback = function(val)
        SaveSettings("Select Skills Gun", val)
    end
})

for _, key in ipairs({"Z", "X"}) do
    Tabs.Skills:AddSlider("GunHold_" .. key, {
        Title = "Hold Time " .. key,
        Min = 0,
        Max = 5,
        Default = tonumber(Settings["Skill " .. key .. " Gun"]) or 0.5,
        Rounding = 2,
        Callback = function(val)
            SaveSettings("Skill " .. key .. " Gun", tonumber(val) or 0.5)
        end
    })
end

Tabs.Skills:AddDropdown("FruitDropdown", {
    Title = "Select Skill Blox Fruit",
    Values = {"Z", "X", "C", "V", "F"},
    Multi = true,
    Default = Settings["Select Skills Blox Fruit"] or {"Z", "X", "C", "V", "F"},
    Callback = function(val)
        SaveSettings("Select Skills Blox Fruit", val)
    end
})

for _, key in ipairs({"Z", "X", "C", "V", "F"}) do
    Tabs.Skills:AddSlider("FruitHold_" .. key, {
        Title = "Hold Time " .. key,
        Min = 0,
        Max = 5,
        Default = tonumber(Settings["Skill " .. key .. " Blox Fruit"]) or 0.5,
        Rounding = 2,
        Callback = function(val)
            SaveSettings("Skill " .. key .. " Blox Fruit", tonumber(val) or 0.5)
        end
    })
end

if Settings["Start Hunt"] then
	task.spawn(function()
		while Settings["Start Hunt"] do
			task.wait(0.1)
			pcall(StartHunt)
		end
	end)
end
