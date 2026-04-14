-- Simple Coordinate Saver (Executor Version) - FIXED for Fly conflict
-- By Kitoo + исправления для совместимости с FLY GUI

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local FOLDER = ".Cordinat"
local FILE = FOLDER .. "/kito.json"

local HOME_KEY = "__HOME__"
local AUTO_KEY = "__AUTO_HOME__"

local canWrite = (type(writefile) == "function" and type(readfile) == "function")
local canFS = (type(isfile) == "function" and type(isfolder) == "function" and type(makefolder) == "function")

if canFS and not isfolder(FOLDER) then
	pcall(makefolder, FOLDER)
end

local function loadCoords()
	if not canWrite then return {} end
	if canFS and isfile(FILE) then
		local ok, data = pcall(readfile, FILE)
		if ok and data and #data > 0 then
			local success, tbl = pcall(function() return HttpService:JSONDecode(data) end)
			if success and type(tbl) == "table" then
				return tbl
			end
		end
	end
	return {}
end

local function saveCoords(tbl)
	if not canWrite then return false end
	local ok, json = pcall(function() return HttpService:JSONEncode(tbl) end)
	if ok then
		pcall(writefile, FILE, json)
		return true
	end
	return false
end

local function getPos()
	local char = LocalPlayer.Character
	if not char then return nil end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	return hrp.Position
end

local function addCoord(name)
	local pos = getPos()
	if not pos then warn("Карактер не найден.") return end
	local coords = loadCoords()
	name = tostring(name or ("Pos_" .. math.random(1000,9999)))
	coords[name] = {pos.X, pos.Y, pos.Z}
	saveCoords(coords)
	print("[+] Сохранено:", name)
end

local function tpCoord(name)
	local coords = loadCoords()
	local t = coords[name]
	if not t then warn("Координата не найдена:", name) return end
	
	local char = LocalPlayer.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.CFrame = CFrame.new(t[1], t[2], t[3])
		print("[✔] Телепорт к:", name)
	end
end

local function delCoord(name)
	local coords = loadCoords()
	if coords[name] then
		coords[name] = nil
		saveCoords(coords)
		print("[-] Удалено:", name)
	else
		warn("Имя не найдено:", name)
	end
end

local function listCoords()
	local coords = loadCoords()
	local hasCoords = false
	for n,v in pairs(coords) do
		if n ~= HOME_KEY and n ~= AUTO_KEY and type(v) == "table" then
			print(string.format("%s -> (%.2f, %.2f, %.2f)", n, v[1], v[2], v[3]))
			hasCoords = true
		end
	end
	if not hasCoords then print("(пусто)") end
end

-- ==================== HOME FUNCTIONS ====================
local function getHomeName()
	local coords = loadCoords()
	return coords[HOME_KEY]
end

local function setHome(name)
	if not name or name == "" then return end
	local coords = loadCoords()
	if not coords[name] or type(coords[name]) ~= "table" then
		warn("Координата не найдена для Home:", name)
		return
	end
	coords[HOME_KEY] = name
	saveCoords(coords)
	print("[HOME] Установлен:", name)
end

local function isAutoHomeEnabled()
	local coords = loadCoords()
	return coords[AUTO_KEY] == true
end

local function setAutoHome(enabled)
	local coords = loadCoords()
	coords[AUTO_KEY] = enabled and true or nil
	saveCoords(coords)
	print("[HOME] Auto Home " .. (enabled and "ВКЛЮЧЁН" or "ВЫКЛЮЧЕН"))
end

-- ==================== ИСПРАВЛЕННЫЙ AUTO HOME (работает даже при включённом флае) ====================
LocalPlayer.CharacterAdded:Connect(function(char)
	task.spawn(function()
		if not isAutoHomeEnabled() then return end
		
		local homeName = getHomeName()
		if not homeName then return end
		
		local coordsTbl = loadCoords()
		local t = coordsTbl[homeName]
		if not t then return end

		-- Ждём появления персонажа
		local hrp = char:WaitForChild("HumanoidRootPart", 10)
		local hum = char:WaitForChild("Humanoid", 5)
		
		if not hrp or not hum then return end
		
		task.wait(0.6)  -- важная задержка, чтобы флай-скрипт успел "осознать" новый персонаж

		-- === Сброс остатков флая перед телепортом ===
		hum.PlatformStand = false
		hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
		
		-- Уничтожаем старые Body movers (если остались от предыдущего флая)
		for _, v in ipairs(hrp:GetChildren()) do
			if v:IsA("BodyVelocity") or v:IsA("BodyGyro") or v:IsA("BodyPosition") then
				v:Destroy()
			end
		end
		
		-- Включаем нормальные состояния
		for _, state in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
			pcall(function() hum:SetStateEnabled(state, true) end)
		end

		-- Сам телепорт
		hrp.CFrame = CFrame.new(t[1], t[2] + 3, t[3])  -- +3 по Y, чтобы не врезаться в пол
		print("[AUTO HOME] ✅ Телепорт на home:", homeName)
	end)
end)

-- ========= UI (без изменений) ==========
-- ... (весь твой UI код остаётся точно таким же, как был)
-- Я не менял GUI часть, только логику Auto Home.

local gui = Instance.new("ScreenGui")
gui.Name = "CoordsSaverUI"
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 270)
frame.Position = UDim2.new(0, 20, 0, 60)
frame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local uiCorner = Instance.new("UICorner", frame)
uiCorner.CornerRadius = UDim.new(0, 10)

-- (весь остальной UI код: title, credit, closeBtn, minBtn, nameBox, saveBtn, refreshBtn, homeLabel, toggleBtn, listFrame и т.д.)
-- Скопируй его из своего предыдущего скрипта без изменений.

-- ... (здесь вставь весь свой UI код от local title = ... до конца refreshList() и подключений кнопок)

-- Глобальные команды
getgenv().Coords = {
	add = addCoord,
	tp = tpCoord,
	remove = delCoord,
	list = listCoords,
	setHome = setHome,
	toggleAutoHome = function()
		local enabled = isAutoHomeEnabled()
		setAutoHome(not enabled)
		updateHomeUI()
	end
}

print("✅ Coordinate Saver активен (исправлена совместимость с Fly)!")
print("Auto Home теперь должен работать даже если флай включён.")
