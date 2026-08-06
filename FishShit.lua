-- cframe for fishing: -796.500916, 106.459023, -778.318237, -0.99981916, -1.00005501e-07, -0.0190182105, -9.99874175e-08, 1, -1.90192639e-09, 0.0190182105, -6.73570341e-16, -0.99981916
local Hub = loadstring(
	game:HttpGet("https://raw.githubusercontent.com/NoxLoveYa/RobloxProjects/refs/heads/main/Gui%20roblox.lua")
)()

local DEBUG = true

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
local autoCastEnabled = false
local autoCastTreshold = 0.965
local autoRebirthEnabled = false

-- Hub Menu
local testPage = Hub.CreateTab("Auto Farm", "⭐", 1)
local sec = Hub.Section(testPage, "Farming")

local toggleFrame, _ = Hub.Toggle(testPage, "Auto Train", false, function(v)
	autoTrainEnabled = v
end)
sec.Add(toggleFrame)

local toggleFrame2, _ = Hub.Toggle(testPage, "Auto Cast", false, function(v)
	autoCastEnabled = v
end)
sec.Add(toggleFrame2)

local toggleFrame3, _ = Hub.Toggle(testPage, "Auto Rebirth", false, function(v)
	autoRebirthEnabled = v
end)
sec.Add(toggleFrame3)

local toggleFrame4, _ = Hub.Toggle(testPage, "Auto Fish", false, function(v)
	autoFishEnabled = v
end)
sec.Add(toggleFrame4)

-- Helpers Functions
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
						"[findGuiPath] Step " .. i .. ' failed: no child named "' .. key .. '" in ' .. parent:GetFullName()
					)
				end
			end
		end
	end
	return current
end

local function VirtualMousePress(pos)
	local pos = pos or workspace.CurrentCamera.ViewportSize / 2
	virtualInput:SendMouseButton(pos, Enum.UserInputType.MouseButton1, true, 1)
	task.wait(0.1)
	virtualInput:SendMouseButton(pos, Enum.UserInputType.MouseButton1, false, 1)
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
	local fishGui = findGuiPath(playerGui, FISH_PATH)
	if not fishGui or not fishGui.Visible then
		return
	end

	if tick() - lastFishTime < autoFishDelay then
		return
	end
	pcall(function()
		firesignal(fishGui.Activated)
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

-- Routines
localplayer.CharacterAdded:Connect(function(char)
	character = char
	humanoid = character:WaitForChild("Humanoid", 5)
	rootpart = character:WaitForChild("HumanoidRootPart", 5)
	print("Character Added")
	print("Humanoid: ", humanoid)
	print("RootPart: ", rootpart)
end)

task.spawn(function()
	while true do
		if autoTrainEnabled then
			autoTrain()
		end
		if autoCastEnabled then
			autoCast()
		end
		if autoRebirthEnabled then
			autoRebirth()
		end
		if autoFishEnabled then
			autoFish()
		end
		task.wait(0.05)
	end
end)
