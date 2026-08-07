local RunService = game:GetService("RunService")

local esp = {}
local connections = {}

local function removeEspElements(player: Player)
	local espElement = esp[player.UserId]
	if not espElement then
		return
	end
	if espElement.glow then
		espElement.glow:Destroy()
	end
	if espElement.box2dElement then
		espElement.box2dElement:Destroy()
	end
	if espElement.nameElement then
		espElement.nameElement:Destroy()
	end
	esp[player.UserId] = nil
end

local function removeAllEspElements()
	for _, espElement in pairs(esp) do
		removeEspElements(espElement.player)
	end
	esp = {}
end

local function resetAll()
	for _, connection in pairs(connections) do
		connection:Disconnect()
	end
	connections = {}
	removeAllEspElements()
end

local function getBoundingBox(character: Model)
	local head: Part = character:FindFirstChild("Head")
	local humanoidRootPart: Part = character:FindFirstChild("HumanoidRootPart")

	if not head or not humanoidRootPart then
		return nil
	end

	local headScreenPosition, headOnScreen = workspace.CurrentCamera:WorldToViewportPoint(head.Position)
	local rootScreenPosition, rootOnScreen = workspace.CurrentCamera:WorldToViewportPoint(humanoidRootPart.Position)

	if not headOnScreen and not rootOnScreen then
		return nil
	end

	local boxSize = math.abs(headScreenPosition.Y - rootScreenPosition.Y)

	local topLeft = Vector2.new(
		math.min(headScreenPosition.X - boxSize * 1.75, rootScreenPosition.X),
		math.min(headScreenPosition.Y - boxSize, rootScreenPosition.Y)
	)
	local topRight = Vector2.new(
		math.max(headScreenPosition.X + boxSize * 1.75, rootScreenPosition.X),
		math.min(headScreenPosition.Y - boxSize, rootScreenPosition.Y)
	)
	local bottomRight = Vector2.new(
		math.max(headScreenPosition.X + boxSize * 1.75, rootScreenPosition.X),
		math.max(headScreenPosition.Y + boxSize * 3.35, rootScreenPosition.Y)
	)
	local bottomLeft = Vector2.new(
		math.min(headScreenPosition.X - boxSize * 1.75, rootScreenPosition.X),
		math.max(headScreenPosition.Y + boxSize * 3.35, rootScreenPosition.Y)
	)

	local box2d = {
		topLeft = topLeft,
		topRight = topRight,
		bottomRight = bottomRight,
		bottomLeft = bottomLeft,
	}

	return box2d
end

local function createGlowElement(player: Player, character: Model)
	local highlight: Highlight = character:FindFirstChildOfClass("Highlight") or Instance.new("Highlight")
	highlight.Adornee = character
	highlight.FillColor = Color3.fromRGB(255, 0, 0)
	highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = character
	return highlight
end

local function createBox2dElement(player: Player, character: Model)
	local box2d = getBoundingBox(character)
	if not box2d then
		return nil
	end

	local box2dElement = Drawing.new("Square")
	box2dElement.Visible = true
	box2dElement.Color = Color3.fromRGB(255, 0, 0)
	box2dElement.Thickness = 2
	box2dElement.Filled = false
	return box2dElement
end

local function createNameElement(player: Player, character: Model)
	local nameElement = Drawing.new("Text")
	nameElement.Visible = true
	nameElement.Color = Color3.fromRGB(255, 255, 255)
	nameElement.Size = 16
	nameElement.Center = true
	nameElement.Outline = true
	nameElement.Text = player.Name
	return nameElement
end

local function createEspElements(player: Player, character: Model)
	if esp[player.UserId] then
		removeEspElements(player)
	end
	local glow: Highlight = createGlowElement(player, character)
	local box2dElement = createBox2dElement(player, character)
	local nameElement = createNameElement(player, character)
	esp[player.UserId] = { player = player, character = character, glow = glow, box2dElement = box2dElement, nameElement = nameElement }
end

local function updateEspElements()
	for _, espElement in pairs(esp) do
		if espElement.character and espElement.character.Parent then
			local box2d = getBoundingBox(espElement.character)
			if box2d and espElement.box2dElement then
				espElement.box2dElement.Position = box2d.topLeft
				espElement.box2dElement.Size =
					Vector2.new(box2d.topRight.X - box2d.topLeft.X, box2d.bottomLeft.Y - box2d.topLeft.Y)
				espElement.box2dElement.Visible = true
				if espElement.nameElement then
				espElement.nameElement.Position = Vector2.new(
					box2d.topLeft.X + (box2d.topRight.X - box2d.topLeft.X) / 2,
					box2d.topLeft.Y - 10
				)
				espElement.nameElement.Visible = true
			end
		elseif box2d then
			espElement.box2dElement = createBox2dElement(espElement.player, espElement.character)
			if espElement.box2dElement then
				espElement.box2dElement.Position = box2d.topLeft
				espElement.box2dElement.Size =
					Vector2.new(box2d.topRight.X - box2d.topLeft.X, box2d.bottomLeft.Y - box2d.topLeft.Y)
				espElement.box2dElement.Visible = true
			end
			if not espElement.nameElement then
				espElement.nameElement = createNameElement(espElement.player, espElement.character)
			end
			if espElement.nameElement then
				espElement.nameElement.Position = Vector2.new(
					box2d.topLeft.X + (box2d.topRight.X - box2d.topLeft.X) / 2,
					box2d.topLeft.Y - 10
				)
					espElement.nameElement.Visible = true
				end
			else
				if espElement.box2dElement then
					espElement.box2dElement.Visible = false
				end
				if espElement.nameElement then
					espElement.nameElement.Visible = false
				end
			end
		else
			removeEspElements(espElement.player)
		end
	end
end

local function connectAll()
	resetAll()

	local function setupPlayer(player)
		if player.Character then
			createEspElements(player, player.Character)
		end
		local connection = player.CharacterAdded:Connect(function(character)
			createEspElements(player, character)
		end)
		local connection2 = player.CharacterRemoving:Connect(function(character)
			removeEspElements(player)
		end)
		table.insert(connections, connection)
		table.insert(connections, connection2)
	end

	for _, player in pairs(game.Players:GetPlayers()) do
		setupPlayer(player)
	end

	local playerAddedConnection = game.Players.PlayerAdded:Connect(function(player)
		setupPlayer(player)
	end)
	table.insert(connections, playerAddedConnection)

	local playerRemovingConnection = game.Players.PlayerRemoving:Connect(function(player)
		removeEspElements(player)
	end)
	table.insert(connections, playerRemovingConnection)

	local renderConnection = RunService.RenderStepped:Connect(function()
		updateEspElements()
	end)
	table.insert(connections, renderConnection)
end

connectAll()

return esp
