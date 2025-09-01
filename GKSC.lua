-- 🐄 CowHub | Gunung Kalimantan (Rayfield UI)

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
    KeySystem = false
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

----------------------------------------------------------------------
-- Players Tab
----------------------------------------------------------------------
local PlayerTab = Window:CreateTab("Players", 4483362458)
PlayerTab:CreateSection("Teleport to Players")

local playerButtons = {}

local function refreshPlayers()
    -- destroy old buttons
    for _, btn in pairs(playerButtons) do
        btn.Visible = false
    end
    playerButtons = {}

    -- create new buttons
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local button = PlayerTab:CreateButton({
                Name = "Teleport to " .. plr.Name,
                Callback = function()
                    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character:MoveTo(plr.Character.HumanoidRootPart.Position + Vector3.new(2,0,2))
                    end
                end
            })
            table.insert(playerButtons, button)
        end
    end
end

-- Update automatically every few seconds
task.spawn(function()
    while task.wait(3) do
        refreshPlayers()
    end
end)

----------------------------------------------------------------------
-- Checkpoints Tab
----------------------------------------------------------------------
local CheckpointTab = Window:CreateTab("Checkpoints", 4483362458)
CheckpointTab:CreateSection("Teleport to Checkpoints")

local checkpointButtons = {}

local function refreshCheckpoints()
    for _, btn in pairs(checkpointButtons) do
        btn.Visible = false
    end
    checkpointButtons = {}

    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:lower():find("checkpoint") then
            local button = CheckpointTab:CreateButton({
                Name = obj.Name,
                Callback = function()
                    LocalPlayer.Character:MoveTo(obj.Position + Vector3.new(0,5,0))
                end
            })
            table.insert(checkpointButtons, button)
        end
    end
end

task.spawn(function()
    while task.wait(5) do
        refreshCheckpoints()
    end
end)

----------------------------------------------------------------------
-- Movement Tab
----------------------------------------------------------------------
local MovementTab = Window:CreateTab("Movement", 4483362458)
MovementTab:CreateSection("Movement Settings")

-- WalkSpeed Slider
MovementTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 100},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 16,
    Callback = function(Value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = Value
        end
    end,
})

-- Fly Toggle
local flying = false
MovementTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Callback = function(Value)
        flying = Value
        local hrp = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
        while flying and task.wait() do
            hrp.Velocity = Vector3.new(0,30,0)
        end
    end
})

-- Noclip Toggle
local noclip = false
MovementTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(Value)
        noclip = Value
    end
})

game:GetService("RunService").Stepped:Connect(function()
    if noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)
