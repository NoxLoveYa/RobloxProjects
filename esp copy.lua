local Settings = {
    BoxColor = Color3.new(0.515, 1, 0),
    BoxSize = 2,
    MaxDistance = 500
}

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
    
    if not head or not humanoidRootPart then
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

for _, player in pairs(game.Players:GetPlayers()) do
    if player.Character then
        boxes[player] = CreateQuadBox(player.Character, Settings.BoxColor)
    end
    player.CharacterAdded:Connect(function(character)
        boxes[player] = CreateQuadBox(character, Settings.BoxColor)
    end)
    player.CharacterRemoving:Connect(function()
        if boxes[player] then
            boxes[player]:Remove()
            boxes[player] = nil
        end
    end)
end

game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        boxes[player] = CreateQuadBox(character, Settings.BoxColor)
    end)
end)

game.Players.PlayerRemoving:Connect(function(player)
    if boxes[player] then
        boxes[player]:Remove()
        boxes[player] = nil
    end
end)

game:GetService("RunService").RenderStepped:Connect(function()
    for player, box in pairs(boxes) do
        UpdateQuadBox(box, player.Character)
    end
end)