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

export type Tab = {
    Text: string,
    Elements: {string},
}

export type Theme = {
    Text: {
        Header: Text,
        TabHeader: Text,
        ActiveTab: Text,
        Element: Text,
    }
}

export type Library = {
    initUI: () -> (),
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

THEMES.Text.Element = {
    Visible = true,
    Outline = true,
    Color = Color3.new(1, 1, 1),
    Font = 0
}

-- Variables
local library = {}
local tabs: {Text} = {}
local nameToIndexTab = {}
local elements: {{Text}} = {}
local connections = {}

local activeTab: number = 1

local cornerLeftPosition: Vector2 = Vector2.new(SCREENSIZE.X - 450, 15)
local headerCenterX = 0
local elementsStartY = 0

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
    options = options or {}

    textObject.Text = text
    textObject.Visible = options.Visible or true
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

local function renderElements()
    local elementColumns = 2
    local elementSpacingX = 28
    local elementSpacingY = 8

    for tabIndex, tabElements in pairs(elements) do
        local isActiveTab = tabIndex == activeTab

        for _, element in ipairs(tabElements) do
            element.Visible = isActiveTab
        end

        if isActiveTab then
            local leftColumnWidth = 0
            local rightColumnWidth = 0

            for elementIndex, element in ipairs(tabElements) do
                if elementIndex % elementColumns == 1 then
                    leftColumnWidth = math.max(leftColumnWidth, element.TextBounds.X)
                else
                    rightColumnWidth = math.max(rightColumnWidth, element.TextBounds.X)
                end
            end

            local blockWidth = leftColumnWidth
            if rightColumnWidth > 0 then
                blockWidth += elementSpacingX + rightColumnWidth
            end

            local blockStartX = headerCenterX - (blockWidth / 2)
            local rowIndex = 0
            local elementIndex = 1

            while elementIndex <= #tabElements do
                local rowHeight = 0
                local leftElement = tabElements[elementIndex]
                local rightElement = tabElements[elementIndex + 1]

                if leftElement then
                    rowHeight = math.max(rowHeight, leftElement.TextBounds.Y)
                end

                if rightElement then
                    rowHeight = math.max(rowHeight, rightElement.TextBounds.Y)
                end

                local currentY = elementsStartY + (rowIndex * (rowHeight + elementSpacingY))

                if leftElement then
                    leftElement.Position = Vector2.new(blockStartX, currentY)
                end

                if rightElement then
                    rightElement.Position = Vector2.new(blockStartX + leftColumnWidth + elementSpacingX, currentY)
                end

                elementIndex += elementColumns
                rowIndex += 1
            end
        end
    end
end

local function updateSelectedTab(newTab: number)
    print("Updating selected tab to:", newTab)
    if newTab == activeTab then return end
    if newTab < 1 then newTab = #tabs elseif newTab > #tabs then newTab = 1 end

    applyTheme(tabs[activeTab], THEMES.Text.TabHeader)
    activeTab = newTab
    applyTheme(tabs[activeTab], THEMES.Text.ActiveTab)
    renderElements()

    print("Selected tab updated to:", activeTab)
end

local function registerTab(name: string)
    local newTab = registerText(name, Vector2.new(0, 0), THEMES.Text.TabHeader)
    table.insert(tabs, newTab)
    nameToIndexTab[name] = #tabs
    return newTab
end

local registerElement = function(element: string, tab: string)
    local tabIndex = nameToIndexTab[tab]
    if not tabIndex then
        warn("Tab '"..tab.."' does not exist. Element not registered.")
        return
    end
    if not elements[tabIndex] then
        elements[tabIndex] = {}
    end

    local newElement = registerText(element, Vector2.new(0, 0), THEMES.Text.Element)

    table.insert(elements[tabIndex], newElement)
end

local function initUI(tabDefinitions: {Tab})
    -- HEADER
    local headerText: Text = registerText("Kittyware V:"..VERSION, cornerLeftPosition, THEMES.Text.Header)

    -- TABS
    for _, tabInfo in pairs(tabDefinitions) do
        registerTab(tabInfo.Text)
        for _, element in pairs(tabInfo.Elements) do
            registerElement(element, tabInfo.Text)
        end
    end

    applyTheme(tabs[activeTab], THEMES.Text.ActiveTab)

    local tabSpacing = 32
    local totalTabsWidth = 0
    for _, tab in ipairs(tabs) do
        totalTabsWidth += tab.TextBounds.X
    end

    local totalSpacingWidth = tabSpacing * math.max(#tabs - 1, 0)
    local totalRowWidth = totalTabsWidth + totalSpacingWidth
    headerCenterX = headerText.Position.X
    if not headerText.Center then
        headerCenterX += headerText.TextBounds.X / 2
    end

    local headerLeftX = headerCenterX - (headerText.TextBounds.X / 2)
    local headerRightX = headerCenterX + (headerText.TextBounds.X / 2)
    local sideInset = ((headerRightX - headerLeftX) - totalRowWidth) / 2
    local rowStartX = headerLeftX + sideInset
    local tabOffsetY = 6
    local rowY = cornerLeftPosition.Y + headerText.TextBounds.Y + tabOffsetY
    local maxTabHeight = 0

    local currentX = rowStartX
    for i, tab in ipairs(tabs) do
        tab.Position = Vector2.new(currentX, rowY)
        maxTabHeight = math.max(maxTabHeight, tab.TextBounds.Y)
        currentX += tab.TextBounds.X

        if i < #tabs then
            currentX += tabSpacing
        end
    end

    elementsStartY = rowY + maxTabHeight + 14
    renderElements()
end

-- Library
library.initUI = initUI
library.THEMES = THEMES

connections["InputBegan"] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if (not gameProcessed) and input.KeyCode == Enum.KeyCode.Delete then
        cleardrawcache()
    elseif input.KeyCode == Enum.KeyCode.Left then
        updateSelectedTab(activeTab - 1)
    elseif input.KeyCode == Enum.KeyCode.Right then
        updateSelectedTab(activeTab + 1)
    end
end)

-- Example Usage
initUI({
    {
        Text = "Combat",
        Elements = {"Aimbot", "Triggerbot"}
    },
    {
        Text = "Visuals",
        Elements = {"Chams", "Esp"}
    },
    {
        Text = "Movement",
        Elements = {"Noclip", "Fly", "Speed"}
    }
})