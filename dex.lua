local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')

local JoinToggle = false
local debounce = false

local clickRemote: RemoteEvent = game:GetService('ReplicatedStorage').UI.Remotes.ClickMoney
local joinRemote: RemoteEvent = game:GetService("ReplicatedStorage").Giveaways.Remotes.Join

RunService.RenderStepped:Connect(function()
    clickRemote:FireServer()
    if (JoinToggle and not debounce) then
        joinRemote:FireServer()
        debounce = true
        task.delay(2.5, function() debounce = false end)
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end

    if input.KeyCode == Enum.KeyCode.K then
        JoinToggle = not JoinToggle
    end
end)