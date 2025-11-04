--THIS MODULE SHOULD ONLY CONTAIN REDUNDANT DATA THAT ALL KITTIES HAVE ACCESS TO
--PUTTING RANDOM STUFF WILL INDUCE TELEPATHY AND CAUSE KITTENS TO BECOME KITS
--WE DO NOT WANT THAT

local KITTYBoard = {
    worldEvents = {},
    coverPoints = {},
    entitiesByFaction = {},
    time = 0,
    gridSize = 32
}
KITTYBoard.__index = KITTYBoard

function KITTYBoard:updateEntities()
    KITTYBoard.entitiesByFaction = {}
    for _, rig in workspace.ENTITIES:GetChildren() do
        local faction = rig:FindFirstChild("Faction")
        if not faction then
            if not self.entitiesByFaction["Neutral"] then self.entitiesByFaction["Neutral"] = {} end
            table.insert(self.entitiesByFaction["Neutral"],rig)
        else
            if not self.entitiesByFaction[faction.Value] then self.entitiesByFaction[faction.Value] = {} end
            table.insert(self.entitiesByFaction[faction.Value],rig)
        end
    end
end

function KITTYBoard:Update(dt)
    self.time += dt

    for name, event in self.worldEvents do
        if event.expireAt <= self.time then self.worldEvents[name] = nil end
    end
end

--have to allow multiple events to exist under the same name, like multiple firing sound instances, or do i have to? What are the chances of two people firing in the same frame.
function KITTYBoard:addEvent(eventName,duration,eventOrigin,eventData)
    self.worldEvents[eventName] = {expireAt = self.time + duration, origin = eventOrigin, data = eventData}
end



return KITTYBoard