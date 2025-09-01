-- Flow.luau
-- Tier 2: Server sync only - temporary server-relevant data

local Flow = {
    Air = 100
}

-- Event for flow data changes
local FlowChanged = Instance.new("BindableEvent")

-- Function to update flow data and notify listeners
function Flow:Set(key, value)
    if self[key] ~= value then
        self[key] = value
        FlowChanged:Fire(key, value)
        print("[Flow] Updated", key, "to:", value)
    end
end

-- Function to listen for flow data changes
function Flow:OnChanged(callback)
    FlowChanged.Event:Connect(callback)
end

return Flow
