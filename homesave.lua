-- Simple Coordinate Saver (Executor Version) - Fixed & Reliable Auto Home
-- By Kitoo + улучшения для работы с Fly

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
			if success and type(tbl) == "table" then return tbl end
		end
	end
	return {}
end

local function saveCoords(tbl)
	if not canWrite then return false end
	local ok, json = pcall(function() return HttpService:JSONEncode(tbl) end)
	if ok then pcall(writefile, FILE, json) end
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
	if not pos then warn("Персонаж не найден") return end
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
	if char and char:FindFirstChild("HumanoidRootPart") then
		char.HumanoidRootPart.CFrame = CFrame.new(t[1], t[2], t[3])
		print("[✔] Телепорт к:", name)
	end
end

local function delCoord(name)
	local coords = loadCoords()
	if coords[name] then
		coords[name] = nil
		saveCoords(coords)
		print("[-] Удалено:", name)
	end
end

local function listCoords()
	local coords = loadCoords()
	local has = false
	for n,v in pairs(coords) do
		if n ~= HOME_KEY and n ~= AUTO_KEY and type(v) == "table" then
			print(string.format("%s → (%.2f, %.2f, %.2f)", n, v[1], v[2], v[3]))
			has = true
		end
	end
	if not has then print("(пусто)") end
end

-- Home функции
local function getHomeName() local c = loadCoords() return c[HOME_KEY] end
local function setHome(name)
	if not name then return end
	local c = loadCoords()
	if c[name] then c[HOME_KEY] = name saveCoords(c) print("[HOME] Установлен:", name) end
end

local function isAutoHomeEnabled() local c = loadCoords() return c[AUTO_KEY] == true end
local function setAutoHome(enabled)
	local c = loadCoords()
	c[AUTO_KEY] = enabled and true or nil
	saveCoords(c)
	print("[HOME] Auto Home " .. (enabled and "ВКЛЮЧЁН" or "ВЫКЛЮЧЕН"))
end

-- ==================== НАДЁЖНЫЙ AUTO HOME ====================
LocalPlayer.CharacterAdded:Connect(function(char)
	task.spawn(function()
		if not isAutoHomeEnabled() then return end
		local homeName = getHomeName()
		if not homeName then return end
		local coords = loadCoords()
		local pos = coords[homeName]
		if not pos then return end

		local hrp = char:WaitForChild("HumanoidRootPart", 10)
		local hum = char:WaitForChild("Humanoid", 8)
		if not hrp or not hum then return end

		task.wait(1.5)

		-- Сброс флая
		hum.PlatformStand = false
		hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
		for _, v in ipairs(hrp:GetDescendants()) do
			if v:IsA("BodyVelocity") or v:IsA("BodyGyro") or v:IsA("BodyPosition") then
				v:Destroy()
			end
		end

		local target = CFrame.new(pos[1], pos[2] + 4, pos[3])

		-- Несколько попыток телепорта
		for i = 1, 6 do
			pcall(function() char:PivotTo(target) end)
			task.wait(0.2)
			if (hrp.Position - target.Position).Magnitude < 15 then
				print("[AUTO HOME] ✅ Успешно телепортировало на", homeName)
				return
			end
		end

		-- Последняя попытка
		pcall(function() hrp.CFrame = target end)
		print("[AUTO HOME] Телепорт завершён:", homeName)
	end)
end)

-- ==================== GUI ====================
local gui = Instance.new("ScreenGui")
gui.Name = "CoordsSaverUI"
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 270)
frame.Position = UDim2.new(0, 20, 0, 60)
frame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
frame.Active = true
frame.Draggable = true
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", frame)
stroke.Thickness = 1
stroke.Color = Color3.fromRGB(80, 80, 80)

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
credit.Text = "by @SukitooV1"
credit.Size = UDim2.new(1, -20, 0, 14)
credit.Position = UDim2.new(0, 45, 0, 22)
credit.BackgroundTransparency = 1
credit.TextColor3 = Color3.fromRGB(160, 160, 160)
credit.Font = Enum.Font.Gotham
credit.TextSize = 11
credit.TextXAlignment = Enum.TextXAlignment.Left

-- Close и Minimize кнопки
local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size = UDim2.new(0, 30, 0, 24)
closeBtn.Position = UDim2.new(1, -35, 0, 3)
closeBtn.Text = "X"
closeBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 5)

local minBtn = Instance.new("TextButton", frame)
minBtn.Size = UDim2.new(0, 30, 0, 24)
minBtn.Position = UDim2.new(1, -70, 0, 3)
minBtn.Text = "-"
minBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
minBtn.TextColor3 = Color3.new(1,1,1)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 5)

closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

local minimized = false
minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		frame.Size = UDim2.new(0, 300, 0, 38)
		for _, v in pairs(frame:GetChildren()) do
			if v ~= title and v ~= credit and v ~= closeBtn and v ~= minBtn then
				if v:IsA("GuiObject") then v.Visible = false end
			end
		end
	else
		frame.Size = UDim2.new(0, 300, 0, 270)
		for _, v in pairs(frame:GetChildren()) do
			if v:IsA("GuiObject") then v.Visible = true end
		end
	end
end)

-- Остальной UI (nameBox, кнопки, список и т.д.)
local nameBox = Instance.new("TextBox", frame)
nameBox.PlaceholderText = "NameCord"
nameBox.Size = UDim2.new(1, -20, 0, 28)
nameBox.Position = UDim2.new(0, 10, 0, 40)
nameBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
nameBox.TextColor3 = Color3.new(1,1,1)
nameBox.Font = Enum.Font.Gotham
nameBox.TextSize = 14
Instance.new("UICorner", nameBox).CornerRadius = UDim.new(0, 5)

local saveBtn = Instance.new("TextButton", frame)
saveBtn.Text = "Save"
saveBtn.Size = UDim2.new(0.5, -15, 0, 30)
saveBtn.Position = UDim2.new(0, 10, 0, 80)
saveBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
saveBtn.TextColor3 = Color3.new(1,1,1)
saveBtn.Font = Enum.Font.Gotham
saveBtn.TextSize = 14
Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 8)

local refreshBtn = Instance.new("TextButton", frame)
refreshBtn.Text = "Refresh List"
refreshBtn.Size = UDim2.new(0.5, -15, 0, 30)
refreshBtn.Position = UDim2.new(0.5, 5, 0, 80)
refreshBtn.BackgroundColor3 = Color3.fromRGB(60, 130, 255)
refreshBtn.TextColor3 = Color3.new(1,1,1)
refreshBtn.Font = Enum.Font.Gotham
refreshBtn.TextSize = 14
Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 8)

local homeLabel = Instance.new("TextLabel", frame)
homeLabel.Size = UDim2.new(0.65, -15, 0, 28)
homeLabel.Position = UDim2.new(0, 10, 0, 115)
homeLabel.BackgroundColor3 = Color3.fromRGB(40,40,40)
homeLabel.TextColor3 = Color3.new(1,1,1)
homeLabel.Text = "🏠 Home: none"
homeLabel.Font = Enum.Font.Gotham
homeLabel.TextSize = 13
homeLabel.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", homeLabel).CornerRadius = UDim.new(0, 5)

local toggleBtn = Instance.new("TextButton", frame)
toggleBtn.Size = UDim2.new(0.3, -10, 0, 28)
toggleBtn.Position = UDim2.new(0.7, 5, 0, 115)
toggleBtn.Text = "Auto Home: OFF"
toggleBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 13
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

local function updateHomeUI()
	local homeName = getHomeName()
	homeLabel.Text = "🏠 Home: " .. (homeName or "none")
	local enabled = isAutoHomeEnabled()
	toggleBtn.Text = "Auto Home: " .. (enabled and "ON" or "OFF")
	toggleBtn.BackgroundColor3 = enabled and Color3.fromRGB(0, 170, 100) or Color3.fromRGB(120, 50, 50)
end

toggleBtn.MouseButton1Click:Connect(function()
	setAutoHome(not isAutoHomeEnabled())
	updateHomeUI()
end)

-- List
local listFrame = Instance.new("ScrollingFrame", frame)
listFrame.Size = UDim2.new(1, -20, 0, 100)
listFrame.Position = UDim2.new(0, 10, 0, 155)
listFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
listFrame.ScrollBarThickness = 6
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UIListLayout", listFrame).Padding = UDim.new(0, 5)

local function refreshList()
	for _, v in pairs(listFrame:GetChildren()) do
		if v:IsA("Frame") then v:Destroy() end
	end

	local coords = loadCoords()
	local keys = {}
	for name in pairs(coords) do
		if name ~= HOME_KEY and name ~= AUTO_KEY and type(coords[name]) == "table" then
			table.insert(keys, name)
		end
	end
	table.sort(keys, function(a,b) return string.lower(a) < string.lower(b) end)

	for _, name in ipairs(keys) do
		local item = Instance.new("Frame", listFrame)
		item.Size = UDim2.new(1, 0, 0, 30)
		item.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		Instance.new("UICorner", item).CornerRadius = UDim.new(0, 7)

		local lbl = Instance.new("TextLabel", item)
		lbl.Size = UDim2.new(0.35, 0
