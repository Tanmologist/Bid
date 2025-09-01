-- TEMP / DEPRECATED server-side money handler
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Require server-side SaveS module
local SaveS = require(script.Parent:WaitForChild("SyncS"):WaitForChild("SaveS"))

-- Ensure MoneyChangeRemote exists on server
local Remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
Remotes.Name = "Remotes"
Remotes.Parent = ReplicatedStorage

local MoneyChangeRemote = Remotes:FindFirstChild("MoneyChangeRemote")
if not MoneyChangeRemote then
    MoneyChangeRemote = Instance.new("RemoteEvent")
    MoneyChangeRemote.Name = "MoneyChangeRemote"
    MoneyChangeRemote.Parent = Remotes
end

-- Ensure SaveDataRemote exists to sync data to client
local SaveDataRemote = Remotes:FindFirstChild("SaveDataRemote")
if not SaveDataRemote then
    SaveDataRemote = Instance.new("RemoteEvent")
    SaveDataRemote.Name = "SaveDataRemote"
    SaveDataRemote.Parent = Remotes
end

-- After change, sync the whole Save table to the client
local function sendSaveDataToPlayer(player)
    local data = SaveS:GetAll(player)
    if data then
        SaveDataRemote:FireClient(player, "UpdateSave", data)
    print("[lingshic] Synced Save table to client", player.Name, data)
    end
end

-- Listen to MoneyChangeRemote
MoneyChangeRemote.OnServerEvent:Connect(function(player, delta)
    -- Only allow number type
    if typeof(delta) ~= "number" then return end
    -- Server-side safe money add/sub
    local old = SaveS:Get(player, "Money") or 0
    local new = old + delta
    SaveS:Set(player, "Money", new)
    print("[lingshic] Player", player.Name, "money changed:", old, "->", new)
    -- After change, sync Save table to client
    sendSaveDataToPlayer(player)
end)
