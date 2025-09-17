local module = {}

local sharedTableRegistry = game:GetService("SharedTableRegistry")

local factionsTable = {}
local sTable = SharedTable.new(factionsTable)
sharedTableRegistry:SetSharedTable("factionKnowledge",sTable)



function module.updateKnowledgeBase(rig)
	if rig then
		local behaviorHandler = rig:FindFirstChild("BehaviorHandler")
		if behaviorHandler then
			local targetFaction = rig.BehaviorHandler.Configuration.Faction.Value
			if factionsTable[targetFaction] == nil then
				factionsTable[targetFaction] = {}
				factionsTable[targetFaction].possibleEnemies = {}
				factionsTable[targetFaction].possibleAllies = {}
			end
		end
	end
	
	for factionName, faction in factionsTable do
		faction.possibleEnemies = {}
		faction.possibleAllies = {}
		for index, item in workspace.ENTITIES:GetChildren() do
			if item:FindFirstChild("BehaviorHandler") then
				if item.BehaviorHandler.Configuration.Faction.Value ~= factionName or item.BehaviorHandler.Configuration.Faction.Value == "" then
					table.insert(faction.possibleEnemies,index)
				elseif item.BehaviorHandler.Configuration.Faction.Value == factionName then
					table.insert(faction.possibleAllies,index)
				end
			elseif item:FindFirstChildOfClass("Humanoid") then
				table.insert(faction.possibleEnemies,index)
			end
		end
	end
	
	local sTable = SharedTable.new(factionsTable)
	sharedTableRegistry:SetSharedTable("factionKnowledge",sTable)
end


return module
