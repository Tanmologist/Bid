-- FlowS.luau
-- Server-side Flow data module - corresponds to client Flow.luau

local FlowS = {}
local DEBUG = false
local function log(...)
    if DEBUG then
        print("[FlowS]", ...)
    end
end

-- Storage for all players' flow data
local PlayersData = {} -- [UserId] = { ... }

-- Event for flow data changes
local FlowChanged = Instance.new("BindableEvent")

-- Initialize player data
function FlowS:InitPlayer(player)
    local uid = player.UserId
    if PlayersData[uid] then return end
    PlayersData[uid] = { Air = 100 }
    log("Initialized flow data for", player.Name)
end

-- Remove player data
function FlowS:RemovePlayer(player)
    PlayersData[player.UserId] = nil
    log("Removed flow data for", player.Name)
end

-- Set data for specific player
function FlowS:Set(player, key, value)
    local uid = player.UserId
    local data = PlayersData[uid]
    if not data then return end
    if data[key] ~= value then
        data[key] = value
        FlowChanged:Fire(player, key, value)
        log("Updated", player.Name, key, "to:", value)
    end
end

-- Get data for specific player
function FlowS:Get(player, key)
    local data = PlayersData[player.UserId]
    if not data then return nil end
    return data[key]
end

-- Get all data for specific player
function FlowS:GetAll(player)
    return PlayersData[player.UserId]
end

-- Update all data for specific player (from client sync)
function FlowS:UpdateAll(player, data)
    local uid = player.UserId
    if PlayersData[uid] then
        PlayersData[uid] = data
        FlowChanged:Fire(player, "ALL", data)
        log("Updated all data for", player.Name)
    end
end

-- Listen for flow data changes
function FlowS:OnChanged(callback)
    return FlowChanged.Event:Connect(callback)
end

return FlowS
