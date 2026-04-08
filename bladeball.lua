local runService: RunService = game:GetService("RunService")
local localPlayer: Player = game.Players.LocalPlayer

runService.RenderStepped:Connect(function()
    for _, ball: Model in pairs(workspace.Balls:GetChildren()) do
        if not ball and not ball.PrimaryPart then end

        local body: BasePart = ball.PrimaryPart
        local velocity: Vector3 = body.Velocity
        local speed: number = velocity.Magnitude
        local direction: Vector3 = velocity.Unit
        local distanceFromPlayer = (localPlayer.Character.HumanoidRootPart.Position - body.Position).Magnitude
        if distanceFromPlayer < 20 then
            Input.mouse1click()
        end
    end
end)