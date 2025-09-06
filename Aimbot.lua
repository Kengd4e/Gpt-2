-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")

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
Frame.Size = UDim2.new(0,320,0,450)
Frame.Position = UDim2.new(0,10,0,50)
Frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
Frame.BackgroundTransparency = 0
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.ClipsDescendants = true
Frame.ZIndex = 2

-- Rounded corners
local uiCorner = Instance.new("UICorner", Frame)
uiCorner.CornerRadius = UDim.new(0,10)

-- Title
local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1,0,0,40)
Title.Position = UDim2.new(0,0,0,0)
Title.BackgroundTransparency = 1
Title.Text = "Script by Keng and GPT"
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.TextStrokeTransparency = 0.7

-- ScrollFrame สำหรับ Player List
local ScrollFrame = Instance.new("ScrollingFrame", Frame)
ScrollFrame.Size = UDim2.new(1,-10,1,-50)
ScrollFrame.Position = UDim2.new(0,5,0,45)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.ScrollBarThickness = 6

local listLayout = Instance.new("UIListLayout", ScrollFrame)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0,5)

local uiPadding = Instance.new("UIPadding", ScrollFrame)
uiPadding.PaddingLeft = UDim.new(0,5)
uiPadding.PaddingRight = UDim.new(0,5)
uiPadding.PaddingTop = UDim.new(0,5)

-- GUI Toggle Button
local GuiToggleBtn = Instance.new("TextButton", ScreenGui)
GuiToggleBtn.Size = UDim2.new(0,120,0,35)
GuiToggleBtn.Position = UDim2.new(0,10,0,10)
GuiToggleBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
GuiToggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
GuiToggleBtn.TextScaled = true
GuiToggleBtn.Text = "Toggle GUI"
GuiToggleBtn.ZIndex = 10
GuiToggleBtn.Active = true
GuiToggleBtn.AutoButtonColor = true
GuiToggleBtn.Font = Enum.Font.GothamBold
local guiVisible = true
GuiToggleBtn.MouseButton1Click:Connect(function()
    guiVisible = not guiVisible
    Frame.Visible = guiVisible
end)

-- UI Helper Functions
local uiIndex = 0
local function createToggle(name, default, callback)
    uiIndex += 1
    local btn = Instance.new("TextButton", Frame)
    btn.Size = UDim2.new(0.9,0,0,35)
    btn.Position = UDim2.new(0.05,0,0,(uiIndex-1)*45 + 50)
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.TextScaled = true
    btn.Text = name .. ": " .. (default and "ON" or "OFF")
    btn.Font = Enum.Font.Gotham
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0,5)
    btn.MouseButton1Click:Connect(function()
        default = not default
        btn.Text = name .. ": " .. (default and "ON" or "OFF")
        callback(default)
    end)
end

local function createSlider(name, min, max, default, callback)
    uiIndex += 1
    local yPos = (uiIndex-1)*45 + 50

    local label = Instance.new("TextLabel", Frame)
    label.Size = UDim2.new(0.9,0,0,20)
    label.Position = UDim2.new(0.05,0,0,yPos)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.TextScaled = true
    label.Font = Enum.Font.Gotham
    label.Text = name .. ": " .. default

    local slider = Instance.new("Frame", Frame)
    slider.Size = UDim2.new(0.9,0,0,20)
    slider.Position = UDim2.new(0.05,0,0,yPos+22)
    slider.BackgroundColor3 = Color3.fromRGB(80,80,80)
    slider.BorderSizePixel = 0
    local corner = Instance.new("UICorner", slider)
    corner.CornerRadius = UDim.new(0,5)

    local fill = Instance.new("Frame", slider)
    fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(255,100,100)
    fill.BorderSizePixel = 0
    local fillCorner = Instance.new("UICorner", fill)
    fillCorner.CornerRadius = UDim.new(0,5)

    local dragging = false
    slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    slider.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
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

-- Create per-player GUI row
local function CreatePlayerRow(player)
    local row = Instance.new("Frame", ScrollFrame)
    row.Size = UDim2.new(1,0,0,50)
    row.BackgroundTransparency = 0.3
    row.BackgroundColor3 = Color3.fromRGB(50,50,50)
    row.BorderSizePixel = 0
    local rowCorner = Instance.new("UICorner", row)
    rowCorner.CornerRadius = UDim.new(0,5)

    local nameLabel = Instance.new("TextLabel", row)
    nameLabel.Size = UDim2.new(0.5,0,1,0)
    nameLabel.Text = player.Name
    nameLabel.TextScaled = true
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = GetTeamColor(player)
    nameLabel.Font = Enum.Font.Gotham

    local espToggle = Instance.new("TextButton", row)
    espToggle.Size = UDim2.new(0.25,0,0.8,0)
    espToggle.Position = UDim2.new(0.5,0,0.1,0)
    espToggle.TextScaled = true
    espToggle.Text = "ESP: ON"
    espToggle.Font = Enum.Font.Gotham
    local espCorner = Instance.new("UICorner", espToggle)
    espCorner.CornerRadius = UDim.new(0,5)

    PlayerSettings[player] = {ESP = true, TeamCheck = true, WallCheck = true}

    espToggle.MouseButton1Click:Connect(function()
        PlayerSettings[player].ESP = not PlayerSettings[player].ESP
        espToggle.Text = "ESP: " .. (PlayerSettings[player].ESP and "ON" or "OFF")
        if not PlayerSettings[player].ESP then
            if ESPBoxes[player] then ESPBoxes[player]:Destroy() ESPBoxes[player] = nil end
            if ESPLabels[player] then ESPLabels[player]:Destroy() ESPLabels[player] = nil end
        end
    end)

    local teamBtn = Instance.new("TextButton", row)
    teamBtn.Size = UDim2.new(0.25,0,0.4,0)
    teamBtn.Position = UDim2.new(0.75,0,0.1,0)
    teamBtn.TextScaled = true
    teamBtn.Text = "Team: ON"
    teamBtn.Font = Enum.Font.Gotham
    local teamCorner = Instance.new("UICorner", teamBtn)
    teamCorner.CornerRadius = UDim.new(0,5)
    teamBtn.MouseButton1Click:Connect(function()
        PlayerSettings[player].TeamCheck = not PlayerSettings[player].TeamCheck
        teamBtn.Text = "Team: " .. (PlayerSettings[player].TeamCheck and "ON" or "OFF")
    end)

    local wallBtn = Instance.new("TextButton", row)
    wallBtn.Size = UDim2.new(0.25,0,0.4,0)
    wallBtn.Position = UDim2.new(0.75,0,0.5,0)
    wallBtn.TextScaled = true
    wallBtn.Text = "Wall: ON"
    wallBtn.Font = Enum.Font.Gotham
    local wallCorner = Instance.new("UICorner", wallBtn)
    wallCorner.CornerRadius = UDim.new(0,5)
    wallBtn.MouseButton1Click:Connect(function()
        PlayerSettings[player].WallCheck = not PlayerSettings[player].WallCheck
        wallBtn.Text = "Wall: " .. (PlayerSettings[player].WallCheck and "ON" or "OFF")
    end)
end

-- ESP / AimLock / FOV Logic
local function CreateESP(player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    if not PlayerSettings[player] or not PlayerSettings[player].ESP then return end

    -- Box
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

    -- BillboardGui Label
    if not ESPLabels[player] then
        local billboard = Instance.new("BillboardGui", player.Character)
        billboard.Name = "ESPLabel"
        billboard.Adornee = player.Character.Head
        billboard.Size = UDim2.new(0,100,0,40)
        billboard.StudsOffset = Vector3.new(0,2,0)
        billboard.AlwaysOnTop = true

        local textLabel = Instance.new("TextLabel", billboard)
        textLabel.Size = UDim2.new(1,0,1,0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = GetTeamColor(player)
        textLabel.TextStrokeTransparency = 0.5
        textLabel.TextScaled = true
        textLabel.Font = Enum.Font.GothamBold
        textLabel.Text = player.Name

        ESPLabels[player] = textLabel
    end
end

local function RemoveESP(player)
    if ESPBoxes[player] then ESPBoxes[player]:Destroy() ESPBoxes[player] = nil end
    if ESPLabels[player] then
        if ESPLabels[player].Parent then ESPLabels[player].Parent:Destroy() end
        ESPLabels[player] = nil
    end
end

local function CanSeeTarget(player)
    if not PlayerSettings[player].WallCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = (player.Character.Head.Position - origin)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    local result = Workspace:Raycast(origin,direction,params)
    if result then
        return result.Instance:IsDescendantOf(player.Character)
    end
    return true
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
            if PlayerSettings[player].ESP and (not PlayerSettings[player].TeamCheck or player.Team ~= LocalPlayer.Team) and CanSeeTarget(player) then
                CreateESP(player)
                if ESPLabels[player] then
                    ESPLabels[player].Text = player.Name .. " [" .. math.floor((player.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude) .. "m]"
                    ESPLabels[player].TextColor3 = GetTeamColor(player)
                end
            else
                RemoveESP(player)
            end
        else
            RemoveESP(player)
        end
    end

    -- AimLock
    if AimLockEnabled then
        local closest = nil
        local shortest = FOV
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") and PlayerSettings[player] and PlayerSettings[player].ESP then
                if (not PlayerSettings[player].TeamCheck or player.Team ~= LocalPlayer.Team) and CanSeeTarget(player) then
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

Players.PlayerRemoving:Connect(RemoveESP)
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if not PlayerSettings[player] then CreatePlayerRow(player) end
    end)
end)
