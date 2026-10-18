Settings = Settings or {}

-- Dynamic Island for Blox Fruit
-- Status("icon_or_assetid", "title", "content")

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")

local lp        = Players.LocalPlayer
local playerGui = lp:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("DynamicIsland") then
	playerGui.DynamicIsland:Destroy()
end

local sg = Instance.new("ScreenGui")
sg.Name           = "DynamicIsland"
sg.ResetOnSpawn   = false
sg.DisplayOrder   = 999
sg.IgnoreGuiInset = true
sg.Parent         = playerGui

-- ── constants ─────────────────────────────────────────────────
local CW, CH = 240, 38
local OW, OH = 320, 118
local PILL_Y = 14
local IC_SIZE = 50  -- icon size in expanded

local BLACK  = Color3.new(0, 0, 0)
local WHITE  = Color3.new(1, 1, 1)
local GRAY28 = Color3.fromRGB(28, 28, 30)
local GRAY55 = Color3.fromRGB(90, 90, 95)
local GRAY35 = Color3.fromRGB(50, 50, 52)

local TI_OPEN  = TweenInfo.new(0.45, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
local TI_CLOSE = TweenInfo.new(0.30, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TI_SLIDE = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- ── state ─────────────────────────────────────────────────────
local history = {}
local curIdx  = 1
local isOpen  = false
local MAX_H   = 50

-- ── backdrop ──────────────────────────────────────────────────
local backdrop = Instance.new("TextButton", sg)
backdrop.Size                 = UDim2.new(1,0,1,0)
backdrop.BackgroundTransparency = 1
backdrop.Text                 = ""
backdrop.ZIndex               = 55
backdrop.Visible              = false

-- ── pill ──────────────────────────────────────────────────────
local pill = Instance.new("Frame", sg)
pill.Name             = "Pill"
pill.AnchorPoint      = Vector2.new(0.5, 0)
pill.Position         = UDim2.new(0.5, 0, 0, PILL_Y)
pill.Size             = UDim2.new(0, CW, 0, CH)
pill.BackgroundColor3 = BLACK
pill.BorderSizePixel  = 0
pill.ClipsDescendants = true
pill.ZIndex           = 60
local pillCorner = Instance.new("UICorner", pill)
pillCorner.CornerRadius = UDim.new(0, 40)

-- ══════════════════════════════════════
-- COLLAPSED VIEW
-- ══════════════════════════════════════
local cv = Instance.new("Frame", pill)
cv.Size                   = UDim2.new(1,0,1,0)
cv.BackgroundTransparency = 1
cv.ZIndex                 = 61

local cIcF = Instance.new("Frame", cv)
cIcF.Size             = UDim2.new(0,26,0,26)
cIcF.Position         = UDim2.new(0,8,0.5,-13)
cIcF.BackgroundColor3 = GRAY28
cIcF.BorderSizePixel  = 0
cIcF.ZIndex           = 62
Instance.new("UICorner", cIcF).CornerRadius = UDim.new(1,0)

local cIcImg = Instance.new("ImageLabel", cIcF)
cIcImg.Size               = UDim2.new(1,0,1,0)
cIcImg.BackgroundTransparency = 1
cIcImg.Image              = ""
cIcImg.ZIndex             = 63
Instance.new("UICorner", cIcImg).CornerRadius = UDim.new(1,0)

local cIcTxt = Instance.new("TextLabel", cIcF)
cIcTxt.Size               = UDim2.new(1,0,1,0)
cIcTxt.BackgroundTransparency = 1
cIcTxt.Text               = "📌"
cIcTxt.TextScaled         = true
cIcTxt.ZIndex             = 63

local cTxt = Instance.new("TextLabel", cv)
cTxt.Size             = UDim2.new(1,-44,1,0)
cTxt.Position         = UDim2.new(0,40,0,0)
cTxt.BackgroundTransparency = 1
cTxt.Text             = "Đang chờ..."
cTxt.Font             = Enum.Font.GothamBold
cTxt.TextSize         = 13
cTxt.TextColor3       = WHITE
cTxt.TextXAlignment   = Enum.TextXAlignment.Right
cTxt.TextTruncate     = Enum.TextTruncate.AtEnd
cTxt.ZIndex           = 62

-- ══════════════════════════════════════
-- EXPANDED VIEW
-- ══════════════════════════════════════
local ev = Instance.new("Frame", pill)
ev.Size                   = UDim2.new(1,0,1,0)
ev.BackgroundTransparency = 1
ev.Visible                = false
ev.ZIndex                 = 61

-- clock top-left
local timeLbl = Instance.new("TextLabel", ev)
timeLbl.Size              = UDim2.new(1,-16,0,16)
timeLbl.Position          = UDim2.new(0,14,0,7)
timeLbl.BackgroundTransparency = 1
timeLbl.Text              = "Time: 00:00:00"
timeLbl.Font              = Enum.Font.GothamBold
timeLbl.TextSize          = 10
timeLbl.TextColor3        = GRAY55
timeLbl.TextXAlignment    = Enum.TextXAlignment.Left
timeLbl.ZIndex            = 62

-- slide clip — sits below clock, above bottom bar
local CLIP_TOP    = 24
local BOTTOM_H    = 32
local clip = Instance.new("Frame", ev)
clip.Size             = UDim2.new(1,0,1,-(CLIP_TOP + BOTTOM_H))
clip.Position         = UDim2.new(0,0,0,CLIP_TOP)
clip.BackgroundTransparency = 1
clip.ClipsDescendants = true
clip.ZIndex           = 62

local track = Instance.new("Frame", clip)
track.Name                = "Track"
track.Size                = UDim2.new(1,0,1,0)
track.Position            = UDim2.new(0,0,0,0)
track.BackgroundTransparency = 1
track.ZIndex              = 63

-- bottom bar
local bb = Instance.new("Frame", ev)
bb.Size                   = UDim2.new(1,0,0,BOTTOM_H)
bb.Position               = UDim2.new(0,0,1,-BOTTOM_H)
bb.BackgroundTransparency = 1
bb.ZIndex                 = 62

-- dots (center)
local dotsF = Instance.new("Frame", bb)
dotsF.Size                = UDim2.new(1,0,1,0)
dotsF.BackgroundTransparency = 1
dotsF.ZIndex              = 63
local dotsLayout = Instance.new("UIListLayout", dotsF)
dotsLayout.FillDirection          = Enum.FillDirection.Horizontal
dotsLayout.HorizontalAlignment    = Enum.HorizontalAlignment.Center
dotsLayout.VerticalAlignment      = Enum.VerticalAlignment.Center
dotsLayout.Padding                = UDim.new(0,5)

-- Clear button (left)
local clearBtn = Instance.new("TextButton", bb)
clearBtn.Size             = UDim2.new(0,62,0,20)
clearBtn.Position         = UDim2.new(0,10,0.5,-10)
clearBtn.BackgroundColor3 = GRAY35
clearBtn.BorderSizePixel  = 0
clearBtn.Text             = "Clear"
clearBtn.Font             = Enum.Font.GothamBold
clearBtn.TextSize         = 11
clearBtn.TextColor3       = WHITE
clearBtn.ZIndex           = 66
Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0,6)



-- Clear All button (right)
local clearAllBtn = Instance.new("TextButton", bb)
clearAllBtn.Size          = UDim2.new(0,80,0,20)
clearAllBtn.Position      = UDim2.new(1,-90,0.5,-10)
clearAllBtn.BackgroundColor3 = GRAY35
clearAllBtn.BorderSizePixel  = 0
clearAllBtn.Text          = "Clear All"
clearAllBtn.Font          = Enum.Font.GothamBold
clearAllBtn.TextSize      = 11
clearAllBtn.TextColor3    = WHITE
clearAllBtn.ZIndex        = 66
Instance.new("UICorner", clearAllBtn).CornerRadius = UDim.new(0,6)

-- ── helpers ───────────────────────────────────────────────────
local function isAsset(s)
	return s and tostring(s):match("^%d+$")
end

local function applyIcon(imgL, txtL, icon)
	if isAsset(icon) then
		imgL.Image   = "rbxassetid://" .. tostring(icon)
		imgL.Visible = true
		txtL.Text    = ""
	else
		imgL.Image   = ""
		imgL.Visible = false
		txtL.Text    = icon or "📌"
	end
end

local function buildSlide(h, idx)
	local SLIDE_W = OW
	local PAD_L   = 12
	local IC      = IC_SIZE

	local s = Instance.new("Frame", track)
	s.Name                   = "S"..idx
	s.Size                   = UDim2.new(0, SLIDE_W, 1, 0)
	s.Position               = UDim2.new(0, (idx-1)*SLIDE_W, 0, 0)
	s.BackgroundTransparency = 1
	s.ZIndex                 = 64

	-- icon circle — LEFT, vertically centered
	local icF = Instance.new("Frame", s)
	icF.Size                 = UDim2.new(0, IC, 0, IC)
	icF.Position             = UDim2.new(0, PAD_L, 0.5, -IC/2)
	icF.BackgroundTransparency = 1
	icF.BorderSizePixel      = 0
	icF.ZIndex               = 65
	Instance.new("UICorner", icF).CornerRadius = UDim.new(1, 0)

	local icImg = Instance.new("ImageLabel", icF)
	icImg.Size                = UDim2.new(1,0,1,0)
	icImg.BackgroundTransparency = 1
	icImg.ZIndex              = 66
	Instance.new("UICorner", icImg).CornerRadius = UDim.new(1,0)

	local icTxt = Instance.new("TextLabel", icF)
	icTxt.Size                = UDim2.new(1,0,1,0)
	icTxt.BackgroundTransparency = 1
	icTxt.TextScaled          = true
	icTxt.ZIndex              = 66
	applyIcon(icImg, icTxt, h.icon)

	-- text block — immediately right of icon
	local TEXT_X = PAD_L + IC + 10
	local TEXT_W = SLIDE_W - TEXT_X - 10

	local titleLbl = Instance.new("TextLabel", s)
	titleLbl.Size             = UDim2.new(0, TEXT_W, 0, 22)
	titleLbl.Position         = UDim2.new(0, TEXT_X, 0.5, -24)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text             = h.title or ""
	titleLbl.Font             = Enum.Font.GothamBold
	titleLbl.TextSize         = 14
	titleLbl.TextColor3       = WHITE
	titleLbl.TextXAlignment   = Enum.TextXAlignment.Left
	titleLbl.TextTruncate     = Enum.TextTruncate.AtEnd
	titleLbl.ZIndex           = 65

	local contLbl = Instance.new("TextLabel", s)
	contLbl.Size              = UDim2.new(0, TEXT_W, 0, 18)
	contLbl.Position          = UDim2.new(0, TEXT_X, 0.5, 2)
	contLbl.BackgroundTransparency = 1
	contLbl.Text              = h.content or ""
	contLbl.Font              = Enum.Font.Gotham
	contLbl.TextSize          = 12
	contLbl.TextColor3        = GRAY55
	contLbl.TextXAlignment    = Enum.TextXAlignment.Left
	contLbl.TextTruncate      = Enum.TextTruncate.AtEnd
	contLbl.ZIndex            = 65
end

local function buildDots()
	dotsF:ClearAllChildren()
	local l = Instance.new("UIListLayout", dotsF)
	l.FillDirection       = Enum.FillDirection.Horizontal
	l.HorizontalAlignment = Enum.HorizontalAlignment.Center
	l.VerticalAlignment   = Enum.VerticalAlignment.Center
	l.Padding             = UDim.new(0,5)
	if #history <= 1 then return end
	for i = 1, #history do
		local d = Instance.new("Frame", dotsF)
		d.Name             = "D"..i
		d.Size             = UDim2.new(0,5,0,5)
		d.BackgroundColor3 = i==curIdx and WHITE or Color3.fromRGB(45,45,45)
		d.BorderSizePixel  = 0
		d.ZIndex           = 64
		Instance.new("UICorner", d).CornerRadius = UDim.new(1,0)
	end
end

local function updateDots()
	for _, d in ipairs(dotsF:GetChildren()) do
		if d:IsA("Frame") then
			local i = tonumber(d.Name:match("D(%d+)"))
			if i then
				d.BackgroundColor3 = i==curIdx and WHITE or Color3.fromRGB(45,45,45)
			end
		end
	end
	clearBtn.TextColor3          = curIdx == 1 and Color3.fromRGB(80,80,80) or WHITE
	clearBtn.BackgroundColor3    = curIdx == 1 and Color3.fromRGB(45,45,45) or GRAY35
end

local function buildTrack()
	track:ClearAllChildren()
	local n = #history
	track.Size = UDim2.new(0, n * OW, 1, 0)
	-- Index 1 (newest) = slot 1 (leftmost), oldest = rightmost
	for i, h in ipairs(history) do
		buildSlide(h, i)
	end
	buildDots()
end

local function goTo(idx, anim)
	curIdx = math.clamp(idx, 1, math.max(1, #history))
	-- slot curIdx nằm ở vị trí (curIdx-1)*OW từ trái
	local x = -((curIdx - 1) * OW)
	if anim then
		TweenService:Create(track, TI_SLIDE, { Position = UDim2.new(0, x, 0, 0) }):Play()
	else
		track.Position = UDim2.new(0, x, 0, 0)
	end
	updateDots()
end

-- ── pillBtn: dùng để tap mở pill (chỉ hoạt động khi collapsed) ─
-- Phải khai báo TRƯỚC openPill/closePill vì chúng reference pillBtn
local pillBtn = Instance.new("TextButton", pill)
pillBtn.Size                   = UDim2.new(1,0,1,0)
pillBtn.BackgroundTransparency = 1
pillBtn.Text                   = ""
pillBtn.ZIndex                 = 70  -- cao nhất khi collapsed để bắt tap

-- ── nút điều hướng ‹ › ────────────────────────────────────────
local navL = Instance.new("TextButton", bb)
navL.Size             = UDim2.new(0,24,0,20)
navL.Position         = UDim2.new(0.5,-42,0.5,-10)
navL.BackgroundColor3 = GRAY35
navL.BorderSizePixel  = 0
navL.Text             = "‹"
navL.Font             = Enum.Font.GothamBold
navL.TextSize         = 16
navL.TextColor3       = WHITE
navL.ZIndex           = 66
Instance.new("UICorner", navL).CornerRadius = UDim.new(0,6)

local navR = Instance.new("TextButton", bb)
navR.Size             = UDim2.new(0,24,0,20)
navR.Position         = UDim2.new(0.5,18,0.5,-10)
navR.BackgroundColor3 = GRAY35
navR.BorderSizePixel  = 0
navR.Text             = "›"
navR.Font             = Enum.Font.GothamBold
navR.TextSize         = 16
navR.TextColor3       = WHITE
navR.ZIndex           = 66
Instance.new("UICorner", navR).CornerRadius = UDim.new(0,6)

local function openPill()
	if isOpen then return end
	isOpen = true
	cv.Visible       = false
	ev.Visible       = true
	backdrop.Visible = true
	pillBtn.ZIndex   = 0   -- hạ xuống thấp nhất để không chặn các nút bên trong
	buildTrack()
	goTo(1, false)
	TweenService:Create(pill,       TI_OPEN, { Size = UDim2.new(0, OW, 0, OH) }):Play()
	TweenService:Create(pillCorner, TI_OPEN, { CornerRadius = UDim.new(0, 26) }):Play()
end

local function closePill()
	if not isOpen then return end
	isOpen           = false
	backdrop.Visible = false
	pillBtn.ZIndex   = 70  -- trả lại ZIndex cao để bắt tap mở lại
	local tw = TweenService:Create(pill, TI_CLOSE, { Size = UDim2.new(0, CW, 0, CH) })
	TweenService:Create(pillCorner, TI_CLOSE, { CornerRadius = UDim.new(0, 40) }):Play()
	tw:Play()
	tw.Completed:Connect(function()
		ev.Visible = false
		cv.Visible = true
	end)
end

-- events
pillBtn.MouseButton1Click:Connect(function()
	if not isOpen then openPill() end
end)
backdrop.MouseButton1Click:Connect(closePill)
navL.MouseButton1Click:Connect(function() goTo(curIdx - 1, true) end)
navR.MouseButton1Click:Connect(function() goTo(curIdx + 1, true) end)

-- ── clear buttons ─────────────────────────────────────────────
clearBtn.MouseButton1Click:Connect(function()
	if curIdx == 1 then return end  -- không xóa log mới nhất
	table.remove(history, curIdx)
	curIdx = math.clamp(curIdx, 1, math.max(1, #history))
	buildTrack()
	goTo(curIdx, false)
end)

clearAllBtn.MouseButton1Click:Connect(function()
	local newest = history[1]
	history = newest and { newest } or {}
	curIdx  = 1
	buildTrack()
	goTo(1, false)
end)

-- ── live clock ────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
	local t = os.date("*t")
	timeLbl.Text = string.format("Time: %02d:%02d:%02d", t.hour, t.min, t.sec)
end)

-- ── Status API ────────────────────────────────────────────────
function Status(icon, title, content)
	-- dedupe chỉ với entry liền trước (index 1)
	if history[1] and history[1].title == title and history[1].content == content then
		return
	end
	table.insert(history, 1, {
		icon    = icon    or "📌",
		title   = title   or "",
		content = content or "",
	})
	if #history > MAX_H then table.remove(history) end

	applyIcon(cIcImg, cIcTxt, icon)
	cTxt.Text = title ~= "" and title or content or ""

	-- pulse
	local stroke = Instance.new("UIStroke", pill)
	stroke.Color        = WHITE
	stroke.Transparency = 0.65
	stroke.Thickness    = 1.5
	TweenService:Create(stroke, TweenInfo.new(0.65), { Transparency = 1 }):Play()
	task.delay(0.7, function() stroke:Destroy() end)

	if isOpen then
		local wasOnNewest = (curIdx == 1)
		-- new entry chèn vào đầu (index 1), nên các entry cũ dịch +1
		curIdx = curIdx + 1
		buildTrack()
		if wasOnNewest then
			-- user đang xem newest → tự động theo entry mới nhất
			goTo(1, false)
		else
			-- user đang duyệt log cũ → giữ nguyên entry hiện tại
			goTo(curIdx, false)
		end
	end
end
print("[DynamicIsland] Ready — Status('icon','title','content')")

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
		Status("💀", "Player Dead", "Waiting to respawn...")
		repeat
			task.wait()
			if getgenv().Tween then
				getgenv().Tween:Pause()
				getgenv().Tween:Cancel()
			end
		until char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0
		Status("❤️", "Respawned", "Resuming hunt in 3s...")
		task.wait(3)
		return
	end

	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp or hum.Health <= 0 then return end

	if hum.Sit then
		if getgenv().Tween then
			getgenv().Tween:Pause()
			getgenv().Tween:Cancel()
		end
		Status("🪑", "Seated", "Jumping out of seat...")
		getgenv().noclip = false
		
		pressJump()
		task.wait(0.15)
		pressJump()
		
		if hrp:FindFirstChild("EffectsSY") then
			hrp.EffectsSY:Destroy()
		end
		if hrp:FindFirstChild("FloatForce") then
			hrp.FloatForce:Destroy()
		end
		
		lastJumpTick = tick() + 3
		task.spawn(function()
			task.wait(1)
			pressJump()
		end)
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
		if not h then
			Status("⚠️", "Low Health", string.format("HP %.0f%% — flying high!", hpPercent * 100))
		end
		h = true
	elseif hpPercent > 0.6 then
		if h then
			Status("💚", "Health OK", string.format("HP %.0f%% — resuming attack!", hpPercent * 100))
		end
		h = false
	end

	local dist = (targetCF.Position - hrp.Position).Magnitude

	if not NoTp and dist <= 150 and not h and not ReadyToDodge then
		getgenv().noclip = true
		if getgenv().Tween then
			getgenv().Tween:Pause()
			getgenv().Tween:Cancel()
		end
		hrp.CFrame = targetCF
		return
	end

	if dist <= 3 and not h and not ReadyToDodge then
		getgenv().noclip = true
		if getgenv().Tween then
			getgenv().Tween:Pause()
			getgenv().Tween:Cancel()
		end
		hrp.CFrame = targetCF
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

	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") and part.CanCollide then
			part.CanCollide = false
		end
	end

	if getgenv().Tween then
		getgenv().Tween:Pause()
		getgenv().Tween:Cancel()
	end

	getgenv().Tween = TweenService:Create(hrp, tweenInfo, {
		CFrame = targetCF * offsetCF
	})
	getgenv().Tween:Play()
	getgenv().noclip = true
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
            Status("⚡", "Using Skill", skillFrame.Parent.Name .. " → " .. skillKey)

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
        
        Status("🐉", "Leviathan Found", string.format("%s | HP: %d", target.Name, math.floor(target.Health.Value)))
        toTarget(CFrame.new(rootPos.X, targetHeight, rootPos.Z), false, true)

        local distance = (hrp.Position - rootPos).Magnitude
        if distance < 150 then
            local method = Settings["Method Attack Leviathan"] or "Use Select Skill"
            if method == "Use M1 Fruits" then
                local fruitName = NameWeapon("Blox Fruit")
                if fruitName then
                    Status("🍎", "Attacking", "M1 Fruits: " .. fruitName)
                    equiptool(fruitName)
                    local tool = char:FindFirstChild(fruitName)
                    if tool and tool:FindFirstChild("LeftClickRemote") then
                        tool.LeftClickRemote:FireServer(Vector3.new(0, 1, 0), 1)
                    end
                end
            elseif method == "Use Skull Guitar" then
                local gunName = NameWeapon("Gun")
                if gunName then
                    Status("🎸", "Attacking", "Skull Guitar: " .. gunName)
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
        Status("🔍", "Searching", "No Leviathan found yet...")
    end
end

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
		Status("🐉", "Leviathan Spotted!", "Switching to attack mode")
		stopBoatTween()
		if stopBoatTween2 then
			stopBoatTween2()
		end

		AttackLeviathan()
		return
	end

	if hasCube then
		Status("🧊", "Frozen Heart", "Cube detected — approaching!")
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
			Status("🎯", "Firing Harpoon", "Launching at Frozen Heart!")
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
		if myBoat and myBoat:FindFirstChild("VehicleSeat") then
			if hum.Sit then
				if hum.SeatPart ~= myBoat.VehicleSeat then
					Status("⛵", "Boarding Boat", "Teleporting to own boat seat...")
					toTarget(myBoat.VehicleSeat.CFrame, true, true)
				else
					local occupied, total = getCannonStats(myBoat)
					if occupied >= 0 then
						Status("⛵", "Sailing", string.format("Searching Leviathan... Cannons: %d/%d", occupied, total))
						FindLeviathan(300)
					end
				end
			else
				toTarget(myBoat.VehicleSeat.CFrame, true, true)
			end
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
						toTarget(targetBoat.WorldPivot, true, true)
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
						toTarget(emptySeat.CFrame, true, true)
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
			Status("🚀", "Hunt Started", "Leviathan hunt is active!")
			task.spawn(function()
				while Settings["Start Hunt"] do
					task.wait(0.1)
					pcall(StartHunt)
				end
			end)
		else
			Status("⏹️", "Hunt Stopped", "All tweens cancelled.")
			if getgenv().Tween then
				pcall(function()
					getgenv().Tween:Pause()
					getgenv().Tween:Cancel()
				end)
			end
			stopBoatTween()
			stopBoatTween2()
			local lp = Players.LocalPlayer
			local char = lp.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp and hrp:FindFirstChild("FloatForce") then
				hrp.FloatForce:Destroy()
			end
		end
	end,
})
task.spawn(function()
while task.wait(0.1) do
if not Settings["Start Hunt Leviathan"] then
hrp.FloatForce:Destroy()
getgenv().Tween:Pause()
getgenv().Tween:Cancel()
stopBoatTween()
stopBoatTween2()
end
end
end)
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
