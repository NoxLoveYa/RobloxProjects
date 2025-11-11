local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Settings = {
    BoxColorTeammates = Color3.new(0, 0.5, 1),
    BoxColor = Color3.new(1, 0.5, 0),
    BoxZombieColor = Color3.new(0.3, 0, 1),
    BoxZombieCorpsColor = Color3.new(1, 0, 0),
    BoxPlayerCorpsColor = Color3.new(1, 0.470588, 0.647058),
    BoxSize = 2,
    MaxDistance = 500,
    YOffset = 0
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

-- Render ESP
game:GetService("RunService").RenderStepped:Connect(function()
    -- Update zombies
    for zombie, box in pairs(zombies) do
        UpdateESP(box, zombieNameTags[zombie], zombieDistanceTags[zombie], nil, zombieHealthTags[zombie], zombie, "Zombie")
    end

    -- Update corps
    for corp, box in pairs(corps) do
        UpdateESP(box, corpsNameTags[corp], corpsDistanceTags[corp], nil, nil, corp, corp:GetAttribute("InteractId") ~= nil and corp.Name or "DeadZombie")
    end

    -- Update players
    for player, box in pairs(boxes) do
        UpdateESP(box, nameTags[player], distanceTags[player], gunTags[player], healthTags[player], player.Character, player.Name)
    end
    
    -- Update watermark color
    text.Color = Color3.fromHSV(math.sin(tick() * 1.5) * 0.5 + 0.5, 0.8, 1)
end)
