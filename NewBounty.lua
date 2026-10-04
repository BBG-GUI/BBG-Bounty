-- Services 
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local HttpService       = game:GetService("HttpService")
local TeleportService   = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

-- Config
local CFG = {
    FruitName        = "Mammoth-Mammoth",
    WeaponTip        = "Melee",
    FlySpeed         = 300,
    SkillKey         = "V",
    SkillRetries     = 50,
    M1Interval       = 0.1,
    ServerRegion     = "India",
    MinPlayers       = 1,
    MaxPlayers       = 12,
    MinBounty        = 0,
    MaxBounty        = 999999999,
    HopInterval      = 120,
    ServerListTimeout= 20,
    HopFallbackAny   = false,

    AutoV3           = true,
    AutoV4           = true,
    V3Interval       = 2,
    V4Interval       = 1,

    Noclip           = true,

    -- Auto Pirate
    AutoTeam         = true,
    Team             = "Pirates",

    -- Server Hop
    AutoExec         = true,
    AutoExecFile     = "mammoth_fly.lua", 

    -- Auto Messages 
    ChatEnabled      = true,
    ChatDelay        = 30,
    ChatMessages     = {
        "BBG PANEL ON TOP",
        "BBG's ART ON TOP",
        "LET'S RUINED BLOX FRUITS LOL",
        "POOR BLOX FRUITS",
        "BBG PANEL !! HAHAHAHA",
    },
}

-- Source
local src = [[

]]
local SRC_TERMINATOR = "--===SRC-END==="

local VOID_VECTOR = Vector3.new(9e30, 9e30, 9e30) -- void M1 argument

-- Utilities 
local function Log(fmt, ...)
    local ok, msg = pcall(string.format, fmt, ...)
    print("[Mammoth] " .. (ok and msg or tostring(fmt)))
end

local function GetChar()
    local char = LocalPlayer.Character
    if char and char.Parent then return char end
    return nil
end

local function GetHRP()
    local char = GetChar()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHum()
    local char = GetChar()
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- WaitForChild
local function SafeWait(parent, name, timeout)
    if not parent then return nil end
    local child = parent:FindFirstChild(name)
    if child then return child end
    local ok, result = pcall(function()
        return parent:WaitForChild(name, timeout or 5)
    end)
    return ok and result or nil
end

-- Pcall
local function InvokeRemote(remote, timeout, ...)
    if not remote then return false end
    local args = table.pack(...)
    local done, result = false, nil
    task.spawn(function()
        local ok, res = pcall(function()
            return remote:InvokeServer(table.unpack(args, 1, args.n))
        end)
        done, result = true, ok and res or nil
    end)
    local deadline = os.clock() + (timeout or 5)
    while not done and os.clock() < deadline do
        task.wait(0.05)
    end
    return done, result
end

-- Equip Fruit
local function GetBackpack()
    return LocalPlayer:FindFirstChildOfClass("Backpack") or LocalPlayer:FindFirstChild("Backpack")
end

-- Find Tools
local function FindToolIn(container, tip, prefName)
    if not container then return nil end
    if prefName and prefName ~= "" then
        local t = container:FindFirstChild(prefName)
        if t and t:IsA("Tool") then return t end
    end
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("Tool") and child.ToolTip == tip then
            return child
        end
    end
    return nil
end

local function GetEquippedFruit()
    return FindToolIn(GetChar(), "Blox Fruit", CFG.FruitName)
end

-- Equip Logic
local function EquipByTip(tip, prefName)
    local char = GetChar()
    local hum  = GetHum()
    if not char or not hum or hum.Health <= 0 then return nil end

    local held = FindToolIn(char, tip, prefName)
    if held then return held end

    local tool = FindToolIn(GetBackpack(), tip, prefName)
    if not tool then return nil end

    pcall(function() hum:EquipTool(tool) end)

    local deadline = os.clock() + 0.6
    while os.clock() < deadline do
        held = FindToolIn(GetChar(), tip, prefName)
        if held then return held end
        task.wait(0.05)
    end
    return nil
end

local function EquipFruit()
    return EquipByTip("Blox Fruit", CFG.FruitName)
end

local function UnequipAll()
    local hum = GetHum()
    if hum then pcall(function() hum:UnequipTools() end) end
end

-- Fly
local FlyActive = false
local FlyConn = nil
local FlyObjects = {}

local function MakeFlyObjects(hrp)
    local objects = { Parts = {} }

    local att = Instance.new("Attachment")
    att.Name = "MammothFlyAtt"
    att.Parent = hrp
    objects.Attachment = att

    local bv = Instance.new("BodyVelocity")
    bv.Name = "MammothFlyVelocity"
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.P = 1250
    bv.Velocity = Vector3.new(0, CFG.FlySpeed, 0)
    bv.Parent = hrp
    objects.Velocity = bv

    local bg = Instance.new("BodyGyro")
    bg.Name = "MammothFlyGyro"
    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.P = 3000
    bg.D = 500
    bg.CFrame = hrp.CFrame
    bg.Parent = hrp
    objects.Gyro = bg

    return objects
end

local function SetPartsCollide(char, collide)
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function() part.CanCollide = collide end)
        end
    end
end

local function StopFly()
    FlyActive = false

    if FlyConn then
        pcall(function() FlyConn:Disconnect() end)
        FlyConn = nil
    end

    if FlyObjects.Velocity then pcall(function() FlyObjects.Velocity:Destroy() end) end
    if FlyObjects.Gyro then pcall(function() FlyObjects.Gyro:Destroy() end) end
    if FlyObjects.Attachment then pcall(function() FlyObjects.Attachment:Destroy() end) end
    FlyObjects = {}

    local hum = GetHum()
    local hrp = GetHRP()
    if hum then
        pcall(function()
            hum.PlatformStand = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
    end
    if hrp then
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
    end
    local char = GetChar()
    if char then SetPartsCollide(char, true) end
end

local function StartFly()
    StopFly()

    local hrp = GetHRP()
    local hum = GetHum()
    if not hrp or not hum then
        return false
    end

    -- Network Ownership 
    pcall(function() hrp:SetNetworkOwner(LocalPlayer) end)

    hum.PlatformStand = true
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end)
    SetPartsCollide(GetChar(), false)

    FlyObjects = MakeFlyObjects(hrp)
    FlyActive = true

    FlyConn = RunService.Heartbeat:Connect(function()
        if not FlyActive then return end

        local root = GetHRP()
        local health = GetHum()
        if not root or not health or health.Health <= 0 then
            StopFly()
            return
        end

        -- CFG.FlySpeed
        local bv = FlyObjects.Velocity
        if bv and bv.Parent then
            bv.Velocity = Vector3.new(0, CFG.FlySpeed, 0)
        end
        local bg = FlyObjects.Gyro
        if bg and bg.Parent then
            bg.CFrame = CFrame.new(root.Position)
        end
    end)

    return true
end


-- NoClip
local NoclipActive = false
local NoclipConn = nil
local NoclipChanged = setmetatable({}, { __mode = "k" })
local NoclipIndex = 0
local NoclipLastScan = 0

local function ApplyNoclipPass()
    local char = GetChar()
    if not char then return end

    local parts = char:GetDescendants()
    local count = #parts
    if count == 0 then return end

    -- Process 
    local perPass = 40
    if count <= perPass then
        NoclipIndex = 0
    else
        NoclipIndex = NoclipIndex % count
    end

    local processed = 0
    local i = NoclipIndex
    while processed < perPass and processed < count do
        i = (i % count) + 1
        local part = parts[i]
        if part and part:IsA("BasePart") and part.CanCollide then
            NoclipChanged[part] = true
            part.CanCollide = false
        end
        processed = processed + 1
    end
    NoclipIndex = i
end

local function StopNoclip()
    NoclipActive = false

    if NoclipConn then
        pcall(function() NoclipConn:Disconnect() end)
        NoclipConn = nil
    end

    -- Restore Parts
    for part in pairs(NoclipChanged) do
        if typeof(part) == "Instance" and part.Parent then
            pcall(function() part.CanCollide = true end)
        end
    end
    NoclipChanged = setmetatable({}, { __mode = "k" })
    NoclipIndex = 0
end

local function StartNoclip()
    if NoclipActive then return end
    NoclipActive = true

    NoclipConn = RunService.Stepped:Connect(function()
        if not NoclipActive then return end

        local char = GetChar()
        if not char then return end

        ApplyNoclipPass()

        -- Anti Void
        local root = GetHRP()
        if root and root.Position.Y < -500 then
            pcall(function()
                root.CFrame = CFrame.new(root.Position.X, 200, root.Position.Z)
            end)
        end
    end)

end

-- Logic
local function GetSkillButton(toolName, key)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local main = pg and pg:FindFirstChild("Main")
    local skills = main and main:FindFirstChild("Skills")
    local board = skills and skills:FindFirstChild(toolName)
    return board and board:FindFirstChild(key)
end

--  Strip
local function IsOnCooldown(btn)
    local cd = btn and btn:FindFirstChild("Cooldown")
    return cd ~= nil and cd.AbsoluteSize.X > 0
end

local function PressKeyOnce(key, useStringForm)
    local hrp = GetHRP()
    pcall(function()
        if useStringForm then
            -- Auto
            VirtualInputManager:SendKeyEvent(true, key, false, hrp or game)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, key, false, hrp or game)
        else
            local code = Enum.KeyCode[key]
            VirtualInputManager:SendKeyEvent(true, code, false, game)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, code, false, game)
        end
    end)
end

local SkillCasted = false
local RunId = 0

local function CastSkill(myId)
    if SkillCasted then return true end

    local key = tostring(CFG.SkillKey):upper()
    local retries = CFG.SkillRetries or 50

    for attempt = 1, retries do
        if myId and myId ~= RunId then return false end

        -- Retry
        if attempt > 1 then
            UnequipAll()
            task.wait(0.15)
        end

        -- Equip 
        if CFG.WeaponTip and CFG.WeaponTip ~= "" then
            pcall(EquipByTip, CFG.WeaponTip)
            task.wait(0.1)
        end

        local fruit = nil
        pcall(function() fruit = EquipFruit() end)

        if fruit then
            -- Task.Wait
            local btn = GetSkillButton(fruit.Name, key)
            local t0 = os.clock()
            while not btn and os.clock() - t0 < 0.8 do
                task.wait(0.05)
                btn = GetSkillButton(fruit.Name, key)
            end

            if btn then
                if IsOnCooldown(btn) then
                    -- Check
                    SkillCasted = true
                    return true
                end

                -- Press
                for press = 1, 10 do
                    PressKeyOnce(key, (attempt + press) % 2 == 0)
                    task.wait(0.05)
                    if IsOnCooldown(GetSkillButton(fruit.Name, key)) then
                        SkillCasted = true
                        Log("%s skill executed (retry %d, key press %d)", key, attempt, press)
                        return true
                    end
                end
            end
        end
    end

    Log("%s skill failed after %d retries", key, retries)
    return false
end


-- M1 Logic
local M1Running = false
local M1Thread = nil

local function FireM1()
    local mammoth = GetEquippedFruit()
    local remote = mammoth and mammoth:FindFirstChild("LeftClickRemote")
    if not remote then return false end
    return pcall(function()
        remote:FireServer(VOID_VECTOR)
    end)
end

local function StartM1Loop()
    if M1Running then return end
    M1Running = true

    M1Thread = task.spawn(function()
        while M1Running do
            task.wait(CFG.M1Interval)

            local char = GetChar()
            if not char then
                task.wait(0.5)
                continue
            end

            -- re-equip if the fruit was dropped
            local mammoth = GetEquippedFruit()
            if not mammoth then
                pcall(EquipFruit)
                task.wait(0.3)
                continue
            end
            if not mammoth:FindFirstChild("LeftClickRemote") then
                task.wait(0.3)
                continue
            end

            FireM1()
        end
    end)
end

local function StopM1Loop()
    M1Running = false
    M1Thread = nil
end

-- Auto Join PirateTeam
local function selectFaction(faction)
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        local activity = remotes:FindFirstChild("RE/OnEventServiceActivity")
        local commF    = remotes:FindFirstChild("CommF_")
        if activity then activity:FireServer("TeamSelect/Team/" .. faction) end
        task.wait(0.05)
        if commF then commF:InvokeServer("SetTeam", faction) end
    end)
end

local function IsPirate()
    return LocalPlayer.Team and LocalPlayer.Team.Name == "Pirates"
end

local function JoinPirates()
    local elapsed = 0
    while elapsed < 30 do
        if IsPirate() then break end
        selectFaction("Pirates")
        task.wait(0.5)
        elapsed += 0.5
    end
end

local PirateWatcherStarted = false
local function StartAutoPirates()
    if not CFG.AutoTeam or PirateWatcherStarted then return end
    PirateWatcherStarted = true

    task.spawn(JoinPirates)

    -- Team Check Logic
    task.spawn(function()
        local lastTeam = LocalPlayer.Team
        while true do
            task.wait(1)
            if LocalPlayer.Team ~= lastTeam then
                lastTeam = LocalPlayer.Team
                if not IsPirate() then JoinPirates() end
            end
        end
    end)
end

-- Server Hop
local QUEUE_GUARD_KEY = "MAMMOTH_FLY_AUTOEXEC_JOB"
local AutoExecArmed = false
local AutoExecWarned = false
local AutoExecQueuedFor = nil

local function GetQueueOnTeleport()
    local env = getgenv and getgenv() or _G
    local fn = env and rawget(env, "queue_on_teleport")
    if type(fn) ~= "function" then
        fn = env and rawget(env, "queueonteleport")
    end
    if type(fn) ~= "function" and syn then fn = syn.queue_on_teleport end
    if type(fn) ~= "function" and fluxus then fn = fluxus.queue_on_teleport end
    return type(fn) == "function" and fn or nil
end

-- Get 
local function GetHopSource()
    if src and src:find("%S") then
        return src
    end

    local fname = CFG.AutoExecFile
    if isfile and readfile then
        local ok, data = pcall(function()
            if isfile(fname) then return readfile(fname) end
            return nil
        end)
        if ok and type(data) == "string" and data:find("%S") then
            return data
        end
    end
    return nil
end

-- Prevent Duplication 
local function BuildPayload(code)
    return table.concat({
        "-- Mammoth auto-exec payload",
        "task.spawn(function()",
        "    repeat task.wait(1) until game:IsLoaded()",
        "    task.wait(2)",
        string.format("    if getgenv().%s == game.JobId then return end", QUEUE_GUARD_KEY),
        string.format("    getgenv().%s = game.JobId", QUEUE_GUARD_KEY),
        "    local src = [==[",
        code,
        "]==]",
        "    local ok, err = pcall(function() loadstring(src)() end)",
        "end)",
        SRC_TERMINATOR,
    }, "\n")
end

local function SetupAutoExec()
    if not CFG.AutoExec then return false end
    if AutoExecQueuedFor == game.JobId then return true end

    local queueFn = GetQueueOnTeleport()
    if not queueFn then
        if not AutoExecWarned then
            AutoExecWarned = true
        end
        return false
    end

    local code = GetHopSource()
    if not code then
        if not AutoExecWarned then
            AutoExecWarned = true
        end
        return false
    end

    -- Write
    if writefile then
        pcall(function()
            if makefolder and isfolder and not isfolder("mammoth") then
                makefolder("mammoth")
            end
            writefile("mammoth/src.lua", code)
        end)
    end

    local ok = pcall(queueFn, BuildPayload(code))
    if ok then
        AutoExecArmed = true
        AutoExecQueuedFor = game.JobId
    end
    return ok
end

-- Auto V3/V4
local function TurnOnV3()
    local char = GetChar()
    if not char then return false end

    -- Transform Check
    local transformed = char:FindFirstChild("RaceTransformed")
    if transformed and transformed.Value then return false end

    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local commE = remotes and remotes:FindFirstChild("CommE")
    if not commE then return false end

    return pcall(function() commE:FireServer("ActivateAbility") end)
end

-- Smart V4
local function TurnOnV4()
    local char = GetChar()
    if not char then return false end

    local energy      = char:FindFirstChild("RaceEnergy")
    local transformed = char:FindFirstChild("RaceTransformed")
    -- Skip
    if not energy or tonumber(energy.Value) == nil or energy.Value < 1 then return false end
    if not transformed or transformed.Value then return false end

    local awakening = char:FindFirstChild("Awakening")
    if not awakening then
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        awakening = backpack and backpack:FindFirstChild("Awakening")
    end
    if not awakening then return false end

    local remote = awakening:FindFirstChild("RemoteFunction")
    if not remote then return false end

    local ok = pcall(function() remote:InvokeServer(true) end)
    if not ok then
        -- Table
        ok = pcall(function() remote:InvokeServer({ true }) end)
    end
    return ok
end

local AbilityLoopStarted = false

local function StartAbilityLoop()
    if AbilityLoopStarted then return end
    AbilityLoopStarted = true

    task.spawn(function()
        while true do
            task.wait(CFG.V3Interval)
            if CFG.AutoV3 then
                pcall(TurnOnV3)
            end
        end
    end)

    task.spawn(function()
        while true do
            task.wait(CFG.V4Interval)
            if CFG.AutoV4 then
                pcall(TurnOnV4)
            end
        end
    end)
end

-- Server Hop Logic
local ServerBrowser = SafeWait(ReplicatedStorage, "__ServerBrowser", 20)
local browser = ServerBrowser
local _place = game.PlaceId
local _id = game.JobId
local _isHopping = false
local _lastHopTime = 0
local HOP_COOLDOWN = 8
local Hopping = false

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
                if CFG.MinPlayers and count < CFG.MinPlayers then ok2 = false end
                if CFG.MaxPlayers and count > CFG.MaxPlayers then ok2 = false end
                if CFG.ServerRegion and CFG.ServerRegion ~= "" then
                    if not string.find(string.lower(info.Region or ""), string.lower(CFG.ServerRegion), 1, true) then ok2 = false end
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
                if CFG.MinPlayers and sv.playing < CFG.MinPlayers then ok2 = false end
                if CFG.MaxPlayers and sv.playing > CFG.MaxPlayers then ok2 = false end
                if ok2 then table.insert(matched, entry) end
            end
        end
    end

    if #matched == 0 then
        if not CFG.HopFallbackAny or #anyValid == 0 then _isHopping = false; return false end
        matched = anyValid
    end
    table.sort(matched, function(a,b) return a.count > b.count end)
    local chosen = matched[math.random(1, math.min(10, #matched))]

    local ok
    if browser then
        ok = pcall(function() browser:InvokeServer("teleport", chosen.uuid) end)
    else
        ok = pcall(function() TeleportService:TeleportToPlaceInstance(_place, chosen.uuid, LocalPlayer) end)
    end
    if not ok then _isHopping = false; _lastHopTime = os.clock() - HOP_COOLDOWN + 3 end
    return ok
end

-- Retry Hop
local function DoServerHop()
    if Hopping then return false end
    Hopping = true


    local attempt = 0
    while true do
        attempt += 1
        local ok = Hop()
        if ok then

            -- Stop
            StopM1Loop()
            StopNoclip()
            StopFly()

            -- New Server Logic
            pcall(SetupAutoExec)

            task.wait(15)
        else
            task.wait(4)
        end
    end
end

-- Auto Chat
local ChatStarted = false

local function SendChat(msg)
    pcall(function()
        local TCS = game:GetService("TextChatService")
        if TCS.ChatVersion == Enum.ChatVersion.TextChatService then
            TCS.TextChannels.RBXGeneral:SendAsync(msg)
        else
            ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All")
        end
    end)
end

local function StartChatLoop()
    if not CFG.ChatEnabled or ChatStarted then return end
    ChatStarted = true
    task.spawn(function()
        while task.wait(1) do
            for _, msg in ipairs(CFG.ChatMessages) do
                if not CFG.ChatEnabled then break end
                SendChat(msg)
                task.wait(CFG.ChatDelay or 30)
            end
        end
    end)
end

-- Main Flow
local Initialized = false
local HopLoopStarted = false

local function RunOnce()
    RunId = RunId + 1
    local myId = RunId
    SkillCasted = false

    local char = GetChar()
    if not char then
        local ok = pcall(function()
            char = LocalPlayer.CharacterAdded:Wait()
        end)
        if not ok or not char then return end
    end

    -- 0)
    if not HopLoopStarted then
        HopLoopStarted = true
        task.spawn(function()
            while true do
                task.wait(CFG.HopInterval)
                DoServerHop()
            end
        end)
    end

    -- 1)
    if CFG.AutoTeam then
        local t = 0
        while not IsPirate() and t < 30 do
            task.wait(0.1); t = t + 0.1
            if myId ~= RunId then return end
        end
    end

    -- Wait
    local waited = 0
    while waited < 15 do
        local hum = GetHum()
        if GetHRP() and hum and hum.Health > 0 then break end
        task.wait(0.1); waited = waited + 0.1
        if myId ~= RunId then return end
    end

    -- 2)
    CastSkill(myId)
    if myId ~= RunId then return end

    pcall(EquipFruit)

    -- 3)
    StartFly()

    -- 4)
    if CFG.Noclip then
        StartNoclip()
    end

    -- 5)
    StartM1Loop()

    -- 6)
    StartAbilityLoop()
end

local function Init()
    if Initialized then return end
    Initialized = true

    -- Run
    local env = getgenv and getgenv() or _G
    if env then
        if env.__MAMMOTH_FLY_RUNNING == game.JobId then
            return
        end
        env.__MAMMOTH_FLY_RUNNING = game.JobId
    end

    SetupAutoExec()

    -- Auto Start
    StartAutoPirates()
    StartChatLoop()

    RunOnce()
end

-- After Respawn 
LocalPlayer.CharacterAdded:Connect(function()
    if not Initialized then return end
    StopNoclip()
    StopFly()
    StopM1Loop()
    task.wait(2)
    task.spawn(RunOnce)
end)

Init()
