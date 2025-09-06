
-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Settings
local aimbotEnabled = false
local TEAM_CHECK = true
local ESP_ENABLED = true
local FOV_RADIUS = 120
local AIM_SMOOTHNESS = 0.2
local MAX_DIST = math.huge

-- FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = true
fovCircle.Thickness = 2
fovCircle.NumSides = 100
fovCircle.Radius = FOV_RADIUS
fovCircle.Filled = false
fovCircle.Color = Color3.fromRGB(0,255,0)
fovCircle.Transparency = 0.8

-- Helper Functions
local function getHead(char)
    return char and char:FindFirstChild("Head")
end

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

local function isVisible(targetHead)
    local myChar = localPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return false end
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {myChar}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    local result = workspace:Raycast(myRoot.Position, (targetHead.Position - myRoot.Position), rayParams)
    return not result
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
            if char and head and isVisible(head) then
                local screenPos, onScreen = worldToScreen(head.Position)
                if onScreen then
                    local distFromCenter = (Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2) - screenPos).Magnitude
                    local worldDist = (myRoot.Position - head.Position).Magnitude
                    if distFromCenter <= FOV_RADIUS and worldDist <= MAX_DIST then
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

-- ESP around head
local espHeads = {}
local function createESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= localPlayer then
            local char = plr.Character
            if char and char:FindFirstChild("Head") then
                local box = Drawing.new("Square")
                box.Visible = true
                box.Color = isEnemy(plr) and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,255,0)
                box.Thickness = 2
                box.Size = Vector2.new(40,40) -- เพิ่มขนาดให้เห็นชัดบนมือถือ
                espHeads[plr] = {Box = box, Char = char}
            end
        end
    end
end
createESP()

Players.PlayerAdded:Connect(function(plr)
    spawn(function()
        wait(1)
        createESP()
    end)
end)

Players.PlayerRemoving:Connect(function(plr)
    if espHeads[plr] then
        espHeads[plr].Box:Remove()
        espHeads[plr] = nil
    end
end)

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MobileAimbotGUI"
ScreenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0,300,0,350) -- ขยายให้ใหญ่สำหรับมือถือ
mainFrame.Position = UDim2.new(0,20,0,50)
mainFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
mainFrame.BackgroundTransparency = 0.3
mainFrame.BorderSizePixel = 0
mainFrame.Parent = ScreenGui
mainFrame.Active = true
mainFrame.Draggable = true

-- Toggle Button Helper
local function createToggle(name, callback, posY)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0,250,0,40) -- ปุ่มใหญ่
    button.Position = UDim2.new(0,25,0,posY)
    button.BackgroundColor3 = Color3.fromRGB(60,60,60)
    button.TextColor3 = Color3.fromRGB(255,255,255)
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 20
    button.Text = name
    button.Parent = mainFrame
    button.MouseButton1Click:Connect(callback)
end

-- Slider Helper
local function createSlider(name, min, max, default, posY, callback)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0,250,0,25)
    label.Position = UDim2.new(0,25,0,posY)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 18
    label.Text = name..": "..tostring(default)
    label.Parent = mainFrame

    local slider = Instance.new("TextButton")
    slider.Size = UDim2.new(0,250,0,25)
    slider.Position = UDim2.new(0,25,0,posY+25)
    slider.BackgroundColor3 = Color3.fromRGB(100,100,100)
    slider.Text = ""
    slider.Parent = mainFrame

    slider.MouseButton1Down:Connect(function()
        local move
        move = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
                local pct = math.clamp((input.Position.X - slider.AbsolutePosition.X)/slider.AbsoluteSize.X,0,1)
                local value = min + (max-min)*pct
                label.Text = name..": "..string.format("%.1f", value)
                callback(value)
            end
        end)
        UserInputService.InputEnded:Wait()
        move:Disconnect()
    end)
end

-- Create Toggles
createToggle("Toggle Aimbot", function()
    aimbotEnabled = not aimbotEnabled
    fovCircle.Color = aimbotEnabled and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,255,0)
end, 10)

createToggle("Toggle TeamCheck", function()
    TEAM_CHECK = not TEAM_CHECK
end, 60)

createToggle("Toggle ESP", function()
    ESP_ENABLED = not ESP_ENABLED
    for _, data in pairs(espHeads) do
        data.Box.Visible = ESP_ENABLED
    end
end, 110)

-- Sliders
createSlider("FOV Radius", 50, 500, FOV_RADIUS, 160, function(val)
    FOV_RADIUS = val
    fovCircle.Radius = FOV_RADIUS
end)

createSlider("Aim Smoothness", 0, 1, AIM_SMOOTHNESS, 230, function(val)
    AIM_SMOOTHNESS = val
end)

-- Main Loop
RunService.RenderStepped:Connect(function()
    fovCircle.Position = UserInputService:GetMouseLocation()

    if ESP_ENABLED then
        for plr, data in pairs(espHeads) do
            local char = data.Char
            local box = data.Box
            if char and char:FindFirstChild("Head") then
                local headPos, onScreen = worldToScreen(char.Head.Position)
                if onScreen then
                    box.Position = headPos - Vector2.new(box.Size.X/2, box.Size.Y/2)
                    box.Color = isEnemy(plr) and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,255,0)
                    box.Visible = true
                else
                    box.Visible = false
                end
            end
        end
    end

    if aimbotEnabled then
        local target = getClosestTarget()
        if target and target.Character and getHead(target.Character) then
            local targetHead = getHead(target.Character)
            camera.CFrame

				
