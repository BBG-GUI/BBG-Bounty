local Players = game:GetService("Players")  
local VirtualInputManager = game:GetService("VirtualInputManager")  
local RunService = game:GetService("RunService")  
local UserInputService = game:GetService("UserInputService")  
local lp = Players.LocalPlayer  
  
local BG_MAIN = Color3.fromRGB(10, 0, 20)  
local ACCENT = Color3.fromRGB(160, 0, 255)  
  
getgenv().AbuseActive = false  
getgenv().SelectedSlot = Enum.KeyCode.Three  
  
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)  
local MainFrame = Instance.new("Frame", ScreenGui)  
MainFrame.Size = UDim2.new(0, 180, 0, 150)  
MainFrame.Position = UDim2.new(0.5, -90, 0.5, -150)  
MainFrame.BackgroundColor3 = BG_MAIN  
MainFrame.BorderSizePixel = 2  
MainFrame.BorderColor3 = ACCENT  
Instance.new("UICorner", MainFrame)  
  
local TitleBar = Instance.new("Frame", MainFrame)  
TitleBar.Size = UDim2.new(1, 0, 0, 32)  
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 0, 40)  
TitleBar.BorderSizePixel = 0  
Instance.new("UICorner", TitleBar)  
  
local Title = Instance.new("TextLabel", TitleBar)  
Title.Size = UDim2.new(1, -30, 1, 0)  
Title.Position = UDim2.new(0, 8, 0, 0)  
Title.Text = "BBG GUI"  
Title.TextColor3 = ACCENT  
Title.Font = Enum.Font.GothamBold  
Title.TextSize = 14  
Title.BackgroundTransparency = 1  
Title.TextXAlignment = Enum.TextXAlignment.Left  
  
local Subtitle = Instance.new("TextLabel", MainFrame)  
Subtitle.Size = UDim2.new(1, 0, 0, 18)  
Subtitle.Position = UDim2.new(0, 0, 0, 32)  
Subtitle.TextColor3 = Color3.fromRGB(200, 150, 255)  
Subtitle.Font = Enum.Font.Gotham  
Subtitle.TextSize = 11  
Subtitle.BackgroundTransparency = 1  
  
local MinBtn = Instance.new("TextButton", TitleBar)  
MinBtn.Size = UDim2.new(0, 24, 0, 24)  
MinBtn.Position = UDim2.new(1, -28, 0, 4)  
MinBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)  
MinBtn.Text = "-"  
MinBtn.TextColor3 = Color3.new(1, 1, 1)  
MinBtn.Font = Enum.Font.GothamBold  
MinBtn.TextSize = 16  
Instance.new("UICorner", MinBtn)  
  
local ContentFrame = Instance.new("Frame", MainFrame)  
ContentFrame.Size = UDim2.new(1, 0, 1, -52)  
ContentFrame.Position = UDim2.new(0, 0, 0, 52)  
ContentFrame.BackgroundTransparency = 1  
  
local minimized = false  
MinBtn.MouseButton1Click:Connect(function()  
    minimized = not minimized  
    if minimized then  
        MainFrame.Size = UDim2.new(0, 180, 0, 32)  
        ContentFrame.Visible = false  
        Subtitle.Visible = false  
        MinBtn.Text = "+"  
    else  
        MainFrame.Size = UDim2.new(0, 180, 0, 150)  
        ContentFrame.Visible = true  
        Subtitle.Visible = true  
        MinBtn.Text = "-"  
    end  
end)  
  
local function Press(key)  
    VirtualInputManager:SendKeyEvent(true, key, false, game)  
    task.wait(0.01)  
    VirtualInputManager:SendKeyEvent(false, key, false, game)  
end  
  
local function ExecuteAbuse()  
    if not getgenv().AbuseActive then return end  
    local char = lp.Character or lp.CharacterAdded:Wait()  
    local hrp = char:WaitForChild("HumanoidRootPart", 10)  
    local hum = char:WaitForChild("Humanoid", 10)  
  
    if hrp and hum and hum.Health > 0 then  
        hrp.CFrame = hrp.CFrame * CFrame.new(0, 500, 0)  
        Press(getgenv().SelectedSlot)  
        task.wait(0.08)  
        Press(Enum.KeyCode.J)  
        local targetPos = CFrame.new(923.2, 3000000000000000000000, 32852.8)  
        hrp.Anchored = true  
        hrp.CFrame = targetPos  
        workspace.CurrentCamera.CFrame = targetPos  
        task.wait(0.05)  
        Press(Enum.KeyCode.Z)  
        task.spawn(function()  
            task.wait(0.03)  
            hum.Health = 0  
        end)  
        local s = tick()  
        while tick() - s < 0.6 do RunService.Heartbeat:Wait() end  
    end  
end  
  
local function VoidSkill()  
    local char = lp.Character  
    local hrp = char and char:FindFirstChild("HumanoidRootPart")  
    if hrp then  
        local oldPos = hrp.CFrame  
        hrp.Anchored = true  
        hrp.CFrame = CFrame.new(923.2, 3000000000000000000000, 32852.8)  
        workspace.CurrentCamera.CFrame = hrp.CFrame  
        task.wait(0.1)  
        Press(Enum.KeyCode.Z)  
        task.wait(0.8)  
        hrp.CFrame = oldPos  
        workspace.CurrentCamera.CameraSubject = char.Humanoid  
        hrp.Anchored = false  
    end  
end  
  
local function MakeButton(parent, text, yPos, bgColor)  
    local btn = Instance.new("TextButton", parent)  
    btn.Size = UDim2.new(0.88, 0, 0, 38)  
    btn.Position = UDim2.new(0.06, 0, 0, yPos)  
    btn.BackgroundColor3 = bgColor  
    btn.Text = text  
    btn.TextColor3 = Color3.new(1, 1, 1)  
    btn.Font = Enum.Font.GothamBold  
    btn.TextSize = 12  
    Instance.new("UICorner", btn)  
    return btn  
end  
  
local VoidBtn   = MakeButton(ContentFrame, "ABUSE",      10, Color3.fromRGB(50, 0, 80))  
local FixBtn    = MakeButton(ContentFrame, "FIX CAMERA", 55, Color3.fromRGB(50, 0, 80))  
FixBtn.TextColor3 = ACCENT  
FixBtn.Size = UDim2.new(0.88, 0, 0, 28)  
  
VoidBtn.MouseButton1Click:Connect(VoidSkill)  
  
FixBtn.MouseButton1Click:Connect(function()  
    getgenv().AbuseActive = false  
    if lp.Character then  
        workspace.CurrentCamera.CameraSubject = lp.Character.Humanoid  
        lp.Character.HumanoidRootPart.Anchored = false  
    end  
end)  
  
lp.CharacterAdded:Connect(function()  
    if getgenv().AbuseActive then  
        task.wait(0.5)  
        task.spawn(ExecuteAbuse)  
    end  
end)  
  
local d, ds, sp  
TitleBar.InputBegan:Connect(function(i)  
    if i.UserInputType == Enum.UserInputType.MouseButton1 then  
        d = true ds = i.Position sp = MainFrame.Position  
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
