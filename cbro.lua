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
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local FONT = Drawing.Fonts.UI
local version = '0.1'

-- SETUP MENU
_G.KittyWare = {}
_G.KittyWare.ESP_ELEMENTS = {}
local Window = Rayfield:CreateWindow({
    Name = "KittyWare",
    LoadingTitle = 'Meoooow',
    LoadingSubtitle = 'By Noxy_Kun',
    ConfigurationSaving = {
        Enabled = true,
        FolderName = 'KittyWare',
        FileName = 'Counterblox'
    },
    Discord = {
        Enabled = false,
        Invite = 'noinvitelink',
        RememberJoins = true,
    },
    KeySystem = false,
    KeySettings = {
        Title = 'Key System',
        Subtitle = 'Discord System',
        Note = 'discord.gg/vZQTkyCXD8',
        FileName = 'Key',
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = { 'idfk' },
    },
})

local EspTab = Window:CreateTab('ESP', nil)

EspTab:CreateToggle({
    Name = "Enabled",
   CurrentValue = true,
   Flag = "ESP_TOGGLE",
   Callback = function(value)
    _G.KittyWare.ESP_ENABLED = value
   end,
})

EspTab:CreateDropdown({
   Name = "ESP Elements",
   Options = {"Box", "Head Circle", "Name", "Gun", "Health Bar", "Outline"},
   CurrentOption = {"Name", "Head Circle", "Gun", "Health Bar", "Outline"},
   MultipleOptions = true,
   Flag = "ESP_ELEMENTS",
   Callback = function(Options)
        _G.KittyWare.ESP_ELEMENTS = {}
        for index, name in pairs(Options) do
            _G.KittyWare.ESP_ELEMENTS[name] = true
        end
   end,
})

Rayfield:LoadConfiguration()

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

        boxQuad.Visible = false
        healthLine.Visible = false
        nameText.Visible = false
        gunText.Visible = false
        headCircle.Visible = false

        if not Character or not _G.KittyWare.ESP_ENABLED then return end

        local Humanoid: Humanoid = Character:FindFirstChild("Humanoid")
        local Head = Character:FindFirstChild("Head")
        local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")

        if player.Team == LocalPlayer.Team or not Head or not HumanoidRootPart or not Humanoid then return end
        if Humanoid.Health <= 0 then return end

        local HeadBoundsPos, HeadVisible = workspace.CurrentCamera:WorldToViewportPoint(Head.Position + Vector3.new(0, 1, 0))
        local HeadPos, _ = workspace.CurrentCamera:WorldToViewportPoint(Head.Position)
        local FeetPos, FeetVisible = workspace.CurrentCamera:WorldToViewportPoint(HumanoidRootPart.Position + Vector3.new(0, -3.5, 0))

        if not HeadVisible or not FeetVisible then return end

        local height = math.abs(HeadBoundsPos.Y - FeetPos.Y)
        local width = height / 1.5 

        if _G.KittyWare.ESP_ELEMENTS["Box"] then            
            boxQuad.PointA = Vector2.new(HeadBoundsPos.X - width / 2, HeadBoundsPos.Y)
            boxQuad.PointB = Vector2.new(HeadBoundsPos.X + width / 2, HeadBoundsPos.Y)
            boxQuad.PointC = Vector2.new(FeetPos.X + width / 2, FeetPos.Y)
            boxQuad.PointD = Vector2.new(FeetPos.X - width / 2, FeetPos.Y)
            boxQuad.Visible = true
        end

        if _G.KittyWare.ESP_ELEMENTS["Head Circle"] then        
            headCircle.Position = Vector2.new(HeadPos.X, HeadPos.Y)
            headCircle.Radius = (HeadPos.Y - HeadBoundsPos.Y) / 2.15
            headCircle.Visible = true
        end

        print(_G.KittyWare.ESP_ELEMENTS["Name"])
        if _G.KittyWare.ESP_ELEMENTS["Name"] then
            nameText.Position = Vector2.new(HeadBoundsPos.X, HeadBoundsPos.Y) + Vector2.new(-(nameText.TextBounds.X / 2), -(nameText.TextBounds.Y * 1.25))
            nameText.Visible = true
        end

        if _G.KittyWare.ESP_ELEMENTS["Gun"] then
            gunText.Text = Character.EquippedTool.Value
            gunText.Position = Vector2.new(FeetPos.X, FeetPos.Y) + Vector2.new(-(gunText.TextBounds.X / 2), 0)
            gunText.Visible = true
        end

        if _G.KittyWare.ESP_ELEMENTS["Health Bar"] then
            healthLine.From = Vector2.new((FeetPos.X - width / 2) - (healthLine.Thickness + 2), FeetPos.Y)
            healthLine.To = Vector2.new((HeadPos.X - width / 2) - (healthLine.Thickness + 2), FeetPos.Y - (height * (Humanoid.Health / Humanoid.MaxHealth)))
            healthLine.Visible = true
        end

        if _G.KittyWare.ESP_ELEMENTS["Outline"] then
            outline.Parent = Character
        else
            outline.Parent = nil
        end
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

-- BHOP
local bhop_running
local function runBHOP()
    if LocalPlayer.Character ~= nil and UserInputService:IsKeyDown(Enum.KeyCode.Space) and LocalPlayer.PlayerGui.GUI.Main.GlobalChat.Visible == false then
        LocalPlayer.Character.Humanoid.Jump = true
        local bhopSpeed = 1000
        local moveDirection = camera.CFrame.LookVector * Vector3.new(1, 0, 1)
        local movement = Vector3.new()
        
        movement = (UserInputService:IsKeyDown(Enum.KeyCode.W) and (movement + moveDirection)) or movement
        movement = (UserInputService:IsKeyDown(Enum.KeyCode.S) and (movement - moveDirection)) or movement
        movement = (UserInputService:IsKeyDown(Enum.KeyCode.D) and (movement + Vector3.new(-moveDirection.Z, 0, moveDirection.X))) or movement
        movement = (UserInputService:IsKeyDown(Enum.KeyCode.A) and (movement + Vector3.new(moveDirection.Z, 0, -moveDirection.X))) or movement
        
        if movement.Unit.X == movement.Unit.X then
            movement = movement.Unit
            LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(movement.X * bhopSpeed, LocalPlayer.Character.HumanoidRootPart.Velocity.Y, movement.Z * bhopSpeed)
        end
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end

    if input.KeyCode == Enum.KeyCode.Space then
        bhop_running = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end

    if input.KeyCode == Enum.KeyCode.Space then
        bhop_running = false
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
    runBHOP()
end)