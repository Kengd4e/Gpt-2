-- Roblox Mobile Aimbot GUI Draggable + Hide/Show + ESP + FOV + Wall Check

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- ===== CONFIG =====
local MAX_DIST = 150
local FOV_RADIUS = 120
local AIM_SMOOTHNESS = 0.2
local TEAM_CHECK = true
-- ==================

local aimbotEnabled = false
local target = nil
local espTable = {}
local guiVisible = true

-- ===== GUI =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AimbotGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

-- ปุ่ม Aimbot
local aimbotBtn = Instance.new("TextButton")
aimbotBtn.Size = UDim2.new(0, 120, 0, 50)
aimbotBtn.Position = UDim2.new(0, 20, 1, -80)
aimbotBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
aimbotBtn.Text = "Aimbot OFF"
aimbotBtn.TextColor3 = Color3.fromRGB(0,0,0)
aimbotBtn.Parent = screenGui

-- ปุ่ม Team Check
local teamBtn = Instance.new("TextButton")
teamBtn.Size = UDim2.new(0, 120, 0, 50)
teamBtn.Position = UDim2.new(0, 160, 1, -80)
teamBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
teamBtn.Text = "Team ON"
teamBtn.TextColor3 = Color3.fromRGB(255,255,255)
teamBtn.Parent = screenGui

-- ปุ่ม Hide/Show GUI
local hideBtn = Instance.new("TextButton")
hideBtn.Size = UDim2.new(0, 100, 0, 40)
hideBtn.Position = UDim2.new(1, -120, 0, 20)
hideBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
hideBtn.Text = "Hide GUI"
hideBtn.TextColor3 = Color3.fromRGB(255,255,255)
hideBtn.Parent = screenGui

-- ===== Draggable Function =====
local function makeDraggable(guiObject)
	local dragging = false
	local dragInput, mousePos, framePos

	guiObject.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			mousePos = input.Position
			framePos = guiObject.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	guiObject.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)

	RunService.RenderStepped:Connect(function()
		if dragging and dragInput then
			local delta = dragInput.Position - mousePos
			guiObject.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X,
										   framePos.Y.Scale, framePos.Y.Offset + delta.Y)
		end
	end)
end

makeDraggable(aimbotBtn)
makeDraggable(teamBtn)
makeDraggable(hideBtn)

-- ===== FOV Circle =====
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = true
fovCircle.Thickness = 1
fovCircle.NumSides = 100
fovCircle.Radius = FOV_RADIUS
fovCircle.Filled = false
fovCircle.Color = Color3.fromRGB(0, 255, 0)
fovCircle.Transparency = 0.8

-- ===== ฟังก์ชันพื้นฐาน =====
local function getHead(char) return char and char:FindFirstChild("Head") end
local function isEnemy(player)
	if TEAM_CHECK and localPlayer.Team ~= nil then
		return player.Team ~= localPlayer.Team
	end
	return true
end
local function worldToScreen(pos)
	local screenPos, onScreen = camera:WorldToViewportPoint(pos)
	return Vector2.new(screenPos.X, screenPos.Y), onScreen
end
local function isVisible(part)
	local myRoot = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return false end
	local rayOrigin = myRoot.Position
	local rayDir = (part.Position - rayOrigin)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {localPlayer.Character}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	local result = Workspace:Raycast(rayOrigin, rayDir, raycastParams)
	return result == nil or result.Instance:IsDescendantOf(part.Parent)
end
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
					if distFromCenter <= FOV_RADIUS and worldDist <= MAX_DIST then
						if isVisible(head) and distFromCenter < shortestDistance then
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

-- ===== ESP =====
local function createESP(player)
	if espTable[player] then return end
	local box = Drawing.new("Square")
	box.Visible = true
	box.Thickness = 1
	box.Filled = false
	espTable[player] = box
end
local function updateESP()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= localPlayer then
			local char = plr.Character
			if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
				createESP(plr)
				local hrp = char.HumanoidRootPart
				local humanoid = char.Humanoid
				local box = espTable[plr]

				local headPos, headOnScreen = worldToScreen((char:FindFirstChild("Head") and char.Head.Position) or (hrp.Position + Vector3.new(0, humanoid.HipHeight, 0)))
				local footPos, footOnScreen = worldToScreen(hrp.Position - Vector3.new(0, humanoid.HipHeight, 0))

				if headOnScreen and footOnScreen then
					box.Visible = true
					local height = math.abs(headPos.Y - footPos.Y)
					local width = height / 2
					box.Position = Vector2.new(headPos.X - width/2, headPos.Y)
					box.Size = Vector2.new(width, height)
					if TEAM_CHECK and localPlayer.Team ~= nil then
						box.Color = (plr.Team == localPlayer.Team) and Color3.fromRGB(0, 0, 255) or Color3.fromRGB(255, 0, 0)
					else
						box.Color = Color3.fromRGB(255, 255, 0)
					end
				else
					box.Visible = false
				end
			elseif espTable[plr] then
				espTable[plr].Visible = false
			end
		end
	end
end

-- ===== RenderStepped =====
RunService.RenderStepped:Connect(function()
	local mouseLocation = UserInputService:GetMouseLocation()
	fovCircle.Position = mouseLocation
	if guiVisible then updateESP() end
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
end)

-- ===== GUI Buttons =====
aimbotBtn.MouseButton1Click:Connect(function()
	aimbotEnabled = not aimbotEnabled
	aimbotBtn.Text = aimbotEnabled and "Aimbot ON" or "Aimbot OFF"
	aimbotBtn.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,255,0)
end)

teamBtn.MouseButton1Click:Connect(function()
	TEAM_CHECK = not TEAM_CHECK
	teamBtn.Text = TEAM_CHECK and "Team ON" or "Team OFF"
	teamBtn.BackgroundColor3 = TEAM_CHECK and Color3.fromRGB(0,0,255) or Color3.fromRGB(255,255,0)
end)

hideBtn.MouseButton1Click:Connect(function()
	guiVisible = not guiVisible
	aimbotBtn.Visible = guiVisible
	teamBtn.Visible = guiVisible
	hideBtn.Text = guiVisible and "Hide GUI" or "Show GUI"
end)
