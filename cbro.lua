-- SERVICES
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace: Workspace = game:GetService("Workspace")
local Players: Players = game:GetService("Players")

-- VARS
local LocalPlayer = Players.LocalPlayer

local PlayersCache = {} -- any cache item must have a Remove method.
local PlayersInitCache = {} -- store lambdas to init each esp element or other needed shit in the 

-- SETTINGS
local FONT = Drawing.Fonts.UI

-- PLAYER CACHE
local function ClearPlayerCache(player: Player)
    local userId = player.UserId
    if PlayersCache[userId] then
        for _, cacheItem in ipairs(PlayersCache[userId].cache) do
            if type(cacheItem) == "table" and cacheItem.Remove then
                cacheItem:Remove()
            elseif cacheItem.Remove then
                cacheItem:Remove()
            end
        end
        PlayersCache[userId] = nil
    end
end

local function InitPlayerCache(player: Player)
    if player == LocalPlayer then return end -- Skip local player
    
    if PlayersCache[player.UserId] then
        ClearPlayerCache(player)
    end

    PlayersCache[player.UserId] = {player = player, cache = {}}
    for _, init in ipairs(PlayersInitCache) do
        init(player)
    end
end

local function InitPlayersCache()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        InitPlayerCache(player)
        
        player.CharacterAdded:Connect(function(character)
            task.wait(0.5) -- Small delay to ensure character is fully loaded
            InitPlayerCache(player)
        end)
        
        player.CharacterRemoving:Connect(function(character)
            ClearPlayerCache(player)
        end)
    end
end


-- ESP
local function initESP(player: Player)
    local cacheEntry = PlayersCache[player.UserId]
    if not cacheEntry then return end
    
    local boxQuad = Drawing.new("Quad")

    local healthLine = Drawing.new("Line")

    local nameText = Drawing.new("Text")
    local gunText = Drawing.new("Text")

    local headCircle = Drawing.new("Circle")

    local outline = Instance.new("Highlight")


    table.insert(cacheEntry.cache, boxQuad)
    table.insert(cacheEntry.cache, healthLine)

    table.insert(cacheEntry.cache, nameText)
    table.insert(cacheEntry.cache, gunText)
    
    table.insert(cacheEntry.cache, headCircle)

    boxQuad.Color = Color3.new(0.580392, 0.760784, 1)
    boxQuad.Thickness = 1

    healthLine.Color = Color3.new(0.764705, 1, 0.219607)
    healthLine.Thickness = 3

    nameText.Text = player.Name
    nameText.Color = Color3.new(1,1,1)
    nameText.OutlineColor = Color3.new(0.2, 0.2, 0.2)
    nameText.Font = FONT
    nameText.Size = 14
    
    gunText.Text = player.Name
    gunText.Color = Color3.new(1,1,1)
    gunText.OutlineColor = Color3.new(0.2, 0.2, 0.2)
    gunText.Font = FONT
    gunText.Size = 14

    headCircle.Radius = 4
    headCircle.Color = Color3.new(1, 0.392156, 0.525490)

    outline.FillTransparency = 1
    outline.OutlineColor = Color3.new(1, 0.419607, 0.498039)
    
    local EspConnection = RunService.RenderStepped:Connect(function(deltaTime)
        local Character = player.Character

        if not Character then 
            boxQuad.Visible = false
            return 
        end

        local Humanoid: Humanoid = Character:FindFirstChild("Humanoid")
        local Head = Character:FindFirstChild("Head")
        local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")

        boxQuad.Visible = false
        healthLine.Visible = false
        nameText.Visible = false
        gunText.Visible = false
        headCircle.Visible = false

        if player.Team == LocalPlayer.Team or not Head or not HumanoidRootPart or not Humanoid then return end
        if Humanoid.Health <= 0 then return end

        local HeadBoundsPos, HeadVisible = workspace.CurrentCamera:WorldToViewportPoint(Head.Position + Vector3.new(0, 1, 0))
        local HeadPos, _ = workspace.CurrentCamera:WorldToViewportPoint(Head.Position)
        local FeetPos, FeetVisible = workspace.CurrentCamera:WorldToViewportPoint(HumanoidRootPart.Position + Vector3.new(0, -3.5, 0))

        if not HeadVisible or not FeetVisible then return end

        local height = math.abs(HeadBoundsPos.Y - FeetPos.Y)
        local width = height / 1.5 

        boxQuad.PointA = Vector2.new(HeadBoundsPos.X - width / 2, HeadBoundsPos.Y)
        boxQuad.PointB = Vector2.new(HeadBoundsPos.X + width / 2, HeadBoundsPos.Y)
        boxQuad.PointC = Vector2.new(FeetPos.X + width / 2, FeetPos.Y)
        boxQuad.PointD = Vector2.new(FeetPos.X - width / 2, FeetPos.Y)

        healthLine.From = Vector2.new((FeetPos.X - width / 2) - (healthLine.Thickness + 2), FeetPos.Y)
        healthLine.To = Vector2.new((HeadPos.X - width / 2) - (healthLine.Thickness + 2), FeetPos.Y - (height * (Humanoid.Health / Humanoid.MaxHealth)))

        nameText.Position = Vector2.new(HeadBoundsPos.X, HeadBoundsPos.Y) + Vector2.new(-(nameText.TextBounds.X / 2), -(nameText.TextBounds.Y * 1.25))

        gunText.Text = Character.EquippedTool.Value
        gunText.Position = Vector2.new(FeetPos.X, FeetPos.Y) + Vector2.new(-(gunText.TextBounds.X / 2), 0)

        headCircle.Position = Vector2.new(HeadPos.X, HeadPos.Y)
        headCircle.Radius = (HeadPos.Y - HeadBoundsPos.Y) / 2.15

        boxQuad.Visible = true
        healthLine.Visible = true
        nameText.Visible = true
        gunText.Visible = true
        headCircle.Visible = true

        outline.Parent = Character
    end)
    
    table.insert(cacheEntry.cache, {
        Remove = function()
            EspConnection:Disconnect()
            boxQuad:Remove()
        end
    })
end
table.insert(PlayersInitCache, initESP)

-- TRIGGERBOT
local triggerbot_running = false
local function runTriggerbot()
    if not triggerbot_running then return end

    local Character = LocalPlayer.Character
    if not Character then return end

    local Humanoid = Character.Humanoid
    if Humanoid.Health <= 0 then return end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { Character }
    local raycastResult = Workspace:Raycast(Workspace.CurrentCamera.CFrame.Position, Workspace.CurrentCamera.CFrame.LookVector.Unit * 1000, params)

    if not raycastResult then return end

    local character = raycastResult.Instance:FindFirstAncestorOfClass("Model")

    if not character or not character:FindFirstChild("Humanoid") then return end

    if Players:GetPlayerFromCharacter(character).Team == LocalPlayer.Team then return end

    mouse1press() task.wait(1 / 24) mouse1release()
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end

    if input.KeyCode == Enum.KeyCode.LeftAlt then
        triggerbot_running = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end

    if input.KeyCode == Enum.KeyCode.LeftAlt then
        triggerbot_running = false
    end
end)

-- SETUP CHEAT
InitPlayersCache()

Players.PlayerAdded:Connect(function(player)
    if player == LocalPlayer then return end
    InitPlayerCache(player)
end)

Players.PlayerRemoving:Connect(function(player)
    ClearPlayerCache(player)
end)

RunService.RenderStepped:Connect(function(deltaTime)
    runTriggerbot()
end)