-- 🐄 CowHub | Gunung Kalimantan

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
    Discord = {Enabled = false},
    KeySystem = false
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- Refresh character on respawn
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid")
end)

----------------------------------------------------------------------
-- Players Tab (Auto Updating)
----------------------------------------------------------------------
local PlayerTab = Window:CreateTab("Players", 4483362458)
PlayerTab:CreateSection("Teleport to Players")

local playerButtons = {}

local function updatePlayers()
    for _, btn in ipairs(playerButtons) do
        btn:Destroy()
    end
    playerButtons = {}

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local button = PlayerTab:CreateButton({
                Name = "Teleport to " .. plr.Name,
                Callback = function()
                    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and Character and Character:FindFirstChild("HumanoidRootPart") then
                        Character:MoveTo(plr.Character.HumanoidRootPart.Position + Vector3.new(2,0,2))
                    end
                end
            })
            table.insert(playerButtons, button)
        end
    end
end

-- Auto-update every 3 seconds
task.spawn(function()
    while task.wait(3) do
        updatePlayers()
    end
end)

----------------------------------------------------------------------
-- Checkpoints Tab (Auto Updating)
----------------------------------------------------------------------
local CheckpointTab = Window:CreateTab("Checkpoints", 4483362458)
CheckpointTab:CreateSection("Teleport to Checkpoints")

local checkpointButtons = {}
local checkpointLabel

local function getCheckpointPosition(obj)
    if obj:IsA("BasePart") or obj:IsA("SpawnLocation") then
        return obj.Position
    elseif obj:IsA("Model") and obj.PrimaryPart then
        return obj.PrimaryPart.Position
    elseif obj:IsA("Model") then
        for _, child in pairs(obj:GetDescendants()) do
            if child:IsA("BasePart") then
                return child.Position
            end
        end
    end
    return nil
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

    -- Search everything in workspace EXCEPT spawners
    for _, obj in pairs(workspace:GetDescendants()) do
        local lowerName = obj.Name:lower()

        -- Only catch true checkpoint objects, ignore spawns
        if (lowerName:find("checkpoint") or lowerName:find("cp") or lowerName:find("stage") 
            or lowerName:find("pos") or lowerName:find("bonfire") or lowerName:find("portal") 
            or lowerName:find("finish") or lowerName:find("goal")) 
            and not obj:IsA("SpawnLocation") then

            local pos = getCheckpointPosition(obj)
            if pos then
                table.insert(checkpoints, {name = obj.Name, obj = obj, pos = pos})
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

    -- Sort by Y so you see them in order of height (lowest → highest)
    table.sort(checkpoints, function(a, b)
        return a.pos.Y < b.pos.Y
    end)

    -- Create buttons
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

    -- Add label with count
    checkpointLabel = CheckpointTab:CreateLabel("Found " .. #checkpoints .. " checkpoints")
end



-- Auto-update every 5 seconds
task.spawn(function()
    while task.wait(5) do
        updateCheckpoints()
    end
end)

----------------------------------------------------------------------
-- Movement Tab
----------------------------------------------------------------------
local MovementTab = Window:CreateTab("Movement", 4483362458)
MovementTab:CreateSection("Movement Settings")

MovementTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16,100},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(v) Humanoid.WalkSpeed = v end
})

local flying, flyConnection = false, nil
MovementTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Callback = function(v)
        flying = v
        local hrp = Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if flying then
            flyConnection = game:GetService("RunService").Heartbeat:Connect(function()
                local uis = game:GetService("UserInputService")
                local dir = Vector3.new()
                if uis:IsKeyDown(Enum.KeyCode.W) then dir = dir+Vector3.new(0,0,-1) end
                if uis:IsKeyDown(Enum.KeyCode.S) then dir = dir+Vector3.new(0,0,1) end
                if uis:IsKeyDown(Enum.KeyCode.A) then dir = dir+Vector3.new(-1,0,0) end
                if uis:IsKeyDown(Enum.KeyCode.D) then dir = dir+Vector3.new(1,0,0) end
                if uis:IsKeyDown(Enum.KeyCode.Space) then dir = dir+Vector3.new(0,1,0) end
                if uis:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir+Vector3.new(0,-1,0) end
                hrp.Velocity = (hrp.CFrame.LookVector*dir.Z + hrp.CFrame.RightVector*dir.X + Vector3.new(0,dir.Y,0))*50
            end)
        else
            if flyConnection then flyConnection:Disconnect() flyConnection=nil end
            hrp.Velocity = Vector3.new()
        end
    end
})

local noclip, noclipConnection = false, nil
MovementTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(v)
        noclip = v
        if noclip then
            noclipConnection = game:GetService("RunService").Stepped:Connect(function()
                if Character then
                    for _, p in pairs(Character:GetChildren()) do
                        if p:IsA("BasePart") then p.CanCollide=false end
                    end
                end
            end)
        else
            if noclipConnection then noclipConnection:Disconnect() noclipConnection=nil end
            if Character then
                for _, p in pairs(Character:GetChildren()) do
                    if p:IsA("BasePart") then p.CanCollide=true end
                end
            end
        end
    end
})
