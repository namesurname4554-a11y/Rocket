-- ==========================================================
-- AUTO FISH v8 — по событиям (не по времени!)
-- Perfect Cast через castAsync, шейк по состоянию
-- ==========================================================

local LP = game:GetService("Players").LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local VIM = game:GetService("VirtualInputManager")

local Net = RS:WaitForChild("packages"):WaitForChild("Net")
local lureShake = Net:FindFirstChild("RE/LureShake/Shake")
local sellAll = RS.events:FindFirstChild("SellAll")
local annoCatch = RS.events:FindFirstChild("anno_catch")
local castAsync = RS.shared.modules.fishing.rodresources.events.castAsync
local handleBobber = Net:FindFirstChild("RE/FishingRod/HandleBobber")
local breakBobber = Net:FindFirstChild("RE/FishingRod/BreakBobber")
local reelFinish = Net:FindFirstChild("RE/Reel/Finish")

local S = {
    State = "IDLE",
    Catches = 0,
    HasBobber = false,      -- bobber в воде?
    PerfectCast = false,
}

local function click(hold)
    local vp = workspace.CurrentCamera.ViewportSize
    local x, y = vp.X / 2, vp.Y / 2
    VIM:SendMouseButtonEvent(x, y, 0, true, game, 1)
    if hold and hold > 0 then task.wait(hold) end
    VIM:SendMouseButtonEvent(x, y, 0, false, game, 1)
end

-- ===== СЛУШАЕМ СОБЫТИЯ =====

-- Bobber появился — каст прошёл
if handleBobber then
    handleBobber.OnClientEvent:Connect(function(...)
        S.HasBobber = true
        print("[BOBBER] В воде! Каст успешен")
    end)
end

-- Bobber сломан — подсечка или провал
if breakBobber then
    breakBobber.OnClientEvent:Connect(function(...)
        S.HasBobber = false
        print("[BOBBER] Убран")
    end)
end

-- Reel завершён — шейк начинается
if reelFinish then
    reelFinish.OnClientEvent:Connect(function(...)
        print("[REEL] Завершён — шейк активен")
        S.State = "SHAKING"
    end)
end

-- Улов
annoCatch.OnClientEvent:Connect(function(data, num)
    S.Catches = S.Catches + 1
    print("[CATCH #"..S.Catches.."] Улов!")
    S.State = "IDLE"
    
    if S.Catches % 10 == 0 and sellAll then
        pcall(function() sellAll:InvokeServer() end)
    end
end)

-- ===== ЦИКЛ =====
task.spawn(function()
    while true do
        if S.State == "IDLE" then
            -- КАСТ: клик с зажатием
            print("[STATE] Каст")
            S.State = "CASTING"
            
            task.spawn(function()
                click(1.5)  -- зажимаем
            end)
            
            -- Ждём bobber'а
            local t = tick()
            while not S.HasBobber and tick() - t < 5 do
                task.wait(0.1)
            end
            
            if S.HasBobber then
                S.State = "WAITING"
                print("[STATE] Ждём поклёвку")
            else
                S.State = "IDLE"
                print("[STATE] Каст не удался — повтор")
            end
            
        elseif S.State == "WAITING" then
            task.wait(3)
            -- ПОДСЕЧКА
            print("[STATE] Подсечка")
            click(0.1)
            
            task.wait(0.5)
            -- Шейк только если reel активен
            S.State = "SHAKING"
            
        elseif S.State == "SHAKING" then
            -- Спамим шейк 3 сек
            local start = tick()
            while tick() - start < 3 and S.State == "SHAKING" do
                if lureShake then
                    pcall(function() lureShake:FireServer() end)
                end
                task.wait(0.1)
            end
            
            S.State = "IDLE"
            print("[STATE] Таймаут шейка")
            
        else
            task.wait(0.3)
        end
    end
end)

print("[AutoFish v8] Запущен по событиям")
