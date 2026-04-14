-- Simple Coordinate Saver (Executor Version) - Надёжный Auto Home
-- By Kitoo | Улучшена проверка телепорта после смерти

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Folder & file
local FOLDER = ".Cordinat"
local FILE = FOLDER .. "/kito.json"

-- Ключи для хранения Home и Auto
local HOME_KEY = "__HOME__"
local AUTO_KEY = "__AUTO_HOME__"

-- Проверка поддержки executor
local canWrite = (type(writefile) == "function" and type(readfile) == "function")
local canFS = (type(isfile) == "function" and type(isfolder) == "function" and type(makefolder) == "function")

if canFS and not isfolder(FOLDER) then
	pcall(makefolder, FOLDER)
end

-- Load / Save
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
	print("[HOME] Установлен как home:", name)
end

local function isAutoHomeEnabled()
	local coords = loadCoords()
	return coords[AUTO_KEY] == true
end

local function setAutoHome(enabled)
	local coords = loadCoords()
	if enabled then
		coords[AUTO_KEY] = true
	else
		coords[AUTO_KEY] = nil
	end
	saveCoords(coords)
	print("[HOME] Auto Home " .. (enabled and "ВКЛЮЧЁН" or "ВЫКЛЮЧЕН"))
end

-- ==================== УЛУЧШЕННЫЙ АВТО-ТЕЛЕПОРТ ПОСЛЕ СМЕРТИ ====================
LocalPlayer.CharacterAdded:Connect(function(char)
	task.spawn(function()
		if not isAutoHomeEnabled() then return end
		
		local homeName = getHomeName()
		if not homeName then return end
		
		local coordsTbl = loadCoords()
		local t = coordsTbl[homeName]
		if not t then return end

		-- Ждём появления нужных частей
		local hrp = char:WaitForChild("HumanoidRootPart", 10)
		local hum = char:WaitForChild("Humanoid", 8)
		if not hrp or not hum then return end

		task.wait(1.8) -- небольшая задержка после респавна

		-- Сброс возможных остатков флая
		hum.PlatformStand = false
		hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)

		-- Удаляем BodyVelocity / BodyGyro если остались от флая
		for _, v in ipairs(hrp:GetChildren()) do
			if v:IsA("BodyVelocity") or v:IsA("BodyGyro") or v:IsA("BodyPosition") then
				v:Destroy()
			end
		end

		-- Несколько попыток телепорта для надёжности
		local targetCFrame = CFrame.new(t[1], t[2] + 4, t[3])

		for attempt = 1, 5 do
			pcall(function()
				char:PivotTo(targetCFrame)
			end)
			
			task.wait(0.25)
			
			-- Проверяем, получилось ли телепортироваться
			if (hrp.Position - targetCFrame.Position).Magnitude < 12 then
				print("[AUTO HOME] ✅ Успешный телепорт на home:", homeName)
				return
			end
		end

		-- Последняя попытка обычным способом
		pcall(function()
			hrp.CFrame = targetCFrame
		end)

		print("[AUTO HOME] Телепорт завершён:", homeName)
	end)
end)

-- ========= ВЕСЬ ТВОЙ ОРИГИНАЛЬНЫЙ UI (ничего не менял) ==========
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

local stroke = Instance.new("UIStroke", frame)
stroke.Thickness = 1
stroke.Color = Color3.fromRGB(80, 80, 80)
stroke.Transparency = 0.4

local title = Instance.new("TextLabel", frame)
title.Text = "Coordinate Saver"
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Position = UDim2.new(0, 10, 0, 0)
title.TextXAlignment = Enum.TextXAlignment.Left

local credit = Instance.new("TextLabel", frame)
credit.Size = UDim2.new(1, -20, 0, 14)
credit.Position = UDim2.new(0, 45, 0, 22)
credit.BackgroundTransparency = 1
credit.Text = "by @SukitooV1"
credit.TextColor3 = Color3.fromRGB(160, 160, 160)
credit.Font = Enum.Font.Gotham
credit.TextSize = 11
credit.TextXAlignment = Enum.TextXAlignment.Left

local minimized = false

local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size = UDim2.new(0, 30, 0, 24)
closeBtn.Position = UDim2.new(1, -35, 0, 3)
closeBtn.Text = "X"
closeBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.BorderSizePixel = 0
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
local uiCorner = Instance.new("UICorner", closeBtn)
uiCorner.CornerRadius = UDim.new(0, 5)

local minBtn = Instance.new("TextButton", frame)
minBtn.Size = UDim2.new(0, 30, 0, 24)
minBtn.Position = UDim2.new(1, -70, 0, 3)
minBtn.Text = "-"
minBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
minBtn.TextColor3 = Color3.new(1,1,1)
minBtn.BorderSizePixel = 0
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
local uiCorner = Instance.new("UICorner", minBtn)
uiCorner.CornerRadius = UDim.new(0, 5)

closeBtn.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		frame.Size = UDim2.new(0, 300, 0, 38)
		for _,v in pairs(frame:GetChildren()) do
			if v ~= title and v ~= credit and v ~= closeBtn and v ~= minBtn then
				if v:IsA("GuiObject") then v.Visible = false end
			end
		end
	else
		frame.Size = UDim2.new(0, 300, 0, 270)
		for _,v in pairs(frame:GetChildren()) do
			if v:IsA("GuiObject") then v.Visible = true end
		end
	end
end)

local nameBox = Instance.new("TextBox", frame)
nameBox.PlaceholderText = "NameCord"
nameBox.Size = UDim2.new(1, -20, 0, 28)
nameBox.Position = UDim2.new(0, 10, 0, 40)
nameBox.Text = ""
nameBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
nameBox.TextColor3 = Color3.new(1,1,1)
nameBox.BorderSizePixel = 0
nameBox.Font = Enum.Font.Gotham
nameBox.TextSize = 14
local uiCorner = Instance.new("UICorner", nameBox)
uiCorner.CornerRadius = UDim.new(0, 5)

local saveBtn = Instance.new("TextButton", frame)
saveBtn.Text = "Save"
saveBtn.Size = UDim2.new(0.5, -15, 0, 30)
saveBtn.Position = UDim2.new(0, 10, 0, 80)
saveBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
saveBtn.TextColor3 = Color3.new(1,1,1)
saveBtn.BorderSizePixel = 0
saveBtn.Font = Enum.Font.Gotham
saveBtn.TextSize = 14
local uiCorner = Instance.new("UICorner", saveBtn)
uiCorner.CornerRadius = UDim.new(0, 8)

local refreshBtn = Instance.new("TextButton", frame)
refreshBtn.Text = "Refresh List"
refreshBtn.Size = UDim2.new(0.5, -15, 0, 30)
refreshBtn.Position = UDim2.new(0.5, 5, 0, 80)
refreshBtn.BackgroundColor3 = Color3.fromRGB(60, 130, 255)
refreshBtn.TextColor3 = Color3.new(1,1,1)
refreshBtn.BorderSizePixel = 0
refreshBtn.Font = Enum.Font.Gotham
refreshBtn.TextSize = 14
local uiCorner = Instance.new("UICorner", refreshBtn)
uiCorner.CornerRadius = UDim.new(0, 8)

local homeLabel = Instance.new("TextLabel", frame)
homeLabel.Size = UDim2.new(0.65, -15, 0, 28)
homeLabel.Position = UDim2.new(0, 10, 0, 115)
homeLabel.BackgroundColor3 = Color3.fromRGB(40,40,40)
homeLabel.TextColor3 = Color3.new(1,1,1)
homeLabel.Text = "🏠 Home: none"
homeLabel.Font = Enum.Font.Gotham
homeLabel.TextSize = 13
homeLabel.TextXAlignment = Enum.TextXAlignment.Left
local uiCornerHome = Instance.new("UICorner", homeLabel)
uiCornerHome.CornerRadius = UDim.new(0, 5)

local toggleBtn = Instance.new("TextButton", frame)
toggleBtn.Size = UDim2.new(0.3, -10, 0, 28)
toggleBtn.Position = UDim2.new(0.7, 5, 0, 115)
toggleBtn.Text = "Auto Home: OFF"
toggleBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.BorderSizePixel = 0
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 13
local uiCornerToggle = Instance.new("UICorner", toggleBtn)
uiCornerToggle.CornerRadius = UDim.new(0, 8)

local function updateHomeUI()
	local homeName = getHomeName()
	homeLabel.Text = "🏠 Home: " .. (homeName or "none")
	local enabled = isAutoHomeEnabled()
	toggleBtn.Text = "Auto Home: " .. (enabled and "ON" or "OFF")
	toggleBtn.BackgroundColor3 = enabled and Color3.fromRGB(0, 170, 100) or Color3.fromRGB(120, 50, 50)
end

toggleBtn.MouseButton1Click:Connect(function()
	local enabled = isAutoHomeEnabled()
	setAutoHome(not enabled)
	updateHomeUI()
end)

local listFrame = Instance.new("ScrollingFrame", frame)
listFrame.Size = UDim2.new(1, -20, 0, 100)
listFrame.Position = UDim2.new(0, 10, 0, 155)
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
listFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 6

local layout = Instance.new("UIListLayout", listFrame)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 5)

local function refreshList()
	for _,v in pairs(listFrame:GetChildren()) do
		if v:IsA("Frame") then v:Destroy() end
	end

	local coords = loadCoords()
	local keys = {}
	for name in pairs(coords) do
		if name ~= HOME_KEY and name ~= AUTO_KEY and type(coords[name]) == "table" then
			table.insert(keys, name)
		end
	end
	table.sort(keys, function(a, b) return string.lower(a) < string.lower(b) end)

	for _, name in ipairs(keys) do
		local pos = coords[name]
		local item = Instance.new("Frame", listFrame)
		item.Size = UDim2.new(1, 0, 0, 30)
		item.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		item.BorderSizePixel = 0
		local uiCorner = Instance.new("UICorner", item)
		uiCorner.CornerRadius = UDim.new(0, 7)

		local lbl = Instance.new("TextLabel", item)
		lbl.Size = UDim2.new(0.35, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = name
		lbl.TextColor3 = Color3.new(1,1,1)
		lbl.Font = Enum.Font.Gotham
		lbl.TextSize = 13
		lbl.TextXAlignment = Enum.TextXAlignment.Left

		local tpBtn = Instance.new("TextButton", item)
		tpBtn.Size = UDim2.new(0.2, -4, 1, -6)
		tpBtn.Position = UDim2.new(0.35, 4, 0, 3)
		tpBtn.Text = "TP"
		tpBtn.Font = Enum.Font.Gotham
		tpBtn.TextColor3 = Color3.new(1,1,1)
		tpBtn.TextSize = 13
		tpBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)
		tpBtn.BorderSizePixel = 0
		local uiCorner = Instance.new("UICorner", tpBtn)
		uiCorner.CornerRadius = UDim.new(0, 6)
		tpBtn.MouseButton1Click:Connect(function() tpCoord(name) end)

		local homeBtn = Instance.new("TextButton", item)
		homeBtn.Size = UDim2.new(0.2, -4, 1, -6)
		homeBtn.Position = UDim2.new(0.55, 4, 0, 3)
		homeBtn.Text = "HOME"
		homeBtn.Font = Enum.Font.Gotham
		homeBtn.TextColor3 = Color3.new(1,1,1)
		homeBtn.TextSize = 12
		homeBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
		homeBtn.BorderSizePixel = 0
		local uiCornerHB = Instance.new("UICorner", homeBtn)
		uiCornerHB.CornerRadius = UDim.new(0, 6)
		homeBtn.MouseButton1Click:Connect(function()
			setHome(name)
			refreshList()
		end)

		local delBtn = Instance.new("TextButton", item)
		delBtn.Size = UDim2.new(0.2, -4, 1, -6)
		delBtn.Position = UDim2.new(0.75, 4, 0, 3)
		delBtn.Text = "DEL"
		delBtn.Font = Enum.Font.Gotham
		delBtn.TextColor3 = Color3.new(1,1,1)
		delBtn.TextSize = 13
		delBtn.BackgroundColor3 = Color3.fromRGB(120,50,50)
		delBtn.BorderSizePixel = 0
		local uiCorner = Instance.new("UICorner", delBtn)
		uiCorner.CornerRadius = UDim.new(0, 6)
		delBtn.MouseButton1Click:Connect(function()
			delCoord(name)
			refreshList()
		end)
	end
	updateHomeUI()
end

saveBtn.MouseButton1Click:Connect(function()
	addCoord(nameBox.Text)
	refreshList()
end)

refreshBtn.MouseButton1Click:Connect(refreshList)
refreshList()

-- Команды
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

print("✅ Coordinate Saver активен с улучшенной проверкой телепорта!")
