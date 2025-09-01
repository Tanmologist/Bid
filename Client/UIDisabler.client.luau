-- Global UI Disabler - Hides all default Roblox UI elements

local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

-- Function to disable core UI elements
local function disableAllCoreUI()
    local coreGuiTypes = {
        Enum.CoreGuiType.PlayerList,
        Enum.CoreGuiType.Health,
        Enum.CoreGuiType.Backpack,
        Enum.CoreGuiType.Chat,
        Enum.CoreGuiType.All
    }
    
    for _, guiType in ipairs(coreGuiTypes) do
        pcall(function()
            StarterGui:SetCoreGuiEnabled(guiType, false)
        end)
    end
end

-- Function to hide additional UI elements
local function hideAdditionalUI()
    -- Hide reset button
    pcall(function()
        StarterGui:SetCore("ResetButtonCallback", false)
    end)
    
    -- Disable developer console
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
    end)
    
    -- Hide top bar
    pcall(function()
        game:GetService("GuiService"):SetGlobalGuiInset(0, 0, 0, 0)
    end)
end

-- Wait for character to ensure UI is loaded
local function onCharacterAdded(character)
    wait(1) -- Small delay to ensure UI is fully loaded
    disableAllCoreUI()
    hideAdditionalUI()
    print("[UIDisabler] All default UI elements disabled")
end

-- Connect to character spawning
if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

-- Initial disable
disableAllCoreUI()
hideAdditionalUI()

print("[UIDisabler] Global UI disabler initialized")
