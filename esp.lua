local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local esp = loadstring(game:HttpGet("https://raw.githubusercontent.com/NoxLoveYa/RobloxProjects/main/esp_library.lua", true))()
local esp_settings = {
    Render = {
        render_teammates = false,
        render_ennemies = true,
        font = 0,
    },
    Colors = {
        ennemies = Color3.fromRGB(153, 94, 172),
        teammates = Color3.fromRGB(158, 172, 94),
    }
}

--connect the esp for the players already here
for index, player in ipairs(Players:GetPlayers()) do
    if player == Players.LocalPlayer then continue end

    esp.update_settings(esp_settings)
    esp.connect_esp(player)
end