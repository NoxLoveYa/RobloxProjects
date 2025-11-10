local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local Settings = {
    BoxColor = Color3.new(0.515, 1, 0),
    BoxSize = 2,
    MaxDistance = 500
}

local PlayersEsp = {}

function initEsp(player: Player)
    local test = Drawing.new("Square")
    table.insert(PlayersEsp, test)
    print(#PlayersEsp)
    print("Initialized ESP for player: " .. player.Name..": ", table.concat(test, '\n'))
    -- test.Trasnparency = 1
    -- test.Thickness = 2
    -- test.Size = Vector2.new(50, 50)
    -- test.Position = Vector2.new(100, 100)
    -- test.color = Settings.BoxColor
    -- if player.Character then
    --     createOverlay(player.Character)
    -- end

    -- player.CharacterAdded:Connect(function(character)
    --     createOverlay(character)
    -- end)

    -- player.CharacterRemoving:Connect(function(character)
    --     ActiveOverlays[character] = nil
    -- end)
end

for _, player in ipairs(Players:GetPlayers()) do
    initEsp(player)
end
Players.PlayerAdded:Connect(initEsp)

-- for _, zombies: Model in ipairs(workspace.Zombies:GetChildren()) do
--     print(zombies.Name)
--     local humanoid = zombies:FindFirstChild("HumanoidRootPart")
--     print(humanoid)
--     if humanoid then
--         createOverlay(zombies)
--     end
-- end
-- workspace.Zombies.ChildAdded:Connect(function(zombies: Model)
--     local humanoid = zombies:FindFirstChild("HumanoidRootPart")
--     if humanoid then
--         createOverlay(zombies)
--     end
-- end)

-- RunService.RenderStepped:Connect(function()
--     for character, overlay in pairs(ActiveOverlays) do
--         local hrp = character:FindFirstChild("HumanoidRootPart")
--         if not hrp then 
--             overlay.Enabled = false
--             continue
--         end 

--         local dist = (Camera.CFrame.Position - hrp.Position).Magnitude

--         overlay.Enabled = (dist <= Settings.MaxDistance)
--     end
-- end)
