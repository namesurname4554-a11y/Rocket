--// ============================================
--//  Popka Hub — Anti-Cheat Tester Panel
--//  For Fisch (authorized testing only)
--//  Fixed: vararg bug, CoreGui -> PlayerGui
--// ============================================

local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local Workspace          = game:GetService("Workspace")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local CoreGui            = game:GetService("CoreGui")
local VirtualUser        = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

--// ============ CONFIG ============
local Config = {
    Fish = {
        AutoCast      = false,
        AutoReel      = false,
        PerfectCast   = false,
        CastCooldown  = 2,
        ReelCooldown  = 2,
        AutoEquipRod  = false,
    },
    Misc = {
        SpeedEnabled  = false,
        SpeedValue    = 50,
        FlyEnabled    = false,
        FlySpeed      = 50,
        NoclipEnabled = false,
        InfiniteJump  = false,
        AntiAFK       = true,
    },
    Profile = {
        TestMode = false,
    }
}

--// ============ REMOTE RESOLUTION ============
local Net
do
    local packages = ReplicatedStorage:FindFirstChild("packages")
    if packages then
        Net = packages:FindFirstChild("Net")
    end
    if not Net then
        local p = ReplicatedStorage:WaitForChild("packages", 5)
        if p then Net = p:WaitForChild("Net", 5) end
    end
end

local function R(name)
    if not Net then return nil end
    return Net:FindFirstChild(name)
end

local shared_ = ReplicatedStorage:FindFirstChild("shared")
local rodEvents
if shared_ then
    local mods = shared_:FindFirstChild("modules")
    if mods then
        local fishing = mods:FindFirstChild("fishing")
        if fishing then
            local rodres = fishing:FindFirstChild("rodresources")
            if rodres then rodEvents = rodres:FindFirstChild("events") end
        end
    end
end

local Remotes = {
    Cast          = R("RF/FishingRod/Cast"),
    ReelStart     = R("RF/Reel/Start"),
    ReelFinish    = R("RE/Reel/Finish"),
    ReelAbort     = R("RE/Reel/Abort"),
    CastAsync     = rodEvents and rodEvents:FindFirstChild("castAsync"),
    CatchFinish   = rodEvents and rodEvents:FindFirstChild("catchfinish"),
    RequestTp     = R("RE/RequestTeleport"),
    GetSpawn      = R("RF/GetSpawnPosition"),
    GetZone       = R("RF/GetZone"),
    DeepTp        = R("RF/Deep/Teleport"),
    MarianasTp    = R("RF/MarianasVeil/Teleport"),
    Equip         = R("RE/Backpack/Equip"),
    Favorite      = R("RE/Backpack/Favourite"),
    ReturnSurface = R("RE/ReturnToSurface"),
}

-- Safe fire helpers (VARARG FIXED)
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
    -- Try CoreGui first, fall back to PlayerGui
    local ok = pcall(function() gui.Parent = CoreGui end)
    if not ok or gui.Parent == nil then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

local existing = CoreGui:FindFirstChild("PopkaHub") or LocalPlayer.PlayerGui:FindFirstChild("PopkaHub")
if existing then existing:Destroy() end

--// ============ THEME ============
local Theme = {
    Bg        = Color3.fromRGB(18, 18, 22),
    Panel     = Color3.fromRGB(26, 26, 32),
    Element   = Color3.fromRGB(36, 36, 44),
    ElementHi = Color3.fromRGB(46, 46, 56),
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
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
safeParent(ScreenGui)

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 500, 0, 360)
Main.Position = UDim2.new(0.5, -250, 0.5, -180)
Main.BackgroundColor3 = Theme.Bg
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = Color3.fromRGB(45, 45, 55)
MainStroke.Thickness = 1

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
TitleLabel.Text = "Popka Hub  |  Fisch Tester"
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
local TabOrder = {"Fish", "Misc", "Profile"}

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
    tb.Size = UDim2.new(0, 100, 0, 24)
    tb.BackgroundColor3 = Theme.Element
    tb.BorderSizePixel = 0
    tb.Text = name
    tb.TextColor3 = Theme.Subtext
    tb.Font = Enum.Font.GothamMedium
    tb.TextSize = 13
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

makeSection(fishPage, "AUTO FARM")
makeToggle(fishPage, "Auto Cast", false, function(v) Config.Fish.AutoCast = v end)
makeToggle(fishPage, "Auto Reel", false, function(v) Config.Fish.AutoReel = v end)
makeSlider(fishPage, "Cast Cooldown (s)", 1, 10, 2, function(v) Config.Fish.CastCooldown = v end)
makeSlider(fishPage, "Reel Cooldown (s)", 1, 10, 2, function(v) Config.Fish.ReelCooldown = v end)

makeSection(fishPage, "TEST ACTIONS")
makeButton(fishPage, "Manual Cast", function()
    local ok, err = invoke(Remotes.Cast)
    print("[Popka] Cast:", ok, err)
end)
makeButton(fishPage, "Manual Reel Start", function()
    local ok, err = invoke(Remotes.ReelStart)
    print("[Popka] ReelStart:", ok, err)
end)
makeButton(fishPage, "Manual Reel Finish", function()
    local ok, err = fire(Remotes.ReelFinish)
    print("[Popka] ReelFinish:", ok, err)
end)
makeButton(fishPage, "Abort Reel", function()
    local ok, err = fire(Remotes.ReelAbort)
    print("[Popka] Abort:", ok, err)
end)

makeSection(fishPage, "TELEPORT")
makeButton(fishPage, "Get Spawn Position (log)", function()
    local ok, res = invoke(Remotes.GetSpawn)
    print("[Popka] Spawn:", ok, res)
end)
makeButton(fishPage, "Get Zone (log)", function()
    local ok, res = invoke(Remotes.GetZone)
    print("[Popka] Zone:", ok, res)
end)
makeButton(fishPage, "Request Teleport to Spawn", function()
    local ok, pos = invoke(Remotes.GetSpawn)
    if ok and pos then
        fire(Remotes.RequestTp, pos)
        print("[Popka] Tp to spawn:", pos)
    end
end)
makeButton(fishPage, "Return to Surface", function()
    fire(Remotes.ReturnSurface)
    print("[Popka] Return to surface")
end)

--// ============ MISC PAGE ============
local miscPage = Pages["Misc"]

makeSection(miscPage, "MOVEMENT")
makeToggle(miscPage, "Speed Hack", false, function(v)
    Config.Misc.SpeedEnabled = v
    local char = LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").WalkSpeed = v and Config.Misc.SpeedValue or 16
    end
end)
makeSlider(miscPage, "Speed Value", 16, 300, 50, function(v)
    Config.Misc.SpeedValue = v
    if Config.Misc.SpeedEnabled then
        local char = LocalPlayer.Character
        if char and char:FindFirstChildOfClass("Humanoid") then
            char:FindFirstChildOfClass("Humanoid").WalkSpeed = v
        end
    end
end)
makeToggle(miscPage, "Fly", false, function(v) Config.Misc.FlyEnabled = v end)
makeSlider(miscPage, "Fly Speed", 10, 200, 50, function(v) Config.Misc.FlySpeed = v end)
makeToggle(miscPage, "Noclip", false, function(v) Config.Misc.NoclipEnabled = v end)
makeToggle(miscPage, "Infinite Jump", false, function(v) Config.Misc.InfiniteJump = v end)

makeSection(miscPage, "OTHER")
makeToggle(miscPage, "Anti-AFK", true, function(v) Config.Misc.AntiAFK = v end)

--// ============ PROFILE PAGE ============
local profilePage = Pages["Profile"]

makeSection(profilePage, "ACCOUNT")
makeInfoRow(profilePage, "Username", LocalPlayer.Name)
makeInfoRow(profilePage, "User ID", LocalPlayer.UserId)
makeInfoRow(profilePage, "Account Age", LocalPlayer.AccountAge .. " days")

makeSection(profilePage, "REMOTES")
local remStatus = makeStatus(profilePage, "")
local total, found = 0, 0
for k, v in pairs(Remotes) do
    total = total + 1
    if v then found = found + 1 end
end
remStatus.Text = "Resolved: " .. found .. " / " .. total

makeSection(profilePage, "TESTER")
makeToggle(profilePage, "Test Mode", false, function(v)
    Config.Profile.TestMode = v
    print("[Popka] Test Mode:", v)
end)
makeButton(profilePage, "Copy User ID", function()
    if setclipboard then
        setclipboard(tostring(LocalPlayer.UserId))
        print("[Popka] Copied User ID")
    end
end)
makeButton(profilePage, "Unload Popka Hub", function()
    ScreenGui:Destroy()
    print("[Popka] Unloaded")
end, Theme.Danger)

--// ============ FUNCTIONALITY ============
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
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
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

local flyGyro, flyVel
local function startFly()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    flyGyro = Instance.new("BodyGyro")
    flyGyro.P = 9e4
    flyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyGyro.CFrame = hrp.CFrame
    flyGyro.Parent = hrp
    flyVel = Instance.new("BodyVelocity")
    flyVel.Velocity = Vector3.zero
    flyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyVel.Parent = hrp
end
local function stopFly()
    if flyGyro then flyGyro:Destroy() flyGyro = nil end
    if flyVel then flyVel:Destroy() flyVel = nil end
end

RunService.RenderStepped:Connect(function()
    if Config.Misc.FlyEnabled then
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if not flyGyro then startFly() end
        if flyGyro and flyVel then
            flyGyro.CFrame = Camera.CFrame
            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
            flyVel.Velocity = dir * Config.Misc.FlySpeed
        end
    else
        if flyGyro or flyVel then stopFly() end
    end
end)

LocalPlayer.Idled:Connect(function()
    if Config.Misc.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

local lastCast = 0
local lastReel = 0

RunService.Heartbeat:Connect(function()
    if not Config.Fish.AutoCast and not Config.Fish.AutoReel then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    local now = os.clock()

    if Config.Fish.AutoCast and now - lastCast >= Config.Fish.CastCooldown then
        lastCast = now
        if Remotes.Cast then pcall(function() Remotes.Cast:InvokeServer() end) end
    end

    if Config.Fish.AutoReel and now - lastReel >= Config.Fish.ReelCooldown then
        lastReel = now
        if Remotes.ReelStart then pcall(function() Remotes.ReelStart:InvokeServer() end) end
        task.wait(0.3)
        if Remotes.ReelFinish then pcall(function() Remotes.ReelFinish:FireServer() end) end
    end
end)

--// ============ BUTTON HOOKS ============
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        Main.Size = UDim2.new(0, 500, 0, 40)
        MinBtn.Text = "+"
    else
        Main.Size = UDim2.new(0, 500, 0, 360)
        MinBtn.Text = "-"
    end
end)

--// ============ INIT ============
switchTab("Fish")
print("[Popka Hub] Loaded - User:", LocalPlayer.Name)
print("[Popka Hub] Remotes resolved:", found, "/", total)
