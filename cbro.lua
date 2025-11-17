local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local Workspace: Workspace = game:GetService("Workspace")
local Players: Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local PlayersCache = {} -- any cache item must have a Remove method.
local PlayersInitCache = {} -- store lambdas to init each esp element or other needed shit in the cache

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

local function initESP(player: Player)
    local cacheEntry = PlayersCache[player.UserId]
    if not cacheEntry then return end
    
    local boxQuad = Drawing.new("Quad")
    local nameText = Drawing.new("Text")

    table.insert(cacheEntry.cache, boxQuad)
    table.insert(cacheEntry.cache, nameText)

    boxQuad.Color = Color3.new(1, 1, 1)
    boxQuad.Thickness = 2

    nameText.Text = player.Name
    nameText.Color = Color3.new(1,1,1)
    nameText.Outline = false
    nameText.Font = Drawing.Fonts.Plex
    nameText.Size = 14
    
    local EspConnection = RunService.RenderStepped:Connect(function(deltaTime)
        local Character = player.Character

        if not Character then 
            boxQuad.Visible = false
            return 
        end

        local Humanoid = Character:FindFirstChild("Humanoid")
        local Head = Character:FindFirstChild("Head")
        local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")

        boxQuad.Visible = false
        nameText.Visible = false

        --if player.Team == LocalPlayer.Team then return end
        if player.Team == LocalPlayer.Team or not Head or not HumanoidRootPart or not Humanoid then return end
        if Humanoid.Health <= 0 then return end

        local HeadPos, HeadVisible = workspace.CurrentCamera:WorldToViewportPoint(Head.Position + Vector3.new(0, 1, 0))
        local FeetPos, FeetVisible = workspace.CurrentCamera:WorldToViewportPoint(HumanoidRootPart.Position + Vector3.new(0, -3.5, 0))

        if not HeadVisible or not FeetVisible then return end

        local height = math.abs(HeadPos.Y - FeetPos.Y)
        local width = height / 2

        boxQuad.PointA = Vector2.new(HeadPos.X - width / 2, HeadPos.Y)
        boxQuad.PointB = Vector2.new(HeadPos.X + width / 2, HeadPos.Y)
        boxQuad.PointC = Vector2.new(FeetPos.X + width / 2, FeetPos.Y)
        boxQuad.PointD = Vector2.new(FeetPos.X - width / 2, FeetPos.Y)

        nameText.Position = Vector2.new(HeadPos.X, HeadPos.Y) + Vector2.new(-nameText.TextBounds.X / 2, -(nameText.TextBounds.Y * 1.25))

        boxQuad.Visible = true
        nameText.Visible = true
    end)
    
    table.insert(cacheEntry.cache, {
        Remove = function()
            EspConnection:Disconnect()
            boxQuad:Remove()
        end
    })
end

table.insert(PlayersInitCache, initESP)

InitPlayersCache()

Players.PlayerAdded:Connect(function(player)
    if player == LocalPlayer then return end
    InitPlayerCache(player)
end)

Players.PlayerRemoving:Connect(function(player)
    ClearPlayerCache(player)
end)