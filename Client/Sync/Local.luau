local Local = {}

-- Whether player is currently fishing (legacy compatibility)
Local.IsFishing = false

-- Whether player is in the shake checking phase
Local.Shake = false

-- Event for local data changes
local LocalChanged = Instance.new("BindableEvent")


-- Function to update local data and notify listeners

function Local:Set(key, value)
    -- Prevent redundant Shake true
    if key == "Shake" and value == true and self.Shake == true then
        return
    end
    if self[key] ~= value then
        self[key] = value
        LocalChanged:Fire(key, value)
        print("[Local] Updated", key, "to:", value)
    end
end

-- Function to listen for local data changes
function Local:OnChanged(callback)
    LocalChanged.Event:Connect(callback)
end

return Local
