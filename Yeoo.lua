--[[
    YEO HUB - FAST ATTACK SIN PAUSA (ATAQUE RÁPIDO) + BYPASS TP
]]

local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")
local lighting = game:GetService("Lighting")
local camera = workspace.CurrentCamera
local VirtualInputManager = game:GetService("VirtualInputManager")

local lp = players.LocalPlayer

-- ==================== VARIABLES ====================
local hitboxEnabled = false
local zoomActive = false
local iJ = false
local ncl = false
local walkWaterEnabled = false
local antiLavaActive = false
local dayFogActive = false
local dayFogConnection = nil
local v4AutoEnabled = false
local deleteShipActive = false

local FruitAuraEnabled = false
local AttackRange = 899999
local V4Connection = nil

local noAnimationActive = false
local noAnimationConnection = nil

local speedEnabled = false
local currentSpeed = 100
local superJumpEnabled = false
local currentJumpPower = 100

local dashLengthEnabled = false
local dashLengthValue = 5
local dashLengthLoop = nil

local tweenToPlayerEnabled = false
local selectedTarget = nil
local activeTween = nil
local tweenConnection = nil

local spectateEnabled = false
local spectateTarget = nil
local originalCameraSubject = nil
local spectateConnection = nil

local antiKickEnabled = false
local antiKickConnection = nil

local bypassTPEnabled = false

-- Silent Aim
local SilentAimPlayers = false
local SilentAimPlayerTarget = nil
local SilentAimPlayerTargetPos = nil
local SilentAimPlayerMaxDist = 5000

local SilentAimNPC = false
local SilentAimNPCTarget = nil
local SilentAimNPCTargetPos = nil
local SilentAimNPCMaxDist = 2000

local SilentAimAllies = {}

-- No CD
local noCDEnabled = false
local CommF = replicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
local permanentFruits = {}

-- Fast Attack (sin pausa, ataque por frame)
local FastAttackEnabled = false
local FastAttackRange = 5000
local Net = replicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
local RegisterHit = Net["RE/RegisterHit"]
local RegisterAttack = Net["RE/RegisterAttack"]
local FastAttackConnection = nil

-- ==================== FUNCIONES ====================
local function isSilentAimAlly(player)
    if SilentAimAllies[player.Name] then return true end
    if lp.Team and player.Team and lp.Team == player.Team then return true end
    return false
end

local function getAllNPCs()
    local npcs = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            if obj == lp.Character then continue end
            if not players:GetPlayerFromCharacter(obj) then
                table.insert(npcs, obj)
            end
        end
    end
    return npcs
end

-- ==================== SILENT AIM HOOK ====================
spawn(function()
    local mt = getrawmetatable(game)
    if not mt then return end
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(...)
        local method = getnamecallmethod()
        local args = {...}
        if tostring(method) ~= "FireServer" or tostring(args[1]) ~= "RemoteEvent" then
            return oldNamecall(...)
        end
        local targetPos = nil
        if SilentAimPlayers and SilentAimPlayerTargetPos then
            targetPos = SilentAimPlayerTargetPos
        elseif SilentAimNPC and SilentAimNPCTargetPos then
            targetPos = SilentAimNPCTargetPos
        end
        if targetPos then
            if type(args[2]) ~= "vector" and type(args[2]) ~= "CFrame" then
                if type(args[1]) == "CFrame" then args[1] = CFrame.new(targetPos)
                elseif type(args[1]) == "Vector3" then args[1] = targetPos end
            else
                if type(args[2]) == "CFrame" then args[2] = CFrame.new(targetPos)
                else args[2] = targetPos end
            end
            return oldNamecall(unpack(args))
        end
        return oldNamecall(...)
    end)
end)

-- ==================== LOOPS SILENT AIM ====================
task.spawn(function()
    while task.wait(0.15) do
        if SilentAimPlayers then
            local myChar = lp.Character
            if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                local myHrp = myChar.HumanoidRootPart
                local bestDist = math.huge
                local bestName, bestPos = nil, nil
                for _, p in pairs(players:GetPlayers()) do
                    if p ~= lp and not isSilentAimAlly(p) then
                        local char = p.Character
                        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                            local dist = (char.HumanoidRootPart.Position - myHrp.Position).Magnitude
                            if dist < bestDist and dist <= SilentAimPlayerMaxDist then
                                bestDist = dist
                                bestName = p.Name
                                bestPos = char.HumanoidRootPart.Position
                            end
                        end
                    end
                end
                SilentAimPlayerTarget = bestName
                SilentAimPlayerTargetPos = bestPos
            end
        else
            SilentAimPlayerTarget = nil
            SilentAimPlayerTargetPos = nil
        end
    end
end)

task.spawn(function()
    while task.wait(0.15) do
        if SilentAimNPC then
            local myChar = lp.Character
            if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                local myHrp = myChar.HumanoidRootPart
                local bestDist = math.huge
                local bestNPC, bestPos = nil, nil
                for _, npc in ipairs(getAllNPCs()) do
                    local hrp = npc:FindFirstChild("HumanoidRootPart")
                    local hum = npc:FindFirstChild("Humanoid")
                    if hrp and hum and hum.Health > 0 then
                        local dist = (hrp.Position - myHrp.Position).Magnitude
                        if dist < bestDist and dist <= SilentAimNPCMaxDist then
                            bestDist = dist
                            bestNPC = npc
                            bestPos = hrp.Position
                        end
                    end
                end
                if bestNPC then
                    SilentAimNPCTarget = bestNPC.Name
                    SilentAimNPCTargetPos = bestPos
                else
                    SilentAimNPCTarget = nil
                    SilentAimNPCTargetPos = nil
                end
            end
        else
            SilentAimNPCTarget = nil
            SilentAimNPCTargetPos = nil
        end
    end
end)

task.spawn(function()
    while task.wait(0.15) do
        if SilentAimPlayers and SilentAimPlayerTarget then
            for _, p in pairs(players:GetPlayers()) do
                if p.Name == SilentAimPlayerTarget and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    SilentAimPlayerTargetPos = p.Character.HumanoidRootPart.Position
                    break
                end
            end
        end
        if SilentAimNPC and SilentAimNPCTarget then
            for _, npc in ipairs(getAllNPCs()) do
                if npc.Name == SilentAimNPCTarget and npc:FindFirstChild("HumanoidRootPart") then
                    SilentAimNPCTargetPos = npc.HumanoidRootPart.Position
                    break
                end
            end
        end
    end
end)

local function onCharacterDied()
    local wasPlayers = SilentAimPlayers
    local wasNPC = SilentAimNPC
    SilentAimPlayers = false
    SilentAimNPC = false
    SilentAimPlayerTarget = nil
    SilentAimPlayerTargetPos = nil
    SilentAimNPCTarget = nil
    SilentAimNPCTargetPos = nil
    task.wait(3)
    if wasPlayers then SilentAimPlayers = true end
    if wasNPC then SilentAimNPC = true end
end
lp.CharacterAdded:Connect(function(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.Died:Connect(onCharacterDied) end
end)
if lp.Character and lp.Character:FindFirstChildOfClass("Humanoid") then
    lp.Character:FindFirstChildOfClass("Humanoid").Died:Connect(onCharacterDied)
end

-- ==================== INF NIGGA ====================
local headlockExecuting = false
local function RunHeadLockVoid()
    if headlockExecuting then return end
    headlockExecuting = true
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local head = char and char:FindFirstChild("Head")
    local torso = char and (char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
    if hrp and head and torso then
        local oldPos = hrp.CFrame
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Z, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Z, false, game)
        local partsToAnchor = {hrp, head, torso}
        for _, p in ipairs(partsToAnchor) do p.Anchored = true end
        local voidCF = CFrame.new(923.2, 8e30, 32852.8)
        hrp.CFrame = voidCF
        torso.CFrame = voidCF
        task.wait(0.55)
        hrp.CFrame = oldPos
        torso.CFrame = oldPos
        task.wait(0.05)
        for _, p in ipairs(partsToAnchor) do p.Anchored = false end
    end
    headlockExecuting = false
end

-- ==================== NO CD + FILTRO NOTIFICACIONES ====================
local function isInCombat()
    local gui = lp:FindFirstChild("PlayerGui")
    if not gui then return false end
    local main = gui:FindFirstChild("Main")
    if not main then return false end
    local hud = main:FindFirstChild("BottomHUDList")
    if not hud then return false end
    local combat = hud:FindFirstChild("InCombat")
    return combat and combat.Visible == true
end

task.spawn(function()
    while task.wait(10) do
        pcall(function()
            local result = CommF:InvokeServer("GetFruits", false)
            permanentFruits = {}
            if type(result) == "table" then
                for _, fruit in pairs(result) do
                    if fruit.HasPermanent then table.insert(permanentFruits, fruit.Name) end
                end
            end
        end)
    end
end)

local noCDDebounce = false
local function executeNoCooldown()
    if not noCDEnabled or noCDDebounce then return end
    noCDDebounce = true
    pcall(function()
        local char = lp.Character
        if not char then return end
        for _, item in pairs(char:GetChildren()) do
            if item:IsA("Tool") and (item.ToolTip == "Sword" or item.ToolTip == "Gun" or item.ToolTip == "Blox Fruit") then
                task.wait(0.01)
                if item.ToolTip == "Blox Fruit" and not table.find(permanentFruits, item.Name) then return end
                local backpackGui = lp.PlayerGui:FindFirstChild("Backpack")
                if backpackGui then backpackGui.Enabled = false end
                char:SetAttribute("AllCooldown", 0.1)
                local result
                repeat
                    task.wait()
                    result = CommF:InvokeServer(item.ToolTip == "Blox Fruit" and "SwitchFruit" or "LoadItem", item.Name)
                until result == true or isInCombat()
                if isInCombat() then
                    char:SetAttribute("AllCooldown", 0.1)
                    local start = tick()
                    repeat task.wait(0.2) until not isInCombat() or tick() - start > 15
                end
                char:SetAttribute("AllCooldown", 3)
                if backpackGui then backpackGui.Enabled = true end
                local backpackItem = lp.Backpack:FindFirstChild(item.Name)
                if backpackItem then backpackItem.Parent = char end
                break
            end
        end
    end)
    noCDDebounce = false
    if lp.Character then lp.Character:SetAttribute("AllCooldown", 3) end
end

pcall(function()
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        if checkcaller() then return oldNamecall(self, ...) end
        local method = getnamecallmethod()
        if noCDEnabled and method == "InvokeServer" and tostring(self) == "" then
            task.spawn(executeNoCooldown)
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
end)

-- Filtro: solo mostrar notificaciones de muerte
local notifyLoop = nil
local notifyDescendantConn = nil
local function hideNonDeathNotifications()
    if not noCDEnabled then return end
    local playerGui = lp:FindFirstChild("PlayerGui")
    if not playerGui then return end
    local deathKeywords = {"killed", "defeated", "eliminado", "has slain", "victory"}
    for _, gui in pairs(playerGui:GetDescendants()) do
        if gui:IsA("TextLabel") then
            local text = gui.Text and gui.Text:lower() or ""
            local isDeath = false
            for _, kw in ipairs(deathKeywords) do
                if text:find(kw) then isDeath = true; break end
            end
            if not isDeath then
                pcall(function() gui.Visible = false end)
                pcall(function() gui:Destroy() end)
            end
        end
    end
end
local function startNotificationFilter()
    if notifyLoop then return end
    notifyLoop = runService.Heartbeat:Connect(hideNonDeathNotifications)
    if not notifyDescendantConn then
        notifyDescendantConn = lp:WaitForChild("PlayerGui").DescendantAdded:Connect(function()
            if noCDEnabled then task.wait(0.05); hideNonDeathNotifications() end
        end)
    end
end
local function stopNotificationFilter()
    if notifyLoop then notifyLoop:Disconnect(); notifyLoop = nil end
    if notifyDescendantConn then notifyDescendantConn:Disconnect(); notifyDescendantConn = nil end
end

-- ==================== ANTI-KICK ====================
local function setupAntiKick()
    if not antiKickEnabled then
        if antiKickConnection then antiKickConnection:Disconnect() end
        return
    end
    local originalKick = game.Kick
    game.Kick = function(...) if antiKickEnabled then return nil end return originalKick(...) end
    local playerKick = lp.Kick
    lp.Kick = function(...) if antiKickEnabled then return nil end return playerKick(...) end
    if not antiKickConnection then
        antiKickConnection = runService.Stepped:Connect(function()
            pcall(function()
                if antiKickEnabled then
                    local vu = game:GetService("VirtualUser")
                    if vu then
                        vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                        task.wait(0.1)
                        vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                    end
                end
            end)
        end)
    end
end

-- ==================== BYPASS TP INSTANTÁNEO ====================
local function instantTP(targetCFrame)
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if bypassTPEnabled then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local originalPlatform = hum and hum.PlatformStand
        if hum then hum.PlatformStand = true end
        local anchoredParts = {}
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                table.insert(anchoredParts, part)
                part.Anchored = true
            end
        end
        char:PivotTo(targetCFrame)
        hrp.CFrame = targetCFrame
        task.wait(0.05)
        for _, part in pairs(anchoredParts) do part.Anchored = false end
        if hum then hum.PlatformStand = originalPlatform end
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        local startTime = tick()
        local targetPos = targetCFrame.Position
        while tick() - startTime < 0.2 do
            if hrp and hrp.Parent then
                hrp.CFrame = CFrame.new(targetPos) * CFrame.Angles(0, hrp.Orientation.Y, 0)
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
            runService.RenderStepped:Wait()
        end
    else
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.Anchored = true
        task.wait(0.15)
        char:PivotTo(targetCFrame * CFrame.new(0,3,0))
        task.wait(0.1)
        hrp.Anchored = false
        hrp.AssemblyLinearVelocity = Vector3.zero
    end
end

-- ==================== TWEEN TO NIGGA ====================
local function setNoCollide(state)
    pcall(function()
        local char = lp.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = not state end
            end
        end
    end)
end
local function startTweenToPlayer()
    if tweenConnection then tweenConnection:Disconnect() end
    tweenConnection = runService.Heartbeat:Connect(function()
        if not tweenToPlayerEnabled or not selectedTarget then return end
        local target = players:FindFirstChild(selectedTarget)
        if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end
        local myChar = lp.Character
        if not myChar then return end
        local myHRP = myChar:FindFirstChild("HumanoidRootPart")
        local targetHRP = target.Character.HumanoidRootPart
        if myHRP and targetHRP then
            local targetPos = targetHRP.Position
            local dist = (myHRP.Position - targetPos).Magnitude
            if dist > 2 then
                setNoCollide(true)
                local time = dist / 200
                if activeTween then activeTween:Cancel() end
                activeTween = tweenService:Create(myHRP, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos)})
                activeTween:Play()
            end
        end
    end)
end
local function stopTweenToPlayer()
    if tweenConnection then tweenConnection:Disconnect(); tweenConnection = nil end
    if activeTween then activeTween:Cancel(); activeTween = nil end
    setNoCollide(false)
end

-- ==================== SPECTATE ====================
local function startSpectate(player)
    if not player or not player.Character or not player.Character:FindFirstChild("Humanoid") then return end
    originalCameraSubject = camera.CameraSubject
    camera.CameraSubject = player.Character.Humanoid
    if spectateConnection then spectateConnection:Disconnect() end
    spectateConnection = runService.RenderStepped:Connect(function()
        if not spectateEnabled or not spectateTarget then return end
        local target = players:FindFirstChild(spectateTarget)
        if not target or not target.Character or not target.Character:FindFirstChild("Humanoid") then stopSpectate() end
    end)
end
local function stopSpectate()
    if spectateConnection then spectateConnection:Disconnect(); spectateConnection = nil end
    camera.CameraSubject = originalCameraSubject or lp.Character
    spectateEnabled = false
    spectateTarget = nil
end

-- ==================== DÍA Y NIEBLA ====================
local function applyFullDayFog()
    lighting.ClockTime = 14
    lighting.Brightness = 2.2
    lighting.GlobalShadows = true
    lighting.Ambient = Color3.fromRGB(170,170,170)
    lighting.OutdoorAmbient = Color3.fromRGB(170,170,170)
    lighting.ColorShift_Bottom = Color3.fromRGB(0,0,0)
    lighting.ColorShift_Top = Color3.fromRGB(0,0,0)
    lighting.ExposureCompensation = 0.2
    lighting.GeographicLatitude = 41.733
    lighting.FogStart = 999999999
    lighting.FogEnd = 999999999
    if lighting:FindFirstChild("Atmosphere") then
        local atm = lighting.Atmosphere
        atm.Density = 0
        atm.Offset = 0
        atm.Haze = 0
        atm.Glare = 0
    end
    for _, v in pairs(lighting:GetDescendants()) do
        if v:IsA("Atmosphere") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or
           v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("ColorCorrectionEffect") then
            if v:IsA("Atmosphere") then
                v.Density = 0
                v.Haze = 0
            else
                v.Enabled = false
            end
        end
    end
end
local function restoreLighting()
    lighting.ClockTime = 12
    lighting.Brightness = 1
    lighting.Ambient = Color3.fromRGB(127,127,127)
    lighting.OutdoorAmbient = Color3.fromRGB(127,127,127)
    lighting.ExposureCompensation = 0
    lighting.FogStart = 0
    lighting.FogEnd = 100000
    if lighting:FindFirstChild("Atmosphere") then
        local atm = lighting.Atmosphere
        atm.Density = 0.3
        atm.Haze = 2
    end
end

-- ==================== ESP ====================
local ESPEnabled = false
local ESPObjects = {}
local espUpdateConnection = nil
local function CreateESP(targetPlayer)
    local char = targetPlayer.Character
    if not char or not char:FindFirstChild("Head") then return nil end
    local levelValue = "???"
    local dataFolder = targetPlayer:FindFirstChild("Data")
    if dataFolder and dataFolder:FindFirstChild("Level") then levelValue = tostring(dataFolder.Level.Value) end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "YeoESP"
    billboard.Adornee = char:FindFirstChild("Head")
    billboard.Size = UDim2.new(0,150,0,60)
    billboard.StudsOffset = Vector3.new(0,3,0)
    billboard.AlwaysOnTop = true
    billboard.Parent = char:FindFirstChild("Head")
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1,0,1,0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(220,220,220)
    label.TextStrokeTransparency = 0.5
    label.Parent = billboard
    local updateConnection = runService.RenderStepped:Connect(function()
        if not billboard.Parent or not targetPlayer.Character or not lp.Character then
            updateConnection:Disconnect()
            return
        end
        local myChar = lp.Character
        local targetChar = targetPlayer.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        if myHRP and targetHRP then
            local dist = math.floor((targetHRP.Position - myHRP.Position).Magnitude)
            local newLevel = "???"
            local dataFolder2 = targetPlayer:FindFirstChild("Data")
            if dataFolder2 and dataFolder2:FindFirstChild("Level") then newLevel = tostring(dataFolder2.Level.Value) end
            label.Text = targetPlayer.Name .. " [Lvl: " .. newLevel .. "]\n" .. dist .. "m"
        end
    end)
    return billboard, updateConnection
end
local function ClearESP()
    for _, obj in pairs(ESPObjects) do
        if obj.billboard then obj.billboard:Destroy() end
        if obj.updateConn then obj.updateConn:Disconnect() end
    end
    ESPObjects = {}
end
local function UpdateESP()
    if not ESPEnabled then return end
    for i, data in pairs(ESPObjects) do
        local targetPlayer = data.player
        if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("Head") then
            if data.billboard then data.billboard:Destroy() end
            if data.updateConn then data.updateConn:Disconnect() end
            table.remove(ESPObjects, i)
        end
    end
    for _, p in pairs(players:GetPlayers()) do
        if p ~= lp and p.Character and p.Character:FindFirstChild("Head") then
            local alreadyExists = false
            for _, data in pairs(ESPObjects) do
                if data.player == p then alreadyExists = true; break end
            end
            if not alreadyExists then
                local billboard, updateConn = CreateESP(p)
                if billboard then table.insert(ESPObjects, {player = p, billboard = billboard, updateConn = updateConn}) end
            end
        end
    end
end
local function StartESPUpdater()
    if espUpdateConnection then espUpdateConnection:Disconnect() end
    espUpdateConnection = runService.RenderStepped:Connect(function() if ESPEnabled then UpdateESP() end end)
end

-- ==================== FAST ATTACK (SIN PAUSA) ====================
local function StartFastAttack()
    if FastAttackConnection then FastAttackConnection:Disconnect() end
    FastAttackConnection = runService.RenderStepped:Connect(function()
        if not FastAttackEnabled then
            if FastAttackConnection then FastAttackConnection:Disconnect(); FastAttackConnection = nil end
            return
        end
        pcall(function()
            local myChar = lp.Character
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myHRP then return end
            local targets = {}
            for _, player in pairs(players:GetPlayers()) do
                if player ~= lp and player.Character then
                    local hum = player.Character:FindFirstChild("Humanoid")
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if hum and hrp and hum.Health > 0 and (hrp.Position - myHRP.Position).Magnitude <= FastAttackRange then
                        table.insert(targets, player.Character)
                    end
                end
            end
            local enemies = workspace:FindFirstChild("Enemies")
            if enemies then
                for _, npc in pairs(enemies:GetChildren()) do
                    local hum = npc:FindFirstChild("Humanoid")
                    local hrp = npc:FindFirstChild("HumanoidRootPart")
                    if hum and hrp and hum.Health > 0 and (hrp.Position - myHRP.Position).Magnitude <= FastAttackRange then
                        table.insert(targets, npc)
                    end
                end
            end
            if #targets > 0 then
                local allTargets = {}
                for _, char in pairs(targets) do
                    local head = char:FindFirstChild("Head")
                    if head then table.insert(allTargets, {char, head}) end
                end
                if #allTargets > 0 then
                    RegisterAttack:FireServer(0)
                    RegisterHit:FireServer(allTargets[1][2], allTargets)
                    local commF = replicatedStorage:FindFirstChild("Remotes") and replicatedStorage.Remotes:FindFirstChild("CommF_")
                    if commF then commF:InvokeServer("CombatLog", allTargets[1][1]) end
                end
            end
        end)
    end)
end

-- ==================== V4 AUTO ====================
local function StartV4Auto()
    if V4Connection then V4Connection:Disconnect() end
    V4Connection = runService.Heartbeat:Connect(function()
        if not v4AutoEnabled then V4Connection:Disconnect(); V4Connection = nil return end
        pcall(function()
            local char = lp.Character
            if char and char:FindFirstChild("Awakening") then
                char.Awakening.RemoteFunction:InvokeServer(true)
            elseif lp.Backpack:FindFirstChild("Awakening") then
                lp.Backpack.Awakening.RemoteFunction:InvokeServer(true)
            end
        end)
    end)
end

-- ==================== FRUIT AURA ====================
local function StartFruitAura()
    task.spawn(function()
        while FruitAuraEnabled do
            task.wait(0.15)
            pcall(function()
                local char = lp.Character
                if not char then return end
                local myHRP = char:FindFirstChild("HumanoidRootPart")
                if not myHRP then return end
                local bestTarget = nil
                local bestDistance = math.huge
                for _, player in pairs(players:GetPlayers()) do
                    if player ~= lp and player.Character then
                        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
                        local hum = player.Character:FindFirstChild("Humanoid")
                        if targetHRP and hum and hum.Health > 0 then
                            local dist = (targetHRP.Position - myHRP.Position).Magnitude
                            if dist < bestDistance and dist <= AttackRange then
                                bestDistance = dist
                                bestTarget = player.Character
                            end
                        end
                    end
                end
                if not bestTarget then
                    local enemies = workspace:FindFirstChild("Enemies")
                    if enemies then
                        for _, npc in pairs(enemies:GetChildren()) do
                            local targetHRP = npc:FindFirstChild("HumanoidRootPart")
                            local hum = npc:FindFirstChild("Humanoid")
                            if targetHRP and hum and hum.Health > 0 then
                                local dist = (targetHRP.Position - myHRP.Position).Magnitude
                                if dist < bestDistance and dist <= AttackRange then
                                    bestDistance = dist
                                    bestTarget = npc
                                end
                            end
                        end
                    end
                end
                if bestTarget then
                    local targetHead = bestTarget:FindFirstChild("Head")
                    if targetHead then
                        local targets = { {bestTarget, targetHead} }
                        RegisterAttack:FireServer(0)
                        RegisterHit:FireServer(targetHead, targets)
                        local commF = replicatedStorage:FindFirstChild("Remotes") and replicatedStorage.Remotes:FindFirstChild("CommF_")
                        if commF then commF:InvokeServer("CombatLog", bestTarget) end
                    end
                end
            end)
        end
    end)
end

-- ==================== NO ANIMATION ====================
local function setupNoAnimation()
    if noAnimationConnection then noAnimationConnection:Disconnect() end
    noAnimationConnection = runService.RenderStepped:Connect(function()
        local char = lp.Character
        if not char or not noAnimationActive then return end
        local hum = char:FindFirstChild("Humanoid")
        if hum then for _, track in pairs(hum:GetPlayingAnimationTracks()) do track:Stop() end end
    end)
    local function onCharacterAdded(character)
        local hum = character:WaitForChild("Humanoid")
        hum.AnimationPlayed:Connect(function(animationTrack) if noAnimationActive then animationTrack:Stop() end end)
    end
    if lp.Character then onCharacterAdded(lp.Character) end
    lp.CharacterAdded:Connect(onCharacterAdded)
end

-- ==================== MOVIMIENTO ====================
local function applySpeed()
    if speedEnabled and lp.Character and lp.Character:FindFirstChild("Humanoid") then
        local hum = lp.Character.Humanoid
        if hum.MoveDirection.Magnitude > 0 and currentSpeed > 0 then
            lp.Character:TranslateBy(hum.MoveDirection * (currentSpeed / 55))
        end
    end
end
runService.Heartbeat:Connect(applySpeed)

local function doSuperJump()
    if superJumpEnabled and currentJumpPower > 0 and lp.Character and lp.Character:FindFirstChild("Humanoid") then
        local hum = lp.Character.Humanoid
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
        local hrp = lp.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, currentJumpPower, hrp.AssemblyLinearVelocity.Z) end
        return true
    end
    return false
end
userInputService.JumpRequest:Connect(function()
    if doSuperJump() then return end
    if iJ and lp.Character and lp.Character:FindFirstChild("Humanoid") then lp.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- ==================== DASH LENGTH ====================
local function applyDashLength()
    if not dashLengthEnabled then return end
    local char = lp.Character
    if not char then return end
    local valueToSet = math.clamp(dashLengthValue, 5, 300)
    if valueToSet ~= dashLengthValue then dashLengthValue = valueToSet end
    char:SetAttribute("DashLength", valueToSet)
    char:SetAttribute("DashLengthAir", valueToSet)
end
local function startDashLengthLoop()
    if dashLengthLoop then task.cancel(dashLengthLoop) end
    dashLengthLoop = task.spawn(function()
        while dashLengthEnabled do
            applyDashLength()
            task.wait(0.2)
        end
    end)
end
local function stopDashLengthLoop()
    if dashLengthLoop then task.cancel(dashLengthLoop); dashLengthLoop = nil end
    if lp.Character then
        lp.Character:SetAttribute("DashLength", 1)
        lp.Character:SetAttribute("DashLengthAir", 1)
    end
end
lp.CharacterAdded:Connect(function(char) if dashLengthEnabled then task.wait(0.5); applyDashLength() end end)

-- ==================== INTERFAZ PRINCIPAL ====================
local pgui = lp:WaitForChild("PlayerGui")
if pgui:FindFirstChild("YeoHub") then pgui.YeoHub:Destroy() end
local screenGui = Instance.new("ScreenGui", pgui)
screenGui.Name = "YeoHub"
screenGui.ResetOnSpawn = false

-- Botón Inf Nigga
local infButton = nil
local function createInfButton()
    if infButton then return end
    infButton = Instance.new("TextButton", screenGui)
    infButton.Name = "InfNiggaBtn"
    infButton.Size = UDim2.new(0, 50, 0, 50)
    infButton.Position = UDim2.new(0, 100, 0.5, 0)
    infButton.BackgroundColor3 = Color3.fromRGB(20,20,30)
    infButton.BackgroundTransparency = 0.2
    infButton.Text = "👾"
    infButton.TextSize = 30
    infButton.Font = Enum.Font.GothamBold
    infButton.TextColor3 = Color3.fromRGB(255,255,255)
    infButton.BorderSizePixel = 0
    Instance.new("UICorner", infButton).CornerRadius = UDim.new(1,0)
    local stroke = Instance.new("UIStroke", infButton)
    stroke.Color = Color3.fromRGB(150,0,255)
    stroke.Thickness = 2
    infButton.Visible = false
    local dragging = false
    local dragStart, startPos
    infButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = infButton.Position
        end
    end)
    userInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            infButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    userInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    infButton.MouseButton1Click:Connect(function() task.spawn(RunHeadLockVoid) end)
end
createInfButton()
local function setInfButtonVisible(visible) if infButton then infButton.Visible = visible end end

-- Marco principal
local mainFrame = Instance.new("Frame", screenGui)
local normalSize, minimizedSize = UDim2.new(0, 420, 0, 400), UDim2.new(0, 150, 0, 35)
mainFrame.Size = normalSize
mainFrame.Position = UDim2.new(0.5, -210, 0.3, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BackgroundTransparency = 0.4
mainFrame.Active = true
mainFrame.Draggable = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)
local mainGradient = Instance.new("UIGradient", mainFrame)
mainGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(40,40,40)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20,20,20))
})
mainGradient.Rotation = 45
local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = Color3.fromRGB(70,70,75)
mainStroke.Thickness = 2
mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- Botón flotante Anti Nigga
local function createFloatBtn(name, text, pos)
    local b = Instance.new("TextButton", screenGui)
    b.Name = name
    b.Size = UDim2.new(0, 130, 0, 35)
    b.Position = pos
    b.BackgroundColor3 = Color3.fromRGB(45,45,45)
    b.Text = text
    b.TextColor3 = Color3.fromRGB(200,200,200)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 10
    b.Visible = false
    b.Active = true
    b.Draggable = true
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    local s = Instance.new("UIStroke", b)
    s.Color = Color3.fromRGB(80,80,80)
    s.Thickness = 1.5
    return b, s
end
local floatAB, strokeAB = createFloatBtn("AntiBuddhaFloat", "ANTI NIGGA: OFF", UDim2.new(0, 20, 0, 20))
local isUpLoopActive = false
floatAB.MouseButton1Click:Connect(function()
    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local flag = hrp:FindFirstChild("UpLoop")
    if flag then
        flag:Destroy()
        isUpLoopActive = false
    else
        isUpLoopActive = true
        flag = Instance.new("BoolValue", hrp)
        flag.Name = "UpLoop"
        task.spawn(function()
            while flag.Parent do
                hrp.CFrame = hrp.CFrame * CFrame.new(0, 273861, 0)
                task.wait(0.05)
            end
        end)
    end
    floatAB.Text = isUpLoopActive and "ANTI NIGGA: ON" or "ANTI NIGGA: OFF"
    floatAB.TextColor3 = isUpLoopActive and Color3.fromRGB(255,255,255) or Color3.fromRGB(180,180,180)
    strokeAB.Color = isUpLoopActive and Color3.fromRGB(200,200,200) or Color3.fromRGB(70,70,70)
end)

-- Pestañas
local topBar = Instance.new("Frame", mainFrame)
topBar.Size = UDim2.new(1, 0, 0, 45)
topBar.BackgroundTransparency = 1
local titleLabel = Instance.new("TextLabel", topBar)
titleLabel.Size = UDim2.new(0.6, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.Text = "YEO HUB"
titleLabel.TextColor3 = Color3.fromRGB(255,255,255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 18
titleLabel.TextXAlignment = "Left"
titleLabel.BackgroundTransparency = 1
local closeBtn = Instance.new("TextButton", topBar)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -40, 0, 7)
closeBtn.Text = "×"
closeBtn.TextSize = 20
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.BackgroundColor3 = Color3.fromRGB(150,40,40)
Instance.new("UICorner", closeBtn)
local maximizeBtn = Instance.new("TextButton", topBar)
maximizeBtn.Size = UDim2.new(0, 30, 0, 30)
maximizeBtn.Position = UDim2.new(1, -75, 0, 7)
maximizeBtn.Text = "□"
maximizeBtn.TextSize = 18
maximizeBtn.TextColor3 = Color3.new(1,1,1)
maximizeBtn.BackgroundColor3 = Color3.fromRGB(60,60,65)
Instance.new("UICorner", maximizeBtn)
local minimizeBtn = Instance.new("TextButton", topBar)
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -110, 0, 7)
minimizeBtn.Text = "-"
minimizeBtn.TextSize = 22
minimizeBtn.TextColor3 = Color3.new(1,1,1)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(60,60,65)
Instance.new("UICorner", minimizeBtn)

local tabContainer = Instance.new("ScrollingFrame", mainFrame)
tabContainer.Size = UDim2.new(1, -20, 0, 40)
tabContainer.Position = UDim2.new(0, 10, 0, 50)
tabContainer.BackgroundTransparency = 1
tabContainer.ScrollBarThickness = 0
tabContainer.CanvasSize = UDim2.new(0,0,0,0)
tabContainer.ScrollingDirection = Enum.ScrollingDirection.X
tabContainer.AutomaticCanvasSize = Enum.AutomaticSize.X
local tabList = Instance.new("UIListLayout", tabContainer)
tabList.FillDirection = Enum.FillDirection.Horizontal
tabList.Padding = UDim.new(0, 8)

local contentFrame = Instance.new("Frame", mainFrame)
contentFrame.Size = UDim2.new(1, -20, 1, -110)
contentFrame.Position = UDim2.new(0, 10, 0, 100)
contentFrame.BackgroundTransparency = 1

local function createPage(name)
    local p = Instance.new("ScrollingFrame", contentFrame)
    p.Name = name
    p.Size = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.Visible = false
    p.ScrollBarThickness = 3
    p.ScrollBarImageColor3 = Color3.fromRGB(100,100,100)
    p.CanvasSize = UDim2.new(0,0,0,650)
    Instance.new("UIListLayout", p).Padding = UDim.new(0, 10)
    p.UIListLayout.HorizontalAlignment = "Center"
    return p
end

local combatPage = createPage("Combate")
local aimPage = createPage("Aim nigga")
local instaTPPage = createPage("Insta TP nigga")
local antiBuddhaPage = createPage("anti buddha")
local movePage = createPage("Movimiento")
local sea2Page = createPage("sea 2 nigga")
local sea3Page = createPage("Sea 3 nigga")
local confiPage = createPage("Confi nigga")

local function showPage(page)
    for _, v in pairs(contentFrame:GetChildren()) do if v:IsA("ScrollingFrame") then v.Visible = false end end
    page.Visible = true
end

local function createTab(name, page)
    local b = Instance.new("TextButton", tabContainer)
    b.Size = UDim2.new(0, 95, 1, 0)
    b.Text = name
    b.BackgroundColor3 = Color3.fromRGB(50,50,55)
    b.TextColor3 = Color3.new(0.9,0.9,0.9)
    b.Font = Enum.Font.Gotham
    b.TextSize = 13
    Instance.new("UICorner", b)
    local s = Instance.new("UIStroke", b)
    s.Color = Color3.fromRGB(80,80,85)
    s.Thickness = 1
    b.MouseButton1Click:Connect(function()
        showPage(page)
        b.BackgroundColor3 = Color3.fromRGB(70,70,75)
        task.wait(0.1)
        b.BackgroundColor3 = Color3.fromRGB(50,50,55)
    end)
end

createTab("Combate", combatPage)
createTab("Aim nigga", aimPage)
createTab("Insta tp nigga", instaTPPage)
createTab("Anti nigga", antiBuddhaPage)
createTab("Mov", movePage)
createTab("Sea 2 nigga", sea2Page)
createTab("Sea 3 nigga", sea3Page)
createTab("Confi nigga", confiPage)
showPage(combatPage)

-- Funciones UI
local function addBtn(txt, parent)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0.95, 0, 0, 42)
    btn.BackgroundColor3 = Color3.fromRGB(45,45,50)
    btn.Text = txt
    btn.TextColor3 = Color3.fromRGB(200,200,200)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    Instance.new("UICorner", btn)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(75,75,80)
    stroke.Thickness = 1.2
    return btn, stroke
end

local function updateBtnState(btn, stroke, on)
    local targetColor = on and Color3.fromRGB(75,75,85) or Color3.fromRGB(45,45,50)
    local targetStroke = on and Color3.fromRGB(200,200,200) or Color3.fromRGB(75,75,80)
    tweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = targetColor}):Play()
    tweenService:Create(stroke, TweenInfo.new(0.3), {Color = targetStroke}):Play()
    btn.TextColor3 = on and Color3.fromRGB(255,255,255) or Color3.fromRGB(200,200,200)
end

local function addSwitch(txt, parent, callback)
    local bubble = Instance.new("Frame", parent)
    bubble.Size = UDim2.new(0.95, 0, 0, 48)
    bubble.BackgroundColor3 = Color3.fromRGB(35,35,40)
    bubble.BorderSizePixel = 0
    Instance.new("UICorner", bubble).CornerRadius = UDim.new(0,10)
    local bStroke = Instance.new("UIStroke", bubble)
    bStroke.Color = Color3.fromRGB(60,60,65)
    bStroke.Thickness = 1
    local label = Instance.new("TextLabel", bubble)
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0,15,0,0)
    label.BackgroundTransparency = 1
    label.Text = txt
    label.TextColor3 = Color3.fromRGB(230,230,230)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    local switchBg = Instance.new("TextButton", bubble)
    switchBg.Size = UDim2.new(0,48,0,24)
    switchBg.Position = UDim2.new(1,-65,0.5,-12)
    switchBg.BackgroundColor3 = Color3.fromRGB(60,60,65)
    switchBg.Text = ""
    Instance.new("UICorner", switchBg).CornerRadius = UDim.new(1,0)
    local slider = Instance.new("Frame", switchBg)
    slider.Size = UDim2.new(0,20,0,20)
    slider.Position = UDim2.new(0,2,0.5,-10)
    slider.BackgroundColor3 = Color3.fromRGB(200,200,200)
    Instance.new("UICorner", slider).CornerRadius = UDim.new(1,0)
    local state = false
    local function updateVisuals(on)
        local tInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        tweenService:Create(slider, tInfo, {Position = on and UDim2.new(1,-22,0.5,-10) or UDim2.new(0,2,0.5,-10)}):Play()
        tweenService:Create(switchBg, tInfo, {BackgroundColor3 = on and Color3.fromRGB(0,210,255) or Color3.fromRGB(60,60,65)}):Play()
    end
    switchBg.MouseButton1Click:Connect(function()
        state = not state
        updateVisuals(state)
        if callback then callback(state) end
    end)
    return bubble
end

local function addNumberControl(parent, labelText, minVal, maxVal, defaultValue, step, callback)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(0.95, 0, 0, 48)
    container.BackgroundColor3 = Color3.fromRGB(35,35,40)
    container.BorderSizePixel = 0
    Instance.new("UICorner", container).CornerRadius = UDim.new(0,10)
    local stroke = Instance.new("UIStroke", container)
    stroke.Color = Color3.fromRGB(60,60,65)
    stroke.Thickness = 1
    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Position = UDim2.new(0,10,0,0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(230,230,230)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    local valueLabel = Instance.new("TextLabel", container)
    valueLabel.Size = UDim2.new(0,50,1,0)
    valueLabel.Position = UDim2.new(0.5,0,0,0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(defaultValue)
    valueLabel.TextColor3 = Color3.fromRGB(255,255,255)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 16
    local minusBtn = Instance.new("TextButton", container)
    minusBtn.Size = UDim2.new(0,35,0,35)
    minusBtn.Position = UDim2.new(0.7,0,0.5,-17.5)
    minusBtn.Text = "-"
    minusBtn.BackgroundColor3 = Color3.fromRGB(50,50,60)
    minusBtn.TextColor3 = Color3.new(1,1,1)
    minusBtn.Font = Enum.Font.GothamBold
    minusBtn.TextSize = 20
    Instance.new("UICorner", minusBtn).CornerRadius = UDim.new(0,6)
    local plusBtn = Instance.new("TextButton", container)
    plusBtn.Size = UDim2.new(0,35,0,35)
    plusBtn.Position = UDim2.new(0.8,0,0.5,-17.5)
    plusBtn.Text = "+"
    plusBtn.BackgroundColor3 = Color3.fromRGB(50,50,60)
    plusBtn.TextColor3 = Color3.new(1,1,1)
    plusBtn.Font = Enum.Font.GothamBold
    plusBtn.TextSize = 20
    Instance.new("UICorner", plusBtn).CornerRadius = UDim.new(0,6)
    local current = defaultValue
    local function update()
        valueLabel.Text = tostring(current)
        if callback then callback(current) end
    end
    minusBtn.MouseButton1Click:Connect(function()
        current = math.clamp(current - step, minVal, maxVal)
        update()
    end)
    plusBtn.MouseButton1Click:Connect(function()
        current = math.clamp(current + step, minVal, maxVal)
        update()
    end)
    update()
    return container
end

-- ==================== CONTENIDO DE PESTAÑAS ====================

-- Aim nigga
addSwitch("Aim niggers", aimPage, function(on)
    SilentAimPlayers = on
    if not on then SilentAimPlayerTarget = nil; SilentAimPlayerTargetPos = nil end
end)
addSwitch("Aim NPC", aimPage, function(on)
    SilentAimNPC = on
    if not on then SilentAimNPCTarget = nil; SilentAimNPCTargetPos = nil end
end)

-- Movimiento
for _, child in pairs(movePage:GetChildren()) do if child:IsA("Frame") or child:IsA("TextButton") then child:Destroy() end end
addSwitch("Velocidad", movePage, function(on) speedEnabled = on end)
addNumberControl(movePage, "Velocidad extra", 0, 500, currentSpeed, 100, function(val) currentSpeed = val end)
addSwitch("Súper Jump", movePage, function(on) superJumpEnabled = on end)
addNumberControl(movePage, "Fuerza del salto", 0, 500, currentJumpPower, 100, function(val) currentJumpPower = val end)
addSwitch("Dash Length", movePage, function(on) dashLengthEnabled = on; if on then startDashLengthLoop(); applyDashLength() else stopDashLengthLoop() end end)
addNumberControl(movePage, "Valor del dash", 5, 300, dashLengthValue, 5, function(val) dashLengthValue = val; if dashLengthEnabled then applyDashLength() end end)
addSwitch("Salto Infinito", movePage, function(on) iJ = on end)
addSwitch("No Clip", movePage, function(on) ncl = on end)
addSwitch("Caminar sobre Agua", movePage, function(on) walkWaterEnabled = on end)

-- Combate
local fBtn, fStroke = addBtn("Kill nigga: OFF", combatPage)
fBtn.MouseButton1Click:Connect(function()
    FastAttackEnabled = not FastAttackEnabled
    fBtn.Text = FastAttackEnabled and "Kill nigga: ON" or "Kill nigga: OFF"
    updateBtnState(fBtn, fStroke, FastAttackEnabled)
    if FastAttackEnabled then StartFastAttack() end
end)

local hBtn, hStroke = addBtn("Hitbox: OFF", combatPage)
task.spawn(function()
    local success, CombatUtil = pcall(function() return require(replicatedStorage.Modules.CombatUtil) end)
    if success and CombatUtil then
        local original = CombatUtil.GetWeaponData
        CombatUtil.GetWeaponData = function(self, name, ...)
            local data = original(self, name, ...)
            if type(data) == 'table' then data.HitboxMagnitude = hitboxEnabled and 250 or 4 end
            return data
        end
    end
end)
hBtn.MouseButton1Click:Connect(function()
    hitboxEnabled = not hitboxEnabled
    hBtn.Text = hitboxEnabled and "Hitbox: ON" or "Hitbox: OFF"
    updateBtnState(hBtn, hStroke, hitboxEnabled)
end)

local frBtn, frStroke = addBtn("Fruit Aura nigga: OFF", combatPage)
frBtn.MouseButton1Click:Connect(function()
    FruitAuraEnabled = not FruitAuraEnabled
    frBtn.Text = FruitAuraEnabled and "Fruit Aura nigga: ON" or "Fruit Aura nigga: OFF"
    updateBtnState(frBtn, frStroke, FruitAuraEnabled)
    if FruitAuraEnabled then StartFruitAura() end
end)

local espBtn, espStroke = addBtn("ESP NIGGA: OFF", combatPage)
espBtn.MouseButton1Click:Connect(function()
    ESPEnabled = not ESPEnabled
    espBtn.Text = ESPEnabled and "ESP NIGGA: ON" or "ESP NIGGA: OFF"
    updateBtnState(espBtn, espStroke, ESPEnabled)
    if ESPEnabled then StartESPUpdater(); UpdateESP() elseif espUpdateConnection then espUpdateConnection:Disconnect(); ClearESP() end
end)

-- Anti nigga
local abBtn, abStroke = addBtn("Anti Nigga: OFF", antiBuddhaPage)
abBtn.MouseButton1Click:Connect(function()
    floatAB.Visible = not floatAB.Visible
    abBtn.Text = floatAB.Visible and "Anti nigga: ON" or "Anti nigga: OFF"
    updateBtnState(abBtn, abStroke, floatAB.Visible)
end)
addSwitch("Auto v4", antiBuddhaPage, function(on) v4AutoEnabled = on; if on then StartV4Auto() end end)
addSwitch("Inf nigga", antiBuddhaPage, function(on) setInfButtonVisible(on) end)

-- Insta TP + Tween + Spectate
local function createInstaTPMenu(parent)
    local dropdown = Instance.new("TextButton", parent)
    dropdown.Size = UDim2.new(0.9, 0, 0, 38)
    dropdown.BackgroundColor3 = Color3.fromRGB(35,35,40)
    dropdown.Text = "Select a nigger ▼"
    dropdown.TextColor3 = Color3.fromRGB(200,200,205)
    dropdown.Font = Enum.Font.Gotham
    dropdown.TextSize = 14
    Instance.new("UICorner", dropdown)
    local refreshBtn = Instance.new("TextButton", parent)
    refreshBtn.Size = UDim2.new(0.9, 0, 0, 38)
    refreshBtn.BackgroundColor3 = Color3.fromRGB(40,40,45)
    refreshBtn.Text = "⟳ REFRESH NIGGERS"
    refreshBtn.TextColor3 = Color3.fromRGB(200,200,205)
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.TextSize = 12
    Instance.new("UICorner", refreshBtn)
    local playerList = Instance.new("ScrollingFrame", parent)
    playerList.Size = UDim2.new(0.9, 0, 0, 130)
    playerList.BackgroundColor3 = Color3.fromRGB(25,25,28)
    playerList.Visible = false
    playerList.ScrollBarThickness = 4
    Instance.new("UICorner", playerList)
    Instance.new("UIListLayout", playerList).Padding = UDim.new(0,5)
    local instaBtn, instaStroke = addBtn("Insta tp to nigga: OFF", parent)
    local tweenBtn, tweenStroke = addBtn("Tween to nigga: OFF", parent)
    local spectateBtn, spectateStroke = addBtn("Spectate nigga: OFF", parent)
    local targetPlayer = nil
    local isInstaTP = false
    local function refreshPlayerList()
        for _, v in pairs(playerList:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
        for _, p in pairs(players:GetPlayers()) do
            if p ~= lp then
                local btn = Instance.new("TextButton", playerList)
                btn.Size = UDim2.new(1, -10, 0, 32)
                btn.BackgroundColor3 = Color3.fromRGB(40,40,45)
                btn.Text = p.Name
                btn.TextColor3 = Color3.fromRGB(200,200,205)
                btn.Font = Enum.Font.Gotham
                btn.TextSize = 12
                Instance.new("UICorner", btn)
                btn.MouseButton1Click:Connect(function()
                    targetPlayer = p
                    dropdown.Text = p.Name .. " ▼"
                    playerList.Visible = false
                    selectedTarget = p.Name
                    if spectateEnabled then
                        stopSpectate()
                        spectateEnabled = true
                        spectateTarget = p.Name
                        startSpectate(p)
                    end
                end)
            end
        end
    end
    dropdown.MouseButton1Click:Connect(function() playerList.Visible = not playerList.Visible; if playerList.Visible then refreshPlayerList() end end)
    refreshBtn.MouseButton1Click:Connect(refreshPlayerList)
    instaBtn.MouseButton1Click:Connect(function()
        if tweenToPlayerEnabled then
            tweenToPlayerEnabled = false
            tweenBtn.Text = "Tween to nigga: OFF"
            updateBtnState(tweenBtn, tweenStroke, false)
            stopTweenToPlayer()
        end
        if spectateEnabled then
            stopSpectate()
            spectateBtn.Text = "Spectate nigga: OFF"
            updateBtnState(spectateBtn, spectateStroke, false)
        end
        isInstaTP = not isInstaTP
        instaBtn.Text = isInstaTP and "Insta tp to nigga: ON" or "Insta tp to nigga: OFF"
        updateBtnState(instaBtn, instaStroke, isInstaTP)
    end)
    tweenBtn.MouseButton1Click:Connect(function()
        if isInstaTP then
            isInstaTP = false
            instaBtn.Text = "Insta tp to nigga: OFF"
            updateBtnState(instaBtn, instaStroke, false)
        end
        if spectateEnabled then
            stopSpectate()
            spectateBtn.Text = "Spectate nigga: OFF"
            updateBtnState(spectateBtn, spectateStroke, false)
        end
        tweenToPlayerEnabled = not tweenToPlayerEnabled
        tweenBtn.Text = tweenToPlayerEnabled and "Tween to nigga: ON" or "Tween to nigga: OFF"
        updateBtnState(tweenBtn, tweenStroke, tweenToPlayerEnabled)
        if tweenToPlayerEnabled then
            if targetPlayer then selectedTarget = targetPlayer.Name; startTweenToPlayer() end
        else stopTweenToPlayer() end
    end)
    spectateBtn.MouseButton1Click:Connect(function()
        if isInstaTP then
            isInstaTP = false
            instaBtn.Text = "Insta tp to nigga: OFF"
            updateBtnState(instaBtn, instaStroke, false)
        end
        if tweenToPlayerEnabled then
            tweenToPlayerEnabled = false
            tweenBtn.Text = "Tween to nigga: OFF"
            updateBtnState(tweenBtn, tweenStroke, false)
            stopTweenToPlayer()
        end
        if spectateEnabled then
            stopSpectate()
            spectateBtn.Text = "Spectate nigga: OFF"
            updateBtnState(spectateBtn, spectateStroke, false)
        else
            if targetPlayer then
                spectateEnabled = true
                spectateTarget = targetPlayer.Name
                spectateBtn.Text = "Spectate nigga: ON"
                updateBtnState(spectateBtn, spectateStroke, true)
                startSpectate(targetPlayer)
            else
                spectateBtn.Text = "Selecciona un nigga primero!"
                task.wait(1)
                if not spectateEnabled then spectateBtn.Text = "Spectate nigga: OFF" end
            end
        end
    end)
    runService.RenderStepped:Connect(function()
        if isInstaTP and targetPlayer and targetPlayer.Character and lp.Character then
            local myRoot = lp.Character:FindFirstChild("HumanoidRootPart")
            local tRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myRoot and tRoot then
                myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 5)
                myRoot.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end)
end
createInstaTPMenu(instaTPPage)

-- TPs a islas
addBtn("🚢 Barco Maldito (Sea 2)", sea2Page).MouseButton1Click:Connect(function() instantTP(CFrame.new(923,126,32852)) end)
addBtn("🏠 TP Mansión (Sea 2)", sea2Page).MouseButton1Click:Connect(function() instantTP(CFrame.new(-390,332,673)) end)
addBtn("☕ Café (Sea 2)", sea2Page).MouseButton1Click:Connect(function() instantTP(CFrame.new(-382,73,263)) end)
addBtn("🏰 Castillo (Sea 3)", sea3Page).MouseButton1Click:Connect(function() instantTP(CFrame.new(-5085,316,-3156)) end)
addBtn("🏠 Mansión (Sea 3)", sea3Page).MouseButton1Click:Connect(function() instantTP(CFrame.new(-12463,375,-7523)) end)

-- Confi nigga (orden: no cd nigger, Anti-Kick, Bypass TP)
addSwitch("no cd nigger", confiPage, function(on)
    noCDEnabled = on
    if on then
        if not noCDConnection then
            noCDConnection = lp.CharacterAdded:Connect(function(character)
                character:SetAttribute("AllCooldown", 3)
            end)
        end
        if lp.Character then lp.Character:SetAttribute("AllCooldown", 3) end
        startNotificationFilter()
    else
        if noCDConnection then noCDConnection:Disconnect(); noCDConnection = nil end
        if lp.Character then lp.Character:SetAttribute("AllCooldown", 0) end
        stopNotificationFilter()
    end
end)
addSwitch("Anti-Kick 🛡️", confiPage, function(on) antiKickEnabled = on; setupAntiKick() end)
addSwitch("Bypass TP", confiPage, function(on) bypassTPEnabled = on end)
addSwitch("Día nigga", confiPage, function(on)
    dayFogActive = on
    if on then
        applyFullDayFog()
        if not dayFogConnection then dayFogConnection = runService.RenderStepped:Connect(applyFullDayFog) end
    else
        if dayFogConnection then dayFogConnection:Disconnect(); dayFogConnection = nil end
        restoreLighting()
    end
end)
addSwitch("Cámara infinita", confiPage, function(on) zoomActive = on; lp.CameraMaxZoomDistance = on and 10000 or 128 end)
addSwitch("Anti lava / Anti kill-parts", confiPage, function(on) antiLavaActive = on end)
addSwitch("Borrar estructura barco", confiPage, function(on)
    deleteShipActive = on
    if deleteShipActive then
        task.spawn(function()
            local shipNames = {"CursedShip", "Cursed Ship", "Ship"}
            local exteriorNames = {"Wall", "Floor", "Ceiling", "Base", "Hull", "Window", "DoorFrame"}
            for _, obj in pairs(workspace:GetDescendants()) do
                for _, name in pairs(shipNames) do
                    if obj.Name:find(name) and (obj:IsA("Model") or obj:IsA("Folder")) then
                        for _, child in pairs(obj:GetDescendants()) do
                            if child:IsA("BasePart") and not child.Parent:FindFirstChild("Humanoid") then
                                local isExterior = false
                                for _, ext in pairs(exteriorNames) do
                                    if child.Name:find(ext) then isExterior = true; break end
                                end
                                if not isExterior then child:Destroy() end
                            end
                        end
                    end
                end
            end
        end)
    end
end)
addSwitch("No Animation", confiPage, function(on) noAnimationActive = on; if on then setupNoAnimation() elseif noAnimationConnection then noAnimationConnection:Disconnect() end end)

-- ==================== LOOPS GLOBALES ====================
runService.Stepped:Connect(function()
    if lp.Character then
        for _, v in pairs(lp.Character:GetDescendants()) do
            if v:IsA("BasePart") then
                if ncl then v.CanCollide = false end
                if antiLavaActive then
                    if v.Name ~= "HumanoidRootPart" and v.Name ~= "Torso" and v.Name ~= "UpperTorso" then
                        v.CanTouch = false
                    end
                else
                    v.CanTouch = true
                end
            end
        end
    end
end)

runService.RenderStepped:Connect(function()
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if walkWaterEnabled and hrp then
        if hrp.Position.Y >= 9.5 and hrp.Velocity.Y <= 0 then
            local waterPart = workspace:FindFirstChild("YeoWaterSolid") or Instance.new("Part", workspace)
            waterPart.Name = "YeoWaterSolid"
            waterPart.Size = Vector3.new(20,1,20)
            waterPart.Transparency = 1
            waterPart.Anchored = true
            waterPart.CFrame = CFrame.new(hrp.Position.X, 9.2, hrp.Position.Z)
        else
            if workspace:FindFirstChild("YeoWaterSolid") then workspace.YeoWaterSolid:Destroy() end
        end
    else
        if workspace:FindFirstChild("YeoWaterSolid") then workspace.YeoWaterSolid:Destroy() end
    end
end)

-- Controles de ventana
closeBtn.MouseButton1Click:Connect(function() print("Cierre desactivado") end)
minimizeBtn.MouseButton1Click:Connect(function()
    contentFrame.Visible = false
    tabContainer.Visible = false
    mainFrame:TweenSize(minimizedSize, "Out", "Quint", 0.3, true)
end)
maximizeBtn.MouseButton1Click:Connect(function()
    mainFrame:TweenSize(normalSize, "Out", "Quint", 0.3, true)
    task.wait(0.25)
    contentFrame.Visible = true
    tabContainer.Visible = true
end)

print("✅ YEO HUB DEFINITIVO - Fast Attack sin pausa (ataque por frame), Bypass TP instantáneo")