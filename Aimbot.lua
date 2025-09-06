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

-- FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = true
fovCircle.Thickness = 2
fovCircle.NumSides = 100
fovCircle.Radius = FOV_RADIUS
fovCircle.Filled = false
fovCircle.Color = Color3.fromRGB(0,255,0)

-- Helper
local function getHead(char) return char and char:FindFirstChild("Head") end
local function isEnemy(player)
    return not TEAM_CHECK or (localPlayer.Team and player.Team ~= localPlayer.Team)
end
local function worldToScreen(pos)
    local screenPos, onScreen = camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen
end
local function getClosestTarget()
    local closest, minDist = nil, math.huge
    local myRoot = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= localPlayer and isEnemy(plr) then
            local head = getHead(plr.Character)
            if head then
                local screenPos, onScreen = worldToScreen(head.Position)
                if onScreen then
                    local dist = (Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2) - screenPos).Magnitude
                    if dist < FOV_RADIUS and dist < minDist then
                        closest = plr
                        minDist = dist
                    end
                end
            end
        end
    end
    return closest
end

-- ESP
local espHeads = {}
local function createESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= localPlayer then
            local head = getHead(plr.Character)
            if head then
                local box = Drawing.new("Square")
                box.Size = Vector2.new(30,30)
                box.Thickness = 2
                box.Visible = ESP_ENABLED
                espHeads[plr] = {Box = box, Char = plr.Character}
            end
        end
    end
end
createESP()
Players.PlayerAdded:Connect(createESP)

-- GUI
local ScreenGui = Instance.new("ScreenGui", localPlayer:WaitForChild("PlayerGui"))
local frame = Instance.new("Frame", ScreenGui)
frame.Size = UDim2.new(0,260,0,300)
frame.Position = UDim2.new(0,20,0,50)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.Active = true
frame.Draggable = true

local function createToggle(name, callback, y)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0,220,0,40)
    btn.Position = UDim2.new(0,20,0,y)
    btn.Text = name
    btn.MouseButton1Click:Connect(callback)
end

createToggle("Toggle Aimbot", function() aimbotEnabled = not aimbotEnabled; fovCircle.Color = aimbotEnabled and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,255,0) end, 10)
createToggle("Toggle TeamCheck", function() TEAM_CHECK = not TEAM_CHECK end, 60)
createToggle("Toggle ESP", function() ESP_ENABLED = not ESP_ENABLED; for _, data in pairs(espHeads) do data.Box.Visible = ESP_ENABLED end end, 110)

-- Main Loop
RunService.RenderStepped:Connect(function()
    fovCircle.Position = UserInputService:GetMouseLocation()

    if ESP_ENABLED then
        for plr, data in pairs(espHeads) do
            local head = getHead(data.Char)
            local box = data.Box
            if head then
                local pos, onScreen = worldToScreen(head.Position)
                box.Position = pos - Vector2.new(box.Size.X/2, box.Size.Y/2)
                box.Color = isEnemy(plr) and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,255,0)
                box.Visible = onScreen
            end
        end
    end

    if aimbotEnabled then
        local target = getClosestTarget()
        if target and target.Character then
            local head = getHead(target.Character)
            if head then
                camera.CFrame = camera.CFrame:Lerp(CFrame.new(camera.CFrame.Position, head.Position), AIM_SMOOTHNESS)
            end
        end
    end
end)
