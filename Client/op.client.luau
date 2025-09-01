-- OP system client-side panel (independent). Toggle with Tab. No dependency for base gameplay.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Require Save for showing money
local Save = require(script.Parent:WaitForChild("Sync"):WaitForChild("Save"))

-- Remotes (optional usage)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local MoneyChangeRemote = Remotes:WaitForChild("MoneyChangeRemote")

-- UI state
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "OPPanel"
screenGui.Enabled = false
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Name = "Panel"
frame.Size = UDim2.new(0, 420, 0, 360)
frame.AnchorPoint = Vector2.new(1, 1)
frame.Position = UDim2.new(1, -20, 1, -20)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 36)
title.Position = UDim2.new(0, 10, 0, 10)
title.BackgroundTransparency = 1
title.Text = "OP Control Panel (J to toggle)"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 24
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame
title.Visible = false -- hide header: only rows are shown

local moneyLabel = Instance.new("TextLabel")
moneyLabel.Size = UDim2.new(1, -20, 0, 28)
moneyLabel.Position = UDim2.new(0, 10, 0, 56)
moneyLabel.BackgroundTransparency = 1
moneyLabel.Text = "Money: 0"
moneyLabel.Font = Enum.Font.SourceSans
moneyLabel.TextSize = 22
moneyLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
moneyLabel.Parent = frame
moneyLabel.Visible = false -- hide standalone money label (we use row layout)

local rowValueLabel -- label inside the Money row
local function refreshMoney()
	local money = tonumber(Save.Money) or 0
	if moneyLabel then
		moneyLabel.Text = "Money: " .. tostring(money)
	end
	if rowValueLabel then
		rowValueLabel.Text = "Money: " .. tostring(money)
	end
end

-- React to save changes
Save:OnChanged(function(key, value)
	if key == "Money" then
		refreshMoney()
	end
end)
refreshMoney()

-- Settings-style list: a single row for Money with four inline buttons on the right
-- Scrollable content area to avoid overlap as items grow
local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Content"
scroll.AnchorPoint = Vector2.new(0, 1)
scroll.Position = UDim2.new(0, 10, 1, -10)
scroll.Size = UDim2.new(1, -20, 1, -80) -- leave top space for hidden title and margins
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = frame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scroll

-- Money row container
local row = Instance.new("Frame")
row.Name = "Row_Money"
row.Size = UDim2.new(1, -0, 0, 56)
row.Position = UDim2.new(0, 0, 0, 0) -- Y controlled by layout
row.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
row.BackgroundTransparency = 0.2
row.BorderSizePixel = 0
row.Parent = scroll

-- Left label showing current money
local left = Instance.new("TextLabel")
left.Name = "Label"
left.Size = UDim2.new(1, -(200 + 24), 1, 0) -- reserve space for button group
left.Position = UDim2.new(0, 12, 0, 0)
left.BackgroundTransparency = 1
left.TextXAlignment = Enum.TextXAlignment.Left
left.TextYAlignment = Enum.TextYAlignment.Center
left.Font = Enum.Font.SourceSansBold
left.TextSize = 20
left.TextColor3 = Color3.fromRGB(255, 255, 255)
left.Parent = row

rowValueLabel = left -- refreshMoney will set text to "Money: <value>"
refreshMoney()

-- Right button group
local group = Instance.new("Frame")
group.Name = "Buttons"
group.Size = UDim2.new(0, 200, 0, 40)
group.AnchorPoint = Vector2.new(1, 0.5)
group.Position = UDim2.new(1, -12, 0.5, 0)
group.BackgroundTransparency = 1
group.Parent = row

local h = Instance.new("UIListLayout")
h.FillDirection = Enum.FillDirection.Horizontal
h.Padding = UDim.new(0, 6)
h.HorizontalAlignment = Enum.HorizontalAlignment.Right
h.VerticalAlignment = Enum.VerticalAlignment.Center
h.Parent = group

local function smallButton(text, color, onClick)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 40, 0, 32)
	b.Text = text
	b.Font = Enum.Font.SourceSansBold
	b.TextSize = 16
	b.BackgroundColor3 = color
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.AutoButtonColor = true
	b.Parent = group
	b.MouseButton1Click:Connect(onClick)
	return b
end

-- Use small arrow-like/text indicators
smallButton("↑", Color3.fromRGB(35, 120, 35), function()
	MoneyChangeRemote:FireServer({ action = "add", amount = 5 })
end)

smallButton("↑↑", Color3.fromRGB(35, 120, 35), function()
	MoneyChangeRemote:FireServer({ action = "add", amount = 500 })
end)

smallButton("↓", Color3.fromRGB(120, 35, 35), function()
	MoneyChangeRemote:FireServer({ action = "add", amount = -2 })
end)

smallButton("0", Color3.fromRGB(80, 80, 80), function()
	MoneyChangeRemote:FireServer({ action = "clear" })
end)

-- Toggle panel with J; do not toggle while typing in text boxes
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if UserInputService:GetFocusedTextBox() ~= nil then return end
	if input.KeyCode == Enum.KeyCode.J then
		screenGui.Enabled = not screenGui.Enabled
	end
end)

