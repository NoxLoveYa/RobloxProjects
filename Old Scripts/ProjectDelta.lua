-- Services
local Workspace: Instance = cloneref(workspace)
local Players: Players = cloneref(game:GetService("Players"))
local RunService: RunService = cloneref(game:GetService("RunService"))

-- CONSTANTS

-- Cache
local Connections = {}
local EspObjects = {}

-- Functions
local function disconnectConnections()
    for _, connection in Connections do
        connection:Disconnect()
    end
end

-- Cheat Functions
local function onPlayerAddedEsp(player: Player)
    local espObjects = {}

    local nameText = Drawing.new("Text")
    nameText.Text = player.DisplayName
    nameText.Visible = false

    table.insert(espObjects, nameText)

    EspObjects[player.UserId] = espObjects
end

local function onPlayerRemoved(player: Player)
    local espObjects = EspObjects[player.UserId]

    for _, espObject in ipairs(espObjects) do
        espObject:Destroy()
    end
    EspObjects[player.UserId] = nil
end

local function updateVisibilityForPlayer(player: Player, visible: boolean)
    local espObject = EspObjects[player.UserId]

    if not espObject then return nil end

    for _, drawing in pairs(espObject) do
        drawing.Visible = visible
    end

    return espObject
end

local function updateEspVisibility()
    for _, player: Player in ipairs(Players:GetPlayers()) do
        local character: Model = player.Character

        if not character or player == Players.LocalPlayer then updateVisibilityForPlayer(player, false) end

        local espObject = updateVisibilityForPlayer(player, true)

        if not espObject then continue end
    end
end

-- Connections
table.insert(Connections, Players.PlayerAdded:Connect(onPlayerAddedEsp))
table.insert(Connections, Players.PlayerRemoving:Connect(onPlayerRemoved))

table.insert(Connections, RunService.RenderStepped:Connect(updateEspVisibility))