-- Load Rayfield
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- Create Window
local Window = Rayfield:CreateWindow({
    Name = "🐄 CowHub | Gunung Kalimantan",
    LoadingTitle = "Loading CowHub...",
    LoadingSubtitle = "by You",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "CowHubConfig",
        FileName = "GKSC_Config"
    },
    Discord = {
        Enabled = false,
    },
    KeySystem = false
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- Refresh Character and Humanoid on respawn
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid")
end)

----------------------------------------------------------------------
-- Players Tab
----------------------------------------------------------------------
local PlayerTab = Window:CreateTab("Players", 4483362458)
local PlayerSection = PlayerTab:CreateSection("Teleport to Players")

local playerButtons = {}  -- Table to store buttons for destruction

local function updatePlayerButtons()
    -- Destroy old buttons
    for _, btn in ipairs(playerButtons) do
        btn:Destroy()
    end
    playerButtons = {}  -- Reset table

    -- Create new buttons
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local button = PlayerTab:CreateButton({
                Name = "Teleport to " .. plr.Name,
                Callback = function()
                    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and Character and Character:FindFirstChild("HumanoidRootPart") then
                        Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame + Vector3.new(2, 0, 2)
                    end
                end
            })
            table.insert(playerButtons, button)
        end
    end
end

Players.PlayerAdded:Connect(updatePlayerButtons)
Players.PlayerRemoving:Connect(updatePlayerButtons)
updatePlayerButtons()

----------------------------------------------------------------------
-- Checkpoints Tab
----------------------------------------------------------------------
local CheckpointTab = Window:CreateTab("Checkpoints", 4483362458)
local CheckpointSection = CheckpointTab:CreateSection("Teleport to Checkpoints")

local function getCheckpointPosition(obj)
    if obj:IsA("BasePart") then
        return obj.Position
    elseif obj:IsA("Model") and obj.PrimaryPart then
        return obj.PrimaryPart.Position
    elseif obj:IsA("Model") then
        -- Find a suitable part, e.g., first BasePart
        for _, child in pairs(obj:GetChildren()) do
            if child:IsA("BasePart") then
                return child.Position
            end
        end
    end
    return nil  -- No valid position
end

local function loadCheckpoints()
    local checkpoints = {}
    
    -- Search for any descendant with "checkpoint" in name (case insensitive)
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name:lower():find("checkpoint") then
            local pos = getCheckpointPosition(obj)
            if pos then
                table.insert(checkpoints, {name = obj.Name, obj = obj, pos = pos})
            end
        end
    end
    
    -- Sort by extracting numbers from names for ascending order
    table.sort(checkpoints, function(a, b)
        local numA = tonumber(a.name:match("%d+")) or 0
        local numB = tonumber(b.name:match("%d+")) or 0
        return numA < numB
    end)
    
    -- Create buttons in sorted order
    for _, cp in ipairs(checkpoints) do
        CheckpointTab:CreateButton({
            Name = cp.name,
            Callback = function()
                if Character and Character:FindFirstChild("HumanoidRootPart") then
                    Character.HumanoidRootPart.CFrame = CFrame.new(cp.pos + Vector3.new(0, 5, 0))
                end
            end
        })
    end
end

loadCheckpoints()

----------------------------------------------------------------------
-- Movement Tab
----------------------------------------------------------------------
local MovementTab = Window:CreateTab("Movement", 4483362458)
local MovementSection = MovementTab:CreateSection("Movement Settings")

-- WalkSpeed Slider
MovementTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 100},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 16,
    Callback = function(Value)
        Humanoid.WalkSpeed = Value
    end,
})

-- Fly Toggle (with fixed controls and hover)
local flying = false
local flyConnection
MovementTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Callback = function(Value)
        flying = Value
        local hrp = Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        if flying then
            flyConnection = game:GetService("RunService").Heartbeat:Connect(function()
                local moveDir = Vector3.new()
                local userInput = game:GetService("UserInputService")
                if userInput:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Vector3.new(0, 0, 1) end  -- Forward
                if userInput:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir + Vector3.new(0, 0, -1) end  -- Backward
                if userInput:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir + Vector3.new(-1, 0, 0) end  -- Left
                if userInput:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Vector3.new(1, 0, 0) end  -- Right
                if userInput:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end  -- Up
                if userInput:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir + Vector3.new(0, -1, 0) end  -- Down

                local primaryPart = Character.PrimaryPart or hrp
                local velocity = (primaryPart.CFrame.LookVector * moveDir.Z + primaryPart.CFrame.RightVector * moveDir.X + Vector3.new(0, moveDir.Y, 0)) * 50
                
                -- To hover when no vertical input, set Y to 0 (resets velocity Y each frame to counter gravity)
                hrp.Velocity = velocity
            end)
        else
            if flyConnection then
                flyConnection:Disconnect()
                flyConnection = nil
            end
            hrp.Velocity = Vector3.new(0, 0, 0)
        end
    end
})

-- Noclip Toggle
local noclip = false
local noclipConnection
MovementTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(Value)
        noclip = Value
        if noclip then
            noclipConnection = game:GetService("RunService").Stepped:Connect(function()
                if Character then
                    for _, part in pairs(Character:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        else
            if noclipConnection then
                noclipConnection:Disconnect()
                noclipConnection = nil
            end
            -- Re-enable collision if needed
            if Character then
                for _, part in pairs(Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
    end
})
