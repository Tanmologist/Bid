local projectileBase = {}

local sharedTableRegistry = game:GetService("SharedTableRegistry")
local sTable = SharedTable.new({})
sharedTableRegistry:SetSharedTable("projectileBase",sTable)

local function deepCopy(previous)
	local copy = {}
	for key, value in previous do
		if type(value) == "table" then
			value = deepCopy(value)
		end
		copy[key] = value
	end
	
	return copy
end


function projectileBase.addProjectile(projectile)
	local previousBase = deepCopy(sharedTableRegistry:GetSharedTable("projectileBase"))
	table.insert(previousBase,projectile)
	
	local sTable = SharedTable.new(previousBase)
	sharedTableRegistry:SetSharedTable("projectileBase",sTable)
end

function projectileBase.removeProjectile(index)
	local previousBase = deepCopy(sharedTableRegistry:GetSharedTable("projectileBase"))
	table.remove(previousBase,index)
	
	local sTable = SharedTable.new(previousBase)
	sharedTableRegistry:SetSharedTable("projectileBase",sTable)
end

function projectileBase.getProjectiles()
	local previousBase = sharedTableRegistry:GetSharedTable("projectileBase")
	local currentBase = deepCopy(previousBase)
	
	return currentBase
end

function projectileBase.setProjectiles(newProjectileBase)
	local sTable = SharedTable.new(newProjectileBase)
	sharedTableRegistry:SetSharedTable("projectileBase",sTable)
end

return projectileBase
