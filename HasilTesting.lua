-- 🐄 CowHub | Gunung Kalimantan — Checkpoints + Movement (Looping Auto-TP + Camera-Relative Fly)
-- Features:
--   • Checkpoints: auto-detect, dedupe, save/load, UI list, finish-line jump
--   • Auto Teleport: loops (Closest → Summit → Lobby → reset timer)
--   • Movement: WalkSpeed, camera-relative Fly (BodyVelocity/BodyGyro), Noclip
--   • Mobile-friendly: floating Fly toggle button (draggable)
-- Players tab removed per request.

-- =========================================================
-- Rayfield
-- =========================================================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
    Name = "🐄 CowHub | Gunung Kalimantan",
    LoadingTitle = "Loading CowHub...",
    LoadingSubtitle = "by You",
    ConfigurationSaving = { Enabled = true, FolderName = "CowHubConfig", FileName = "GKSC_Config" },
    Discord = { Enabled = false },
    KeySystem = false
})

-- =========================================================
-- Services & Refs
-- =========================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

local function notify(msg, dur)
    pcall(function()
        Rayfield:Notify({ Title = "CowHub", Content = tostring(msg), Duration = dur or 2 })
    end)
end

-- Rebind on respawn and clean flying state if any
LocalPlayer.CharacterAdded:Connect(function(ch)
    Character = ch
    Humanoid = ch:WaitForChild("Humanoid")
    if _G.__CowFlyStop then _G.__CowFlyStop() end
end)

local function safeHRP()
    if Character and Character.Parent and Character:FindFirstChild("HumanoidRootPart") then
        return Character.HumanoidRootPart
    end
    return nil
end

-- =========================================================
-- Checkpoints Tab
-- =========================================================
local CheckpointTab = Window:CreateTab("Checkpoints", 4483362458)
CheckpointTab:CreateSection("Teleport to Checkpoints")

-- Persistence config
local SAVE_FOLDER = "CowHubConfig"
local SAVE_FILE = SAVE_FOLDER .. "/gk_checkpoints.json"
local DEDUPE_TOL = 3 -- studs

-- Storage
local checkpoints_map = {}   -- key -> {name=string, pos=Vector3}
local checkpoint_buttons = {}
local saved_list = {}        -- array of { name=string, pos={X,Y,Z} }

-- FS guards (executor only)
local HAS_FS = (typeof(isfile) == "function") and (typeof(writefile) == "function") and (typeof(makefolder) == "function")
if HAS_FS then pcall(function() if not isfolder(SAVE_FOLDER) then makefolder(SAVE_FOLDER) end end) end

local function save_to_file()
    if not HAS_FS then return end
    pcall(function() writefile(SAVE_FILE, HttpService:JSONEncode(saved_list)) end)
end

local function load_from_file()
    if not HAS_FS then return end
    local ok, data = pcall(function() return readfile(SAVE_FILE) end)
    if ok and data then
        local succ, dec = pcall(function() return HttpService:JSONDecode(data) end)
        if succ and typeof(dec) == "table" then saved_list = dec end
    end
end

local function vecFromTable(t)
    if typeof(t) == "Vector3" then return t end
    if typeof(t) == "table" then
        return Vector3.new(tonumber(t.X) or 0, tonumber(t.Y) or 0, tonumber(t.Z) or 0)
    end
    return Vector3.new()
end

local function makeKey(pos)
    return string.format("%d_%d_%d", math.floor(pos.X/DEDUPE_TOL), math.floor(pos.Y/DEDUPE_TOL), math.floor(pos.Z/DEDUPE_TOL))
end

-- Safe ground-snap teleport
local function safeTeleport(pos)
    local hrp = safeHRP()
    if not hrp then return end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = { Character }

    local function snap(origin, length)
        local r = Workspace:Raycast(origin, Vector3.new(0, -length, 0), params)
        if r and r.Position then
            hrp.CFrame = CFrame.new(r.Position + Vector3.new(0, 4, 0))
            if hrp.AssemblyLinearVelocity then hrp.AssemblyLinearVelocity = Vector3.new() else hrp.Velocity = Vector3.new() end
            return true
        end
        return false
    end

    if snap(pos + Vector3.new(0,160,0), 400) then return end
    if snap(pos + Vector3.new(0, 50,0), 200) then return end
    hrp.CFrame = CFrame.new(pos + Vector3.new(0,6,0))
    if hrp.AssemblyLinearVelocity then hrp.AssemblyLinearVelocity = Vector3.new() else hrp.Velocity = Vector3.new() end
end

-- Smooth 3D climb to summit
local function safeSummitTeleport(targetPos)
    local hrp = safeHRP()
    if not hrp then notify("Your character is not loaded", 3) return end
    local startPos = hrp.Position
    local distance = (targetPos - startPos).Magnitude
    local steps = math.clamp(math.floor(distance/20), 8, 120)
    for i=1,steps do
        local t = i/steps
        local newPos = startPos:Lerp(targetPos, t)
        hrp.CFrame = CFrame.new(newPos)
        if hrp.AssemblyLinearVelocity then hrp.AssemblyLinearVelocity = Vector3.new() else hrp.Velocity = Vector3.new() end
        task.wait(0.15)
    end
    safeTeleport(targetPos)
    notify("Reached summit safely", 2)
end

local function getSortedCheckpoints()
    local arr = {}
    for _, v in pairs(checkpoints_map) do table.insert(arr, v) end
    table.sort(arr, function(a,b) return a.pos.Y < b.pos.Y end)
    return arr
end

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
        checkpoints_map[makeKey(p)] = checkpoints_map[makeKey(p)] or { name = s.name or "SavedCP", pos = p }
    end
end

-- Build UI
local ui_debounce = false
local function rebuildCheckpointUI()
    if ui_debounce then return end
    ui_debounce = true
    task.spawn(function()
        task.wait(0.2)
        for _, b in ipairs(checkpoint_buttons) do pcall(function() if b and b.Destroy then b:Destroy() end end) end
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
                    Callback = function() safeTeleport(top.pos + Vector3.new(0,30,0)) end
                })
            end)
            if okf and fbtn then table.insert(checkpoint_buttons, fbtn) end
        end
        pcall(function() CheckpointTab:CreateLabel("Found " .. tostring(#arr) .. " checkpoints") end)
        ui_debounce = false
    end)
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

Workspace.DescendantAdded:Connect(function(obj)
    task.wait(0.12)
    if isCandidate(obj) then
        local pos = getPosFrom(obj)
        if pos then
            local key = makeKey(pos)
            if not checkpoints_map[key] then
                local nm = tostring(obj.Name or "Checkpoint")
                checkpoints_map[key] = { name = nm, pos = pos }
                table.insert(saved_list, { name = nm, pos = { X = pos.X, Y = pos.Y, Z = pos.Z } })
                save_to_file(); rebuildCheckpointUI()
            end
        end
        return
    end
    local par = obj.Parent
    if par and isCandidate(par) then
        local p = getPosFrom(par)
        if p then
            local key = makeKey(p)
            if not checkpoints_map[key] then
                local nm = tostring(par.Name or "Checkpoint")
                checkpoints_map[key] = { name = nm, pos = p }
                table.insert(saved_list, { name = nm, pos = { X = p.X, Y = p.Y, Z = p.Z } })
                save_to_file(); rebuildCheckpointUI()
            end
        end
    end
end)

-- Utilities
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
        save_to_file(); rebuildCheckpointUI(); notify("Rescan done", 2)
    end
})

CheckpointTab:CreateButton({
    Name = "Clear Saved Checkpoints",
    Callback = function()
        checkpoints_map = {}
        saved_list = {}
        if HAS_FS and typeof(isfile)=="function" and typeof(delfile)=="function" then
            pcall(function() if isfile(SAVE_FILE) then delfile(SAVE_FILE) end end)
        end
        rebuildCheckpointUI(); notify("Cleared saved checkpoints", 2)
    end
})

-- =========================================================
-- Main Lobby (session) & Auto Teleport Loop
-- =========================================================
local lobbyPos = nil -- session-only; fallback = lowest checkpoint

CheckpointTab:CreateButton({
    Name = "Set Current Position as Main Lobby",
    Callback = function()
        local hrp = safeHRP(); if not hrp then return notify("Your character is not loaded", 3) end
        lobbyPos = hrp.Position
        notify("Main Lobby set to your current position", 2)
    end
})
CheckpointTab:CreateButton({
    Name = "Clear Main Lobby (fallback to lowest CP)",
    Callback = function()
        lobbyPos = nil
        notify("Main Lobby cleared (using lowest checkpoint)", 2)
    end
})

local function formatTime(s)
    s = math.max(0, math.floor(s))
    local m = math.floor(s/60)
    local sec = s%60
    return string.format("%d:%02d", m, sec)
end

local countdownLabel = CheckpointTab:CreateLabel("Auto Teleport Off")
local function setLabel(lbl, txt)
    pcall(function()
        if lbl and lbl.Set then lbl:Set(txt) elseif lbl and lbl.SetText then lbl:SetText(txt) end
    end)
end

local function getClosestCheckpoint(pos)
    local best, bestDist
    for _, cp in pairs(checkpoints_map) do
        local d = (cp.pos - pos).Magnitude
        if not bestDist or d < bestDist then bestDist = d; best = cp end
    end
    return best
end

local function getSummitAndBase()
    local arr = getSortedCheckpoints()
    return arr[#arr], arr[1], arr
end

local autoActive = false
local autoThread
local timerMax = 300 -- default 5m

CheckpointTab:CreateSlider({
    Name = "Auto TP Interval (0s - 10m)",
    Range = {0, 600},
    Increment = 1,
    CurrentValue = timerMax,
    Callback = function(v)
        timerMax = tonumber(v) or 0
        if not autoActive then setLabel(countdownLabel, "Interval set to: " .. formatTime(math.max(1, timerMax))) end
    end
})

local function performAutoTeleport()
    local summit, base, arr = getSummitAndBase()
    if not arr or #arr == 0 then return notify("No checkpoints found yet.", 3) end
    local hrp = safeHRP(); if not hrp then return notify("Your character is not loaded", 3) end

    -- 1) Closest checkpoint
    local closest = getClosestCheckpoint(hrp.Position)
    if closest then
        safeTeleport(closest.pos)
        local startT = time()
        while time() - startT < 1.5 do
            local h = safeHRP(); if h and (h.Position - closest.pos).Magnitude < 8 then break end
            task.wait(0.05)
        end
    end

    -- 2) Summit
    if summit then
        local summitTarget = summit.pos + Vector3.new(0, 30, 0)
        safeSummitTeleport(summitTarget)
        task.wait(0.5)
    end

    -- 3) Lobby
    local lobbyTarget = lobbyPos or (base and base.pos) or hrp.Position
    safeTeleport(lobbyTarget)
    notify("Cycle complete. Timer reset.", 2)
end

local function startAutoLoop()
    if autoThread then return end
    autoThread = task.spawn(function()
        local interval = math.max(1, timerMax)
        local deadline = time() + interval
        while autoActive do
            local remaining = deadline - time()
            if remaining <= 0 then
                performAutoTeleport()
                interval = math.max(1, timerMax)
                deadline = time() + interval
            else
                setLabel(countdownLabel, "Time until next TP: " .. formatTime(remaining))
                task.wait(0.2)
            end
        end
        setLabel(countdownLabel, "Auto Teleport Off"); autoThread = nil
    end)
end

CheckpointTab:CreateToggle({
    Name = "Auto Teleport (Loop)",
    CurrentValue = false,
    Callback = function(val)
        autoActive = val
        if val then setLabel(countdownLabel, "Time until next TP: " .. formatTime(math.max(1, timerMax))); startAutoLoop() end
    end
})

-- =========================================================
-- Movement Tab (WalkSpeed, Fly, Noclip)
-- =========================================================
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

-- Camera-relative Fly (BodyVelocity/BodyGyro)
local bodyVelocity, bodyGyro
local isFlying = false
local flySpeed = 50
local maxSpeed = 200

local function startFlying()
    if not Character or not Humanoid or Humanoid.Health <= 0 then return end
    local hrp = Character:FindFirstChild("HumanoidRootPart"); if not hrp or isFlying then return end
    isFlying = true

    Humanoid.PlatformStand = true

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.new()
    bodyVelocity.Parent = hrp

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(400000, 400000, 400000)
    bodyGyro.P = 3000
    bodyGyro.D = 500
    bodyGyro.CFrame = CFrame.new()
    bodyGyro.Parent = hrp

    task.spawn(function()
        while isFlying and Character and Humanoid and Humanoid.Health > 0 do
            local cam = workspace.CurrentCamera
            local move = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0, 1, 0) end

            if move.Magnitude > 0 then
                move = move.Unit * math.clamp(flySpeed, 0, maxSpeed)
            end

            if bodyVelocity then bodyVelocity.Velocity = move end
            local hrpNow = Character and Character:FindFirstChild("HumanoidRootPart")
            if hrpNow and bodyGyro then
                bodyGyro.CFrame = CFrame.fromMatrix(hrpNow.Position, cam.CFrame.LookVector, cam.CFrame.UpVector)
            end
            RunService.Heartbeat:Wait()
        end

        if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
        if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
        if Humanoid then Humanoid.PlatformStand = false end
    end)
end

local function stopFlying()
    if not isFlying then return end
    isFlying = false
    if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
    if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
    if Humanoid then Humanoid.PlatformStand = false end
end

_G.__CowFlyStop = function()
    if isFlying then isFlying = false end
    if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
    if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
    if Humanoid then Humanoid.PlatformStand = false end
end

MovementTab:CreateToggle({
    Name = "Fly (camera-relative)",
    CurrentValue = false,
    Callback = function(val)
        if val then startFlying() else stopFlying() end
    end
})

MovementTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, maxSpeed},
    Increment = 10,
    CurrentValue = flySpeed,
    Callback = function(v)
        flySpeed = v
        notify("Fly speed set to " .. tostring(v), 2)
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

-- =========================================================
-- Mobile-friendly floating Fly button (draggable)
-- =========================================================
local function getUILayer()
    local ok, ui = pcall(gethui) -- some executors support gethui()
    if ok and ui then return ui end
    return game:GetService("CoreGui")
end

local function createFlyToggleButton()
    local parent = getUILayer()
    if not parent then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "CowHubFlyToggle"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = parent

    local btn = Instance.new("TextButton")
    btn.Name = "FlyButton"
    btn.Size = UDim2.new(0, 90, 0, 36)
    btn.Position = UDim2.new(0, 20, 0.82, 0)
    btn.TextScaled = true
    btn.Text = "FLY: OFF"
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.AutoButtonColor = true
    btn.BackgroundTransparency = 0.1
    btn.Parent = gui

    -- Dragging
    local dragging = false
    local dragStart, startPos
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = btn.Position
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local function sync()
        if isFlying then
            btn.Text = "FLY: ON"
            btn.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
        else
            btn.Text = "FLY: OFF"
            btn.BackgroundColor3 = Color3.fromRGB(160, 60, 60)
        end
    end

    btn.MouseButton1Click:Connect(function()
        if isFlying then stopFlying() else startFlying() end
        sync()
    end)

    -- Keep in sync if toggled from Rayfield
    task.spawn(function()
        while gui.Parent do
            sync()
            task.wait(0.2)
        end
    end)
end

pcall(createFlyToggleButton)
