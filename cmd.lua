-- Kimchi Console v1.0
-- Embedded developer console styled to match KimchiHub
-- Toggle with F2

local LogService = game:GetService("LogService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

-- ============================================================
-- THEME (matches KimchiHub)
-- ============================================================
local Accent = Color3.fromRGB(99, 102, 241)
local Bg      = Color3.fromRGB(18, 18, 18)
local BgSec   = Color3.fromRGB(22, 22, 22)
local BgTer   = Color3.fromRGB(30, 30, 30)
local BgElev  = Color3.fromRGB(38, 38, 38)
local Border  = Color3.fromRGB(50, 50, 50)
local Text    = Color3.fromRGB(255, 255, 255)
local TextSec = Color3.fromRGB(150, 150, 150)
local TextMut = Color3.fromRGB(100, 100, 100)
local Error   = Color3.fromRGB(239, 68, 68)
local Success = Color3.fromRGB(34, 197, 94)

local TweenFast   = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TweenMed    = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TweenSmooth = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function Tween(obj, props, info)
	TweenService:Create(obj, info or TweenFast, props):Play()
end

-- ============================================================
-- DRAGGING SYSTEM
-- ============================================================
local DraggingSystem = {}

function DraggingSystem.IsMouseOverFrame(frame, position)
	local absPos, absSize = frame.AbsolutePosition, frame.AbsoluteSize
	return position.X >= absPos.X
		and position.X <= absPos.X + absSize.X
		and position.Y >= absPos.Y
		and position.Y <= absPos.Y + absSize.Y
end

function DraggingSystem.MakeDraggable(mainFrame, dragFrame, callbacks)
	if not mainFrame or not dragFrame then return end

	local DRAG_THRESHOLD = 5
	local dragging, dragStart, startPos = false, nil, nil
	local dragDistance, isDraggingStarted = 0, false
	local currentTouch = nil
	local inputBeganConn, inputEndedConn, inputChangedConn = nil, nil, nil

	local function updatePosition(input)
		if not dragging or not dragStart then return end
		local delta = input.Position - dragStart
		dragDistance = math.sqrt(delta.X ^ 2 + delta.Y ^ 2)
		local screenSize = workspace.CurrentCamera.ViewportSize

		local newScaleX, newOffsetX = startPos.X.Scale, startPos.X.Offset + delta.X
		local newScaleY, newOffsetY = startPos.Y.Scale, startPos.Y.Offset + delta.Y

		if startPos.X.Scale > 0 then
			local absoluteX = (screenSize.X * startPos.X.Scale) + startPos.X.Offset + delta.X
			newScaleX, newOffsetX = absoluteX / screenSize.X, 0
		end
		if startPos.Y.Scale > 0 then
			local absoluteY = (screenSize.Y * startPos.Y.Scale) + startPos.Y.Offset + delta.Y
			newScaleY, newOffsetY = absoluteY / screenSize.Y, 0
		end

		mainFrame.Position = UDim2.new(newScaleX, newOffsetX, newScaleY, newOffsetY)
		if callbacks and callbacks.OnDragUpdate then
			callbacks.OnDragUpdate(mainFrame.Position, dragDistance)
		end
	end

	local function resetDragState()
		dragging, dragStart, startPos = false, nil, nil
		dragDistance, isDraggingStarted = 0, false
		currentTouch = nil
	end

	local function cleanupConnections()
		if inputEndedConn then inputEndedConn:Disconnect(); inputEndedConn = nil end
		if inputChangedConn then inputChangedConn:Disconnect(); inputChangedConn = nil end
	end

	local function onInputEnded(endInput)
		if not dragging then return end
		if currentTouch then
			if endInput.UserInputType ~= Enum.UserInputType.Touch or endInput ~= currentTouch then return end
		else
			if endInput.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		end

		local wasDragged = dragDistance > DRAG_THRESHOLD
		if not wasDragged and callbacks and callbacks.OnClick then
			callbacks.OnClick()
		end
		if wasDragged and isDraggingStarted and callbacks and callbacks.OnDragEnd then
			callbacks.OnDragEnd(mainFrame.Position, wasDragged)
		end
		resetDragState()
		cleanupConnections()
	end

	local function onInputChanged(moveInput)
		if not dragging then return end
		local isRelevant = currentTouch
			and (moveInput.UserInputType == Enum.UserInputType.Touch and moveInput == currentTouch)
			or (moveInput.UserInputType == Enum.UserInputType.MouseMovement)
		if not isRelevant then return end

		if not isDraggingStarted and dragDistance > DRAG_THRESHOLD then
			isDraggingStarted = true
			if callbacks and callbacks.OnDragStart then callbacks.OnDragStart() end
		end
		updatePosition(moveInput)
	end

	local function onInputBegan(input)
		if input.UserInputState ~= Enum.UserInputState.Begin or dragging then return end
		local it = input.UserInputType
		if it ~= Enum.UserInputType.MouseButton1 and it ~= Enum.UserInputType.Touch then return end
		if not DraggingSystem.IsMouseOverFrame(dragFrame, input.Position) then return end

		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
		dragDistance = 0
		isDraggingStarted = false
		currentTouch = (it == Enum.UserInputType.Touch) and input or nil

		inputEndedConn = UserInputService.InputEnded:Connect(onInputEnded)
		inputChangedConn = UserInputService.InputChanged:Connect(onInputChanged)
	end

	inputBeganConn = dragFrame.InputBegan:Connect(onInputBegan)

	return function()
		if inputBeganConn then inputBeganConn:Disconnect() end
		cleanupConnections()
		resetDragState()
	end
end

-- ============================================================
-- RESIZE SYSTEM
-- ============================================================
local ResizeSystem = {}
local RESIZE_MIN_W, RESIZE_MIN_H = 300, 200

function ResizeSystem.MakeResizable(mainFrame, handle, callbacks)
	if not mainFrame or not handle then return end

	local resizing, resizeStart, startSize, startPosition = false, nil, nil, nil
	local activeTouch = nil
	local inputBeganConn, inputEndedConn, inputChangedConn = nil, nil, nil

	local function mode()
		local n = handle.Name
		if n == "ResizeRight" then return "right"
		elseif n == "ResizeLeft" then return "left"
		elseif n == "ResizeBottom" then return "bottom"
		elseif n == "ResizeTop" then return "top"
		elseif n == "ResizeBottomRight" then return "bottomRight"
		elseif n == "ResizeBottomLeft" then return "bottomLeft"
		elseif n == "ResizeTopRight" then return "topRight"
		elseif n == "ResizeTopLeft" then return "topLeft"
		end
		return "right"
	end

	local function updateResize(input)
		if not resizing or not resizeStart then return end
		local delta = input.Position - resizeStart
		local m = mode()
		local w, h = startSize.X.Offset, startSize.Y.Offset
		local x, y = startPosition.X.Offset, startPosition.Y.Offset

		if m == "right" or m == "bottomRight" or m == "topRight" then
			w = math.max(RESIZE_MIN_W, startSize.X.Offset + delta.X)
		elseif m == "left" or m == "bottomLeft" or m == "topLeft" then
			w = math.max(RESIZE_MIN_W, startSize.X.Offset - delta.X)
			x = startPosition.X.Offset + (startSize.X.Offset - w)
		end
		if m == "bottom" or m == "bottomRight" or m == "bottomLeft" then
			h = math.max(RESIZE_MIN_H, startSize.Y.Offset + delta.Y)
		elseif m == "top" or m == "topRight" or m == "topLeft" then
			h = math.max(RESIZE_MIN_H, startSize.Y.Offset - delta.Y)
			y = startPosition.Y.Offset + (startSize.Y.Offset - h)
		end

		mainFrame.Size = UDim2.new(0, w, 0, h)
		mainFrame.Position = UDim2.new(startPosition.X.Scale, x, startPosition.Y.Scale, y)
		if callbacks and callbacks.OnResizeUpdate then
			callbacks.OnResizeUpdate(mainFrame.Size, mainFrame.Position)
		end
	end

	local function resetState()
		resizing, resizeStart, startSize, startPosition = false, nil, nil, nil
		activeTouch = nil
	end

	local function cleanupConnections()
		if inputEndedConn then inputEndedConn:Disconnect(); inputEndedConn = nil end
		if inputChangedConn then inputChangedConn:Disconnect(); inputChangedConn = nil end
	end

	local function onResizeEnd(endInput)
		if not resizing then return end
		if activeTouch then
			if endInput.UserInputType ~= Enum.UserInputType.Touch or endInput ~= activeTouch then return end
		else
			if endInput.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		end
		if callbacks and callbacks.OnResizeEnd then callbacks.OnResizeEnd(mainFrame.Size) end
		resetState()
		cleanupConnections()
	end

	local function onResizeChanged(moveInput)
		if not resizing then return end
		if activeTouch then
			if moveInput.UserInputType ~= Enum.UserInputType.Touch or moveInput ~= activeTouch then return end
		else
			if moveInput.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		end
		updateResize(moveInput)
	end

	local function onResizeBegan(input)
		if input.UserInputState ~= Enum.UserInputState.Begin or resizing then return end
		local it = input.UserInputType
		if it ~= Enum.UserInputType.MouseButton1 and it ~= Enum.UserInputType.Touch then return end
		if not DraggingSystem.IsMouseOverFrame(handle, input.Position) then return end

		resizing = true
		resizeStart = input.Position
		startSize = mainFrame.Size
		startPosition = mainFrame.Position
		activeTouch = (it == Enum.UserInputType.Touch) and input or nil

		if callbacks and callbacks.OnResizeStart then callbacks.OnResizeStart() end
		inputEndedConn = UserInputService.InputEnded:Connect(onResizeEnd)
		inputChangedConn = UserInputService.InputChanged:Connect(onResizeChanged)
	end

	inputBeganConn = handle.InputBegan:Connect(onResizeBegan)

	return function()
		if inputBeganConn then inputBeganConn:Disconnect() end
		cleanupConnections()
		resetState()
	end
end

-- ============================================================
-- DESTROY PREVIOUS INSTANCE
-- ============================================================
if CoreGui:FindFirstChild("KimchiConsole") then
	CoreGui.KimchiConsole:Destroy()
end

-- ============================================================
-- STATE
-- ============================================================
local autoScroll = true
local textSize = 12
local cleanupTasks = {}

local function getDPIScale()
	local w = workspace.CurrentCamera.ViewportSize.X
	return math.clamp(w / 1920, 0.7, 1.15)
end

-- ============================================================
-- SCREEN GUI
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KimchiConsole"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = CoreGui

-- ============================================================
-- GLOW CONTAINER (matching KimchiHub's glow rings)
-- ============================================================
local GlowContainer = Instance.new("Frame")
GlowContainer.Name = "GlowContainer"
GlowContainer.Size = UDim2.new(0, 590, 0, 440)
GlowContainer.Position = UDim2.new(0.5, -295, 0.5, -220)
GlowContainer.BackgroundTransparency = 1
GlowContainer.ZIndex = 0
GlowContainer.Parent = screenGui

for i = 1, 3 do
	local glow = Instance.new("Frame")
	glow.Size = UDim2.new(1, -(4-i)*8, 1, -(4-i)*8)
	glow.Position = UDim2.new(0.5, 0, 0.5, 0)
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.BackgroundColor3 = Accent
	glow.BackgroundTransparency = 0.88 + (i * 0.03)
	glow.BorderSizePixel = 0
	glow.ZIndex = -i
	glow.Parent = GlowContainer
end

-- ============================================================
-- MAIN FRAME
-- ============================================================
local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
mainFrame.Size = UDim2.new(0, 550, 0, 400)
mainFrame.Position = UDim2.new(0.5, -275, 0.5, -200)
mainFrame.BackgroundColor3 = Bg
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.ZIndex = 1
mainFrame.Parent = screenGui

local uiScale = Instance.new("UIScale")
uiScale.Scale = getDPIScale()
uiScale.Parent = mainFrame

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Border
mainStroke.Thickness = 1
mainStroke.Parent = mainFrame

-- Accent line at top (matching KimchiHub)
local accentLine = Instance.new("Frame")
accentLine.Size = UDim2.new(1, 0, 0, 2)
accentLine.BackgroundColor3 = Accent
accentLine.BorderSizePixel = 0
accentLine.ZIndex = 5
accentLine.Parent = mainFrame

-- ============================================================
-- TITLE BAR
-- ============================================================
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.Position = UDim2.new(0, 0, 0, 2)
titleBar.BackgroundColor3 = BgSec
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 2
titleBar.Parent = mainFrame

local tbCorner = Instance.new("UICorner")
tbCorner.CornerRadius = UDim.new(0, 8)
tbCorner.Parent = titleBar

-- Mask bottom corners of titlebar
local tbMask = Instance.new("Frame")
tbMask.Size = UDim2.new(1, 0, 0, 8)
tbMask.Position = UDim2.new(0, 0, 1, -8)
tbMask.BackgroundColor3 = BgSec
tbMask.BorderSizePixel = 0
tbMask.ZIndex = 2
tbMask.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -120, 1, 0)
titleLabel.Position = UDim2.new(0, 14, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Kimchi Console"
titleLabel.TextColor3 = Text
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 3
titleLabel.Parent = titleBar

-- ============================================================
-- TITLE BAR CONTROLS (KimchiHub-style)
-- ============================================================
local controls = Instance.new("Frame")
controls.Size = UDim2.new(0, 250, 1, 0)
controls.Position = UDim2.new(1, -256, 0, 0)
controls.BackgroundTransparency = 1
controls.ZIndex = 3
controls.Parent = titleBar

local controlList = Instance.new("UIListLayout")
controlList.SortOrder = Enum.SortOrder.LayoutOrder
controlList.FillDirection = Enum.FillDirection.Horizontal
controlList.HorizontalAlignment = Enum.HorizontalAlignment.Right
controlList.VerticalAlignment = Enum.VerticalAlignment.Center
controlList.Padding = UDim.new(0, 4)
controlList.Parent = controls

local function makeTitleButton(name, text, sizeX, bgColor)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, sizeX, 0, 24)
	btn.BackgroundColor3 = bgColor or BgTer
	btn.BorderSizePixel = 0
	btn.Text = text
	btn.TextColor3 = TextSec
	btn.TextSize = 11
	btn.Font = Enum.Font.GothamBold
	btn.AutoButtonColor = false
	btn.ZIndex = 3
	btn.Parent = controls

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Color = Border
	stroke.Thickness = 1
	stroke.Transparency = 0.5
	stroke.Parent = btn

	btn.MouseEnter:Connect(function()
		Tween(btn, {BackgroundColor3 = bgColor and BgElev or BgTer}, TweenFast)
		Tween(btn, {TextColor3 = Text}, TweenFast)
	end)
	btn.MouseLeave:Connect(function()
		Tween(btn, {BackgroundColor3 = bgColor or BgTer}, TweenFast)
		Tween(btn, {TextColor3 = TextSec}, TweenFast)
	end)

	return btn
end

local autoScrollBtn = makeTitleButton("AutoScroll", "Scroll: ON", 65)
autoScrollBtn.BackgroundColor3 = Color3.fromRGB(60, 80, 160)
autoScrollBtn.TextColor3 = Text

local copyAllBtn = makeTitleButton("CopyAll", "Copy All", 60)
local clearBtn = makeTitleButton("Clear", "Clear", 48)

-- Font size box
local textSizeBox = Instance.new("TextBox")
textSizeBox.Size = UDim2.new(0, 38, 0, 24)
textSizeBox.BackgroundColor3 = BgTer
textSizeBox.BorderSizePixel = 0
textSizeBox.Text = "12"
textSizeBox.TextColor3 = Text
textSizeBox.Font = Enum.Font.GothamBold
textSizeBox.TextSize = 11
textSizeBox.PlaceholderText = "px"
textSizeBox.PlaceholderColor3 = TextMut
textSizeBox.TextXAlignment = Enum.TextXAlignment.Center
textSizeBox.ZIndex = 3
textSizeBox.Parent = controls

local tsCorner = Instance.new("UICorner")
tsCorner.CornerRadius = UDim.new(0, 4)
tsCorner.Parent = textSizeBox

local tsStroke = Instance.new("UIStroke")
tsStroke.Color = Border
tsStroke.Thickness = 1
tsStroke.Transparency = 0.5
tsStroke.Parent = textSizeBox

-- Close button
local closeBtn = makeTitleButton("Close", "x", 28, Color3.fromRGB(160, 50, 50))
closeBtn.TextSize = 14

closeBtn.MouseEnter:Connect(function()
	Tween(closeBtn, {BackgroundColor3 = Error}, TweenFast)
	Tween(closeBtn, {TextColor3 = Text}, TweenFast)
end)
closeBtn.MouseLeave:Connect(function()
	Tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(160, 50, 50)}, TweenFast)
	Tween(closeBtn, {TextColor3 = TextSec}, TweenFast)
end)

-- ============================================================
-- LOG CONTAINER
-- ============================================================
local logContainer = Instance.new("ScrollingFrame")
logContainer.Name = "Logs"
logContainer.Size = UDim2.new(1, -16, 1, -56)
logContainer.Position = UDim2.new(0, 8, 0, 48)
logContainer.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
logContainer.BackgroundTransparency = 0.15
logContainer.BorderSizePixel = 0
logContainer.ScrollBarThickness = 0
logContainer.ScrollingEnabled = false
logContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
logContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
logContainer.ScrollBarImageColor3 = Border
logContainer.ScrollBarImageTransparency = 0.5
logContainer.ZIndex = 1
logContainer.Parent = mainFrame

local logStroke = Instance.new("UIStroke")
logStroke.Color = Border
logStroke.Thickness = 1
logStroke.Transparency = 0.6
logStroke.Parent = logContainer

local logCorner = Instance.new("UICorner")
logCorner.CornerRadius = UDim.new(0, 6)
logCorner.Parent = logContainer

local logList = Instance.new("UIListLayout")
logList.SortOrder = Enum.SortOrder.LayoutOrder
logList.Padding = UDim.new(0, 2)
logList.Parent = logContainer

local logPadding = Instance.new("UIPadding")
logPadding.PaddingLeft = UDim.new(0, 6)
logPadding.PaddingRight = UDim.new(0, 6)
logPadding.PaddingTop = UDim.new(0, 4)
logPadding.PaddingBottom = UDim.new(0, 4)
logPadding.Parent = logContainer

-- ============================================================
-- RESIZE HANDLES
-- ============================================================
local function createResizeHandle(name, position, size)
	local handle = Instance.new("TextButton")
	handle.Name = name
	handle.Size = size
	handle.Position = position
	handle.BackgroundTransparency = 1
	handle.Text = ""
	handle.AutoButtonColor = false
	handle.ZIndex = 10
	handle.Parent = mainFrame
	return handle
end

local resizeRight        = createResizeHandle("ResizeRight",        UDim2.new(1, -4, 0, 0),   UDim2.new(0, 8, 1, 0))
local resizeLeft         = createResizeHandle("ResizeLeft",         UDim2.new(0, -4, 0, 0),   UDim2.new(0, 8, 1, 0))
local resizeBottom       = createResizeHandle("ResizeBottom",       UDim2.new(0, 0, 1, -4),   UDim2.new(1, 0, 0, 8))
local resizeTop          = createResizeHandle("ResizeTop",          UDim2.new(0, 0, 0, -4),   UDim2.new(1, 0, 0, 8))
local resizeBottomRight  = createResizeHandle("ResizeBottomRight",  UDim2.new(1, -12, 1, -12), UDim2.new(0, 16, 0, 16))
local resizeBottomLeft   = createResizeHandle("ResizeBottomLeft",   UDim2.new(0, -4, 1, -12),  UDim2.new(0, 16, 0, 16))
local resizeTopRight     = createResizeHandle("ResizeTopRight",     UDim2.new(1, -12, 0, -4),  UDim2.new(0, 16, 0, 16))
local resizeTopLeft      = createResizeHandle("ResizeTopLeft",      UDim2.new(0, -4, 0, -4),   UDim2.new(0, 16, 0, 16))

-- ============================================================
-- LOG RENDERING
-- ============================================================
local COLORS = {
	default = Color3.fromRGB(210, 210, 220),
	error   = Color3.fromRGB(255, 100, 100),
	warning = Color3.fromRGB(255, 195, 100),
	info    = Color3.fromRGB(130, 190, 255),
}

local ICON = {
	[Enum.MessageType.MessageError]   = {bg = Color3.fromRGB(220, 55, 55),  glyph = "!"},
	[Enum.MessageType.MessageWarning] = {bg = Color3.fromRGB(220, 155, 35), glyph = "!"},
	[Enum.MessageType.MessageInfo]    = {bg = Color3.fromRGB(75, 130, 210),  glyph = "i"},
}

local logCounter = 0

local function updateScrollability()
	local contentH = logList.AbsoluteContentSize.Y
	local containerH = logContainer.AbsoluteSize.Y
	if contentH > containerH then
		logContainer.ScrollBarThickness = 5
		logContainer.ScrollingEnabled = true
	else
		logContainer.ScrollBarThickness = 0
		logContainer.ScrollingEnabled = false
	end
end

local scrollDirty = false
local function queueScrollUpdate()
	if scrollDirty then return end
	scrollDirty = true
	task.defer(function()
		scrollDirty = false
		updateScrollability()
	end)
end

logList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(queueScrollUpdate)
logContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(queueScrollUpdate)

local function addLog(message, color, messageType)
	logCounter = logCounter + 1
	local icon = ICON[messageType] or ICON[Enum.MessageType.MessageInfo]

	local logFrame = Instance.new("Frame")
	logFrame.Name = "Entry_" .. logCounter
	logFrame.Size = UDim2.new(1, 0, 0, 0)
	logFrame.BackgroundTransparency = 1
	logFrame.AutomaticSize = Enum.AutomaticSize.Y
	logFrame.ZIndex = 1
	logFrame.Parent = logContainer

	-- Background stripe on hover
	local bgStripe = Instance.new("Frame")
	bgStripe.Size = UDim2.new(1, 0, 1, 0)
	bgStripe.BackgroundColor3 = BgTer
	bgStripe.BackgroundTransparency = 1
	bgStripe.BorderSizePixel = 0
	bgStripe.ZIndex = 0
	bgStripe.Parent = logFrame

	-- Icon badge
	local badge = Instance.new("Frame")
	badge.Size = UDim2.new(0, 16, 0, 16)
	badge.Position = UDim2.new(0, 0, 0, 3)
	badge.BackgroundColor3 = icon.bg
	badge.BorderSizePixel = 0
	badge.ZIndex = 2
	badge.Parent = logFrame

	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0, 3)
	badgeCorner.Parent = badge

	local badgeText = Instance.new("TextLabel")
	badgeText.Size = UDim2.new(1, 0, 1, 0)
	badgeText.BackgroundTransparency = 1
	badgeText.Text = icon.glyph
	badgeText.TextColor3 = Color3.new(1, 1, 1)
	badgeText.Font = Enum.Font.GothamBold
	badgeText.TextSize = 11
	badgeText.ZIndex = 2
	badgeText.Parent = badge

	-- Message text
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "TextLabel"
	textLabel.Size = UDim2.new(1, -75, 0, 0)
	textLabel.Position = UDim2.new(0, 22, 0, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = message
	textLabel.TextColor3 = color or COLORS.default
	textLabel.Font = Enum.Font.RobotoMono
	textLabel.TextSize = textSize
	textLabel.TextWrapped = true
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.AutomaticSize = Enum.AutomaticSize.Y
	textLabel.RichText = false
	textLabel.ZIndex = 2
	textLabel.Parent = logFrame

	-- Copy button (appears on hover)
	local copyBtn = Instance.new("TextButton")
	copyBtn.Size = UDim2.new(0, 40, 0, 18)
	copyBtn.Position = UDim2.new(1, -40, 0, 0)
	copyBtn.BackgroundColor3 = BgElev
	copyBtn.BackgroundTransparency = 0.15
	copyBtn.BorderSizePixel = 0
	copyBtn.Text = "Copy"
	copyBtn.TextColor3 = TextMut
	copyBtn.Font = Enum.Font.Gotham
	copyBtn.TextSize = 9
	copyBtn.AutoButtonColor = false
	copyBtn.ZIndex = 2
	copyBtn.Parent = logFrame

	local copyCorner = Instance.new("UICorner")
	copyCorner.CornerRadius = UDim.new(0, 3)
	copyCorner.Parent = copyBtn

	-- Hover reveals stripe + copy button
	logFrame.MouseEnter:Connect(function()
		Tween(bgStripe, {BackgroundTransparency = 0.7}, TweenFast)
		Tween(copyBtn, {TextColor3 = TextSec}, TweenFast)
	end)
	logFrame.MouseLeave:Connect(function()
		Tween(bgStripe, {BackgroundTransparency = 1}, TweenFast)
		Tween(copyBtn, {TextColor3 = TextMut}, TweenFast)
	end)

	copyBtn.MouseButton1Click:Connect(function()
		local ok = pcall(function()
			if setclipboard then setclipboard(message) end
		end)
		if ok then
			copyBtn.Text = "OK"
			Tween(copyBtn, {TextColor3 = Success}, TweenFast)
			task.delay(1, function()
				if copyBtn and copyBtn.Parent then
					copyBtn.Text = "Copy"
					Tween(copyBtn, {TextColor3 = TextMut}, TweenFast)
				end
			end)
		end
	end)

	-- Auto-scroll
	if autoScroll then
		task.defer(function()
			if logContainer and logContainer.Parent then
				logContainer.CanvasPosition = Vector2.new(0, logContainer.AbsoluteCanvasSize.Y)
			end
		end)
	end

	queueScrollUpdate()
end

-- ============================================================
-- BUTTON ACTIONS
-- ============================================================
autoScrollBtn.MouseButton1Click:Connect(function()
	autoScroll = not autoScroll
	autoScrollBtn.Text = autoScroll and "Scroll: ON" or "Scroll: OFF"
	if autoScroll then
		autoScrollBtn.BackgroundColor3 = Color3.fromRGB(60, 80, 160)
		Tween(autoScrollBtn, {BackgroundColor3 = Color3.fromRGB(60, 80, 160)}, TweenFast)
	else
		Tween(autoScrollBtn, {BackgroundColor3 = BgTer}, TweenFast)
	end
end)

clearBtn.MouseButton1Click:Connect(function()
	for _, child in ipairs(logContainer:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	queueScrollUpdate()
end)

copyAllBtn.MouseButton1Click:Connect(function()
	local all = {}
	for _, child in ipairs(logContainer:GetChildren()) do
		if child:IsA("Frame") then
			local tl = child:FindFirstChild("TextLabel")
			if tl then table.insert(all, tl.Text) end
		end
	end
	if #all > 0 then
		pcall(function()
			if setclipboard then setclipboard(table.concat(all, "\n")) end
		end)
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	screenGui.Enabled = false
end)

local function updateTextSize()
	local n = tonumber(textSizeBox.Text)
	if not n then return end
	n = math.clamp(math.floor(n), 8, 28)
	textSize = n
	textSizeBox.Text = tostring(n)
	for _, logFrame in ipairs(logContainer:GetChildren()) do
		if logFrame:IsA("Frame") then
			local tl = logFrame:FindFirstChild("TextLabel")
			if tl then tl.TextSize = textSize end
		end
	end
end

textSizeBox.FocusLost:Connect(updateTextSize)

-- ============================================================
-- DRAG + RESIZE
-- ============================================================
local function initDragResize()
	-- Drag
	local d = DraggingSystem.MakeDraggable(mainFrame, titleBar, {OnClick = function() end})
	if d then table.insert(cleanupTasks, d) end

	-- Resize
	local handles = {
		resizeRight, resizeLeft, resizeBottom, resizeTop,
		resizeBottomRight, resizeBottomLeft, resizeTopRight, resizeTopLeft,
	}
	for _, h in ipairs(handles) do
		local destroy = ResizeSystem.MakeResizable(mainFrame, h, {
			OnResizeUpdate = function() queueScrollUpdate() end,
		})
		if destroy then table.insert(cleanupTasks, destroy) end
	end
end

initDragResize()

-- ============================================================
-- KEYBIND + LOG HOOK
-- ============================================================
local logServiceConn = nil

local function connectLogService()
	if logServiceConn then return end
	logServiceConn = LogService.MessageOut:Connect(function(message, messageType)
		local color = COLORS.default
		if messageType == Enum.MessageType.MessageError then
			color = COLORS.error
		elseif messageType == Enum.MessageType.MessageWarning then
			color = COLORS.warning
		elseif messageType == Enum.MessageType.MessageInfo then
			color = COLORS.info
		end
		addLog(string.format("[%s] %s", os.date("%H:%M:%S"), message), color, messageType)
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.F2 then
		screenGui.Enabled = not screenGui.Enabled
		if screenGui.Enabled then connectLogService() end
	end
end)

task.defer(updateScrollability)

-- ============================================================
-- PUBLIC API
-- ============================================================
getgenv().KimchiConsole = {
	Log = function(msg)
		addLog(string.format("[%s] %s", os.date("%H:%M:%S"), tostring(msg)), COLORS.default, Enum.MessageType.MessageInfo)
	end,
	Warn = function(msg)
		addLog(string.format("[%s] %s", os.date("%H:%M:%S"), tostring(msg)), COLORS.warning, Enum.MessageType.MessageWarning)
	end,
	Error = function(msg)
		addLog(string.format("[%s] %s", os.date("%H:%M:%S"), tostring(msg)), COLORS.error, Enum.MessageType.MessageError)
	end,
	Show   = function() screenGui.Enabled = true  connectLogService() end,
	Hide   = function() screenGui.Enabled = false end,
	Toggle = function()
		screenGui.Enabled = not screenGui.Enabled
		if screenGui.Enabled then connectLogService() end
	end,
	Clear = function()
		for _, child in ipairs(logContainer:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end
		queueScrollUpdate()
	end,
	IsVisible = function() return screenGui.Enabled end,
}

print("Kimchi Console v1.0 loaded — press F2 to toggle")
