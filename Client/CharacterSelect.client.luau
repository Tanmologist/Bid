-- Character Selection UI System
-- Toggle with Tab key, shows light blue character selection interface

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Require Save for character data persistence
local Save = require(script.Parent:WaitForChild("Sync"):WaitForChild("Save"))

-- Remote for character selection
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CharacterSelectRemote = Remotes:WaitForChild("CharacterSelectRemote")

-- Character data
local Characters = {
    {
        id = "C1",
        name = "Plain One",
        description = "A simple character with basic abilities"
    },
    {
        id = "C2",
        name = "Warrior",
        description = "A strong fighter with enhanced combat skills"
    },
    {
        id = "C3",
        name = "Mage",
        description = "A magic user with powerful spells"
    },
    {
        id = "C4",
        name = "Assassin",
        description = "A stealthy character with high speed"
    },
    {
        id = "C5",
        name = "Healer",
        description = "A support character with healing abilities"
    },
    {
        id = "C6",
        name = "Tank",
        description = "A defensive character with high durability"
    },
    {
        id = "C7",
        name = "Archer",
        description = "A ranged character with precise attacks"
    }
}

-- UI state
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CharacterSelect"
screenGui.Enabled = false
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

-- Main frame with light blue theme
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 650, 0, 600) -- Increased height for more characters
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(173, 216, 230) -- Light blue
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Add corner rounding
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -40, 0, 50)
title.Position = UDim2.new(0, 20, 0, 20)
title.BackgroundTransparency = 1
title.Text = "Character Selection"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 32
title.TextColor3 = Color3.fromRGB(25, 25, 25)
title.TextXAlignment = Enum.TextXAlignment.Center
title.Parent = mainFrame

-- Close button (X)
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.Position = UDim2.new(1, -50, 0, 10)
closeButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
closeButton.Text = "×"
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 24
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

-- Character list container
local listFrame = Instance.new("ScrollingFrame")
listFrame.Name = "CharacterList"
listFrame.Size = UDim2.new(1, -40, 1, -140)
listFrame.Position = UDim2.new(0, 20, 0, 80)
listFrame.BackgroundTransparency = 1
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 8
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
listFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 10)
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = listFrame

-- Current selected character
local selectedCharacter = Save.SelectedCharacter or "C1"

-- Function to create character card
local function createCharacterCard(characterData)
    local card = Instance.new("Frame")
    card.Name = "CharacterCard_" .. characterData.id
    card.Size = UDim2.new(1, -20, 0, 80) -- Slightly reduced height for better fit
    card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    card.BorderSizePixel = 0
    card.Parent = listFrame
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card
    
    -- Character ID/Name
    local charName = Instance.new("TextLabel")
    charName.Name = "CharacterName"
    charName.Size = UDim2.new(1, -20, 0, 30)
    charName.Position = UDim2.new(0, 10, 0, 10)
    charName.BackgroundTransparency = 1
    charName.Text = characterData.id .. " - " .. characterData.name
    charName.Font = Enum.Font.SourceSansBold
    charName.TextSize = 20
    charName.TextColor3 = Color3.fromRGB(25, 25, 25)
    charName.TextXAlignment = Enum.TextXAlignment.Left
    charName.Parent = card
    
    -- Character description
    local charDesc = Instance.new("TextLabel")
    charDesc.Name = "CharacterDescription"
    charDesc.Size = UDim2.new(1, -20, 0, 18)
    charDesc.Position = UDim2.new(0, 10, 0, 35)
    charDesc.BackgroundTransparency = 1
    charDesc.Text = characterData.description
    charDesc.Font = Enum.Font.SourceSans
    charDesc.TextSize = 14
    charDesc.TextColor3 = Color3.fromRGB(80, 80, 80)
    charDesc.TextXAlignment = Enum.TextXAlignment.Left
    charDesc.Parent = card
    
    -- Select button
    local selectButton = Instance.new("TextButton")
    selectButton.Name = "SelectButton"
    selectButton.Size = UDim2.new(0, 80, 0, 25)
    selectButton.Position = UDim2.new(1, -90, 1, -30)
    selectButton.BackgroundColor3 = Color3.fromRGB(40, 167, 69)
    selectButton.Text = "Select"
    selectButton.Font = Enum.Font.SourceSansBold
    selectButton.TextSize = 14
    selectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    selectButton.Parent = card
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = selectButton
    
    -- Update card appearance based on selection
    local function updateCardAppearance()
        if selectedCharacter == characterData.id then
            -- Animate to selected state
            local selectedTween = TweenService:Create(card, 
                TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                {BackgroundColor3 = Color3.fromRGB(255, 215, 0)} -- Bright gold
            )
            selectedTween:Play()
            
            selectButton.Text = "✓ Selected"
            selectButton.BackgroundColor3 = Color3.fromRGB(34, 139, 34) -- Forest green
            -- Add glow effect
            card.BorderSizePixel = 3
            card.BorderColor3 = Color3.fromRGB(255, 140, 0) -- Dark orange border
        else
            -- Animate to unselected state
            local unselectedTween = TweenService:Create(card,
                TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                {BackgroundColor3 = Color3.fromRGB(255, 255, 255)} -- White
            )
            unselectedTween:Play()
            
            selectButton.Text = "Select"
            selectButton.BackgroundColor3 = Color3.fromRGB(40, 167, 69) -- Green
            card.BorderSizePixel = 0
        end
    end
    
    -- Select button click handler
    selectButton.MouseButton1Click:Connect(function()
        if selectedCharacter ~= characterData.id then
            selectedCharacter = characterData.id
            Save:Set("SelectedCharacter", selectedCharacter)
            CharacterSelectRemote:FireServer(selectedCharacter)
            print("[CharacterSelect] Selected character:", selectedCharacter)
            
            -- Update all cards
            for _, child in pairs(listFrame:GetChildren()) do
                if child.Name:sub(1, 13) == "CharacterCard" then
                    local cardId = child.Name:sub(15) -- Extract character ID
                    local cardButton = child:FindFirstChild("SelectButton")
                    if cardButton then
                        if cardId == selectedCharacter then
                            -- Animate selected card
                            local selectedTween = TweenService:Create(child,
                                TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                                {BackgroundColor3 = Color3.fromRGB(255, 215, 0)} -- Bright gold
                            )
                            selectedTween:Play()
                            cardButton.Text = "✓ Selected"
                            cardButton.BackgroundColor3 = Color3.fromRGB(34, 139, 34) -- Forest green
                            child.BorderSizePixel = 3
                            child.BorderColor3 = Color3.fromRGB(255, 140, 0) -- Dark orange border
                        else
                            -- Animate unselected cards
                            local unselectedTween = TweenService:Create(child,
                                TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                                {BackgroundColor3 = Color3.fromRGB(255, 255, 255)} -- White
                            )
                            unselectedTween:Play()
                            cardButton.Text = "Select"
                            cardButton.BackgroundColor3 = Color3.fromRGB(40, 167, 69) -- Green
                            child.BorderSizePixel = 0
                        end
                    end
                end
            end
        end
    end)
    
    updateCardAppearance()
    return card
end

-- Create character cards
for _, character in ipairs(Characters) do
    createCharacterCard(character)
end

-- Confirm button at bottom
local confirmButton = Instance.new("TextButton")
confirmButton.Name = "ConfirmButton"
confirmButton.Size = UDim2.new(0, 120, 0, 40)
confirmButton.Position = UDim2.new(0.5, -60, 1, -50)
confirmButton.BackgroundColor3 = Color3.fromRGB(0, 123, 255)
confirmButton.Text = "Confirm"
confirmButton.Font = Enum.Font.SourceSansBold
confirmButton.TextSize = 18
confirmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
confirmButton.Parent = mainFrame

local confirmCorner = Instance.new("UICorner")
confirmCorner.CornerRadius = UDim.new(0, 8)
confirmCorner.Parent = confirmButton

-- Close/Confirm handlers
local function closeInterface()
    screenGui.Enabled = false
end

closeButton.MouseButton1Click:Connect(closeInterface)
confirmButton.MouseButton1Click:Connect(closeInterface)

-- Toggle interface with Tab key
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if UserInputService:GetFocusedTextBox() ~= nil then return end
    if input.KeyCode == Enum.KeyCode.Tab then
        screenGui.Enabled = not screenGui.Enabled
        print("[CharacterSelect] Interface toggled:", screenGui.Enabled)
    end
end)

-- React to save changes (in case character is changed externally)
Save:OnChanged(function(key, value)
    if key == "SelectedCharacter" then
        selectedCharacter = value
        print("[CharacterSelect] Character updated to:", value)
    end
end)

print("[CharacterSelect] Character selection system initialized")
