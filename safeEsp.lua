local cache = {}
local players = cloneref(game:GetService("Players"))
local localPlayer = cloneref(players.LocalPlayer)
local camera = cloneref(workspace.CurrentCamera)
local runService = cloneref(game:GetService("RunService"))
local workspace = cloneref(game.Workspace)
local counterTerroristsFolder = cloneref(workspace:WaitForChild("Characters"):FindFirstChild("Counter-Terrorists"))
local terroristsFolder = cloneref(workspace:WaitForChild("Characters"):FindFirstChild("Terrorists"))
local userInputService = cloneref(game:GetService("UserInputService"))

local watermark = Drawing.new("Text")
watermark.Font = 2
watermark.Size = 20
watermark.Color = Color3.new(1, 0, 0)
watermark.Outline = true
watermark.OutlineColor = Color3.new(0, 0, 0)
watermark.Center = true
watermark.Visible = true
watermark.Text = "Safe ESP by Nox"
watermark.Position = Vector2.new(camera.ViewportSize.X / 2, 50)

local function getCharacter(player: Player)
    local character = terroristsFolder:FindFirstChild(player.Name) or counterTerroristsFolder:FindFirstChild(player.Name)
    if not character then return nil end
    return cloneref(character)
end

local function run()
    local currentCharacter = getCharacter(localPlayer)
    local currentTeam = currentCharacter and currentCharacter.Parent.Name
    for _, player: Player in pairs(players:GetPlayers()) do
        if player == localPlayer then continue end
        local character = getCharacter(player)
        if not character or character.Parent.Name == currentTeam then
            if cache[player] then
                cache[player].Visible = false
                cache[player].Text = player.Name
            end
            continue
        end
        if not character:FindFirstChild("Head") then if cache[player] then cache[player].Visible = false cache[player].Text = player.Name end continue end
        local head = character.Head
        local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
        if not onScreen then if cache[player] then cache[player].Visible = false end continue end
        if not cache[player] then
            cache[player] = Drawing.new("Text")
            cache[player].Font = 2
            cache[player].Size = 14
            cache[player].Color = Color3.new(0.858823, 1, 0.858823)
            cache[player].Outline = true
            cache[player].OutlineColor = Color3.new(0, 0, 0)
            cache[player].Center = true
            cache[player].Visible = true
            cache[player].Text = player.Name
        end
        cache[player].Position = Vector2.new(screenPos.X, screenPos.Y - 20)
        cache[player].Visible = true
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        cache[player].Text = player.Name .. " [" .. math.floor(humanoid.Health) .. "]"
    end
end

local con = runService.RenderStepped:Connect(function()
    run()
end)

local playerCon = players.PlayerRemoving:Connect(function(player)
    if cache[player] then
        cache[player]:Remove()
        cache[player] = nil
    end
end)

local keyCon = nil
keyCon = userInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if con then con:Disconnect() end
        if playerCon then playerCon:Disconnect() end
        if keyCon then keyCon:Disconnect() end
        for _, v in pairs(cache) do
            v:Remove()
        end
        cache = {}
        watermark:Remove()
    end
end)