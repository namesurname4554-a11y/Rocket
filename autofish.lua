--// ============================================
--//  Popka Hub v5 — Fisch Tester
--//  No logger • Fixed Auto Fish • Teleport/GPS • More
--// ============================================

local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local Workspace          = game:GetService("Workspace")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local CoreGui            = game:GetService("CoreGui")
local VirtualUser        = game:GetService("VirtualUser")
local Lighting           = game:GetService("Lighting")
local TweenService       = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

--// ============ CONFIG ============
local Config = {
    Fish = {
        AutoFish      = false,
        AutoSell      = false,
        AutoCast      = false,
        AutoReel      = false,
        AutoShake     = false,
        CastCooldown  = 2,
        ReelCooldown  = 1.5,
        ShakeDelay    = 0.1,
    },
    Movement = {
        SpeedEnabled  = false,
        SpeedValue    = 50,
        JumpEnabled   = false,
        JumpValue     = 100,
        FlyEnabled    = false,
        FlySpeed      = 80,
        FlyKeys       = {W=false,A=false,S=false,D=false,Space=false,LCtrl=false},
        Noclip        = false,
        InfiniteJump  = false,
        ClickTP       = false,
        SwimSpeed     = false,
    },
    Teleport = {
        Selected = "Spawn",
        GPSEnabled = false,
        GPSTarget = nil,
    },
    Visual = {
        PlayerESP     = false,
        Nametags      = false,
        FishESP       = false,
        Fullbright    = false,
        NoFog         = false,
        CameraFOV     = 70,
    },
    Misc = {
        AntiAFK       = true,
        AutoReconnect = false,
        AntiFling     = false,
        InfiniteYield = false,
    },
    UI = {
        Accent = Color3.fromRGB(255, 100, 150),
        Transparency = 0,
    }
}

--// ============ REMOTES ============
local Net = ReplicatedStorage:FindFirstChild("packages") 
            and ReplicatedStorage.packages:FindFirstChild("Net")

local function R(name)
    if not Net then return nil end
    return Net:FindFirstChild(name)
end

local rodEvents
do
    local s = ReplicatedStorage:FindFirstChild("shared")
    local m = s and s:FindFirstChild("modules")
    local f = m and m:FindFirstChild("fishing")
    local r = f and f:FindFirstChild("rodresources")
    rodEvents = r and r:FindFirstChild("events")
end

local Remotes = {
    CastAsync     = rodEvents and rodEvents:FindFirstChild("castAsync"),
    CatchFinish   = rodEvents and rodEvents:FindFirstChild("catchfinish"),
    HandleBobber  = rodEvents and rodEvents:FindFirstChild("handlebobber"),
    BreakBobber   = rodEvents and rodEvents:FindFirstChild("breakbobber"),
    ResetRod      = rodEvents and rodEvents:FindFirstChild("reset"),
    CastRod       = R("RF/FishingRod/Cast"),
    ReelStart     = R("RF/Reel/Start"),
    ReelFinish    = R("RE/Reel/Finish"),
    ReelAbort     = R("RE/Reel/Abort"),
    LureStart     = R("RF/LureShake/Start"),
    LureStop      = R("RE/LureShake/Stop"),
    LureShake     = R("RE/LureShake/Shake"),
    StabStart     = R("RF/Stab/Start"),
    StabFinish    = R("RE/Stab/Finish"),
    StabAbort     = R("RE/Stab/Abort"),
    RequestTp     = R("RE/RequestTeleport"),
    GetSpawn      = R("RF/GetSpawnPosition"),
    GetZone       = R("RF/GetZone"),
    DeepTp        = R("RF/Deep/Teleport"),
    MarianasTp    = R("RF/MarianasVeil/Teleport"),
    ReturnSurface = R("RE/ReturnToSurface"),
    Equip         = R("RE/Backpack/Equip"),
    Favorite      = R("RE/Backpack/Favourite"),
    BoatsSpawn    = R("RF/Boats/Spawn"),
    BoatsDespawn  = R("RE/Boats/Despawn"),
    FastTravel    = R("RE/FastTravel/ToggleUI"),
    FT_Fade       = R("RE/FastTravel/Fade"),
}

local function fire(remote, ...)
    if not remote then return false, "missing" end
    local args = {...}
    local ok, err = pcall(function() remote:FireServer(table.unpack(args)) end)
    return ok, err
end

local function invoke(remote, ...)
    if not remote then return false, "missing" end
    local args = {...}
    local ok, res = pcall(function() return remote:InvokeServer(table.unpack(args)) end)
    return ok, res
end

--// ============ CLEANUP ============
for _, g in ipairs({CoreGui, LocalPlayer:WaitForChild("PlayerGui")}) do
    local old = g:FindFirstChild("PopkaHub")
    if old then old:Destroy() end
end

--// ============ THEME ============
local Theme = {
    Bg        = Color3.fromRGB(18, 18, 22),
    Panel     = Color3.fromRGB(26, 26, 32),
    Element   = Color3.fromRGB(36, 36, 44),
    Accent    = Config.UI.Accent,
    Text      = Color3.fromRGB(235, 235, 240),
    Subtext   = Color3.fromRGB(150, 150, 165),
    ToggleOff = Color3.fromRGB(55, 55, 65),
    Danger    = Color3.fromRGB(230, 80, 80),
    Success   = Color3.fromRGB(100, 220, 120),
}

--// ============ GUI ============
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PopkaHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local FULL_SIZE = UDim2.new(0, 580, 0, 440)
local MINI_SIZE = UDim2.new(0, 580, 0, 40)

local Main = Instance.new("Frame")
Main.Size = FULL_SIZE
Main.Position = UDim2.new(0.5, -290, 0.5, -220)
Main.BackgroundColor3 = Theme.Bg
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.ClipsDescendants = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = Color3.fromRGB(45, 45, 55)

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Theme.Panel
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)

local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 15)
TitleFix.Position = UDim2.new(0, 0, 1, -15)
TitleFix.BackgroundColor3 = Theme.Panel
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -100, 1, 0)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Popka Hub v5  |  Fisch Tester"
TitleLabel.TextColor3 = Theme.Accent
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 15
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 26, 0, 26)
MinBtn.Position = UDim2.new(1, -66, 0, 7)
MinBtn.BackgroundColor3 = Theme.Element
MinBtn.BorderSizePixel = 0
MinBtn.Text = "-"
MinBtn.TextColor3 = Theme.Text
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 16
MinBtn.Parent = TitleBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -34, 0, 7)
CloseBtn.BackgroundColor3 = Theme.Element
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "x"
CloseBtn.TextColor3 = Theme.Text
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

local ContentWrap = Instance.new("Frame")
ContentWrap.Size = UDim2.new(1, 0, 1, -40)
ContentWrap.Position = UDim2.new(0, 0, 0, 40)
ContentWrap.BackgroundTransparency = 1
ContentWrap.Parent = Main

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -20, 0, 32)
TabBar.Position = UDim2.new(0, 10, 0, 8)
TabBar.BackgroundColor3 = Theme.Panel
TabBar.BorderSizePixel = 0
TabBar.Parent = ContentWrap
Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 8)

local TabLayout = Instance.new("UIListLayout", TabBar)
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0, 3)
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, -20, 1, -58)
TabContainer.Position = UDim2.new(0, 10, 0, 48)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = ContentWrap

local Pages = {}
local TabButtons = {}
local TabOrder = {"Fish", "Movement", "Teleport", "Visual", "Misc", "Customize", "Profile"}

local function createPage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = Theme.Accent
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.Parent = TabContainer

    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local pad = Instance.new("UIPadding", page)
    pad.PaddingTop = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 4)

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)

    Pages[name] = page
end

for _, name in ipairs(TabOrder) do
    createPage(name)
    local tb = Instance.new("TextButton")
    tb.Size = UDim2.new(0, 76, 0, 24)
    tb.BackgroundColor3 = Theme.Element
    tb.BorderSizePixel = 0
    tb.Text = name
    tb.TextColor3 = Theme.Subtext
    tb.Font = Enum.Font.GothamMedium
    tb.TextSize = 11
    tb.Parent = TabBar
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 6)
    TabButtons[name] = tb
end

local function switchTab(name)
    for tabName, btn in pairs(TabButtons) do
        if tabName == name then
            btn.BackgroundColor3 = Theme.Accent
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = Theme.Element
            btn.TextColor3 = Theme.Subtext
        end
    end
    for tabName, page in pairs(Pages) do
        page.Visible = (tabName == name)
    end
end

for tabName, btn in pairs(TabButtons) do
    btn.MouseButton1Click:Connect(function() switchTab(tabName) end)
end

--// ============ UI ELEMENTS ============
local function makeSection(parent, text)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 22)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 1, 0)
    lbl.Position = UDim2.new(0, 6, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Theme.Accent
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame
end

local function makeToggle(parent, text, default, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = Theme.Element
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = btn

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 36, 0, 18)
    indicator.Position = UDim2.new(1, -48, 0.5, -9)
    indicator.BackgroundColor3 = default and Theme.Accent or Theme.ToggleOff
    indicator.BorderSizePixel = 0
    indicator.Parent = btn
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = default and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = indicator
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        indicator.BackgroundColor3 = state and Theme.Accent or Theme.ToggleOff
        knob.Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        callback(state)
    end)
end

local function makeSlider(parent, text, min, max, default, callback)
    local holder = Instance.new("TextButton")
    holder.Size = UDim2.new(1, 0, 0, 44)
    holder.BackgroundColor3 = Theme.Element
    holder.BorderSizePixel = 0
    holder.Text = ""
    holder.AutoButtonColor = false
    holder.Parent = parent
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 16)
    label.Position = UDim2.new(0, 12, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. default
    label.TextColor3 = Theme.Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = holder

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, -24, 0, 6)
    barBg.Position = UDim2.new(0, 12, 0, 28)
    barBg.BackgroundColor3 = Theme.ToggleOff
    barBg.BorderSizePixel = 0
    barBg.Parent = holder
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = barBg
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local dragging = false
    local function update(input)
        local rel = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * rel)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        label.Text = text .. ": " .. val
        callback(val)
    end

    holder.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function makeButton(parent, text, callback, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = color or Theme.Element
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Theme.Text
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback)
end

local function makeInfoRow(parent, key, value)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 28)
    row.BackgroundColor3 = Theme.Element
    row.BorderSizePixel = 0
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local k = Instance.new("TextLabel")
    k.Size = UDim2.new(0.4, 0, 1, 0)
    k.Position = UDim2.new(0, 12, 0, 0)
    k.BackgroundTransparency = 1
    k.Text = key
    k.TextColor3 = Theme.Subtext
    k.Font = Enum.Font.Gotham
    k.TextSize = 12
    k.TextXAlignment = Enum.TextXAlignment.Left
    k.Parent = row

    local v = Instance.new("TextLabel")
    v.Size = UDim2.new(0.6, -12, 1, 0)
    v.Position = UDim2.new(0.4, 0, 0, 0)
    v.BackgroundTransparency = 1
    v.Text = tostring(value)
    v.TextColor3 = Theme.Text
    v.Font = Enum.Font.GothamMedium
    v.TextSize = 12
    v.TextXAlignment = Enum.TextXAlignment.Right
    v.Parent = row
end

--// ============ FISH PAGE ============
local fishPage = Pages["Fish"]

makeSection(fishPage, "AUTO FISH (all-in-one)")
makeToggle(fishPage, "Auto Fish", false, function(v) Config.Fish.AutoFish = v end)
makeSlider(fishPage, "Cast Cooldown", 1, 10, 2, function(v) Config.Fish.CastCooldown = v end)
makeSlider(fishPage, "Reel Cooldown", 1, 10, 2, function(v) Config.Fish.ReelCooldown = v end)
makeSlider(fishPage, "Shake Delay (ms)", 50, 500, 100, function(v) Config.Fish.ShakeDelay = v / 1000 end)

makeSection(fishPage, "INDIVIDUAL AUTO")
makeToggle(fishPage, "Auto Cast", false, function(v) Config.Fish.AutoCast = v end)
makeToggle(fishPage, "Auto Reel", false, function(v) Config.Fish.AutoReel = v end)
makeToggle(fishPage, "Auto Shake", false, function(v) Config.Fish.AutoShake = v end)
makeToggle(fishPage, "Auto Sell", false, function(v) Config.Fish.AutoSell = v end)

makeSection(fishPage, "MANUAL ACTIONS")
makeButton(fishPage, "Cast Rod", function()
    local ok, err = invoke(Remotes.CastAsync)
    if not ok then invoke(Remotes.CastRod) end
    print("[Popka] Cast done")
end)
makeButton(fishPage, "Reel Start", function() invoke(Remotes.ReelStart) end)
makeButton(fishPage, "Reel Finish", function() fire(Remotes.ReelFinish) end)
makeButton(fishPage, "Shake Once", function()
    fire(Remotes.LureShake, Vector2.new(math.random(-100,100), math.random(-100,100)))
end)
makeButton(fishPage, "Abort Reel", function() fire(Remotes.ReelAbort) end)
makeButton(fishPage, "Reset Rod", function() fire(Remotes.ResetRod) end)
makeButton(fishPage, "Break Bobber", function() fire(Remotes.BreakBobber) end)

makeSection(fishPage, "MINIGAMES")
makeButton(fishPage, "Lure Start", function() invoke(Remotes.LureStart) end)
makeButton(fishPage, "Lure Stop", function() fire(Remotes.LureStop) end)
makeButton(fishPage, "Stab Start", function() invoke(Remotes.StabStart) end)
makeButton(fishPage, "Stab Finish", function() fire(Remotes.StabFinish) end)

--// ============ MOVEMENT PAGE ============
local movePage = Pages["Movement"]

makeSection(movePage, "SPEED")
makeToggle(movePage, "Speed Hack", false, function(v)
    Config.Movement.SpeedEnabled = v
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v and Config.Movement.SpeedValue or 16 end
    end
end)
makeSlider(movePage, "Speed Value", 16, 500, 50, function(v) Config.Movement.SpeedValue = v end)
makeToggle(movePage, "Swim Speed (affects swim)", false, function(v) Config.Movement.SwimSpeed = v end)

makeSection(movePage, "JUMP")
makeToggle(movePage, "Jump Power Hack", false, function(v)
    Config.Movement.JumpEnabled = v
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = v and Config.Movement.JumpValue or 50 end
    end
end)
makeSlider(movePage, "Jump Power", 50, 500, 100, function(v) Config.Movement.JumpValue = v end)
makeToggle(movePage, "Infinite Jump", false, function(v) Config.Movement.InfiniteJump = v end)

makeSection(movePage, "FLY")
makeToggle(movePage, "Fly", false, function(v) Config.Movement.FlyEnabled = v end)
makeSlider(movePage, "Fly Speed", 20, 500, 80, function(v) Config.Movement.FlySpeed = v end)

makeSection(movePage, "OTHER")
makeToggle(movePage, "Noclip", false, function(v) Config.Movement.Noclip = v end)
makeToggle(movePage, "Click Teleport", false, function(v) Config.Movement.ClickTP = v end)
makeButton(movePage, "Reset Character", function()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    end
end)

--// ============ TELEPORT PAGE ============
local tpPage = Pages["Teleport"]

makeSection(tpPage, "PRESET LOCATIONS")
local tpLocations = {
    ["Spawn"]        = nil,
    ["Return Surface"] = "surface",
    ["The Depths"]   = "deep",
    ["Marianas Veil"]= "marianas",
    ["Fast Travel"]  = "fasttravel",
}

for name, mode in pairs(tpLocations) do
    makeButton(tpPage, "Teleport: " .. name, function()
        if name == "Spawn" then
            local ok, pos = invoke(Remotes.GetSpawn)
            if ok and pos then fire(Remotes.RequestTp, pos) end
        elseif name == "Return Surface" then
            fire(Remotes.ReturnSurface)
        elseif name == "The Depths" then
            invoke(Remotes.DeepTp)
        elseif name == "Marianas Veil" then
            invoke(Remotes.MarianasTp)
        elseif name == "Fast Travel" then
            fire(Remotes.FastTravel)
        end
        print("[Popka] Teleport:", name)
    end)
end

makeSection(tpPage, "GPS")
makeToggle(tpPage, "Show GPS Waypoint", false, function(v)
    Config.Teleport.GPSEnabled = v
end)
makeButton(tpPage, "Set GPS to Nearest Player", function()
    local closest, minDist = nil, math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (LocalPlayer.Character.HumanoidRootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude
            if dist < minDist then
                minDist = dist
                closest = plr
            end
        end
    end
    if closest then
        Config.Teleport.GPSTarget = closest.Character.HumanoidRootPart
        print("[Popka] GPS locked to:", closest.Name)
    end
end)

local gpsGui = Instance.new("BillboardGui")
gpsGui.Size = UDim2.new(0, 150, 0, 60)
gpsGui.AlwaysOnTop = true
gpsGui.Enabled = false
gpsGui.Name = "PopkaGPS"

local gpsFrame = Instance.new("Frame", gpsGui)
gpsFrame.Size = UDim2.new(1, 0, 1, 0)
gpsFrame.BackgroundTransparency = 0.4
gpsFrame.BackgroundColor3 = Theme.Accent
Instance.new("UICorner", gpsFrame).CornerRadius = UDim.new(0, 8)

local gpsLabel = Instance.new("TextLabel", gpsGui)
gpsLabel.Size = UDim2.new(1, 0, 1, 0)
gpsLabel.BackgroundTransparency = 1
gpsLabel.Text = "GPS"
gpsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
gpsLabel.Font = Enum.Font.GothamBold
gpsLabel.TextSize = 14

makeSection(tpPage, "DIRECT CFrame TELEPORT")
makeButton(tpPage, "TP to Cursor (Raycast)", function()
    local mouse = LocalPlayer:GetMouse()
    local target = mouse.Hit
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(target.Position + Vector3.new(0, 3, 0))
    end
end)
makeButton(tpPage, "TP to Random Player", function()
    local players = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(players, p)
        end
    end
    if #players > 0 then
        local target = players[math.random(1, #players)]
        LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5)
    end
end)

--// ============ VISUAL PAGE ============
local visualPage = Pages["Visual"]

makeSection(visualPage, "PLAYER ESP")
makeToggle(visualPage, "Player ESP", false, function(v) Config.Visual.PlayerESP = v end)
makeToggle(visualPage, "Nametags", false, function(v) Config.Visual.Nametags = v end)

makeSection(visualPage, "FISH ESP")
makeToggle(visualPage, "Fish ESP (shiny)", false, function(v) Config.Visual.FishESP = v end)

makeSection(visualPage, "WORLD")
makeToggle(visualPage, "Fullbright", false, function(v)
    Config.Visual.Fullbright = v
    if v then
        Lighting.Ambient = Color3.fromRGB(200,200,200)
        Lighting.Brightness = 3
        Lighting.OutdoorAmbient = Color3.fromRGB(200,200,200)
        Lighting.ClockTime = 12
    else
        Lighting.Ambient = Color3.fromRGB(70,70,70)
        Lighting.Brightness = 1
        Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
    end
end)
makeToggle(visualPage, "No Fog", false, function(v)
    if v then
        Lighting.FogEnd = 1e10
        Lighting.FogStart = 1e10
    else
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
    end
end)
makeSlider(visualPage, "Camera FOV", 70, 120, 70, function(v)
    Camera.FieldOfView = v
end)

-- ESP implementation
local espCache = {}
local function createESP(plr)
    if plr == LocalPlayer then return end
    if espCache[plr] then return end
    local char = plr.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local hl = Instance.new("Highlight")
    hl.Name = "PopkaESP"
    hl.FillColor = Color3.fromRGB(255, 100, 150)
    hl.FillTransparency = 0.7
    hl.OutlineColor = Color3.fromRGB(255, 100, 150)
    hl.OutlineTransparency = 0
    hl.Adornee = char
    hl.Parent = char

    local bb = Instance.new("BillboardGui")
    bb.Name = "PopkaNametag"
    bb.Size = UDim2.new(0, 120, 0, 50)
    bb.StudsOffset = Vector3.new(0, 3.5, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = char:FindFirstChild("Head")
    bb.Parent = char

    local nl = Instance.new("TextLabel", bb)
    nl.Size = UDim2.new(1, 0, 0.5, 0)
    nl.BackgroundTransparency = 1
    nl.Text = plr.Name
    nl.TextColor3 = Color3.fromRGB(255, 100, 150)
    nl.TextStrokeTransparency = 0
    nl.Font = Enum.Font.GothamBold
    nl.TextSize = 12

    local dl = Instance.new("TextLabel", bb)
    dl.Size = UDim2.new(1, 0, 0.5, 0)
    dl.Position = UDim2.new(0, 0, 0.5, 0)
    dl.BackgroundTransparency = 1
    dl.Text = "0"
    dl.TextColor3 = Color3.fromRGB(255, 255, 255)
    dl.TextStrokeTransparency = 0
    dl.Font = Enum.Font.Gotham
    dl.TextSize = 11

    espCache[plr] = {hl = hl, bb = bb, dist = dl}
end

local function removeESP(plr)
    if espCache[plr] then
        if espCache[plr].hl then espCache[plr].hl:Destroy() end
        if espCache[plr].bb then espCache[plr].bb:Destroy() end
        espCache[plr] = nil
    end
end

for _, plr in ipairs(Players:GetPlayers()) do createESP(plr) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)

-- Fish ESP: highlight fish parts
local fishHighlights = {}
local function updateFishESP()
    for _, h in pairs(fishHighlights) do h:Destroy() end
    fishHighlights = {}

    if not Config.Visual.FishESP then return end

    local function scanModel(m)
        if not m:IsA("Model") then return end
        local name = m.Name:lower()
        if name:find("fish") or name:find("shark") or name:find("whale") then
            local hl = Instance.new("Highlight")
            hl.FillColor = Color3.fromRGB(255, 215, 0)
            hl.FillTransparency = 0.5
            hl.OutlineColor = Color3.fromRGB(255, 215, 0)
            hl.Adornee = m
            hl.Parent = m
            table.insert(fishHighlights, hl)
        end
    end

    for _, obj in pairs(Workspace:GetDescendants()) do
        pcall(scanModel, obj)
    end
end

task.spawn(function()
    while ScreenGui.Parent do
        task.wait(3)
        if Config.Visual.FishESP then updateFishESP() end
    end
end)

--// ============ MISC PAGE ============
local miscPage = Pages["Misc"]

makeSection(miscPage, "QUALITY OF LIFE")
makeToggle(miscPage, "Anti-AFK", true, function(v) Config.Misc.AntiAFK = v end)
makeToggle(miscPage, "Anti-Fling", false, function(v) Config.Misc.AntiFling = v end)
makeToggle(miscPage, "Infinite Yield", false, function(v) Config.Misc.InfiniteYield = v end)
makeToggle(miscPage, "Auto Reconnect", false, function(v) Config.Misc.AutoReconnect = v end)

makeSection(miscPage, "INFO")
makeButton(miscPage, "Print Character Info", function()
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hrp and hum then
            print("[Popka] Pos:", hrp.Position)
            print("[Popka] Health:", hum.Health)
            print("[Popka] Speed:", hum.WalkSpeed)
        end
    end
end)
makeButton(miscPage, "Print Server Info", function()
    print("[Popka] Players:", #Players:GetPlayers())
    print("[Popka] Job ID:", game.JobId)
    print("[Popka] Place ID:", game.PlaceId)
end)

--// ============ CUSTOMIZE PAGE ============
local customizePage = Pages["Customize"]

makeSection(customizePage, "ACCENT COLOR")
local accents = {
    ["Pink"] = Color3.fromRGB(255,100,150),
    ["Cyan"] = Color3.fromRGB(100,220,255),
    ["Lime"] = Color3.fromRGB(150,255,100),
    ["Orange"] = Color3.fromRGB(255,160,60),
    ["Purple"] = Color3.fromRGB(180,120,255),
    ["Red"] = Color3.fromRGB(240,70,70),
    ["Gold"] = Color3.fromRGB(255,215,0),
    ["White"] = Color3.fromRGB(240,240,240),
}
for name, color in pairs(accents) do
    makeButton(customizePage, "Accent: " .. name, function()
        Theme.Accent = color
        TitleLabel.TextColor3 = color
        for _, btn in pairs(TabButtons) do
            if btn.BackgroundColor3 ~= Theme.Element then btn.BackgroundColor3 = color end
        end
    end)
end

makeSection(customizePage, "TRANSPARENCY")
makeSlider(customizePage, "Main alpha (%)", 0, 100, 0, function(v)
    Main.BackgroundTransparency = v / 100
end)

makeSection(customizePage, "THEME")
makeButton(customizePage, "Theme: Dark", function()
    Main.BackgroundColor3 = Color3.fromRGB(18,18,22)
    TitleBar.BackgroundColor3 = Color3.fromRGB(26,26,32)
    TitleFix.BackgroundColor3 = Color3.fromRGB(26,26,32)
    TabBar.BackgroundColor3 = Color3.fromRGB(26,26,32)
end)
makeButton(customizePage, "Theme: Black", function()
    Main.BackgroundColor3 = Color3.fromRGB(0,0,0)
    TitleBar.BackgroundColor3 = Color3.fromRGB(8,8,8)
    TitleFix.BackgroundColor3 = Color3.fromRGB(8,8,8)
    TabBar.BackgroundColor3 = Color3.fromRGB(8,8,8)
end)

--// ============ PROFILE PAGE ============
local profilePage = Pages["Profile"]

makeSection(profilePage, "ACCOUNT")
makeInfoRow(profilePage, "Username", LocalPlayer.Name)
makeInfoRow(profilePage, "User ID", LocalPlayer.UserId)
makeInfoRow(profilePage, "Account Age", LocalPlayer.AccountAge .. " days")
makeInfoRow(profilePage, "Place ID", game.PlaceId)

makeSection(profilePage, "TESTER TOOLS")
makeButton(profilePage, "Copy User ID", function()
    if setclipboard then setclipboard(tostring(LocalPlayer.UserId)) end
end)
makeButton(profilePage, "Copy Job ID", function()
    if setclipboard then setclipboard(game.JobId) end
end)
makeButton(profilePage, "Unload Popka Hub", function() ScreenGui:Destroy() end, Theme.Danger)

--// ============ FLY ============
UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    local k = i.KeyCode
    if k == Enum.KeyCode.W then Config.Movement.FlyKeys.W = true end
    if k == Enum.KeyCode.A then Config.Movement.FlyKeys.A = true end
    if k == Enum.KeyCode.S then Config.Movement.FlyKeys.S = true end
    if k == Enum.KeyCode.D then Config.Movement.FlyKeys.D = true end
    if k == Enum.KeyCode.Space then Config.Movement.FlyKeys.Space = true end
    if k == Enum.KeyCode.LeftControl then Config.Movement.FlyKeys.LCtrl = true end
end)
UserInputService.InputEnded:Connect(function(i)
    local k = i.KeyCode
    if k == Enum.KeyCode.W then Config.Movement.FlyKeys.W = false end
    if k == Enum.KeyCode.A then Config.Movement.FlyKeys.A = false end
    if k == Enum.KeyCode.S then Config.Movement.FlyKeys.S = false end
    if k == Enum.KeyCode.D then Config.Movement.FlyKeys.D = false end
    if k == Enum.KeyCode.Space then Config.Movement.FlyKeys.Space = false end
    if k == Enum.KeyCode.LeftControl then Config.Movement.FlyKeys.LCtrl = false end
end)

RunService.Heartbeat:Connect(function()
    if not Config.Movement.FlyEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    hum.PlatformStand = true
    local camCF = Camera.CFrame
    local fk = Config.Movement.FlyKeys
    local move = Vector3.zero
    if fk.W then move = move + camCF.LookVector end
    if fk.S then move = move - camCF.LookVector end
    if fk.A then move = move - camCF.RightVector end
    if fk.D then move = move + camCF.RightVector end
    if fk.Space then move = move + Vector3.new(0,1,0) end
    if fk.LCtrl then move = move - Vector3.new(0,1,0) end
    if move.Magnitude > 0 then
        hrp.CFrame = hrp.CFrame + (move.Unit * Config.Movement.FlySpeed * (1/60))
    end
    hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + camCF.LookVector)
    hrp.Velocity = Vector3.zero
end)

task.spawn(function()
    local was = false
    while ScreenGui.Parent do
        task.wait(0.2)
        if was and not Config.Movement.FlyEnabled then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.PlatformStand = false end
            end
        end
        was = Config.Movement.FlyEnabled
    end
end)

--// ============ LOOPS ============
RunService.Heartbeat:Connect(function()
    if Config.Movement.SpeedEnabled then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = Config.Movement.SpeedValue end
        end
    end
    if Config.Movement.JumpEnabled then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = Config.Movement.JumpValue end
        end
    end
end)

RunService.Stepped:Connect(function()
    if Config.Movement.Noclip then
        local char = LocalPlayer.Character
        if char then
            for _, p in pairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if Config.Movement.InfiniteJump then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end)

-- Click TP
LocalPlayer:GetMouse().Button1Down:Connect(function()
    if Config.Movement.ClickTP then
        local target = LocalPlayer:GetMouse().Hit
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = CFrame.new(target.Position + Vector3.new(0, 3, 0))
        end
    end
end)

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    if Config.Misc.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- Anti-Fling
RunService.Heartbeat:Connect(function()
    if Config.Misc.AntiFling then
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp and hrp.Velocity.Magnitude > 200 then
                hrp.Velocity = Vector3.zero
            end
        end
    end
end)

--// ============ AUTO FISH (FIXED) ============
-- Uses time-based delays + avoids task.wait inside Heartbeat
local autoFish = {
    phase = "idle",
    lastCast = 0,
    castEnd = 0,
    lastReel = 0,
    lastShake = 0,
}

RunService.Heartbeat:Connect(function()
    local want = Config.Fish.AutoFish or Config.Fish.AutoCast or Config.Fish.AutoReel or Config.Fish.AutoShake
    if not want then return end

    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    local now = os.clock()

    if Config.Fish.AutoFish then
        if autoFish.phase == "idle" and now - autoFish.lastCast >= Config.Fish.CastCooldown then
            invoke(Remotes.CastAsync)
            if not Remotes.CastAsync then invoke(Remotes.CastRod) end
            autoFish.phase = "waiting"
            autoFish.castEnd = now + 3
            autoFish.lastCast = now
        elseif autoFish.phase == "waiting" and now >= autoFish.castEnd then
            autoFish.phase = "reeling"
        elseif autoFish.phase == "reeling" and now - autoFish.lastReel >= Config.Fish.ReelCooldown then
            invoke(Remotes.ReelStart)
            autoFish.phase = "finishing"
            autoFish.lastReel = now
        elseif autoFish.phase == "finishing" and now - autoFish.lastReel >= 0.2 then
            fire(Remotes.ReelFinish)
            autoFish.phase = "idle"
        end
        if autoFish.phase == "waiting" and now - autoFish.lastShake >= Config.Fish.ShakeDelay then
            fire(Remotes.LureShake, Vector2.new(math.random(-100,100), math.random(-100,100)))
            autoFish.lastShake = now
        end
    end

    if Config.Fish.AutoCast and not Config.Fish.AutoFish then
        if now - autoFish.lastCast >= Config.Fish.CastCooldown then
            invoke(Remotes.CastAsync)
            if not Remotes.CastAsync then invoke(Remotes.CastRod) end
            autoFish.lastCast = now
        end
    end
    if Config.Fish.AutoReel and not Config.Fish.AutoFish then
        if now - autoFish.lastReel >= Config.Fish.ReelCooldown then
            invoke(Remotes.ReelStart)
            autoFish.lastReel = now
            task.delay(0.2, function()
                fire(Remotes.ReelFinish)
            end)
        end
    end
    if Config.Fish.AutoShake and not Config.Fish.AutoFish then
        if now - autoFish.lastShake >= Config.Fish.ShakeDelay then
            fire(Remotes.LureShake, Vector2.new(math.random(-100,100), math.random(-100,100)))
            autoFish.lastShake = now
        end
    end
end)

--// ============ ESP UPDATE LOOP ============
RunService.RenderStepped:Connect(function()
    for plr, data in pairs(espCache) do
        if not data.hl or not data.hl.Parent then espCache[plr] = nil continue end
        local char = plr.Character
        if char and char:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local dist = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude)
            data.dist.Text = dist .. " studs"
        end
        if data.hl then data.hl.Enabled = Config.Visual.PlayerESP end
        if data.bb then data.bb.Enabled = Config.Visual.Nametags or Config.Visual.PlayerESP end
    end
end)

--// ============ GPS UPDATE ============
RunService.RenderStepped:Connect(function()
    if Config.Teleport.GPSEnabled and Config.Teleport.GPSTarget and Config.Teleport.GPSTarget.Parent then
        gpsGui.Enabled = true
        gpsGui.Adornee = Config.Teleport.GPSTarget
    else
        gpsGui.Enabled = false
    end
end)

--// ============ COLLAPSE ============
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        Main.Size = MINI_SIZE
        ContentWrap.Visible = false
        MinBtn.Text = "+"
    else
        Main.Size = FULL_SIZE
        ContentWrap.Visible = true
        MinBtn.Text = "-"
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

--// ============ INIT ============
switchTab("Fish")
local total, found = 0, 0
for k, v in pairs(Remotes) do
    total = total + 1
    if v then found = found + 1 end
end
print("[Popka Hub v5] Loaded -", LocalPlayer.Name)
print("[Popka Hub v5] Remotes:", found, "/", total)
