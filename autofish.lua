-- ==========================================================
-- AUTO FISH v7 — FULL FINAL
-- VIM клики + спам LureShake + продажа
-- Работает как Lunor
-- ==========================================================

local LP = game:GetService("Players").LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local VIM = game:GetService("VirtualInputManager")

-- Remote
local Net = RS:WaitForChild("packages"):WaitForChild("Net")
local lureShake = Net:FindFirstChild("RE/LureShake/Shake")
local sellAll = RS:WaitForChild("events"):WaitForChild("SellAll")
local annoCatch = RS:WaitForChild("events"):WaitForChild("anno_catch")

-- Settings
local CONFIG = {
    HOLD_TIME = 1.5,        -- время зажатия при касте
    WAIT_BITE = 3.5,        -- ждать поклёвку
    SHAKE_DURATION = 6,     -- сколько шейкать
    SHAKE_RATE = 0.05,      -- частота шейка (20/сек)
    SELL_EVERY = 10,        -- продавать каждые N уловов
    AUTO_SELL = true,
}

-- State
local S = {
    State = "IDLE",   -- IDLE, CASTING, WAITING, REELING, SHAKING
    Catches = 0,
    Total = 0,
    StartTime = tick(),
    Running = true,
}

-- ==== Проверки ====
print("=== AUTO FISH v7 ===")
print("LureShake:", lureShake and "OK" or "NOT FOUND")
print("SellAll:", sellAll and "OK" or "NOT FOUND")
print("anno_catch:", annoCatch and "OK" or "NOT FOUND")

if not annoCatch then
    return warn("[AutoFish] anno_catch не найден! Остановка.")
end

-- ==== Функции ====
local function getTool()
    local char = LP.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Tool")
end

local function equipRod()
    local tool = getTool()
    if tool then return tool end
    local bp = LP:FindFirstChild("Backpack")
    if bp then
        for _, t in pairs(bp:GetChildren()) do
            if t:IsA("Tool") then
                t.Parent = LP.Character
                task.wait(0.3)
                return t
            end
        end
    end
    return nil
end

local function click(hold)
    local vp = workspace.CurrentCamera.ViewportSize
    local x, y = vp.X / 2, vp.Y / 2
    VIM:SendMouseButtonEvent(x, y, 0, true, game, 1)
    if hold and hold > 0 then task.wait(hold) end
    VIM:SendMouseButtonEvent(x, y, 0, false, game, 1)
end

local function shake()
    if lureShake then
        pcall(function() lureShake:FireServer() end)
    end
end

local function sell()
    if sellAll then
        local ok, r = pcall(function() return sellAll:InvokeServer() end)
        if ok then
            print("[SELL] Продано:", r)
        end
    end
end

-- ==== Слушаем улов ====
annoCatch.OnClientEvent:Connect(function(data, num)
    S.Catches = S.Catches + 1
    S.State = "CAUGHT"
    print("[CATCH #"..S.Catches.."] рыба поймана!")
    
    -- Продажа
    if CONFIG.AUTO_SELL and S.Catches % CONFIG.SELL_EVERY == 0 then
        sell()
    end
    
    task.wait(0.5)
    S.State = "IDLE"
end)

-- ==== Статистика ====
task.spawn(function()
    while S.Running do
        task.wait(60)
        local elapsed = (tick() - S.StartTime) / 60
        print(string.format("[STATS] Уловов: %d | За %.1f мин | %.1f улов/мин", 
            S.Catches, elapsed, S.Catches / elapsed))
    end
end)

-- ==== ГЛАВНЫЙ ЦИКЛ ====
task.spawn(function()
    while S.Running do
        if S.State == "IDLE" then
            -- Экипируем удочку
            equipRod()
            
            -- КАСТ: клик с зажатием
            S.State = "CASTING"
            click(CONFIG.HOLD_TIME)
            print("[STATE] Каст (hold "..CONFIG.HOLD_TIME.."s)")
            
            task.wait(0.5)
            S.State = "WAITING"
            
        elseif S.State == "WAITING" then
            task.wait(CONFIG.WAIT_BITE)
            
            -- ПОДСЕЧКА
            S.State = "REELING"
            click(0.1)
            print("[STATE] Подсечка")
            
            task.wait(0.3)
            S.State = "SHAKING"
            
        elseif S.State == "SHAKING" then
            -- ШЕЙК: спам LureShake + клики
            local start = tick()
            while tick() - start < CONFIG.SHAKE_DURATION and S.State == "SHAKING" do
                shake()
                task.wait(CONFIG.SHAKE_RATE)
            end
            
            if S.State == "SHAKING" then
                S.State = "IDLE"
                print("[STATE] Таймаут → IDLE")
            end
            
        else
            -- CAUGHT → ждём
            task.wait(0.3)
        end
        
        task.wait(0.1)
    end
end)

print("[AutoFish v7] 🎣 Запущен!")
print("Конфиг: HOLD="..CONFIG.HOLD_TIME.."s, WAIT="..CONFIG.WAIT_BITE.."s, SHAKE="..CONFIG.SHAKE_DURATION.."s")
