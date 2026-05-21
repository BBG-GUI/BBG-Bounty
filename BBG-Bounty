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
    if _isHopping then return f