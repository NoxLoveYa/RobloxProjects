local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local PlayersFolder = Workspace:WaitForChild("Players")
local RunService = game:GetService("RunService")

local TeamIndexToName = {
    [1] = "Ghosts",
    [2] = "Phantoms"
}

local PhantomSleeveColor = Color3.fromRGB(155, 182, 255)

local isAlive = false
local currentTeam = nil

local function GetCurrentTeam()
    for _, child in ipairs(workspace.CurrentCamera:GetChildren()) do
        local sleeves = child:FindFirstChild("Sleeves")
        if sleeves then
            local slot1 = sleeves:FindFirstChild("Slot1")
            if slot1 then
                -- Check if the color matches Phantom sleeve color
                if slot1.Color3 == PhantomSleeveColor then
                    currentTeam = TeamIndexToName[2] -- Phantoms
                else
                    currentTeam = TeamIndexToName[1] -- Ghosts
                end
                return
            end
        end
    end
    currentTeam = nil
end

function applyHighlight(currentTeamIndex, PlayersTeams)
    for index, currentFolder in ipairs(PlayersTeams) do
        -- Only process enemy teams
        if TeamIndexToName[index] ~= TeamIndexToName[currentTeamIndex] then
            for _, enemy in pairs(currentFolder:GetChildren()) do
                local highlight = enemy:FindFirstChild("KittyHighlight")
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "KittyHighlight"
                    highlight.FillTransparency = 1
                    highlight.OutlineColor = Color3.new(1, 0.211764, 0.407843)
                    highlight.Parent = enemy
                end
            end
        else
            -- Remove highlights from teammates
            for _, teammate in pairs(currentFolder:GetChildren()) do
                local highlight = teammate:FindFirstChild("KittyHighlight")
                if highlight then
                    highlight:Destroy()
                end
            end
        end
    end
end

RunService.Heartbeat:Connect(function()
    isAlive = #workspace.CurrentCamera:GetChildren() >= 3
    if not isAlive then 
        currentTeam = nil
        return 
    end
    
    if currentTeam == nil then
        GetCurrentTeam()
    end
    
    if not currentTeam then return end
    
    local PlayersTeams = PlayersFolder:GetChildren()
    local currentTeamIndex = currentTeam == "Ghosts" and 1 or 2
    
    applyHighlight(currentTeamIndex, PlayersTeams)
    -- for _, camChild: Model in ipairs(workspace.CurrentCamera:GetChildren()) do
    --     local sleeves: Part = camChild:FindFirstChild("Sleeves")
    --     if not sleeves then continue end
    --     for _, child:Instance in ipairs(sleeves:GetChildren()) do
    --         child:Destroy()
    --     end
    --     sleeves.Material = Enum.Material.Neon
    --     sleeves.Transparency = 0.5
    --     sleeves.Color = Color3.new(1, 0.211764, 0.407843)
    -- end
end)