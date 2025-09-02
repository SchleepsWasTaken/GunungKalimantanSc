-- 🐄 CowHub | Gunung Kalimantan — Fixed Full Script
-- Features: Players (live, real-time Y, no stacking), Checkpoints (stream-safe, dedupe, saved), Movement (WalkSpeed/Fly/Noclip)

-- Load Rayfield
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
    Name = "🐄 CowHub | Gunung Kalimantan",
    LoadingTitle = "Loading CowHub...",
    LoadingSubtitle = "by You",
    ConfigurationSaving = { Enabled = true, FolderName = "CowHubConfig", FileName = "GKSC_Config" },
    Discord = { Enabled = false },
    KeySystem = false
})
-- Services & player refs
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
LocalPlayer.CharacterAdded:Connect(function(ch) Character = ch; Humanoid = ch:WaitForChild("Humanoid") end)
-- ============================
-- Players Tab (live, real-time Y, no stacking)
-- ============================
local PlayerTab = Window:CreateTab("Players", 4483362458)
PlayerTab:CreateSection("Teleport to Players")
local playerUI = {} -- Store Rayfield button objects
local rebuildDebounce = false
local playerButtons = {} -- Map player to button for real-time updates

local function safeTeleportToPlayer(plr)
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then
        Rayfield:Notify({ Title = "CowHub", Content = "Your character is not loaded", Duration = 3 })
        return
    end
    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
        local targetPos = plr.Character.HumanoidRootPart.Position + Vector3.new(2, 0, 2)
        Character:MoveTo(targetPos)
        Rayfield:Notify({ Title = "CowHub", Content = "Teleported to " .. plr.Name, Duration = 2 })
    else
        Rayfield:Notify({ Title = "CowHub", Content = "Failed to teleport to " .. plr.Name .. ": Player not loaded", Duration = 3 })
    end
end

local function rebuildPlayers()
    if rebuildDebounce then return end
    rebuildDebounce = true

    -- Destroy all existing buttons and clear tables
    for _, b in ipairs(playerUI) do
        pcall(function() if b and b.Destroy then b:Destroy() end end)
    end
    playerUI = {}
    playerButtons = {}

    -- Recreate buttons for current players
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local yPos = "?"
            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                yPos = math.floor(plr.Character.HumanoidRootPart.Position.Y)
            elseif plr.Character then
                for _, part in ipairs(plr.Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        yPos = math.floor(part.Position.Y)
                        break
                    end
                end
            end
            local buttonName = plr.Name .. " (Y:" .. yPos .. ")"
            local ok, btn = pcall(function()
                return PlayerTab:CreateButton({
                    Name = buttonName,
                    Callback = function()
                        safeTeleportToPlayer(plr)
                    end
                })
            end)
            if ok and btn then
                table.insert(playerUI, btn)
                playerButtons[plr] = btn
            end
        end
    end
    rebuildDebounce = false
end

-- Start real-time update loop by rebuilding every 1 second
RunService.RenderStepped:Connect(function()
    task.wait(1) -- Update every 1 second
    rebuildPlayers()
end)

-- Refresh players with debounced events
Players.PlayerAdded:Connect(function(plr)
    task.wait(0.5)
    rebuildPlayers()
    plr.CharacterAppearanceLoaded:Connect(function()
        task.wait(0.5)
        rebuildPlayers()
    end)
end)
Players.PlayerRemoving:Connect(function()
    task.wait(0.5)
    rebuildPlayers()
end)
PlayerTab:CreateButton({
    Name = "Refresh Players",
    Callback = rebuildPlayers
})
rebuildPlayers()
-- ============================
-- Checkpoints Tab (robust)
-- ============================
local CheckpointTab = Window:CreateTab("Checkpoints", 4483362458)
CheckpointTab:CreateSection("Teleport to Checkpoints")
-- Config
local SAVE_FOLDER = "CowHubConfig"
local SAVE_FILE = SAVE_FOLDER .. "/gk_checkpoints.json"
local DEDUPE_TOL = 3 -- studs for dedupe
-- Storage
local checkpoints_map = {} -- key -> {name=string, pos=Vector3}
local checkpoint_buttons = {} -- Rayfield buttons
local saved_list = {} -- array-writable for persistence (table of {name, pos={X,Y,Z}})
-- Filesystem helpers
if isfolder then pcall(function() if not isfolder(SAVE_FOLDER) then makefolder(SAVE_FOLDER) end end) end
local function save_to_file()
    if writefile then
        pcall(function()
            writefile(SAVE_FILE, HttpService:JSONEncode(saved_list))
        end)
    end
end
local function load_from_file()
    if isfile then
        local ok, data = pcall(readfile, SAVE_FILE)
        if ok and data then
            local succ, dec = pcall(function() return HttpService:JSONDecode(data) end)
            if succ and type(dec) == "table" then saved_list = dec end
        end
    end
end
local function vecFromTable(t)
    if typeof(t) == "Vector3" then return t end
    return Vector3.new(t.X or 0, t.Y or 0, t.Z or 0)
end
local function makeKey(pos)
    return math.floor(pos.X / DEDUPE_TOL) .. "_" .. math.floor(pos.Y / DEDUPE_TOL) .. "_" .. math.floor(pos.Z / DEDUPE_TOL)
end
-- Safe teleport (raycast down to find ground)
local function safeTeleport(pos)
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = Character.HumanoidRootPart
    local origin = pos + Vector3.new(0, 160, 0)
    local dir = Vector3.new(0, -400, 0)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = { Character }
    params.FilterType = Enum.RaycastFilterType.Blacklist
    local res = workspace:Raycast(origin, dir, params)
    if res and res.Position then
        local target = res.Position + Vector3.new(0, 4, 0)
        hrp.CFrame = CFrame.new(target)
        hrp.Velocity = Vector3.new(0, 0, 0)
        return
    end
    local res2 = workspace:Raycast(pos + Vector3.new(0, 50, 0), Vector3.new(0, -200, 0), params)
    if res2 and res2.Position then
        local target = res2.Position + Vector3.new(0, 4, 0)
        hrp.CFrame = CFrame.new(target)
        hrp.Velocity = Vector3.new(0, 0, 0)
        return
    end
    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 6, 0))
    hrp.Velocity = Vector3.new(0, 0, 0)
end
-- Safe summit teleport with delay (simulated walk)
local function safeSummitTeleport(targetPos)
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then
        Rayfield:Notify({ Title = "CowHub", Content = "Your character is not loaded", Duration = 3 })
        return
    end
    local hrp = Character.HumanoidRootPart
    local currentPos = hrp.Position
    local distance = (targetPos - currentPos).Magnitude
    local steps = math.max(5, math.floor(distance / 50)) -- At least 5 steps, 50 studs per step
    local stepHeight = (targetPos.Y - currentPos.Y) / steps
    for i = 1, steps do
        local newPos = Vector3.new(targetPos.X, currentPos.Y + (stepHeight * i), targetPos.Z)
        hrp.CFrame = CFrame.new(newPos)
        task.wait(0.6) -- Slightly longer pause to reduce detection risk
    end
    -- Use safeTeleport at the end to ensure safe landing
    safeTeleport(targetPos)
    Rayfield:Notify({ Title = "CowHub", Content = "Reached summit safely", Duration = 2 })
end
-- Get sorted checkpoints
local function getSortedCheckpoints()
    local arr = {}
    for _, v in pairs(checkpoints_map) do table.insert(arr, v) end
    table.sort(arr, function(a, b) return a.pos.Y < b.pos.Y end)
    return arr
end
-- UI rebuild (debounced)
local ui_debounce = false
local function rebuildCheckpointUI()
    if ui_debounce then return end
    ui_debounce = true
    task.spawn(function()
        task.wait(0.25)
        for _, b in ipairs(checkpoint_buttons) do
            pcall(function() if b and b.Destroy then b:Destroy() end end)
        end
        checkpoint_buttons = {}
        CheckpointTab:CreateSection("Teleport to Checkpoints (Refreshed)")
        local arr = {}
        for _, v in pairs(checkpoints_map) do table.insert(arr, v) end
        table.sort(arr, function(a, b) return a.pos.Y < b.pos.Y end)
        for idx, cp in ipairs(arr) do
            local ok, btn = pcall(function()
                return CheckpointTab:CreateButton({
                    Name = ("Checkpoint %d | %s (Y:%d)"):format(idx, cp.name, math.floor(cp.pos.Y)),
                    Callback = function() safeTeleport(cp.pos) end
                })
            end)
            if ok and btn then table.insert(checkpoint_buttons, btn) end
        end
        if #arr > 0 then
            local top = arr[#arr]
            local okf, fbtn = pcall(function()
                return CheckpointTab:CreateButton({
                    Name = ("🏁 Finish Line (Y:%d)"):format(math.floor(top.pos.Y + 30)),
                    Callback = function() safeTeleport(top.pos + Vector3.new(0, 30, 0)) end
                })
            end)
            if okf and fbtn then table.insert(checkpoint_buttons, fbtn) end
        end
        pcall(function() CheckpointTab:CreateLabel("Found " .. tostring(#arr) .. " checkpoints") end)
        ui_debounce = false
    end)
end
-- Register checkpoint (avoid duplicates in saved_list)
local function registerCheckpoint(obj, pos)
    if not pos then return end
    local key = makeKey(pos)
    if checkpoints_map[key] then return end -- already in map
    -- Check if position is already in saved_list (within tolerance)
    for _, s in ipairs(saved_list) do
        local saved_pos = vecFromTable(s.pos)
        if (saved_pos - pos).Magnitude < DEDUPE_TOL then
            checkpoints_map[key] = { name = s.name or tostring(obj.Name or "Checkpoint"), pos = pos }
            print(("✅ Loaded saved checkpoint: %s Y=%d"):format(s.name or tostring(obj.Name), math.floor(pos.Y)))
            rebuildCheckpointUI()
            return
        end
    end
    -- New checkpoint, add to both map and saved_list
    local name = tostring(obj.Name or "Checkpoint")
    checkpoints_map[key] = { name = name, pos = pos }
    table.insert(saved_list, { name = name, pos = { X = pos.X, Y = pos.Y, Z = pos.Z } })
    save_to_file()
    print(("✅ Registered new checkpoint: %s Y=%d"):format(pcall(function() return obj:GetFullName() end) and obj:GetFullName() or tostring(obj), math.floor(pos.Y)))
    rebuildCheckpointUI()
end
-- Candidate detection
local function isCandidate(obj)
    local name = (obj.Name or ""):lower()
    if name:find("medkit") or name:find("kotak") or name:find("aqua") then return false end
    if name:find("checkpoint") then return true end
    for _, d in ipairs(obj:GetDescendants()) do
        if d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
            for _, g in ipairs(d:GetDescendants()) do
                if (g:IsA("TextLabel") or g:IsA("TextButton") or g:IsA("TextBox")) and type(g.Text) == "string" then
                    if string.match(string.lower(g.Text), "check ?point") then return true end
                end
            end
        end
    end
    return false
end
local function getPosFrom(obj)
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        if obj.PrimaryPart then return obj.PrimaryPart.Position end
        local found = obj:FindFirstChildWhichIsA("BasePart", true)
        if found then return found.Position end
    end
    return nil
end
-- Load saved checkpoints
load_from_file()
for _, s in ipairs(saved_list) do
    if s and s.pos then
        local p = vecFromTable(s.pos)
        registerCheckpoint({ Name = s.name or "SavedCP", GetFullName = function() return "SavedCheckpoint" end }, p)
    end
end
-- Initial scan
pcall(function()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isCandidate(obj) then
            local pos = getPosFrom(obj)
            if pos then registerCheckpoint(obj, pos) end
        end
    end
end)
-- Listen for new objects
Workspace.DescendantAdded:Connect(function(obj)
    task.wait(0.12)
    if isCandidate(obj) then
        local pos = getPosFrom(obj)
        if pos then registerCheckpoint(obj, pos) return end
    end
    local par = obj.Parent
    if par and isCandidate(par) then
        local pos = getPosFrom(par)
        if pos then registerCheckpoint(par, pos) end
    end
end)
-- Checkpoint utilities
CheckpointTab:CreateButton({
    Name = "Re-scan Visible Workspace",
    Callback = function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if isCandidate(obj) then
                local p = getPosFrom(obj)
                if p then registerCheckpoint(obj, p) end
            end
        end
        Rayfield:Notify({ Title = "CowHub", Content = "Rescan done", Duration = 2 })
    end
})
CheckpointTab:CreateButton({
    Name = "Clear Saved Checkpoints",
    Callback = function()
        checkpoints_map = {}
        saved_list = {}
        pcall(function() if isfile and isfile(SAVE_FILE) then pcall(delfile, SAVE_FILE) end end)
        rebuildCheckpointUI()
        Rayfield:Notify({ Title = "CowHub", Content = "Cleared saved checkpoints", Duration = 2 })
    end
})

-- Auto Teleport Feature
local autoActive = false
local timer = 300 -- 5 minutes in seconds
local autoConn
local countdownLabel = CheckpointTab:CreateLabel("Auto Teleport Off")
local isPerforming = false

local function performAutoTeleport()
    local arr = getSortedCheckpoints()
    if #arr < 2 then
        Rayfield:Notify({ Title = "CowHub", Content = "Not enough checkpoints (need at least 2)", Duration = 3 })
        return
    end
    local bottom = arr[1].pos
    local summit = arr[#arr].pos + Vector3.new(0, 30, 0) -- Match manual teleport offset
    -- Teleport to summit using safeTeleport directly
    safeTeleport(summit)
    Rayfield:Notify({ Title = "CowHub", Content = "Reached summit safely", Duration = 2 })
    task.wait(5) -- Wait 5 seconds at summit
    -- Teleport back to bottom
    safeTeleport(bottom)
    Rayfield:Notify({ Title = "CowHub", Content = "Back to bottom, resetting timer", Duration = 2 })
end

CheckpointTab:CreateToggle({
    Name = "Auto Teleport",
    CurrentValue = false,
    Callback = function(val)
        autoActive = val
        if val then
            timer = 300
            autoConn = RunService.Heartbeat:Connect(function(dt)
                if not autoActive or isPerforming then return end
                timer = timer - dt
                if timer <= 0 then
                    isPerforming = true
                    performAutoTeleport()
                    timer = 300 -- Reset timer after cycle
                    isPerforming = false
                end
                -- Update label
                local min = math.floor(timer / 60)
                local sec = math.floor(timer % 60)
                countdownLabel:Set("Time until next TP: " .. min .. ":" .. string.format("%02d", sec))
            end)
        else
            if autoConn then autoConn:Disconnect() autoConn = nil end
            timer = 300
            countdownLabel:Set("Auto Teleport Off")
        end
    end
})
-- ============================
-- Movement Tab
-- ============================
local MovementTab = Window:CreateTab("Movement", 4483362458)
MovementTab:CreateSection("Movement Settings")
MovementTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(v)
        if Humanoid and Humanoid.Parent then pcall(function() Humanoid.WalkSpeed = v end) end
    end
})
local flying = false
local flyConn
MovementTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Callback = function(val)
        flying = val
        local uis = game:GetService("UserInputService")
        local rs = game:GetService("RunService")
        if flying then
            flyConn = rs.Heartbeat:Connect(function()
                if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
                local hrp = Character.HumanoidRootPart
                local dir = Vector3.new()
                if uis:IsKeyDown(Enum.KeyCode.W) then dir = dir + Vector3.new(0, 0, -1) end
                if uis:IsKeyDown(Enum.KeyCode.S) then dir = dir + Vector3.new(0, 0, 1) end
                if uis:IsKeyDown(Enum.KeyCode.A) then dir = dir + Vector3.new(-1, 0, 0) end
                if uis:IsKeyDown(Enum.KeyCode.D) then dir = dir + Vector3.new(1, 0, 0) end
                if uis:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
                if uis:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir + Vector3.new(0, -1, 0) end
                hrp.Velocity = (hrp.CFrame.LookVector * dir.Z + hrp.CFrame.RightVector * dir.X + Vector3.new(0, dir.Y, 0)) * 60
            end)
        else
            if flyConn then flyConn:Disconnect(); flyConn = nil end
            if Character and Character:FindFirstChild("HumanoidRootPart") then
                Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            end
        end
    end
})
local noclip = false
local noclipConn
MovementTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(val)
        noclip = val
        local rs = game:GetService("RunService")
        if noclip then
            noclipConn = rs.Stepped:Connect(function()
                if Character then
                    for _, part in ipairs(Character:GetDescendants()) do
                        if part:IsA("BasePart") then pcall(function() part.CanCollide = false end) end
                    end
                end
            end)
        else
            if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
            if Character then
                for _, part in ipairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") then pcall(function() part.CanCollide = true end) end
                end
            end
        end
    end
})
