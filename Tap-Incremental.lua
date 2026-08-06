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

-- Routines
task.spawn(function()
	while true do
		if autoClickEnabled then
			AutoClickRemote:FireServer()
		end
		task.wait(0.01)
	end
end)
