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

local function hideEsp(player: Player)
    cache[player].NameEsp.Visible = false
    cache[player].NameEsp.Text = player.Name

    cache[player].HeadCircle.Visible = false
end

local function destroyEsp(player: Player)
    cache[player].NameEsp:Remove()
    cache[player].NameEsp = nil

    cache[player].HeadCircle:Remove()
    cache[player].HeadCircle = nil

    cache[player] = nil
end

local function createNameEsp(player: Player, character: Model)
    cache[player].NameEsp = Drawing.new("Text")
    cache[player].NameEsp.Font = 2
    cache[player].NameEsp.Size = 14
    cache[player].NameEsp.Color = Color3.new(0.858823, 1, 0.858823)
    cache[player].NameEsp.Outline = true
    cache[player].NameEsp.OutlineColor = Color3.new(0, 0, 0)
    cache[player].NameEsp.Center = true
    cache[player].NameEsp.Visible = true
    cache[player].NameEsp.Text = player.Name
end

local function updateNameEsp(player: Player, character: Model, screenPos: Vector3)
    cache[player].NameEsp.Position = Vector2.new(screenPos.X, screenPos.Y - 20)
    cache[player].NameEsp.Visible = true
    local humanoid: Humanoid = character:FindFirstChildOfClass("Humanoid")
    cache[player].NameEsp.Text = player.Name .. " [" .. math.floor(humanoid.Health) .. "]"
end

local function createHeadEsp(player: Player, character: Model)
    cache[player].HeadCircle = Drawing.new("Circle")
    cache[player].HeadCircle.Radius = 4
    cache[player].HeadCircle.Filled = true
    cache[player].HeadCircle.Color = Color3.new(1, 0.156862, 0.564705)
    cache[player].HeadCircle.Transparency = 0.5
    cache[player].HeadCircle.Visible = true
end

local function updateHeadEsp(player: Player, character: Model, screenPos: Vector3)
    cache[player].HeadCircle.Position = Vector2.new(screenPos.X, screenPos.Y)
    cache[player].HeadCircle.Visible = true
end

local function createEsp(player: Player, character)
    local head = character.Head
    local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
    if not onScreen then if cache[player] then hideEsp(player) end return end
    if not cache[player] then
        cache[player] = {}
        createNameEsp(player, character)
        createHeadEsp(player, character)
    end
    updateNameEsp(player, character, screenPos)
    updateHeadEsp(player, character, screenPos)
end

local function run()
    local currentCharacter = getCharacter(localPlayer)
    local currentTeam = currentCharacter and currentCharacter.Parent.Name
    for _, player: Player in pairs(players:GetPlayers()) do
        if player == localPlayer then continue end
        local character = getCharacter(player)
        if not character or currentTeam == nil or character.Parent.Name == currentTeam then
            if cache[player] then
                hideEsp(player)
            end
            continue
        end
        if not character:FindFirstChild("Head") then if cache[player] then cache[player].Visible = false cache[player].Text = player.Name end continue end
        createEsp(player, character)
    end
end

local con = runService.RenderStepped:Connect(function()
    local success, error = pcall(run)

    if not success then
        warn("Error in ESP: " .. tostring(error))
    end
end)

local playerCon = players.PlayerRemoving:Connect(function(player)
    local success, error = pcall(function()
        if cache[player] then
            destroyEsp(player)
        end
    end)

    if not success then
        warn("Error removing ESP for player " .. player.Name .. ": " .. tostring(error))
    end
end)

local keyCon = nil
keyCon = userInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        local success, error = pcall(function()
            if con then con:Disconnect() end
            if playerCon then playerCon:Disconnect() end
            if keyCon then keyCon:Disconnect() end
            for _, v in pairs(cache) do
                v.NameEsp:Remove()
            end
            cache = {}
            watermark:Remove()
            print("Safe ESP unloaded successfully.")
        end)
        if not success then
            warn("Error unloading Safe ESP: " .. tostring(error))
        end
    end
end)