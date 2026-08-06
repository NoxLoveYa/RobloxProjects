local Hub = loadstring(
	game:HttpGet("https://raw.githubusercontent.com/NoxLoveYa/RobloxProjects/refs/heads/main/Gui%20roblox.lua")
)()

local AutoClickRemote = game:GetService("ReplicatedStorage").Remotes.Tap

-- Var
local autoClickEnabled = false

-- Hub Menu
local autoFarmPage = Hub.CreateTab("Auto Farm", "⚙", 1)
local sec = Hub.Section(autoFarmPage, "FARMING")

local toggleFrame, _ = Hub.Toggle(autoFarmPage, "Auto Click", false, function(v)
	autoClickEnabled = v
end)
sec.Add(toggleFrame)

-- Functions
local function autoBuy()
	for _, gui in ipairs(game:GetService("Players").LocalPlayer.PlayerGui:QueryDescendants("TextButton")) do
		if gui.Text ~= "Max" then
			continue
		end
		local color = gui:GetChildren("UIGradient")

		if
			color
			and color.Color
				== ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(246, 255, 76)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(119, 73, 0)),
				})
		then
			firesignal(gui.Activated)
		end
	end
end

-- Routines
task.spawn(function()
	while true do
		if autoClickEnabled then
			AutoClickRemote:FireServer()
		end
		task.wait(0.01)
	end
end)
