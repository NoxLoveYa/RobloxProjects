local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local Settings = {
    BoxColor = Color3.new(0.515, 1, 0),
    BoxSize = 2,
    MaxDistance = 500
}

local ActiveOverlays = {}

function createOverlay(character: Model)
    local overlay = Instance.new("BillboardGui", character)
    overlay.Size = UDim2.new(5.0, 0, 7, 0)
    overlay.AlwaysOnTop = true
    overlay.Name = "ESPOverlay"

    -- main box
    local boxFrame: Frame = Instance.new("Frame", overlay)
    boxFrame.Size = UDim2.new(1, 0, 1, 0)
    boxFrame.BackgroundTransparency = 1
    boxFrame.ZIndex = 2

    local boxCorner: UIStroke = Instance.new("UIStroke", boxFrame)
    boxCorner.Thickness = Settings.BoxSize
    boxCorner.Color = Settings.BoxColor
    boxCorner.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    boxCorner.LineJoinMode = Enum.LineJoinMode.Miter

    -- black outline frame
    local boxStrokeFrame: Frame = Instance.new("Frame", overlay)
    boxStrokeFrame.Position = UDim2.new(0, Settings.BoxSize, 0, Settings.BoxSize)
    boxStrokeFrame.Size = UDim2.new(1, -Settings.BoxSize - 2, 1, -Settings.BoxSize - 2)
    boxStrokeFrame.BackgroundTransparency = 1

    local boxCornerStroke: UIStroke = Instance.new("UIStroke", boxStrokeFrame)
    boxCornerStroke.Thickness = Settings.BoxSize + 4
    boxCornerStroke.Color = Color3.new(0, 0, 0)
    boxCornerStroke.LineJoinMode = Enum.LineJoinMode.Miter

    ActiveOverlays[character] = overlay
end

function initEsp(player: Player)
    if player.Character then
        createOverlay(player.Character)
    end

    player.CharacterAdded:Connect(function(character)
        createOverlay(character)
    end)

    player.CharacterRemoving:Connect(function(character)
        ActiveOverlays[character] = nil
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    initEsp(player)
end
Players.PlayerAdded:Connect(initEsp)

RunService.RenderStepped:Connect(function()
    for character, overlay in pairs(ActiveOverlays) do
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            overlay.Enabled = false
            continue
        end

        local dist = (Camera.CFrame.Position - hrp.Position).Magnitude

        overlay.Enabled = (dist <= Settings.MaxDistance)
    end
end)
