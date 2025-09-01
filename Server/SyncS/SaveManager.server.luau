-- SaveManager.server.luau
-- Handles DataStore I/O for SaveS module (load, periodic save, exit save)

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local SaveS = require(script.Parent:WaitForChild("SaveS"))

local SaveDataStore = DataStoreService:GetDataStore("PlayerSaveData")

local function getKey(player)
    return "Player_" .. player.UserId
end

-- Load player data from DataStore, or initialize if not found
local function loadPlayerData(player)
    local key = getKey(player)
    local success, result = pcall(function()
        return SaveDataStore:GetAsync(key)
    end)
    if success and result then
        SaveS:UpdateAll(player, result)
        -- loaded from DataStore
    else
        if not success then
            warn("[SaveManager] Failed to load DataStore for", player.Name, "->", result)
        end
        SaveS:InitPlayer(player)
        -- initialized default data
    end
end

-- Save player data to DataStore
local function savePlayerData(player)
    local data = SaveS:GetAll(player)
    if data then
        local success, err = pcall(function()
            SaveDataStore:SetAsync(getKey(player), data)
        end)
        if not success then
            warn("[SaveManager] Failed to save DataStore for", player and player.Name, "->", err)
        end
    end
end

-- Periodically save all players' data
local function autoSaveLoop()
    while true do
        wait(60)
        for _, player in ipairs(Players:GetPlayers()) do
            savePlayerData(player)
        end
        -- periodic save completed
    end
end

-- Listen for player join/leave
Players.PlayerAdded:Connect(function(player)
    loadPlayerData(player)
end)

Players.PlayerRemoving:Connect(function(player)
    savePlayerData(player)
    SaveS:RemovePlayer(player)
end)

-- Start periodic save loop
task.spawn(autoSaveLoop)
