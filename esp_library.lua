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
        ennemies = Color3.fromRGB(153, 94, 172),
        teammates = Color3.fromRGB(158, 172, 94),
    }
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local function CalculateBox(Model)
	if not Model then return end
	local CFrame, Size = Model:GetBoundingBox()
    local Camera = workspace.CurrentCamera
	
	local CornerTable = {
		TopLeft = Camera:WorldToViewportPoint(Vector3.new(CFrame.X - Size.X / 2, CFrame.Y + Size.Y / 2, CFrame.Z)),
		TopRight = Camera:WorldToViewportPoint(Vector3.new(CFrame.X + Size.X / 2, CFrame.Y + Size.Y / 2, CFrame.Z)),
		BottomLeft = Camera:WorldToViewportPoint(Vector3.new(CFrame.X - Size.X / 2, CFrame.Y - Size.Y / 2, CFrame.Z)),
		BottomRight = Camera:WorldToViewportPoint(Vector3.new(CFrame.X + Size.X / 2, CFrame.Y - Size.Y / 2, CFrame.Z))
	}
	
	local WorldPosition, OnScreen = Camera:WorldToViewportPoint(CFrame.Position)
	local ScreenSize = Vector2.new((CornerTable.TopLeft - CornerTable.TopRight).Magnitude, (CornerTable.TopLeft - CornerTable.BottomLeft).Magnitude)
    local ScreenPosition = Vector2.new(WorldPosition.X - ScreenSize.X / 2, WorldPosition.Y - ScreenSize.Y / 2)
	return {
        WorldPosition = WorldPosition,
		ScreenPosition = ScreenPosition, 
		ScreenSize = ScreenSize,
		OnScreen = OnScreen,
        ScreenDepth = WorldPosition.Z
	}
end

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
    
    garbage.esp.texts[player.Name]["Call"] = RunService.Heartbeat:Connect(function(deltaTime)

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

        local box = CalculateBox(character)

        if box.OnScreen then
            text.Position = Vector2.new(box.ScreenPosition.X + box.ScreenSize.X/2, box.ScreenPosition.Y - 12)

            local screen_depth = box.ScreenPosition.X + box.ScreenSize.X - box.ScreenPosition.X
            screen_depth = screen_depth
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

    if (garbage.esp.texts[player.Name]["Call"] ~= nil) then
        garbage.esp.texts[player.Name]["Call"]:Disconnect()
        garbage.esp.texts[player.Name]["Call"] = nil
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