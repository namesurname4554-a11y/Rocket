-- ROCKET Blox Fruits Menu v1
-- Под Delta / MuMu Android 15
-- Вставляй целиком в Delta → Execute

if game.PlaceId ~= 2753915549 and game.PlaceId ~= 4442272183 and game.PlaceId ~= 7449423635 then
    return warn("Это не Blox Fruits!")
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer

-- ===== GUI =====
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ROCKET_Menu"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LP:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 260, 0, 340)
Main.Position = UDim2.new(0, 20, 0.3, 0)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local UICorner = Instance.new("UICorner", Main)
UICorner.CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
Title.Text = "ROCKET | Blox Fruits"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = Main

local TitleCorner = Instance.new("UICorner", Title)
TitleCorner.CornerRadius = UDim.new(0, 10)

-- ===== Функции =====
local State = {
    AutoFarm = false,
    AutoQuest = false,
    Speed = false,
    ESP = false,
}

-- Auto Farm (моб рядом)
local function getNearestMob()
    local closest, dist = nil, math.huge
    for _, v in pairs(workspace.Enemies:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 and v:FindFirstChild("HumanoidRootPart") then
            local d = (v.HumanoidRootPart.Position - LP.Character.HumanoidRootPart.Position).Magnitude
            if d < dist then
                dist = d
                closest = v
            end
        end
    end
    return closest
end

-- Auto Quest (квестодатель)
local function getQuestNPC()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") then
            if v.Name:lower():find("quest") or v.Name:lower():find("questgiver") then
                return v
            end
        end
    end
    return nil
end

-- Teleport to position
local function tweenTo(pos)
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = LP.Character.HumanoidRootPart
    local tween = TweenService:Create(hrp, TweenInfo.new(0.3, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos)})
    tween:Play()
end

-- Speed
RunService.RenderStepped:Connect(function()
    if State.Speed and LP.Character and LP.Character:FindFirstChild("Humanoid") then
        LP.Character.Humanoid.WalkSpeed = 80
    end
end)

-- Auto Farm loop
task.spawn(function()
    while task.wait(0.2) do
        if State.AutoFarm and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            local mob = getNearestMob()
            if mob then
                tweenTo(mob.HumanoidRootPart.Position + Vector3.new(0, 5, 0))
                task.wait(0.15)
                if mob:FindFirstChild("Humanoid") then
                    mob.Humanoid.Health = 0
                end
            end
        end
    end
end)

-- Auto Quest loop
task.spawn(function()
    while task.wait(1) do
        if State.AutoQuest then
            local npc = getQuestNPC()
            if npc and npc:FindFirstChild("Head") then
                tweenTo(npc.Head.Position + Vector3.new(0, 3, 0))
            end
        end
    end
end)

-- ESP
local ESPFolder = Instance.new("Folder", ScreenGui)
ESP_Folder = ESPFolder
RunService.RenderStepped:Connect(function()
    for _, v in pairs(workspace.Enemies:GetChildren()) do
        if v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
            if State.ESP then
                local billboard = v:FindFirstChild("ROCKET_ESP")
                if not billboard then
                    billboard = Instance.new("BillboardGui", v)
                    billboard.Name = "ROCKET_ESP"
                    billboard.Size = UDim2.new(0, 100, 0, 30)
                    billboard.AlwaysOnTop = true
                    billboard.Adornee = v.HumanoidRootPart
                    local text = Instance.new("TextLabel", billboard)
                    text.Size = UDim2.new(1, 0, 1, 0)
                    text.BackgroundTransparency = 1
                    text.TextColor3 = Color3.fromRGB(255, 60, 60)
                    text.TextStrokeTransparency = 0
                    text.Font = Enum.Font.GothamBold
                    text.TextSize = 14
                    text.Text = v.Name
                end
                local txt = v.ROCKET_ESP:FindFirstChildOfClass("TextLabel")
                if txt then
                    txt.Text = v.Name .. " | " .. math.floor(v.Humanoid.Health) .. "/" .. math.floor(v.Humanoid.MaxHealth)
                end
            else
                local old = v:FindFirstChild("ROCKET_ESP")
                if old then old:Destroy() end
            end
        end
    end
end)

-- ===== Кнопки =====
local function makeButton(text, y, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 36)
    btn.Position = UDim2.new(0.05, 0, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.Parent = Main
    local c = Instance.new("UICorner", btn)
    c.CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local b1 = makeButton("Auto Farm: OFF", 50, function()
    State.AutoFarm = not State.AutoFarm
    b1.Text = "Auto Farm: " .. (State.AutoFarm and "ON" or "OFF")
    b1.BackgroundColor3 = State.AutoFarm and Color3.fromRGB(0, 140, 60) or Color3.fromRGB(45, 45, 60)
end)

local b2 = makeButton("Auto Quest: OFF", 95, function()
    State.AutoQuest = not State.AutoQuest
    b2.Text = "Auto Quest: " .. (State.AutoQuest and "ON" or "OFF")
    b2.BackgroundColor3 = State.AutoQuest and Color3.fromRGB(0, 140, 60) or Color3.fromRGB(45, 45, 60)
end)

local b3 = makeButton("Speed: OFF", 140, function()
    State.Speed = not State.Speed
    b3.Text = "Speed: " .. (State.Speed and "ON" or "OFF")
    b3.BackgroundColor3 = State.Speed and Color3.fromRGB(0, 140, 60) or Color3.fromRGB(45, 45, 60)
    if not State.Speed and LP.Character and LP.Character:FindFirstChild("Humanoid") then
        LP.Character.Humanoid.WalkSpeed = 16
    end
end)

local b4 = makeButton("ESP: OFF", 185, function()
    State.ESP = not State.ESP
    b4.Text = "ESP: " .. (State.ESP and "ON" or "OFF")
    b4.BackgroundColor3 = State.ESP and Color3.fromRGB(0, 140, 60) or Color3.fromRGB(45, 45, 60)
end)

local b5 = makeButton("Teleport: Sea 1", 230, function()
    if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        tweenTo(Vector3.new(0, 50, 0))
    end
end)

local b6 = makeButton("Закрыть меню", 275, function()
    ScreenGui:Destroy()
end)

print("[ROCKET] Menu loaded. PlaceId:", game.PlaceId)
