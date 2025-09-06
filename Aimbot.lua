-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- SETTINGS
local AimLockEnabled = false
local ESPEnabled = true
local TeamCheck = true
local WallCheck = true
local PredictionEnabled = true
local FOVEnabled = true
local AimKey = Enum.KeyCode.Q
local TargetPart = "Head"
local FOVRadius = 100
local BulletSpeed = 300 -- สามารถปรับอัตโนมัติภายหลัง

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 250, 0, 300)
Frame.Position = UDim2.new(0.5, -125, 0.5, -150)
Frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
Frame.BackgroundTransparency = 0.2
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

local UIListLayout = Instance.new("UIListLayout", Frame)
UIListLayout.Padding = UDim.new(0,5)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,0,0,30)
Title.Text = "Script by Keng & G"
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.BackgroundTransparency = 1
Title.Parent = Frame

-- Toggle Buttons
local function CreateToggle(name, default, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,30)
    btn.Text = name.." : "..(default and "ON" or "OFF")
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Parent = Frame
    btn.MouseButton1Click:Connect(function()
        default = not default
        btn.Text = name.." : "..(default and "ON" or "OFF")
        callback(default)
    end)
end

CreateToggle("AimLock", AimLockEnabled, function(val) AimLockEnabled = val end)
CreateToggle("ESP", ESPEnabled, function(val) ESPEnabled = val end)
CreateToggle("TeamCheck", TeamCheck, function(val) TeamCheck = val end)
CreateToggle("WallCheck", WallCheck, function(val) WallCheck = val end)
CreateToggle("Prediction", PredictionEnabled, function(val) PredictionEnabled = val end)
CreateToggle("FOV", FOVEnabled, function(val) FOVEnabled = val end)

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = true
FOVCircle.Radius = FOVRadius
FOVCircle.Color = Color3.fromRGB(200,200,200)
FOVCircle.Thickness = 1
FOVCircle.Transparency = 0.5
FOVCircle.Filled = false

-- Functions
local function GetClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = FOVRadius

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(TargetPart) then
            if TeamCheck and player.Team == LocalPlayer.Team then continue end
            local headPos = player.Character[TargetPart].Position
            local screenPos, onScreen = Camera:WorldToViewportPoint(headPos)
            if onScreen then
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                if distance < shortestDistance then
                    closestPlayer = player
                    shortestDistance = distance
                end
            end
        end
    end

    return closestPlayer
end

-- Prediction
local function PredictPosition(target)
    if not PredictionEnabled then return target.Position end
    local velocity = target:FindFirstChild("HumanoidRootPart") and target.HumanoidRootPart.Velocity or Vector3.new()
    local distance = (Camera.CFrame.Position - target.Position).Magnitude
    local travelTime = distance / BulletSpeed
    return target.Position + velocity * travelTime
end

-- AimLock
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == AimKey then
        AimLockEnabled = not AimLockEnabled
    end
end)

-- ESP Highlight
local ESPFolder = Instance.new("Folder", Workspace)
ESPFolder.Name = "ESP"

local function CreateESP(player)
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(255,0,0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 1
    highlight.Adornee = player.Character
    highlight.Parent = ESPFolder
    return highlight
end

local ESPTable = {}
RunService.RenderStepped:Connect(function()
    -- Update FOV Circle
    if FOVEnabled then
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    -- AimLock
    if AimLockEnabled then
        local target = GetClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild(TargetPart) then
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, PredictPosition(target.Character[TargetPart]))
        end
    end

    -- ESP
    if ESPEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                if not ESPTable[player] then
                    ESPTable[player] = CreateESP(player)
                end
            end
        end
    else
        for _, highlight in pairs(ESPTable) do
            highlight:Destroy()
        end
        ESPTable = {}
    end
end)
