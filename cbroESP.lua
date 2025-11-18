local Players = game:GetService('Players')
local InputService = game:GetService('UserInputService')
local RunService = game:GetService('RunService')

local GUI = loadstring(
    game:HttpGet(
        'https://raw.githubusercontent.com/NoxLoveYa/RobloxProjects/refs/heads/main/librarys/uilibrary.lua'
    )
)()

-- Load Aim Assist Library
local AimAssist = loadstring(
    game:HttpGet(
        'https://raw.githubusercontent.com/NoxLoveYa/RobloxProjects/refs/heads/main/librarys/aimassist.lua'
    )
)()
local MyAimAssist = AimAssist.new()
MyAimAssist:Start()

local Settings = {
    BoxColor = Color3.new(1, 0.113725, 0.380392),
    MaxDistance = 2500,
    ShowBox = true,
    ShowName = true,
    ShowDistance = true,
    ShowHealth = true,
}

local function CalculateTextSize(distance)
    return math.max(10, math.min(16, 20 - (distance / 100)))
end

local function CreateQuadBox()
    local quad = Drawing.new('Quad')
    quad.Visible = false
    quad.Color = Settings.BoxColor
    quad.Thickness = 2
    quad.Filled = false
    return quad
end

local function CreateNameTag()
    local text = Drawing.new('Text')
    text.Visible = false
    text.Size = 12
    text.Center = true
    text.Outline = true
    text.OutlineColor = Color3.new(0, 0, 0)
    text.Color = Color3.new(255, 255, 255)
    return text
end

local function FormatDistance(distance)
    return tostring(math.floor(distance)) .. 'm'
end

local function CreateDistanceTag()
    local text = Drawing.new('Text')
    text.Visible = false
    text.Size = 12
    text.Center = true
    text.Outline = true
    text.OutlineColor = Color3.new(0, 0, 0)
    text.Color = Color3.new(255, 255, 255)
    return text
end

local function CreateHealthTag()
    local text = Drawing.new('Text')
    text.Visible = false
    text.Size = 12
    text.Center = true
    text.Outline = true
    text.OutlineColor = Color3.new(0, 0, 0)
    text.Color = Color3.new(0, 255, 0)
    return text
end

-- Menu
local text = Drawing.new('Text')
text.Visible = true
text.Text = 'Kitty ESP V0.1'
text.Outline = true
text.Position = Vector2.new(125, 5)

-- ESP Variables (new architecture)
local esp = {} -- Main ESP table storing all player data

-- Helper ESP function
local function UpdateESP(playerData, character, displayName)
    local head = character:FindFirstChild('Head')
    local humanoidRootPart = character:FindFirstChild('HumanoidRootPart')
    local humanoid = character:FindFirstChild('Humanoid')

    if not head or not humanoidRootPart then
        playerData.Box.Visible = false
        if playerData.NameTag then
            playerData.NameTag.Visible = false
        end
        if playerData.DistanceTag then
            playerData.DistanceTag.Visible = false
        end
        if playerData.HealthTag then
            playerData.HealthTag.Visible = false
        end
        return
    end

    local distance = (
        workspace.CurrentCamera.CFrame.Position - humanoidRootPart.Position
    ).Magnitude

    if humanoid and humanoid.Health <= 0 or distance > Settings.MaxDistance then
        playerData.Box.Visible = false
        if playerData.NameTag then
            playerData.NameTag.Visible = false
        end
        if playerData.DistanceTag then
            playerData.DistanceTag.Visible = false
        end
        if playerData.HealthTag then
            playerData.HealthTag.Visible = false
        end
        return
    end

    local headPos, headVisible = workspace.CurrentCamera:WorldToViewportPoint(
        head.Position + Vector3.new(0, 2, 0)
    )
    local feetPos, feetVisible = workspace.CurrentCamera:WorldToViewportPoint(
        humanoidRootPart.Position - Vector3.new(0, 5, 0)
    )

    if not headVisible or not feetVisible or headPos.Z < 0 or feetPos.Z < 0 then
        playerData.Box.Visible = false
        if playerData.NameTag then
            playerData.NameTag.Visible = false
        end
        if playerData.DistanceTag then
            playerData.DistanceTag.Visible = false
        end
        if playerData.HealthTag then
            playerData.HealthTag.Visible = false
        end
        return
    end

    local height = math.abs(headPos.Y - feetPos.Y)
    local width = height / 2

    -- Update box
    playerData.Box.PointA = Vector2.new(headPos.X - width / 2, headPos.Y)
    playerData.Box.PointB = Vector2.new(headPos.X + width / 2, headPos.Y)
    playerData.Box.PointC = Vector2.new(feetPos.X + width / 2, feetPos.Y)
    playerData.Box.PointD = Vector2.new(feetPos.X - width / 2, feetPos.Y)

    playerData.Box.Visible = Settings.ShowBox
    playerData.Box.Color = Settings.BoxColor

    local textSize = CalculateTextSize(distance)

    -- Update name tag
    if playerData.NameTag then
        playerData.NameTag.Text = displayName
        playerData.NameTag.Size = textSize
        playerData.NameTag.Outline = true
        playerData.NameTag.Position =
            Vector2.new(headPos.X, headPos.Y - textSize)
        playerData.NameTag.Visible = Settings.ShowName
    end

    -- Update distance tag
    if playerData.DistanceTag then
        playerData.DistanceTag.Text = FormatDistance(distance)
        playerData.DistanceTag.Size = textSize
        playerData.DistanceTag.Outline = true
        playerData.DistanceTag.Position = Vector2.new(feetPos.X, feetPos.Y)
        playerData.DistanceTag.Visible = Settings.ShowDistance
    end

    -- Update health tag
    if playerData.HealthTag then
        if not humanoid then
            playerData.HealthTag.Visible = false
            return
        end
        local healthPercent = humanoid
                and math.floor((humanoid.Health / humanoid.MaxHealth) * 100)
            or 0
        playerData.HealthTag.Text = healthPercent .. '%'
        playerData.HealthTag.Size = textSize
        playerData.HealthTag.Outline = true

        -- Color gradient based on health
        if healthPercent > 75 then
            playerData.HealthTag.Color = Color3.fromRGB(0, 255, 0) -- Green
        elseif healthPercent > 50 then
            playerData.HealthTag.Color = Color3.fromRGB(255, 255, 0) -- Yellow
        elseif healthPercent > 25 then
            playerData.HealthTag.Color = Color3.fromRGB(255, 165, 0) -- Orange
        else
            playerData.HealthTag.Color = Color3.fromRGB(255, 0, 0) -- Red
        end

        playerData.HealthTag.Position = Vector2.new(
            headPos.X - width / 2 - textSize,
            headPos.Y + height / 10
        )
        playerData.HealthTag.Visible = Settings.ShowHealth
    end
end

local function ConnectEsp(player)
    -- Skip local player
    if player == Players.LocalPlayer then
        return
    end

    local function CreatePlayerESP()
        return {
            Box = CreateQuadBox(),
            NameTag = CreateNameTag(),
            DistanceTag = CreateDistanceTag(),
            HealthTag = CreateHealthTag(),
        }
    end

    if player.Character then
        esp[player] = CreatePlayerESP()
    end

    player.CharacterAdded:Connect(function(character)
        esp[player] = CreatePlayerESP()
    end)

    player.CharacterRemoving:Connect(function()
        if esp[player] then
            for _, drawingObject in pairs(esp[player]) do
                if drawingObject then
                    drawingObject:Remove()
                end
            end
            esp[player] = nil
        end
    end)

    game.Players.PlayerRemoving:Connect(function(removedPlayer)
        if removedPlayer == player and esp[player] then
            for _, drawingObject in pairs(esp[player]) do
                if drawingObject then
                    drawingObject:Remove()
                end
            end
            esp[player] = nil
        end
    end)
end

-- Handle Players (skip local player)
for _, player in pairs(game.Players:GetPlayers()) do
    ConnectEsp(player)
end

game.Players.PlayerAdded:Connect(function(player)
    ConnectEsp(player)
end)

-- Create Menu
local window = GUI:Load({
    sizex = 550,
    sizey = 450,
    theme = 'Kitty',
    folder = 'ESP',
    extension = 'cfg',
})

-- General Tab
local generalTab = window:Tab('General')

local generalSection = generalTab:Section({
    name = 'Main Settings',
    side = 'left',
})

generalSection:Toggle({
    name = 'Enabled',
    default = true,
    flag = 'esp_enabled',
})

-- generalSection:Toggle({
--     name = 'Triggerbot (Experimental)',
--     default = true,
--     flag = 'general_triggerbot',
-- })

-- ESP Tab
local espTab = window:Tab('ESP')

-- Display Options Section
local displaySection = espTab:Section({
    name = 'Ennemies Options',
    side = 'left',
})

displaySection:Slider({
    name = 'Max Distance',
    min = 100,
    max = 5000,
    float = 50,
    default = Settings.MaxDistance,
    text = '[value]m',
    flag = 'esp_distance',
})

displaySection:Toggle({
    name = 'Show Boxes',
    default = true,
    flag = 'esp_show_box',
})

displaySection:Toggle({
    name = 'Show Names',
    default = true,
    flag = 'esp_show_name',
})

displaySection:Toggle({
    name = 'Show Distance',
    default = true,
    flag = 'esp_show_distance',
})

displaySection:Toggle({
    name = 'Show Health',
    default = true,
    flag = 'esp_show_health',
})

-- Colors Section
local colorSection = espTab:Section({
    name = 'Colors',
    side = 'left',
})

colorSection:ColorPicker({
    name = 'Player Color',
    default = Settings.BoxColor,
    flag = 'color_players',
})

-- AIM ASSIST TAB (NEW)
local aimAssistTab = window:Tab('Aim Assist')

local aimAssistSection = aimAssistTab:Section({
    name = 'Aim Assist Settings',
    side = 'left',
})

aimAssistSection:Toggle({
    name = 'Aim Assist',
    default = true,
    flag = 'aim_assist_enabled',
})

aimAssistSection:Slider({
    name = 'Strength',
    min = 0.1,
    max = 10.0,
    float = 0.1,
    default = 10.0,
    text = '[value]',
    flag = 'aim_assist_strength',
})

aimAssistSection:Slider({
    name = 'FOV',
    min = 5,
    max = 90,
    float = 1,
    default = 30,
    text = '[value]°',
    flag = 'aim_assist_fov',
})

aimAssistSection:Dropdown({
    name = 'Target Part',
    values = { 'Head', 'HumanoidRootPart', 'UpperTorso' },
    default = 'Head',
    flag = 'aim_assist_target_part',
})

local aimAssistOptionsSection = aimAssistTab:Section({
    name = 'Options',
    side = 'right',
})

aimAssistOptionsSection:Toggle({
    name = 'Require Right Click',
    default = true,
    flag = 'aim_assist_require_mouse',
})

aimAssistOptionsSection:Toggle({
    name = 'Team Check',
    default = false,
    flag = 'aim_assist_team_check',
})

aimAssistOptionsSection:Toggle({
    name = 'Visibility Check',
    default = false,
    flag = 'aim_assist_visible_check',
})

-- Status display for aim assist
local aimAssistStatus = Drawing.new('Text')
aimAssistStatus.Visible = true
aimAssistStatus.Text = 'Aim Assist: OFF'
aimAssistStatus.Size = 14
aimAssistStatus.Outline = true
aimAssistStatus.Position = Vector2.new(125, 25)
aimAssistStatus.Color = Color3.new(1, 0.3, 0.3)

-- Render ESP
RunService.RenderStepped:Connect(function()
    local espEnabled = GUI.flags.esp_enabled ~= false

    -- Update settings from GUI flags
    Settings.MaxDistance = GUI.flags.esp_distance or Settings.MaxDistance
    Settings.ShowBox = GUI.flags.esp_show_box ~= false
    Settings.ShowName = GUI.flags.esp_show_name ~= false
    Settings.ShowDistance = GUI.flags.esp_show_distance ~= false
    Settings.ShowHealth = GUI.flags.esp_show_health ~= false
    Settings.BoxColor = GUI.flags.color_players or Settings.BoxColor

    -- Update aim assist settings from GUI flags
    MyAimAssist.Settings.Enabled = GUI.flags.aim_assist_enabled or true
    MyAimAssist.Settings.Strength = GUI.flags.aim_assist_strength or 10.0
    MyAimAssist.Settings.FOV = GUI.flags.aim_assist_fov or 30
    MyAimAssist.Settings.TargetPart = GUI.flags.aim_assist_target_part or 'Head'
    MyAimAssist.Settings.RequireMouseDown = GUI.flags.aim_assist_require_mouse
        or false
    MyAimAssist.Settings.TeamCheck = GUI.flags.aim_assist_team_check or false
    MyAimAssist.Settings.VisibleCheck = GUI.flags.aim_assist_visible_check
        or false
    --MyAimAssist.Settings.TriggerbotEnabled = GUI.flags.general_triggerbot or true

    -- Update aim assist status display
    if MyAimAssist.Settings.Enabled then
        if MyAimAssist.AimAssistActive then
            aimAssistStatus.Text = 'Aim Assist: ACTIVE'
            aimAssistStatus.Color = Color3.new(0.3, 1, 0.3) -- Green
        else
            aimAssistStatus.Text = 'Aim Assist: READY'
            aimAssistStatus.Color = Color3.new(1, 1, 1) -- White
        end
    else
        aimAssistStatus.Text = 'Aim Assist: OFF'
        aimAssistStatus.Color = Color3.new(1, 0.3, 0.3) -- Red
    end

    if not espEnabled then
        -- Hide everything if ESP is disabled
        for _, playerData in pairs(esp) do
            if playerData then
                for _, drawingObject in pairs(playerData) do
                    if drawingObject then
                        drawingObject.Visible = false
                    end
                end
            end
        end
        return
    end

    -- Update players (skip local player)
    for player, playerData in pairs(esp) do
        if player.Character and player ~= Players.LocalPlayer then
            UpdateESP(playerData, player.Character, player.Name)
        end
    end

    -- Update watermark color
    text.Color = Color3.fromHSV(math.sin(tick() * 1.5) * 0.5 + 0.5, 0.8, 1)
end)

task.wait(0.1)
InputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.RightAlt then
        GUI:Close()
    end
    print(input.KeyCode)
end)

print('🎯 Kitty ESP + Aim Assist Loaded!')
print('✅ RightAlt: Toggle Menu')
print('🎯 Aim Assist integrated with full menu control')
