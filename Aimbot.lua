-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Settings
local AimLockEnabled = false
local ESPEnabled = false
local TeamCheck = true
local WallCheck = true
local FOV = 150

-- ESP Storage
local ESPBoxes = {}

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = true
FOVCircle.Color = Color3.fromRGB(255,0,0)
FOVCircle.Thickness = 2
FOVCircle.NumSides = 100

-- GUI Creation
local ScreenGui = Instance.new("ScreenGui", game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0,200,0,250)
Frame.Position = UDim2.new(0,10,0,50)
Frame.BackgroundTransparency = 0.5
Frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true

local function createToggle(name, default, callback)
    local btn = Instance.new("TextButton", Frame)
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.Position = UDim2.new(0, 5, 0, (#Frame:GetChildren()-1)*35)
    btn.Text = name .. ": " .. (default and "ON" or "OFF")
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.MouseButton1Click:Connect(function()
        default = not default
        btn.Text = name .. ": " .. (default and "ON" or "OFF")
        callback(default)
    end)
end

-- Toggles
createToggle("AimLock", AimLockEnabled, function(v) AimLockEnabled = v end)
createToggle("ESP", ESPEnabled, function(v) ESPEnabled = v end)
createToggle("TeamCheck", TeamCheck, function(v) TeamCheck = v end)
createToggle("WallCheck", WallCheck, function(v) WallCheck = v end)

-- Color Helper
local function GetTeamColor(player)
    if player.Team == LocalPlayer.Team then
        return Color3.fromRGB(0,255,0)
    else
        return Color3.fromRGB(255,0,0)
    end
end

-- ESP Functions
local function CreateESP(player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    local box = Instance.new("BoxHandleAdornment")
    box.Adornee = player.Character.HumanoidRootPart
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Size = Vector3.new(4,6,2)
    box.Transparency = 0.5
    box.Color3 = GetTeamColor(player)
    box.Parent = Workspace
    ESPBoxes[player] = box
end

local function RemoveESP(player)
    if ESPBoxes[player] then
        ESPBoxes[player]:Destroy()
        ESPBoxes[player] = nil
    end
end

local function UpdateESP(player)
    if ESPBoxes[player] then
        ESPBoxes[player].Color3 = GetTeamColor(player)
    end
end

-- Wall Check Function
local function CanSeeTarget(target)
    if not WallCheck then return true end
    local origin = Camera.CFrame.Position
    local targetPos = target.Character.Head.Position
    local ray = Ray.new(origin, (targetPos-origin).Unit * (targetPos-origin).Magnitude)
    local hitPart, _ = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character})
    if hitPart then
        return hitPart:IsDescendantOf(target.Character)
    end
    return true
end

-- Get Closest Target
local function GetClosestEnemy()
    local closestPlayer = nil
    local shortestDistance = FOV
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            if TeamCheck and player.Team == LocalPlayer.Team then continue end
            if not CanSeeTarget(player) then continue end
            local screenPos, onScreen = Camera:WorldToViewportPoint(player.Character.Head.Position)
            if onScreen then
                local distance = (Vector2.new(screenPos.X,screenPos.Y) - Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    return closestPlayer
end

-- Main Loop
RunService.RenderStepped:Connect(function()
    -- Update FOV Circle
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
    FOVCircle.Radius = FOV

    -- Update ESP
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if TeamCheck and player.Team == LocalPlayer.Team then
                RemoveESP(player)
            else
                if ESPEnabled then
                    if not ESPBoxes[player] then
                        CreateESP(player)
                    else
                        UpdateESP(player)
                    end
                end
            end
        else
            RemoveESP(player)
        end
    end

    -- Aimlock
    if AimLockEnabled then
        local target = GetClosestEnemy()
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character.Head.Position)
        end
    end
end)

-- Remove ESP when player leaves
Players.PlayerRemoving:Connect(RemoveESP)
