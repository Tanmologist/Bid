-- SyncFire.client.luau
-- Handles one-way sync: receives Save and Flow data from server

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require the three data modules
local Save = require(script.Parent:WaitForChild("Save"))
local Flow = require(script.Parent:WaitForChild("Flow"))
local Local = require(script.Parent:WaitForChild("Local"))

-- Wait for server to create the RemoteEvents
local function waitForRemoteEvent(eventName)
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    return remotes:WaitForChild(eventName)
end

-- Get the RemoteEvents (server must create these first)
local SaveDataRemote = waitForRemoteEvent("SaveDataRemote")
local FlowDataRemote = waitForRemoteEvent("FlowDataRemote")

print("[SyncFire] Connected to server events")


-- Listen for Save data from server
SaveDataRemote.OnClientEvent:Connect(function(messageType, data)
    if messageType == "UpdateSave" then
        for k, v in pairs(data) do
            Save:Set(k, v)
        end
        print("[SyncFire] Received Save data from server:", data)
    end
end)

-- Listen for Flow data from server
FlowDataRemote.OnClientEvent:Connect(function(messageType, data)
    if messageType == "UpdateFlow" then
        for k, v in pairs(data) do
            Flow:Set(k, v)
        end
        print("[SyncFire] Received Flow data from server:", data)
    end
end)

-- Local data doesn't sync to server (client-only)
Local:OnChanged(function(key, value)
    print("[SyncFire] Local data changed:", key, "=", value, "(client-only)")
end)