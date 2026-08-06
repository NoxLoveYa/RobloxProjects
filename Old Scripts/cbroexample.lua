loadstring(game:HttpGet('https://[Log in to view URL]', true))()

--  SCRIPT HERE

local clientId = game:GetService('RbxAnalyticsService'):GetClientId()
local runService = game:GetService('RunService')
local userInputService = game:GetService('UserInputService')
local players = game:GetService('Players')
local lighting = game:GetService('Lighting')
local replicatedStorage = game:GetService('ReplicatedStorage')
local camera = workspace.CurrentCamera
local weapons = replicatedStorage.Weapons
local debris = workspace.Debris
local rayIgnore = workspace.Ray_Ignore
local localPlayer = players.LocalPlayer
local worldToViewportPoint = camera.WorldToViewportPoint

local fovCircle = Drawing.new('Circle')
fovCircle.Visible = false
fovCircle.Thickness = 1.5
fovCircle.Radius = 150
fovCircle.Transparency = 1
fovCircle.Color = Color3.fromRGB(200, 200, 200)

local aimbot = {
    Enabled = false,
    TeamCheck = false,
    Smoothing = 1,
    EnableFOV = false,
}

local chams = {
    Enabled = false,
    UseTeamColor = false,
    ChamsColor = Color3.fromRGB(200, 200, 200),
}

local sounds = {
    KillSoundEnabled = false,
    HitSoundEnabled = false,
    KillSound = nil,
    HitSound = nil,
}

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Rellah's CB",
    LoadingTitle = 'Loading CB',
    LoadingSubtitle = 'By Rellah',
    ConfigurationSaving = {
        Enabled = true,
        FolderName = 'CounterBlox',
        FileName = 'CounterBlox',
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
        Key = { 'rellahiscool' },
    },
})

local HomeTab = Window:CreateTab('Home', nil)
local CombatTab = Window:CreateTab('Combat', nil)
local MiscTab = Window:CreateTab('Misc', nil)
local VisualsTab = Window:CreateTab('Visuals', nil)

local version = '1.0'

function GetClosestPlayer(origin)
    local closestPlayer = nil
    local shortestDistance = math.huge
    local ray = Ray.new(origin.Position, origin.LookVector).Unit

    for _, player in pairs(players:GetPlayers()) do
        if
            player.Character
            and player.Character:FindFirstChild('Humanoid')
            and player.Character:FindFirstChild('HumanoidRootPart')
            and player ~= localPlayer
            and (player.Team ~= localPlayer.Team or not aimbot.TeamCheck)
        then
            local headPosition = player.Character.Head.Position
            local distance = (headPosition - ray:ClosestPoint(headPosition)).Magnitude

            if distance < shortestDistance then
                shortestDistance = distance
                closestPlayer = player
            end
        end
    end

    return closestPlayer
end

HomeTab:CreateLabel('Premium Version')
HomeTab:CreateLabel('Version: ' .. version)

CombatTab:CreateSection('Aimbot')
CombatTab:CreateToggle({
    Name = 'Aimbot',
    CurrentValue = false,
    Flag = 'Aimbot',
    Callback = function(value)
        aimbot.Enabled = value
    end,
})

CombatTab:CreateSection('Settings')
CombatTab:CreateSlider({
    Name = 'FOV Radius',
    Range = { 0, 2000 },
    Increment = 1,
    CurrentValue = 150,
    Flag = 'FOVRadius',
    Callback = function(value)
        fovCircle.Radius = value
    end,
})

CombatTab:CreateColorPicker({
    Name = 'FOV Color',
    Color = Color3.fromRGB(200, 200, 200),
    Flag = 'FOVColor',
    Callback = function(color)
        fovCircle.Color = color or Color3.fromRGB(200, 200, 200)
    end,
})

CombatTab:CreateToggle({
    Name = 'Use FOV',
    CurrentValue = false,
    Flag = 'UseFOV',
    Callback = function(value)
        aimbot.EnableFOV = value
    end,
})

CombatTab:CreateToggle({
    Name = 'Team Check',
    CurrentValue = false,
    Flag = 'TeamCheck',
    Callback = function(value)
        aimbot.TeamCheck = value
    end,
})

CombatTab:CreateSection('Character')
CombatTab:CreateToggle({
    Name = 'Spinbot',
    CurrentValue = false,
    Flag = 'Spinbot',
    Callback = function(value)
        _G.SpinBot = value
    end,
})

CombatTab:CreateSection('Settings')
CombatTab:CreateSlider({
    Name = 'Speed',
    Range = { 0, 500 },
    Increment = 1,
    CurrentValue = 150,
    Flag = 'FOVRadius',
    Callback = function(value)
        _G.Speed = value
    end,
})

MiscTab:CreateSection('Guns')
MiscTab:CreateButton({
    Name = 'No Fire Rate',
    Callback = function()
        for _, weapon in ipairs(weapons:GetChildren()) do
            if weapon:FindFirstChild('FireRate') then
                weapon:FindFirstChild('FireRate').Value = 0
            end
        end
    end,
})

MiscTab:CreateButton({
    Name = 'No Spread',
    Callback = function()
        for _, weapon in ipairs(weapons:GetChildren()) do
            if weapon:FindFirstChild('Spread') then
                weapon:FindFirstChild('Spread').Value = 0
                for _, spread in
                    ipairs(weapon:FindFirstChild('Spread'):GetChildren())
                do
                    spread.Value = 0
                end
            end
        end
    end,
})

MiscTab:CreateButton({
    Name = 'Instant Reload Time',
    Callback = function()
        for _, weapon in ipairs(weapons:GetChildren()) do
            if weapon:FindFirstChild('ReloadTime') then
                weapon:FindFirstChild('ReloadTime').Value = 0.05
            end
        end
    end,
})

MiscTab:CreateButton({
    Name = 'Instant Equip Time',
    Callback = function()
        for _, weapon in ipairs(weapons:GetChildren()) do
            if weapon:FindFirstChild('EquipTime') then
                weapon:FindFirstChild('EquipTime').Value = 0.05
            end
        end
    end,
})

MiscTab:CreateButton({
    Name = 'Inf Ammo',
    Callback = function()
        for _, weapon in ipairs(weapons:GetChildren()) do
            if
                weapon:FindFirstChild('Ammo')
                and weapon:FindFirstChild('StoredAmmo')
            then
                weapon:FindFirstChild('Ammo').Value = 6969
                weapon:FindFirstChild('StoredAmmo').Value = 6969
            end
        end
    end,
})

MiscTab:CreateSection('Sounds')
MiscTab:CreateToggle({
    Name = 'Hit Sound',
    CurrentValue = false,
    Flag = 'HitSound',
    Callback = function(value)
        sounds.HitSoundEnabled = value
    end,
})

MiscTab:CreateToggle({
    Name = 'Kill Sound',
    CurrentValue = false,
    Flag = 'KillSound',
    Callback = function(value)
        sounds.KillSoundEnabled = value
    end,
})

MiscTab:CreateDropdown({
    Name = 'Hit Sounds',
    Options = {
        'Bameware',
        'Bell',
        'Bubble',
        'Pick',
        'Pop',
        'Rust',
        'Skeet',
        'Neverlose',
        'Minecraft',
    },
    CurrentOption = { 'Bubble' },
    MultipleOptions = false,
    Flag = 'HitSounds',
    Callback = function(option)
        if option == 'Bameware' then
            sounds.HitSound = 3124331820
        elseif option == 'Bell' then
            sounds.HitSound = 6534947240
        elseif option == 'Bubble' then
            sounds.HitSound = 6534947588
        elseif option == 'Pick' then
            sounds.HitSound = 1347140027
        elseif option == 'Pop' then
            sounds.HitSound = 198598793
        elseif option == 'Rust' then
            sounds.HitSound = 1255040462
        elseif option == 'Skeet' then
            sounds.HitSound = 5633695679
        elseif option == 'Neverlose' then
            sounds.HitSound = 6534948092
        elseif option == 'Minecraft' then
            sounds.HitSound = 4018616850
        end
        print(option)
        print(sounds.HitSound)
    end,
})

MiscTab:CreateDropdown({
    Name = 'Kill Sounds',
    Options = {
        'Bameware',
        'Bell',
        'Bubble',
        'Pick',
        'Pop',
        'Rust',
        'Skeet',
        'Neverlose',
        'Minecraft',
    },
    CurrentOption = { 'Bubble' },
    MultipleOptions = false,
    Flag = 'KillSounds',
    Callback = function(option)
        if option == 'Bameware' then
            sounds.KillSound = 3124331820
        elseif option == 'Bell' then
            sounds.KillSound = 6534947240
        elseif option == 'Bubble' then
            sounds.KillSound = 6534947588
        elseif option == 'Pick' then
            sounds.KillSound = 1347140027
        elseif option == 'Pop' then
            sounds.KillSound = 198598793
        elseif option == 'Rust' then
            sounds.KillSound = 1255040462
        elseif option == 'Skeet' then
            sounds.KillSound = 5633695679
        elseif option == 'Neverlose' then
            sounds.KillSound = 6534948092
        elseif option == 'Minecraft' then
            sounds.KillSound = 4018616850
        end
        print(option)
        print(sounds.KillSound)
    end,
})

MiscTab:CreateSection('Effects')
MiscTab:CreateToggle({
    Name = 'Remove Scope',
    CurrentValue = false,
    Flag = 'RemoveScope',
    Callback = function(value)
        _G.RemoveScope = value
    end,
})

MiscTab:CreateToggle({
    Name = 'Remove Flash',
    CurrentValue = false,
    Flag = 'RemoveFlash',
    Callback = function(value)
        _G.RemoveFlash = value
    end,
})

MiscTab:CreateToggle({
    Name = 'Remove Smoke',
    CurrentValue = false,
    Flag = 'RemoveSmoke',
    Callback = function(value)
        _G.RemoveSmoke = value
    end,
})

MiscTab:CreateToggle({
    Name = 'Remove Blood',
    CurrentValue = false,
    Flag = 'RemoveBlood',
    Callback = function(value)
        _G.RemoveBlood = value
    end,
})

MiscTab:CreateToggle({
    Name = 'Remove Bullets Holes',
    CurrentValue = false,
    Flag = 'RemoveBulletsHoles',
    Callback = function(value)
        _G.RemoveBulletsHoles = value
    end,
})

MiscTab:CreateSection('Movement')
MiscTab:CreateToggle({
    Name = 'Auto Bhop',
    CurrentValue = false,
    Flag = 'Bhop',
    Callback = function(value)
        _G.Bhop = value
    end,
})

MiscTab:CreateSlider({
    Name = 'Bhop Speed',
    Range = { 0, 300 },
    Increment = 1,
    CurrentValue = 100,
    Flag = 'BhopSpeed',
    Callback = function(value)
        _G.BhopSpeed = value
    end,
})

MiscTab:CreateSection('Character')
MiscTab:CreateToggle({
    Name = 'Fly',
    CurrentValue = false,
    Flag = 'Fly',
    Callback = function(value)
        _G.Fly = value
    end,
})

MiscTab:CreateToggle({
    Name = 'Noclip',
    CurrentValue = false,
    Flag = 'Noclip',
    Callback = function(value)
        _G.Noclip = value
    end,
})

MiscTab:CreateSlider({
    Name = 'Fly Speed',
    Range = { 0, 120 },
    Increment = 1,
    CurrentValue = 16,
    Flag = 'FlySpeed',
    Callback = function(value)
        _G.FlySpeed = value
    end,
})

MiscTab:CreateSection('Stuff')
MiscTab:CreateButton({
    Name = 'Infinite Cash',
    Callback = function()
        runService.RenderStepped:Connect(function()
            if localPlayer and localPlayer.Parent then
                localPlayer.Cash.Value = 9550
            end
            task.wait()
        end)
    end,
})

local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local ESPObjects = {}
local isESPEnabled = false
local espUpdateConnection

local function CreateESP(player)
    local esp = Drawing.new('Square')
    local healthBar = Drawing.new('Square')
    local healthBarBorder = Drawing.new('Square')
    esp.Thickness, esp.Filled, esp.Transparency, esp.Color =
        1, false, 1, Color3.new(1, 0, 0)
    healthBar.Thickness, healthBar.Filled, healthBar.Transparency, healthBar.Color =
        1, true, 1, Color3.new(0, 1, 0)
    healthBarBorder.Thickness, healthBarBorder.Filled, healthBarBorder.Transparency, healthBarBorder.Color =
        1, false, 1, Color3.new(0, 0, 0)
    ESPObjects[player] =
        { esp = esp, healthBar = healthBar, healthBarBorder = healthBarBorder }
end

local function RemoveESP(player)
    if ESPObjects[player] then
        for _, obj in pairs(ESPObjects[player]) do
            obj:Remove()
        end
        ESPObjects[player] = nil
    end
end

local function UpdateESP()
    if not isESPEnabled then
        return
    end
    for player, objects in pairs(ESPObjects) do
        if
            player.Team ~= LocalPlayer.Team
            and player.Character
            and player.Character:FindFirstChild('HumanoidRootPart')
        then
            local rootPart = player.Character.HumanoidRootPart
            local humanoid = player.Character:FindFirstChildOfClass('Humanoid')
            local screenPos, onScreen =
                Camera:WorldToViewportPoint(rootPart.Position)
            if onScreen and humanoid then
                local boxSize =
                    Vector2.new(1000 / screenPos.Z, 2500 / screenPos.Z)
                local boxPosition = Vector2.new(
                    screenPos.X - boxSize.X / 2,
                    screenPos.Y - boxSize.Y / 2
                )
                objects.esp.Size, objects.esp.Position, objects.esp.Visible =
                    boxSize, boxPosition, true
                local healthBarWidth, healthBarHeight = 2, boxSize.Y
                local healthBarPosition = Vector2.new(
                    boxPosition.X - healthBarWidth - 5,
                    boxPosition.Y
                )
                objects.healthBarBorder.Size =
                    Vector2.new(healthBarWidth + 2, healthBarHeight + 2)
                objects.healthBarBorder.Position = Vector2.new(
                    healthBarPosition.X - 1,
                    healthBarPosition.Y - 1
                )
                objects.healthBarBorder.Visible = true
                local healthPercentage = humanoid.Health / humanoid.MaxHealth
                objects.healthBar.Size = Vector2.new(
                    healthBarWidth,
                    healthBarHeight * healthPercentage
                )
                objects.healthBar.Position = Vector2.new(
                    healthBarPosition.X,
                    healthBarPosition.Y
                        + healthBarHeight * (1 - healthPercentage)
                )
                objects.healthBar.Visible = true
            else
                for _, obj in pairs(objects) do
                    obj.Visible = false
                end
            end
        else
            for _, obj in pairs(objects) do
                obj.Visible = false
            end
        end
    end
end

local function InitializeESP()
    Players.PlayerAdded:Connect(CreateESP)
    Players.PlayerRemoving:Connect(RemoveESP)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            CreateESP(player)
        end
    end
    espUpdateConnection = RunService.Heartbeat:Connect(UpdateESP)
end

local function CleanupESP()
    for player in pairs(ESPObjects) do
        RemoveESP(player)
    end
    ESPObjects = {}
end

VisualsTab:CreateSection('ESP')
VisualsTab:CreateToggle({
    Name = 'ESP',
    CurrentValue = false,
    Flag = 'ESP',
    Callback = function(value)
        if value then
            if not isESPEnabled then
                isESPEnabled = true
                InitializeESP()
            end
        else
            if isESPEnabled then
                isESPEnabled = false
                CleanupESP()
                if espUpdateConnection then
                    espUpdateConnection:Disconnect()
                    espUpdateConnection = nil
                end
            end
        end
    end,
})

VisualsTab:CreateSection('Camera')
VisualsTab:CreateSlider({
    Name = 'Field Of View',
    Range = { 0, 120 },
    Increment = 1,
    CurrentValue = 80,
    Flag = 'BhopSpeed',
    Callback = function(value)
        _G.FieldOfView = value
    end,
})

VisualsTab:CreateSection('Arms')
VisualsTab:CreateToggle({
    Name = 'Arms Chams',
    CurrentValue = false,
    Flag = 'ArmsChams',
    Callback = function(value)
        _G.ArmsChams = value
    end,
})

VisualsTab:CreateSection('Guns')
VisualsTab:CreateToggle({
    Name = 'Guns Chams',
    CurrentValue = false,
    Flag = 'GunsChams',
    Callback = function(value)
        _G.GunsChams = value
    end,
})

VisualsTab:CreateColorPicker({
    Name = 'Guns Chams Color',
    Color = Color3.fromRGB(200, 200, 200),
    Flag = 'GunsChamsColor',
    Callback = function(color)
        _G.ChamsColor = color
    end,
})

localPlayer.Additionals.TotalDamage.Changed:Connect(function(value)
    if sounds.HitSoundEnabled == true and value ~= 0 then
        local sound = Instance.new('Sound')
        sound.Parent = game:GetService('SoundService')
        sound.SoundId = 'rbxassetid://' .. sounds.HitSound
        sound.Volume = 3
        sound:Play()
    end
end)

localPlayer.Status.Kills.Changed:Connect(function(value)
    if sounds.KillSoundEnabled == true and value ~= 0 then
        local sound = Instance.new('Sound')
        sound.Parent = game:GetService('SoundService')
        sound.SoundId = 'rbxassetid://' .. sounds.KillSound
        sound.Volume = 3
        sound:Play()
    end
end)

runService.RenderStepped:Connect(function()
    if _G.RemoveScope == true then
        localPlayer.PlayerGui.GUI.Crosshairs.Scope.ImageTransparency = 1
        localPlayer.PlayerGui.GUI.Crosshairs.Scope.Scope.ImageTransparency = 1
        localPlayer.PlayerGui.GUI.Crosshairs.Scope.Scope.Size =
            UDim2.new(2, 0, 2, 0)
        localPlayer.PlayerGui.GUI.Crosshairs.Scope.Scope.Position =
            UDim2.new(-0.5, 0, -0.5, 0)
        localPlayer.PlayerGui.GUI.Crosshairs.Scope.Scope.Blur.ImageTransparency =
            1
        localPlayer.PlayerGui.GUI.Crosshairs.Scope.Scope.Blur.Blur.ImageTransparency =
            1
        localPlayer.PlayerGui.GUI.Crosshairs.Frame1.Transparency = 1
        localPlayer.PlayerGui.GUI.Crosshairs.Frame2.Transparency = 1
        localPlayer.PlayerGui.GUI.Crosshairs.Frame3.Transparency = 1
        localPlayer.PlayerGui.GUI.Crosshairs.Frame4.Transparency = 1
    else
        localPlayer.PlayerGui.GUI.Crosshairs.Scope.ImageTransparency = 0
        localPlayer.PlayerGui.GUI.Crosshairs.Scope.Scope.ImageTransparency = 0
        localPlayer.PlayerGui.GUI.Crosshairs.Scope.Scope.Size =
            UDim2.new(1, 0, 1, 0)
        localPlayer.PlayerGui.GUI.Crosshairs.Scope.Scope.Position =
            UDim2.new(0, 0, 0, 0)
        localPlayer.PlayerGui.GUI.Crosshairs.Scope.Scope.Blur.ImageTransparency =
            0
        localPlayer.PlayerGui.GUI.Crosshairs.Scope.Scope.Blur.Blur.ImageTransparency =
            0
        localPlayer.PlayerGui.GUI.Crosshairs.Frame1.Transparency = 0
        localPlayer.PlayerGui.GUI.Crosshairs.Frame2.Transparency = 0
        localPlayer.PlayerGui.GUI.Crosshairs.Frame3.Transparency = 0
        localPlayer.PlayerGui.GUI.Crosshairs.Frame4.Transparency = 0
    end
    task.wait()
end)

runService.RenderStepped:Connect(function()
    if _G.RemoveFlash == true then
        localPlayer.PlayerGui.Blnd.Enabled = false
    else
        localPlayer.PlayerGui.Blnd.Enabled = true
    end
    task.wait()
end)

runService.RenderStepped:Connect(function()
    if _G.RemoveBulletsHoles == true then
        for _, bullet in pairs(debris:GetChildren()) do
            if bullet.Name == 'Bullet' then
                bullet:Remove()
            end
        end
    end
    task.wait()
end)

runService.RenderStepped:Connect(function()
    if _G.RemoveSmoke == true then
        for _, smoke in pairs(rayIgnore.Smokes:GetChildren()) do
            if smoke.Name == 'Smoke' then
                smoke:Remove()
            end
        end
    end
    task.wait()
end)

runService.RenderStepped:Connect(function()
    if _G.RemoveBlood == true then
        for _, blood in pairs(debris:GetChildren()) do
            if blood.Name == 'SurfaceGui' then
                blood:Remove()
            end
        end
    end
    task.wait()
end)

runService.RenderStepped:Connect(function()
    if _G.Noclip == true then
        for _, part in pairs(localPlayer.Character:GetChildren()) do
            if part:IsA('BasePart') and part.CanCollide == true then
                part.CanCollide = false
            end
        end
    else
        for _, part in pairs(localPlayer.Character:GetChildren()) do
            if part:IsA('BasePart') and part.CanCollide == true then
                part.CanCollide = true
            end
        end
    end
    task.wait()
end)

runService.RenderStepped:Connect(function()
    if _G.Fly == true then
        if localPlayer.Character ~= nil then
            local flySpeed = _G.FlySpeed or 16
            local flyVector = Vector3.new(0, 1, 0)

            if userInputService:IsKeyDown(Enum.KeyCode.W) then
                flyVector = flyVector
                    + (camera.CoordinateFrame.lookVector * flySpeed)
            end
            if userInputService:IsKeyDown(Enum.KeyCode.A) then
                flyVector = flyVector
                    + (camera.CoordinateFrame.rightVector * -flySpeed)
            end
            if userInputService:IsKeyDown(Enum.KeyCode.S) then
                flyVector = flyVector
                    + (camera.CoordinateFrame.lookVector * -flySpeed)
            end
            if userInputService:IsKeyDown(Enum.KeyCode.D) then
                flyVector = flyVector
                    + (camera.CoordinateFrame.rightVector * flySpeed)
            end

            localPlayer.Character.HumanoidRootPart.Velocity = flyVector
            localPlayer.Character.Humanoid.PlatformStand = true
        end
    end
    task.wait()
end)

runService.RenderStepped:Connect(function()
    if _G.Bhop == true then
        if
            localPlayer.Character ~= nil
            and userInputService:IsKeyDown(Enum.KeyCode.Space)
            and localPlayer.PlayerGui.GUI.Main.GlobalChat.Visible == false
        then
            localPlayer.Character.Humanoid.Jump = true
            local bhopSpeed = _G.BhopSpeed or 100
            local moveDirection = camera.CFrame.LookVector
                * Vector3.new(1, 0, 1)
            local movement = Vector3.new()

            movement = (
                userInputService:IsKeyDown(Enum.KeyCode.W)
                and (movement + moveDirection)
            ) or movement
            movement = (
                userInputService:IsKeyDown(Enum.KeyCode.S)
                and (movement - moveDirection)
            ) or movement
            movement = (
                userInputService:IsKeyDown(Enum.KeyCode.D)
                and (
                    movement + Vector3.new(-moveDirection.Z, 0, moveDirection.X)
                )
            ) or movement
            movement = (
                userInputService:IsKeyDown(Enum.KeyCode.A)
                and (
                    movement + Vector3.new(moveDirection.Z, 0, -moveDirection.X)
                )
            ) or movement

            if movement.Unit.X == movement.Unit.X then
                movement = movement.Unit
                localPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(
                    movement.X * bhopSpeed,
                    localPlayer.Character.HumanoidRootPart.Velocity.Y,
                    movement.Z * bhopSpeed
                )
            end
        end
    end
    task.wait()
end)

runService.RenderStepped:Connect(function()
    if aimbot.Enabled == true then
        local isMouseDown = userInputService:IsMouseButtonPressed(
            Enum.UserInputType.MouseButton2
        )
        if isMouseDown then
            local closestPlayer = GetClosestPlayer(camera.CFrame)
            if closestPlayer ~= nil then
                local screenPos = camera:WorldToScreenPoint(
                    closestPlayer.Character.Head.Position
                )
                local screenPos2D = Vector2.new(screenPos.X, screenPos.Y)
                if
                    (screenPos2D - fovCircle.Position).Magnitude
                    < fovCircle.Radius
                then
                    camera.CFrame = camera.CFrame:Lerp(
                        CFrame.new(
                            camera.CFrame.Position,
                            closestPlayer.Character.Head.Position
                        ),
                        aimbot.Smoothing
                    )
                end
            end
        end
    end

    if aimbot.EnableFOV then
        fovCircle.Visible = true
        fovCircle.Position = workspace.CurrentCamera.ViewportSize / 2
    else
        fovCircle.Visible = false
    end

    task.wait()
end)

runService.RenderStepped:Connect(function()
    if
        localPlayer.Character ~= nil
        and localPlayer.Character.Humanoid.Health > 0
    then
        if _G.SpinBot then
            localPlayer.Character.Humanoid.AutoRotate = false
            localPlayer.Character.HumanoidRootPart.CFrame = localPlayer.Character.HumanoidRootPart.CFrame
                * CFrame.Angles(0, math.rad(_G.Speed or 50), 0)
        else
            localPlayer.Character.Humanoid.AutoRotate = true
        end
    end
    task.wait()
end)

runService.RenderStepped:Connect(function()
    if _G.ThirdPerson == true then
        if
            localPlayer.CameraMinZoomDistance ~= _G.ThirdPersonDistance or 10
        then
            localPlayer.CameraMinZoomDistance = _G.ThirdPersonDistance or 10
            localPlayer.CameraMaxZoomDistance = _G.ThirdPersonDistance or 10
            workspace.ThirdPerson.Value = true
        end
    elseif localPlayer.Character ~= nil then
        localPlayer.CameraMinZoomDistance = 0
        localPlayer.CameraMaxZoomDistance = 0
        workspace.ThirdPerson.Value = false
    end
    task.wait()
end)

runService.RenderStepped:Connect(function()
    camera.FieldOfView = _G.FieldOfView or 80
    task.wait()
end)

runService.RenderStepped:Connect(function()
    if _G.GunsChams == true then
        for _, model in ipairs(workspace.Camera:GetChildren()) do
            if model:IsA('Model') and model.Name == 'Arms' then
                for _, part in ipairs(model:GetChildren()) do
                    if part:IsA('MeshPart') or part:IsA('BasePart') then
                        part.Color = _G.ChamsColor
                            or Color3.fromRGB(200, 200, 200)
                        part.Material = Enum.Material.ForceField
                    end
                end
            end
        end
    else
        for _, model in ipairs(workspace.Camera:GetChildren()) do
            if model:IsA('Model') and model.Name == 'Arms' then
                for _, part in ipairs(model:GetChildren()) do
                    if part:IsA('MeshPart') or part:IsA('BasePart') then
                        part.Color = Color3.fromRGB(200, 200, 200)
                        part.Material = Enum.Material.Plastic
                    end
                end
            end
        end
    end
    task.wait()
end)

runService.RenderStepped:Connect(function()
    if _G.ArmsChams == true then
        for _, model in ipairs(workspace.Camera:GetChildren()) do
            if model:IsA('Model') and model.Name == 'Arms' then
                for _, childModel in ipairs(model:GetChildren()) do
                    if
                        childModel:IsA('Model')
                        and childModel.Name ~= 'AnimSaves'
                    then
                        for _, part in ipairs(childModel:GetChildren()) do
                            if part:IsA('BasePart') then
                                part.Transparency = 1
                                for _, child in ipairs(part:GetChildren()) do
                                    if child:IsA('BasePart') then
                                        child.Material =
                                            Enum.Material.ForceField
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    else
        for _, model in ipairs(workspace.Camera:GetChildren()) do
            if model:IsA('Model') and model.Name == 'Arms' then
                for _, childModel in ipairs(model:GetChildren()) do
                    if
                        childModel:IsA('Model')
                        and childModel.Name ~= 'AnimSaves'
                    then
                        for _, part in ipairs(childModel:GetChildren()) do
                            if part:IsA('BasePart') then
                                part.Transparency = 0
                                for _, child in ipairs(part:GetChildren()) do
                                    if child:IsA('BasePart') then
                                        child.Material = Enum.Material.Plastic
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    task.wait()
end)

runService.RenderStepped:Connect(function()
    for _, player in ipairs(players:GetChildren()) do
        if chams.Enabled == true then
            if chams.UseTeamColor == true then
                if player.Character:FindFirstChild('Highlight') then
                    player.Character.Highlight.FillColor =
                        player.TeamColor.Color
                else
                    local highlight =
                        Instance.new('Highlight', player.Character)
                    highlight.FillColor = player.TeamColor.Color
                end
            elseif player.Character:FindFirstChild('Highlight') then
                player.Character.Highlight.FillColor = chams.ChamsColor
                    or Color3.fromRGB(200, 200, 200)
            else
                local highlight = Instance.new('Highlight', player.Character)
                highlight.FillColor = chams.ChamsColor
                    or Color3.fromRGB(200, 200, 200)
            end
        elseif player.Character:FindFirstChild('Highlight') then
            player.Character.Highlight:Destroy()
        end
    end
    task.wait()
end)

-- end of script
