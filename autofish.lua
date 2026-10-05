--// ============================================
--//  Popka Hub v3 — Fisch Tester Panel
--//  Fixed: Fly, Cast, Reel, Shake + Auto Fish
--// ============================================

local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local Workspace          = game:GetService("Workspace")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local CoreGui            = game:GetService("CoreGui")
local VirtualUser        = game:GetService("VirtualUser")
local Lighting           = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

--// ============ CONFIG ============
local Config = {
    Fish = {
        AutoCast      = false,
        AutoReel      = false,
        AutoShake     = false,
        AutoFish      = false,   -- all-in-one
        CastCooldown  = 2,
        ReelCooldown  = 2,
        ShakeDelay    = 0.15,
    },
    Misc = {
        SpeedEnabled  = false,
        SpeedValue    = 50,
        FlyEnabled    = false,
        FlySpeed      = 80,
        FlyMethod     = "Velocity", -- "Velocity" or "CFrame"
        NoclipEnabled = false,
        InfiniteJump  = false,
        AntiAFK       = true,
        Fullbright    = false,
        ClickTP       = false,
    },
    Customize = {
        Accent        = Color3.fromRGB(255, 100, 150),
        Transparency  = 0,
    },
    Profile = {
        TestMode = false,
    }
}

--// ============ REMOTES ============
local Net
do
    local packages = ReplicatedStorage:FindFirstChild("packages")
    if packages then Net = packages:FindFirstChild("Net") end
    if not Net then
        local p = ReplicatedStorage:WaitForChild("packages", 5)
        if p then Net = p:WaitForChild("Net", 5) end
    end
end

local function R(name)
    if not Net then return nil end
    return Net:FindFirstChild(name)
end

local rodEvents
do
    local shared_ = ReplicatedStorage:FindFirstChild("shared")
    local mods = shared_ and shared_:FindFirstChild("modules")
    local fishing = mods and mods:FindFirstChild("fishing")
    local rodres = fishing and fishing:FindFirstChild("rodresources")
    rodEvents = rodres and rodres:FindFirstChild("events")
end

local Remotes = {
    CastRod       = R("RF/FishingRod/Cast"),
    CastAsync     = rodEvents and rodEvents:FindFirstChild("castAsync"),
    CatchFinish   = rodEvents and rodEvents:FindFirstChild("catchfinish"),
    HandleBobber  = rodEvents and rodEvents:FindFirstChild("handlebobber"),
    BreakBobber   = rodEvents and rodEvents:FindFirstChild("breakbobber"),
    ResetRod      = rodEvents and rodEvents:FindFirstChild("reset"),
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
local function safeParent(gui)
    local ok = pcall(function() gui.Parent = CoreGui end)
    if not ok or gui.Parent == nil then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

local old = CoreGui:FindFirstChild("PopkaHub")
if old then old:Destroy() end
local old2 = LocalPlayer.PlayerGui:FindFirstChild("PopkaHub")
if old2 then old2:Destroy() end

--// ============ THEME ============
local Theme = {
    Bg        = Color3.fromRGB(18, 18, 22),
    Panel     = Color3.fromRGB(26, 26, 32),
    Element   = Color3.fromRGB(36, 36, 44),
    Accent    = Config.Customize.Accent,
    Text      = Color3.fromRGB(235, 235, 240),
    Subtext   = Color3.fromRGB(150, 150, 165),
    ToggleOff = Color3.fromRGB(55, 55, 65),
    Danger    = Color3.fromRGB(230, 80, 80),
}

--// ============ GUI ============
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PopkaHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
safeParent(ScreenGui)

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 520, 0, 400)
Main.Position = UDim2.new(0.5, -260, 0.5, -200)
Main.BackgroundColor3 = Theme.Bg
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
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
TitleLabel.Text = "Popka Hub v3  |  Fisch Tester"
TitleLabel.TextColor3 = Theme.Accent
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 15
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- COLLAPSE BUTTON (fixed)
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

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -20, 0, 32)
TabBar.Position = UDim2.new(0, 10, 0, 48)
TabBar.BackgroundColor3 = Theme.Panel
TabBar.BorderSizePixel = 0
TabBar.Parent = Main
Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 8)

local TabLayout = Instance.new("UIListLayout", TabBar)
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0, 4)
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, -20, 1, -100)
TabContainer.Position = UDim2.new(0, 10, 0, 90)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = Main

local Pages = {}
local TabButtons = {}
local TabOrder = {"Fish", "Misc", "Customize", "Profile"}

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
    tb.Size = UDim2.new(0, 80, 0, 24)
    tb.BackgroundColor3 = Theme.Element
    tb.BorderSizePixel = 0
    tb.Text = name
    tb.TextColor3 = Theme.Subtext
    tb.Font = Enum.Font.GothamMedium
    tb.TextSize = 12
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

local function makeStatus(parent, text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Theme.Subtext
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent
    return lbl
end

--// ============ FISH PAGE ============
local fishPage = Pages["Fish"]

makeSection(fishPage, "AUTO FISH")
makeToggle(fishPage, "Auto Fish (all-in-one)", false, function(v) 
    Config.Fish.AutoFish = v
    if v then print("[Popka] Auto Fish ON") else print("[Popka] Auto Fish OFF") end
end)
makeToggle(fishPage, "Auto Cast", false, function(v) Config.Fish.AutoCast = v end)
makeToggle(fishPage, "Auto Reel", false, function(v) Config.Fish.AutoReel = v end)
makeToggle(fishPage, "Auto Shake", false, function(v) Config.Fish.AutoShake = v end)

makeSection(fishPage, "TIMING")
makeSlider(fishPage, "Cast Cooldown (s)", 1, 10, 2, function(v) Config.Fish.CastCooldown = v end)
makeSlider(fishPage, "Reel Cooldown (s)", 1, 10, 2, function(v) Config.Fish.ReelCooldown = v end)
makeSlider(fishPage, "Shake Delay (ms)", 50, 500, 150, function(v) Config.Fish.ShakeDelay = v / 1000 end)

makeSection(fishPage, "MANUAL ACTIONS")
makeButton(fishPage, "Cast Rod", function()
    local ok, err = invoke(Remotes.CastAsync)
    if not ok or not Remotes.CastAsync then
        ok, err = invoke(Remotes.CastRod)
    end
    print("[Popka] Cast:", ok, err)
end)
makeButton(fishPage, "Start Reel", function()
    local ok, err = invoke(Remotes.ReelStart)
    print("[Popka] ReelStart:", ok, err)
end)
makeButton(fishPage, "Finish Reel", function()
    local ok, err = fire(Remotes.ReelFinish)
    print("[Popka] ReelFinish:", ok, err)
end)
makeButton(fishPage, "Trigger Catch", function()
    local ok, err = fire(Remotes.CatchFinish)
    print("[Popka] CatchFinish:", ok, err)
end)

makeSection(fishPage, "MINIGAMES")
makeButton(fishPage, "Lure Shake (once)", function()
    fire(Remotes.LureShake, Vector2.new(math.random(-100,100), math.random(-100,100)))
end)
makeButton(fishPage, "Stab Start", function()
    invoke(Remotes.StabStart)
end)
makeButton(fishPage, "Stab Finish", function()
    fire(Remotes.StabFinish)
end)

makeSection(fishPage, "ROD")
makeButton(fishPage, "Reset Rod", function() fire(Remotes.ResetRod) end)
makeButton(fishPage, "Break Bobber", function() fire(Remotes.BreakBobber) end)

makeSection(fishPage, "TELEPORT")
makeButton(fishPage, "Teleport to Spawn", function()
    local ok, pos = invoke(Remotes.GetSpawn)
    if ok and pos then fire(Remotes.RequestTp, pos) end
end)
makeButton(fishPage, "Return to Surface", function() fire(Remotes.ReturnSurface) end)

--// ============ MISC PAGE ============
local miscPage = Pages["Misc"]

makeSection(miscPage, "MOVEMENT")
makeToggle(miscPage, "Speed Hack", false, function(v)
    Config.Misc.SpeedEnabled = v
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v and Config.Misc.SpeedValue or 16 end
    end
end)
makeSlider(miscPage, "Speed Value", 16, 300, 50, function(v)
    Config.Misc.SpeedValue = v
    if Config.Misc.SpeedEnabled then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = v end
        end
    end
end)
makeToggle(miscPage, "Noclip", false, function(v) Config.Misc.NoclipEnabled = v end)
makeToggle(miscPage, "Infinite Jump", false, function(v) Config.Misc.InfiniteJump = v end)

makeSection(miscPage, "FLY (REBUILT)")
makeToggle(miscPage, "Fly", false, function(v) 
    Config.Misc.FlyEnabled = v
    print("[Popka] Fly:", v)
end)
makeSlider(miscPage, "Fly Speed", 20, 500, 80, function(v) Config.Misc.FlySpeed = v end)

makeSection(miscPage, "VISUAL")
makeToggle(miscPage, "Fullbright", false, function(v)
    Config.Misc.Fullbright = v
    if v then
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.Brightness = 3
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        Lighting.FogEnd = 9e9
        Lighting.ClockTime = 12
    else
        Lighting.Ambient = Color3.fromRGB(70, 70, 70)
        Lighting.Brightness = 1
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        Lighting.FogEnd = 100000
    end
end)

makeSection(miscPage, "OTHER")
makeToggle(miscPage, "Anti-AFK", true, function(v) Config.Misc.AntiAFK = v end)

--// ============ CUSTOMIZE PAGE ============
local customizePage = Pages["Customize"]

makeSection(customizePage, "ACCENT COLOR")

local accentPresets = {
    ["Pink"]    = Color3.fromRGB(255, 100, 150),
    ["Cyan"]    = Color3.fromRGB(100, 220, 255),
    ["Lime"]    = Color3.fromRGB(150, 255, 100),
    ["Orange"]  = Color3.fromRGB(255, 160, 60),
    ["Purple"]  = Color3.fromRGB(180, 120, 255),
    ["Red"]     = Color3.fromRGB(240, 70, 70),
    ["White"]   = Color3.fromRGB(240, 240, 240),
    ["Gold"]    = Color3.fromRGB(255, 215, 0),
}

for name, color in pairs(accentPresets) do
    makeButton(customizePage, "Accent: " .. name, function()
        Theme.Accent = color
        TitleLabel.TextColor3 = color
        for _, btn in pairs(TabButtons) do
            if btn.BackgroundColor3 ~= Theme.Element then
                btn.BackgroundColor3 = color
            end
        end
        print("[Popka] Accent:", name)
    end)
end

makeSection(customizePage, "TRANSPARENCY")
makeSlider(customizePage, "Main alpha (%)", 0, 100, 0, function(v)
    Main.BackgroundTransparency = v / 100
end)
makeSlider(customizePage, "Title alpha (%)", 0, 100, 0, function(v)
    TitleBar.BackgroundTransparency = v / 100
    TitleFix.BackgroundTransparency = v / 100
    TabBar.BackgroundTransparency = v / 100
end)

makeSection(customizePage, "THEME")
makeButton(customizePage, "Theme: Dark", function()
    Theme.Bg = Color3.fromRGB(18, 18, 22)
    Theme.Panel = Color3.fromRGB(26, 26, 32)
    Theme.Element = Color3.fromRGB(36, 36, 44)
    Main.BackgroundColor3 = Theme.Bg
    TitleBar.BackgroundColor3 = Theme.Panel
    TitleFix.BackgroundColor3 = Theme.Panel
    TabBar.BackgroundColor3 = Theme.Panel
end)
makeButton(customizePage, "Theme: Black", function()
    Theme.Bg = Color3.fromRGB(0, 0, 0)
    Theme.Panel = Color3.fromRGB(8, 8, 8)
    Theme.Element = Color3.fromRGB(18, 18, 18)
    Main.BackgroundColor3 = Theme.Bg
    TitleBar.BackgroundColor3 = Theme.Panel
    TitleFix.BackgroundColor3 = Theme.Panel
    TabBar.BackgroundColor3 = Theme.Panel
end)
makeButton(customizePage, "Theme: Navy", function()
    Theme.Bg = Color3.fromRGB(12, 18, 32)
    Theme.Panel = Color3.fromRGB(20, 28, 46)
    Theme.Element = Color3.fromRGB(30, 40, 62)
    Main.BackgroundColor3 = Theme.Bg
    TitleBar.BackgroundColor3 = Theme.Panel
    TitleFix.BackgroundColor3 = Theme.Panel
    TabBar.BackgroundColor3 = Theme.Panel
end)

--// ============ PROFILE PAGE ============
local profilePage = Pages["Profile"]

makeSection(profilePage, "ACCOUNT")
makeInfoRow(profilePage, "Username", LocalPlayer.Name)
makeInfoRow(profilePage, "User ID", LocalPlayer.UserId)
makeInfoRow(profilePage, "Account Age", LocalPlayer.AccountAge .. " days")

makeSection(profilePage, "REMOTES")
local total, found = 0, 0
for k, v in pairs(Remotes) do
    total = total + 1
    if v then found = found + 1 end
end
makeStatus(profilePage, "Resolved: " .. found .. " / " .. total)

makeSection(profilePage, "TESTER")
makeToggle(profilePage, "Test Mode", false, function(v) Config.Profile.TestMode = v end)
makeButton(profilePage, "Copy User ID", function()
    if setclipboard then setclipboard(tostring(LocalPlayer.UserId)) end
end)
makeButton(profilePage, "Dump Remote Status", function()
    for k, v in pairs(Remotes) do
        print("[Popka.Remote]", k, v and "OK" or "MISSING")
    end
end)
makeButton(profilePage, "Unload Popka Hub", function() ScreenGui:Destroy() end, Theme.Danger)

--// ============ FLY (REBUILT — works on most methods) ============
local flyKeys = {W=false, A=false, S=false, D=false, Space=false, LCtrl=false}

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    local k = input.KeyCode
    if k == Enum.KeyCode.W then flyKeys.W = true end
    if k == Enum.KeyCode.A then flyKeys.A = true end
    if k == Enum.KeyCode.S then flyKeys.S = true end
    if k == Enum.KeyCode.D then flyKeys.D = true end
    if k == Enum.KeyCode.Space then flyKeys.Space = true end
    if k == Enum.KeyCode.LeftControl then flyKeys.LCtrl = true end
end)

UserInputService.InputEnded:Connect(function(input)
    local k = input.KeyCode
    if k == Enum.KeyCode.W then flyKeys.W = false end
    if k == Enum.KeyCode.A then flyKeys.A = false end
    if k == Enum.KeyCode.S then flyKeys.S = false end
    if k == Enum.KeyCode.D then flyKeys.D = false end
    if k == Enum.KeyCode.Space then flyKeys.Space = false end
    if k == Enum.KeyCode.LeftControl then flyKeys.LCtrl = false end
end)

-- Use Velocity method: works with PlatformStand
local function getRoot()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hrp, hum
end

RunService.Heartbeat:Connect(function()
    if not Config.Misc.FlyEnabled then return end
    local hrp, hum = getRoot()
    if not hrp or not hum then return end

    -- Disable default movement
    hum.PlatformStand = true
    hrp.Velocity = Vector3.zero

    -- Direction from camera
    local camCF = Camera.CFrame
    local move = Vector3.zero
    if flyKeys.W then move = move + camCF.LookVector end
    if flyKeys.S then move = move - camCF.LookVector end
    if flyKeys.A then move = move - camCF.RightVector end
    if flyKeys.D then move = move + camCF.RightVector end
    if flyKeys.Space then move = move + Vector3.new(0,1,0) end
    if flyKeys.LCtrl then move = move - Vector3.new(0,1,0) end

    if move.Magnitude > 0 then
        hrp.CFrame = hrp.CFrame + (move.Unit * Config.Misc.FlySpeed * (1/60))
    end
    hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + camCF.LookVector)
end)

-- Restore normal state when fly off
task.spawn(function()
    local wasFly = false
    while ScreenGui.Parent do
        task.wait(0.2)
        if wasFly and not Config.Misc.FlyEnabled then
            local hrp, hum = getRoot()
            if hum then hum.PlatformStand = false end
        end
        wasFly = Config.Misc.FlyEnabled
    end
end)

--// ============ OTHER FUNCTIONS ============

-- Speed loop
RunService.Heartbeat:Connect(function()
    if Config.Misc.SpeedEnabled then        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = Config.Misc.SpeedValue end
        end
    end
end)

-- Noclip loop
RunService.Stepped:Connect(function()
    if Config.Misc.NoclipEnabled then
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end)

-- Infinite jump
UserInputService.JumpRequest:Connect(function()
    if Config.Misc.InfiniteJump then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
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

--// ============ AUTO FISH STATE MACHINE ============
local autoState = {
    phase = "idle", -- idle -> casting -> casted -> reeling -> shaking
    lastCast = 0,
    lastReel = 0,
    lastShake = 0,
    castTimeout = 0,
}

local function autoCast()
    if Remotes.CastAsync then
        return invoke(Remotes.CastAsync)
    elseif Remotes.CastRod then
        return invoke(Remotes.CastRod)
    end
    return false
end

local function autoReel()
    invoke(Remotes.ReelStart)
    task.wait(0.2)
    fire(Remotes.ReelFinish)
end

local function autoShake()
    if Remotes.LureShake then
        fire(Remotes.LureShake, Vector2.new(math.random(-100, 100), math.random(-100, 100)))
    end
end

RunService.Heartbeat:Connect(function()
    local shouldRun = Config.Fish.AutoFish or Config.Fish.AutoCast or Config.Fish.AutoReel or Config.Fish.AutoShake
    if not shouldRun then return end

    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    local now = os.clock()

    -- Auto Fish all-in-one
    if Config.Fish.AutoFish then
        if autoState.phase == "idle" and now - autoState.lastCast >= Config.Fish.CastCooldown then
            autoCast()
            autoState.phase = "casting"
            autoState.castTimeout = now + 3
            autoState.lastCast = now
            print("[Popka.Auto] Casting...")
        elseif autoState.phase == "casting" and now >= autoState.castTimeout then
            -- Wait a moment for fish to bite, then reel
            autoState.phase = "reeling"
            autoState.lastReel = now
        elseif autoState.phase == "reeling" and now - autoState.lastReel >= Config.Fish.ReelCooldown then
            autoReel()
            autoState.phase = "idle"
            print("[Popka.Auto] Reeled")
        end

        -- Shake constantly during cast
        if autoState.phase == "casting" and now - autoState.lastShake >= Config.Fish.ShakeDelay then
            autoShake()
            autoState.lastShake = now
        end
    end

    -- Standalone toggles
    if Config.Fish.AutoCast and not Config.Fish.AutoFish then
        if now - autoState.lastCast >= Config.Fish.CastCooldown then
            autoCast()
            autoState.lastCast = now
        end
    end
    if Config.Fish.AutoReel and not Config.Fish.AutoFish then
        if now - autoState.lastReel >= Config.Fish.ReelCooldown then
            autoReel()
            autoState.lastReel = now
        end
    end
    if Config.Fish.AutoShake and not Config.Fish.AutoFish then
        if now - autoState.lastShake >= Config.Fish.ShakeDelay then
            autoShake()
            autoState.lastShake = now
        end
    end
end)

--// ============ COLLAPSE / CLOSE ============
local originalSize = UDim2.new(0, 520, 0, 400)
local miniSize = UDim2.new(0, 520, 0, 40)
local minimized = false

MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        Main.Size = miniSize
        MinBtn.Text = "+"
    else
        Main.Size = originalSize
        MinBtn.Text = "-"
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

--// ============ INIT ============
switchTab("Fish")
print("[Popka Hub v3] Loaded - User:", LocalPlayer.Name)
print("[Popka Hub v3] Remotes resolved:", found, "/", total)
print("[Popka Hub v3] Fly method: Heartbeat CF (PlatformStand)")
