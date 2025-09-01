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
    Discord = {
        Enabled = false,
    },
    KeySystem = false
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

----------------------------------------------------------------------
-- Players Tab
----------------------------------------------------------------------
local PlayerTab = Window:CreateTab("Players", 4483362458)
local PlayerSection = PlayerTab:CreateSection("Teleport to Players")

local function updatePlayerButtons()
    PlayerTab:Clear() -- clears all old buttons before regenerating

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            PlayerTab:CreateButton({
                Name = "Teleport to " .. plr.Name,
                Callback = function()
                    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        Character:MoveTo(plr.Character.HumanoidRootPart.Position + Vector3.new(2,0,2))
                    end
                end
            })
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

local function loadCheckpoints()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:lower():find("checkpoint") then
            CheckpointTab:CreateButton({
                Name = obj.Name,
                Callback = function()
                    Character:MoveTo(obj.Position + Vector3.new(0,5,0))
                end
            })
        end
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

-- Fly Toggle
local flying = false
MovementTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Callback = function(Value)
        flying = Value
        local hrp = Character:WaitForChild("HumanoidRootPart")
        while flying and task.wait() do
            hrp.Velocity = Vector3.new(0,30,0) -- float upwards
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
        game:GetService("RunService").Stepped:Connect(function()
            if noclip and Character then
                for _, part in pairs(Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
})
