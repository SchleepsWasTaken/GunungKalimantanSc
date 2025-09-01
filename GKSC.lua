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
local refreshPlayerButton

local function updatePlayerButtons()
    -- Destroy old buttons (except refresh)
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
                        Character:MoveTo(plr.Character.HumanoidRootPart.Position + Vector3.new(2, 0, 2))
                    end
                end
            })
            table.insert(playerButtons, button)
        end
    end
end

-- Add a manual refresh button
refreshPlayerButton = PlayerTab:CreateButton({
    Name = "Refresh Players",
    Callback = updatePlayerButtons
})

Players.PlayerAdded:Connect(updatePlayerButtons)
Players.PlayerRemoving:Connect(updatePlayerButtons)
updatePlayerButtons()

----------------------------------------------------------------------
-- Checkpoints Tab
----------------------------------------------------------------------
local CheckpointTab = Window:CreateTab("Checkpoints", 4483362458)
local CheckpointSection = CheckpointTab:CreateSection("Teleport to Checkpoints")

local checkpointButtons = {}  -- Table to store checkpoint buttons
local refreshCheckpointButton
local checkpointLabel

local function getCheckpointPosition(obj)
    if obj:IsA("BasePart") or obj:IsA("SpawnLocation") then
        return obj.Position
    elseif obj:IsA("Model") and obj.PrimaryPart then
        return obj.PrimaryPart.Position
    elseif obj:IsA("Model") then
        -- Find a suitable part, e.g., first BasePart
        for _, child in pairs(obj:GetDescendants()) do
            if child:IsA("BasePart") then
                return child.Position
            end
        end
    end
    return nil  -- No valid position
end

local function updateCheckpoints()
    -- Destroy old buttons and label
    for _, btn in ipairs(checkpointButtons) do
        btn:Destroy()
    end
    checkpointButtons = {}
    if checkpointLabel then
        checkpointLabel:Destroy()
    end

    local checkpoints = {}
    
    -- Broader search: include more keywords and SpawnLocation
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") then
            local pos = getCheckpointPosition(obj)
            if pos then
                table.insert(checkpoints, {name = obj.Name .. " (Spawn)", obj = obj, pos = pos})
            end
        else
            local lowerName = obj.Name:lower()
            if lowerName:find("checkpoint") or lowerName:find("pos") or lowerName:find("cp") or 
               lowerName:find("stage") or lowerName:find("spawn") or lowerName:find("bonfire") or 
               lowerName:find("portal") then
                local pos = getCheckpointPosition(obj)
                if pos then
                    table.insert(checkpoints, {name = obj.Name, obj = obj, pos = pos})
                end
            end
        end
    end
    
    -- Remove duplicates by approx position
    local uniqueCheckpoints = {}
    local seen = {}
    for _, cp in ipairs(checkpoints) do
        local key = math.floor(cp.pos.X / 10) .. "_" .. math.floor(cp.pos.Y / 10) .. "_" .. math.floor(cp.pos.Z / 10)
        if not seen[key] then
            seen[key] = true
            table.insert(uniqueCheckpoints, cp)
        end
    end
    checkpoints = uniqueCheckpoints
    
    -- Sort by Y position ascending
    table.sort(checkpoints, function(a, b)
        return a.pos.Y < b.pos.Y
    end)
    
    -- Create buttons in sorted order
    for _, cp in ipairs(checkpoints) do
        local button = CheckpointTab:CreateButton({
            Name = cp.name .. " (Y: " .. math.floor(cp.pos.Y) .. ")",
            Callback = function()
                if Character and Character:FindFirstChild("HumanoidRootPart") then
                    Character:MoveTo(cp.pos + Vector3.new(0, 5, 0))
                end
            end
        })
        table.insert(checkpointButtons, button)
    end
    
    -- Add a label with count
    checkpointLabel = CheckpointTab:CreateLabel("Found " .. #checkpoints .. " checkpoints")
end

-- Add a manual refresh button for checkpoints
refreshCheckpointButton = CheckpointTab:CreateButton({
    Name = "Refresh Checkpoints",
    Callback = updateCheckpoints
})

-- Initial load
updateCheckpoints()

-- Optional: Reload on workspace changes (if checkpoints load dynamically)
workspace.ChildAdded:Connect(function(child)
    if child:IsA("BasePart") or child:IsA("Model") or child:IsA("SpawnLocation") then
        updateCheckpoints()
    end
end)

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

-- Fly Toggle (with swapped W/S for reverse feel)
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
                if userInput:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Vector3.new(0, 0, -1) end  -- Swapped for reverse
                if userInput:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir + Vector3.new(0, 0, 1) end   -- Swapped
                if userInput:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir + Vector3.new(-1, 0, 0) end
                if userInput:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Vector3.new(1, 0, 0) end
                if userInput:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                if userInput:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir + Vector3.new(0, -1, 0) end

                local primaryPart = Character.PrimaryPart or hrp
                local velocity = (primaryPart.CFrame.LookVector * moveDir.Z + primaryPart.CFrame.RightVector * moveDir.X + Vector3.new(0, moveDir.Y, 0)) * 50
                
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
