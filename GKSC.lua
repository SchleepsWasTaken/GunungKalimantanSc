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
-- Checkpoints Tab (Reliable detection, dedupe, persistent save, safe-teleport)
----------------------------------------------------------------------
local HttpService = game:GetService("HttpService")
local CheckpointTab = Window:CreateTab("Checkpoints", 4483362458)
CheckpointTab:CreateSection("Teleport to Checkpoints")

-- config
local SAVE_FOLDER = "CowHubConfig"
local SAVE_FILE = SAVE_FOLDER .. "/checkpoints.json"
local DEDUPE_TOL = 5 -- in studs, rounding tolerance for duplicates

-- storage
local checkpointButtons = {}
local checkpoints_map = {} -- key -> {name=str, pos=Vector3}
local saved_checkpoints = {}

-- filesystem helpers (works when executor provides them)
if isfolder then
    if not isfolder(SAVE_FOLDER) then
        pcall(makefolder, SAVE_FOLDER)
    end
end

local function loadSaved()
    if isfile and isfile(SAVE_FILE) then
        local ok, dat = pcall(readfile, SAVE_FILE)
        if ok and dat then
            local success, decoded = pcall(function() return HttpService:JSONDecode(dat) end)
            if success and type(decoded) == "table" then
                saved_checkpoints = decoded
            end
        end
    end
end

local function saveSaved()
    if writefile then
        local ok, encoded = pcall(function() return HttpService:JSONEncode(saved_checkpoints) end)
        if ok and encoded then
            pcall(writefile, SAVE_FILE, encoded)
        end
    end
end

-- util
local function vecFromTable(t)
    if typeof(t) == "Vector3" then return t end
    return Vector3.new(t.X or 0, t.Y or 0, t.Z or 0)
end

local function computeKey(pos)
    return math.floor(pos.X / DEDUPE_TOL) .. "_" .. math.floor(pos.Y / DEDUPE_TOL) .. "_" .. math.floor(pos.Z / DEDUPE_TOL)
end

-- safe teleport
local function safeTeleport(pos)
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = Character.HumanoidRootPart
    local origin = pos + Vector3.new(0, 150, 0)
    local dir = Vector3.new(0, -500, 0)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {Character}
    params.FilterType = Enum.RaycastFilterType.Blacklist

    local res = workspace:Raycast(origin, dir, params)
    if res and res.Position then
        local target = res.Position + Vector3.new(0, 4, 0)
        hrp.CFrame = CFrame.new(target)
        hrp.Velocity = Vector3.new()
        return
    end

    local res2 = workspace:Raycast(pos + Vector3.new(0,50,0), Vector3.new(0, -300, 0), params)
    if res2 and res2.Position then
        local target = res2.Position + Vector3.new(0, 4, 0)
        hrp.CFrame = CFrame.new(target)
        hrp.Velocity = Vector3.new()
        return
    end

    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 6, 0))
    hrp.Velocity = Vector3.new()
end

-- UI rebuild
local ui_dirty = false
local function scheduleUIRefresh()
    if ui_dirty then return end
    ui_dirty = true
    task.spawn(function()
        task.wait(0.5)
        for _, btn in ipairs(checkpointButtons) do
            pcall(function() btn:Destroy() end)
        end
        checkpointButtons = {}

        local list = {}
        for _, cp in pairs(checkpoints_map) do
            table.insert(list, cp)
        end
        table.sort(list, function(a,b) return a.pos.Y < b.pos.Y end)

        for i, cp in ipairs(list) do
            local idx = i
            local displayName = (cp.name and tostring(cp.name) or "Checkpoint") .. " (Y: " .. math.floor(cp.pos.Y) .. ")"
            local btn = CheckpointTab:CreateButton({
                Name = "Checkpoint " .. idx .. " | " .. displayName,
                Callback = function()
                    safeTeleport(cp.pos)
                end
            })
            table.insert(checkpointButtons, btn)
        end

        if #list > 0 then
            local top = list[#list]
            local finishBtn = CheckpointTab:CreateButton({
                Name = "🏁 Finish Line (Y: " .. math.floor(top.pos.Y) .. ")",
                Callback = function()
                    safeTeleport(top.pos + Vector3.new(0,10,0))
                end
            })
            table.insert(checkpointButtons, finishBtn)
        end

        CheckpointTab:CreateLabel("Found " .. tostring(#list) .. " checkpoints (saved)")

        ui_dirty = false
    end)
end

local function registerCheckpoint(obj, pos)
    if not pos then return end
    local key = computeKey(pos)
    if checkpoints_map[key] then return end

    checkpoints_map[key] = { name = (obj.Name or "Checkpoint"), pos = pos }

    local found = false
    for _, scp in ipairs(saved_checkpoints) do
        local skey = computeKey(vecFromTable(scp.pos))
        if skey == key then found = true break end
    end
    if not found then
        table.insert(saved_checkpoints, { name = (obj.Name or "Checkpoint"), pos = { X = pos.X, Y = pos.Y, Z = pos.Z } })
        saveSaved()
    end

    print("✅ Registered checkpoint:", pcall(function() return obj:GetFullName() end) and obj:GetFullName() or tostring(obj), "Y =", math.floor(pos.Y))
    scheduleUIRefresh()
end

local function isCheckpointCandidate(obj)
    local lname = (obj.Name or ""):lower()
    local parentName = (obj.Parent and obj.Parent.Name or ""):lower()

    if lname:find("checkpoint") or lname:find("cp") or lname:find("flag") or lname:find("stage") or lname:find("finish") or lname:find("goal") or lname:find("line") or parentName:find("checkpoint") then
        return true
    end

    for _, d in ipairs(obj:GetDescendants()) do
        if d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
            for _, g in ipairs(d:GetDescendants()) do
                if (g:IsA("TextLabel") or g:IsA("TextButton") or g:IsA("TextBox")) and type(g.Text) == "string" then
                    if string.match(string.lower(g.Text), "checkpoint") or string.match(string.lower(g.Text), "check ?point") then
                        return true
                    end
                end
            end
        end
        if d:IsA("ProximityPrompt") then
            return true
        end
    end

    return false
end

local function getPositionFor(obj)
    if obj:IsA("BasePart") then
        return obj.Position
    elseif obj:IsA("Model") then
        if obj.PrimaryPart then return obj.PrimaryPart.Position end
        local found = obj:FindFirstChildWhichIsA("BasePart", true)
        if found then return found.Position end
    end
    return nil
end

-- initial load
loadSaved()
for _, scp in ipairs(saved_checkpoints) do
    if scp and scp.pos then
        local p = vecFromTable(scp.pos)
        registerCheckpoint({ Name = scp.name or "SavedCheckpoint", GetFullName = function() return "SavedCheckpoint" end }, p)
    end
end

local function scanContainer(container)
    for _, obj in ipairs(container:GetDescendants()) do
        if isCheckpointCandidate(obj) then
            local pos = getPositionFor(obj)
            if pos then
                registerCheckpoint(obj, pos)
            end
        end
    end
end

local containers = { workspace, game:GetService("ReplicatedStorage"), game:GetService("Lighting") }

for _, c in ipairs(containers) do
    pcall(scanContainer, c)

    c.DescendantAdded:Connect(function(obj)
        task.wait(0.05)
        if isCheckpointCandidate(obj) then
            local pos = getPositionFor(obj)
            if pos then registerCheckpoint(obj, pos) end
        else
            local par = obj.Parent
            if par and isCheckpointCandidate(par) then
                local pos = getPositionFor(par)
                if pos then registerCheckpoint(par, pos) end
            end
        end
    end)
end

task.spawn(function()
    while true do
        task.wait(5)
        scheduleUIRefresh()
    end
end)

CheckpointTab:CreateButton({
    Name = "Clear Saved Checkpoints",
    Callback = function()
        checkpoints_map = {}
        saved_checkpoints = {}
        if isfile and isfile(SAVE_FILE) then pcall(delfile, SAVE_FILE) end
        scheduleUIRefresh()
        Rayfield:Notify({ Title = "CowHub", Content = "Saved checkpoints cleared", Duration = 3 })
    end
})

CheckpointTab:CreateButton({
    Name = "Re-scan All Containers Now",
    Callback = function()
        for _, c in ipairs(containers) do
            pcall(scanContainer, c)
        end
        scheduleUIRefresh()
        Rayfield:Notify({ Title = "CowHub", Content = "Rescan complete", Duration = 3 })
    end
})

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
