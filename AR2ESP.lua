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


local function CreateQuadBox(character, color)
    local quad = Drawing.new("Quad")
    quad.Visible = false
    quad.Color = color
    quad.Thickness = 2
    quad.Filled = false
    
    return quad
end

local function UpdateQuadBox(quad, character)
    local head = character:FindFirstChild("Head")
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid: Humanoid = character:FindFirstChild("Humanoid")
    
    if not head or not humanoidRootPart or humanoid and humanoid.Health <= 0 or (workspace.CurrentCamera.CFrame.Position - humanoidRootPart.Position).Magnitude > Settings.MaxDistance then
        quad.Visible = false
        return
    end
    
    local headPos, headVisible = workspace.CurrentCamera:WorldToViewportPoint(head.Position + Vector3.new(0, 1, 0))
    local feetPos, feetVisible = workspace.CurrentCamera:WorldToViewportPoint(humanoidRootPart.Position - Vector3.new(0, 4, 0))
    
    if not headVisible or not feetVisible or headPos.Z < 0 or feetPos.Z < 0 then
        quad.Visible = false
        return
    end
    
    local height = math.abs(headPos.Y - feetPos.Y)
    local width = height / 2
    
    quad.PointA = Vector2.new(headPos.X - width/2, headPos.Y)
    quad.PointB = Vector2.new(headPos.X + width/2, headPos.Y)
    quad.PointC = Vector2.new(feetPos.X + width/2, feetPos.Y)
    quad.PointD = Vector2.new(feetPos.X - width/2, feetPos.Y)
    
    quad.Visible = true
end

local boxes = {}
local zombies = {}

local function ConnectEsp(player: Player)
    if player == Players.LocalPlayer then return end

    if player.Character then
        boxes[player] = CreateQuadBox(player.Character, (player.Team == Players.LocalPlayer.Team) and Settings.BoxColorTeammates or Settings.BoxColor)
    end

    player.CharacterAdded:Connect(function(character)
        boxes[player] = CreateQuadBox(character, (player.Team == Players.LocalPlayer.Team) and Settings.BoxColorTeammates or Settings.BoxColor)
    end)

    player.CharacterRemoving:Connect(function()
        if boxes[player] then
            boxes[player]:Remove()
            boxes[player] = nil
        end
    end)

    game.Players.PlayerRemoving:Connect(function(player)
        if boxes[player] then
            boxes[player]:Remove()
            boxes[player] = nil
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
text.Position = Vector2.new(10, 10)

game:GetService("RunService").RenderStepped:Connect(function()
    for _, zombie: Model in ipairs(workspace:WaitForChild("Zombies"):GetChildren()) do
        local atttribute = zombie:GetAttribute("ID")
        if atttribute then
            UpdateQuadBox(zombies[atttribute], zombie)
        else
            atttribute = HttpService:GenerateGUID(false)
            zombie:SetAttribute("ID", atttribute)
            zombies[atttribute] = CreateQuadBox(zombie, Settings.BoxZombieColor)
            zombie.Destroying:Connect(function()
                zombies[atttribute]:Remove()
                zombies[atttribute] = nil
            end)
        end
    end

    for player, box in pairs(boxes) do
        UpdateQuadBox(box, player.Character)
    end
    text.Color = Color3.fromHSV(math.sin(127.5), 0.5, 1)
end)
