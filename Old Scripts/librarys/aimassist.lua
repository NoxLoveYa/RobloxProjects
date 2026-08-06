-- AimAssist.lua
local AimAssist = {}
AimAssist.__index = AimAssist

-- Dependencies
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')
local visiblePlayers = {}

function AimAssist.new()
    local self = setmetatable({}, AimAssist)

    -- Default settings
    self.Settings = {
        Enabled = false,
        Strength = 10.0,
        FOV = 30,
        TargetPart = 'Head',
        RequireMouseDown = true,
        TeamCheck = false,
        VisibleCheck = false,
        TriggerbotEnabled = true,
    }

    -- Internal state
    self.LocalPlayer = Players.LocalPlayer
    self.Camera = workspace.CurrentCamera
    self.Connection = nil
    self.LastTarget = nil
    self.AimAssistActive = false

    return self
end

function AimAssist:GetBestTarget()
    local bestTarget = nil
    local closestAngle = self.Settings.FOV
    local cameraPos = self.Camera.CFrame.Position
    local cameraLook = self.Camera.CFrame.LookVector

    for _, player in pairs(Players:GetPlayers()) do
        if player == self.LocalPlayer then
            continue
        end
        if self.Settings.TeamCheck and player.Team == self.LocalPlayer.Team then
            continue
        end
        if not player.Character then
            continue
        end

        local humanoid = player.Character:FindFirstChild('Humanoid')
        local targetPart =
            player.Character:FindFirstChild(self.Settings.TargetPart)

        if not humanoid or humanoid.Health <= 0 or not targetPart then
            continue
        end

        -- Visibility check
        if self.Settings.VisibleCheck and not visiblePlayers[player] then
            continue
        end

        -- Calculate angle to target
        local targetPos = targetPart.Position
        local directionToTarget = (targetPos - cameraPos).Unit
        local dotProduct = cameraLook:Dot(directionToTarget)
        local angle = math.deg(math.acos(math.clamp(dotProduct, -1, 1)))

        -- Check if within FOV and closest
        if angle < closestAngle then
            closestAngle = angle
            bestTarget = {
                Player = player,
                Position = targetPos,
                Character = player.Character,
            }
        end
    end

    return bestTarget
end

function AimAssist:SmoothAimTowards(targetPosition, deltaTime)
    local cameraPos = self.Camera.CFrame.Position
    local currentLook = self.Camera.CFrame.LookVector
    local desiredLook = (targetPosition - cameraPos).Unit

    -- Smooth interpolation
    local lerpAlpha = self.Settings.Strength * deltaTime * 10
    local smoothedLook = currentLook:Lerp(desiredLook, lerpAlpha)

    -- Apply the new camera direction
    self.Camera.CFrame = CFrame.new(cameraPos, cameraPos + smoothedLook)
end

function AimAssist:Start()
    if self.Connection then
        return
    end

    self.Connection = RunService.RenderStepped:Connect(function(deltaTime)
        if not self.Settings.Enabled then
            self.AimAssistActive = false
            return
        end
        if not self.LocalPlayer.Character then
            return
        end

        -- Check activation conditions
        local shouldActivate = true
        if self.Settings.RequireMouseDown then
            shouldActivate = UserInputService:IsMouseButtonPressed(
                Enum.UserInputType.MouseButton2
            )
        end

        if shouldActivate then
            local target = self:GetBestTarget()
            if target then
                self:SmoothAimTowards(target.Position, deltaTime)
                self.LastTarget = target
                self.AimAssistActive = true
            else
                self.AimAssistActive = false
            end
        else
            self.AimAssistActive = false
        end
        -- if self.Settings.TriggerbotEnabled then
        --     local rayOrigin = self.Camera.CFrame.Position
        --     local rayDirection = (self.Camera.CFrame.LookVector).Unit * 1000
        --     local raycastParams = RaycastParams.new()
            
        --     -- Exclude only our own character (so we hit everything else)
        --     raycastParams.FilterDescendantsInstances = {self.LocalPlayer.Character}
        --     raycastParams.FilterType = Enum.RaycastFilterType.Blacklist  -- This is actually correct!

        --     local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

        --     if raycastResult then
        --         local hitInstance = raycastResult.Instance
        --         -- Check if we hit a player (not a wall)
        --         local character = hitInstance:FindFirstAncestorOfClass("Model")
        --         if character and character:FindFirstChild("Humanoid") then
        --             local player = Players:GetPlayerFromCharacter(character)
        --             if player and player ~= self.LocalPlayer then
        --                 mouse1click()
        --             end
        --         end
        --     end
        -- end
    end)
    self.VisibleConnection = RunService.RenderStepped:Connect(function()
        visiblePlayers = {}
        for _, player in pairs(Players:GetPlayers()) do
            if player == self.LocalPlayer then
                continue
            end
            if not player.Character then
                continue
            end

            local humanoid = player.Character:FindFirstChild('Humanoid')
            local targetPart =
                player.Character:FindFirstChild(self.Settings.TargetPart)

            if not humanoid or humanoid.Health <= 0 or not targetPart then
                continue
            end

            local rayOrigin = self.Camera.CFrame.Position
            local rayDirection = (targetPart.Position - rayOrigin).Unit * 1000
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {self.LocalPlayer.Character}
            raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

            local raycastResult =
                workspace:Raycast(rayOrigin, rayDirection, raycastParams)

            if raycastResult and raycastResult.Instance:IsDescendantOf(player.Character) then
                visiblePlayers[player] = true
            end
        end
    end)
end

function AimAssist:Stop()
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
    if self.VisibleConnection then
        self.VisibleConnection:Disconnect()
        self.VisibleConnection = nil
    end
    self.AimAssistActive = false
end

function AimAssist:Destroy()
    self:Stop()
    self.Settings.Enabled = false
end

-- Export the library
return AimAssist
