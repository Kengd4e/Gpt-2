-- Services
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Settings
local Settings = {
    AimbotEnabled = true,
    ESPEnabled = true,
    FOV = 150,
    TeamCheck = true,
    WallCheck = true
}

-- Create GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SmoothAimbotGUI"
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0,220,0,250)
MainFrame.Position = UDim2.new(0,10,0,10)
MainFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
MainFrame.ClipsDescendants = true

local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 2
UIStroke.Color = Color3.fromRGB(255, 255, 255)
UIStroke.Parent = MainFrame

-- Function to create smooth toggle button
local function CreateToggle(name, pos, settingKey)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,200,0,30)
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Text = name.." : "..(Settings[settingKey] and "ON" or "OFF")
    btn.Parent = MainFrame

    btn.MouseButton1Click:Connect(function()
        Settings[settingKey] = not Settings[settingKey]
        local color = Settings[settingKey] and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
        local tween = TweenService:Create(btn,TweenInfo.new(0.3,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{BackgroundColor3=color})
        tween:Play()
        btn.Text = name.." : "..(Settings[settingKey] and "ON" or "OFF")
    end)
end

-- Function to create smooth slider
local function CreateSlider(name, pos, min, max, key)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(0,200,0,30)
    sliderFrame.Position = pos
    sliderFrame.BackgroundColor3 = Color3.fromRGB(50,50,50)
    sliderFrame.Parent = MainFrame

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((Settings[key]-min)/(max-min),0,1,0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(0,170,255)
    sliderFill.Parent = sliderFrame

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1,0,1,0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.fromRGB(255,255,255)
    textLabel.Text = name.." : "..Settings[key]
    textLabel.Parent = sliderFrame

    sliderFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local uis = game:GetService("UserInputService")
            local conn
            conn = uis.InputChanged:Connect(function(mouse)
                if mouse.UserInputType == Enum.UserInputType.MouseMovement then
                    local delta = mouse.Position.X - sliderFrame.AbsolutePosition.X
                    local value = math.clamp(min + (delta/sliderFrame.AbsoluteSize.X)*(max-min),min,max)
                    Settings[key] = math.floor(value)
                    local tween = TweenService:Create(sliderFill,TweenInfo.new(0.1,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{Size=UDim2.new((value-min)/(max-min),0,1,0)})
                    tween:Play()
                    textLabel.Text = name.." : "..Settings[key]
                end
            end)
            uis.InputEnded:Connect(function()
                conn:Disconnect()
            end)
        end
    end)
end

-- Create toggles
CreateToggle("Aimbot", UDim2.new(0,10,0,10),"AimbotEnabled")
CreateToggle("ESP", UDim2.new(0,10,0,50),"ESPEnabled")
CreateToggle("TeamCheck", UDim2.new(0,10,0,90),"TeamCheck")
CreateToggle("WallCheck", UDim2.new(0,10,0,130),"WallCheck")

-- Create FOV slider
CreateSlider("FOV", UDim2.new(0,10,0,170),50,500,"FOV")
