-- Banan Hub v3 | Blox Fruits | Delta / Android
-- Вкладки, фиксы, реальная атака, авто-квест

if game.PlaceId ~= 2753915549 and game.PlaceId ~= 4442272183 and game.PlaceId ~= 7449423635 then
    return warn("[Banan Hub] Not Blox Fruits!")
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer

-- ===== STATE =====
local S = {
    -- Farm
    LevelFarm=false, MasteryFarm=false, AutoFarm=false, AutoQuest=false,
    AutoRaid=false, AutoBoss=false, BossName="", AutoFish=false, AutoCollect=false,
    Weapon="Melee", QuestMobs={},
    -- Combat
    AutoHaki=false, AutoSword=false, AutoFruitSniper=false,
    -- Movement
    Noclip=false, InfJump=false, Fly=false,
    -- Utility
    AntiAFK=false, ServerHop=false, FullBright=false,
    MenuOpen=true,
}

-- ===== GUI =====
local Gui = Instance.new("ScreenGui")
Gui.Name="BananHub"
Gui.ResetOnSpawn=false
Gui.IgnoreGuiInset=true
Gui.Parent=LP:WaitForChild("PlayerGui")

local Main=Instance.new("Frame")
Main.Size=UDim2.new(0,520,0,360)
Main.Position=UDim2.new(0.5,-260,0.5,-180)
Main.BackgroundColor3=Color3.fromRGB(15,15,22)
Main.BorderSizePixel=0
Main.Active=true Main.Draggable=true
Main.Parent=Gui
Instance.new("UICorner",Main).CornerRadius=UDim.new(0,14)
local st=Instance.new("UIStroke",Main) st.Color=Color3.fromRGB(255,200,0) st.Thickness=1.5

-- Header
local Head=Instance.new("Frame")
Head.Size=UDim2.new(1,0,0,44)
Head.BackgroundColor3=Color3.fromRGB(25,25,35)
Head.BorderSizePixel=0
Head.Parent=Main
Instance.new("UICorner",Head).CornerRadius=UDim.new(0,14)

local HeadGrad=Instance.new("UIGradient",Head)
HeadGrad.Color=ColorSequence.new{
    ColorSequenceKeypoint.new(0,Color3.fromRGB(255,200,0)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(255,140,0))
}
HeadGrad.Rotation=0

local Title=Instance.new("TextLabel")
Title.Size=UDim2.new(1,-100,1,0)
Title.Position=UDim2.new(0,16,0,0)
Title.BackgroundTransparency=1
Title.Text="🍌 Banan Hub | Blox Fruits"
Title.TextColor3=Color3.fromRGB(20,20,20)
Title.Font=Enum.Font.GothamBold
Title.TextSize=16
Title.TextXAlignment=Enum.TextXAlignment.Left
Title.Parent=Head

local CloseBtn=Instance.new("TextButton")
CloseBtn.Size=UDim2.new(0,30,0,30)
CloseBtn.Position=UDim2.new(1,-38,0,7)
CloseBtn.BackgroundColor3=Color3.fromRGB(40,40,55)
CloseBtn.Text="X"
CloseBtn.TextColor3=Color3.fromRGB(255,255,255)
CloseBtn.Font=Enum.Font.GothamBold
CloseBtn.TextSize=14
CloseBtn.Parent=Head
Instance.new("UICorner",CloseBtn).CornerRadius=UDim.new(0,6)

local Bubble=Instance.new("TextButton")
Bubble.Size=UDim2.new(0,54,0,54)
Bubble.Position=UDim2.new(0,20,0.3,0)
Bubble.BackgroundColor3=Color3.fromRGB(255,180,0)
Bubble.Text="🍌"
Bubble.TextColor3=Color3.fromRGB(20,20,20)
Bubble.Font=Enum.Font.GothamBold
Bubble.TextSize=24
Bubble.Visible=false
Bubble.Draggable=true
Bubble.Parent=Gui
Instance.new("UICorner",Bubble).CornerRadius=UDim.new(1,0)

CloseBtn.MouseButton1Click:Connect(function() Main.Visible=false Bubble.Visible=true end)
Bubble.MouseButton1Click:Connect(function() Main.Visible=true Bubble.Visible=false end)

-- Sidebar (вкладки)
local Side=Instance.new("Frame")
Side.Size=UDim2.new(0,110,1,-50)
Side.Position=UDim2.new(0,6,0,46)
Side.BackgroundColor3=Color3.fromRGB(22,22,30)
Side.BorderSizePixel=0
Side.Parent=Main
Instance.new("UICorner",Side).CornerRadius=UDim.new(0,10)

local SideList=Instance.new("UIListLayout")
SideList.Padding=UDim.new(0,4)
SideList.SortOrder=Enum.SortOrder.LayoutOrder
SideList.Parent=Side
Instance.new("UIPadding",Side).PaddingTop=UDim.new(0,6)

-- Content area
local Content=Instance.new("Frame")
Content.Size=UDim2.new(1,-130,1,-56)
Content.Position=UDim2.new(0,122,0,52)
Content.BackgroundTransparency=1
Content.Parent=Main

local pages={}
local activePage=nil

local function selectTab(name)
    for n,p in pairs(pages) do p.Visible=(n==name) end
    activePage=name
end

local function makeTab(name, order)
    local t=Instance.new("TextButton")
    t.Size=UDim2.new(1,-12,0,34)
    t.Position=UDim2.new(0,6,0,0)
    t.BackgroundColor3=Color3.fromRGB(35,35,48)
    t.Text=name
    t.TextColor3=Color3.fromRGB(220,220,235)
    t.Font=Enum.Font.GothamMedium
    t.TextSize=13
    t.LayoutOrder=order
    t.Parent=Side
    Instance.new("UICorner",t).CornerRadius=UDim.new(0,7)
    t.MouseButton1Click:Connect(function()
        selectTab(name)
        for _,c in pairs(Side:GetChildren()) do
            if c:IsA("TextButton") then
                c.BackgroundColor3=Color3.fromRGB(35,35,48)
                c.TextColor3=Color3.fromRGB(220,220,235)
            end
        end
        t.BackgroundColor3=Color3.fromRGB(255,180,0)
        t.TextColor3=Color3.fromRGB(20,20,20)
    end)
    local p=Instance.new("ScrollingFrame")
    p.Size=UDim2.new(1,0,1,0)
    p.BackgroundTransparency=1
    p.BorderSizePixel=0
    p.ScrollBarThickness=4
    p.ScrollBarImageColor3=Color3.fromRGB(255,180,0)
    p.CanvasSize=UDim2.new(0,0,0,0)
    p.AutomaticCanvasSize=Enum.AutomaticSize.Y
    p.Visible=false
    p.Parent=Content
    local l=Instance.new("UIListLayout")
    l.Padding=UDim.new(0,6)
    l.SortOrder=Enum.SortOrder.LayoutOrder
    l.Parent=p
    pages[name]=p
    return p
end

-- ===== HELPERS =====
local function notify(text)
    local m=Instance.new("TextLabel")
    m.Size=UDim2.new(0,240,0,30)
    m.Position=UDim2.new(1,-260,0,50)
    m.BackgroundColor3=Color3.fromRGB(30,30,45)
    m.Text="🍌 "..text
    m.TextColor3=Color3.fromRGB(255,255,255)
    m.Font=Enum.Font.Gotham
    m.TextSize=12
    m.Parent=Gui
    Instance.new("UICorner",m).CornerRadius=UDim.new(0,6)
    task.delay(2.5,function() if m then m:Destroy() end end)
end

local function char() return LP.Character or LP.CharacterAdded:Wait() end
local function hrp() local c=char() return c:FindFirstChild("HumanoidRootPart") end
local function hum() local c=char() return c:FindFirstChildOfClass("Humanoid") end
local function tween(pos,spd)
    local h=hrp() if not h then return end
    TweenService:Create(h,TweenInfo.new(spd or 0.25,Enum.EasingStyle.Linear),{CFrame=CFrame.new(pos)}):Play()
end

-- Атака tool'ом
local function getWeapon()
    local c=char() if not c then return nil end
    local best=nil
    if S.Weapon=="Melee" then
        for _,t in pairs(c:GetChildren()) do
            if t:IsA("Tool") and t:FindFirstChild("Handle") then
                if not best or (t.Name:lower():find("sword") and not best.Name:lower():find("sword")) then best=t end
            end
        end
    else
        for _,t in pairs(c:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower():find(S.Weapon:lower()) then best=t break end
        end
    end
    return best
end

local function realAttack(mob)
    if not mob or not mob:FindFirstChild("Humanoid") then return end
    local h=hrp() if not h then return end
    -- телепорт вплотную
    h.CFrame=mob.HumanoidRootPart.CFrame*CFrame.new(0,0,3)
    local w=getWeapon()
    if w then
        pcall(function()
            w.Parent=char()
            w:Activate()
        end)
    end
end

local function findMob(filterQuest)
    local h=hrp() if not h then return nil end
    local enemies=workspace:FindFirstChild("Enemies")
    if not enemies then return nil end
    local best,bd=nil,math.huge
    for _,v in pairs(enemies:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v.Humanoid.Health>0 and v:FindFirstChild("HumanoidRootPart") then
            local ok=true
            if filterQuest and #S.QuestMobs>0 then
                ok=false
                for _,n in pairs(S.QuestMobs) do
                    if v.Name:lower():find(n:lower()) then ok=true break end
                end
            end
            if ok then
                local d=(v.HumanoidRootPart.Position-h.Position).Magnitude
                if d<bd then bd=d best=v end
            end
        end
    end
    return best
end

-- ===== LEVEL DATA =====
local function myLevel()
    local ok,lv=pcall(function()
        return LP.Data.Level.Value
    end)
    if ok and lv then return lv end
    return 1
end

-- ===== QUEST =====
local function getQuestNPC()
    local myLv=myLevel()
    local best,bd=nil,math.huge
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") then
            local n=v.Name:lower()
            if n:find("quest") or n:find("giver") or n:find("boss") or n:find("elder") or n:find("captain") then
                local npcLv=1
                local lvObj=v:FindFirstChild("Level") or (v:FindFirstChild("Humanoid") and v.Humanoid:FindFirstChild("Level"))
                if lvObj and lvObj.Value then npcLv=lvObj.Value end
                local diff=math.abs(npcLv-myLv)
                if diff<bd then bd=diff best=v end
            end
        end
    end
    return best
end

local function takeQuest(npc)
    if not npc then return end
    for _,d in pairs(npc:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            pcall(function() fireproximityprompt(d) end)
        elseif d:IsA("ClickDetector") then
            pcall(function() fireclickdetector(d) end)
        end
    end
end

-- ===== LOOPS =====
task.spawn(function()
    while task.wait(0.15) do
        if (S.AutoFarm or S.LevelFarm or S.MasteryFarm) and hrp() then
            local mob=findMob(S.AutoFarm)
            if mob then realAttack(mob) end
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if S.AutoQuest then
            local npc=getQuestNPC()
            if npc and npc:FindFirstChild("Head") then
                tween(npc.Head.Position+Vector3.new(0,3,0),0.4)
                task.wait(0.3)
                takeQuest(npc)
            end
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if S.AutoRaid then
            -- placeholder: ищет Chip и Raid NPC, кидает в чат /raid
            pcall(function()
                local args={"\/raid"}
                game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer(unpack(args))
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if S.AutoBoss and S.BossName~="" then
            local enemies=workspace:FindFirstChild("Enemies")
            if enemies then
                for _,v in pairs(enemies:GetChildren()) do
                    if v.Name:lower():find(S.BossName:lower()) and v:FindFirstChild("HumanoidRootPart") then
                        realAttack(v)
                        break
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.4) do
        if S.AutoCollect and hrp() then
            for _,v in pairs(workspace:GetChildren()) do
                if v.Name=="Fruit" or v.Name=="Drop" or (v:IsA("Tool") and v:FindFirstChild("Handle")) then
                    local h=v:FindFirstChild("Handle")
                    if h then tween(h.Position+Vector3.new(0,3,0),0.3) end
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(3) do
        if S.AutoHaki then
            pcall(function()
                for _,t in pairs(LP.Backpack:GetChildren()) do
                    if t.Name:lower():find("haki") or t.Name:lower():find("buso") or t.Name:lower():find("ken") then
                        t.Parent=LP.Character
                    end
                end
            end)
        end
        if S.AutoSword then
            pcall(function()
                for _,t in pairs(LP.Backpack:GetChildren()) do
                    if t.Name:lower():find("sword") or t.Name:lower():find("katana") or t.Name:lower():find("blade") then
                        t.Parent=LP.Character
                    end
                end
            end)
        end
        if S.AutoFruitSniper and hrp() then
            for _,v in pairs(workspace:GetChildren()) do
                if v.Name=="Fruit" and v:FindFirstChild("Handle") then
                    tween(v.Handle.Position+Vector3.new(0,3,0),0.3)
                    task.wait(0.3)
                    pcall(function() firetouchinterest(hrp(),v.Handle,0) firetouchinterest(hrp(),v.Handle,1) end)
                end
            end
        end
    end
end)

-- Movement & misc
RunService.Stepped:Connect(function()
    local c=LP.Character if not c then return end
    local h=c:FindFirstChild("HumanoidRootPart")
    if S.Noclip then
        for _,p in pairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=false end
        end
    end
    if S.Fly and h then h.Velocity=Vector3.new(0,50,0) end
end)

UIS.JumpRequest:Connect(function()
    if S.InfJump then
        local h=hum() if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

task.spawn(function()
    while task.wait(2) do
        if S.FullBright then
            local L=game:GetService("Lighting")
            L.Brightness=3 L.ClockTime=12 L.FogEnd=1e5 L.GlobalShadows=false
        end
        if S.AntiAFK then
            pcall(function()
                game:GetService("VirtualUser"):CaptureController()
                game:GetService("VirtualUser"):Button1Down(Vector2.new(0,0))
            end)
        end
    end
end)

-- ===== UI BUILDERS =====
local function btn(parent,text,cb)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(1,-8,0,36)
    b.BackgroundColor3=Color3.fromRGB(38,38,55)
    b.Text=text
    b.TextColor3=Color3.fromRGB(235,235,245)
    b.Font=Enum.Font.GothamMedium
    b.TextSize=13
    b.Parent=parent
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,8)
    local s=Instance.new("UIStroke",b) s.Color=Color3.fromRGB(70,70,100)
    b.MouseButton1Click:Connect(cb)
    return b
end

local function toggle(parent,label,key,cb)
    local b=btn(parent,label..": OFF",function()
        S[key]=not S[key]
        b.Text=label..": "..(S[key] and "ON" or "OFF")
        b.BackgroundColor3=S[key] and Color3.fromRGB(0,150,70) or Color3.fromRGB(38,38,55)
        if cb then cb(S[key]) end
    end)
    return b
end

local function label(parent,text)
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,-8,0,22)
    l.BackgroundTransparency=1
    l.Text=text
    l.TextColor3=Color3.fromRGB(180,180,220)
    l.Font=Enum.Font.GothamBold
    l.TextSize=12
    l.TextXAlignment=Enum.TextXAlignment.Left
    l.Parent=parent
    return l
end

local function textbox(parent,placeholder,cb)
    local t=Instance.new("TextBox")
    t.Size=UDim2.new(1,-8,0,32)
    t.BackgroundColor3=Color3.fromRGB(28,28,40)
    t.PlaceholderText=placeholder
    t.Text=""
    t.TextColor3=Color3.fromRGB(255,255,255)
    t.PlaceholderColor3=Color3.fromRGB(140,140,170)
    t.Font=Enum.Font.Gotham
    t.TextSize=12
    t.Parent=parent
    Instance.new("UICorner",t).CornerRadius=UDim.new(0,6)
    t.FocusLost:Connect(function() if cb then cb(t.Text) end end)
    return t
end

-- ===== FARM TAB =====
local pFarm=makeTab("Farm",1)
label(pFarm,"Автофарм")
toggle(pFarm,"Auto Farm (по квесту)","AutoFarm")
toggle(pFarm,"Level Farm","LevelFarm")
toggle(pFarm,"Mastery Farm","MasteryFarm")
toggle(pFarm,"Auto Quest","AutoQuest")
toggle(pFarm,"Auto Collect","AutoCollect")
label(pFarm,"Боссы и рейды")
toggle(pFarm,"Auto Raid","AutoRaid")
toggle(pFarm,"Auto Boss","AutoBoss")
textbox(pFarm,"Имя босса (напр. Saber)",function(t) S.BossName=t notify("Босс: "..t) end)
label(pFarm,"Оружие для атаки")
for _,w in ipairs({"Melee","Sword","Gun","Fruit"}) do
    btn(pFarm,"  "..w,function() S.Weapon=w notify("Оружие: "..w) end)
end
label(pFarm,"Рыбалка")
toggle(pFarm,"Auto Fish","AutoFish")

-- ===== COMBAT TAB =====
local pCombat=makeTab("Combat",2)
label(pCombat,"Авто-экипировка")
toggle(pCombat,"Auto Haki","AutoHaki")
toggle(pCombat,"Auto Sword","AutoSword")
toggle(pCombat,"Auto Fruit Sniper","AutoFruitSniper")

-- ===== MOVEMENT TAB =====
local pMove=makeTab("Move",3)
label(pMove,"Перемещение")
toggle(pMove,"Noclip","Noclip")
toggle(pMove,"Infinite Jump","InfJump")
toggle(pMove,"Fly (вверх)","Fly")

-- ===== UTILITY TAB =====
local pUtil=makeTab("Utility",4)
label(pUtil,"Утилиты")
toggle(pUtil,"Anti-AFK","AntiAFK")
toggle(pUtil,"Full Bright","FullBright")
toggle(pUtil,"Server Hop","ServerHop",function(v)
    if v then
        notify("Server hop...")
        pcall(function()
            local TS=game:GetService("TeleportService")
            local servers=game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
            for _,s in pairs(servers.data) do
                if s.playing<s.maxPlayers and s.id~=game.JobId then
                    TS:TeleportToPlaceInstance(game.PlaceId,s.id,LP)
                    break
                end
            end
        end)
    end
end)

-- ===== INFO TAB =====
local pInfo=makeTab("Info",5)
label(pInfo,"Banan Hub v3")
local infoLbl=Instance.new("TextLabel")
infoLbl.Size=UDim2.new(1,-8,0,80)
infoLbl.BackgroundColor3=Color3.fromRGB(28,28,40)
infoLbl.Text="🍌 Banan Hub v3\nDelta / Android\nBlox Fruits\nМеню: перетаскивай за шапку"
infoLbl.TextColor3=Color3.fromRGB(220,220,240)
infoLbl.Font=Enum.Font.Gotham
infoLbl.TextSize=12
infoLbl.TextWrapped=true
infoLbl.Parent=pInfo
Instance.new("UICorner",infoLbl).CornerRadius=UDim.new(0,8)

-- ===== INIT =====
selectTab("Farm")
-- Подсветка первой вкладки
for _,c in pairs(Side:GetChildren()) do
    if c:IsA("TextButton") and c.Text=="Farm" then
        c.BackgroundColor3=Color3.fromRGB(255,180,0)
        c.TextColor3=Color3.fromRGB(20,20,20)
    end
end

notify("Banan Hub v3 загружен")
print("[Banan Hub v3] Loaded | PlaceId:",game.PlaceId)
