-- 🐄 CowHub | Gunung Kalimantan Utility Hub
-- Works with Delta (Mobile) & Xeno (PC)

-- // SERVICES
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- // SETTINGS
local DEFAULT_SPEED = 16
local LOGO_ID = "rbxassetid://YOUR_LOGO_ID" -- put your logo asset id here

-- // DRAG FUNCTION
local function makeDraggable(frame)
    local dragToggle, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragToggle = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragToggle = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragToggle and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                       startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- // MAIN GUI
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "CowHubUI"

-- TopBar Frame
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 400, 0, 300)
MainFrame.Position = UDim2.new(0.3, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Active = true
MainFrame.Draggable = false
makeDraggable(MainFrame)

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

-- Title Bar
local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 30)
TopBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(1, -60, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.Text = "🐄 CowHub | Gunung Kalimantan"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14

-- Minimize & Close
local MinimizeBtn = Instance.new("TextButton", TopBar)
MinimizeBtn.Text = "-"
MinimizeBtn.Size = UDim2.new(0, 25, 0, 25)
MinimizeBtn.Position = UDim2.new(1, -55, 0.5, -12)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)

local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.Text = "X"
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -30, 0.5, -12)
CloseBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 50)

-- Tab Buttons
local TabFrame = Instance.new("Frame", MainFrame)
TabFrame.Size = UDim2.new(0, 100, 1, -30)
TabFrame.Position = UDim2.new(0, 0, 0, 30)
TabFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

local ContentFrame = Instance.new("Frame", MainFrame)
ContentFrame.Size = UDim2.new(1, -100, 1, -30)
ContentFrame.Position = UDim2.new(0, 100, 0, 30)
ContentFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)

-- Tabs: Players / Checkpoints / Movement
local tabs = {}
local function createTab(name)
    local btn = Instance.new("TextButton", TabFrame)
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.Text = name
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)

    local frame = Instance.new("ScrollingFrame", ContentFrame)
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Visible = false
    frame.ScrollBarThickness = 6

    tabs[name] = {Button = btn, Frame = frame}

    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(tabs) do t.Frame.Visible = false end
        frame.Visible = true
    end)
end

createTab("Players")
createTab("Checkpoints")
createTab("Movement")

tabs["Players"].Frame.Visible = true -- default

-- Players Tab
local function updatePlayers()
    tabs["Players"].Frame:ClearAllChildren()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local btn = Instance.new("TextButton", tabs["Players"].Frame)
            btn.Size = UDim2.new(1, -10, 0, 30)
            btn.Position = UDim2.new(0, 5, 0, (#tabs["Players"].Frame:GetChildren()-1)*35)
            btn.Text = plr.Name
            btn.MouseButton1Click:Connect(function()
                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    Character:MoveTo(plr.Character.HumanoidRootPart.Position + Vector3.new(2,0,2))
                end
            end)
        end
    end
end
Players.PlayerAdded:Connect(updatePlayers)
Players.PlayerRemoving:Connect(updatePlayers)
updatePlayers()

-- Checkpoints Tab
for _, obj in pairs(workspace:GetDescendants()) do
    if obj:IsA("BasePart") and obj.Name:lower():find("checkpoint") then
        local btn = Instance.new("TextButton", tabs["Checkpoints"].Frame)
        btn.Size = UDim2.new(1, -10, 0, 30)
        btn.Position = UDim2.new(0, 5, 0, (#tabs["Checkpoints"].Frame:GetChildren()-1)*35)
        btn.Text = obj.Name
        btn.MouseButton1Click:Connect(function()
            Character:MoveTo(obj.Position + Vector3.new(0,5,0))
        end)
    end
end

-- Movement Tab
local speedLabel = Instance.new("TextLabel", tabs["Movement"].Frame)
speedLabel.Text = "WalkSpeed"
speedLabel.Size = UDim2.new(0, 200, 0, 30)
speedLabel.Position = UDim2.new(0, 10, 0, 10)
speedLabel.TextColor3 = Color3.new(1,1,1)
speedLabel.BackgroundTransparency = 1

local speedBox = Instance.new("TextBox", tabs["Movement"].Frame)
speedBox.Size = UDim2.new(0, 100, 0, 30)
speedBox.Position = UDim2.new(0, 220, 0, 10)
speedBox.Text = tostring(DEFAULT_SPEED)
speedBox.FocusLost:Connect(function()
    local val = tonumber(speedBox.Text)
    if val then Humanoid.WalkSpeed = val end
end)

-- Minimize -> Logo
local MinLogo = Instance.new("ImageButton", ScreenGui)
MinLogo.Size = UDim2.new(0, 50, 0, 50)
MinLogo.Position = UDim2.new(0.5, -25, 0.9, -25)
MinLogo.Image = LOGO_ID
MinLogo.Visible = false
makeDraggable(MinLogo)

MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    MinLogo.Visible = true
end)
MinLogo.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    MinLogo.Visible = false
end)
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

print("🐄 CowHub | Gunung Kalimantan Utility Loaded Successfully")
