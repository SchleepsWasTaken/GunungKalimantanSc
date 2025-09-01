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
-- Checkpoints Tab (Filtered Detection)
----------------------------------------------------------------------
local CheckpointTab = Window:CreateTab("Checkpoints", 4483362458)
CheckpointTab:CreateSection("Teleport to Checkpoints")

local checkpointButtons = {}
local checkpointLabel
local checkpoints = {}

-- helper to register a checkpoint
local function registerCheckpoint(obj, pos)
    local key = math.floor(pos.X/5).."_"..math.floor(pos.Y/5).."_"..math.floor(pos.Z/5)
    if checkpoints[key] then return end -- already added

    checkpoints[key] = {name = obj.Name, pos = pos}
    local cp = checkpoints[key]

    local button = CheckpointTab:CreateButton({
        Name = cp.name .. " (Y: " .. math.floor(pos.Y) .. ")",
        Callback = function()
            if Character and Character:FindFirstChild("HumanoidRootPart") then
                Character:MoveTo(pos + Vector3.new(0,5,0))
            end
        end
    })
    table.insert(checkpointButtons, button)
    print("✅ Registered checkpoint:", obj:GetFullName(), "Y =", math.floor(pos.Y))
end

-- scan function with filtering
local function scanForCheckpoints(container)
    for _, obj in pairs(container:GetDescendants()) do
        if obj:IsA("BasePart") then
            local lname = obj.Name:lower()
            -- filter: only real checkpoints
            if lname:find("checkpoint") or lname:find("flag") or lname:find("goal") or lname:find("line") or lname:find("end") then
                if not (lname:find("medkit") or lname:find("kotak") or lname:find("aqua")) then
                    registerCheckpoint(obj, obj.Position)
                end
            end
        elseif obj:IsA("Model") then
            local lname = obj.Name:lower()
            if lname:find("checkpoint") or lname:find("flag") or lname:find("goal") or lname:find("line") or lname:find("end") then
                if not (lname:find("medkit") or lname:find("kotak") or lname:find("aqua")) then
                    local primary = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    if primary then
                        registerCheckpoint(obj, primary.Position)
                    end
                end
            end
        end
    end
end

-- scan important containers
local containers = {workspace, game.ReplicatedStorage, game.Lighting}
for _, c in ipairs(containers) do
    scanForCheckpoints(c)
    c.DescendantAdded:Connect(function(obj)
        task.wait(0.1)
        if obj:IsA("BasePart") then
            local lname = obj.Name:lower()
            if lname:find("checkpoint") or lname:find("flag") or lname:find("goal") or lname:find("line") or lname:find("end") then
                if not (lname:find("medkit") or lname:find("kotak") or lname:find("aqua")) then
                    registerCheckpoint(obj, obj.Position)
                end
            end
        end
    end)
end

-- refresh label & finish line button
task.spawn(function()
    while task.wait(5) do
        if checkpointLabel then checkpointLabel:Destroy() end
        checkpointLabel = CheckpointTab:CreateLabel("Found " .. tostring(#checkpointButtons) .. " checkpoints")

        local highest = nil
        for _, cp in pairs(checkpoints) do
            if not highest or cp.pos.Y > highest.pos.Y then
                highest = cp
            end
        end

        if highest then
            CheckpointTab:CreateButton({
                Name = "🏁 Finish Line (Y: " .. math.floor(highest.pos.Y) .. ")",
                Callback = function()
                    if Character and Character:FindFirstChild("HumanoidRootPart") then
                        Character:MoveTo(highest.pos + Vector3.new(0,10,0))
                    end
                end
            })
        end
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
