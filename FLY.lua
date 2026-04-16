local main = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local up = Instance.new("TextButton")
local down = Instance.new("TextButton")
local onof = Instance.new("TextButton")
local TextLabel = Instance.new("TextLabel")
local plus = Instance.new("TextButton")
local speed = Instance.new("TextLabel")
local mine = Instance.new("TextButton")
local closebutton = Instance.new("TextButton")
local mini = Instance.new("TextButton")
local mini2 = Instance.new("TextButton")

main.Name = "main"
main.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
main.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
main.ResetOnSpawn = false

Frame.Parent = main
Frame.BackgroundColor3 = Color3.fromRGB(163, 255, 137)
Frame.BorderColor3 = Color3.fromRGB(103, 221, 213)
Frame.Position = UDim2.new(0.100320168, 0, 0.379746825, 0)
Frame.Size = UDim2.new(0, 190, 0, 57)

-- (все остальные создания GUI без изменений, я их пропустил для краткости, оставь как было)

up.Name = "up"
-- ... (весь твой GUI код остаётся точно таким же до конца создания кнопок)

speeds = 1
local speaker = game:GetService("Players").LocalPlayer
local nowe = false

-- === НОВОЕ: Система принудительного дропа FPS ===
local lowFPSMode = false
local fpsKillerConnection = nil

local function ForceLowFPS()
    if fpsKillerConnection then return end
    
    fpsKillerConnection = game:GetService("RunService").RenderStepped:Connect(function()
        if not lowFPSMode then 
            fpsKillerConnection:Disconnect()
            fpsKillerConnection = nil
            return 
        end
        
        -- Busy-wait чтобы сильно нагрузить клиент и уронить FPS до ~1-3
        local targetTime = tick() + 0.45  -- ~2 FPS (0.5 секунды на кадр)
        while tick() < targetTime do
            -- Пустой цикл, жрёт CPU
        end
    end)
end

local function StopLowFPS()
    lowFPSMode = false
    if fpsKillerConnection then
        fpsKillerConnection:Disconnect()
        fpsKillerConnection = nil
    end
end

-- Основная логика кнопки Fly (изменённая часть)
onof.MouseButton1Down:Connect(function()
    nowe = not nowe   -- переключаем состояние

    if nowe == true then
        -- === ВКЛЮЧИЛИ FLY — ДРОПАЕМ FPS ===
        lowFPSMode = true
        ForceLowFPS()

        -- (твой старый код fly остаётся без изменений)
        game.Players.LocalPlayer.Character.Animate.Disabled = true
        -- ... весь твой код для R6 и R15 (BodyGyro, BodyVelocity и т.д.) ...

        print("Fly ON + Low FPS (~2 FPS)")

    else
        -- === ВЫКЛЮЧИЛИ FLY — ВОССТАНАВЛИВАЕМ FPS ===
        StopLowFPS()

        -- (твой старый код отключения fly)
        game.Players.LocalPlayer.Character.Animate.Disabled = false
        -- ... отключение BodyGyro, BodyVelocity и т.д. ...

        print("Fly OFF + Normal FPS")
    end
end)

-- Остальной твой код (up, down, plus, mine, closebutton, mini и т.д.) остаётся **точно таким же**

closebutton.MouseButton1Click:Connect(function()
    StopLowFPS()  -- на всякий случай
    main:Destroy()
end)

-- Минификация и остальное без изменений
