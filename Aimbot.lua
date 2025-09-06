-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Settings
local AimLockEnabled = false
local ESPEnabled = true
local TeamCheck = true
local WallCheck = true
local FOVEnabled = true
local FOV = 150
local FOVColor = Color3.fromRGB(255,100,100)
local FOVTransparency = 0.3
local Smoothness = 0.3

-- Storage
local ESPBoxes = {}
local ESPLabels = {}
local PlayerSettings = {}
local PlayerRows = {}

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = FOVEnabled
FOVCircle.Color = FOVColor
FOVCircle.Thickness = 2
FOVCircle.NumSides = 100
FOVCircle.Transparency = FOVTransparency

-- GUI
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.ResetOnSpawn = false

-- Main Frame
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0,320,0,420)
Frame.Position = UDim2.new(0,10,0,50)
Frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
Frame.BackgroundTransparency = 0.1
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.ZIndex = 5

-- Title
local Title = Instance.new("script by keng and gpt", Frame)
Title.Size = UDim2.new(1,0,0,30)
Title.BackgroundTransparency = 1
Title.Text = "🔥 Roblox ESP & AimLock 🔥"
Title.TextScaled = true
Title.TextColor3 = Color3.fromRGB(255,200,50)
Title.Font = Enum.Font.GothamBold

-- ScrollFrame
local ScrollFrame = Instance.new("ScrollingFrame", Frame)
ScrollFrame.Size = UDim2.new(1,0,1,-50)
ScrollFrame.Position = UDim2.new(0,0,0,50)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.CanvasSize = UDim2.new(0,0,0,0)

-- GUI Toggle Button
local GuiToggleBtn = Instance.new("TextButton", ScreenGui)
GuiToggleBtn.Size = UDim2.new(0,120,0,35)
GuiToggleBtn.Position = UDim2.new(0,10,0,10)
GuiToggleBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
GuiToggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
GuiToggleBtn.TextScaled = true
GuiToggleBtn.Text = "Toggle GUI"
GuiToggleBtn.ZIndex = 10

local guiVisible = true
GuiToggleBtn.MouseButton1Click:Connect(function()
    guiVisible = not guiVisible
    Frame.Visible = guiVisible
end)

-- UI Helpers
local uiIndex = 0
local function createToggle(name, default, callback)
    uiIndex += 1
    local btn = Instance.new("TextButton", Frame)
    btn.Size = UDim2.new(0.9,0,0,35)
    btn.Position = UDim2.new(0.05,0,0,(uiIndex-1)*40 + 50)
    btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.TextScaled = true
    btn.Text = name .. ": " .. (default and "ON" or "OFF")
    btn.MouseButton1Click:Connect(function()
        default = not default
        btn.Text = name .. ": " .. (default and "ON" or "OFF")
        callback(default)
    end)
end

local function createSlider(name, min, max, default, callback)
    uiIndex += 1
    local label = Instance.new("TextLabel", Frame)
    label.Size = UDim2.new(0.9,0,0,20)
    label.Position = UDim2.new(0.05,0,0,(uiIndex-1)*40 + 50)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.TextScaled = true
    label.Text = name .. ": " .. default

    local slider = Instance.new("Frame", Frame)
    slider.Size = UDim2.new(0.9,0,0,20)
    slider.Position = UDim2.new(0.05,0,0,(uiIndex-1)*40 + 72)
    slider.BackgroundColor3 = Color3.fromRGB(80,80,80)

    local fill = Instance.new("Frame", slider)
    fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(255,150,150)

    local dragging = false
    slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    slider.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    slider.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local relativeX = math.clamp(input.Position.X - slider.AbsolutePosition.X, 0, slider.AbsoluteSize.X)
            local value = min + (relativeX/slider.AbsoluteSize.X)*(max-min)
            fill.Size = UDim2.new((value-min)/(max-min),0,1,0)
            callback(value)
            label.Text = name .. ": " .. math.floor(value)
        end
    end)
end

-- GUI Toggles
createToggle("AimLock", AimLockEnabled, function(v) AimLockEnabled = v end)
createToggle("ESP", ESPEnabled, function(v) ESPEnabled = v end)
createToggle("TeamCheck", TeamCheck, function(v) TeamCheck = v end)
createToggle("WallCheck", WallCheck, function(v) WallCheck = v end)
createToggle("FOV Circle", FOVEnabled, function(v) FOVEnabled = v; FOVCircle.Visible = v end)
createSlider("FOV Size", 50, 500, FOV, function(v) FOV = v end)
createSlider("FOV Transparency", 0, 1, FOVTransparency, function(v) FOVTransparency = v; FOVCircle.Transparency = v end)

-- Color Helper
local function GetTeamColor(player)
    if player.Team == LocalPlayer.Team then
        return Color3.fromRGB(0,255,0)
    else
        return Color3.fromRGB(255,0,0)
    end
end

-- Create Player Row
local function CreatePlayerRow(player)
    local row = Instance.new("Frame", ScrollFrame)
    row.Size = UDim2.new(1,-10,0,40)
    row.BackgroundTransparency = 0.3
    row.BackgroundColor3 = Color3.fromRGB(50,50,50)

    local nameLabel = Instance.new("TextLabel", row)
    nameLabel.Size = UDim2.new(0.5,0,1,0)
    nameLabel.Text = player.Name
    nameLabel.TextScaled = true
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = GetTeamColor(player)

    local espToggle = Instance.new("TextButton", row)
    espToggle.Size = UDim2.new(0.25,0,0.8,0)
    espToggle.Position = UDim2.new(0.5,0,0.1,0)
    espToggle.TextScaled = true
    espToggle.Text = "ESP: ON"
    PlayerSettings[player] = {ESP = true, TeamCheck = true, WallCheck = true}

    espToggle.MouseButton1Click:Connect(function()
        PlayerSettings[player].ESP = not PlayerSettings[player].ESP
        espToggle.Text = "ESP: " .. (PlayerSettings[player].ESP and "ON" or "OFF")
        if not PlayerSettings[player].ESP then
            if ESPBoxes[player] then ESPBoxes[player]:Destroy() ESPBoxes[player] = nil end
            if ESPLabels[player] then ESPLabels[player]:Remove() ESPLabels[player] = nil end
        end
    end)

    -- Team Button
    local teamBtn = Instance.new("TextButton", row)
    teamBtn.Size = UDim2.new(0.25,0,0.4,0)
    teamBtn.Position = UDim2.new(0.75,0,0.1,0)
    teamBtn.TextScaled = true
    teamBtn.Text = "Team: ON"
    teamBtn.MouseButton1Click:Connect(function()
        PlayerSettings[player].TeamCheck = not PlayerSettings[player].TeamCheck
        teamBtn.Text = "Team: " .. (PlayerSettings[player].TeamCheck and "ON" or "OFF")
    end)

    -- Wall Button
    local wallBtn = Instance.new("TextButton", row)
    wallBtn.Size = UDim2.new(0.25,0,0.4,0)
    wallBtn.Position = UDim2.new(0.75,0,0.5,0)
    wallBtn.TextScaled = true
    wallBtn.Text = "Wall: ON"
    wallBtn.MouseButton1Click:Connect(function()
        PlayerSettings[player].WallCheck = not PlayerSettings[player].WallCheck
        wallBtn.Text = "Wall: " .. (PlayerSettings[player].WallCheck and "ON" or "OFF")
    end)

    table.insert(PlayerRows, row)

    -- อัปเดตตำแหน่ง rows
    for i, r in ipairs(PlayerRows) do
        r.Position = UDim2.new(0,5,0,(i-1)*45)
    end
end

-- Main Loop
RunService.RenderStepped:Connect(function()
    FOVCircle.Visible = FOVEnabled
    if FOVEnabled then
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
        FOVCircle.Radius = FOV
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if not PlayerSettings[player] then CreatePlayerRow(player) end

            -- Update ESP
            if PlayerSettings[player].ESP and (not PlayerSettings[player].TeamCheck or player.Team ~= LocalPlayer.Team) then
                if not ESPBoxes[player] then
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
                if not ESPLabels[player] then
                    local label = Drawing.new("Text")
                    label.Text = player.Name
                    label.Color = GetTeamColor(player)
                    label.Center = true
                    label.Size = 20
                    label.Visible = true
                    ESPLabels[player] = label
                end

                -- Update label position
                local screenPos, onScreen = Camera:WorldToViewportPoint(player.Character.Head.Position + Vector3.new(0,2,0))
                if onScreen then
                    ESPLabels[player].Position = Vector2.new(screenPos.X,screenPos.Y)
                    local distance = (player.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                    ESPLabels[player].Text = player.Name.." ["..math.floor(distance).."m]"
                    ESPLabels[player].Size = math.clamp(50 - distance/2, 10, 50)
                    ESPLabels[player].Visible = true
                    ESPBoxes[player].Color3 = GetTeamColor(player)
                    ESPLabels[player].Color = GetTeamColor(player)
                else
                    ESPLabels[player].Visible = false
                end
            else
                if ESPBoxes[player] then ESPBoxes[player]:Destroy() ESPBoxes[player] = nil end
                if ESPLabels[player] then ESPLabels[player]:Remove() ESPLabels[player] = nil end
            end
        end
    end

    -- AimLock
    if AimLockEnabled then
        local closest = nil
        local shortest = FOV
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") and PlayerSettings[player] and PlayerSettings[player].ESP then
                if (not PlayerSettings[player].TeamCheck or player.Team ~= LocalPlayer.Team) then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(player.Character.Head.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X,screenPos.Y)-Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)).Magnitude
                        if dist < shortest then
                            shortest = dist
                            closest = player
                        end
                    end
                end
            end
        end
        if closest then
            local dir = (closest.Character.Head.Position - Camera.CFrame.Position).Unit
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position,Camera.CFrame.Position+dir), Smoothness)
        end
    end
end)

-- Player Added/Removing
Players.PlayerRemoving:Connect(function(player)
    if ESPBoxes[player] then ESPBoxes[player]:Destroy() ESPBoxes[player] = nil end
    if ESPLabels[player] then ESPLabels[player]:Remove() ESPLabels[player] = nil end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if not PlayerSettings[player] then CreatePlayerRow(player) end
    end)
end)
