-- cframe for fishing: -796.500916, 106.459023, -778.318237, -0.99981916, -1.00005501e-07, -0.0190182105, -9.99874175e-08, 1, -1.90192639e-09, 0.0190182105, -6.73570341e-16, -0.99981916
--loadstring(game:HttpGet("https://raw.githubusercontent.com/NoxLoveYa/RobloxProjects/refs/heads/main/Gui%20roblox.lua"))()

-- Includes
local Players: Players = game:GetService("Players")

-- Var
local localplayer: Player = game.Players.LocalPlayer
local humanoid: Humanoid = nil
local character: Model = nil
local rootpart: BasePart = nil

-- Menu Elements
local HudGui: ScreenGui = localplayer:WaitForChild("PlayerGui"):WaitForChild("5", 5)
local TrainingFrame: Frame = HudGui:WaitForChild("1", 5)

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
        for _, gui in ipairs(Players.LocalPlayer:QueryDescendants("TextButton")) do
            local guiFullName = gui:GetFullName()
            if guiFullName ~= "Players.akyw.PlayerGui.5.1.1.1.1.3" then continue end
            firesignal(gui.Activated)
        end
        task.wait(0.1)
    end
end)