-- SaveS.luau
-- Server-side Save data module - corresponds to client Save.luau, with DataStore support.
-- NOTE: Keys use player.UserId (number) to avoid retaining Player object references.

local SaveS = {}

local DEBUG = false
local function log(...)
    if DEBUG then
        print("[SaveS]", ...)
    end
end

-- Storage for all players' save data; map userId -> data table
local PlayersData: { [number]: { Money: number, SelectedCharacter: string } } = {}

local SaveChanged = Instance.new("BindableEvent")



function SaveS:InitPlayer(player)
    local uid = player.UserId
    -- Idempotent: do not overwrite existing data (prevents DataStore load being clobbered)
    if PlayersData[uid] then return end
    PlayersData[uid] = { Money = 0, SelectedCharacter = "C1" }
    log("Initialized save data for", player.Name)
end

function SaveS:RemovePlayer(player)
    PlayersData[player.UserId] = nil
    log("Removed save data for", player.Name)
end

-- Set data for specific player (auto-save)
function SaveS:Set(player, key, value)
    local uid = player.UserId
    local data = PlayersData[uid]
    if not data then return end
    if data[key] ~= value then
        data[key] = value
        SaveChanged:Fire(player, key, value)
        log("Updated", player.Name, key, "to:", value)
        -- No immediate DataStore write; periodic/on-exit only
    end
end

-- Get data for specific player
function SaveS:Get(player, key)
    local data = PlayersData[player.UserId]
    if not data then return nil end
    return data[key]
end

-- Get all data for specific player
function SaveS:GetAll(player)
    return PlayersData[player.UserId]
end

-- Update all data for specific player (from client sync, auto-save)
-- Update all data for specific player (from client sync, no immediate save)
function SaveS:UpdateAll(player, data)
    local uid = player.UserId
    if PlayersData[uid] then
        PlayersData[uid] = data
        SaveChanged:Fire(player, "ALL", data)
        log("Updated all data for", player.Name)
    end
end

-- Listen for save data changes
function SaveS:OnChanged(callback)
    return SaveChanged.Event:Connect(callback)
end


return SaveS
