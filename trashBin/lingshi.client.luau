-- TEMP / DEPRECATED test script: Q adds 5, E subtracts 2
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Require per project convention
local Save = require(script.Parent:WaitForChild("Sync"):WaitForChild("Save"))

-- Create top-left money UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MoneyTestGui"
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local moneyLabel = Instance.new("TextLabel")
moneyLabel.Name = "MoneyLabel"
moneyLabel.Size = UDim2.new(0, 200, 0, 40)
moneyLabel.Position = UDim2.new(0, 10, 0, 10)
moneyLabel.BackgroundTransparency = 0.5
moneyLabel.BackgroundColor3 = Color3.fromRGB(30,30,30)
moneyLabel.TextColor3 = Color3.fromRGB(255,255,0)
moneyLabel.Font = Enum.Font.SourceSansBold
moneyLabel.TextSize = 28
moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
moneyLabel.Parent = screenGui

local function updateMoneyLabel()
    local money = Save.Money or 0
    moneyLabel.Text = "Money: " .. tostring(money)
end

updateMoneyLabel()

-- Poll every 0.1s to refresh UI for testing local Save updates
spawn(function()
    while true do
        updateMoneyLabel()
        wait(0.1)
    end
end)

-- Assume a RemoteEvent for money operations
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local MoneyChangeRemote = Remotes:WaitForChild("MoneyChangeRemote")
local SaveDataRemote = Remotes:WaitForChild("SaveDataRemote")

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Q then
    MoneyChangeRemote:FireServer(5) -- request +5
    elseif input.KeyCode == Enum.KeyCode.E then
    MoneyChangeRemote:FireServer(-2) -- request -2
    end
end)

-- Listen to server Save table sync
SaveDataRemote.OnClientEvent:Connect(function(command, data)
    if command == "UpdateSave" and type(data) == "table" then
        for key, value in pairs(data) do
            Save:Set(key, value)
        end
    end
end)
