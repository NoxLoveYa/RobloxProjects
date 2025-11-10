local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Settings = {
    BoxColor = Color3.new(0.515, 1, 0),
    BoxSize = 2
}

function createOverlay(character: Model)
    local overlay = Instance.new("BillboardGui", character)

    overlay.Size = UDim2.new(4.5, 0, 7, 0)
    overlay.AlwaysOnTop = true

    -- Actual Box
    local boxFrame: Frame = Instance.new("Frame", overlay)
    boxFrame.Size = UDim2.new(1, 0, 1, 0)
    boxFrame.BackgroundTransparency = 1
    boxFrame.ZIndex = 2

    local boxCorner: UIStroke = Instance.new("UIStroke", boxFrame)
    boxCorner.Thickness = Settings.BoxSize
    boxCorner.Color = Settings.BoxColor
    boxCorner.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    boxCorner.LineJoinMode = Enum.LineJoinMode.Miter

    local boxStrokeFrame: Frame = Instance.new("Frame", overlay)
    boxStrokeFrame.Position = UDim2.new(0, Settings.BoxSize, 0, Settings.BoxSize)
    boxStrokeFrame.Size = UDim2.new(1, -Settings.BoxSize - 2, 1, -Settings.BoxSize - 2)
    boxStrokeFrame.BackgroundTransparency = 1

    local boxCornerStroke: UIStroke = Instance.new("UIStroke", boxStrokeFrame)
    boxCornerStroke.Thickness = Settings.BoxSize + 4
    boxCornerStroke.Color = Color3.new(0, 0, 0)
    boxCornerStroke.LineJoinMode = Enum.LineJoinMode.Miter
end

function initEsp(player: Player)
    local character: Model = player.Character
    if (character ~= nil) then
        createOverlay(character)
    end
    player.CharacterAdded:Connect(function(character)
        createOverlay(character)
    end)
end

for _, player: Player in ipairs(Players:GetPlayers()) do
    --if player == Players.LocalPlayer then continue end
    initEsp(player)
end
Players.PlayerAdded:Connect(function(player)
    --if player == Players.LocalPlayer then return end
    initEsp(player)
end)