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

-- Force Auto Farm to the top (independent of library CreateTab order support)
local autoFarmData = Hub.Pages and Hub.Pages["Auto Farm"]
if autoFarmData then
	for _, data in pairs(Hub.Pages) do
		if data ~= autoFarmData and data.LayoutOrder >= 1 then
			data.LayoutOrder = data.LayoutOrder + 1
			data.Btn.LayoutOrder = data.Btn.LayoutOrder + 1
		end
	end
	autoFarmData.LayoutOrder = 1
	autoFarmData.Btn.LayoutOrder = 1
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
