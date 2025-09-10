-- 🐄 CowHub | Gunung Kalimantan — Checkpoints + Movement (with editable Auto-TP timer)
-- Features kept: Checkpoints (stream-safe, dedupe, saved), Movement (WalkSpeed/Fly/Noclip)
-- Players tab removed. Auto Teleport gets a slider: 0s..600s (0 treated as 1s to avoid spam).

-- Load Rayfield
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
    Name = "🐄 CowHub | Gunung Kalimantan",
    LoadingTitle = "Loading CowHub...",
    LoadingSubtitle = "by Babang Sekelep",
    ConfigurationSaving = { Enabled = true, FolderName = "CowHubConfig", FileName = "GKSC_Config" },
    Discord = { Enabled = false },
    KeySystem = false
})

-- Services & player refs
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
LocalPlayer.CharacterAdded:Connect(function(ch)
    Character = ch
    Humanoid = ch:WaitForChild("Humanoid")
end)

local function notify(msg, dur)
    pcall(function()
        Rayfield:Notify({ Title = "CowHub", Content = tostring(msg), Duration = dur or 2 })
    end)
end

local function safeHRP()
    if Character and Character.Parent and Character:FindFirstChild("HumanoidRootPart") then
        return Character.HumanoidRootPart
    end
    return nil
end

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
local checkpoints_map = {}   -- key -> {name=string, pos=Vector3}
local checkpoint_buttons = {} -- Rayfield buttons
local saved_list = {}        -- array-writable for persistence (table of {name, pos={X,Y,Z}})

-- Filesystem helpers
local HAS_FS = (typeof(isfile) == "function") and (typeof(writefile) == "function") and (typeof(makefolder) == "function")
if HAS_FS then pcall(function() if not isfolder(SAVE_FOLDER) then makefolder(SAVE_FOLDER) end end) end

local function save_to_file()
    if HAS_FS then pcall(function() writefile(SAVE_FILE, HttpService:JSONEncode(saved_list)) end) end
end

local function load_from_file()
    if HAS_FS then
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
    local hrp = safeHRP()
    if not hrp then return end

    local function snap(origin, length)
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = { Character }
        params.FilterType = Enum.RaycastFilterType.Blacklist
        local res = workspace:Raycast(origin, Vector3.new(0, -length, 0), params)
        if res and res.Position then
            hrp.CFrame = CFrame.new(res.Position + Vector3.new(0, 4, 0))
            hrp.Velocity = Vector3.new()
            return true
        end
        return false
    end

    if snap(pos + Vector3.new(0, 160, 0), 400) then return end
    if snap(pos + Vector3.new(0, 50, 0), 200) then return end

    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 6, 0))
    hrp.Velocity = Vector3.new()
end

-- Safe summit teleport with gradual steps (simulated walk)
local function safeSummitTeleport(targetPos)
    local hrp = safeHRP()
    if not hrp then
        notify("Your character is not loaded", 3)
        return
    end
    local currentPos = hrp.Position
    local distance = (targetPos - currentPos).Magnitude
    local steps = math.max(5, math.floor(distance / 50)) -- At least 5 steps, ~50 studs per step
    local stepHeight = (targetPos.Y - currentPos.Y) / steps
    for i = 1, steps do
        local newPos = Vector3.new(targetPos.X, currentPos.Y + (stepHeight * i), targetPos.Z)
        hrp.CFrame = CFrame.new(newPos)
        task.wait(0.6)
    end
    safeTeleport(targetPos)
    notify("Reached summit safely", 2)
end

-- Sorted list helper
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

        local arr = getSortedCheckpoints()
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
        local key = makeKey(p)
        if not checkpoints_map[key] then
            checkpoints_map[key] = { name = s.name or "SavedCP", pos = p }
        end
    end
end
rebuildCheckpointUI()

-- Initial scan
pcall(function()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isCandidate(obj) then
            local pos = getPosFrom(obj)
            if pos then
                local key = makeKey(pos)
                if not checkpoints_map[key] then
                    local name = tostring(obj.Name or "Checkpoint")
                    checkpoints_map[key] = { name = name, pos = pos }
                    table.insert(saved_list, { name = name, pos = { X = pos.X, Y = pos.Y, Z = pos.Z } })
                end
            end
        end
    end
    save_to_file()
    rebuildCheckpointUI()
end)

-- Listen for new objects
Workspace.DescendantAdded:Connect(function(obj)
    task.wait(0.12)
    if isCandidate(obj) then
        local pos = getPosFrom(obj)
        if pos then
            local key = makeKey(pos)
            if not checkpoints_map[key] then
                local name = tostring(obj.Name or "Checkpoint")
                checkpoints_map[key] = { name = name, pos = pos }
                table.insert(saved_list, { name = name, pos = { X = pos.X, Y = pos.Y, Z = pos.Z } })
                save_to_file()
                rebuildCheckpointUI()
            end
        end
        return
    end
    local par = obj.Parent
    if par and isCandidate(par) then
        local pos = getPosFrom(par)
        if pos then
            local key = makeKey(pos)
            if not checkpoints_map[key] then
                local name = tostring(par.Name or "Checkpoint")
                checkpoints_map[key] = { name = name, pos = pos }
                table.insert(saved_list, { name = name, pos = { X = pos.X, Y = pos.Y, Z = pos.Z } })
                save_to_file()
                rebuildCheckpointUI()
            end
        end
    end
end)

-- Checkpoint utilities
CheckpointTab:CreateButton({
    Name = "Re-scan Visible Workspace",
    Callback = function()
        pcall(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if isCandidate(obj) then
                    local p = getPosFrom(obj)
                    if p then
                        local key = makeKey(p)
                        if not checkpoints_map[key] then
                            local nm = tostring(obj.Name or "Checkpoint")
                            checkpoints_map[key] = { name = nm, pos = p }
                            table.insert(saved_list, { name = nm, pos = { X = p.X, Y = p.Y, Z = p.Z } })
                        end
                    end
                end
            end
        end)
        save_to_file()
        rebuildCheckpointUI()
        notify("Rescan done", 2)
    end
})

CheckpointTab:CreateButton({
    Name = "Clear Saved Checkpoints",
    Callback = function()
        checkpoints_map = {}
        saved_list = {}
        if HAS_FS and typeof(isfile) == "function" and typeof(delfile) == "function" then
            pcall(function() if isfile(SAVE_FILE) then delfile(SAVE_FILE) end end)
        end
        rebuildCheckpointUI()
        notify("Cleared saved checkpoints", 2)
    end
})

-- ============================
-- Auto Teleport (with editable timer)
-- ============================
local function formatTime(s)
    s = math.max(0, math.floor(s))
    local m = math.floor(s / 60)
    local sec = s % 60
    return string.format("%d:%02d", m, sec)
end

local countdownLabel = CheckpointTab:CreateLabel("Auto Teleport Off")
local function setLabel(lbl, txt)
    pcall(function()
        if lbl and lbl.Set then lbl:Set(txt)
        elseif lbl and lbl.SetText then lbl:SetText(txt)
        end
    end)
end

local autoActive = false
local isPerforming = false
local autoConn

-- Timer state
local timerMax = 300 -- default 5 minutes
local timer = timerMax

-- Interval slider (0..600s; 0 -> treated as 1s internally to avoid spam)
CheckpointTab:CreateSlider({
    Name = "Auto TP Interval (0s - 10m)",
    Range = {0, 600},
    Increment = 1,
    CurrentValue = timerMax,
    Callback = function(v)
        timerMax = tonumber(v) or 0
        -- Avoid CPU spike: treat 0 as 1s internally
        if not autoActive then
            setLabel(countdownLabel, "Interval set to: " .. formatTime(math.max(1, timerMax)))
        end
        timer = math.max(1, timerMax)
    end
})

local function performAutoTeleport()
    local arr = getSortedCheckpoints()
    if #arr < 2 then
        notify("Not enough checkpoints (need at least 2)", 3)
        return
    end

    local bottom = arr[1].pos
    local summit = arr[#arr].pos + Vector3.new(0, 30, 0) -- extra Y to avoid clipping

    -- Simulate climb then return
    safeSummitTeleport(summit)
    task.wait(5)
    safeTeleport(bottom)
    notify("Back to bottom, timer reset", 2)
end

CheckpointTab:CreateToggle({
    Name = "Auto Teleport",
    CurrentValue = false,
    Callback = function(val)
        autoActive = val
        if val then
            timer = math.max(1, timerMax)
            setLabel(countdownLabel, "Time until next TP: " .. formatTime(timer))
            autoConn = RunService.Heartbeat:Connect(function(dt)
                if not autoActive or isPerforming then return end
                timer = timer - dt
                if timer <= 0 then
                    isPerforming = true
                    performAutoTeleport()
                    timer = math.max(1, timerMax)
                    isPerforming = false
                end
                setLabel(countdownLabel, "Time until next TP: " .. formatTime(timer))
            end)
        else
            if autoConn then autoConn:Disconnect() autoConn = nil end
            timer = math.max(1, timerMax)
            setLabel(countdownLabel, "Auto Teleport Off")
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

-- Fly
local flying = false
local flyConn
local flySpeed = 60
MovementTab:CreateSlider({
    Name = "Fly Speed",
    Range = {20, 300},
    Increment = 5,
    CurrentValue = flySpeed,
    Callback = function(v) flySpeed = v end
})
MovementTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Callback = function(val)
        flying = val
        if flying then
            flyConn = RunService.Heartbeat:Connect(function()
                local hrp = safeHRP()
                if not hrp then return end
                local dir = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Vector3.new(0, 0, -1) end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir + Vector3.new(0, 0, 1) end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir + Vector3.new(-1, 0, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Vector3.new(1, 0, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir + Vector3.new(0, -1, 0) end
                local move = (hrp.CFrame.LookVector * dir.Z) + (hrp.CFrame.RightVector * dir.X) + Vector3.new(0, dir.Y, 0)
                hrp.Velocity = move * flySpeed
            end)
        else
            if flyConn then flyConn:Disconnect(); flyConn = nil end
            local hrp = safeHRP()
            if hrp then hrp.Velocity = Vector3.new() end
        end
    end
})

-- Noclip
local noclip = false
local noclipConn
MovementTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(val)
        noclip = val
        if noclip then
            noclipConn = RunService.Stepped:Connect(function()
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
