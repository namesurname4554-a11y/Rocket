--// ============================================
--//  Popka Hub v4 — Fisch Tester
--//  Fixed: Collapse, Arg capture, More tabs
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
        AutoFish      = false,
        CastCooldown  = 2,
        ReelCooldown  = 2,
        ShakeDelay    = 0.15,
        CastArgs      = {},  -- captured args
        ReelArgs      = {},
        ShakeArgs     = {},
    },
    Misc = {
        SpeedEnabled  = false,
        SpeedValue    = 50,
        FlyEnabled    = false,
        FlySpeed      = 80,
        NoclipEnabled = false,
        InfiniteJump  = false,
        AntiAFK       = true,
        Fullbright    = false,
        ClickTP       = false,
    },
    Visual = {
        ESP = false,
        Tracers = false,
        Nametags = false,
    },
    Logger = {
        Enabled = false,
    },
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
    CastAsync    = rodEvents and rodEvents:FindFirstChild("castAsync"),
    CatchFinish  = rodEvents and rodEvents:FindFirstChild("catchfinish"),
    HandleBobber = rodEvents and rodEvents:FindFirstChild("handlebobber"),
    BreakBobber  = rodEvents and rodEvents:FindFirstChild("breakbobber"),
    ResetRod     = rodEvents and rodEvents:FindFirstChild("reset"),
    CastRod      = R("RF/FishingRod/Cast"),
    ReelStart    = R("RF/Reel/Start"),
    ReelFinish   = R("RE/Reel/Finish"),
    ReelAbort    = R("RE/Reel/Abort"),
    LureStart    = R("RF/LureShake/Start"),
    LureStop     = R("RE/LureShake/Stop"),
    LureShake    = R("RE/LureShake/Shake"),
    StabStart    = R("RF/Stab/Start"),
    StabFinish   = R("RE/Stab/Finish"),
    StabAbort    = R("RE/Stab/Abort"),
    RequestTp    = R("RE/RequestTeleport"),
    GetSpawn     = R("RF/GetSpawnPosition"),
    GetZone      = R("RF/GetZone"),
    DeepTp       = R("RF/Deep/Teleport"),
    MarianasTp   = R("RF/MarianasVeil/Teleport"),
    ReturnSurface= R("RE/ReturnToSurface"),
    Equip        = R("RE/Backpack/Equip"),
    Favorite     = R("RE/Backpack/Favourite"),
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

--// ============ ARG LOGGER ============
-- Hooks remotes so we can see what args the game actually sends
local hookEnabled = false
local hookConnections = {}
local logBuffer = {}

local function setupHook()
    if hookEnabled then return end
    hookEnabled = true

    -- Log which remotes we can hook
    local targets = {}
    for name, r in pairs(Remotes) do
        if r then targets[r] = name end
    end

    -- Hook via metatable (if getrawmetatable exists)
    if getrawmetatable and setreadonly and hookmetamethod then
        local mt = getrawmetatable(game)
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local name = targets[self]
            if name and (method == "FireServer" or method == "InvokeServer") then
                local args = {...}
                local argStr = ""
                for i, a in ipairs(args) do
                    argStr = argStr .. tostring(a) .. (i < #args and ", " or "")
                end
                local line = "[HOOK] " .. name .. ":" .. method .. "(" .. argStr .. ")"
                table.insert(logBuffer, line)
                if #logBuffer > 50 then table.remove(logBuffer, 1) end
                print(line)
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
        print("[Popka Hook] Installed via getrawmetatable")
    elseif hookfunction and getnamecallmethod then
        print("[Popka Hook] getrawmetatable not available — using alternative")
        -- Some executors only support hookmetamethod
        local ok = pcall(function()
            local mt = getrawmetatable(game)
            local old = mt.__namecall
            mt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod()
                local name = targets[self]
                if name then
                    local args = {...}
                    local argStr = ""
                    for i, a in ipairs(args) do
                        argStr = argStr .. tostring(a) .. (i < #args and ", " or "")
                    end
                    print("[HOOK]", name, method, argStr)
                end
                return old(self, ...)
            end)
        end)
        if not ok then print("[Popka Hook] Failed to install hook") end
    else
        print("[Popka Hook] Executor doesn't support metatable hooks")
    end
end

--// ============ CLEANUP ============
local old = CoreGui:FindFirstChild("PopkaHub")
if old then old:Destroy() end
local old2 = LocalPlayer.PlayerGui:FindFirstChild("PopkaHub")
if old2 then old2:Destroy() end

--// ============ THEME ============
local Theme = {
    Bg        = Color3.fromRGB(18, 18, 22),
    Panel     = Color3.fromRGB(26, 26, 32),
    Element   = Color3.fromRGB(36, 36, 44),
    Accent    = Color3.fromRGB(255, 100, 150),
    Text      = Color3.fromRGB(235, 235, 240),
    Subtext   = Color3.fromRGB(150, 150, 165),
    ToggleOff = Color3.fromRGB(55, 55, 65),
    Danger    = Color3.fromRGB(230, 80, 80),
}

--// ============ GUI ============
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PopkaHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local FULL_SIZE  = UDim2.new(0, 540, 0, 420)
local MINI_SIZE  = UDim2.new(0, 540, 0, 40)

local Main = Instance.new("Frame")
Main.Size = FULL_SIZE
Main.Position = UDim2.new(0.5, -270, 0.5, -210)
Main.BackgroundColor3 = Theme.Bg
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.ClipsDescendants = true   -- IMPORTANT for collapse
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = Color3.fromRGB(45, 45, 55)

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
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
TitleLabel.Text = "Popka Hub v4  |  Fisch Tester"
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

-- Content wrapper (this is what we hide on collapse)
local ContentWrap = Instance.new("Frame")
ContentWrap.Name = "ContentWrap"
ContentWrap.Size = UDim2.new(1, 0, 1, -40)
ContentWrap.Position = UDim2.new(0, 0, 0, 40)
ContentWrap.BackgroundTransparency = 1
ContentWrap.Visible = true
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
TabLayout.Padding = UDim.new(0, 4)
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, -20, 1, -58)
TabContainer.Position = UDim2.new(0, 10, 0, 48)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = ContentWrap

local Pages = {}
local TabButtons = {}
local TabOrder = {"Fish", "Misc", "Visual", "Customize", "Logger", "Profile"}

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
    tb.Size = UDim2.new(0, 78, 0, 24)
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

makeSection(fishPage, "AUTO FISH")
makeToggle(fishPage, "Auto Fish (all-in-one)", false, function(v) Config.Fish.AutoFish = v end)
makeSlider(fishPage, "Cast Cooldown", 1, 10, 2, function(v) Config.Fish.CastCooldown = v end)
makeSlider(fishPage, "Shake Delay (ms)", 50, 500, 150, function(v) Config.Fish.ShakeDelay = v / 1000 end)

makeSection(fishPage, "MANUAL (with default args)")
makeButton(fishPage, "Cast (no args)", function()
    local ok, err = invoke(Remotes.CastAsync)
    print("[Popka] CastAsync:", ok, err)
end)
makeButton(fishPage, "Reel Start", function()
    local ok, err = invoke(Remotes.ReelStart)
    print("[Popka] ReelStart:", ok, err)
end)
makeButton(fishPage, "Reel Finish", function()
    local ok, err = fire(Remotes.ReelFinish)
    print("[Popka] ReelFinish:", ok, err)
end)
makeButton(fishPage, "Shake (random)", function()
    fire(Remotes.LureShake, Vector2.new(math.random(-100,100), math.random(-100,100)))
end)

makeSection(fishPage, "MANUAL (with captured args)")
makeButton(fishPage, "Replay last Cast", function()
    if #Config.Fish.CastArgs > 0 then
        invoke(Remotes.CastAsync, table.unpack(Config.Fish.CastArgs))
    else
        print("[Popka] No captured Cast args — enable Logger and cast manually first")
    end
end)
makeButton(fishPage, "Replay last Shake", function()
    if #Config.Fish.ShakeArgs > 0 then
        fire(Remotes.LureShake, table.unpack(Config.Fish.ShakeArgs))
    else
        print("[Popka] No captured Shake args")
    end
end)

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
makeSlider(miscPage, "Speed Value", 16, 300, 50, function(v) Config.Misc.SpeedValue = v end)
makeToggle(miscPage, "Noclip", false, function(v) Config.Misc.NoclipEnabled = v end)
makeToggle(miscPage, "Infinite Jump", false, function(v) Config.Misc.InfiniteJump = v end)

makeSection(miscPage, "FLY (v4 method)")
makeToggle(miscPage, "Fly", false, function(v) Config.Misc.FlyEnabled = v end)
makeSlider(miscPage, "Fly Speed", 20, 500, 80, function(v) Config.Misc.FlySpeed = v end)

makeSection(miscPage, "MISC")
makeToggle(miscPage, "Fullbright", false, function(v)
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
makeToggle(miscPage, "Anti-AFK", true, function(v) Config.Misc.AntiAFK = v end)

--// ============ VISUAL PAGE (NEW) ============
local visualPage = Pages["Visual"]

makeSection(visualPage, "PLAYER ESP")
makeToggle(visualPage, "ESP Boxes", false, function(v) Config.Visual.ESP = v end)
makeToggle(visualPage, "Nametags", false, function(v) Config.Visual.Nametags = v end)
makeToggle(visualPage, "Tracers", false, function(v) Config.Visual.Tracers = v end)

-- ESP state
local espCache = {}
local tracerCache = {}

local function createESP(plr)
    if plr == LocalPlayer then return end
    if espCache[plr] then return end

    local char = plr.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PopkaESP"
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = char:FindFirstChild("Head") or char.HumanoidRootPart
    billboard.Parent = char

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, 0, 0.5, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = plr.Name
    nameLbl.TextColor3 = Color3.fromRGB(255, 100, 150)
    nameLbl.TextStrokeTransparency = 0
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 12
    nameLbl.Parent = billboard

    local distLbl = Instance.new("TextLabel")
    distLbl.Size = UDim2.new(1, 0, 0.5, 0)
    distLbl.Position = UDim2.new(0, 0, 0.5, 0)
    distLbl.BackgroundTransparency = 1
    distLbl.Text = "0 studs"
    distLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    distLbl.TextStrokeTransparency = 0
    distLbl.Font = Enum.Font.Gotham
    distLbl.TextSize = 11
    distLbl.Parent = billboard

    espCache[plr] = {gui = billboard, distLbl = distLbl}
end

local function removeESP(plr)
    if espCache[plr] then
        if espCache[plr].gui then espCache[plr].gui:Destroy() end
        espCache[plr] = nil
    end
end

for _, plr in ipairs(Players:GetPlayers()) do createESP(plr) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)

RunService.RenderStepped:Connect(function()
    for plr, data in pairs(espCache) do
        if not data.gui or not data.gui.Parent then
            espCache[plr] = nil
            continue
        end
        data.gui.Enabled = Config.Visual.ESP or Config.Visual.Nametags
        local char = plr.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local dist = math.floor((Camera.CFrame.Position - char.HumanoidRootPart.Position).Magnitude)
            data.distLbl.Text = dist .. " studs"
        end
    end
end)

--// ============ CUSTOMIZE PAGE ============
local customizePage = Pages["Customize"]

makeSection(customizePage, "ACCENT")
local presets = {
    ["Pink"] = Color3.fromRGB(255,100,150),
    ["Cyan"] = Color3.fromRGB(100,220,255),
    ["Lime"] = Color3.fromRGB(150,255,100),
    ["Orange"] = Color3.fromRGB(255,160,60),
    ["Purple"] = Color3.fromRGB(180,120,255),
    ["Red"] = Color3.fromRGB(240,70,70),
}
for name, color in pairs(presets) do
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

--// ============ LOGGER PAGE (NEW) ============
local loggerPage = Pages["Logger"]

makeSection(loggerPage, "ARGUMENT CAPTURE")
makeToggle(loggerPage, "Enable Hook", false, function(v)
    if v then
        setupHook()
        print("[Popka] Hook enabled")
    else
        print("[Popka] Hook disabled (restart script to fully unhook)")
    end
end)

makeSection(loggerPage, "INSTRUCTIONS")
local infoLbl = Instance.new("TextLabel")
infoLbl.Size = UDim2.new(1, 0, 0, 90)
infoLbl.BackgroundColor3 = Theme.Element
infoLbl.BorderSizePixel = 0
infoLbl.Text = "1. Enable Hook\n2. Play Fisch normally (cast, reel, shake)\n3. Watch the console for [HOOK] lines\n4. Those show the args the game sends\n5. Report them to update the panel"
infoLbl.TextColor3 = Theme.Text
infoLbl.Font = Enum.Font.Gotham
infoLbl.TextSize = 11
infoLbl.TextWrapped = true
infoLbl.Parent = loggerPage
Instance.new("UICorner", infoLbl).CornerRadius = UDim.new(0, 6)

makeButton(loggerPage, "Print Captured Log", function()
    for _, line in ipairs(logBuffer) do print(line) end
end)

makeButton(loggerPage, "Clear Log", function()
    logBuffer = {}
    print("[Popka] Log cleared")
end)

--// ============ PROFILE PAGE ============
local profilePage = Pages["Profile"]

makeSection(profilePage, "ACCOUNT")
makeInfoRow(profilePage, "Username", LocalPlayer.Name)
makeInfoRow(profilePage, "User ID", LocalPlayer.UserId)
makeInfoRow(profilePage, "Account Age", LocalPlayer.AccountAge .. " days")

makeSection(profilePage, "TOOLS")
makeButton(profilePage, "Copy User ID", function()
    if setclipboard then setclipboard(tostring(LocalPlayer.UserId)) end
end)
makeButton(profilePage, "Unload", function() ScreenGui:Destroy() end, Theme.Danger)

--// ============ FLY v4 — Direct CFrame ============
local flyKeys = {W=false,A=false,S=false,D=false,Space=false,LCtrl=false}

UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    local k = i.KeyCode
    if k == Enum.KeyCode.W then flyKeys.W=true end
    if k == Enum.KeyCode.A then flyKeys.A=true end
    if k == Enum.KeyCode.S then flyKeys.S=true end
    if k == Enum.KeyCode.D then flyKeys.D=true end
    if k == Enum.KeyCode.Space then flyKeys.Space=true end
    if k == Enum.KeyCode.LeftControl then flyKeys.LCtrl=true end
end)
UserInputService.InputEnded:Connect(function(i)
    local k = i.KeyCode
    if k == Enum.KeyCode.W then flyKeys.W=false end
    if k == Enum.KeyCode.A then flyKeys.A=false end
    if k == Enum.KeyCode.S then flyKeys.S=false end
    if k == Enum.KeyCode.D then flyKeys.D=false end
    if k == Enum.KeyCode.Space then flyKeys.Space=false end
    if k == Enum.KeyCode.LeftControl then flyKeys.LCtrl=false end
end)

RunService.Heartbeat:Connect(function()
    if not Config.Misc.FlyEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    hum.PlatformStand = true

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
    hrp.Velocity = Vector3.zero
end)

task.spawn(function()
    local was = false
    while ScreenGui.Parent do
        task.wait(0.2)
        if was and not Config.Misc.FlyEnabled then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.PlatformStand = false end
            end
        end
        was = Config.Misc.FlyEnabled
    end
end)

--// ============ LOOPS ============
RunService.Heartbeat:Connect(function()
    if Config.Misc.SpeedEnabled then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = Config.Misc.SpeedValue end
        end
    end
end)

RunService.Stepped:Connect(function()
    if Config.Misc.NoclipEnabled then
        local char = LocalPlayer.Character
        if char then
            for _, p in pairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if Config.Misc.InfiniteJump then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end)

LocalPlayer.Idled:Connect(function()
    if Config.Misc.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- Auto Fish state machine
local autoState = { phase = "idle", lastCast = 0, castTimeout = 0, lastShake = 0 }

RunService.Heartbeat:Connect(function()
    if not Config.Fish.AutoFish then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    local now = os.clock()

    if autoState.phase == "idle" and now - autoState.lastCast >= Config.Fish.CastCooldown then
        invoke(Remotes.CastAsync)
        autoState.phase = "casting"
        autoState.castTimeout = now + 3
        autoState.lastCast = now
    elseif autoState.phase == "casting" and now >= autoState.castTimeout then
        autoState.phase = "reeling"
    elseif autoState.phase == "reeling" then
        invoke(Remotes.ReelStart)
        task.wait(0.2)
        fire(Remotes.ReelFinish)
        autoState.phase = "idle"
    end

    if autoState.phase == "casting" and now - autoState.lastShake >= Config.Fish.ShakeDelay then
        fire(Remotes.LureShake, Vector2.new(math.random(-100,100), math.random(-100,100)))
        autoState.lastShake = now
    end
end)

--// ============ COLLAPSE (FIXED) ============
local minimized = false

MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        Main.Size = MINI_SIZE
        ContentWrap.Visible = false   -- HIDE content
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
print("[Popka Hub v4] Loaded -", LocalPlayer.Name)
print("[Popka Hub v4] Remotes:", found, "/", total)
