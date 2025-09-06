-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ================= Key System =================
local NormalKeys = {["NORMAL"] = true}
local PremiumKeys = {["PREM"] = true}

local function CheckKey(key)
    if NormalKeys[key] then return "Normal"
    elseif PremiumKeys[key] then return "Premium"
    else return false end
end

-- GUI สำหรับใส่ Key
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local KeyGui = Instance.new("ScreenGui", PlayerGui)
KeyGui.ResetOnSpawn = false

local Frame = Instance.new("Frame", KeyGui)
Frame.Size = UDim2.new(0,300,0,150)
Frame.Position = UDim2.new(0.5,-150,0.5,-75)
Frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0,10)

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1,0,0,40)
Title.Position = UDim2.new(0,0,0,0)
Title.BackgroundTransparency = 1
Title.Text = "Enter Key"
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.Font = Enum.Font.GothamBold
Title.TextScaled = true

local TextBox = Instance.new("TextBox", Frame)
TextBox.Size = UDim2.new(0.8,0,0,30)
TextBox.Position = UDim2.new(0.1,0,0,50)
TextBox.PlaceholderText = "Enter your key"
TextBox.Text = ""
TextBox.TextColor3 = Color3.fromRGB(255,255,255)
TextBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
TextBox.ClearTextOnFocus = false
Instance.new("UICorner", TextBox).CornerRadius = UDim.new(0,5)

local Button = Instance.new("TextButton", Frame)
Button.Size = UDim2.new(0.5,0,0,35)
Button.Position = UDim2.new(0.25,0,0,90)
Button.BackgroundColor3 = Color3.fromRGB(70,70,70)
Button.TextColor3 = Color3.fromRGB(255,255,255)
Button.TextScaled = true
Button.Font = Enum.Font.GothamBold
Button.Text = "Submit"
Instance.new("UICorner", Button).CornerRadius = UDim.new(0,5)

local KeyType = nil

Button.MouseButton1Click:Connect(function()
    local inputKey = TextBox.Text:upper():gsub(" ","")
    local result = CheckKey(inputKey)
    if result then
        KeyType = result
        Title.Text = "Key Accepted! ("..result..")"
        wait(1)
        KeyGui:Destroy()
        print(result.." Key Activated")
        startScript(result) -- เริ่มสคริปต์หลัก
    else
        Title.Text = "Invalid Key!"
        TextBox.Text = ""
    end
end)

-- =================== Script หลัก ===================
function startScript(keyType)
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

    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Size = UDim2.new(0,320,0,450)
    MainFrame.Position = UDim2.new(0,10,0,50)
    MainFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.ClipsDescendants = true
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0,10)

    local TitleLabel = Instance.new("TextLabel", MainFrame)
    TitleLabel.Size = UDim2.new(1,0,0,40)
    TitleLabel.Position = UDim2.new(0,0,0,0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "Script by Keng and GPT"
    TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
    TitleLabel.TextScaled = true
    TitleLabel.Font = Enum.Font.GothamBold

    local ScrollFrame = Instance.new("ScrollingFrame", MainFrame)
    ScrollFrame.Size = UDim2.new(1,-10,1,-50)
    ScrollFrame.Position = UDim2.new(0,5,0,45)
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.ScrollBarThickness = 6
    local listLayout = Instance.new("UIListLayout", ScrollFrame)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0,5)

    local GuiToggleBtn = Instance.new("TextButton", ScreenGui)
    GuiToggleBtn.Size = UDim2.new(0,120,0,35)
    GuiToggleBtn.Position = UDim2.new(0,10,0,10)
    GuiToggleBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    GuiToggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
    GuiToggleBtn.TextScaled = true
    GuiToggleBtn.Text = "Toggle GUI"
    GuiToggleBtn.Font = Enum.Font.GothamBold
    local guiVisible = true
    GuiToggleBtn.MouseButton1Click:Connect(function()
        guiVisible = not guiVisible
        MainFrame.Visible = guiVisible
    end)

    -- =================== ESP Functions ===================
    local function GetTeamColor(player)
        if player.Team == LocalPlayer.Team then
            return Color3.fromRGB(0,255,0)
        else
            return Color3.fromRGB(255,0,0)
        end
    end

    local function CreateESP(player)
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
        if not PlayerSettings[player] or not PlayerSettings[player].ESP then return end

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

    -- =================== Premium Fly System ===================
    local FlyEnabled = false
    local FlySpeed = 50
    local BodyVelocity, BodyGyro

    if keyType == "Premium" then
        local FlyBtn = Instance.new("TextButton", MainFrame)
        FlyBtn.Size = UDim2.new(0.4,0,0,35)
        FlyBtn.Position = UDim2.new(0.05,0,0,400)
        FlyBtn.BackgroundColor3 = Color3.fromRGB(100,0,255)
        FlyBtn.TextColor3 = Color3.fromRGB(255,255,255)
        FlyBtn.TextScaled = true
        FlyBtn.Text = "Toggle Fly"
        Instance.new("UICorner", FlyBtn).CornerRadius = UDim.new(0,5)
        FlyBtn.MouseButton1Click:Connect(function()
            FlyEnabled = not FlyEnabled
            if FlyEnabled then
                local char = LocalPlayer.Character
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChild("Humanoid")
                if hrp and hum then
                    hum.PlatformStand = true
                    BodyVelocity = Instance.new("BodyVelocity", hrp)
                    BodyVelocity.MaxForce = Vector3.new(1e5,1e5,1e5)
                    BodyGyro = Instance.new("BodyGyro", hrp)
                    BodyGyro.MaxTorque = Vector3.new(1e5,1e5,1e5)
                end
            else
                local char = LocalPlayer.Character
                local hum = char:FindFirstChild("Humanoid")
                if hum then hum.PlatformStand = false end
                if BodyVelocity then BodyVelocity:Destroy() BodyVelocity = nil end
                if BodyGyro then BodyGyro:Destroy() BodyGyro = nil end
            end
        end)

        -- Slider สำหรับปรับความเร็วบิน
        local speedSlider = Instance.new("Frame", MainFrame)
        speedSlider.Size = UDim2.new(0.4,0,0,20)
        speedSlider.Position = UDim2.new(0.55,0,0,410)
        speedSlider.BackgroundColor3 = Color3.fromRGB(80,80,80)
        Instance.new("UICorner", speedSlider).CornerRadius = UDim.new(0,5)

        local fill = Instance.new("Frame", speedSlider)
        fill.Size = UDim2.new(0.5,0,1,0)
        fill.BackgroundColor3 = Color3.fromRGB(200,100,255)
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0,5)

        local dragging = false
        speedSlider.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
        end)
        speedSlider.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
        speedSlider.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local relativeX = math.clamp(input.Position.X - speedSlider.AbsolutePosition.X,0,speedSlider.AbsoluteSize.X)
                fill.Size = UDim2.new(relativeX/speedSlider.AbsoluteSize.X,0,1,0)
                FlySpeed = 50 + (relativeX/speedSlider.AbsoluteSize.X)*200
            end
        end)
    end

    -- =================== Main Loop ===================
    RunService.RenderStepped:Connect(function()
        FOVCircle.Visible = FOVEnabled
        if FOVEnabled then
            FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
            FOVCircle.Radius = FOV
        end

        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                if not PlayerSettings[player] then PlayerSettings[player] = {ESP=true,TeamCheck=true,WallCheck=true} end
                if PlayerSettings[player].ESP
