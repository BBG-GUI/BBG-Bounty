-- ============================================================
--  BBG BOUNTY  |  Night Grind Edition
--  Features: Kill Aura (Inf Range), Auto Bounty Grind,
--            Auto Haki, Z Spam, Sky Glitch, Server Hop
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local HttpService       = game:GetService("HttpService")
local VIM               = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local pgui   = player:WaitForChild("PlayerGui")

-- Cleanup old GUI
for _, n in ipairs({"BBGBountyUI", "ZBountyUI"}) do
    for _, parent in ipairs({pgui, game:GetService("CoreGui")}) do
        pcall(function()
            local old = parent:FindFirstChild(n)
            if old then old:Destroy() end
        end)
    end
end

-- ============================================================
--  THEME SYSTEM
-- ============================================================
local THEMES = {
    Default = { accent=Color3.fromRGB(210,215,225), bg=Color3.fromRGB(9,9,11),   card=Color3.fromRGB(17,17,20)  },
    Cyan    = { accent=Color3.fromRGB(0,190,240),   bg=Color3.fromRGB(8,10,20),  card=Color3.fromRGB(12,15,28)  },
    Red     = { accent=Color3.fromRGB(230,60,60),   bg=Color3.fromRGB(14,7,7),   card=Color3.fromRGB(20,12,12)  },
    Green   = { accent=Color3.fromRGB(50,220,100),  bg=Color3.fromRGB(7,13,8),   card=Color3.fromRGB(10,19,12)  },
    Purple  = { accent=Color3.fromRGB(170,80,255),  bg=Color3.fromRGB(11,7,18),  card=Color3.fromRGB(16,11,26)  },
    Orange  = { accent=Color3.fromRGB(240,130,40),  bg=Color3.fromRGB(14,10,6),  card=Color3.fromRGB(20,15,9)   },
    Blue    = { accent=Color3.fromRGB(60,120,255),  bg=Color3.fromRGB(7,8,18),   card=Color3.fromRGB(11,12,26)  },
    Pink    = { accent=Color3.fromRGB(240,60,180),  bg=Color3.fromRGB(14,7,13),  card=Color3.fromRGB(20,10,18)  },
}
local THEME    = THEMES.Cyan
local T_ACCENT = THEME.accent
local T_BG     = THEME.bg
local T_CARD   = THEME.card
local C = {
    text   = Color3.fromRGB(220,225,245),
    muted  = Color3.fromRGB(90,100,135),
    green  = Color3.fromRGB(45,210,110),
    red    = Color3.fromRGB(215,60,60),
    gold   = Color3.fromRGB(240,185,55),
    pirate = Color3.fromRGB(190,50,50),
    marine = Color3.fromRGB(40,110,200),
}

-- ============================================================
--  CONFIG
-- ============================================================
local CONFIG = {
    Team          = "Pirates",  -- "Pirates" or "Marines"
    Weapon        = "Melee",    -- "Melee", "Sword", or "funcion" (both)
    MinLevel      = 100,
    NoHitTimeout  = 15,
    HopMinPlayers = 6,
    HopMaxPlayers = 10,
    HopRegion     = nil,
    HopFallbackAny= true,
    MaxServerTime = 0,
}

-- ============================================================
--  STATE
-- ============================================================
local State = {
    active         = false,
    enabledCielo   = false,
    autoHaki       = false,
    respawnAbuse   = false,
    lastHitTime    = os.clock(),
    serverJoinTime = os.clock(),
    sessionEarned  = 0,
    startBounty    = 0,
    currentBounty  = 0,
    kills          = 0,
    status         = "OFF",
    killAuraActive = false,
    killAuraRange  = 5000,
    killAuraConn   = nil,
}

-- ============================================================
--  UI HELPERS
-- ============================================================
local function addStroke(p, color, thick, trans)
    local s = Instance.new("UIStroke", p)
    s.Color = color or T_ACCENT; s.Thickness = thick or 1; s.Transparency = trans or 0
    return s
end
local function mkCorner(p, r)
    Instance.new("UICorner", p).CornerRadius = UDim.new(0, r or 8)
end
local function mkLabel(parent, size, pos, text, font, textSize, color, xAlign)
    local l = Instance.new("TextLabel", parent)
    l.Size = size; l.Position = pos or UDim2.new(0,0,0,0)
    l.BackgroundTransparency = 1; l.Text = text or ""
    l.Font = font or Enum.Font.Gotham; l.TextSize = textSize or 11
    l.TextColor3 = color or C.text
    l.TextXAlignment = xAlign or Enum.TextXAlignment.Center
    l.TextTruncate = Enum.TextTruncate.AtEnd
    return l
end
local function mkFrame(parent, size, pos, bg, trans, radius)
    local f = Instance.new("Frame", parent)
    f.Size = size; f.Position = pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3 = bg or T_CARD
    f.BackgroundTransparency = trans or 0
    f.BorderSizePixel = 0; mkCorner(f, radius or 8)
    return f
end
local function mkBtn(parent, size, pos, text, font, textSize, bg, textColor)
    local b = Instance.new("TextButton", parent)
    b.Size = size; b.Position = pos or UDim2.new(0,0,0,0)
    b.BackgroundColor3 = bg or T_CARD
    b.Text = text or ""; b.Font = font or Enum.Font.GothamBold
    b.TextSize = textSize or 11; b.TextColor3 = textColor or C.text
    b.BorderSizePixel = 0; b.AutoButtonColor = false; mkCorner(b, 7)
    return b
end

-- ============================================================
--  SCREEN GUI
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BBGBountyUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
local _ok = pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not _ok then ScreenGui.Parent = pgui end

-- Toggle button
local ToggleBtn = mkBtn(ScreenGui, UDim2.new(0,38,0,38), UDim2.new(0,8,0,8), "⚡", Enum.Font.GothamBlack, 16, T_BG, T_ACCENT)
addStroke(ToggleBtn, T_ACCENT, 1, 0.3)

-- ============================================================
--  MAIN WINDOW  (Sacred layout)
-- ============================================================
local Main = mkFrame(ScreenGui, UDim2.new(0,560,0,340), UDim2.new(0,52,0,8), T_BG, 0, 10)
Main.Active = true; Main.Draggable = true; Main.Visible = false
local mainStroke = addStroke(Main, T_ACCENT, 1, 0.6)

-- Animated border glow
task.spawn(function()
    local t = 0
    while true do
        task.wait(0.06); t += 0.06
        if mainStroke and mainStroke.Parent then
            mainStroke.Transparency = 0.45 + 0.3 * math.abs(math.sin(t * 0.8))
        end
    end
end)

-- ── LEFT PANEL ───────────────────────────────────────────────
local left = mkFrame(Main, UDim2.new(0,160,1,0), UDim2.new(0,0,0,0), T_CARD, 0.25, 10)
addStroke(left, T_ACCENT, 1, 0.55)

-- Avatar
local avOuter = mkFrame(left, UDim2.new(0,64,0,64), UDim2.new(0.5,-32,0,10), T_BG, 0, 32)
addStroke(avOuter, T_ACCENT, 2, 0.2)
local avImg = Instance.new("ImageLabel", avOuter)
avImg.Size = UDim2.new(1,-4,1,-4); avImg.Position = UDim2.new(0,2,0,2)
avImg.BackgroundTransparency = 1; avImg.ScaleType = Enum.ScaleType.Crop
mkCorner(avImg, 32)
task.spawn(function()
    local ok3, url = pcall(function()
        return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
    end)
    if ok3 and url then avImg.Image = url end
end)

mkLabel(left, UDim2.new(1,-8,0,14), UDim2.new(0,4,0,80), player.Name, Enum.Font.GothamBlack, 12, C.text)

-- Current bounty
local bountyBg = mkFrame(left, UDim2.new(0.88,0,0,24), UDim2.new(0.06,0,0,98), T_BG, 0)
addStroke(bountyBg, T_ACCENT, 1, 0.5)
local CurrLbl = mkLabel(bountyBg, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), "0", Enum.Font.GothamBlack, 14, C.green)

-- Session timer
local timerBg = mkFrame(left, UDim2.new(0.88,0,0,20), UDim2.new(0.06,0,0,126), T_CARD, 0)
addStroke(timerBg, T_ACCENT, 1, 0.6)
local StatBadge = mkLabel(timerBg, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), "00:00", Enum.Font.GothamBold, 12, Color3.fromRGB(130,142,178))
local _sessionStart = os.clock()
task.spawn(function()
    while true do
        task.wait(1)
        if State.active then
            local e = math.floor(os.clock() - _sessionStart)
            StatBadge.Text = string.format("%02d:%02d", math.floor(e/60), e%60)
        end
    end
end)

-- Faction badge
local facBg = mkFrame(left, UDim2.new(0.88,0,0,22), UDim2.new(0.06,0,0,150),
    CONFIG.Team == "Pirates" and Color3.fromRGB(100,22,22) or Color3.fromRGB(20,55,110), 0)
addStroke(facBg, CONFIG.Team == "Pirates" and Color3.fromRGB(210,80,80) or Color3.fromRGB(80,150,230), 1, 0.35)
mkLabel(facBg, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0),
    CONFIG.Team == "Pirates" and "🏴 PIRATAS" or "⚓ MARINES", Enum.Font.GothamBlack, 11, Color3.new(1,1,1))

-- Status dot + label
local statusDot = Instance.new("Frame", left)
statusDot.Size = UDim2.new(0,7,0,7); statusDot.Position = UDim2.new(0,10,0,182)
statusDot.BackgroundColor3 = C.red; statusDot.BorderSizePixel = 0; mkCorner(statusDot, 4)
local statusLblLeft = mkLabel(left, UDim2.new(1,-22,0,14), UDim2.new(0,20,0,179), "OFF", Enum.Font.GothamBold, 10, C.muted, Enum.TextXAlignment.Left)

-- Kills
mkLabel(left, UDim2.new(1,-8,0,10), UDim2.new(0,4,0,200), "KILLS", Enum.Font.Gotham, 8, C.muted)
local killsLblLeft = mkLabel(left, UDim2.new(1,-8,0,20), UDim2.new(0,4,0,211), "0", Enum.Font.GothamBlack, 18, C.red)

-- ── RIGHT PANEL ──────────────────────────────────────────────
local right = mkFrame(Main, UDim2.new(1,-162,1,0), UDim2.new(0,162,0,0), T_BG, 0.45, 10)

-- Header bar
local headerBar = mkFrame(right, UDim2.new(1,-6,0,30), UDim2.new(0,3,0,4), T_CARD, 0)
addStroke(headerBar, T_ACCENT, 1, 0.6)
mkLabel(headerBar, UDim2.new(0,110,1,0), UDim2.new(0,10,0,0), "BBG Bounty", Enum.Font.GothamBlack, 13, C.text, Enum.TextXAlignment.Left)
local TimerLbl = mkLabel(headerBar, UDim2.new(0,60,1,0), UDim2.new(0,115,0,0), "⏱ 0s", Enum.Font.GothamBold, 11, C.muted)
local hActivoBadge = mkFrame(headerBar, UDim2.new(0,72,0,18), UDim2.new(0,180,0.5,-9), T_BG:Lerp(T_ACCENT,0.15), 0)
addStroke(hActivoBadge, T_ACCENT, 1, 0.5)
local hActivoLbl = mkLabel(hActivoBadge, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), "● OFF", Enum.Font.GothamBold, 9, C.muted)
local minBtn = mkBtn(headerBar, UDim2.new(0,22,0,18), UDim2.new(1,-26,0.5,-9), "−", Enum.Font.GothamBlack, 13, Color3.fromRGB(80,20,20), Color3.new(1,1,1))
addStroke(minBtn, Color3.fromRGB(200,70,70), 1, 0.4)

-- Stats row
local statsRow = mkFrame(right, UDim2.new(1,-6,0,40), UDim2.new(0,3,0,38), T_CARD, 0)
addStroke(statsRow, T_ACCENT, 1, 0.55)
local function statCell(parent, label, idx, total, valColor)
    local w = 1/total
    local cell = mkFrame(parent, UDim2.new(w,0,1,0), UDim2.new(w*idx,0,0,0), T_CARD, 1)
    if idx > 0 then
        local sep = Instance.new("Frame", cell)
        sep.Size = UDim2.new(0,1,0.45,0); sep.Position = UDim2.new(0,0,0.275,0)
        sep.BackgroundColor3 = T_ACCENT; sep.BackgroundTransparency = 0.7; sep.BorderSizePixel = 0
    end
    mkLabel(cell, UDim2.new(1,0,0,12), UDim2.new(0,0,0,2), label, Enum.Font.Gotham, 7, C.muted)
    return mkLabel(cell, UDim2.new(1,0,0,22), UDim2.new(0,0,0,14), "—", Enum.Font.GothamBlack, 14, valColor or C.text)
end
local KillLbl   = statCell(statsRow, "KILLS",   0, 4, C.red)
local EarnedLbl = statCell(statsRow, "GANADO",  1, 4, C.green)
local StartLbl  = statCell(statsRow, "INICIAL", 2, 4, C.text)
local PingLbl   = statCell(statsRow, "PING",    3, 4, T_ACCENT)

task.spawn(function()
    while true do
        task.wait(2)
        pcall(function()
            local p = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
            PingLbl.Text = p.."ms"
            PingLbl.TextColor3 = p < 100 and C.green or (p < 250 and C.gold or C.red)
        end)
    end
end)

-- Timer bar
local barBg = mkFrame(right, UDim2.new(1,-6,0,14), UDim2.new(0,3,0,82), T_BG, 0)
addStroke(barBg, T_ACCENT, 1, 0.65)
local TimerBar = Instance.new("Frame", barBg)
TimerBar.Size = UDim2.new(0,0,1,0); TimerBar.BackgroundColor3 = T_ACCENT; TimerBar.BorderSizePixel = 0
mkCorner(TimerBar, 5)
local tgrad = Instance.new("UIGradient", TimerBar)
tgrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, T_ACCENT),
    ColorSequenceKeypoint.new(1, T_ACCENT:Lerp(Color3.new(1,1,1),0.3)),
})
local barPctLbl = mkLabel(barBg, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), "0s", Enum.Font.GothamBold, 8, C.text)

-- ── Scroll area for buttons ───────────────────────────────────
local scroll = Instance.new("ScrollingFrame", right)
scroll.Size = UDim2.new(1,-6,1,-102); scroll.Position = UDim2.new(0,3,0,100)
scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 2; scroll.ScrollBarImageColor3 = T_ACCENT
scroll.CanvasSize = UDim2.new(0,0,0,300)
local listLayout = Instance.new("UIListLayout", scroll)
listLayout.Padding = UDim.new(0,5); listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function secLabel(txt)
    local l = Instance.new("TextLabel", scroll)
    l.Size = UDim2.new(0.96,0,0,16); l.BackgroundTransparency = 1
    l.Text = "· "..txt:upper().." ·"; l.Font = Enum.Font.GothamBold
    l.TextSize = 9; l.TextColor3 = T_ACCENT; l.TextXAlignment = Enum.TextXAlignment.Left
end
local function secBtn(txt, strokeColor)
    local b = mkBtn(scroll, UDim2.new(0.96,0,0,32), nil, txt, Enum.Font.GothamBold, 11, T_CARD, C.text)
    addStroke(b, strokeColor or T_ACCENT, 1, 0.4)
    return b
end

-- Buttons
secLabel("Bounty Grind")
local grindBtn = secBtn("▶  Start Bounty Grind", C.green)
local stopBtn  = secBtn("■  Stop Grind",          C.red)

secLabel("Kill Aura / Infinite Range")
local auraBtn  = secBtn("Kill Aura: OFF",  Color3.fromRGB(1,0.3,0.3))

secLabel("Settings")
local teamBtn   = secBtn("Team: "..CONFIG.Team,    CONFIG.Team == "Pirates" and C.pirate or C.marine)
local weaponBtn = secBtn("Weapon: "..CONFIG.Weapon, T_ACCENT)

-- ============================================================
--  MINI BAR
-- ============================================================
local miniBar = mkFrame(ScreenGui, UDim2.new(0,185,0,26), UDim2.new(0,52,0,10), T_BG, 0.1, 8)
miniBar.Visible = false; miniBar.Active = true
addStroke(miniBar, T_ACCENT, 1, 0.5)
local mKills  = mkLabel(miniBar, UDim2.new(0.25,0,1,0), UDim2.new(0,0,0,0),    "0K",    Enum.Font.GothamBold, 10, C.red)
local mBounty = mkLabel(miniBar, UDim2.new(0.38,0,1,0), UDim2.new(0.25,0,0,0), "+0",    Enum.Font.GothamBold, 10, C.green)
local mPing   = mkLabel(miniBar, UDim2.new(0.2,0,1,0),  UDim2.new(0.63,0,0,0), "0ms",   Enum.Font.GothamBold, 10, T_ACCENT)
local mFPS    = mkLabel(miniBar, UDim2.new(0.17,0,1,0), UDim2.new(0.83,0,0,0), "0fps",  Enum.Font.GothamBold, 10, C.muted)

-- FPS counter
local _fv, _fc, _fl = 0, 0, os.clock()
RunService.RenderStepped:Connect(function()
    _fc += 1; local n = os.clock()
    if n - _fl >= 1 then _fv = _fc; _fc = 0; _fl = n end
end)
task.spawn(function()
    while true do
        task.wait(0.5)
        if not miniBar.Visible then continue end
        pcall(function()
            mKills.Text = State.kills.."K"
            mBounty.Text = "+"..tostring(State.sessionEarned)
            local p = 0
            pcall(function() p = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()) end)
            mPing.Text = p.."ms"; mPing.TextColor3 = p < 100 and C.green or (p < 250 and C.gold or C.red)
            mFPS.Text = _fv.."fps"; mFPS.TextColor3 = _fv >= 50 and C.green or (_fv >= 30 and C.gold or C.red)
        end)
    end
end)
miniBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        miniBar.Visible = false; Main.Visible = true
    end
end)

-- ============================================================
--  UTILITY FUNCTIONS
-- ============================================================
local function fmt(n)
    if not n then return "0" end; n = math.floor(n)
    if n >= 1e9 then return string.format("%.2fB", n/1e9)
    elseif n >= 1e6 then return string.format("%.2fM", n/1e6)
    elseif n >= 1e3 then return string.format("%.1fK", n/1e3) end
    return tostring(n)
end

local function getBounty()
    local val = 0
    pcall(function()
        local d = player:FindFirstChild("Data")
        if d then
            local b = d:FindFirstChild("Bounty") or d:FindFirstChild("Honor") or d:FindFirstChild("Rep")
            if b and type(b.Value) == "number" then val = b.Value; return end
        end
        local ls = player:FindFirstChild("leaderstats")
        if ls then
            local b = ls:FindFirstChild("Bounty/Honor") or ls:FindFirstChild("Bounty") or ls:FindFirstChild("Honor")
            if b and type(b.Value) == "number" then val = b.Value end
        end
    end)
    return val
end

local CommF_
pcall(function() CommF_ = ReplicatedStorage:WaitForChild("Remotes",5):WaitForChild("CommF_",5) end)

local function buso()
    pcall(function() CommF_:InvokeServer("Buso") end)
end
local function down(key)
    pcall(function()
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        VIM:SendKeyEvent(true, key, false, hrp); task.wait(0.15)
        VIM:SendKeyEvent(false, key, false, hrp)
    end)
end
local function equip(tooltip)
    if not tooltip then return end
    pcall(function()
        local char = player.Character or player.CharacterAdded:Wait()
        local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
        for _, tool in pairs(player.Backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.ToolTip == tooltip then hum:EquipTool(tool); return end
        end
    end)
end
local function selectFaction(faction)
    pcall(function()
        for _, v in pairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("RemoteEvent") and v.Name == "RE/OnEventServiceActivity" then
                v:FireServer("TeamSelect/Team/"..faction)
            end
            if v:IsA("RemoteFunction") and v.Name == "CommF_" then
                task.wait(0.05); v:InvokeServer("SetTeam", faction)
            end
        end
    end)
end
local function hasValidTargets()
    for _, pl in pairs(Players:GetPlayers()) do
        if pl ~= player then
            local level = 0
            pcall(function()
                local d = pl:FindFirstChild("Data")
                if d then local lv = d:FindFirstChild("Level"); if lv then level = lv.Value end end
            end)
            if level >= CONFIG.MinLevel then return true end
        end
    end
    return false
end
local function findChooseTeam()
    for _, gui in ipairs(player.PlayerGui:GetChildren()) do
        local ct = gui:FindFirstChild("ChooseTeam", true); if ct then return ct end
    end
    return nil
end

-- Save / Load
local SAVE_FILE = "bbg_bounty.json"
local function saveData()
    pcall(function()
        writefile(SAVE_FILE, HttpService:JSONEncode({
            sessionEarned = State.sessionEarned,
            startBounty   = State.startBounty,
            kills         = State.kills,
        }))
    end)
end
local function loadData()
    pcall(function()
        if isfile and isfile(SAVE_FILE) then
            local d = HttpService:JSONDecode(readfile(SAVE_FILE))
            if d then
                State.sessionEarned = d.sessionEarned or 0
                State.startBounty   = d.startBounty   or getBounty()
                State.kills         = d.kills         or 0
                return
            end
        end
        State.startBounty = getBounty()
    end)
end

-- ============================================================
--  SERVER HOP  (Sacred: cooldown + 5 retries)
-- ============================================================
local _place = game.PlaceId; local _id = game.JobId
local _isHopping = false; local _lastHopTime = 0; local HOP_COOLDOWN = 8
local browser
pcall(function() browser = ReplicatedStorage:FindFirstChild("__ServerBrowser") end)

local function Hop()
    if _isHopping then return false end
    if os.clock() - _lastHopTime < HOP_COOLDOWN then return false end
    _isHopping = true; _lastHopTime = os.clock()
    task.delay(12, function() _isHopping = false end)
    State.respawnAbuse = false; State.enabledCielo = false

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
                        if type(info) == "table" and info.Count then allServers[uuid] = info; valid += 1 end
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

    local apiServers = {}
    if not foundData then
        for _, ord in ipairs({"Desc","Asc"}) do
            pcall(function()
                local r = HttpService:JSONDecode(game:HttpGet(
                    "https://games.roblox.com/v1/games/".._place.."/servers/Public?sortOrder="..ord.."&limit=100"))
                if r and r.data then for _, sv in ipairs(r.data) do table.insert(apiServers, sv) end end
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
                    if not string.find(string.lower(info.Region or ""), string.lower(CONFIG.HopRegion),1,true) then ok2 = false end
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
    table.sort(matched, function(a,b) return a.count > b.count end)
    local chosen = matched[math.random(1, math.min(10, #matched))]
    print(string.format("[BBG] Hop → %d players | %s", chosen.count, chosen.region))
    local ok = pcall(function() if browser then browser:InvokeServer("teleport", chosen.uuid) end end)
    if not ok then _isHopping = false; _lastHopTime = os.clock() - HOP_COOLDOWN + 3 end
    return ok
end

-- ============================================================
--  KILL AURA  (Infinite Range — from Kill_Aura pptx)
-- ============================================================
local Net, RegisterHit, RegisterAttack
pcall(function()
    Net = ReplicatedStorage.Modules.Net
    RegisterHit    = Net["RE/RegisterHit"]
    RegisterAttack = Net["RE/RegisterAttack"]
end)

local function AttackMultipleTargets(targets)
    pcall(function()
        if not targets or #targets == 0 then return end
        local allTargets = {}
        for _, char in pairs(targets) do
            local head = char:FindFirstChild("Head")
            if head then allTargets[#allTargets+1] = {char, head} end
        end
        if #allTargets == 0 then return end
        if RegisterAttack then RegisterAttack:FireServer(0) end
        if RegisterHit    then RegisterHit:FireServer(allTargets[1][2], allTargets) end
    end)
end

local function StartKillAura()
    if State.killAuraConn then task.cancel(State.killAuraConn) end
    State.killAuraConn = task.spawn(function()
        while State.killAuraActive do
            task.wait(0.01)
            local myChar = player.Character
            local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myHRP then continue end
            local targets = {}
            for _, pl in pairs(Players:GetPlayers()) do
                if pl ~= player and pl.Character then
                    local hum = pl.Character:FindFirstChild("Humanoid")
                    local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
                    if hum and hrp and hum.Health > 0 and
                       (hrp.Position - myHRP.Position).Magnitude <= State.killAuraRange then
                        targets[#targets+1] = pl.Character
                    end
                end
            end
            local enemies = workspace:FindFirstChild("Enemies")
            if enemies then
                for _, npc in pairs(enemies:GetChildren()) do
                    local hum = npc:FindFirstChild("Humanoid")
                    local hrp = npc:FindFirstChild("HumanoidRootPart")
                    if hum and hrp and hum.Health > 0 and
                       (hrp.Position - myHRP.Position).Magnitude <= State.killAuraRange then
                        targets[#targets+1] = npc
                    end
                end
            end
            if #targets > 0 then AttackMultipleTargets(targets) end
        end
    end)
end

-- ============================================================
--  GRIND LOOPS
-- ============================================================
-- Auto haki
task.spawn(function()
    while task.wait(0.5) do
        if State.autoHaki then buso() end
    end
end)

-- Respawn abuse + Z spam (Sacred logic)
local angle = 0
task.spawn(function()
    while task.wait() do
        if not State.respawnAbuse then continue end
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            angle += math.rad(500)
            root.CFrame = root.CFrame * CFrame.new(math.cos(angle)*3, 0, math.sin(angle)*3)
        end
        if State.autoHaki then buso() end
        if CONFIG.Weapon == "funcion" then
            equip("Sword"); task.wait(0.15); down("Z"); task.wait(0.3)
            equip("Melee"); task.wait(0.15); down("Z"); task.wait(0.3)
        else
            equip(CONFIG.Weapon); task.wait(0.15); down("Z"); task.wait(0.5)
        end
        if char and char:FindFirstChild("Humanoid") then char.Humanoid.Health = 0 end
        player.CharacterAdded:Wait(); task.wait(0.5)
    end
end)

-- Sky glitch
RunService.RenderStepped:Connect(function(dt)
    if not State.enabledCielo then return end
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root then root.CFrame = root.CFrame + Vector3.new(0, 1e35*dt, 0) end
end)

-- Damage detection (Sacred: creator tag)
local function getEquipped()
    local char = player.Character; if not char then return nil end
    for _, t in ipairs(char:GetChildren()) do if t:IsA("Tool") then return t end end
    return nil
end
local function watchPlayer(p)
    if p == player then return end
    local function watchEnemy(char)
        pcall(function()
            local hum = char:WaitForChild("Humanoid", 5); if not hum then return end
            local last = hum.Health
            hum:GetPropertyChangedSignal("Health"):Connect(function()
                local delta = last - hum.Health; last = hum.Health
                if delta > 1 and State.active and getEquipped() then
                    local isOurs = false
                    local creator = hum:FindFirstChild("creator")
                    if creator and creator:IsA("ObjectValue") and creator.Value == player then isOurs = true end
                    if not isOurs then
                        for _, tag in ipairs(hum:GetChildren()) do
                            if tag:IsA("ObjectValue") and tag.Value == player then isOurs = true; break end
                        end
                    end
                    if isOurs then State.lastHitTime = os.clock() end
                end
            end)
        end)
    end
    p.CharacterAdded:Connect(function(c) task.wait(0.5); watchEnemy(c) end)
    if p.Character then watchEnemy(p.Character) end
end
for _, p in ipairs(Players:GetPlayers()) do watchPlayer(p) end
Players.PlayerAdded:Connect(watchPlayer)

-- Bounty notification
pcall(function()
    local CommE = ReplicatedStorage:WaitForChild("Remotes",5):WaitForChild("CommE",5)
    CommE.OnClientEvent:Connect(function(event, ...)
        if not State.active or event ~= "Notify" then return end
        local msg = select(1,...) or ""
        if msg:find("Bounty<Color=/> from") or msg:find("Honor<Color=/> from") then
            local earned = tonumber(string.match(msg, ">(%d+)")) or 0
            State.sessionEarned += earned; State.kills += 1
            State.lastHitTime = os.clock(); State.currentBounty = getBounty()
            saveData()
        end
    end)
end)

-- Hop watcher (Sacred: retries + MaxServerTime + bounty drop detect)
local _prevBounty = 0
task.spawn(function()
    task.wait(10); _prevBounty = getBounty()
    while true do
        task.wait(3); if not State.active then continue end
        local cur = getBounty()
        if _prevBounty > 0 and cur < _prevBounty then
            State.status = "Bounty caido → Hop"
            State.lastHitTime = os.clock() - CONFIG.NoHitTimeout - 1
        end
        _prevBounty = cur
    end
end)

task.spawn(function()
    while task.wait(1) do
        if not State.active then continue end
        if CONFIG.MaxServerTime and CONFIG.MaxServerTime > 0 then
            if os.clock() - State.serverJoinTime >= CONFIG.MaxServerTime then
                State.status = "Tiempo → Hop"; saveData()
                for i=1,5 do if Hop() then break end; task.wait(4) end
                task.wait(3); State.serverJoinTime = os.clock()
                State.lastHitTime = os.clock(); State.status = "Activo"; continue
            end
        end
        if not hasValidTargets() then
            State.status = "Sin targets → Hop"
            for i=1,5 do if Hop() then break end; task.wait(4) end
            task.wait(2); State.serverJoinTime = os.clock()
            State.lastHitTime = os.clock(); State.status = "Activo"; continue
        end
        if os.clock() - State.lastHitTime >= CONFIG.NoHitTimeout then
            State.status = "Hopeando..."; saveData()
            local hopped = false
            for i=1,5 do hopped = Hop(); if hopped then break end; task.wait(4) end
            if hopped then task.wait(3) end
            State.serverJoinTime = os.clock(); State.lastHitTime = os.clock(); State.status = "Activo"
        end
    end
end)

-- Auto faction re-select after hop
task.spawn(function()
    local lastVis = false
    while true do
        task.wait(0.5); if not State.active then continue end
        local ct = findChooseTeam(); local vis = ct and ct.Visible or false
        if vis and not lastVis then
            task.wait(0.4)
            for i=1,5 do
                selectFaction(CONFIG.Team); task.wait(1.2)
                if player.Team and player.Team.Name == CONFIG.Team then break end
            end
        end
        lastVis = vis
    end
end)

-- Start / Stop
local function startAll()
    loadData()
    State.active = true; State.enabledCielo = true
    State.autoHaki = true; State.respawnAbuse = true
    State.lastHitTime = os.clock(); State.serverJoinTime = os.clock()
    State.currentBounty = getBounty(); State.status = "Activo"
    _sessionStart = os.clock()
    print("[BBG] Grind ACTIVO — "..CONFIG.Team.." / "..CONFIG.Weapon)
end
local function stopAll()
    State.active = false; State.enabledCielo = false
    State.autoHaki = false; State.respawnAbuse = false
    State.status = "OFF"; saveData()
    print("[BBG] Grind DETENIDO")
end

-- ============================================================
--  GUI UPDATER
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            State.currentBounty = getBounty()
            CurrLbl.Text   = fmt(State.currentBounty)
            KillLbl.Text   = tostring(State.kills)
            EarnedLbl.Text = "+"..fmt(State.sessionEarned)
            StartLbl.Text  = fmt(State.startBounty)
            killsLblLeft.Text = tostring(State.kills)
            if State.active then
                local sinceHit  = os.clock() - State.lastHitTime
                local remaining = math.max(0, CONFIG.NoHitTimeout - sinceHit)
                local pct       = remaining / CONFIG.NoHitTimeout
                TimerBar.Size = UDim2.new(pct,0,1,0)
                barPctLbl.Text = math.ceil(remaining).."s"
                tgrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, pct > 0.4 and T_ACCENT or C.red),
                    ColorSequenceKeypoint.new(1, pct > 0.4 and T_ACCENT:Lerp(Color3.new(1,1,1),0.25) or C.gold),
                })
                TimerLbl.Text = remaining > 0 and ("⏱ "..math.ceil(remaining).."s") or "⏱ Hop"
                TimerLbl.TextColor3 = remaining > 0 and (pct > 0.4 and C.muted or C.gold) or C.red
                statusLblLeft.Text = State.status
            end
        end)
    end
end)

-- ============================================================
--  BUTTON LOGIC
-- ============================================================
grindBtn.MouseButton1Click:Connect(function()
    if State.active then return end
    grindBtn.BackgroundColor3 = C.green:Lerp(T_CARD, 0.5)
    task.spawn(function()
        local confirmed, elapsed = false, 0
        if player.Team and player.Team.Name == CONFIG.Team then confirmed = true end
        while not confirmed do
            task.wait(0.3); elapsed += 0.3
            selectFaction(CONFIG.Team); task.wait(0.5)
            if player.Team and player.Team.Name == CONFIG.Team then confirmed = true; break end
            if elapsed >= 30 then confirmed = true end
        end
        startAll()
        hActivoLbl.Text = "● ACTIVO"; hActivoLbl.TextColor3 = C.green
        statusDot.BackgroundColor3 = C.green
        hActivoBadge.BackgroundColor3 = T_BG:Lerp(T_ACCENT, 0.2)
        if not hasValidTargets() then
            State.status = "Sin targets → Hop"; task.wait(2)
            for i=1,5 do if Hop() then break end; task.wait(4) end
            task.wait(5); State.lastHitTime = os.clock(); State.status = "Activo"
        end
    end)
end)

stopBtn.MouseButton1Click:Connect(function()
    stopAll()
    grindBtn.BackgroundColor3 = T_CARD
    hActivoLbl.Text = "● OFF"; hActivoLbl.TextColor3 = C.muted
    statusDot.BackgroundColor3 = C.red
    hActivoBadge.BackgroundColor3 = T_CARD
end)

auraBtn.MouseButton1Click:Connect(function()
    State.killAuraActive = not State.killAuraActive
    if State.killAuraActive then
        StartKillAura()
        auraBtn.Text = "Kill Aura: ON ✓"
        auraBtn.BackgroundColor3 = C.red:Lerp(T_CARD, 0.3)
    else
        if State.killAuraConn then task.cancel(State.killAuraConn); State.killAuraConn = nil end
        auraBtn.Text = "Kill Aura: OFF"; auraBtn.BackgroundColor3 = T_CARD
    end
end)

-- Team toggle
teamBtn.MouseButton1Click:Connect(function()
    CONFIG.Team = CONFIG.Team == "Pirates" and "Marines" or "Pirates"
    teamBtn.Text = "Team: "..CONFIG.Team
    addStroke(teamBtn, CONFIG.Team == "Pirates" and C.pirate or C.marine, 1, 0.4)
    facBg.BackgroundColor3 = CONFIG.Team == "Pirates" and Color3.fromRGB(100,22,22) or Color3.fromRGB(20,55,110)
    local facLbl = facBg:FindFirstChildOfClass("TextLabel")
    if facLbl then facLbl.Text = CONFIG.Team == "Pirates" and "🏴 PIRATAS" or "⚓ MARINES" end
end)

-- Weapon toggle
weaponBtn.MouseButton1Click:Connect(function()
    local weapons = {"Melee","Sword","funcion"}
    local idx = 1
    for i, w in ipairs(weapons) do if w == CONFIG.Weapon then idx = i; break end end
    CONFIG.Weapon = weapons[(idx % #weapons) + 1]
    weaponBtn.Text = "Weapon: "..CONFIG.Weapon
end)

-- ============================================================
--  TOGGLE / MINIMIZE
-- ============================================================
local minimized = false
local function openMain()
    miniBar.Visible = false; minimized = false; minBtn.Text = "−"
    Main.Visible = true; Main.BackgroundTransparency = 1
    Main.Size = UDim2.new(0,560,0,0); Main.Position = UDim2.new(0,52,0,-10); Main.BackgroundColor3 = T_BG
    TweenService:Create(Main, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = UDim2.new(0,560,0,340), BackgroundTransparency = 0, Position = UDim2.new(0,52,0,8),
    }):Play()
end
local function closeMain(showMini)
    TweenService:Create(Main, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
        Size = UDim2.new(0,560,0,0), BackgroundTransparency = 1, Position = UDim2.new(0,52,0,-10),
    }):Play()
    task.wait(0.18); Main.Visible = false
    Main.Size = UDim2.new(0,560,0,340); Main.BackgroundTransparency = 0; Main.Position = UDim2.new(0,52,0,8)
    if showMini then miniBar.Visible = true end
end

ToggleBtn.MouseButton1Click:Connect(function()
    if miniBar.Visible then openMain()
    elseif Main.Visible then minimized = true; minBtn.Text = "+"; task.spawn(function() closeMain(false) end)
    else openMain() end
end)
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then minBtn.Text = "+"; task.spawn(function() closeMain(true) end)
    else openMain() end
end)

Main.Visible = true

-- ============================================================
--  AUTO START EVERYTHING ON LOAD
-- ============================================================
task.spawn(function()
    task.wait(1) -- wait for game to settle

    -- Auto start Kill Aura
    State.killAuraActive = true
    StartKillAura()
    auraBtn.Text = "Kill Aura: ON ✓"
    auraBtn.BackgroundColor3 = C.red:Lerp(T_CARD, 0.3)

    -- Auto start Bounty Grind
    local confirmed, elapsed = false, 0
    if player.Team and player.Team.Name == CONFIG.Team then confirmed = true end
    while not confirmed do
        task.wait(0.3); elapsed += 0.3
        selectFaction(CONFIG.Team); task.wait(0.5)
        if player.Team and player.Team.Name == CONFIG.Team then confirmed = true; break end
        if elapsed >= 30 then confirmed = true end
    end

    startAll()
    grindBtn.BackgroundColor3 = C.green:Lerp(T_CARD, 0.5)
    hActivoLbl.Text = "● ACTIVO"; hActivoLbl.TextColor3 = C.green
    statusDot.BackgroundColor3 = C.green
    hActivoBadge.BackgroundColor3 = T_BG:Lerp(T_ACCENT, 0.2)

    if not hasValidTargets() then
        State.status = "Sin targets → Hop"; task.wait(2)
        for i=1,5 do if Hop() then break end; task.wait(4) end
        task.wait(5); State.lastHitTime = os.clock(); State.status = "Activo"
    end

    print("[BBG Bounty] Auto-started ✓")
end)

print("[BBG Bounty] Loaded ✓ | Team="..CONFIG.Team.." | Weapon="..CONFIG.Weapon)
