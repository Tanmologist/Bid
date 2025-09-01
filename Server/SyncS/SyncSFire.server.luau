-- SyncSFire.server.luau
-- Handles two-way sync between server and clients using server modules

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Require server-side data modules
local SaveS = require(script.Parent:WaitForChild("SaveS"))
local FlowS = require(script.Parent:WaitForChild("FlowS"))

-- Obtain centrally created remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SaveDataRemote = Remotes:WaitForChild("SaveDataRemote")
local FlowDataRemote = Remotes:WaitForChild("FlowDataRemote")

-- Storage for each player's data - now handled by modules
-- local PlayerSaveData = {}  -- Replaced by SaveS module
-- local PlayerFlowData = {}  -- Replaced by FlowS module

-- Register change listeners and auto sync entire table to client
SaveS:OnChanged(function(player, key, value)
    sendSaveDataToPlayer(player)
end)
FlowS:OnChanged(function(player, key, value)
    sendFlowDataToPlayer(player)
end)

local function initializePlayerData(player)
    -- Initialize only if missing (avoids overwriting DataStore-loaded data)
    SaveS:InitPlayer(player)
    FlowS:InitPlayer(player)
    print("[Server] Initialized (or confirmed) data for player:", player.Name)
end

local function cleanupPlayerData(player)
    -- Remove in-memory data only
    SaveS:RemovePlayer(player)
    FlowS:RemovePlayer(player)
    print("[Server] Cleaned up data for player:", player.Name)
end


-- Send Save data to specific player
function sendSaveDataToPlayer(player)
    local data = SaveS:GetAll(player)
    if data then
        SaveDataRemote:FireClient(player, "UpdateSave", data)
        print("[Server] Sent Save data to", player.Name, ":", data)
    end
end

-- Send Flow data to specific player
function sendFlowDataToPlayer(player)
    local data = FlowS:GetAll(player)
    if data then
        FlowDataRemote:FireClient(player, "UpdateFlow", data)
        print("[Server] Sent Flow data to", player.Name, ":", data)
    end
end



-- Player management
Players.PlayerAdded:Connect(function(player)
    initializePlayerData(player)
    
    -- Send initial data to client after a short delay
    wait(2)
    sendSaveDataToPlayer(player)
    sendFlowDataToPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
    cleanupPlayerData(player)
end)