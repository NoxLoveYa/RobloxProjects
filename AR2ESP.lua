local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local GUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/NoxLoveYa/RobloxProjects/refs/heads/main/librarys/uilibrary.lua"))()

local Settings = {
    BoxColorTeammates = Color3.new(0, 0.5, 1),
    BoxColor = Color3.new(1, 0.5, 0),
    BoxZombieColor = Color3.new(0.3, 0, 1),
    BoxZombieCorpsColor = Color3.new(1, 0, 0),
    BoxPlayerCorpsColor = Color3.new(1, 0.470588, 0.647058),
    BoxSize = 2,
    MaxDistance = 500,
    YOffset = 0,
    ShowBox = true,
    ShowName = true,
    ShowDistance = true,
    ShowGun = true,
    ShowHealth = true,
    TeamCheck = false
}

local function CalculateTextSize(distance)
    return math.max(10, math.min(16, 20 - (distance / 100)))
end

local function CreateQuadBox(character, color)
    local quad = Drawing.new("Quad")
    quad.Visible = false
    quad.Color = color
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

local function CreateGunTag()
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

-- Keybinds
local keybinds = {}

-- Keybinds Helper
function keybinds:AddKeybind(key, callback, options)
    options = options or {}
    local isToggle = options.toggle or false
    local currentState = false
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end -- Don't trigger if typing in chat etc
        
        if input.KeyCode == key then
            if isToggle then
                currentState = not currentState
                callback(currentState)
            else
                callback(true)
            end
        end
    end)
    
    if not isToggle then
        UserInputService.InputEnded:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            if input.KeyCode == key then
                callback(false)
            end
        end)
    end
end

-- Register Keybinds
keybinds:AddKeybind(Enum.KeyCode.Delete, function(state)
    Settings.MaxDistance += 500
    print("Increasing max distance: ", Settings.MaxDistance)
end, {toggle = true})

keybinds:AddKeybind(Enum.KeyCode.Insert, function(state)
    Settings.MaxDistance -= 500
    print("Decreasing max distance: ", Settings.MaxDistance)
end, {toggle = true})

-- ESP VAR
local boxes = {}
local nameTags = {}
local distanceTags = {}
local gunTags = {}
local healthTags = {}
local zombies = {}
local zombieNameTags = {}
local zombieDistanceTags = {}
local zombieHealthTags = {}
local corps = {}
local corpsNameTags = {}
local corpsDistanceTags = {}
local corpsHealthTags = {}

-- Helper ESP function
local function UpdateESP(quad, nameTag, distanceTag, gunTag, healthTag, character, displayName)
    local head = character:FindFirstChild("Head")
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid: Humanoid = character:FindFirstChild("Humanoid")

    if not head or not humanoidRootPart then
        quad.Visible = false
        if nameTag then nameTag.Visible = false end
        if distanceTag then distanceTag.Visible = false end
        if gunTag then gunTag.Visible = false end
        if healthTag then healthTag.Visible = false end
        return
    end

    local distance = (workspace.CurrentCamera.CFrame.Position - humanoidRootPart.Position).Magnitude

    if humanoid and humanoid.Health <= 0 or distance > Settings.MaxDistance then
        quad.Visible = false
        if nameTag then nameTag.Visible = false end
        if distanceTag then distanceTag.Visible = false end
        if gunTag then gunTag.Visible = false end
        if healthTag then healthTag.Visible = false end
        return
    end
    
    local headPos, headVisible = workspace.CurrentCamera:WorldToViewportPoint(head.Position + Vector3.new(0, 2, 0))
    local feetPos, feetVisible = workspace.CurrentCamera:WorldToViewportPoint(humanoidRootPart.Position - Vector3.new(0, 5, 0))
    
    if not headVisible or not feetVisible or headPos.Z < 0 or feetPos.Z < 0 then
        quad.Visible = false
        if nameTag then nameTag.Visible = false end
        if distanceTag then distanceTag.Visible = false end
        if gunTag then gunTag.Visible = false end
        if healthTag then healthTag.Visible = false end
        return
    end
    
    local height = math.abs(headPos.Y - feetPos.Y)
    local width = height / 2
    
    -- Update box with proper sizing
    quad.PointA = Vector2.new(headPos.X - width/2, headPos.Y)
    quad.PointB = Vector2.new(headPos.X + width/2, headPos.Y)
    quad.PointC = Vector2.new(feetPos.X + width/2, feetPos.Y)
    quad.PointD = Vector2.new(feetPos.X - width/2, feetPos.Y)
    
    quad.Visible = true
    
    local textSize = CalculateTextSize(distance)
    
    -- Update name tag (Unnamed ESP positioning)
    if nameTag then
        nameTag.Text = displayName
        nameTag.Size = textSize
        nameTag.Outline = true
        
        -- Position above the character using calculated upper position
        nameTag.Position = Vector2.new(headPos.X, headPos.Y -textSize )
        nameTag.Visible = true
    end
    
    -- Update distance tag (positioned at bottom)
    if distanceTag then
        distanceTag.Text = FormatDistance(distance)
        distanceTag.Size = textSize
        distanceTag.Outline = true
        
        -- Position at bottom of character (below feet)
        distanceTag.Position = Vector2.new(feetPos.X, feetPos.Y)
        distanceTag.Visible = true
    end

    -- Update gun tag (positioned under the distance tag)
    if gunTag ~= nil then
        local equipped = character.Equipped:GetChildren() 
        gunTag.Text = #equipped > 0 and equipped[1].Name or "Unarmed"
        gunTag.Size = textSize
        gunTag.Outline = true

        -- Position at bottom of character (below feet)
        gunTag.Position = Vector2.new(feetPos.X, feetPos.Y + textSize)
        gunTag.Visible = true
    end

    -- Update health tag (positioned on the left side of box)
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
        
        -- Position on the left side of the box
        healthTag.Position = Vector2.new(headPos.X - width/2 - textSize, headPos.Y + height / 6)
        healthTag.Visible = true
    end
end

local function ConnectEsp(player: Player)
    -- if player == Players.LocalPlayer then return end

    if player.Character then
        boxes[player] = CreateQuadBox(player.Character, (player.TeamColor == Players.LocalPlayer.TeamColor) and Settings.BoxColorTeammates or Settings.BoxColor)
        nameTags[player] = CreateNameTag()
        distanceTags[player] = CreateDistanceTag()
        gunTags[player] = CreateGunTag()
        healthTags[player] = CreateHealthTag()
    end

    player.CharacterAdded:Connect(function(character)
        boxes[player] = CreateQuadBox(character, (player.TeamColor == Players.LocalPlayer.TeamColor) and Settings.BoxColorTeammates or Settings.BoxColor)
        nameTags[player] = CreateNameTag()
        distanceTags[player] = CreateDistanceTag()
        gunTags[player] = CreateGunTag()
        healthTags[player] = CreateHealthTag()
    end)

    player.CharacterRemoving:Connect(function()
        if boxes[player] then
            boxes[player]:Remove()
            boxes[player] = nil
        end
        if nameTags[player] then
            nameTags[player]:Remove()
            nameTags[player] = nil
        end
        if distanceTags[player] then
            distanceTags[player]:Remove()
            distanceTags[player] = nil
        end
        if gunTags[player] then
            gunTags[player]:Remove()
            gunTags[player] = nil
        end
        if healthTags[player] then
            healthTags[player]:Remove()
            healthTags[player] = nil
        end
    end)

    game.Players.PlayerRemoving:Connect(function(player)
        if boxes[player] then
            boxes[player]:Remove()
            boxes[player] = nil
        end
        if nameTags[player] then
            nameTags[player]:Remove()
            nameTags[player] = nil
        end
        if distanceTags[player] then
            distanceTags[player]:Remove()
            distanceTags[player] = nil
        end
        if gunTags[player] then
            gunTags[player]:Remove()
            gunTags[player] = nil
        end
        if healthTags[player] then
            healthTags[player]:Remove()
            healthTags[player] = nil
        end
    end)
end

-- Handle Players
for _, player in pairs(game.Players:GetPlayers()) do
    ConnectEsp(player)
end
game.Players.PlayerAdded:Connect(function(player)
    ConnectEsp(player)
end)

-- Handle zombies
for _, zombie in ipairs(workspace.Zombies:GetChildren()) do
    zombies[zombie] = CreateQuadBox(zombie, Settings.BoxZombieColor)
    zombieNameTags[zombie] = CreateNameTag()
    zombieDistanceTags[zombie] = CreateDistanceTag()
    zombieHealthTags[zombie] = CreateHealthTag()
    zombie.Destroying:Connect(function()
        if zombies[zombie] then
            zombies[zombie]:Remove()
            zombies[zombie] = nil
        end
        if zombieNameTags[zombie] then
            zombieNameTags[zombie]:Remove()
            zombieNameTags[zombie] = nil
        end
        if zombieDistanceTags[zombie] then
            zombieDistanceTags[zombie]:Remove()
            zombieDistanceTags[zombie] = nil
        end
        if zombieHealthTags[zombie] then
            zombieHealthTags[zombie]:Remove()
            zombieHealthTags[zombie] = nil
        end
    end)
end
workspace.Zombies.ChildAdded:Connect(function(zombie: Model)
    zombies[zombie] = CreateQuadBox(zombie, Settings.BoxZombieColor)
    zombieNameTags[zombie] = CreateNameTag()
    zombieDistanceTags[zombie] = CreateDistanceTag()
    zombieHealthTags[zombie] = CreateHealthTag()
    zombie.Destroying:Connect(function()
        if zombies[zombie] then
            zombies[zombie]:Remove()
            zombies[zombie] = nil
        end
        if zombieNameTags[zombie] then
            zombieNameTags[zombie]:Remove()
            zombieNameTags[zombie] = nil
        end
        if zombieDistanceTags[zombie] then
            zombieDistanceTags[zombie]:Remove()
            zombieDistanceTags[zombie] = nil
        end
        if zombieHealthTags[zombie] then
            zombieHealthTags[zombie]:Remove()
            zombieHealthTags[zombie] = nil
        end
    end)
end)

-- Handle Corps
for _, corp in ipairs(workspace.Corpses:GetChildren()) do
    local isPlayer = corp:GetAttribute("InteractId") ~= nil
    corps[corp] = CreateQuadBox(corp, isPlayer and Settings.BoxPlayerCorpsColor or Settings.BoxZombieCorpsColor)
    corpsNameTags[corp] = CreateNameTag()
    corpsDistanceTags[corp] = CreateDistanceTag()
    corpsHealthTags[corp] = CreateHealthTag()
    corp.Destroying:Connect(function()
        if corps[corp] then
            corps[corp]:Remove()
            corps[corp] = nil
        end
        if corpsNameTags[corp] then
            corpsNameTags[corp]:Remove()
            corpsNameTags[corp] = nil
        end
        if corpsDistanceTags[corp] then
            corpsDistanceTags[corp]:Remove()
            corpsDistanceTags[corp] = nil
        end
    end)
end
workspace.Corpses.ChildAdded:Connect(function(corp: Model)
    local isPlayer = corp:GetAttribute("InteractId") ~= nil
    corps[corp] = CreateQuadBox(corp, isPlayer and Settings.BoxPlayerCorpsColor or Settings.BoxZombieCorpsColor)
    corpsNameTags[corp] = CreateNameTag()
    corpsDistanceTags[corp] = CreateDistanceTag()
    corpsHealthTags[corp] = CreateHealthTag()
    corp.Destroying:Connect(function()
        if corps[corp] then
            corps[corp]:Remove()
            corps[corp] = nil
        end
        if corpsNameTags[corp] then
            corpsNameTags[corp]:Remove()
            corpsNameTags[corp] = nil
        end
        if corpsDistanceTags[corp] then
            corpsDistanceTags[corp]:Remove()
            corpsDistanceTags[corp] = nil
        end
    end)
end)

-- Create Menu
local window = GUI:Load({
    sizex = 500,
    sizey = 550,
    theme = "AirHub",
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
    flag = "esp_enabled",
    callback = function(state)
        -- Toggle entire ESP visibility
        for _, box in pairs(boxes) do
            box.Visible = state
        end
        for _, box in pairs(zombies) do
            box.Visible = state
        end
        for _, box in pairs(corps) do
            box.Visible = state
        end
    end
})

generalSection:Toggle({
    name = "Team Check",
    default = false,
    flag = "esp_teamcheck",
    callback = function(state)
        Settings.TeamCheck = state
        -- Re-color all player boxes based on team check
        for player, box in pairs(boxes) do
            if player.Character then
                local isTeammate = player.TeamColor == Players.LocalPlayer.TeamColor
                if state and isTeammate then
                    box.Color = Settings.BoxColorTeammates
                else
                    box.Color = Settings.BoxColor
                end
            end
        end
    end
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
    flag = "esp_distance",
    callback = function(value)
        Settings.MaxDistance = value
    end
})

displaySection:Toggle({
    name = "Show Boxes",
    default = true,
    flag = "esp_show_box",
    callback = function(state)
        Settings.ShowBox = state
    end
})

displaySection:Toggle({
    name = "Show Names",
    default = true,
    flag = "esp_show_name",
    callback = function(state)
        Settings.ShowName = state
    end
})

displaySection:Toggle({
    name = "Show Distance",
    default = true,
    flag = "esp_show_distance",
    callback = function(state)
        Settings.ShowDistance = state
    end
})

displaySection:Toggle({
    name = "Show Gun",
    default = true,
    flag = "esp_show_gun",
    callback = function(state)
        Settings.ShowGun = state
    end
})

displaySection:Toggle({
    name = "Show Health",
    default = true,
    flag = "esp_show_health",
    callback = function(state)
        Settings.ShowHealth = state
    end
})

-- Colors Section (Left side)
local colorSection = espTab:Section({
    name = "Colors",
    side = "left"
})

colorSection:ColorPicker({
    name = "Teammate Color",
    default = Settings.BoxColorTeammates,
    flag = "color_teammates",
    callback = function(color)
        Settings.BoxColorTeammates = color
    end
})

colorSection:ColorPicker({
    name = "Enemy Color",
    default = Settings.BoxColor,
    flag = "color_enemies",
    callback = function(color)
        Settings.BoxColor = color
    end
})

colorSection:ColorPicker({
    name = "Zombie Color",
    default = Settings.BoxZombieColor,
    flag = "color_zombies",
    callback = function(color)
        Settings.BoxZombieColor = color
    end
})

colorSection:ColorPicker({
    name = "Zombie Corpse Color",
    default = Settings.BoxZombieCorpsColor,
    flag = "color_zombie_corps",
    callback = function(color)
        Settings.BoxZombieCorpsColor = color
    end
})

colorSection:ColorPicker({
    name = "Player Corpse Color",
    default = Settings.BoxPlayerCorpsColor,
    flag = "color_player_corps",
    callback = function(color)
        Settings.BoxPlayerCorpsColor = color
    end
})

-- Render ESP
game:GetService("RunService").RenderStepped:Connect(function()
    local espEnabled = GUI.flags.esp_enabled ~= false
    local showBox = GUI.flags.esp_show_box ~= false
    local showName = GUI.flags.esp_show_name ~= false
    local showDistance = GUI.flags.esp_show_distance ~= false
    local showGun = GUI.flags.esp_show_gun ~= false
    local showHealth = GUI.flags.esp_show_health ~= false
    
    -- Update zombies
    for zombie, box in pairs(zombies) do
        if espEnabled and showBox then
            box.Color = Settings.BoxZombieColor
            UpdateESP(box, showName and zombieNameTags[zombie] or nil, showDistance and zombieDistanceTags[zombie] or nil, nil, showHealth and zombieHealthTags[zombie] or nil, zombie, "Zombie")
        else
            box.Visible = false
            if zombieNameTags[zombie] then zombieNameTags[zombie].Visible = false end
            if zombieDistanceTags[zombie] then zombieDistanceTags[zombie].Visible = false end
            if zombieHealthTags[zombie] then zombieHealthTags[zombie].Visible = false end
        end
    end

    -- Update corps
    for corp, box in pairs(corps) do
        if espEnabled and showBox then
            local isPlayer = corp:GetAttribute("InteractId") ~= nil
            box.Color = isPlayer and Settings.BoxPlayerCorpsColor or Settings.BoxZombieCorpsColor
            UpdateESP(box, showName and corpsNameTags[corp] or nil, showDistance and corpsDistanceTags[corp] or nil, nil, nil, corp, corp:GetAttribute("InteractId") ~= nil and corp.Name or "DeadZombie")
        else
            box.Visible = false
            if corpsNameTags[corp] then corpsNameTags[corp].Visible = false end
            if corpsDistanceTags[corp] then corpsDistanceTags[corp].Visible = false end
            if corpsHealthTags[corp] then corpsHealthTags[corp].Visible = false end
        end
    end

    -- Update players
    for player, box in pairs(boxes) do
        if espEnabled and showBox and player.Character then
            local isTeammate = player.TeamColor == Players.LocalPlayer.TeamColor
            box.Color = isTeammate and Settings.BoxColorTeammates or Settings.BoxColor
            UpdateESP(box, showName and nameTags[player] or nil, showDistance and distanceTags[player] or nil, showGun and gunTags[player] or nil, showHealth and healthTags[player] or nil, player.Character, player.Name)
        else
            box.Visible = false
            if nameTags[player] then nameTags[player].Visible = false end
            if distanceTags[player] then distanceTags[player].Visible = false end
            if gunTags[player] then gunTags[player].Visible = false end
            if healthTags[player] then healthTags[player].Visible = false end
        end
    end
    
    -- Update watermark color
    text.Color = Color3.fromHSV(math.sin(tick() * 1.5) * 0.5 + 0.5, 0.8, 1)
end)

task.wait(0.1) -- Small delay to ensure menu is fully loaded
GUI:Close() -- This toggles it on (opens it)