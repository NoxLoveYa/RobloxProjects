--[[
    StarUI Library
    Made by: NoxLoveYa
    Version: 0.0.1
]]

-- Services
local UserInputService: UserInputService = cloneref(game:GetService("UserInputService"))
local RunService: RunService = cloneref(game:GetService("RunService"))
local Camera: Camera = cloneref(workspace.CurrentCamera)

-- Types
export type Text = {
    visible: boolean?,
    Zindex: number?,
    Transparency: number?,
    Color: Color3?,
    Text: string?,
    TextBounds: Vector2?,
    Font: number?,
    Size: number?,
    Position: Vector2?,
    Center: boolean?,
    Outline: boolean?,
    OutlineColor: Color3?,
    Destroy: () -> ()?,
}

-- Constants
local VERSION = "0.0.1"
local SCREENSIZE: Vector2 = Camera.ViewportSize

-- Themes
local THEMES: {{Text: Text}} = {}
THEMES.Text = {}

THEMES.Text.Header = {
    Visible = true,
    Center = true,
    Outline = true,
    Color = Color3.new(1, 0, 0.384313),
    Font = 1
}

THEMES.Text.TabHeader = {
    Visible = true,
    Outline = true,
    Color = Color3.new(0.529411, 0.701960, 1),
    Font = 1
}

THEMES.Text.ActiveTab = {
    Visible = true,
    Outline = true,
    Color = Color3.new(0.749019, 1, 0.529411),
    Font = 1
}

-- Variables
local library = {}
local tabs: {Text} = {}
local connections = {}

local activeTab: number = 1

local cornerLeftPosition: Vector2 = Vector2.new(SCREENSIZE.X - 450, 15)

-- Functions
local function applyTheme(text: Text, theme: Text)
    text.Visible = theme.Visible or text.Visible
    text.ZIndex = theme.Zindex or text.ZIndex
    text.Transparency = theme.Transparency or text.Transparency
    text.Color = theme.Color or text.Color
    text.Font = theme.Font or text.Font
    text.Size = theme.Size or text.Size
    text.Center = theme.Center or text.Center
    text.Outline = theme.Outline or text.Outline
    text.OutlineColor = theme.OutlineColor or text.OutlineColor    
end

local function registerText(text: string, position: Vector2?, options: Text?): Text
    local textObject: Text = Drawing.new("Text")
    textObject.Text = text
    textObject.Visible = options.Text or true
    textObject.ZIndex = options.Zindex or 1
    textObject.Transparency = options.Transparency or 1
    textObject.Color = options.Color or Color3.new(1, 1, 1)
    textObject.Font = options.Font or 0
    textObject.Size = options.Size or 18
    textObject.Position = position or Vector2.new(0, 0)
    textObject.Center = options.Center or false
    textObject.Outline = options.Outline or false
    textObject.OutlineColor = options.OutlineColor or Color3.new(0, 0, 0)

    return textObject
end

local function updateSelectedTab(newTab: number)
    print("Updating selected tab to:", newTab)
    if newTab == activeTab then return end
    if newTab < 1 then newTab = #tabs elseif newTab > #tabs then newTab = 1 end

    applyTheme(tabs[activeTab], THEMES.Text.TabHeader)
    activeTab = newTab
    applyTheme(tabs[activeTab], THEMES.Text.ActiveTab)

    print("Selected tab updated to:", activeTab)
end

local function initUI()
    -- HEADER
    local headerText: Text = registerText("Kittyware V:"..VERSION, cornerLeftPosition, THEMES.Text.Header)

    -- TABS
    table.insert(tabs, registerText("Visuals", cornerLeftPosition + Vector2.new(0, headerText.TextBounds.Y), THEMES.Text.TabHeader))
    table.insert(tabs, registerText("Misc", cornerLeftPosition + Vector2.new(0, headerText.TextBounds.Y), THEMES.Text.TabHeader))


    applyTheme(tabs[activeTab], THEMES.Text.ActiveTab)

    local tabSpacing = 32
    local totalTabsWidth = 0
    for _, tab in ipairs(tabs) do
        totalTabsWidth += tab.TextBounds.X
    end

    local totalSpacingWidth = tabSpacing * math.max(#tabs - 1, 0)
    local totalRowWidth = totalTabsWidth + totalSpacingWidth
    local headerCenterX = headerText.Position.X
    if not headerText.Center then
        headerCenterX += headerText.TextBounds.X / 2
    end

    local headerLeftX = headerCenterX - (headerText.TextBounds.X / 2)
    local headerRightX = headerCenterX + (headerText.TextBounds.X / 2)
    local sideInset = ((headerRightX - headerLeftX) - totalRowWidth) / 2
    local rowStartX = headerLeftX + sideInset
    local rowY = cornerLeftPosition.Y + headerText.TextBounds.Y

    local currentX = rowStartX
    for i, tab in ipairs(tabs) do
        tab.Position = Vector2.new(currentX, rowY)
        currentX += tab.TextBounds.X

        if i < #tabs then
            currentX += tabSpacing
        end
    end
end

-- Library
library.initUI = initUI

connections["InputBegan"] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.Delete then
        cleardrawcache()
    elseif input.KeyCode == Enum.KeyCode.Left then
        updateSelectedTab(activeTab - 1)
    elseif input.KeyCode == Enum.KeyCode.Right then
        updateSelectedTab(activeTab + 1)
    end
end)

-- Example Usage
initUI()