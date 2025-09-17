local handler = {}

local replicatedStorage = game:GetService("ReplicatedStorage")

local remotes = replicatedStorage:WaitForChild("Remotes")
local hitregRemote = remotes:WaitForChild("hitregRemote")
local suppressRemote = remotes:WaitForChild("suppressRemote")


local damageHandler = require(game.ReplicatedStorage.Modules.damageHandler)
local projectileBase = require(script.Parent.ProjectileBase)

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

local function castHit(projectile,castOrigin,castDirection)
	local raycastParams = RaycastParams.new()
	local sender = workspace.ENTITIES:GetChildren()[projectile.senderID]
	raycastParams.FilterDescendantsInstances = {sender}
	while true do
		local raycastResult = workspace:Raycast(castOrigin,castDirection,raycastParams)
		if not raycastResult then
			return nil
		else --ray hit something, check whether or not to start a new round of iteration
			local castInstance = raycastResult.Instance
			if (castInstance.Transparency ~= 1 and castInstance.CanCollide == true) or string.sub(castInstance.Name,#castInstance.Name-2,#castInstance.Name) == "Leg" or string.sub(castInstance.Name,#castInstance.Name-2,#castInstance.Name) == "Arm" or castInstance.Name == "Head" or castInstance.Name == "Torso" then  --only non transparent parts with collision will be registered
				return raycastResult
			else 
				local newParameters = raycastParams.FilterDescendantsInstances
				table.insert(newParameters,raycastResult.Instance)
				raycastParams.FilterDescendantsInstances = newParameters
			end
		end
	end
end

local function onHit(projectile,raycastResult)
	if raycastResult.Instance.Parent:FindFirstChildOfClass("Humanoid") then
		local castInfo = {
			baseDamage = projectile.baseDamage,
			damageType = projectile.damageType,
			headshotMultiplier = projectile.headshotMultiplier or 2.0,
			limbshotMultiplier = projectile.limbshotMultiplier or 0.8,
			shotDistance = (projectile.startPosition-raycastResult.Position).Magnitude
		}
		if raycastResult.Instance.Name == "Head" then
			castInfo.shotLimb = "Head"
		elseif raycastResult.Instance.Name == "Left Arm" or raycastResult.Instance.Name == "Right Arm" then
			castInfo.shotLimb = "Arm"
		elseif raycastResult.Instance.Name == "Left Leg" or raycastResult.Instance.Name == "Right Leg" then
			castInfo.shotLimb = "Leg"
		else
			castInfo.shotLimb = "Torso"
		end

		damageHandler.castDamage(workspace.ENTITIES:GetChildren()[projectile.senderID],raycastResult.Instance.Parent,castInfo)
	end
end

local function onStep(projectile,dt,index)
	local currentPos = projectile.position
	local nextPos = projectile.position + (projectile.velocity * dt)
	--hitregRemote:FireAllClients("update",self)
	local hitPart = castHit(projectile,currentPos,(projectile.velocity * dt))
	if hitPart then
		onHit(projectile,hitPart)
		hitregRemote:FireAllClients("destroy",deepCopy(projectile),{hitPart.Position,hitPart.Normal,hitPart.Instance})
		projectileBase.removeProjectile(index)
		return hitPart
	else
		projectile.position = nextPos
		projectile.lifetime -= dt
		if projectile.lifetime <= 0 then
			hitregRemote:FireAllClients("destroy",deepCopy(projectile),nil)
			projectileBase.removeProjectile(index)
			return "kill"
		end
	end 
end












function handler.new(startPosition:Vector3,castDirection:Vector3,projectileInfo:any)
	local projectile = {
		startPosition = startPosition,
		
		position = startPosition,
		velocity = projectileInfo.velocity * castDirection.Unit,
		baseDamage = projectileInfo.baseDamage,
		damageType = projectileInfo.damageType,
		headshotMultiplier = projectileInfo.headshotMultiplier or 2.0,
		limbshotMultiplier = projectileInfo.limbshotMultiplier or 0.8,
		suppression = projectileInfo.suppression or 10,
		lifetime = 3,
		
		modelID = projectileInfo.modelID,
		senderID = 0,
		senderName = projectileInfo.sender.Name
	}
	
	for index, model in workspace.ENTITIES:GetChildren() do
		if model == projectileInfo.sender then
			projectile.senderID = index
		end
	end
	
	projectileBase.addProjectile(projectile)
end

function handler.onStep(dt)
	local oldBase = projectileBase.getProjectiles()
	for index, projectile in oldBase do

		local hit = onStep(projectile,dt,index)
		if hit == "kill" then
			table.remove(oldBase,index)
		elseif hit then
			for index, rig in workspace.ENTITIES:GetChildren() do
				local dist = (rig.HumanoidRootPart.Position - hit.Position).Magnitude
				if rig:FindFirstChild("BehaviorHandler") and dist < projectile.suppression then
					local sender = workspace.ENTITIES:GetChildren()[projectile.senderID]
					rig.BehaviorHandler:FindFirstChildOfClass("Script").rigEvent:Fire("suppress",sender)
				end
			end
			suppressRemote:FireAllClients(hit.Position,projectile.suppression)
			
			table.remove(oldBase,index)
		end
	end
	if #oldBase > 0 then handler.fireAllClients() end
	
	projectileBase.setProjectiles(oldBase)
end

function handler.fireAllClients()
	local whowhee = {}
	for index, projectile in projectileBase.getProjectiles() do
		table.insert(whowhee,deepCopy(projectile))
	end
	
	hitregRemote:FireAllClients("updateAll",whowhee)
end


return handler