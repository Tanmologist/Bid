local projectileBehavior = require(script.Parent.ProjectileHitBehavior)

local remotes = game.ReplicatedStorage:WaitForChild("Remotes")
local hitregRemote = remotes:WaitForChild("hitregRemote")

local handler = {}
local projectiles = {}

local Projectile = {}
Projectile.__index = Projectile

local function castHit(sender,castOrigin,castDirection)
	local raycastParams = RaycastParams.new()
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






function Projectile:New(startPosition:Vector3,castDirection:Vector3,projectileInfo:any)
    local projectile = {
		startPosition = startPosition,

		position = startPosition,
		velocity = projectileInfo.velocity * castDirection.Unit,

		baseDamage = projectileInfo.baseDamage,
		damageType = projectileInfo.damageType,
		headshotMultiplier = projectileInfo.headshotMultiplier or 2.0,
		limbshotMultiplier = projectileInfo.limbshotMultiplier or 0.8,
		suppression = projectileInfo.suppression or 10,
		lifetime = 2,
		
		model = projectileInfo.model,
		sender = projectileInfo.sender,
		senderName = projectileInfo.sender.Name,
		id = `p{workspace:GetServerTimeNow() * 1000}{math.random(1000, 9999)}`,

		hitBehavior = projectileInfo.hitBehavior or "standard",
	}

	local packet = {
		id = projectile.id,
		origin    = projectile.startPosition,
		vel       = projectile.velocity,
		t0        = workspace:GetServerTimeNow(),  -- global sync point
		behaviour = projectile.hitBehavior,
		senderID = projectile.sender.Name,
		lifetime = projectile.lifetime
	}
	hitregRemote:FireAllClients("spawn", packet)

    setmetatable(projectile, Projectile)
    return projectile
end

function Projectile:Update(dt)
    local currentPos = self.position
	local nextPos = self.position + (self.velocity * dt)

    local raycastResult = castHit(self.sender,currentPos,(self.velocity * dt))
    if raycastResult then
		local onHit = projectileBehavior.getServerBehavior("standard")
		onHit(self,raycastResult)

		hitregRemote:FireAllClients("landed", {
			id   = self.id,
			pos  = raycastResult.Position,
			norm = raycastResult.Normal,
			part = raycastResult.Instance
		})
		
		projectiles[self.id] = nil
	else
		--normal update
		self.position = nextPos
		self.lifetime -= dt
		if self.lifetime <= 0 then --projectile exists for too long
			hitregRemote:FireAllClients("remove",{id = self.id})
			projectiles[self.id] = nil
		end
	end 
end

function handler.Update(dt)
	for index,item in pairs(projectiles) do
		item:Update(dt)
	end
end

function handler.New(castOrigin,castDirection,castInfo)
	local newProjectile = Projectile:New(castOrigin,castDirection,castInfo)
	projectiles[newProjectile.id] = newProjectile
end

return handler