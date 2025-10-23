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
end



return KITTYBoard