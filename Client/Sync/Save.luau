-- Save.luau
-- Tier 1: Database storage - persistent important data

local Save = {
    Money = 0,
    SelectedCharacter = "C1" -- Default character
}

-- Event for save data changes
local SaveChanged = Instance.new("BindableEvent")

-- Function to update save data and notify listeners
function Save:Set(key, value)
    if self[key] ~= value then
        self[key] = value
        SaveChanged:Fire(key, value)
        print("[Save] Updated", key, "to:", value)
    end
end

-- Function to listen for save data changes
function Save:OnChanged(callback)
    SaveChanged.Event:Connect(callback)
end

return Save