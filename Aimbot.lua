-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local localPlayer = Players.LocalPlayer

-- Settings
local AimbotEnabled = false
local ESPEnabled = true
local HighlightEnabled = true
local FOV = 200
local TeamCheck = true
local WallCheck = true

-- GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AimbotESPGUI"
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

-- Buttons
local toggleAimbot = Instance.new("TextButton")
toggleAimbot.Size = UDim2.new(0, 120, 0, 50)
toggleAimbot.Position = UDim2.new(0.05, 0, 0.85, 0)
toggleAimbot.Text = "Aimbot: OFF"
toggleAimbot.Parent = screenGui

local toggleESP = Instance.new("TextButton")
toggleESP.Size = UDim2.new(0, 120, 0, 50)
toggleESP.Position = UDim2.new(0.05, 0, 0.75, 0)
toggleESP.Text = "ESP: ON"
toggleESP.Parent = screenGui

local fovButton = Instance.new("TextButton")
fovButton.Size = UDim2.new(0, 120, 0, 50)
fovButton.Position = UDim2.new(0.05, 0, 0.65, 0)
fovButton.Text = "FOV: "..FOV
fovButton.Parent = screenGui

-- FOV Circle
local fovCircle = Instance.new("Frame")
fovCircle.Size = UDim2.new(0, FOV*2, 0, FOV*2)
fovCircle.Position = UDim2.new(0.5, -FOV, 0.5, -FOV)
fovCircle.AnchorPoint = Vector2.new(0.5,0.5)
fovCircle.BackgroundTransparency = 1
fovCircle.BorderSizePixel = 2
fovCircle.BorderColor3 = Color3.fromRGB(255,0,0)
fovCircle.Parent = screenGui

-- Button functionality
toggleAimbot.MouseButton1Click:Connect(function()
    AimbotEnabled = not AimbotEnabled
    toggleAimbot.Text = AimbotEnabled and "Aimbot: ON" or "Aimbot: OFF"
end)

toggleESP.MouseButton1Click:Connect(function()
    ESPEnabled = not ESPEnabled
    toggleESP.Text = ESPEnabled and "ESP: ON" or "ESP: OFF"
end)

fovButton.MouseButton1Click:Connect(function()
    FOV = FOV + 50
    if FOV > 500 then FOV = 50 end
    fovButton.Text = "FOV: "..FOV
    fovCircle.Size = UDim2.new(0, FOV*2, 0, FOV*2)
    fovCircle.Position = UDim2.new(0.5, -FOV, 0.5, -FOV)
end)

-- ESP & Highlight storage
local espObjects = {}
local highlights = {}

local function CreateESP(player)
    local box = Instance.new("BoxHandleAdornment")
    box.Adornee = player.Character:FindFirstChild("HumanoidRootPart")
    box.Size = Vector3.new(2,5,1)
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Parent = player.Character

    local nameTag = Instance.new("BillboardGui")
    nameTag.Adornee = player.Character:FindFirstChild("Head")
    nameTag.Size = UDim2.new(0,100,0,50)
    nameTag.AlwaysOnTop = true

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1,0,1,0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextScaled = true
    textLabel.Parent = nameTag
    nameTag.Parent = player.Character

    espObjects[player] = {box=box, nameTag=textLabel}

    -- Create Highlight
    local highlight = Instance.new("Highlight")
    highlight.Adornee = player.Character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = Color3.new(1,0,0)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.new(1,1,1)
    highlight.OutlineTransparency = 0
    highlight.Parent = player.Character
    highlights[player] = highlight
end

local function RemoveESP(player)
    if espObjects[player] then
        if espObjects[player].box then espObjects[player].box:Destroy() end
        if espObjects[player].nameTag then espObjects[player].nameTag.Parent:Destroy() end
        espObjects[player] = nil
    end
    if highlights[player] then
        highlights[player]:Destroy()
        highlights[player] = nil
    end
end

-- Wall check
local function IsVisible(target)
    if not WallCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = (target.Position - origin).Unit * (target.Position - origin).Magnitude
    local ray = Ray.new(origin, direction)
    local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {localPlayer.Character}, false, true)
    return hit == target.Parent:FindFirstChild("HumanoidRootPart") or hit == nil
end

-- Closest target
local function GetClosestTarget()
    local closestTarget = nil
    local shortestDistance = FOV

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Head") then
            if TeamCheck and player.Team == localPlayer.Team then continue end
            local headPos, onScreen = Camera:WorldToViewportPoint(player.Character.Head.Position)
            if onScreen then
                local mousePos = UserInputService:GetMouseLocation()
                local distance = (Vector2.new(headPos.X, headPos.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
                if distance < shortestDistance and IsVisible(player.Character.Head) then
                    shortestDistance = distance
                    closestTarget = player
                end
            end
        end
    end
    return closestTarget
end

-- Main loop
RunService.RenderStepped:Connect(function()
    -- Aimbot
    local lockedTarget = nil
    if AimbotEnabled then
        local target = GetClosestTarget()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character.Head.Position)
            lockedTarget = target
        end
    end

    -- ESP & Highlight
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            if ESPEnabled and (not TeamCheck or player.Team ~= localPlayer.Team) then
                if not espObjects[player] then
                    CreateESP(player)
                end
                -- Update name + distance
                local distance = (player.Character.HumanoidRootPart.Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude
                espObjects[player].nameTag.Text = player.Name.." | "..math.floor(distance).."m"

                -- Color by team and FOV
                local inFOV = false
                local headPos, onScreen = Camera:WorldToViewportPoint(player.Character.Head.Position)
                if onScreen then
                    local mousePos = UserInputService:GetMouseLocation()
                    local screenDistance = (Vector2.new(headPos.X, headPos.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
                    if screenDistance <= FOV then
                        inFOV = true
                    end
                end

                if TeamCheck and player.Team == localPlayer.Team then
                    espObjects[player].box.Color3 = Color3.new(0,1,0)
                    espObjects[player].nameTag.TextColor3 = Color3.new(0,1,0)
                    if highlights[player] then highlights[player].FillColor = Color3.new(0,1,0) end
                elseif player == lockedTarget then
                    -- Highlight locked target
                    espObjects[player].box.Color3 = Color3.new(1,0,0)
                    espObjects[player].nameTag.TextColor3 = Color3.new(1,0,0)
                    if highlights[player] then highlights[player].FillColor = Color3.new(1,0,0) end
                elseif inFOV then
                    espObjects[player].box.Color3 = Color3.new(1,0,0)
                    espObjects[player].nameTag.TextColor3 = Color3.new(1,0,0)
                    if highlights[player] then highlights[player].FillColor = Color3.new(1,0,0) end
                else
                    espObjects[player].box.Color3 = Color3.new(1,1,0)
                    espObjects[player].nameTag.TextColor3 = Color3.new(1,1,0)
                    if highlights[player] then highlights[player].FillColor = Color3.new(1,1,0) end
                end
            else
                RemoveESP(player)
            end
        end
    end
end)
