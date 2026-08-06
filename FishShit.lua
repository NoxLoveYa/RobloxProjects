-- cframe for fishing: -796.500916, 106.459023, -778.318237, -0.99981916, -1.00005501e-07, -0.0190182105, -9.99874175e-08, 1, -1.90192639e-09, 0.0190182105, -6.73570341e-16, -0.99981916
local Hub = loadstring(
	game:HttpGet("https://raw.githubusercontent.com/NoxLoveYa/RobloxProjects/refs/heads/main/Gui%20roblox.lua")
)()

local DEBUG = false

-- Includes
local Players: Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local localplayer: Player = game.Players.LocalPlayer
local playerGui: PlayerGui = localplayer:WaitForChild("PlayerGui", 5)
local virtualInput: VirtualInput = UserInputService:CreateVirtualInput()

-- Var
local humanoid: Humanoid = nil
local character: Model = nil
local rootpart: BasePart = nil

-- Hub Menu Var
local autoTrainEnabled = false
local autoFishEnabled = false
local autoSellEnabled = false
local autoCastTreshold = 0.965
local autoRebirthEnabled = false

-- Hub Menu
local testPage = Hub.CreateTab("Auto Farm", "⭐", 1)
local sec = Hub.Section(testPage, "Farming")

local toggleFrame, _ = Hub.Toggle(testPage, "Auto Train", false, function(v)
	autoTrainEnabled = v
end)
sec.Add(toggleFrame)

local toggleFrame2, _ = Hub.Toggle(testPage, "Auto Fish", false, function(v)
	autoFishEnabled = v
end)
sec.Add(toggleFrame2)

local toggleFrame3, _ = Hub.Toggle(testPage, "Auto Sell", false, function(v)
	autoSellEnabled = v
end)
sec.Add(toggleFrame3)

local toggleFrame4, _ = Hub.Toggle(testPage, "Auto Rebirth", false, function(v)
	autoRebirthEnabled = v
end)
sec.Add(toggleFrame4)

-- Helpers Functions
local function updatePlayerInfo()
	character = localplayer.Character
	if character then
		humanoid = character:WaitForChild("Humanoid", 5)
		rootpart = character:WaitForChild("HumanoidRootPart", 5)
	end
	localplayer.CharacterAdded:Connect(function(char)
		character = char
		humanoid = character:WaitForChild("Humanoid", 5)
		rootpart = character:WaitForChild("HumanoidRootPart", 5)
	end)
end

local function findGuiPath(from, path, className)
	local current = from
	local lastIndex = #path
	for i, key in ipairs(path) do
		if not current then
			return nil
		end
		local parent = current
		if i == lastIndex and className then
			local match = nil
			for _, child in ipairs(parent:GetChildren()) do
				if child.Name == key and child:IsA(className) then
					match = child
					break
				end
			end
			if not match then
				if DEBUG then
					warn(
						"[findGuiPath] Step "
							.. i
							.. ' failed: no child named "'
							.. key
							.. '" of class '
							.. className
							.. " in "
							.. parent:GetFullName()
					)
				end
			end
			current = match
		else
			current = parent:FindFirstChild(key)
			if not current then
				if DEBUG then
					warn(
						"[findGuiPath] Step "
							.. i
							.. ' failed: no child named "'
							.. key
							.. '" in '
							.. parent:GetFullName()
					)
				end
			end
		end
	end
	return current
end

-- Find a GuiObject (TextLabel/TextButton/TextBox) by its displayed text
-- Partial (substring) match by default; className is optional
local function findGuiByText(from, text, className)
	local scanned, classMatches = 0, 0
	local textMatchButWrongClass = nil
	for _, obj in ipairs(from:GetDescendants()) do
		if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
			scanned = scanned + 1
			if not className or obj:IsA(className) then
				classMatches = classMatches + 1
			end
			if obj.Text:find(text, 1, true) then
				if not className or obj:IsA(className) then
					return obj
				else
					textMatchButWrongClass = obj
				end
			end
		end
	end
	if DEBUG then
		warn(
			"[findGuiByText] NOT FOUND for text '"
				.. text
				.. "' (class "
				.. tostring(className)
				.. ") in "
				.. from:GetFullName()
				.. " | scanned "
				.. scanned
				.. " text elements, "
				.. classMatches
				.. " matched class"
		)
		if textMatchButWrongClass then
			warn(
				"[findGuiByText] Text found but on a different class: "
					.. textMatchButWrongClass.ClassName
					.. " ("
					.. textMatchButWrongClass:GetFullName()
					.. ")"
			)
		end
	end
	return nil
end

local function VirtualMousePress(pos)
	pcall(function()
		local pos = pos or workspace.CurrentCamera.ViewportSize / 2
		virtualInput:SendMouseButton(pos, Enum.UserInputType.MouseButton1, true, 1)
		task.wait(0.1)
		virtualInput:SendMouseButton(pos, Enum.UserInputType.MouseButton1, false, 1)
	end)
end

local suffixes = {
	K = 1e3,
	M = 1e6,
	B = 1e9,
	T = 1e12,
	Qa = 1e15,
	Qi = 1e18,
	Se = 1e21,
}

local function parseNumber(str)
	local num = tonumber(str)
	if num then
		return num
	end

	local value, suffix = str:match("^([%d%.]+)(%a+)$")
	if not value then
		return nil
	end

	value = tonumber(value)
	local multiplier = suffixes[suffix]

	if not multiplier then
		return nil
	end

	return value * multiplier
end

local function GetPower()
	return parseNumber(localplayer.leaderstats.Power.Value)
end

-- Extract current/max from a string like "Stored Fishes [7/100]"
local function parseCount(str)
	if not str then
		return nil
	end
	local current, max = str:match("%[(%d+)/(%d+)%]")
	if not current then
		current, max = str:match("(%d+)/(%d+)")
	end
	if not current then
		return nil
	end
	return tonumber(current), tonumber(max)
end

local function autoEquipBestFish()
	local Event = game:GetService("ReplicatedStorage")["shared/network@globalFunctions"].equipBestAquariumFish
	Event:FireServer(0)
end

-- Functions
local function autoTrain()
	for _, gui in ipairs(playerGui:QueryDescendants("TextButton")) do
		local guiFullName = gui:GetFullName()
		if guiFullName ~= "Players." .. localplayer.Name .. ".PlayerGui.6.1.1.1.1.3" then
			continue
		end
		firesignal(gui.Activated)
	end
end

local CAST_PATH = { "6", "1", "53", "1", "1", "1" }
local function autoCast()
	local castGui = findGuiPath(playerGui, CAST_PATH)
	if not castGui then
		return
	end
	local meter = castGui:GetChildren()[3]
	if meter and meter.Size and meter.Size.Height.Scale > autoCastTreshold then
		VirtualMousePress(workspace.CurrentCamera.ViewportSize / 2)
	end
end

local autoFishDelay = 1
local lastFishTime = 0
local FISH_PATH = { "6", "1", "53", "1", "1", "2" }
local function autoFish()
	local fishTPButton = findGuiByText(playerGui, "Fish!", "TextLabel")
	if fishTPButton then
		fishTPButton = fishTPButton.Parent.Parent:FindFirstChildOfClass("TextButton")
		firesignal(fishTPButton.Activated)
	end

	local fishGui = findGuiPath(playerGui, FISH_PATH)
	if not fishGui or not fishGui.Visible then
		return
	end

	if tick() - lastFishTime < autoFishDelay then
		return
	end
	pcall(function()
		firesignal(fishGui.Activated)
		autoEquipBestFish()
	end)
	lastFishTime = tick()
end

local EXP_PATH = { "6", "1", "2", "3" }
local function autoRebirth()
	local needRerbirth = false
	local expGui = findGuiPath(playerGui, EXP_PATH)
	if not expGui then
		return
	end

	local currentExpBar = findGuiPath(expGui, { "1" }, "Frame")
	local expTargetBar = findGuiPath(expGui, { "2" }, "Frame")

	if not currentExpBar or not expTargetBar then
		return
	end

	local currentExp = currentExpBar.Size.X.Scale
	local expTarget = expTargetBar.Position.X.Scale
	if currentExp >= expTarget then
		needRerbirth = true
	end
	if needRerbirth then
		-- TODO: Actually rebirth, currently just prints
		print("Rebirthing...")
	end
end

local autoSellThreshold = 1
local autoSellDelay = 10
local autoSellLastTime = 0
local CLOSE_BUTTON_PATH = { "6", "1", "31", "31", "4", "5", "2", "2", "3" }
local function autoSell()
	if tick() - autoSellLastTime < autoSellDelay then
		return
	end
	local openBackpackGui = findGuiByText(playerGui, "- [G] Open Backpack -", "TextLabel")
	if not openBackpackGui then
		return
	end
	local btn = openBackpackGui.Parent
	if not btn or not btn:IsA("TextButton") then
		return
	end

	autoEquipBestFish()
	firesignal(btn.Activated)
	task.delay(0.15, function()
		local storedFishGui = findGuiByText(playerGui, "Stored Fishes", "TextLabel")
		if not storedFishGui then
			if DEBUG then
				warn("[autoSell] Stored Fishes label not found")
			end
			return
		end
		local current, max = parseCount(storedFishGui.Text)
		if not current then
			if DEBUG then
				warn("[autoSell] Could not parse count from: " .. tostring(storedFishGui.Text))
			end
			return
		end
		if DEBUG then
			print("[autoSell] Stored Fishes:", current, "/", max or "?")
		end
		if current >= autoSellThreshold then
			if not rootpart then
				updatePlayerInfo()
			end
			local oldCFrame = rootpart.CFrame
			rootpart.CFrame = CFrame.new(workspace.Map.Shops.SellShop.WorldPivot.Position)
			task.delay(0.5, function()
				local sellButton = findGuiByText(playerGui, "Sell")
				if not sellButton then
					return
				end
				task.delay(0.15, function()
					firesignal(sellButton.Parent.parent.parent.Activated)
					rootpart.CFrame = oldCFrame
				end)
			end)
		else
			local closeButton = findGuiPath(playerGui, CLOSE_BUTTON_PATH)
			firesignal(closeButton.Activated)
		end
		autoSellLastTime = tick()
	end)
end

task.wait(3.5)

updatePlayerInfo()

task.spawn(function()
	while true do
		if autoTrainEnabled then
			autoTrain()
		end
		if autoRebirthEnabled then
			autoRebirth()
		end
		if autoSellEnabled then
			autoSell()
		end
		if autoFishEnabled then
			autoFish()
			autoCast()
		end
		task.wait(0.05)
	end
end)

task.spawn(function()
	while true do
		local clickableStuffGui = findGuiPath(playerGui, { "6", "1", "53" })
		if clickableStuffGui then
			for _, child in ipairs(clickableStuffGui:GetDescendants()) do
				if child:IsA("TextButton") or child:IsA("ImageButton") and child.Visible then
					firesignal(child.Activated)
				end
			end
		end
		task.wait(0.05)
	end
end)