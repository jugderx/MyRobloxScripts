-- Локальный скрипт для сильного дропа FPS (троллинг)
-- Запускать через executor (Fluxus, Solara и т.д.)

local RunService = game:GetService("RunService")

getgenv().TARGET_FPS = 1  -- Изменяй это значение. Чем ниже — тем сильнее лагает (5-15 нормально, ниже 5 может крашнуть Roblox)

local frameStart = os.clock()

RunService.PreSimulation:Connect(function()
	while os.clock() - frameStart < 1 / getgenv().TARGET_FPS do
		-- busy wait — жрёт CPU и роняет FPS
	end
	frameStart = os.clock()
end)

print("Лаг включён! FPS принудительно ограничен до ≈" .. getgenv().TARGET_FPS)
