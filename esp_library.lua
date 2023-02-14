local garbage = {
    esp = {
        texts = {

        },
        calls = {

        }
    }
}

local settings = {
    Render = {
        render_teammates = false,
        render_ennemies = true,
        font = 0,
    },
    Colors = {
        ennemies = Color3.new(1, 0.639215, 0.345098),
        teammates = Color3.new(0.384313, 0.215686, 0.701960)
    }
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local function create_esp(character: Model)

    local player = Players:GetPlayerFromCharacter(character)
    if (not player) then return end

    --create the esp
    local text = Drawing.new("Text")

    text.Text = player.Name
    text.Size = 20
    text.Font = settings.Render.font
    text.Center = true

    --teammates
    if player.TeamColor == Players.LocalPlayer.TeamColor then
        text.Color = settings.Colors.teammates
    --ennemies
    else
        text.Color = settings.Colors.ennemies
    end
    
    RunService.Heartbeat:Connect(function(deltaTime)

        local camera = workspace.CurrentCamera

        local head = character:FindFirstChild("Head")
        if not head then return end

        --update settings
        if player.TeamColor == Players.LocalPlayer.TeamColor then
            text.Color = settings.Colors.teammates
            text.Visible = settings.Render.render_teammates
        --ennemies
        else
            text.Color = settings.Colors.ennemies
            text.Visible = settings.Render.render_ennemies
        end

        text.Size = 20
        text.Font = settings.Render.font

        --calculate the screen_pos
        local screen_pos, on_screen = camera:WorldToScreenPoint(head.Position + Vector3.new(0, 1, 0))
        --skip if not on screen
        if on_screen then
            text.Position = Vector2.new(screen_pos.X, screen_pos.Y)
            text.Visible = true
        else
            text.Visible = false
        end
    end)

    table.insert(garbage.esp.texts[player.Name]["Esp"], text)
end

local function delete_esp(character: Model)

    local player = Players:GetPlayerFromCharacter(character)
    if not player then return end

    for index, value in pairs (garbage.esp.texts[player.Name]["Esp"]) do
        value:Remove()
        garbage.esp.texts[player.Name]["Esp"][index] = nil
    end
end

local function connect_esp(player: Player)

    --create table entry
    garbage.esp.calls[player.Name] = {}
    garbage.esp.texts[player.Name] = {}
    --esp table
    garbage.esp.texts[player.Name]["Esp"] = {}
    garbage.esp.texts[player.Name]["Call"] = {}

    --connect events
    garbage.esp.calls[player.Name]["CharacterAdded"] = player.CharacterAdded:Connect(create_esp)
    garbage.esp.calls[player.Name]["CharacterRemoving"] = player.CharacterRemoving:Connect(delete_esp)

    --create esp if players is already here
    if player.Character then
        create_esp(player.Character)
    end
end

local function disconnect_esp(player: Player)

    --remove esp objects
    delete_esp(player.Character)
end

garbage.esp.calls["PlayerAdded"] = Players.PlayerAdded:Connect(connect_esp)

garbage.esp.calls["PlayerRemoving"] = Players.PlayerRemoving:Connect(disconnect_esp)

local function update_settings(new_settings: table)
    settings = new_settings
end

for index, player in ipairs(Players:GetPlayers()) do
    if player == Players.LocalPlayer then continue end

    connect_esp(player)
end

return {connect_esp = connect_esp, disconnect_esp = disconnect_esp, update_settings = update_settings}