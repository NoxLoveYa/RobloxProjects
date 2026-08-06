-- cframe for fishing: -796.500916, 106.459023, -778.318237, -0.99981916, -1.00005501e-07, -0.0190182105, -9.99874175e-08, 1, -1.90192639e-09, 0.0190182105, -6.73570341e-16, -0.99981916
local Hub = loadstring(
	game:HttpGet("https://raw.githubusercontent.com/NoxLoveYa/RobloxProjects/refs/heads/main/Gui%20roblox.lua")
)()

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
local autoCastEnabled = false
local autoCastTreshold = 0.98

-- Hub Menu
local testPage = Hub.CreateTab("Test Tab", "⭐")
local sec = Hub.Section(testPage, "Farming")

local toggleFrame, _ = Hub.Toggle(testPage, "Auto Train", false, function(v)
	autoTrainEnabled = v
end)
sec.Add(toggleFrame)

local toggleFrame2, _ = Hub.Toggle(testPage, "Auto Cast", false, function(v)
	autoCastEnabled = v
end)
sec.Add(toggleFrame2)

-- Helpers Functions
local function findGuiPath(from, path)
	local current = from
	for _, key in ipairs(path) do
		if not current then
			return nil
		end
		current = current:FindFirstChild(key)
	end
	return current
end

local function VirtualMousePress(pos)
	local pos = pos or workspace.CurrentCamera.ViewportSize / 2
	virtualInput:SendMouseButton(pos, Enum.UserInputType.MouseButton1, true, 1)
	task.wait(0.1)
	virtualInput:SendMouseButton(pos, Enum.UserInputType.MouseButton1, false, 1)
end

-- Functions
local function autoTrain()
	for _, gui in ipairs(playerGui:QueryDescendants("TextButton")) do
		local guiFullName = gui:GetFullName()
		if guiFullName ~= "Players." .. localplayer.Name .. ".PlayerGui.5.1.1.1.1.3" then
			continue
		end
		firesignal(gui.Activated)
	end
end

local CAST_PATH = { "5", "1", "53", "1", "1", "1" }
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
		task.wait(0.1)
	end
end)
