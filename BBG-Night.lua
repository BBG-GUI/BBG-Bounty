-- ============================================================
--  BBG BOUNTY  |  INF Abuser  |  Auto Mode
--  Auto: Inf Height Z Spam + Self Kill loop
--  + BBG Server Hop (cooldown + retry + API fallback)
-- ============================================================

local Players            = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local HttpService        = game:GetService("HttpService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

-- Config
local CONFIG = {
    HopMinPlayers  = 6,
    HopMaxPlayers  = 10,
    HopFallbackAny = true,
    HopRegion      = nil,
    NoHitTimeout   = 18,  -- seconds before auto hop
    ForcedHopTime  = 120, -- 2 minutes (forced server hop)
}

local BG_MAIN = Color3.fromRGB(10, 0, 20)
local ACCENT  = Color3.fromRGB(160, 0, 255)

getgenv().AbuseActive  = true
getgenv().SelectedSlot = Enum.KeyCode.Three

-- ============================================================
--  UI
-- ============================================================
-- Cleanup old
pcall(function()
    local old = game.CoreGui:FindFirstChild("BBG_AbuserGui")
    if old then old:Destroy() end
end)

local ScreenGui  = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name   = "BBG_AbuserGui"
ScreenGui.ResetOnSpawn = false

local MainFrame  = Instance.new("Frame", ScreenGui)
MainFrame.Size   = UDim2.new(0, 180, 0, 200)
MainFrame.Position = UDim2.new(0.5, -90, 0.5, -150)
MainFrame.BackgroundColor3 = BG_MAIN
MainFrame.BorderSizePixel  = 2
MainFrame.BorderColor3     = ACCENT
Instance.new("UICorner", MainFrame)

local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size  = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 0, 40)
TitleBar.BorderSizePixel  = 0
Instance.new("UICorner", TitleBar)

local Title = Instance.new("TextLabel", TitleBar)
Title.Size   = UDim2.new(1, -30, 1, 0)
Title.Position = UDim2.new(0, 8, 0, 0)
Title.Text   = "BBG BOUNTY"
Title.TextColor3 = ACCENT
Title.Font   = Enum.Font.GothamBold
Title.TextSize = 14
Title.BackgroundTransparency = 1
Title.TextXAlignment = Enum.TextXAlignment.Left

local StatusLbl = Instance.new("TextLabel", MainFrame)
StatusLbl.Size  = UDim2.new(1, 0, 0, 18)
StatusLbl.Position = UDim2.new(0, 0, 0, 32)
StatusLbl.TextColor3 = Color3.fromRGB(200, 150, 255)
StatusLbl.Font  = Enum.Font.Gotham
StatusLbl.TextSize = 10
StatusLbl.BackgroundTransparency = 1
StatusLbl.Text  = "Status: Running"

local MinBtn = Instance.new("TextButton", TitleBar)
MinBtn.Size  = UDim2.new(0, 24, 0, 24)
MinBtn.Position = UDim2.new(1, -28, 0, 4)
MinBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
MinBtn.Text  = "-"
MinBtn.TextColor3 = Color3.new(1, 1, 1)
MinBtn.Font  = Enum.Font.GothamBold
MinBtn.TextSize = 16
Instance.new("UICorner", MinBtn)

local ContentFrame = Instance.new("Frame", MainFrame)
ContentFrame.Size = UDim2.new(1, 0, 1, -52)
ContentFrame.Position = UDim2.new(0, 0, 0, 52)
ContentFrame.BackgroundTransparency = 1

-- Minimize
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        MainFrame.Size = UDim2.new(0, 180, 0, 32)
        ContentFrame.Visible = false
        StatusLbl.Visible = false
        MinBtn.Text = "+"
    else
        MainFrame.Size = UDim2.new(0, 180, 0, 200)
        ContentFrame.Visible = true
        StatusLbl.Visible = true
        MinBtn.Text = "-"
    end
end)

-- Dragging
local d, ds, sp
TitleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        d = true; ds = i.Position; sp = MainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if d and i.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = i.Position - ds
        MainFrame.Position = UDim2.new(sp.X.Scale, sp.X.Offset + delta.X, sp.Y.Scale, sp.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then d = false end
end)

-- Buttons
local function MakeButton(parent, text, yPos, bgColor)
    local btn = Instance.new("TextButton", parent)
    btn.Size     = UDim2.new(0.88, 0, 0, 38)
    btn.Position = UDim2.new(0.06, 0, 0, yPos)
    btn.BackgroundColor3 = bgColor
    btn.Text     = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font     = Enum.Font.GothamBold
    btn.TextSize = 12
    Instance.new("UICorner", btn)
    return btn
end

local AbuseBtn = MakeButton(ContentFrame, "■ AUTO ABUSE: ON", 5,  Color3.fromRGB(150, 0, 0))
local FixBtn   = MakeButton(ContentFrame, "FIX CAMERA",        50, Color3.fromRGB(50, 0, 80))
FixBtn.TextColor3 = ACCENT
FixBtn.Size    = UDim2.new(0.88, 0, 0, 28)

-- Session Timer (BBG style: 00:00)
local timerBg = Instance.new("Frame", ContentFrame)
timerBg.Size  = UDim2.new(0.88, 0, 0, 24)
timerBg.Position = UDim2.new(0.06, 0, 0, 85)
timerBg.BackgroundColor3 = Color3.fromRGB(20, 0, 40)
timerBg.BorderSizePixel  = 0
Instance.new("UICorner", timerBg)
local timerTopLbl = Instance.new("TextLabel", timerBg)
timerTopLbl.Size  = UDim2.new(1, 0, 0, 10)
timerTopLbl.Position = UDim2.new(0, 0, 0, 0)
timerTopLbl.Text  = "ACTIVE TIME"
timerTopLbl.Font  = Enum.Font.Gotham
timerTopLbl.TextSize = 7
timerTopLbl.TextColor3 = Color3.fromRGB(140, 100, 200)
timerTopLbl.BackgroundTransparency = 1
local TimerLbl = Instance.new("TextLabel", timerBg)
TimerLbl.Size  = UDim2.new(1, 0, 0, 14)
TimerLbl.Position = UDim2.new(0, 0, 0, 10)
TimerLbl.Text  = "00:00"
TimerLbl.Font  = Enum.Font.GothamBold
TimerLbl.TextSize = 13
TimerLbl.TextColor3 = Color3.fromRGB(130, 142, 178)
TimerLbl.BackgroundTransparency = 1

-- BBG timer loop: only ticks when AbuseActive
local _sessionStart = os.clock()
task.spawn(function()
    while true do
        task.wait(1)
        if getgenv().AbuseActive then
            local elapsed = math.floor(os.clock() - _sessionStart)
            TimerLbl.Text = string.format("%02d:%02d", math.floor(elapsed / 60), elapsed % 60)
        end
    end
end)

-- ============================================================
--  REMOTES (BBG)
-- ============================================================
local CommF_
pcall(function()
    CommF_ = ReplicatedStorage:WaitForChild("Remotes", 5):WaitForChild("CommF_", 5)
end)

local function selectFaction(faction)
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        local activity = remotes:FindFirstChild("RE/OnEventServiceActivity")
        local commF    = remotes:FindFirstChild("CommF_")
        if activity then activity:FireServer("TeamSelect/Team/"..faction) end
        task.wait(0.05)
        if commF then commF:InvokeServer("SetTeam", faction) end
    end)
end

local function buso()
    pcall(function()
        if CommF_ then CommF_:InvokeServer("Buso") end
    end)
end

-- Auto Haki/Buso loop (BBG: every 0.5s)
task.spawn(function()
    while true do
        task.wait(0.5)
        if getgenv().AbuseActive then buso() end
    end
end)

-- ============================================================
--  CORE FUNCTIONS
-- ============================================================
local function Press(key)
    VirtualInputManager:SendKeyEvent(true,  key, false, game)
    task.wait(0.01)
    VirtualInputManager:SendKeyEvent(false, key, false, game)
end

-- ExecuteAbuse: original logic (exact) + Melee equip before Z
local function ExecuteAbuse()
    if not getgenv().AbuseActive then return end
    local char = lp.Character or lp.CharacterAdded:Wait()
    local hrp  = char:WaitForChild("HumanoidRootPart", 10)
    local hum  = char:WaitForChild("Humanoid", 10)
    if hrp and hum and hum.Health > 0 then
        -- Step 1: jump 500 studs up (original)
        hrp.CFrame = hrp.CFrame * CFrame.new(0, 500, 0)
        Press(getgenv().SelectedSlot)
        task.wait(0.08)
        Press(Enum.KeyCode.J)

        -- Step 2: teleport to inf height (original)
        local targetPos = CFrame.new(923.2, 3000000000000000000000, 32852.8)
        hrp.Anchored = true
        hrp.CFrame   = targetPos
        workspace.CurrentCamera.CFrame = targetPos
        task.wait(0.05)

        -- Step 3: equip Melee then press Z
        pcall(function()
            local h = char:FindFirstChildOfClass("Humanoid")
            if h then
                for _, tool in pairs(lp.Backpack:GetChildren()) do
                    if tool:IsA("Tool") and tool.ToolTip == "Melee" then
                        h:EquipTool(tool); break
                    end
                end
            end
        end)
        task.wait(0.15)
        Press(Enum.KeyCode.Z)

        -- Step 4: self kill (original)
        task.spawn(function()
            task.wait(4.0)
            hum.Health = 0
        end)
        local s = tick()
        while tick() - s < 0.6 do RunService.Heartbeat:Wait() end
    end
end

-- Auto loop on respawn
lp.CharacterAdded:Connect(function()
    if getgenv().AbuseActive then
        task.wait(0.5)
        task.spawn(ExecuteAbuse)
    end
end)

-- ============================================================
--  SERVER HOP  (BBG: cooldown + retry + API fallback)
-- ============================================================
local _place = game.PlaceId
local _id    = game.JobId
local browser
pcall(function() browser = ReplicatedStorage:FindFirstChild("__ServerBrowser") end)

local _isHopping  = false
local _lastHopTime = 0
local HOP_COOLDOWN = 8

local function Hop()
    if _isHopping then return false end
    if os.clock() - _lastHopTime < HOP_COOLDOWN then return false end
    _isHopping = true; _lastHopTime = os.clock()
    task.delay(12, function() _isHopping = false end)

    local allServers = {}; local foundData = false; local pendingCount = 0

    if browser then
        for page = 1, 100 do
            if foundData then break end
            pendingCount += 1
            task.spawn(function()
                local ok, result = pcall(function() return browser:InvokeServer(page) end)
                if ok and type(result) == "table" then
                    local valid = 0
                    for uuid, info in pairs(result) do
                        if type(info) == "table" and info.Count then
                            allServers[uuid] = info; valid += 1
                        end
                    end
                    if valid > 0 then foundData = true end
                end
                pendingCount -= 1
            end)
        end
        local waited = 0
        while pendingCount > 0 and waited < 6 do
            task.wait(0.2); waited += 0.2
            if foundData and waited > 1 then break end
        end
    end

    -- API fallback agar browser nahi mila
    local apiServers = {}
    if not foundData then
        for _, ord in ipairs({"Desc", "Asc"}) do
            pcall(function()
                local r = HttpService:JSONDecode(game:HttpGet(
                    "https://games.roblox.com/v1/games/".._place.."/servers/Public?sortOrder="..ord.."&limit=100"))
                if r and r.data then
                    for _, sv in ipairs(r.data) do table.insert(apiServers, sv) end
                end
            end)
        end
        if #apiServers == 0 then _isHopping = false; return false end
    end

    local seen, matched, anyValid = {}, {}, {}
    if foundData then
        for uuid, info in pairs(allServers) do
            if uuid ~= _id then
                local count = info.Count or 0
                local entry = {uuid=uuid, count=count, region=info.Region or "?"}
                table.insert(anyValid, entry)
                local ok2 = true
                if CONFIG.HopMinPlayers and count < CONFIG.HopMinPlayers then ok2 = false end
                if CONFIG.HopMaxPlayers and count > CONFIG.HopMaxPlayers then ok2 = false end
                if CONFIG.HopRegion and CONFIG.HopRegion ~= "" then
                    if not string.find(string.lower(info.Region or ""), string.lower(CONFIG.HopRegion), 1, true) then ok2 = false end
                end
                if ok2 then table.insert(matched, entry) end
            end
        end
    else
        for _, sv in ipairs(apiServers) do
            if sv.id and sv.id ~= _id and not seen[sv.id] and sv.playing and sv.maxPlayers and sv.playing < sv.maxPlayers then
                seen[sv.id] = true
                local entry = {uuid=sv.id, count=sv.playing, region="?"}
                table.insert(anyValid, entry)
                local ok2 = true
                if CONFIG.HopMinPlayers and sv.playing < CONFIG.HopMinPlayers then ok2 = false end
                if CONFIG.HopMaxPlayers and sv.playing > CONFIG.HopMaxPlayers then ok2 = false end
                if ok2 then table.insert(matched, entry) end
            end
        end
    end

    if #matched == 0 then
        if not CONFIG.HopFallbackAny or #anyValid == 0 then _isHopping = false; return false end
        matched = anyValid
    end

    table.sort(matched, function(a, b) return a.count > b.count end)
    local chosen = matched[math.random(1, math.min(10, #matched))]
    print(string.format("[BBG] Hop → %d players | %s", chosen.count, chosen.region))

    local ok = pcall(function()
        if browser then browser:InvokeServer("teleport", chosen.uuid) end
    end)
    if not ok then
        _isHopping = false
        _lastHopTime = os.clock() - HOP_COOLDOWN + 3
    end
    return ok
end

-- Auto hop watcher — hop agar koi player nahi mila timeout ke baad
local _lastKillTime = os.clock()
local _lastForcedHop = os.clock()

task.spawn(function()
    while true do
        task.wait(1)
        if not getgenv().AbuseActive then continue end
        
        local timeSinceAction = os.clock() - _lastKillTime
        local timeSinceForced = os.clock() - _lastForcedHop
        
        -- Condition 1: No activity (18s) OR Condition 2: Forced timer (4m)
        if timeSinceAction >= CONFIG.NoHitTimeout or timeSinceForced >= CONFIG.ForcedHopTime then
            StatusLbl.Text = timeSinceForced >= CONFIG.ForcedHopTime and "Status: Forced Hopping..." or "Status: Hopping..."
            local hopped = false
            for i = 1, 5 do
                hopped = Hop(); if hopped then break end; task.wait(4)
            end
            _lastKillTime = os.clock()
            _lastForcedHop = os.clock()
            StatusLbl.Text = hopped and "Status: Hopped ✓" or "Status: Hop failed"
        end
    end
end)

-- Update kill time on each abuse cycle
local _origExecute = ExecuteAbuse
ExecuteAbuse = function()
    _lastKillTime = os.clock()
    _origExecute()
end

-- ============================================================
--  BUTTON LOGIC
-- ============================================================
AbuseBtn.MouseButton1Click:Connect(function()
    getgenv().AbuseActive = not getgenv().AbuseActive
    if getgenv().AbuseActive then
        AbuseBtn.Text = "AUTO ABUSE: ON"
        AbuseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        StatusLbl.Text = "Status: Running"
        _lastKillTime = os.clock()
        _lastForcedHop = os.clock()
        task.spawn(ExecuteAbuse)
    else
        AbuseBtn.Text = "AUTO ABUSE: OFF"
        AbuseBtn.BackgroundColor3 = Color3.fromRGB(50, 0, 80)
        StatusLbl.Text = "Status: OFF"
    end
end)

-- Pirates join loop (on execute)
task.spawn(function()
    local elapsed = 0
    while elapsed < 30 do
        task.wait(0.5)
        elapsed += 0.5
        if lp.Team and lp.Team.Name == "Pirates" then break end
        selectFaction("Pirates")
    end
end)

-- New server watcher (hop ke baad Pirates auto-select)
task.spawn(function()
    local lastTeam = lp.Team
    while true do
        task.wait(1)
        if lp.Team ~= lastTeam then
            lastTeam = lp.Team
            if not lp.Team or lp.Team.Name ~= "Pirates" then
                local elapsed = 0
                while elapsed < 30 do
                    task.wait(0.5)
                    elapsed += 0.5
                    if lp.Team and lp.Team.Name == "Pirates" then break end
                    selectFaction("Pirates")
                end
            end
        end
    end
end)

-- Auto start on execute
_lastKillTime = os.clock()
_lastForcedHop = os.clock()
task.spawn(ExecuteAbuse)

FixBtn.MouseButton1Click:Connect(function()
    pcall(function()
        workspace.CurrentCamera.CameraSubject = lp.Character.Humanoid
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    end)
end)
