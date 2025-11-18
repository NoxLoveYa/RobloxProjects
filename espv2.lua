--Services
local Workspace = game:GetService("Workspace")
local PlayersService = game:GetService("Players")

--Store
local localPlayer = PlayersService.LocalPlayer

local SETTINGS = {
    AimAssist = {
        Enabled = true
    },
    ESP = {
        Enabled = true,
        Ennemies = {
            Enabled = true,
            Name = true, -- TODO
            Box = true, -- TODO
            Distance = true, -- TODO
            Weapons = true, -- TODO
            Inventory = true, -- TODO,
            Skeleton = true, -- TODO
            HeadCircle = true, -- TODO
            Glow = true -- TODO
        },
        Teammates = {
            Enabled = true,
            Name = true, -- TODO
            Box = true, -- TODO
            Distance = true, -- TODO
            Weapons = true, -- TODO
            Inventory = true, -- TODO,
            Skeleton = true, -- TODO
            HeadCircle = true, -- TODO
            Glow = true -- TODO
        }
    }
}

-- PLAYER HANDLER
local Players = {}