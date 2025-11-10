local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Settings = {
    BoxColorTeammates = Color3.new(0, 0.5, 1),
    BoxColor = Color3.new(1, 0.5, 0),
    BoxZombieColor = Color3.new(0.3, 0, 1),
    BoxSize = 2,
    MaxDistance = 500
}

local keybinds = {}

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

keybinds:AddKeybind(Enum.KeyCode.Delete, function(state)
    Settings.MaxDistance += 500
    print("Increasing max distance: ", Settings.MaxDistance)
end, {toggle = true})

keybinds:AddKeybind(Enum.KeyCode.Insert, function(state)
    Settings.MaxDistance -= 500
    print("Decreasing max distance: ", Settings.MaxDistance)
end, {toggle = true})

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
    return text
end

local function UpdateESP(quad, nameTag, distanceTag, character, displayName)
    local head = character:FindFirstChild("Head")
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid: Humanoid = character:FindFirstChild("Humanoid")

    if not head or not humanoidRootPart then
        quad.Visible = false
        if nameTag then nameTag.Visible = false end
        if distanceTag then distanceTag.Visible = false end
        return
    end

    local distance = (workspace.CurrentCamera.CFrame.Position - humanoidRootPart.Position).Magnitude

    if not head or not humanoidRootPart or humanoid and humanoid.Health <= 0 or distance > Settings.MaxDistance then
        quad.Visible = false
        if nameTag then
            nameTag.Visible = false
        end
        if distanceTag then
            distanceTag.Visible = false
        end
        return
    end
    
    local headPos, headVisible = workspace.CurrentCamera:WorldToViewportPoint(head.Position + Vector3.new(0, 1, 0))
    local feetPos, feetVisible = workspace.CurrentCamera:WorldToViewportPoint(humanoidRootPart.Position - Vector3.new(0, 4, 0))
    
    if not headVisible or not feetVisible or headPos.Z < 0 or feetPos.Z < 0 then
        quad.Visible = false
        if nameTag then
            nameTag.Visible = false
        end
        if distanceTag then
            distanceTag.Visible = false
        end
        return
    end
    
    local height = math.abs(headPos.Y - feetPos.Y)
    local width = height / 2
    
    -- Update box
    quad.PointA = Vector2.new(headPos.X - width/2, headPos.Y)
    quad.PointB = Vector2.new(headPos.X + width/2, headPos.Y)
    quad.PointC = Vector2.new(feetPos.X + width/2, feetPos.Y)
    quad.PointD = Vector2.new(feetPos.X - width/2, feetPos.Y)
    
    quad.Visible = true
    

    local textSize = CalculateTextSize(distance)
    if nameTag then
        nameTag.Text = displayName
        nameTag.Size = textSize
        nameTag.Position = Vector2.new(headPos.X, headPos.Y - 18) -- Position above head
        nameTag.Color = quad.Color
        nameTag.Visible = true
    end
    if distanceTag then
        distanceTag.Text = FormatDistance(distance)
        distanceTag.Size = textSize
        distanceTag.Position = Vector2.new(feetPos.X, feetPos.Y) -- Position under feet
        distanceTag.Color = quad.Color
        distanceTag.Visible = true
    end
end

local boxes = {}
local nameTags = {}
local distanceTags = {}
local zombies = {}
local zombieNameTags = {}
local zombieDistanceTags = {}

local function ConnectEsp(player: Player)
    if player == Players.LocalPlayer then return end

    if player.Character then
        boxes[player] = CreateQuadBox(player.Character, (player.Team == Players.LocalPlayer.Team) and Settings.BoxColorTeammates or Settings.BoxColor)
        nameTags[player] = CreateNameTag()
        distanceTags[player] = CreateDistanceTag()
    end

    player.CharacterAdded:Connect(function(character)
        boxes[player] = CreateQuadBox(character, (player.Team == Players.LocalPlayer.Team) and Settings.BoxColorTeammates or Settings.BoxColor)
        nameTags[player] = CreateNameTag()
        distanceTags[player] = CreateDistanceTag()
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
    end)
end

for _, player in pairs(game.Players:GetPlayers()) do
    ConnectEsp(player)
end
game.Players.PlayerAdded:Connect(function(player)
    ConnectEsp(player)
end)

local text = Drawing.new("Text")
text.Visible = true
text.Text = "Kitty ESP V0.1"
text.Outline = true
text.Position = Vector2.new(5, 5)

local function renderZombies()
    for _, zombie: Model in ipairs(workspace:WaitForChild("Zombies"):GetChildren()) do
        local atttribute = zombie:GetAttribute("ID")
        if atttribute then
            UpdateESP(zombies[atttribute], zombieNameTags[atttribute], zombieDistanceTags[atttribute], zombie, "Zombie")
        else
            atttribute = HttpService:GenerateGUID(false)
            zombie:SetAttribute("ID", atttribute)
            zombies[atttribute] = CreateQuadBox(zombie, Settings.BoxZombieColor)
            zombieNameTags[atttribute] = CreateNameTag()
            zombieDistanceTags[atttribute] = CreateDistanceTag()
            zombie.Destroying:Connect(function()
                if zombies[atttribute] then
                    zombies[atttribute]:Remove()
                    zombies[atttribute] = nil
                end
                if zombieNameTags[atttribute] then
                    zombieNameTags[atttribute]:Remove()
                    zombieNameTags[atttribute] = nil
                end
                if zombieDistanceTags[atttribute] then
                    zombieDistanceTags[atttribute]:Remove()
                    zombieDistanceTags[atttribute] = nil
                end
            end)
        end
    end
end

game:GetService("RunService").RenderStepped:Connect(function()
    -- Update zombies
    renderZombies()

    -- Update players
    for player, box in pairs(boxes) do
        UpdateESP(box, nameTags[player], distanceTags[player], player.Character, player.Name)
    end
    
    -- Update watermark color
    text.Color = Color3.fromHSV(math.sin(tick()) * 0.5 + 0.5, 0.8, 1)
end)