local Players = game:GetService("Players")

local GUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/NoxLoveYa/RobloxProjects/refs/heads/main/librarys/uilibrary.lua"))()

local Settings = {
    BoxColor = Color3.new(0, 0.5, 1),
    MaxDistance = 500,
    ShowBox = true,
    ShowName = true,
    ShowDistance = true,
    ShowHealth = true
}

local function CalculateTextSize(distance)
    return math.max(10, math.min(16, 20 - (distance / 100)))
end

local function CreateQuadBox()
    local quad = Drawing.new("Quad")
    quad.Visible = false
    quad.Color = Settings.BoxColor
    quad.Thickness = 2
    quad.Filled = false
    return quad
end

local function CreateNameTag()
    local text = Drawing.new("Text")
    text.Visible = false
    text.Size = 12
    text.Center = true
    text.Outline = true
    text.OutlineColor = Color3.new(0, 0, 0)
    text.Color = Color3.new(255, 255, 255)
    return text
end

local function FormatDistance(distance)
    return tostring(math.floor(distance)) .. "m"
end

local function CreateDistanceTag()
    local text = Drawing.new("Text")
    text.Visible = false
    text.Size = 12
    text.Center = true
    text.Outline = true
    text.OutlineColor = Color3.new(0, 0, 0)
    text.Color = Color3.new(255, 255, 255)
    return text
end

local function CreateHealthTag()
    local text = Drawing.new("Text")
    text.Visible = false
    text.Size = 12
    text.Center = true
    text.Outline = true
    text.OutlineColor = Color3.new(0, 0, 0)
    text.Color = Color3.new(0, 255, 0)
    return text
end

-- Menu
local text = Drawing.new("Text")
text.Visible = true
text.Text = "Kitty ESP V0.1"
text.Outline = true
text.Position = Vector2.new(125, 5)

-- ESP Variables
local boxes = {}
local nameTags = {}
local distanceTags = {}
local healthTags = {}

-- Helper ESP function
local function UpdateESP(quad, nameTag, distanceTag, healthTag, character, displayName)
    local head = character:FindFirstChild("Head")
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")

    if not head or not humanoidRootPart then
        quad.Visible = false
        if nameTag then nameTag.Visible = false end
        if distanceTag then distanceTag.Visible = false end
        if healthTag then healthTag.Visible = false end
        return
    end

    local distance = (workspace.CurrentCamera.CFrame.Position - humanoidRootPart.Position).Magnitude

    if humanoid and humanoid.Health <= 0 or distance > Settings.MaxDistance then
        quad.Visible = false
        if nameTag then nameTag.Visible = false end
        if distanceTag then distanceTag.Visible = false end
        if healthTag then healthTag.Visible = false end
        return
    end
    
    local headPos, headVisible = workspace.CurrentCamera:WorldToViewportPoint(head.Position + Vector3.new(0, 2, 0))
    local feetPos, feetVisible = workspace.CurrentCamera:WorldToViewportPoint(humanoidRootPart.Position - Vector3.new(0, 5, 0))
    
    if not headVisible or not feetVisible or headPos.Z < 0 or feetPos.Z < 0 then
        quad.Visible = false
        if nameTag then nameTag.Visible = false end
        if distanceTag then distanceTag.Visible = false end
        if healthTag then healthTag.Visible = false end
        return
    end
    
    local height = math.abs(headPos.Y - feetPos.Y)
    local width = height / 2
    
    -- Update box
    quad.PointA = Vector2.new(headPos.X - width/2, headPos.Y)
    quad.PointB = Vector2.new(headPos.X + width/2, headPos.Y)
    quad.PointC = Vector2.new(feetPos.X + width/2, feetPos.Y)
    quad.PointD = Vector2.new(feetPos.X - width/2, feetPos.Y)
    
    quad.Visible = Settings.ShowBox
    quad.Color = Settings.BoxColor
    
    local textSize = CalculateTextSize(distance)
    
    -- Update name tag
    if nameTag then
        nameTag.Text = displayName
        nameTag.Size = textSize
        nameTag.Outline = true
        nameTag.Position = Vector2.new(headPos.X, headPos.Y - textSize)
        nameTag.Visible = Settings.ShowName
    end
    
    -- Update distance tag
    if distanceTag then
        distanceTag.Text = FormatDistance(distance)
        distanceTag.Size = textSize
        distanceTag.Outline = true
        distanceTag.Position = Vector2.new(feetPos.X, feetPos.Y)
        distanceTag.Visible = Settings.ShowDistance
    end

    -- Update health tag
    if healthTag then
        if not humanoid then
            healthTag.Visible = false
            return
        end
        local healthPercent = humanoid and math.floor((humanoid.Health / humanoid.MaxHealth) * 100) or 0
        healthTag.Text = healthPercent .. "%"
        healthTag.Size = textSize
        healthTag.Outline = true
        
        -- Color gradient based on health
        if healthPercent > 75 then
            healthTag.Color = Color3.fromRGB(0, 255, 0)  -- Green
        elseif healthPercent > 50 then
            healthTag.Color = Color3.fromRGB(255, 255, 0)  -- Yellow
        elseif healthPercent > 25 then
            healthTag.Color = Color3.fromRGB(255, 165, 0)  -- Orange
        else
            healthTag.Color = Color3.fromRGB(255, 0, 0)  -- Red
        end
        
        healthTag.Position = Vector2.new(headPos.X - width/2 - textSize, headPos.Y + height / 6)
        healthTag.Visible = Settings.ShowHealth
    end
end

local function ConnectEsp(player)
    -- Skip local player
    if player == Players.LocalPlayer then return end

    if player.Character then
        boxes[player] = CreateQuadBox()
        nameTags[player] = CreateNameTag()
        distanceTags[player] = CreateDistanceTag()
        healthTags[player] = CreateHealthTag()
    end

    player.CharacterAdded:Connect(function(character)
        boxes[player] = CreateQuadBox()
        nameTags[player] = CreateNameTag()
        distanceTags[player] = CreateDistanceTag()
        healthTags[player] = CreateHealthTag()
    end)

    player.CharacterRemoving:Connect(function()
        if boxes[player] then boxes[player]:Remove() boxes[player] = nil end
        if nameTags[player] then nameTags[player]:Remove() nameTags[player] = nil end
        if distanceTags[player] then distanceTags[player]:Remove() distanceTags[player] = nil end
        if healthTags[player] then healthTags[player]:Remove() healthTags[player] = nil end
    end)

    game.Players.PlayerRemoving:Connect(function(removedPlayer)
        if removedPlayer == player then
            if boxes[player] then boxes[player]:Remove() boxes[player] = nil end
            if nameTags[player] then nameTags[player]:Remove() nameTags[player] = nil end
            if distanceTags[player] then distanceTags[player]:Remove() distanceTags[player] = nil end
            if healthTags[player] then healthTags[player]:Remove() healthTags[player] = nil end
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
    sizex = 300,
    sizey = 300,
    theme = "Kitty",
    folder = "AR2ESP",
    extension = "cfg"
})

-- General Tab
local generalTab = window:Tab("General")

local generalSection = generalTab:Section({
    name = "Main Settings",
    side = "left"
})

generalSection:Toggle({
    name = "Enabled",
    default = true,
    flag = "esp_enabled"
})

-- ESP Tab
local espTab = window:Tab("ESP")

-- Display Options Section
local displaySection = espTab:Section({
    name = "Display Options",
    side = "left"
})

displaySection:Slider({
    name = "Max Distance",
    min = 100,
    max = 5000,
    float = 50,
    default = Settings.MaxDistance,
    text = "[value]m",
    flag = "esp_distance"
})

displaySection:Toggle({
    name = "Show Boxes",
    default = true,
    flag = "esp_show_box"
})

displaySection:Toggle({
    name = "Show Names",
    default = true,
    flag = "esp_show_name"
})

displaySection:Toggle({
    name = "Show Distance",
    default = true,
    flag = "esp_show_distance"
})

displaySection:Toggle({
    name = "Show Health",
    default = true,
    flag = "esp_show_health"
})

-- Colors Section
local colorSection = espTab:Section({
    name = "Colors",
    side = "left"
})

colorSection:ColorPicker({
    name = "Player Color",
    default = Settings.BoxColor,
    flag = "color_players"
})

-- Render ESP
game:GetService("RunService").RenderStepped:Connect(function()
    local espEnabled = GUI.flags.esp_enabled ~= false
    
    -- Update settings from GUI flags
    Settings.MaxDistance = GUI.flags.esp_distance or Settings.MaxDistance
    Settings.ShowBox = GUI.flags.esp_show_box ~= false
    Settings.ShowName = GUI.flags.esp_show_name ~= false
    Settings.ShowDistance = GUI.flags.esp_show_distance ~= false
    Settings.ShowHealth = GUI.flags.esp_show_health ~= false
    Settings.BoxColor = GUI.flags.color_players or Settings.BoxColor
    
    if not espEnabled then
        -- Hide everything if ESP is disabled
        for _, box in pairs(boxes) do box.Visible = false end
        for _, tag in pairs(nameTags) do tag.Visible = false end
        for _, tag in pairs(distanceTags) do tag.Visible = false end
        for _, tag in pairs(healthTags) do tag.Visible = false end
        return
    end
    
    -- Update players (skip local player)
    for player, box in pairs(boxes) do
        if player.Character and player ~= Players.LocalPlayer then
            UpdateESP(box, nameTags[player], distanceTags[player], healthTags[player], player.Character, player.Name)
        end
    end
    
    -- Update watermark color
    text.Color = Color3.fromHSV(math.sin(tick() * 1.5) * 0.5 + 0.5, 0.8, 1)
end)

task.wait(0.1)
GUI:Close()