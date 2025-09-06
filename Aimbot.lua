-- Roblox Full Aimbot + ESP Highlight + FOV Circle with Centered Stylish GUI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ====== Settings ======
local Settings = {
    AimbotEnabled = true,
    ESPEnabled = true,
    TeamCheck = true,
    WallCheck = true,
    FOV = 200,
    TargetPart = "Head"
}

-- ====== GUI ======
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimbotGUI"
ScreenGui.Parent = CoreGui

-- ปุ่มเปิด/ปิด GUI
local ToggleButton = Instance.new("TextButton", ScreenGui)
ToggleButton.Size = UDim2.new(0, 180, 0, 50)
ToggleButton.Position = UDim2.new(0.5, -90, 0.05, 0) -- อยู่ตรงกลางด้านบน
ToggleButton.Text = "Toggle GUI"
ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
ToggleButton.TextColor3 = Color3.new(1,1,1)
ToggleButton.TextScaled = true
ToggleButton.AutoButtonColor = true
ToggleButton.BorderSizePixel = 0
ToggleButton.TextStrokeTransparency = 0.7

-- Frame สำหรับฟีเจอร์ทั้งหมด
local GUIFrame = Instance.new("Frame", ScreenGui)
GUIFrame.Size = UDim2.new(0, 220, 0, 240)
GUIFrame.Position = UDim2.new(0.5, -110, 0.5, -120) -- อยู่ตรงกลาง
GUIFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
GUIFrame.BorderSizePixel = 0
GUIFrame.BackgroundTransparency = 0.1
GUIFrame.ClipsDescendants = true

-- เงารอบกรอบ
local UICorner = Instance.new("UICorner", GUIFrame)
UICorner.CornerRadius = UDim.new(0, 15)

local UIStroke = Instance.new("UIStroke", GUIFrame)
UIStroke.Thickness = 2
UIStroke.Transparency = 0.5
UIStroke.Color = Color3.fromRGB(0, 150, 255)

-- ฟังก์ชันสร้างปุ่ม toggle
local function createToggle(name, default, yPos)
    local frame = Instance.new("Frame", GUIFrame)
    frame.Size = UDim2.new(1, -20, 0, 40)
    frame.Position = UDim2.new(0, 10, 0, yPos)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    frame.ClipsDescendants = true
    frame.BorderSizePixel = 0
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0,10)

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Text = name
    label.TextColor3 = Color3.new(1,1,1)
    label.BackgroundTransparency = 1
    label.TextScaled = true

    local button = Instance.new("TextButton", frame)
    button.Size = UDim2.new(0.3, 0, 1, 0)
    button.Position = UDim2.new(0.7, 0, 0, 0)
    button.Text = default and "ON" or "OFF"
    button.BackgroundColor3 = default and Color3.fromRGB(0,200,0) or Color3.fromRGB(200,0,0)
    button.TextColor3 = Color3.new(1,1,1)
    button.AutoButtonColor = true
    local btnCorner = Instance.new("UICorner", button)
    btnCorner.CornerRadius = UDim.new(0,10)
    
    button.MouseButton1Click:Connect(function()
        local value = button.Text == "OFF"
        button.Text = value and "ON" or "OFF"
        button.BackgroundColor3 = value and Color3.fromRGB(0,200,0) or Color3.fromRGB(200,0,0)
        Settings[name.."Enabled"] = value
    end)
end

-- สร้างปุ่มทั้งหมด
createToggle("Aimbot", Settings.AimbotEnabled, 10)
createToggle("ESP", Settings.ESPEnabled, 60)
createToggle("TeamCheck", Settings.TeamCheck, 110)
createToggle("WallCheck", Settings.WallCheck, 160)

-- สลับเปิด/ปิด GUI
ToggleButton.MouseButton1Click:Connect(function()
    GUIFrame.Visible = not GUIFrame.Visible
end)

-- ====== FOV Circle ======
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = true
FOVCircle.Radius = Settings.FOV
FOVCircle.Color = Color3.fromRGB(0, 255, 0)
FOVCircle.Thickness = 2
FOVCircle.Filled = false

-- ====== Helper Functions ======
local function IsVisible(part)
    if not Settings.WallCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin)
    local ray = Ray.new(origin, direction)
    local hit, _ = Workspace:FindPartOnRay(ray, LocalPlayer.Character, false, true)
    return hit == nil
end

local function GetClosestEnemy()
    local closestPlayer = nil
    local shortestDistance = Settings.FOV

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(Settings.TargetPart) then
            if not Settings.TeamCheck or player.Team ~= LocalPlayer.Team then
                local headPos, onScreen = Camera:WorldToViewportPoint(player.Character[Settings.TargetPart].Position)
                if onScreen then
                    local mousePos = UserInputService:GetMouseLocation()
                    local distance = (Vector2.new(headPos.X, headPos.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
                    if distance < shortestDistance and IsVisible(player.Character[Settings.TargetPart]) then
                        shortestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- ====== ESP Highlight ======
local ESPHighlights = {}

local function createHighlight(player)
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = player.Character
    ESPHighlights[player] = highlight
end

Players.PlayerRemoving:Connect(function(player)
    if ESPHighlights[player] then
        ESPHighlights[player]:Destroy()
        ESPHighlights[player] = nil
    end
end)

-- ====== Main Loop ======
RunService.RenderStepped:Connect(function()
    -- FOV Circle
    FOVCircle.Position = UserInputService:GetMouseLocation()
    FOVCircle.Radius = Settings.FOV
    FOVCircle.Visible = Settings.AimbotEnabled

    -- ESP
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if Settings.ESPEnabled then
                if not ESPHighlights[player] then
                    createHighlight(player)
                end
                ESPHighlights[player].Enabled = true
            else
                if ESPHighlights[player] then
                    ESPHighlights[player].Enabled = false
                end
            end
        end
    end

    -- Aimbot
    if Settings.AimbotEnabled then
        local target = GetClosestEnemy()
        if target and target.Character and target.Character:FindFirstChild(Settings.TargetPart) then
            local targetPos = target.Character[Settings.TargetPart].Position
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos)
        end
    end
end)
