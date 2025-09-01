-- // Gunung Kalimantan Utility GUI
-- // Compatible: Delta (Mobile), Xeno (PC), other executors
-- // Features: Player TP, Checkpoint TP, Fly, Noclip, Walkspeed Slider, Minimize/Close

-- CONFIG
local DEFAULT_SPEED = 16
local LOGO_ID = "rbxassetid://YOUR_LOGO_ID_HERE" -- Replace with your own logo asset id

-- Services
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GK_GUI"
ScreenGui.Parent = game.CoreGui
ScreenGui.ResetOnSpawn = false

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 350, 0, 400)
MainFrame.Position = UDim2.new(0.3, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- Top Bar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 30)
TopBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
TopBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Text = "Gunung Kalimantan Utility"
Title.Size = UDim2.new(1, -60, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

-- Minimize Button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 25, 0, 25)
MinBtn.Position = UDim2.new(1, -60, 0, 2)
MinBtn.Text = "-"
MinBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Parent = TopBar

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -30, 0, 2)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Parent = TopBar

-- Minimized Logo
local MinLogo = Instance.new("ImageButton")
MinLogo.Size = UDim2.new(0, 50, 0, 50)
MinLogo.Position = UDim2.new(0.05, 0, 0.5, 0)
MinLogo.Image = LOGO_ID
MinLogo.Visible = false
MinLogo.BackgroundTransparency = 1
MinLogo.Parent = ScreenGui

-- Make Logo Draggable
local dragging = false
local dragInput, dragStart, startPos
MinLogo.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MinLogo.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MinLogo.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Toggle Minimize
MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    MinLogo.Visible = true
end)
MinLogo.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    MinLogo.Visible = false
end)

-- Close
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Container (Scrolling for Player/Checkpoint)
local Container = Instance.new("Frame")
Container.Size = UDim2.new(1, -20, 1, -50)
Container.Position = UDim2.new(0, 10, 0, 40)
Container.BackgroundTransparency = 1
Container.Parent = MainFrame

-- ScrollFrame for Players
local PlayerScroll = Instance.new("ScrollingFrame")
PlayerScroll.Size = UDim2.new(0.5, -5, 1, 0)
PlayerScroll.Position = UDim2.new(0, 0, 0, 0)
PlayerScroll.CanvasSize = UDim2.new(0,0,0,0)
PlayerScroll.ScrollBarThickness = 6
PlayerScroll.BackgroundColor3 = Color3.fromRGB(35,35,35)
PlayerScroll.Parent = Container

-- ScrollFrame for Checkpoints
local CheckScroll = Instance.new("ScrollingFrame")
CheckScroll.Size = UDim2.new(0.5, -5, 1, 0)
CheckScroll.Position = UDim2.new(0.5, 5, 0, 0)
CheckScroll.CanvasSize = UDim2.new(0,0,0,0)
CheckScroll.ScrollBarThickness = 6
CheckScroll.BackgroundColor3 = Color3.fromRGB(35,35,35)
CheckScroll.Parent = Container

-- Function to teleport
local function tpTo(pos)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = pos
    end
end

-- Update Player List
local function updatePlayers()
    PlayerScroll:ClearAllChildren()
    local y = 0
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, -5, 0, 25)
            Btn.Position = UDim2.new(0, 0, 0, y)
            Btn.Text = plr.Name
            Btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
            Btn.TextColor3 = Color3.fromRGB(255,255,255)
            Btn.Parent = PlayerScroll
            Btn.MouseButton1Click:Connect(function()
                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    tpTo(plr.Character.HumanoidRootPart.CFrame)
                end
            end)
            y = y + 30
        end
    end
    PlayerScroll.CanvasSize = UDim2.new(0,0,0,y)
end

Players.PlayerAdded:Connect(updatePlayers)
Players.PlayerRemoving:Connect(updatePlayers)
updatePlayers()

-- Update Checkpoints
local function updateCheckpoints()
    CheckScroll:ClearAllChildren()
    local y = 0
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and string.find(obj.Name:lower(), "checkpoint") then
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, -5, 0, 25)
            Btn.Position = UDim2.new(0, 0, 0, y)
            Btn.Text = obj.Name
            Btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
            Btn.TextColor3 = Color3.fromRGB(255,255,255)
            Btn.Parent = CheckScroll
            Btn.MouseButton1Click:Connect(function()
                tpTo(obj.CFrame + Vector3.new(0,3,0))
            end)
            y = y + 30
        end
    end
    CheckScroll.CanvasSize = UDim2.new(0,0,0,y)
end

updateCheckpoints()

-- Walkspeed slider
local SliderFrame = Instance.new("Frame")
SliderFrame.Size = UDim2.new(1, 0, 0, 40)
SliderFrame.Position = UDim2.new(0, 0, 1, -45)
SliderFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
SliderFrame.Parent = MainFrame

local SliderBar = Instance.new("Frame")
SliderBar.Size = UDim2.new(0.8, 0, 0.3, 0)
SliderBar.Position = UDim2.new(0.1, 0, 0.5, -5)
SliderBar.BackgroundColor3 = Color3.fromRGB(80,80,80)
SliderBar.Parent = SliderFrame

local Knob = Instance.new("Frame")
Knob.Size = UDim2.new(0, 10, 1.5, 0)
Knob.Position = UDim2.new(0, 0, -0.25, 0)
Knob.BackgroundColor3 = Color3.fromRGB(200,200,200)
Knob.Active = true
Knob.Draggable = true
Knob.Parent = SliderBar

local function setSpeedByKnob()
    local percent = Knob.Position.X.Offset / (SliderBar.AbsoluteSize.X - Knob.AbsoluteSize.X)
    percent = math.clamp(percent, 0, 1)
    local speed = DEFAULT_SPEED + math.floor(percent * 100)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = speed
    end
end

Knob:GetPropertyChangedSignal("Position"):Connect(setSpeedByKnob)

-- Reset Button
local ResetBtn = Instance.new("TextButton")
ResetBtn.Size = UDim2.new(0.2,0,0.6,0)
ResetBtn.Position = UDim2.new(0.8,0,0.2,0)
ResetBtn.Text = "Reset"
ResetBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)
ResetBtn.TextColor3 = Color3.fromRGB(255,255,255)
ResetBtn.Parent = SliderFrame
ResetBtn.MouseButton1Click:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = DEFAULT_SPEED
    end
end)

-- Fly/Noclip
local flying = false
local noclip = false
local flyConnection

local FlyBtn = Instance.new("TextButton")
FlyBtn.Size = UDim2.new(0.5, -5, 0, 30)
FlyBtn.Position = UDim2.new(0,0,1,-80)
FlyBtn.Text = "Fly: OFF"
FlyBtn.BackgroundColor3 = Color3.fromRGB(60,60,100)
FlyBtn.TextColor3 = Color3.fromRGB(255,255,255)
FlyBtn.Parent = MainFrame

local NoclipBtn = Instance.new("TextButton")
NoclipBtn.Size = UDim2.new(0.5, -5, 0, 30)
NoclipBtn.Position = UDim2.new(0.5,5,1,-80)
NoclipBtn.Text = "Noclip: OFF"
NoclipBtn.BackgroundColor3 = Color3.fromRGB(100,60,60)
NoclipBtn.TextColor3 = Color3.fromRGB(255,255,255)
NoclipBtn.Parent = MainFrame

-- Fly function
local function toggleFly()
    flying = not flying
    FlyBtn.Text = "Fly: " .. (flying and "ON" or "OFF")
    if flying then
        flyConnection = RunService.RenderStepped:Connect(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local HRP = LocalPlayer.Character.HumanoidRootPart
                local camCF = workspace.CurrentCamera.CFrame
                local moveDir = Vector3.new()
                if UIS:IsKeyDown(Enum.KeyCode.W) then
                    moveDir = moveDir + camCF.LookVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.S) then
                    moveDir = moveDir - camCF.LookVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.A) then
                    moveDir = moveDir - camCF.RightVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.D) then
                    moveDir = moveDir + camCF.RightVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then
                    moveDir = moveDir + Vector3.new(0,1,0)
                end
                if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
                    moveDir = moveDir - Vector3.new(0,1,0)
                end
                if moveDir.Magnitude > 0 then
                    HRP.Velocity = moveDir.Unit * 50
                else
                    HRP.Velocity = Vector3.new(0,0,0)
                end
            end
        end)
    else
        if flyConnection then flyConnection:Disconnect() end
    end
end

FlyBtn.MouseButton1Click:Connect(toggleFly)

-- Noclip function
RunService.Stepped:Connect(function()
    if noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

NoclipBtn.MouseButton1Click:Connect(function()
    noclip = not noclip
    NoclipBtn.Text = "Noclip: " .. (noclip and "ON" or "OFF")
end)
