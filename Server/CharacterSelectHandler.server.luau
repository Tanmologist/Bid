-- Character Selection Handler - Server-side processing of character selection

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require SaveS for data persistence
local SaveS = require(script.Parent:WaitForChild("SyncS"):WaitForChild("SaveS"))

-- Remote for character selection
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CharacterSelectRemote = Remotes:WaitForChild("CharacterSelectRemote")

-- Valid character IDs
local ValidCharacters = {
    ["C1"] = true,
    ["C2"] = true,
    ["C3"] = true,
    ["C4"] = true,
    ["C5"] = true,
    ["C6"] = true,
    ["C7"] = true
}

-- Handle character selection from clients
CharacterSelectRemote.OnServerEvent:Connect(function(player, characterId)
    -- Validate input
    if typeof(characterId) ~= "string" then
        print("[CharacterSelectHandler] Invalid character ID type from", player.Name)
        return
    end
    
    if not ValidCharacters[characterId] then
        print("[CharacterSelectHandler] Invalid character ID:", characterId, "from", player.Name)
        return
    end
    
    -- Get current selected character
    local currentCharacter = SaveS:Get(player, "SelectedCharacter") or "C1"
    
    -- Update if different
    if currentCharacter ~= characterId then
        SaveS:Set(player, "SelectedCharacter", characterId)
        print("[CharacterSelectHandler] Player", player.Name, "selected character:", characterId)
        
        -- Future: Apply character-specific changes here
        -- For now, we only save the selection
    else
        print("[CharacterSelectHandler] Player", player.Name, "already has character:", characterId)
    end
end)

-- Initialize player data when they join
Players.PlayerAdded:Connect(function(player)
    SaveS:InitPlayer(player)
    print("[CharacterSelectHandler] Initialized character data for", player.Name)
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
    SaveS:RemovePlayer(player)
    print("[CharacterSelectHandler] Cleaned up character data for", player.Name)
end)

print("[CharacterSelectHandler] Character selection handler initialized")
