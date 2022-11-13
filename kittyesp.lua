local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local localplayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local RunService = game:GetService("RunService")

local settings = {
    enable_esp = true,
    ffa = true,
    see_teammates = false,
    max_distance = 1500,
    colors = {
        ennemies = Color3.fromRGB(153, 94, 172),
        teammates = Color3.fromRGB(158, 172, 94),
        friends = Color3.fromRGB(94, 125, 172),
    }
}

local garbage = {}
local esp_call = nil
local keybinds_call = nil

local function clear_esp()
    --delete our textobjects
    for _,text in pairs(garbage) do
        text:Remove()
    end
    --clear the table containing our deleted textobjects
    table.clear(garbage)
end

esp_call = RunService.RenderStepped:Connect(function(deltaTime)
    if not localplayer then
        localplayer = Players.LocalPlayer
        return 
    end
    if not camera then
        camera = Workspace.CurrentCamera
        return 
    end
    clear_esp()

    if not settings.enable_esp then return end

    for i,player in pairs(Players:GetPlayers()) do
        --skip our localplayer
        if player == localplayer then continue end
        --check if character exist
        local character = player.Character
        if not character then continue end
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then continue end
        local health = humanoid.Health
        if not health or health <= 0 then continue end
        --check esp settings
        if not settings.ffa and not settings.see_teammates and player.TeamColor == localplayer.TeamColor then continue end
        --check distance
        local head = character:FindFirstChild("Head")
        if not head then continue end
        local world_pos = head.Position
        if not world_pos then continue end
        local distance_from_character = localplayer:DistanceFromCharacter(world_pos)
        if (distance_from_character > settings.max_distance) then continue end
        --add the text to render the esp
        local text = Drawing.new("Text")
        table.insert(garbage, text)
        text.Text = player.Name
        text.Size = 14
        text.Center = true
        text.Outline = true
        text.Font = 1
        text.Visible = false
        --check team for color
        local is_friend = (localplayer:GetFriendStatus(player) == 2)
        if settings.ffa then
            text.Color = settings.colors.ennemies
        elseif (player.TeamColor == localplayer.TeamColor) then
            text.Color = settings.colors.teammates
        else
            text.Color = settings.colors.ennemies
        end
        --calculate the screen_pos
        local screen_pos, is_visible = camera:WorldToScreenPoint(world_pos + Vector3.new(0, 1, 0))
        --skip if not on screen
        if not is_visible then continue end
        --set text pos and make it visible
        text.Position = Vector2.new(screen_pos.X, screen_pos.Y)
        text.Visible = true
    end
end)

--keybinds to change settings
keybinds_call = UserInputService.InputBegan:Connect(function(input, _ganeProcessed)
    if (input.UserInputType == Enum.UserInputType.Keyboard) then
        if (input.KeyCode == Enum.KeyCode.Delete) then
            if esp_call then esp_call:Disconnect() end
            if keybinds_call then keybinds_call:Disconnect() end
            clear_esp()
        end
        if (input.KeyCode == Enum.KeyCode.RightAlt) then
            settings.enable_esp = not settings.enable_esp
        end
        if (input.KeyCode == Enum.KeyCode.RightShift) then
            settings.see_teammates = not settings.see_teammates
        end
        if (input.KeyCode == Enum.KeyCode.RightControl) then
            settings.ffa = not settings.ffa
        end
        if (input.KeyCode == Enum.KeyCode.PageUp) then
            settings.max_distance = settings.max_distance + 50
        end
        if (input.KeyCode == Enum.KeyCode.PageDown) then
            settings.max_distance = settings.max_distance - 50
        end
    end
end)
