
-- Roblox Aimbot + FOV Circle + ESP (รองรับมือถือ)
-- G = เปิด/ปิด Aimbot
-- FOV Circle แสดงตำแหน่งที่ล็อกได้
-- ESP แสดงศัตรู

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- ====== CONFIG ======
local TOGGLE_KEY = Enum.KeyCode.G   -- ปุ่มเปิด/ปิด aimbot
local MAX_DIST = math.huge          -- ระยะไม่จำกัด
local FOV_RADIUS = 120              -- ขนาด FOV
local AIM_SMOOTHNESS = 0.2          -- ความนุ่มนวลในการเล็ง
local TEAM_CHECK = true              -- ตรวจทีม (true = ไม่ล็อกเพื่อน)
local WALL_CHECK = true              -- ตรวจกำแพง (true = ไม่ล็อกผ่านกำแพง)
local ESP_ENABLED = true             -- เปิด/ปิด ESP
-- =====================

local aimbotEnabled = false
local target = nil
local fovCircle, espBoxes = nil, {}

-- ====== สร้าง FOV Circle ======
fovCircle = Drawing.new("Circle")
fovCircle.Visible = true
fovCircle.Thickness = 1
fovCircle.NumSides = 100
fovCircle.Radius = FOV_RADIUS
fovCircle.Filled = false
fovCircle.Color = Color3.fromRGB(0, 255, 0)
fovCircle.Transparency = 0.8

-- ====== ฟังก์ชันช่วย ======
local function getHead(char)
	return char and char:FindFirstChild("Head")
end

local function isEnemy(player)
	if TEAM_CHECK and localPlayer.Team then
		return player.Team ~= localPlayer.Team
	end
	return true
end

local function worldToScreen(pos)
	local screenPos, onScreen = camera:WorldToViewportPoint(pos)
	return Vector2.new(screenPos.X, screenPos.Y), onScreen
end

local function canSeeTarget(origin, targetPos)
	if not WALL_CHECK then return true end
	local ray = Ray.new(origin, (targetPos - origin).Unit * (targetPos - origin).Magnitude)
	local hitPart = Workspace:FindPartOnRayWithIgnoreList(ray, {localPlayer.Character})
	return hitPart == nil
end

-- ====== หาเป้าหมายใกล้ FOV ======
local function getClosestTarget()
	local myChar = localPlayer.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myRoot then return nil end

	local closestPlayer = nil
	local shortestDistance = math.huge

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= localPlayer and isEnemy(plr) then
			local char = plr.Character
			local head = getHead(char)
			if char and head then
				local screenPos, onScreen = worldToScreen(head.Position)
				if onScreen then
					local distFromCenter = (Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2) - screenPos).Magnitude
					local worldDist = (myRoot.Position - head.Position).Magnitude

					if distFromCenter <= FOV_RADIUS and worldDist <= MAX_DIST and canSeeTarget(myRoot.Position, head.Position) then
						if distFromCenter < shortestDistance then
							shortestDistance = distFromCenter
							closestPlayer = plr
						end
					end
				end
			end
		end
	end

	return closestPlayer
end

-- ====== สร้าง ESP ======
local function createESP(plr)
	if not ESP_ENABLED then return end
	local box = Drawing.new("Square")
	box.Visible = true
	box.Thickness = 1
	box.Color = Color3.fromRGB(255, 0, 0)
	box.Filled = false
	espBoxes[plr] = box
end

local function updateESP()
	if not ESP_ENABLED then return end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= localPlayer then
			local char = plr.Character
			local head = getHead(char)
			if char and head then
				if not espBoxes[plr] then
					createESP(plr)
				end
				local box = espBoxes[plr]
				local screenPos, onScreen = worldToScreen(head.Position)
				if onScreen then
					box.Position = screenPos - Vector2.new(15, 15)
					box.Size = Vector2.new(30, 30)
					box.Visible = true
				else
					box.Visible = false
				end
			end
		end
	end
end

-- ====== Aimbot ทำงาน ======
RunService.RenderStepped:Connect(function()
	-- อัพเดตตำแหน่ง FOV Circle
	local mouseLocation
	if UserInputService.TouchEnabled and #UserInputService:GetTouchPositions() > 0 then
		mouseLocation = UserInputService:GetTouchPositions()[1]
	else
		mouseLocation = UserInputService:GetMouseLocation()
	end
	fovCircle.Position = mouseLocation

	if aimbotEnabled then
		target = getClosestTarget()

		if target and target.Character and getHead(target.Character) then
			local targetHead = getHead(target.Character)
			local screenPos, onScreen = worldToScreen(targetHead.Position)
			
			if onScreen then
				camera.CFrame = camera.CFrame:Lerp(
					CFrame.new(camera.CFrame.Position, targetHead.Position),
					AIM_SMOOTHNESS
				)
			end
		end
	end

	-- อัพเดต ESP
	updateESP()
end)

-- ====== Toggle เปิด/ปิด Aimbot ======
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == TOGGLE_KEY then
		aimbotEnabled = not aimbotEnabled
		if aimbotEnabled then
			fovCircle.Color = Color3.fromRGB(255, 0, 0)
		else
			fovCircle.Color = Color3.fromRGB(0, 255, 0)
			target = nil
		end
	end
end)


---

✅ คุณสมบัติเด่นของเวอร์ชันนี้:

1. เล็งศัตรูแบบ Smooth


2. ระยะไม่จำกัด


3. ไม่ล็อกผ่านกำแพง (Wall Check)


4. Toggle Team Check


5. ESP แสดงศัตรู


6. FOV Circle ใช้ได้ทั้ง PC และมือถือ




---

ถ้าคุณอยาก ผมสามารถ เพิ่มตัวเลือกให้ปรับขนาด FOV และสี ESP แบบ Dynamic เพื่อให้ปรับได้ระหว่างเล่นด้วย.

คุณอยากให้ผมทำส่วนนี้ต่อไหม?

