-- ROCKET Blox Fruits Menu v2
-- Delta / MuMu Android 15+
-- Обновление: фикс ON/OFF, авто-квест по лвл, авто-фарм по квесту, оружие, свёртка, дизайн

if game.PlaceId ~= 2753915549 and game.PlaceId ~= 4442272183 and game.PlaceId ~= 7449423635 then
    return warn("[ROCKET] Это не Blox Fruits!")
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer

-- ===== STATE =====
local State = {
    AutoFarm = false,
    AutoQuest = false,
    Speed = false,
    ESP = false,
    Noclip = false,
    InfJump = false,
    FullBright = false,
    AutoCollect = false,
    AutoHaki = false,
    Fly = false,
    Weapon = "Melee",
    MenuOpen = true,
    Title = "ROCKET",
}

local MENU_TITLES = {
    "ROCKET", "Blox Fruits", "Fruit Hub", "Delta Menu",
    "Sea Beast", "Auto Farm", "OP Script", "Level Up",
    "Pirate Hub", "Grand Line"
}

-- ===== GUI =====
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ROCKET_Menu_v2"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LP:WaitForChild("PlayerGui")

-- Главный фрейм
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 300, 0, 480)
Main.Position = UDim2.new(0, 20, 0.15, 0)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = Color3.fromRGB(80, 120, 255)
MainStroke.Thickness = 1.5

-- Заголовок
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
Header.BorderSizePixel = 0
Header.Parent = Main
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = State.Title .. " | Blox Fruits v2"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- Кнопка свернуть
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -70, 0, 5)
MinBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 14
MinBtn.Parent = Header
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

-- Кнопка закрыть (сворачивает в кружок)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 40)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

-- Круглая кнопка (появляется при закрытии)
local Bubble = Instance.new("TextButton")
Bubble.Size = UDim2.new(0, 50, 0, 50)
Bubble.Position = UDim2.new(0, 20, 0.3, 0)
Bubble.BackgroundColor3 = Color3.fromRGB(40, 90, 220)
Bubble.Text = "R"
Bubble.TextColor3 = Color3.fromRGB(255, 255, 255)
Bubble.Font = Enum.Font.GothamBold
Bubble.TextSize = 22
Bubble.Visible = false
Bubble.Active = true
Bubble.Draggable = true
Bubble.Parent = ScreenGui
Instance.new("UICorner", Bubble).CornerRadius = UDim.new(1, 0)

-- Скролл-контейнер для кнопок
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -16, 1, -50)
Scroll.Position = UDim2.new(0, 8, 0, 45)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 4
Scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 120, 255)
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = Main

local UIList = Instance.new("UIListLayout")
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0, 6)
UIList.Parent = Scroll

-- ===== СВЁРТКА =====
CloseBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    Bubble.Visible = true
end)

Bubble.MouseButton1Click:Connect(function()
    Main.Visible = true
    Bubble.Visible = false
end)

MinBtn.MouseButton1Click:Connect(function()
    if Scroll.Visible then
        Scroll.Visible = false
        Main.Size = UDim2.new(0, 300, 0, 45)
    else
        Scroll.Visible = true
        Main.Size = UDim2.new(0, 300, 0, 480)
    end
end)

-- ===== ХЕЛПЕРЫ =====
local function notify(text)
    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(0, 220, 0, 30)
    msg.Position = UDim2.new(1, -240, 0, 50)
    msg.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    msg.Text = "[ROCKET] " .. text
    msg.TextColor3 = Color3.fromRGB(255, 255, 255)
    msg.Font = Enum.Font.Gotham
    msg.TextSize = 12
    msg.Parent = ScreenGui
    Instance.new("UICorner", msg).CornerRadius = UDim.new(0, 6)
    task.delay(2, function()
        if msg then msg:Destroy() end
    end)
end

local function getChar()
    return LP.Character or LP.CharacterAdded:Wait()
end

local function getHRP()
    local c = getChar()
    return c:FindFirstChild("HumanoidRootPart")
end

local function tweenTo(pos, speed)
    local hrp = getHRP()
    if not hrp then return end
    local t = TweenService:Create(hrp, TweenInfo.new(speed or 0.3, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos)})
    t:Play()
end

local function getNearestMob(filterQuest)
    local hrp = getHRP()
    if not hrp then return nil end
    local closest, dist = nil, math.huge
    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then return nil end
    for _, v in pairs(enemies:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 and v:FindFirstChild("HumanoidRootPart") then
            local ok = true
            if filterQuest and _G.QuestMobs and #_G.QuestMobs > 0 then
                ok = false
                for _, name in pairs(_G.QuestMobs) do
                    if v.Name:lower():find(name:lower()) then ok = true break end
                end
            end
            if ok then
                local d = (v.HumanoidRootPart.Position - hrp.Position).Magnitude
                if d < dist then dist = d; closest = v end
            end
        end
    end
    return closest
end

local function attack(mob)
    if not mob or not mob:FindFirstChild("Humanoid") then return end
    -- Простая эмуляция атаки: подходим вплотную + дёргаем инструмент
    local tool = nil
    if State.Weapon == "Melee" then
        tool = getChar():FindFirstChildOfClass("Tool")
    else
        for _, t in pairs(getChar():GetChildren()) do
            if t:IsA("Tool") then
                if t.Name:lower():find(State.Weapon:lower()) then tool = t break end
            end
        end
    end
    if tool then
        tool.Parent = getChar()
        tool:Activate()
    end
    mob.Humanoid.Health = mob.Humanoid.Health - (tool and 15 or 5)
end

-- ===== AUTO QUEST =====
local function findQuestNPC()
    local myLevel = LP.Data and LP.Data.Level and LP.Data.Level.Value or 1
    local best, bestDiff = nil, math.huge
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") then
            local n = v.Name:lower()
            if n:find("quest") or n:find("giver") or n:find("boss") then
                local npcLevel = 1
                local lvlVal = v:FindFirstChild("Level") or (v:FindFirstChild("Humanoid") and v.Humanoid:FindFirstChild("Level"))
                if lvlVal and lvlVal.Value then npcLevel = lvlVal.Value end
                local diff = math.abs(npcLevel - myLevel)
                if diff < bestDiff then bestDiff = diff; best = v end
            end
        end
    end
    return best
end

task.spawn(function()
    while task.wait(0.5) do
        if State.AutoQuest then
            local npc = findQuestNPC()
            if npc and npc:FindFirstChild("Head") then
                tweenTo(npc.Head.Position + Vector3.new(0, 3, 0), 0.5)
                task.wait(0.4)
                -- Попытка взять квест через ProximityPrompt
                for _, p in pairs(npc:GetDescendants()) do
                    if p:IsA("ProximityPrompt") then
                        fireproximityprompt(p)
                        break
                    end
                end
            end
        end
    end
end)

-- ===== AUTO FARM =====
task.spawn(function()
    while task.wait(0.15) do
        if State.AutoFarm and getHRP() then
            local mob = getNearestMob(true)
            if mob then
                tweenTo(mob.HumanoidRootPart.Position + Vector3.new(0, 4, 0), 0.2)
                task.wait(0.12)
                attack(mob)
            end
        end
    end
end)

-- ===== AUTO COLLECT =====
task.spawn(function()
    while task.wait(0.5) do
        if State.AutoCollect and getHRP() then
            for _, v in pairs(workspace:GetChildren()) do
                if v.Name == "Fruit" or v.Name == "Drop" or v:FindFirstChild("Handle") and v:IsA("Tool") then
                    if v:FindFirstChild("Handle") then
                        tweenTo(v.Handle.Position + Vector3.new(0, 3, 0), 0.4)
                    end
                end
            end
        end
    end
end)

-- ===== ESP =====
RunService.RenderStepped:Connect(function()
    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then return end
    for _, v in pairs(enemies:GetChildren()) do
        if v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
            if State.ESP then
                local bb = v:FindFirstChild("ROCKET_ESP")
                if not bb then
                    bb = Instance.new("BillboardGui", v)
                    bb.Name = "ROCKET_ESP"
                    bb.Size = UDim2.new(0, 110, 0, 30)
                    bb.AlwaysOnTop = true
                    bb.Adornee = v.HumanoidRootPart
                    local txt = Instance.new("TextLabel", bb)
                    txt.Size = UDim2.new(1, 0, 1, 0)
                    txt.BackgroundTransparency = 1
                    txt.TextColor3 = Color3.fromRGB(255, 70, 70)
                    txt.TextStrokeTransparency = 0
                    txt.Font = Enum.Font.GothamBold
                    txt.TextSize = 13
                end
                local txt = bb:FindFirstChildOfClass("TextLabel")
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

-- ===== SPEED / NOCLIP / INF JUMP / FULLBRIGHT / FLY / HAKI =====
RunService.Stepped:Connect(function()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")

    if hum and State.Speed then hum.WalkSpeed = 80 elseif hum then hum.WalkSpeed = 16 end

    if hrp then
        if State.Noclip then
            for _, p in pairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
        if State.Fly then
            hrp.Velocity = Vector3.new(0, 50, 0)
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if State.InfJump then
        local hum = getChar():FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

task.spawn(function()
    while task.wait(2) do
        if State.FullBright then
            game:GetService("Lighting").Brightness = 3
            game:GetService("Lighting").ClockTime = 12
            game:GetService("Lighting").FogEnd = 100000
            game:GetService("Lighting").GlobalShadows = false
        end
        if State.AutoHaki then
            pcall(function()
                for _, t in pairs(LP.Backpack:GetChildren()) do
                    if t.Name:lower():find("haki") or t.Name:lower():find("buso") then
                        t.Parent = LP.Character
                    end
                end
            end)
        end
    end
end)

-- ===== UI ЭЛЕМЕНТЫ =====
local function makeButton(text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = Color3.fromRGB(38, 38, 55)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(235, 235, 245)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 14
    btn.AutoButtonColor = true
    btn.Parent = Scroll
    local c = Instance.new("UICorner", btn)
    c.CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(70, 70, 100)
    stroke.Thickness = 1

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(55, 55, 80)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        if btn.BackgroundColor3 ~= Color3.fromRGB(0, 140, 60) then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(38, 38, 55)}):Play()
        end
    end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Универсальный toggle
local function toggleButton(label, key, extra)
    local btn = makeButton(label .. ": OFF", function()
        State[key] = not State[key]
        btn.Text = label .. ": " .. (State[key] and "ON" or "OFF")
        btn.BackgroundColor3 = State[key] and Color3.fromRGB(0, 140, 60) or Color3.fromRGB(38, 38, 55)
        if extra then extra(State[key]) end
    end)
    return btn
end

toggleButton("Auto Farm", "AutoFarm")
toggleButton("Auto Quest", "AutoQuest")
toggleButton("Speed 80", "Speed")
toggleButton("ESP", "ESP")
toggleButton("Noclip", "Noclip")
toggleButton("Infinite Jump", "InfJump")
toggleButton("Full Bright", "FullBright")
toggleButton("Auto Collect", "AutoCollect")
toggleButton("Auto Haki", "AutoHaki")
toggleButton("Fly (up)", "Fly")

-- Выбор оружия
local wLabel = Instance.new("TextLabel")
wLabel.Size = UDim2.new(1, 0, 0, 24)
wLabel.BackgroundTransparency = 1
wLabel.Text = "Оружие для авто-фарма:"
wLabel.TextColor3 = Color3.fromRGB(180, 180, 220)
wLabel.Font = Enum.Font.Gotham
wLabel.TextSize = 12
wLabel.TextXAlignment = Enum.TextXAlignment.Left
wLabel.Parent = Scroll

for _, wpn in pairs({"Melee", "Sword", "Gun", "Fruit"}) do
    local wBtn = makeButton("  " .. wpn, function()
        State.Weapon = wpn
        notify("Оружие: " .. wpn)
    end)
    wBtn.Size = UDim2.new(1, 0, 0, 30)
end

-- Выбор названия меню
local tLabel = Instance.new("TextLabel")
tLabel.Size = UDim2.new(1, 0, 0, 24)
tLabel.BackgroundTransparency = 1
tLabel.Text = "Название меню:"
tLabel.TextColor3 = Color3.fromRGB(180, 180, 220)
tLabel.Font = Enum.Font.Gotham
tLabel.TextSize = 12
tLabel.TextXAlignment = Enum.TextXAlignment.Left
tLabel.Parent = Scroll

for _, name in pairs(MENU_TITLES) do
    local nBtn = makeButton("  " .. name, function()
        State.Title = name
        Title.Text = name .. " | Blox Fruits v2"
        notify("Название: " .. name)
    end)
    nBtn.Size = UDim2.new(1, 0, 0, 28)
end

notify("ROCKET v2 загружен. PlaceId: " .. game.PlaceId)
print("[ROCKET v2] Loaded")
