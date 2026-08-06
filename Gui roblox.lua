-- Radium Hub v1.0
-- Custom UI Library for Roblox

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local HUB_VERSION = "1.0.0"

-- Font: raw Enum values — always compatible
local FONT = Enum.Font.Gotham
local FONT_BOLD = Enum.Font.GothamBold

-- Accent colors
local AccentColors = {
	Purple = Color3.fromRGB(99, 102, 241),
	Cyan = Color3.fromRGB(6, 182, 212),
	Green = Color3.fromRGB(34, 197, 94),
	Blue = Color3.fromRGB(59, 130, 246),
	Yellow = Color3.fromRGB(250, 204, 21),
	Orange = Color3.fromRGB(249, 115, 22),
	Red = Color3.fromRGB(239, 68, 68),
	Pink = Color3.fromRGB(236, 72, 153),
	White = Color3.fromRGB(255, 255, 255),
}

-- Background themes
local BgThemes = {
	Dark = {
		Bg = Color3.fromRGB(18, 18, 18), BgSec = Color3.fromRGB(22, 22, 22),
		BgTer = Color3.fromRGB(30, 30, 30), BgElev = Color3.fromRGB(38, 38, 38),
		Border = Color3.fromRGB(50, 50, 50),
	},
	Darker = {
		Bg = Color3.fromRGB(10, 10, 10), BgSec = Color3.fromRGB(14, 14, 14),
		BgTer = Color3.fromRGB(20, 20, 20), BgElev = Color3.fromRGB(28, 28, 28),
		Border = Color3.fromRGB(40, 40, 40),
	},
	Midnight = {
		Bg = Color3.fromRGB(15, 15, 25), BgSec = Color3.fromRGB(20, 20, 32),
		BgTer = Color3.fromRGB(28, 28, 42), BgElev = Color3.fromRGB(38, 38, 55),
		Border = Color3.fromRGB(50, 50, 70),
	},
	Ocean = {
		Bg = Color3.fromRGB(12, 20, 25), BgSec = Color3.fromRGB(16, 26, 32),
		BgTer = Color3.fromRGB(22, 34, 42), BgElev = Color3.fromRGB(30, 44, 55),
		Border = Color3.fromRGB(40, 58, 70),
	},
	Forest = {
		Bg = Color3.fromRGB(14, 20, 14), BgSec = Color3.fromRGB(18, 26, 18),
		BgTer = Color3.fromRGB(25, 35, 25), BgElev = Color3.fromRGB(34, 46, 34),
		Border = Color3.fromRGB(45, 60, 45),
	},
	Wine = {
		Bg = Color3.fromRGB(22, 14, 18), BgSec = Color3.fromRGB(28, 18, 24),
		BgTer = Color3.fromRGB(38, 26, 32), BgElev = Color3.fromRGB(50, 36, 42),
		Border = Color3.fromRGB(65, 48, 55),
	},
	Charcoal = {
		Bg = Color3.fromRGB(25, 25, 25), BgSec = Color3.fromRGB(32, 32, 32),
		BgTer = Color3.fromRGB(42, 42, 42), BgElev = Color3.fromRGB(52, 52, 52),
		Border = Color3.fromRGB(65, 65, 65),
	},
}

local AccentOrder = {"Purple", "Cyan", "Green", "Blue", "Yellow", "Orange", "Red", "Pink", "White"}
local BgThemeOrder = {"Dark", "Darker", "Midnight", "Ocean", "Forest", "Wine", "Charcoal"}

-- Current theme state
local Accent = Color3.fromRGB(99, 102, 241)
local CurrentBgTheme = "Dark"
local Bg = BgThemes.Dark.Bg
local BgSec = BgThemes.Dark.BgSec
local BgTer = BgThemes.Dark.BgTer
local BgElev = BgThemes.Dark.BgElev
local Border = BgThemes.Dark.Border
local Text = Color3.fromRGB(255, 255, 255)
local TextSec = Color3.fromRGB(150, 150, 150)
local TextMut = Color3.fromRGB(100, 100, 100)
local Success = Color3.fromRGB(34, 197, 94)
local Error = Color3.fromRGB(239, 68, 68)
local Warning = Color3.fromRGB(250, 204, 21)
local Info = Color3.fromRGB(59, 130, 246)

-- State flags
local GlowEnabled = true
local TransparencyMode = false
local ToggleKeybind = Enum.KeyCode.RightShift

-- Tweens
local TweenFast  = TweenInfo.new(0.1,  Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TweenMed   = TweenInfo.new(0.2,  Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TweenSmooth = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- Element tracking tables
local AccentElements     = {}
local BgElements         = {}
local BgSecElements      = {}
local BgTerElements      = {}
local BgElevElements     = {}
local BorderElements     = {}
local ComponentBgs       = {}
local ToggleBgBtns       = {} -- toggle knob backgrounds, tracked for theme changes
local SearchableItems    = {}
local GlowFrames         = {}
local OpenDropdowns      = {}
local DropdownOptionBtns = {}

-- ============================ UTILITY ============================
local tweenCache = {}
local function Tween(obj, props, info)
	if tweenCache[obj] then tweenCache[obj]:Cancel() end
	tweenCache[obj] = TweenService:Create(obj, info or TweenFast, props)
	tweenCache[obj]:Play()
end

local function Ripple(parent, x, y)
	local r = Instance.new("Frame")
	r.BackgroundColor3 = Color3.new(1, 1, 1)
	r.BackgroundTransparency = 0.85
	r.BorderSizePixel = 0
	r.ZIndex = 10
	r.Size = UDim2.new(0, 0, 0, 0)
	r.Position = UDim2.new(0, x - parent.AbsolutePosition.X, 0, y - parent.AbsolutePosition.Y)
	r.Parent = parent
	local size = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2
	local t = TweenService:Create(r, TweenInfo.new(0.35), {
		Size = UDim2.new(0, size, 0, size),
		Position = UDim2.new(0, x - parent.AbsolutePosition.X - size/2, 0, y - parent.AbsolutePosition.Y - size/2),
		BackgroundTransparency = 1
	})
	t:Play()
	t.Completed:Connect(function() r:Destroy() end)
end

local function CloseAllDropdowns()
	for _, closeFunc in ipairs(OpenDropdowns) do
		pcall(closeFunc)
	end
end

-- Force Potassium renderer to repaint after property changes
local function nudgeRender()
	if Window then Window.ZIndex = Window.ZIndex + 1 end
	if Window then Window.ZIndex = Window.ZIndex - 1 end
end

-- ====================== NOTIFICATION SYSTEM ======================
local Notifications = {}
local function Notify(title, text, duration, notiType)
	duration = duration or 3
	notiType = notiType or "info"
	local colors = {
		success = {bg = Color3.fromRGB(22, 60, 30), accent = Success},
		error   = {bg = Color3.fromRGB(60, 22, 22), accent = Error},
		warning = {bg = Color3.fromRGB(60, 55, 20), accent = Warning},
		info    = {bg = Color3.fromRGB(22, 35, 55), accent = Info},
	}
	local c = colors[notiType] or colors.info

	local Noti = Instance.new("Frame")
	Noti.Size = UDim2.new(0, 260, 0, 56)
	Noti.Position = UDim2.new(1, -270, 0, 10 + (#Notifications * 62))
	Noti.BackgroundColor3 = c.bg
	Noti.BorderSizePixel = 0
	Noti.ClipsDescendants = true
	Noti.ZIndex = 200
	Noti.Parent = ScreenGui or nil

	local AccBar = Instance.new("Frame")
	AccBar.Size = UDim2.new(0, 3, 1, 0)
	AccBar.BackgroundColor3 = c.accent
	AccBar.BorderSizePixel = 0
	AccBar.ZIndex = 201
	AccBar.Parent = Noti

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Size = UDim2.new(1, -20, 0, 18)
	TitleLabel.Position = UDim2.new(0, 12, 0, 6)
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Text = title or "Notification"
	TitleLabel.TextColor3 = Text
	TitleLabel.TextSize = 12
	TitleLabel.Font = FONT_BOLD
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.ZIndex = 201
	TitleLabel.Parent = Noti

	local BodyLabel = Instance.new("TextLabel")
	BodyLabel.Size = UDim2.new(1, -20, 0, 16)
	BodyLabel.Position = UDim2.new(0, 12, 0, 28)
	BodyLabel.BackgroundTransparency = 1
	BodyLabel.Text = text or ""
	BodyLabel.TextColor3 = TextSec
	BodyLabel.TextSize = 10
	BodyLabel.Font = FONT
	BodyLabel.TextXAlignment = Enum.TextXAlignment.Left
	pcall(function() BodyLabel.TextTruncation = Enum.TextTruncation.AtEnd end)
	BodyLabel.ZIndex = 201
	BodyLabel.Parent = Noti

	table.insert(Notifications, Noti)

	-- Slide in
	Noti.Position = UDim2.new(1, 10, 0, 10 + (#Notifications - 1) * 62)
	TweenService:Create(Noti, TweenMed, {
		Position = UDim2.new(1, -270, 0, 10 + (#Notifications - 1) * 62)
	}):Play()

	-- Auto dismiss
	task.delay(duration, function()
		if not Noti.Parent then return end
		TweenService:Create(Noti, TweenMed, {
			Position = UDim2.new(1, 10, Noti.Position.Y.Scale, Noti.Position.Y.Offset)
		}):Play()
		task.delay(0.25, function()
			if Noti.Parent then Noti:Destroy() end
			for i, n in ipairs(Notifications) do
				if n == Noti then table.remove(Notifications, i); break end
				end
			for i, n in ipairs(Notifications) do
				TweenService:Create(n, TweenMed, {
					Position = UDim2.new(1, -270, 0, 10 + (i - 1) * 62)
				}):Play()
				end
		end)
	end)

	-- Max 5 visible
	if #Notifications > 5 then
		local oldest = table.remove(Notifications, 1)
		if oldest and oldest.Parent then
			TweenService:Create(oldest, TweenMed, {BackgroundTransparency = 1}):Play()
			task.delay(0.2, function() if oldest.Parent then oldest:Destroy() end end)
		end
	end
end

-- ====================== CONFIG SAVE/LOAD ========================
local ConfigPath = "radium_hub_config.json"
local Config = {
	accent = "Purple",
	bgTheme = "Dark",
	glow = true,
	scale = 100,
	keybind = "RightShift",
	posSX = nil,  -- saved UDim2 position components
	posOX = nil,
	posSY = nil,
	posOY = nil,
	hbSX = nil,  -- saved heart badge position components
	hbOX = nil,
	hbSY = nil,
	hbOY = nil,
}

local function SaveConfig()
	local data
	pcall(function() data = HttpService:JSONEncode(Config) end)
	if data then
		pcall(function() writefile(ConfigPath, data) end)
	end
end

local function LoadConfig()
	local raw
	pcall(function() raw = readfile(ConfigPath) end)
	if not raw then return end
	local decoded
	pcall(function() decoded = HttpService:JSONDecode(raw) end)
	if not decoded then return end
	if decoded.accent   then Config.accent   = decoded.accent   end
	if decoded.bgTheme  then Config.bgTheme  = decoded.bgTheme  end
	if decoded.glow ~= nil then Config.glow = decoded.glow     end
	if decoded.scale    then Config.scale    = decoded.scale    end
	if decoded.keybind  then Config.keybind  = decoded.keybind  end
	if decoded.posSX then Config.posSX = decoded.posSX end
	if decoded.posOX then Config.posOX = decoded.posOX end
	if decoded.posSY then Config.posSY = decoded.posSY end
	if decoded.posOY then Config.posOY = decoded.posOY end
	if decoded.hbSX then Config.hbSX = decoded.hbSX end
	if decoded.hbOX then Config.hbOX = decoded.hbOX end
	if decoded.hbSY then Config.hbSY = decoded.hbSY end
	if decoded.hbOY then Config.hbOY = decoded.hbOY end
end

-- Use task.cancel for debouncing (no :Disconnect() on threads)
local saveThread = nil
local function DebouncedSave()
	if saveThread then
		task.cancel(saveThread)
		saveThread = nil
	end
	saveThread = task.delay(0.5, function()
		saveThread = nil
		SaveConfig()
	end)
end

LoadConfig()

-- ========================= GUI SETUP =============================
-- Remove existing instance
if PlayerGui:FindFirstChild("RadiumHub") then
	PlayerGui.RadiumHub:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RadiumHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- Dimensions
local WinW   = IsMobile and 360 or 500
local WinH   = IsMobile and 340 or 380
local SideW  = IsMobile and 105 or 125
local TopbarH = 38
local SearchH = 32
local CurrentScale = Config.scale / 100

-- Glow container
local GlowContainer = Instance.new("Frame")
GlowContainer.Name = "GlowContainer"
GlowContainer.Size = UDim2.new(0, WinW + 40, 0, WinH + 40)
GlowContainer.Position = UDim2.new(0.5, -(WinW + 40)/2, 0.5, -(WinH + 40)/2)
	GlowContainer.BackgroundTransparency = 1
GlowContainer.ZIndex = 0
GlowContainer.Parent = ScreenGui

for i = 1, 4 do
	local glow = Instance.new("Frame")
	glow.Name = "Glow" .. i
	glow.Size = UDim2.new(1, -(4-i)*10, 1, -(4-i)*10)
	glow.Position = UDim2.new(0.5, 0, 0.5, 0)
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.BackgroundColor3 = Accent
	glow.BackgroundTransparency = 0.7 + (i * 0.05)
	glow.BorderSizePixel = 0
	glow.ZIndex = i
	glow.Parent = GlowContainer
	table.insert(GlowFrames, glow)
end

-- Main Window
local Window = Instance.new("Frame")
Window.Name = "Window"
Window.Size = UDim2.new(0, WinW, 0, WinH)
Window.Position = UDim2.new(0.5, -WinW/2, 0.5, -WinH/2)
Window.BackgroundColor3 = Bg
Window.BorderSizePixel = 0
Window.ClipsDescendants = true
Window.ZIndex = 1
Window.Parent = ScreenGui
Window.BackgroundTransparency = 0
table.insert(BgElements, Window)

local WindowStroke = Instance.new("UIStroke")
WindowStroke.Color = Border
WindowStroke.Thickness = 1
WindowStroke.Parent = Window
table.insert(BorderElements, WindowStroke)

-- Accent line
local AccentLine = Instance.new("Frame")
AccentLine.Name = "AccentLine"
AccentLine.Size = UDim2.new(1, 0, 0, 2)
AccentLine.Position = UDim2.new(0, 0, 0, 0)
AccentLine.BackgroundColor3 = Accent
AccentLine.BorderSizePixel = 0
AccentLine.ZIndex = 5
AccentLine.Parent = Window
table.insert(AccentElements, AccentLine)

-- Topbar
local Topbar = Instance.new("Frame")
Topbar.Name = "Topbar"
Topbar.Size = UDim2.new(1, 0, 0, TopbarH)
Topbar.Position = UDim2.new(0, 0, 0, 2)
Topbar.BackgroundColor3 = BgSec
Topbar.BorderSizePixel = 0
Topbar.ZIndex = 2
Topbar.Parent = Window
table.insert(BgSecElements, Topbar)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Radium Hub"
Title.TextColor3 = Text
Title.TextSize = 14
Title.Font = FONT_BOLD
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 2
Title.Parent = Topbar

-- Minimize button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 24, 0, 24)
MinBtn.Position = UDim2.new(1, -62, 0.5, -12)
MinBtn.BackgroundColor3 = BgTer
MinBtn.BorderSizePixel = 0
MinBtn.Text = "−"
MinBtn.TextColor3 = TextSec
MinBtn.TextSize = 14
MinBtn.Font = FONT_BOLD
MinBtn.ZIndex = 2
MinBtn.Parent = Topbar
table.insert(BgTerElements, MinBtn)

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -32, 0.5, -12)
CloseBtn.BackgroundColor3 = BgTer
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "×"
CloseBtn.TextColor3 = TextSec
CloseBtn.TextSize = 16
CloseBtn.Font = FONT_BOLD
CloseBtn.ZIndex = 2
CloseBtn.Parent = Topbar
table.insert(BgTerElements, CloseBtn)

-- Search Bar
local SearchBar = Instance.new("Frame")
SearchBar.Name = "SearchBar"
SearchBar.Size = UDim2.new(1, -SideW - 16, 0, SearchH)
SearchBar.Position = UDim2.new(0, SideW + 8, 0, TopbarH + 8)
SearchBar.BackgroundColor3 = BgTer
SearchBar.BorderSizePixel = 0
SearchBar.ZIndex = 2
SearchBar.Parent = Window
table.insert(BgTerElements, SearchBar)

local SearchStroke = Instance.new("UIStroke")
SearchStroke.Color = Border
SearchStroke.Thickness = 1
SearchStroke.Parent = SearchBar
table.insert(BorderElements, SearchStroke)

local SearchInput = Instance.new("TextBox")
SearchInput.Size = UDim2.new(1, -16, 1, 0)
SearchInput.Position = UDim2.new(0, 8, 0, 0)
SearchInput.BackgroundTransparency = 1
SearchInput.Text = ""
SearchInput.PlaceholderText = "Search features..."
SearchInput.PlaceholderColor3 = TextMut
SearchInput.TextColor3 = Text
SearchInput.TextSize = 11
SearchInput.Font = FONT
SearchInput.TextXAlignment = Enum.TextXAlignment.Left
SearchInput.ClearTextOnFocus = false
SearchInput.ZIndex = 2
SearchInput.Parent = SearchBar

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, SideW, 1, -TopbarH - 2)
Sidebar.Position = UDim2.new(0, 0, 0, TopbarH + 2)
Sidebar.BackgroundColor3 = BgSec
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 2
Sidebar.ClipsDescendants = false
Sidebar.Parent = Window
table.insert(BgSecElements, Sidebar)

-- Tab indicator
local TabIndicator = Instance.new("Frame")
TabIndicator.Name = "TabIndicator"
TabIndicator.Size = UDim2.new(0, 3, 0, 24)
TabIndicator.Position = UDim2.new(0, 0, 0, 13)
TabIndicator.BackgroundColor3 = Accent
TabIndicator.BorderSizePixel = 0
TabIndicator.ZIndex = 10
TabIndicator.Visible = false
TabIndicator.Parent = Sidebar
table.insert(AccentElements, TabIndicator)

do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = TabIndicator
end

local TabsHolder = Instance.new("ScrollingFrame")
TabsHolder.Name = "TabsHolder"
TabsHolder.Size = UDim2.new(1, -12, 1, -48)
TabsHolder.Position = UDim2.new(0, 6, 0, 8)
TabsHolder.BackgroundTransparency = 1
TabsHolder.ZIndex = 2
TabsHolder.ScrollBarThickness = 2
TabsHolder.ScrollBarImageColor3 = Border
TabsHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
TabsHolder.AutomaticCanvasSize = Enum.AutomaticSize.Y
TabsHolder.ScrollingDirection = Enum.ScrollingDirection.Y
TabsHolder.Parent = Sidebar

local TabsLayout = Instance.new("UIListLayout")
TabsLayout.Padding = UDim.new(0, 4)
TabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabsLayout.Parent = TabsHolder

-- Status bar
local StatusBar = Instance.new("Frame")
StatusBar.Size = UDim2.new(1, -12, 0, 26)
StatusBar.Position = UDim2.new(0, 6, 1, -34)
StatusBar.BackgroundColor3 = BgTer
StatusBar.BorderSizePixel = 0
StatusBar.ZIndex = 2
StatusBar.Parent = Sidebar
table.insert(BgTerElements, StatusBar)

local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.new(0, 6, 0, 6)
StatusDot.Position = UDim2.new(0, 8, 0.5, -3)
StatusDot.BackgroundColor3 = Success
StatusDot.BorderSizePixel = 0
StatusDot.ZIndex = 2
StatusDot.Parent = StatusBar

do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = StatusDot
end

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, -20, 1, 0)
StatusText.Position = UDim2.new(0, 18, 0, 0)
StatusText.BackgroundTransparency = 1
StatusText.Text = "Undetected"
StatusText.TextColor3 = TextSec
StatusText.TextSize = 10
StatusText.Font = FONT
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.ZIndex = 2
StatusText.Parent = StatusBar

-- Status dot animation (heartbeat-driven, no polling)
do
	local dotTick = 0
	local dotPhase = false
	RunService.Heartbeat:Connect(function(dt)
		dotTick = dotTick + dt
		if dotTick >= 1 then
			dotTick = dotTick - 1
			dotPhase = not dotPhase
			if StatusDot and StatusDot.Parent then
				TweenService:Create(StatusDot, TweenInfo.new(1, Enum.EasingStyle.Sine), {
					BackgroundTransparency = dotPhase and 0.5 or 0
				}):Play()
				end
		end
	end)
end

-- Content panel
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -SideW, 1, -TopbarH - SearchH - 16)
Content.Position = UDim2.new(0, SideW, 0, TopbarH + SearchH + 14)
Content.BackgroundColor3 = Bg
Content.BorderSizePixel = 0
Content.ClipsDescendants = true
Content.ZIndex = 2
Content.Parent = Window
table.insert(BgElements, Content)

-- Dropdown holder (sits above everything in ScreenGui)
local DropdownHolder = Instance.new("Frame")
DropdownHolder.Name = "DropdownHolder"
DropdownHolder.Size = UDim2.new(1, 0, 1, 0)
DropdownHolder.BackgroundTransparency = 1
DropdownHolder.ZIndex = 100
DropdownHolder.Parent = ScreenGui

-- ========================== TAB SYSTEM ===========================
local Pages = {}
local ActiveTab = nil
local TabIndex = 0
local scrollDebounce = {}

local function SetGlowEnabled(enabled)
	GlowEnabled = enabled
	GlowContainer.Visible = enabled
end

local function SetAccent(color)
	Accent = color
	for _, el in ipairs(AccentElements) do
		if el and el.Parent then el.BackgroundColor3 = color end
	end
	for _, glow in ipairs(GlowFrames) do
		if glow and glow.Parent then glow.BackgroundColor3 = color end
	end
	if ActiveTab and Pages[ActiveTab] then
		Pages[ActiveTab].Icon.TextColor3 = color
		Pages[ActiveTab].Btn.BackgroundColor3 = color
	end
	for _, data in ipairs(ToggleBgBtns) do
		if data.btn and data.btn.Parent and data.isOn() then
			data.btn.BackgroundColor3 = color
		end
	end
	if HeartBadge and HeartBadge.Parent then
		HeartBadge.TextColor3 = color
		if HeartStroke and HeartStroke.Parent then HeartStroke.Color = color end
	end
	nudgeRender()
end

local function SetBgTheme(themeName)
	local theme = BgThemes[themeName]
	if not theme then return end
	CurrentBgTheme = themeName
	Bg    = theme.Bg
	BgSec = theme.BgSec
	BgTer = theme.BgTer
	BgElev = theme.BgElev
	Border = theme.Border
	for _, el in ipairs(BgElements)     do if el and el.Parent then el.BackgroundColor3 = Bg    end end
	for _, el in ipairs(BgSecElements)  do if el and el.Parent then el.BackgroundColor3 = BgSec end end
	for _, el in ipairs(BgTerElements)  do if el and el.Parent then el.BackgroundColor3 = BgTer end end
	for _, el in ipairs(BgElevElements) do if el and el.Parent then el.BackgroundColor3 = BgElev end end
	for _, el in ipairs(BorderElements) do if el and el.Parent then el.Color = Border end end
	for _, el in ipairs(ComponentBgs)   do if el and el.Parent then el.BackgroundColor3 = BgTer end end
	for _, el in ipairs(DropdownOptionBtns) do if el and el.Parent then el.BackgroundColor3 = BgElev end end
	for _, data in ipairs(ToggleBgBtns) do
		if data.btn and data.btn.Parent then
			data.btn.BackgroundColor3 = data.isOn() and Accent or BgElev
		end
	end
	nudgeRender()
end

local function getTabVisualIndex(order)
	local count = 0
	for _, data in pairs(Pages) do
		if data.LayoutOrder < order then count = count + 1 end
	end
	return count
end

local function CreateTab(name, icon, order)
	TabIndex = TabIndex + 1
	local myIndex = TabIndex
	local myOrder = order or TabIndex
	if order then
		-- shift existing tabs to make room (insertion semantics)
		for _, data in pairs(Pages) do
			if data.LayoutOrder >= order then
				data.LayoutOrder = data.LayoutOrder + 1
				data.Btn.LayoutOrder = data.Btn.LayoutOrder + 1
			end
		end
	end

	local Btn = Instance.new("TextButton")
	Btn.Name = name
	Btn.Size = UDim2.new(1, 0, 0, 34)
	Btn.BackgroundColor3 = Accent
	Btn.BackgroundTransparency = 1
	Btn.BorderSizePixel = 0
	Btn.Text = ""
	Btn.AutoButtonColor = false
	Btn.LayoutOrder = myOrder
	Btn.ZIndex = 3
	Btn.Parent = TabsHolder

	local IconLabel = Instance.new("TextLabel")
	IconLabel.Name = "Icon"
	IconLabel.Size = UDim2.new(0, 20, 1, 0)
	IconLabel.Position = UDim2.new(0, 8, 0, 0)
	IconLabel.BackgroundTransparency = 1
	IconLabel.Text = icon
	IconLabel.TextColor3 = TextSec
	IconLabel.TextSize = 12
	IconLabel.Font = FONT_BOLD
	IconLabel.ZIndex = 3
	IconLabel.Parent = Btn

	local Label = Instance.new("TextLabel")
	Label.Name = "Label"
	Label.Size = UDim2.new(1, -32, 1, 0)
	Label.Position = UDim2.new(0, 28, 0, 0)
	Label.BackgroundTransparency = 1
	Label.Text = name
	Label.TextColor3 = TextSec
	Label.TextSize = 11
	Label.Font = FONT_BOLD
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.ZIndex = 3
	Label.Parent = Btn

	local Page = Instance.new("ScrollingFrame")
	Page.Name = name
	Page.Size = UDim2.new(1, -12, 1, -8)
	Page.Position = UDim2.new(0, 6, 0, 4)
	Page.BackgroundTransparency = 1
	Page.BorderSizePixel = 0
	Page.ScrollBarThickness = 3
	Page.ScrollBarImageColor3 = Border
	Page.CanvasSize = UDim2.new(0, 0, 0, 0)
	Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Page.Visible = false
	Page.ZIndex = 2
	Page.Parent = Content

	-- Debounced scroll-close
	Page:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		local now = os.clock()
		if not scrollDebounce[Page] or now - scrollDebounce[Page] > 0.15 then
			scrollDebounce[Page] = now
			CloseAllDropdowns()
		end
	end)

	local Layout = Instance.new("UIListLayout")
	Layout.Padding = UDim.new(0, 5)
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Parent = Page

	local Pad = Instance.new("UIPadding")
	Pad.PaddingBottom = UDim.new(0, 8)
	Pad.Parent = Page

	local function Select()
		if ActiveTab == name then return end
		if ActiveTab and Pages[ActiveTab] then
			local prev = Pages[ActiveTab]
			prev.Page.Visible = false
				prev.Page.ScrollingEnabled = false
			Tween(prev.Btn, {BackgroundTransparency = 1}, TweenSmooth)
			Tween(prev.Icon, {TextColor3 = TextSec}, TweenSmooth)
			Tween(prev.Label, {TextColor3 = TextSec}, TweenSmooth)
		end
		ActiveTab = name
		Page.CanvasPosition = Vector2.new(0, 0) -- scroll to top
			Page.Position = UDim2.new(0, 14, 0, 4)
		Page.Visible = true
			Page.ScrollingEnabled = true
			Tween(Page, {Position = UDim2.new(0, 6, 0, 4)}, TweenSmooth)
		Btn.BackgroundColor3 = Accent
		Tween(Btn, {BackgroundTransparency = 0.85}, TweenSmooth)
		Tween(IconLabel, {TextColor3 = Accent}, TweenSmooth)
		Tween(Label, {TextColor3 = Text}, TweenSmooth)
		TabIndicator.Visible = true
		local scrollOffset = TabsHolder.CanvasPosition.Y; local indicatorY = 8 + getTabVisualIndex(Btn.LayoutOrder) * 38 + 5 - scrollOffset
		Tween(TabIndicator, {Position = UDim2.new(0, 0, 0, indicatorY)}, TweenSmooth)
		SearchInput.Text = ""
		for _, item in ipairs(SearchableItems) do
			if item.frame and item.frame.Parent then item.frame.Visible = true end
		end
	end

	Pages[name] = {
		Btn = Btn, Page = Page, Icon = IconLabel,
		Label = Label, Index = myIndex, LayoutOrder = myOrder,
		Select = Select  -- exposed so safe init can call directly
	}

	Btn.MouseButton1Click:Connect(Select)
	Btn.TouchTap:Connect(Select)
	Btn.MouseEnter:Connect(function()
		if ActiveTab ~= name then
				Btn.BackgroundColor3 = Accent
			Tween(Btn, {BackgroundTransparency = 0.9}, TweenFast)
			Tween(IconLabel, {TextColor3 = Text}, TweenFast)
		end
	end)
	Btn.MouseLeave:Connect(function()
		if ActiveTab ~= name then
			Tween(Btn, {BackgroundTransparency = 1}, TweenFast)
			Tween(IconLabel, {TextColor3 = TextSec}, TweenFast)
		end
	end)
	-- Keep indicator aligned when scrolling
	TabsHolder:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		if ActiveTab == name and TabIndicator.Visible then
			local scrollOffset = TabsHolder.CanvasPosition.Y
			local indicatorY = 8 + getTabVisualIndex(Btn.LayoutOrder) * 38 + 5 - scrollOffset
			TabIndicator.Position = UDim2.new(0, 0, 0, indicatorY)
		end
	end)
	return Page
end

-- ========================== SEARCH ===============================
local function DoSearch(query)
	query = string.lower(query)
	local activePage = ActiveTab and Pages[ActiveTab] and Pages[ActiveTab].Page
	for _, item in ipairs(SearchableItems) do
		if item.frame and item.frame.Parent then
			if activePage and not item.frame:IsDescendantOf(activePage) then
				item.frame.Visible = false
			elseif query == "" then
				item.frame.Visible = true
			else
				local match = string.find(string.lower(item.name), query)
					or (item.keywords and string.find(string.lower(item.keywords), query))
				item.frame.Visible = match ~= nil
				end
		end
	end
end

SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
	DoSearch(SearchInput.Text)
end)

-- ======================== COMPONENTS =============================

	local function Section(parent, text)
		local children = {}
		local heightCache = {}
		local collapsed = false

		local Header = Instance.new("TextButton")
		Header.Size = UDim2.new(1, 0, 0, 20)
		Header.BackgroundTransparency = 1
		Header.Text = "▼ " .. text
		Header.TextColor3 = TextMut
		Header.TextSize = 9
		Header.Font = FONT_BOLD
		Header.TextXAlignment = Enum.TextXAlignment.Left
		Header.AutoButtonColor = false
		Header.ZIndex = 2
		Header.Parent = parent

		Header.MouseButton1Click:Connect(function()
			collapsed = not collapsed
			Header.Text = (collapsed and "▶ " or "▼ ") .. text
			for _, child in ipairs(children) do
				if child then
					child.Visible = not collapsed
					if collapsed then
						child.Size = UDim2.new(1, 0, 0, 0)
					else
						child.Size = UDim2.new(1, 0, 0, heightCache[child] or 34)
					end
				end
			end
		end)

		local sec = {}
		sec.Add = function(frame)
			heightCache[frame] = frame.Size.Y.Offset
			table.insert(children, frame)
		end
		sec.IsCollapsed = function()
			return collapsed
		end
		return sec
	end
local function Button(parent, text, callback, keywords)
	local B = Instance.new("TextButton")
	B.Size = UDim2.new(1, 0, 0, 34)
	B.BackgroundColor3 = BgTer
	B.BorderSizePixel = 0
	B.Text = text
	B.TextColor3 = Text
	B.TextSize = 11
	B.Font = FONT_BOLD
	B.AutoButtonColor = false
	B.ClipsDescendants = true
	B.ZIndex = 2
	B.Parent = parent
	table.insert(ComponentBgs, B)
	table.insert(SearchableItems, {frame = B, name = text, keywords = keywords})

	local S = Instance.new("UIStroke")
	S.Color = Border
	S.Thickness = 1
	S.Transparency = 0.5
	S.Parent = B
	table.insert(BorderElements, S)

	B.MouseButton1Click:Connect(function()
		local mousePos = UserInputService:GetMouseLocation()
		Ripple(B, mousePos.X, mousePos.Y)
		if callback then callback() end
	end)
	B.TouchTap:Connect(function(t)
		if t[1] then Ripple(B, t[1].X, t[1].Y) end
		if callback then callback() end
	end)
	B.MouseEnter:Connect(function() Tween(B, {BackgroundColor3 = BgElev}) end)
	B.MouseLeave:Connect(function() Tween(B, {BackgroundColor3 = BgTer}) end)
	return B
end

local function Toggle(parent, text, default, callback, keywords)
	local toggled = default or false
	local F = Instance.new("Frame")
	F.Size = UDim2.new(1, 0, 0, 34)
	F.BackgroundColor3 = BgTer
	F.BorderSizePixel = 0
	F.ZIndex = 2
	F.Parent = parent
	table.insert(ComponentBgs, F)
	table.insert(SearchableItems, {frame = F, name = text, keywords = keywords})

	local S = Instance.new("UIStroke")
	S.Color = Border
	S.Thickness = 1
	S.Transparency = 0.5
	S.Parent = F
	table.insert(BorderElements, S)

	local L = Instance.new("TextLabel")
	L.Size = UDim2.new(1, -50, 1, 0)
	L.Position = UDim2.new(0, 10, 0, 0)
	L.BackgroundTransparency = 1
	L.Text = text
	L.TextColor3 = Text
	L.TextSize = 11
	L.Font = FONT_BOLD
	L.TextXAlignment = Enum.TextXAlignment.Left
	L.ZIndex = 2
	L.Parent = F

	local TB = Instance.new("TextButton")
	TB.Size = UDim2.new(0, 36, 0, 18)
	TB.Position = UDim2.new(1, -44, 0.5, -9)
	TB.BackgroundColor3 = toggled and Accent or BgElev
	TB.BorderSizePixel = 0
	TB.Text = ""
	TB.ZIndex = 2
	TB.AutoButtonColor = false
	TB.Parent = F
	table.insert(ToggleBgBtns, {btn = TB, isOn = function() return toggled end}) -- track for theme changes

	local TBC = Instance.new("UICorner")
	TBC.CornerRadius = UDim.new(1, 0)
	TBC.Parent = TB

	local K = Instance.new("Frame")
	K.Size = UDim2.new(0, 14, 0, 14)
	K.Position = toggled and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
	K.BackgroundColor3 = Color3.new(1, 1, 1)
	K.BorderSizePixel = 0
	K.ZIndex = 3
	K.Parent = TB

	local KC = Instance.new("UICorner")
	KC.CornerRadius = UDim.new(1, 0)
	KC.Parent = K

	local function DoToggle()
		toggled = not toggled
		TB.BackgroundColor3 = toggled and Accent or BgElev
		TweenService:Create(K, TweenSmooth, {
			Position = toggled and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
		}):Play()
		if callback then callback(toggled) end
	end

	TB.MouseButton1Click:Connect(DoToggle)
	TB.TouchTap:Connect(DoToggle)
	return F, function() return toggled end
end

local function Slider(parent, text, min, max, default, callback, keywords)
	local val = (default ~= nil) and default or min
	local F = Instance.new("Frame")
	F.Size = UDim2.new(1, 0, 0, 46)
	F.BackgroundColor3 = BgTer
	F.BorderSizePixel = 0
	F.ZIndex = 2
	F.Parent = parent
	table.insert(ComponentBgs, F)
	table.insert(SearchableItems, {frame = F, name = text, keywords = keywords})

	local S = Instance.new("UIStroke")
	S.Color = Border
	S.Thickness = 1
	S.Transparency = 0.5
	S.Parent = F
	table.insert(BorderElements, S)

	local L = Instance.new("TextLabel")
	L.Size = UDim2.new(0.65, 0, 0, 18)
	L.Position = UDim2.new(0, 10, 0, 4)
	L.BackgroundTransparency = 1
	L.Text = text
	L.TextColor3 = Text
	L.TextSize = 11
	L.Font = FONT_BOLD
	L.TextXAlignment = Enum.TextXAlignment.Left
	L.ZIndex = 2
	L.Parent = F

	local V = Instance.new("TextLabel")
	V.Size = UDim2.new(0.35, -10, 0, 18)
	V.Position = UDim2.new(0.65, 0, 0, 4)
	V.BackgroundTransparency = 1
	V.Text = tostring(val)
	V.TextColor3 = TextSec
	V.TextSize = 11
	V.Font = FONT_BOLD
	V.TextXAlignment = Enum.TextXAlignment.Right
	V.ZIndex = 2
	V.Parent = F

	local T = Instance.new("Frame")
	T.Size = UDim2.new(1, -20, 0, 5)
	T.Position = UDim2.new(0, 10, 0, 30)
	T.BackgroundColor3 = BgElev
	T.BorderSizePixel = 0
	T.ZIndex = 2
	T.Parent = F
	table.insert(BgElevElements, T)

	local TC = Instance.new("UICorner")
	TC.CornerRadius = UDim.new(1, 0)
	TC.Parent = T

	local pct = (val - min) / (max - min)
	local Fill = Instance.new("Frame")
	Fill.Size = UDim2.new(pct, 0, 1, 0)
	Fill.BackgroundColor3 = Accent
	Fill.BorderSizePixel = 0
	Fill.ZIndex = 2
	Fill.Parent = T
	table.insert(AccentElements, Fill)

	local FC = Instance.new("UICorner")
	FC.CornerRadius = UDim.new(1, 0)
	FC.Parent = Fill

	local Thumb = Instance.new("Frame")
	Thumb.Size = UDim2.new(0, 12, 0, 12)
	Thumb.Position = UDim2.new(pct, -6, 0.5, -6)
	Thumb.BackgroundColor3 = Color3.new(1, 1, 1)
	Thumb.BorderSizePixel = 0
	Thumb.ZIndex = 3
	Thumb.Parent = T

	local ThumbC = Instance.new("UICorner")
	ThumbC.CornerRadius = UDim.new(1, 0)
	ThumbC.Parent = Thumb

		local dragging = false
		local pendingX = 0
		local needsUpdate = false
		local function Update(x)
			pendingX = x
			needsUpdate = true
		end

		local function applyUpdate(x)
			local pos = T.AbsolutePosition.X
			local size = T.AbsoluteSize.X
			local p = math.clamp((x - pos) / size, 0, 1)
			val = math.floor(min + (p * (max - min)))
			V.Text = tostring(val)
			Fill.Size = UDim2.new(p, 0, 1, 0)
			Thumb.Position = UDim2.new(p, -6, 0.5, -6)
			if callback then callback(val) end
		end
	local SB = Instance.new("TextButton")
	SB.Size = UDim2.new(1, 0, 1, 10)
	SB.Position = UDim2.new(0, 0, 0, -5)
	SB.BackgroundTransparency = 1
	SB.Text = ""
	SB.ZIndex = 4
	SB.Parent = T

	SB.MouseButton1Down:Connect(function()
		dragging = true
		Update(UserInputService:GetMouseLocation().X)
	end)
	SB.TouchTap:Connect(function(t) if t[1] then Update(t[1].X) end end)
	SB.TouchPan:Connect(function(t) if t[1] then Update(t[1].X) end end)

	local sliderInputChanged = UserInputService.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			Update(i.Position.X)
		end
	end)
	local sliderInputEnded = UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)

		local sliderRenderStepped = RunService.RenderStepped:Connect(function()
			if needsUpdate then
				needsUpdate = false
				applyUpdate(pendingX)
				end
		end)
	-- Cleanup when slider is destroyed
	F.AncestryChanged:Connect(function()
		if not F.Parent then
			if sliderInputChanged then sliderInputChanged:Disconnect(); sliderInputChanged = nil end
			if sliderInputEnded then sliderInputEnded:Disconnect(); sliderInputEnded = nil end
				if sliderRenderStepped then sliderRenderStepped:Disconnect(); sliderRenderStepped = nil end
			for i, el in ipairs(ComponentBgs) do
				if el == F then table.remove(ComponentBgs, i); break end
				end
			for i, el in ipairs(SearchableItems) do
				if el.frame == F then table.remove(SearchableItems, i); break end
				end
		end
	end)
	return F, function() return val end
end

local function Dropdown(parent, text, options, default, callback, keywords)
	local selected = (default ~= nil) and default or options[1]
	local open = false
	local optionButtons = {}

	local F = Instance.new("Frame")
	F.Size = UDim2.new(1, 0, 0, 34)
	F.BackgroundColor3 = BgTer
	F.BorderSizePixel = 0
	F.ClipsDescendants = false
	F.ZIndex = 2
	F.Parent = parent
	table.insert(ComponentBgs, F)
	table.insert(SearchableItems, {frame = F, name = text, keywords = keywords})

	local S = Instance.new("UIStroke")
	S.Color = Border
	S.Thickness = 1
	S.Transparency = 0.5
	S.Parent = F
	table.insert(BorderElements, S)

	local MB = Instance.new("TextButton")
	MB.Size = UDim2.new(1, 0, 1, 0)
	MB.BackgroundTransparency = 1
	MB.Text = ""
	MB.ZIndex = 2
	MB.Parent = F

	local L = Instance.new("TextLabel")
	L.Size = UDim2.new(0.45, 0, 1, 0)
	L.Position = UDim2.new(0, 10, 0, 0)
	L.BackgroundTransparency = 1
	L.Text = text
	L.TextColor3 = Text
	L.TextSize = 11
	L.Font = FONT_BOLD
	L.TextXAlignment = Enum.TextXAlignment.Left
	L.ZIndex = 2
	L.Parent = MB

	local VL = Instance.new("TextLabel")
	VL.Name = "Val"
	VL.Size = UDim2.new(0.55, -28, 1, 0)
	VL.Position = UDim2.new(0.45, 0, 0, 0)
	VL.BackgroundTransparency = 1
	VL.Text = selected
	VL.TextColor3 = TextSec
	VL.TextSize = 10
	VL.Font = FONT
	VL.TextXAlignment = Enum.TextXAlignment.Right
	VL.ZIndex = 2
	VL.Parent = MB

	local Arr = Instance.new("TextLabel")
	Arr.Size = UDim2.new(0, 18, 1, 0)
	Arr.Position = UDim2.new(1, -22, 0, 0)
	Arr.BackgroundTransparency = 1
	Arr.Text = "v"
	Arr.TextColor3 = TextMut
	Arr.TextSize = 10
	Arr.Font = FONT_BOLD
	Arr.ZIndex = 2
	Arr.Parent = MB

	local DL = Instance.new("Frame")
	DL.Name = "DropdownList"
	DL.Size = UDim2.new(0, 0, 0, 0)
	DL.BackgroundColor3 = BgElev
	DL.BorderSizePixel = 0
	DL.Visible = false
	DL.ZIndex = 101
	DL.ClipsDescendants = true
	DL.Parent = DropdownHolder
	table.insert(BgElevElements, DL)

	local DLS = Instance.new("UIStroke")
	DLS.Color = Border
	DLS.Thickness = 1
	DLS.Parent = DL
	table.insert(BorderElements, DLS)

	local SearchBox = Instance.new("Frame")
	SearchBox.Size = UDim2.new(1, 0, 0, 28)
	SearchBox.Position = UDim2.new(0, 0, 0, 0)
	SearchBox.BackgroundColor3 = BgTer
	SearchBox.BorderSizePixel = 0
	SearchBox.ZIndex = 102
	SearchBox.Parent = DL
	table.insert(BgTerElements, SearchBox)

	local SearchBoxInput = Instance.new("TextBox")
	SearchBoxInput.Size = UDim2.new(1, -16, 1, 0)
	SearchBoxInput.Position = UDim2.new(0, 8, 0, 0)
	SearchBoxInput.BackgroundTransparency = 1
	SearchBoxInput.Text = ""
	SearchBoxInput.PlaceholderText = "Search..."
	SearchBoxInput.PlaceholderColor3 = TextMut
	SearchBoxInput.TextColor3 = Text
	SearchBoxInput.TextSize = 10
	SearchBoxInput.Font = FONT
	SearchBoxInput.TextXAlignment = Enum.TextXAlignment.Left
	SearchBoxInput.ClearTextOnFocus = false
	SearchBoxInput.ZIndex = 102
	SearchBoxInput.Parent = SearchBox

	local OptionsScroll = Instance.new("ScrollingFrame")
	OptionsScroll.Size = UDim2.new(1, 0, 1, -28)
	OptionsScroll.Position = UDim2.new(0, 0, 0, 28)
	OptionsScroll.BackgroundTransparency = 1
	OptionsScroll.BorderSizePixel = 0
	OptionsScroll.ScrollBarThickness = 4
	OptionsScroll.ScrollBarImageColor3 = TextMut
	OptionsScroll.ScrollBarImageTransparency = 0.5
	OptionsScroll.CanvasSize = UDim2.new(0, 0, 0, #options * 28)
	OptionsScroll.ZIndex = 102
	OptionsScroll.Parent = DL

	local DLL = Instance.new("UIListLayout")
	DLL.SortOrder = Enum.SortOrder.LayoutOrder
	DLL.Parent = OptionsScroll

	local function CloseDrop()
		if not open then return end
		open = false
		if DL and DL.Parent then DL.Visible = false end
		if Arr and Arr.Parent then Arr.Rotation = 0 end
		if SearchBoxInput and SearchBoxInput.Parent then SearchBoxInput.Text = "" end
		for _, data in ipairs(optionButtons) do
			if data.btn and data.btn.Parent then data.btn.Visible = true end
		end
		if OptionsScroll and OptionsScroll.Parent then
			OptionsScroll.CanvasSize = UDim2.new(0, 0, 0, #options * 28)
		end
	end

	table.insert(OpenDropdowns, CloseDrop)

	-- Cleanup when dropdown container is destroyed
	F.AncestryChanged:Connect(function()
		if not F.Parent then
			for i, f in ipairs(OpenDropdowns) do
				if f == CloseDrop then table.remove(OpenDropdowns, i); break end
				end
			for _, data in ipairs(optionButtons) do
				for i, btn in ipairs(DropdownOptionBtns) do
					if btn == data.btn then table.remove(DropdownOptionBtns, i); break end
				end
				end
			for i, el in ipairs(ComponentBgs) do
				if el == F then table.remove(ComponentBgs, i); break end
				end
			for i, el in ipairs(SearchableItems) do
				if el.frame == F then table.remove(SearchableItems, i); break end
				end
			if dropInputConn then dropInputConn:Disconnect(); dropInputConn = nil end
		end
	end)

	local function FilterOptions(query)
		query = string.lower(query)
		local visibleCount = 0
		for _, data in ipairs(optionButtons) do
			local match = query == "" or string.find(string.lower(data.opt), query)
			if data.btn and data.btn.Parent then
				data.btn.Visible = match ~= nil
				end
			if match then visibleCount = visibleCount + 1 end
		end
		OptionsScroll.CanvasSize = UDim2.new(0, 0, 0, visibleCount * 28)
	end

	SearchBoxInput:GetPropertyChangedSignal("Text"):Connect(function()
		FilterOptions(SearchBoxInput.Text)
	end)

	for i, opt in ipairs(options) do
		local OB = Instance.new("TextButton")
		OB.Size = UDim2.new(1, -4, 0, 28)
		OB.BackgroundColor3 = BgElev
		OB.BorderSizePixel = 0
		OB.Text = opt
		OB.TextColor3 = opt == selected and Accent or Text
		OB.TextSize = 10
		OB.Font = FONT
		OB.ZIndex = 103
		OB.LayoutOrder = i
		OB.Parent = OptionsScroll

			table.insert(optionButtons, {btn = OB, opt = opt})
			table.insert(DropdownOptionBtns, OB)

		local function Sel()
			selected = opt
			VL.Text = opt
			for _, data in ipairs(optionButtons) do
				if data.btn and data.btn.Parent then
					data.btn.TextColor3 = data.opt == opt and Accent or Text
				end
				end
			CloseDrop()
			if callback then callback(opt) end
		end

		OB.MouseButton1Click:Connect(Sel)
		OB.TouchTap:Connect(Sel)
		OB.MouseEnter:Connect(function() Tween(OB, {BackgroundColor3 = BgTer}) end)
		OB.MouseLeave:Connect(function() Tween(OB, {BackgroundColor3 = BgElev}) end)
	end

	-- Expose a method to programmatically update the selected value
	local function SetSelected(newOpt)
		selected = newOpt
		VL.Text = newOpt
		for _, data in ipairs(optionButtons) do
			if data.btn and data.btn.Parent then
				data.btn.TextColor3 = data.opt == newOpt and Accent or Text
				end
		end
	end

	local function ToggleDrop()
		if open then
			CloseDrop()
			return
		end
		-- Close other open dropdowns
		for _, closeFunc in ipairs(OpenDropdowns) do
			if closeFunc ~= CloseDrop then pcall(closeFunc) end
		end
		open = true

		local absPos = F.AbsolutePosition
		local absSize = F.AbsoluteSize
		local listH = #options * 28 + 28
		local maxH = math.min(listH, 196)
		local screenH = ScreenGui.AbsoluteSize.Y

		-- Flip above if near bottom edge
		local belowSpace = screenH - (absPos.Y + absSize.Y + 3)
		if belowSpace < maxH then
			DL.Position = UDim2.new(0, absPos.X, 0, absPos.Y - maxH - 3)
		else
			DL.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 3)
		end
		DL.Size = UDim2.new(0, absSize.X, 0, maxH)
		OptionsScroll.CanvasSize = UDim2.new(0, 0, 0, #options * 28)
		DL.Visible = true
		Arr.Rotation = 180

		-- Refresh option highlight colors with current accent
		for _, data in ipairs(optionButtons) do
			if data.btn and data.btn.Parent then
				data.btn.TextColor3 = data.opt == selected and Accent or Text
				end
		end

		task.defer(function()
			pcall(function() SearchBoxInput:CaptureFocus() end)
		end)
	end

	MB.MouseButton1Click:Connect(ToggleDrop)
	MB.TouchTap:Connect(ToggleDrop)

	local dropInputConn = UserInputService.InputBegan:Connect(function(input)
		if open and (input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch) then
			task.defer(function()
				if not DL or not DL.Parent then return end
				local pos = input.Position
				local dlPos = DL.AbsolutePosition
				local dlSize = DL.AbsoluteSize
				local fPos = F.AbsolutePosition
				local fSize = F.AbsoluteSize
				local inDL = pos.X >= dlPos.X and pos.X <= dlPos.X + dlSize.X
					and pos.Y >= dlPos.Y and pos.Y <= dlPos.Y + dlSize.Y
				local inF = pos.X >= fPos.X and pos.X <= fPos.X + fSize.X
					and pos.Y >= fPos.Y and pos.Y <= fPos.Y + fSize.Y
				if not inDL and not inF then CloseDrop() end
				end)
		end
	end)

	return F, SetSelected, function() return selected end
end

-- =================== KEYBIND PICKER COMPONENT ====================
local function KeybindPicker(parent, text, default, callback, keywords)
	local current = default or Enum.KeyCode.RightShift
	local listening = false

	local F = Instance.new("Frame")
	F.Size = UDim2.new(1, 0, 0, 34)
	F.BackgroundColor3 = BgTer
	F.BorderSizePixel = 0
	F.ZIndex = 2
	F.Parent = parent
	table.insert(ComponentBgs, F)
	table.insert(SearchableItems, {frame = F, name = text, keywords = keywords})

	local S = Instance.new("UIStroke")
	S.Color = Border
	S.Thickness = 1
	S.Transparency = 0.5
	S.Parent = F
	table.insert(BorderElements, S)

	local L = Instance.new("TextLabel")
	L.Size = UDim2.new(0.5, -10, 1, 0)
	L.Position = UDim2.new(0, 10, 0, 0)
	L.BackgroundTransparency = 1
	L.Text = text
	L.TextColor3 = Text
	L.TextSize = 11
	L.Font = FONT_BOLD
	L.TextXAlignment = Enum.TextXAlignment.Left
	L.ZIndex = 2
	L.Parent = F

	local KB = Instance.new("TextButton")
	KB.Size = UDim2.new(0, 100, 0, 22)
	KB.Position = UDim2.new(1, -108, 0.5, -11)
	KB.BackgroundColor3 = BgElev
	KB.BorderSizePixel = 0
	KB.Text = current.Name
	KB.TextColor3 = Text
	KB.TextSize = 10
	KB.Font = FONT_BOLD
	KB.ZIndex = 2
	KB.Parent = F

	local KBC = Instance.new("UICorner")
	KBC.CornerRadius = UDim.new(0, 4)
	KBC.Parent = KB

	KB.MouseButton1Click:Connect(function()
		if listening then return end
		listening = true
		KB.Text = "..."
		KB.BackgroundColor3 = Accent

		local conn
		conn = UserInputService.InputBegan:Connect(function(i, p)
			if p then return end
			if i.UserInputType == Enum.UserInputType.Keyboard then
				current = i.KeyCode
				KB.Text = current.Name
				KB.BackgroundColor3 = BgElev
				listening = false
				if conn then conn:Disconnect() end
				if callback then callback(current) end
				end
		end)
		task.delay(5, function()
			if listening then
				listening = false
				KB.Text = current.Name
				KB.BackgroundColor3 = BgElev
				if conn then conn:Disconnect() end
				end
		end)
	end)
	KB.MouseEnter:Connect(function()
		if not listening then Tween(KB, {BackgroundColor3 = BgTer}) end
	end)
	KB.MouseLeave:Connect(function()
		if not listening then Tween(KB, {BackgroundColor3 = BgElev}) end
	end)

	return F, function() return current end
end

local function Label(parent, text, sec)
	local L = Instance.new("TextLabel")
	L.Size = UDim2.new(1, 0, 0, 18)
	L.BackgroundTransparency = 1
	L.Text = text
	L.TextColor3 = sec and TextSec or Text
	L.TextSize = 10
	L.Font = FONT
	L.TextXAlignment = Enum.TextXAlignment.Left
	L.ZIndex = 2
	L.Parent = parent
	return L
end

local function Spacer(parent, h)
	local S = Instance.new("Frame")
	S.Size = UDim2.new(1, 0, 0, h or 5)
	S.BackgroundTransparency = 1
	S.Parent = parent
end

-- ====================== CREATE TABS ==============================
local MainPage     = CreateTab("Main",     "▶")
local SettingsPage = CreateTab("Settings", "⚙")
local InfoPage     = CreateTab("Info",     "ℹ")

-- ==================== SAFE TAB AUTO-SELECT =======================
task.spawn(function()
	local attempts = 0
	while not Pages["Main"] and attempts < 20 do
		task.wait(0.1)
		attempts = attempts + 1
	end
	if Pages["Main"] and not ActiveTab then
		Pages["Main"].Select()
	end
end)

-- ========================= MAIN PAGE =============================
-- Empty template — wire your own features here
Section(MainPage, "WELCOME")
Label(MainPage, "Radium Hub v" .. HUB_VERSION, false)
Spacer(MainPage, 4)
Label(MainPage, "Use the Settings tab to customize the UI.", true)
Label(MainPage, "Wire your scripts into the components below.", true)

-- ======================= SETTINGS PAGE ===========================
	local secTheme = Section(SettingsPage, "THEME")
-- Store setSelected callbacks so config init can sync them
local accentSetSelected = nil
local bgThemeSetSelected = nil

local accentFrame, accentSetSelectedFn = Dropdown(SettingsPage, "Accent Color", AccentOrder, Config.accent, function(name)
	if AccentColors[name] then
		SetAccent(AccentColors[name])
		Config.accent = name
		DebouncedSave()
	end
end, "color accent theme")
accentSetSelected = accentSetSelectedFn
	secTheme.Add(accentFrame)

local bgFrame, bgThemeSetSelectedFn = Dropdown(SettingsPage, "Background", BgThemeOrder, Config.bgTheme, function(name)
	SetBgTheme(name)
	Config.bgTheme = name
	DebouncedSave()
end, "background theme dark")
bgThemeSetSelected = bgThemeSetSelectedFn
	secTheme.Add(bgFrame)

Spacer(SettingsPage, 8)
local secEffects = Section(SettingsPage, "EFFECTS")
local glowFrame, _ = Toggle(SettingsPage, "Window Glow", Config.glow, function(enabled)
	SetGlowEnabled(enabled)
	Config.glow = enabled
	DebouncedSave()
end, "glow effect light")
	secEffects.Add(glowFrame)

local transFrame, _ = Toggle(SettingsPage, "Transparency", false, function(enabled)
	TransparencyMode = enabled
	if enabled then
		Window.BackgroundTransparency = 0.1
		Topbar.BackgroundTransparency = 0.2
		Sidebar.BackgroundTransparency = 0.2
		StatusBar.BackgroundTransparency = 0.2
		Content.BackgroundTransparency = 0.4
		SearchBar.BackgroundTransparency = 0.4
		for _, bg in ipairs(ComponentBgs) do
			if bg and bg.Parent then bg.BackgroundTransparency = 0.4 end
		end
	else
		Window.BackgroundTransparency = 0
		Topbar.BackgroundTransparency = 0
		Sidebar.BackgroundTransparency = 0
		StatusBar.BackgroundTransparency = 0
		Content.BackgroundTransparency = 0
		SearchBar.BackgroundTransparency = 0
		for _, bg in ipairs(ComponentBgs) do
			if bg and bg.Parent then bg.BackgroundTransparency = 0 end
		end
	end
end, "transparent opacity")
	secEffects.Add(transFrame)

Spacer(SettingsPage, 8)
local secInterface = Section(SettingsPage, "INTERFACE")
-- FIX: scale slider no longer re-centers window
local function updateScale(v)
	CurrentScale = v / 100
	Config.scale = v
	DebouncedSave()
	local nW, nH = math.floor(WinW * CurrentScale), math.floor(WinH * CurrentScale)
	-- Keep window centered but don't throw away dragged position
	-- Only recenter if no saved position (first run)
	local oldPos = Window.Position
	Window.Size = UDim2.new(0, nW, 0, nH)
	GlowContainer.Size = UDim2.new(0, nW + 40, 0, nH + 40)
	-- Re-center glow around window
	GlowContainer.Position = UDim2.new(oldPos.X.Scale, oldPos.X.Offset - 20, oldPos.Y.Scale, oldPos.Y.Offset - 20)
	Window.Position = oldPos -- maintain position
end
local scaleFrame, _ = Slider(SettingsPage, "UI Scale", 100, 150, Config.scale, updateScale, "scale size zoom")
	secInterface.Add(scaleFrame)

Spacer(SettingsPage, 8)
local secKeybind = Section(SettingsPage, "KEYBIND")
local kbFrame, _ = KeybindPicker(SettingsPage, "Toggle GUI Key", ToggleKeybind, function(kb)
	ToggleKeybind = kb
	Config.keybind = kb.Name
	DebouncedSave()
	Notify("Keybind", "Toggle set to " .. kb.Name, 2, "success")
end, "keybind hotkey toggle")
	secKeybind.Add(kbFrame)

-- ========================= INFO PAGE =============================
Section(InfoPage, "ABOUT")
Label(InfoPage, "Radium Hub v" .. HUB_VERSION, false)

Spacer(InfoPage, 8)
Section(InfoPage, "KEYBINDS")
Label(InfoPage, ToggleKeybind.Name .. " - Toggle GUI", true)
Label(InfoPage, "Drag topbar to move", true)

Spacer(InfoPage, 8)
Section(InfoPage, "PLATFORM")
Label(InfoPage, "Device: " .. (IsMobile and "Mobile" or "PC"), true)
Label(InfoPage, "Executor: " .. (identifyexecutor and identifyexecutor() or "Unknown"), true)

Spacer(InfoPage, 8)
Section(InfoPage, "CREDITS")
Label(InfoPage, "Developer: Uzuha", true)

-- ==================== MINIMIZE / CLOSE ===========================
local minimized = false

-- Small heart badge shown when minimized
local HeartBadge = Instance.new("TextButton")
HeartBadge.Name = "HeartBadge"
HeartBadge.Size = UDim2.new(0, 44, 0, 44)
HeartBadge.Position = UDim2.new(0.5, -22, 0.5, -22)
HeartBadge.BackgroundColor3 = Bg
HeartBadge.BorderSizePixel = 0
HeartBadge.Text = "<3"
HeartBadge.TextColor3 = Accent
HeartBadge.TextSize = 20
HeartBadge.Font = FONT_BOLD
HeartBadge.Visible = false
HeartBadge.ZIndex = 200
HeartBadge.Parent = ScreenGui
table.insert(BgElements, HeartBadge)

local HeartStroke = Instance.new("UIStroke")
HeartStroke.Color = Accent
HeartStroke.Thickness = 1.5
HeartStroke.Parent = HeartBadge
table.insert(BorderElements, HeartStroke)

local HeartCorner = Instance.new("UICorner")
HeartCorner.CornerRadius = UDim.new(0, 8)
HeartCorner.Parent = HeartBadge

local function doMinimize()
	minimized = true
	CloseAllDropdowns()
	-- Hide glow
	GlowContainer.Visible = false
	-- Hide main window
	Window.Visible = false
	DropdownHolder.Visible = false
	-- Show heart badge
	HeartBadge.Visible = true
	if Config.hbSX then
		HeartBadge.Position = UDim2.new(Config.hbSX, Config.hbOX, Config.hbSY, Config.hbOY)
	else
		HeartBadge.Position = UDim2.new(Window.Position.X.Scale, Window.Position.X.Offset + (math.floor(WinW * CurrentScale) - 44) / 2, Window.Position.Y.Scale, Window.Position.Y.Offset + (math.floor(WinH * CurrentScale) - 44) / 2) -- centered where window was
	end
end

local function doRestore()
	minimized = false
	-- Restore glow if enabled
	GlowContainer.Visible = GlowEnabled
	-- Show main window
	Window.Visible = true
	DropdownHolder.Visible = true
	-- Hide heart badge
	HeartBadge.Visible = false
end

MinBtn.MouseButton1Click:Connect(function()
	if minimized then doRestore() else doMinimize() end
end)

-- Close button = destroy GUI
CloseBtn.MouseButton1Click:Connect(function()
	ScreenGui:Destroy()
end)

-- Click heart badge to restore, drag to move
local HEART_DRAG_THRESHOLD = 8
local heartDragging = false
local heartWasDragged = false
local heartDragStart, heartStartPos = nil, nil
HeartBadge.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		heartDragging = true
		heartWasDragged = false
		heartDragStart = i.Position
		heartStartPos = HeartBadge.Position
	end
end)
local heartInputChanged = UserInputService.InputChanged:Connect(function(i)
	if not heartDragging then return end
	if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
		local d = i.Position - heartDragStart
		if (d.X ^ 2 + d.Y ^ 2) ^ 0.5 > HEART_DRAG_THRESHOLD then
			heartWasDragged = true
		end
		HeartBadge.Position = UDim2.new(heartStartPos.X.Scale, heartStartPos.X.Offset + d.X,
			heartStartPos.Y.Scale, heartStartPos.Y.Offset + d.Y)
	end
end)
local heartInputEnded = UserInputService.InputEnded:Connect(function(i)
	if heartDragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
		heartDragging = false
		if heartWasDragged then
			-- Save the new badge position instead of restoring the hub
			Config.hbSX = HeartBadge.Position.X.Scale
			Config.hbOX = HeartBadge.Position.X.Offset
			Config.hbSY = HeartBadge.Position.Y.Scale
			Config.hbOY = HeartBadge.Position.Y.Offset
			DebouncedSave()
		else
			doRestore()
		end
	end
end)

MinBtn.MouseEnter:Connect(function() Tween(MinBtn, {BackgroundColor3 = BgElev}) end)
MinBtn.MouseLeave:Connect(function() Tween(MinBtn, {BackgroundColor3 = BgTer}) end)
CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn, {BackgroundColor3 = Error, TextColor3 = Text}) end)
CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn, {BackgroundColor3 = BgTer, TextColor3 = TextSec}) end)
HeartBadge.MouseEnter:Connect(function() Tween(HeartBadge, {BackgroundColor3 = BgElev}) end)
HeartBadge.MouseLeave:Connect(function() Tween(HeartBadge, {BackgroundColor3 = Bg}) end)

-- ======================== DRAG SYSTEM ============================
-- FIX: Replaced InputEnded + heartbeat fallback with reliable
-- RenderStepped + IsMouseButtonPressed check. This cannot get stuck.
local dragging = false
local dragStart, startPos, glowStartPos = nil, nil, nil

Topbar.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = i.Position
		startPos = Window.Position
		glowStartPos = GlowContainer.Position
	end
end)

local dragInputChanged = UserInputService.InputChanged:Connect(function(i)
	if not dragging then return end
	if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
		local d = i.Position - dragStart
		Window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
			startPos.Y.Scale, startPos.Y.Offset + d.Y)
		GlowContainer.Position = UDim2.new(glowStartPos.X.Scale, glowStartPos.X.Offset + d.X,
			glowStartPos.Y.Scale, glowStartPos.Y.Offset + d.Y)
	end
end)

-- Reliability: check every frame if the button is still held
RunService.RenderStepped:Connect(function()
	if not dragging then return end
	if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
		-- Also check InputEnded as fallback for Touch
		dragging = false
		Config.posSX = Window.Position.X.Scale
		Config.posOX = Window.Position.X.Offset
		Config.posSY = Window.Position.Y.Scale
		Config.posOY = Window.Position.Y.Offset
		DebouncedSave()
	end
end)

-- Keep InputEnded as a fast path for clean releases
local dragInputEnded = UserInputService.InputEnded:Connect(function(i)
	if not dragging then return end
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		dragging = false
		Config.posSX = Window.Position.X.Scale
		Config.posOX = Window.Position.X.Offset
		Config.posSY = Window.Position.Y.Scale
		Config.posOY = Window.Position.Y.Offset
		DebouncedSave()
	end
end)

-- ========================== KEYBIND ==============================
UserInputService.InputBegan:Connect(function(i, p)
	if p then return end
	if i.KeyCode == ToggleKeybind then
		if minimized then
			doRestore()
		else
			doMinimize()
		end
	end
end)

-- ========================== MOBILE ===============================
if IsMobile then
	local MB = Instance.new("TextButton")
	MB.Size = UDim2.new(0, 40, 0, 40)
	MB.Position = UDim2.new(0, 10, 0.5, -20)
	MB.BackgroundColor3 = Accent
	MB.BorderSizePixel = 0
	MB.Text = "K"
	MB.TextColor3 = Text
	MB.TextSize = 16
	MB.Font = FONT_BOLD
	MB.Parent = ScreenGui
	table.insert(AccentElements, MB)

	local MBC = Instance.new("UICorner")
	MBC.CornerRadius = UDim.new(1, 0)
	MBC.Parent = MB

	MB.MouseButton1Click:Connect(function()
		if minimized then doRestore() else doMinimize() end
	end)
end

-- =========================== INIT ================================
task.spawn(function()
	task.wait(0.15)

	-- Apply saved accent
	if AccentColors[Config.accent] then
		SetAccent(AccentColors[Config.accent])
		-- Sync dropdown display to match
		if accentSetSelected then accentSetSelected(Config.accent) end
	end

	-- Apply saved background theme
	SetBgTheme(Config.bgTheme)
	if bgThemeSetSelected then bgThemeSetSelected(Config.bgTheme) end

	-- Apply glow
	SetGlowEnabled(Config.glow)

	-- Apply keybind
	if Config.keybind then
		local kb = Enum.KeyCode[Config.keybind]
		if kb then ToggleKeybind = kb end
	end

	-- Apply scale (without recentering if position was saved)
	if Config.scale and Config.scale ~= 100 then
		CurrentScale = Config.scale / 100
		local nW, nH = math.floor(WinW * CurrentScale), math.floor(WinH * CurrentScale)
		Window.Size = UDim2.new(0, nW, 0, nH)
		GlowContainer.Size = UDim2.new(0, nW + 40, 0, nH + 40)
		if not Config.posSX then
			Window.Position = UDim2.new(0.5, -nW/2, 0.5, -nH/2)
			GlowContainer.Position = UDim2.new(0.5, -(nW+40)/2, 0.5, -(nH+40)/2)
		end
	end

	-- Restore window position (full UDim2, preserves Scale + Offset)
	if Config.posSX then
		Window.Position = UDim2.new(Config.posSX, Config.posOX, Config.posSY, Config.posOY)
		GlowContainer.Position = UDim2.new(Config.posSX, Config.posOX - 20, Config.posSY, Config.posOY - 20)
	end
	end)

print("Radium Hub v" .. HUB_VERSION)
print("Device:", IsMobile and "Mobile" or "PC")
print("Toggle:", ToggleKeybind.Name)
Notify("Radium Hub", "v" .. HUB_VERSION .. " loaded", 3, "success")

return {
	CreateTab     = CreateTab,
	Section       = Section,
	Button        = Button,
	Toggle        = Toggle,
	Slider        = Slider,
	Dropdown      = Dropdown,
	KeybindPicker = KeybindPicker,
	Label         = Label,
	Spacer        = Spacer,

	Notify          = Notify,
	SetAccent       = SetAccent,
	SetBgTheme      = SetBgTheme,
	SetGlowEnabled  = SetGlowEnabled,
	CloseAllDropdowns = CloseAllDropdowns,

	Pages = Pages,
}
