local pfs = game:GetService("PathfindingService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local kittyBoard = require(script.Parent.KITTYBoard)

local KITTY = {}
KITTY.__index = KITTY
--KITTY refers to "Komplicated Intelligence in Tactics without TelepathY", :D
--objects of KITTY class are referred to kittens

--General functions
-- KITTY module
function KITTY:New(rig)
    local kitten = {
        stats = { --read only stuff
            FOV = 40,
            maxSightingRange = 200,

            baseDamge = 10,
            damageType = "Physical",

            reactionTime = 0.5,
            aimTime = 0.1,
            accuracy = 0.1 --percent of shots that will land ontarget
        },
        
        core = {
            facts  = {},      -- timed facts
            visibleEnemies = {},
            now    = 0,
            wantsMove = nil,
            wantsLook = nil,
        },
        rig = rig,
        faction = nil,
        tree = nil,
    }
    setmetatable(kitten, KITTY)
    kitten.mover.rig = rig
    
    return kitten
end

-- one public heartbeat call
function KITTY:Update(dt)
    self:See()
    self.mover:Update(dt)

    -- update timers
    self.core.now = self.core.now + dt
    for name, f in pairs(self.core.facts) do
        if f.expireAt <= self.core.now then self.core.facts[name] = nil end
    end
    -- tick brain
    if self.tree then self.tree:Update(self, dt) end
end

-- helper: add / query facts
function KITTY:addFact(name, duration, priority, data)
    self.core.facts[name] = {expireAt = self.core.now + duration, priority = priority or 5, data = data}
end

function KITTY:factActive(name) return self.core.facts[name] ~= nil end


















--KITTY base functions like moving and stuff
-------------------------------------------------------------
-------------------------------------------------------------
-------------------------------------------------------------
-------------------------------------------------------------
-------------------------------------------------------------
-------------------------------------------------------------
-------------------------------------------------------------
-------------------------------------------------------------

--KITTY'S EYES
-------------------------------------------------------------
-------------------------------------------------------------
function KITTY:See()
    local head = self.rig.Head
    if not head then return end

    local function castHit(rig,castOrigin,castDirection) --the point of this is to make raycast ignore accessory parts and parts with no collision
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {rig}

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
	
	local function checkIfVisible(part)
		local headAngle = head.CFrame.LookVector
		local partAngle = (part.Position - head.Position)

		if partAngle.Magnitude > self.stats.maxSightingRange then
			return nil
		else
			local dotProduct = headAngle:Dot(partAngle)
			local viewAngle = math.deg(math.acos(dotProduct/(headAngle.Magnitude*partAngle.Magnitude)))

			if viewAngle > self.stats.FOV/2 then
				return nil
			else
				local raycastResult = castHit(self.rig,head.Position,partAngle.Unit*self.stats.maxSightingRange)
				if raycastResult and raycastResult.Instance == part then
					return raycastResult.Instance
				end
			end
		end
	end

    self.core.visibleEnemies = {}
    --a filter with increasing cost as you go down. Most entities get passed on first few layers
    local entityList = kittyBoard.entitiesByFaction
    for _,faction in entityList do
        if faction ~= self.faction or self.faction == nil then
            for _,rig in faction do
                if checkIfVisible(rig.Torso) and rig.Humanoid.Health > 0 then
                    local dist = (rig.Torso.Position - head.Position).Magnitude
                    table.insert(self.core.visibleEnemies, {rig = rig, distance = dist})
			    end
            end
        end
    end

    table.sort(self.core.visibleEnemies, function(a, b) return a.distance < b.distance end)
end
-------------------------------------------------------------
-------------------------------------------------------------



--KITTY's legs
-------------------------------------------------------------
-------------------------------------------------------------
KITTY.mover= 
{
    moving = false,
    interruptReached = false,
    interruptTimeout = 0,

    movementQueue = {},
    coreLocations = {},
    waypoints = {},

    rig = nil
}

function KITTY.mover:moveTo(targetPosition)
	self.moving = true
	repeat self.rig.Humanoid:MoveTo(targetPosition) until self.rig.Humanoid.MoveToFinished:Wait()
	self.moving = false
end 

function KITTY.mover:Update(dt)
    local humanoid = self.rig.Humanoid
    local root = self.rig.HumanoidRootPart

    if self.moving == false and #self.waypoints > 0 then
		local targetPosition = self.waypoints[1]
		if targetPosition == self.coreLocations[1] then
			table.remove(self.coreLocations,1)
		end
		table.remove(self.waypoints,1)
		self:moveTo(targetPosition)
			
		if not self.interruptReached then
			self.interruptReached = true
			
			local locations = table.clone(self.coreLocations)
			table.clear(self.coreLocations)
			for _,v in locations do
				self.movementQueue.addLocation(v) --resume regular  movement queue
			end
		end		
	end
		
	self.interruptTimeout = math.clamp(self.interruptTimeout - dt,0,10)
	if self.interruptTimeout == 0 and self.interruptReached == false then --interrupt failed to execute
		humanoid:MoveTo(root.Position)
	end
end

function KITTY.mover:addLocation(endPosition)
    local humanoid = self.rig.Humanoid
    local root = self.rig.HumanoidRootPart

    local startPosition
    if #self.waypoints == 0 then
        startPosition = root.Position
    elseif #self.coreLocations == 0 then
        startPosition = self.waypoints[#self.waypoints]
    else
        startPosition = self.coreLocations[#self.coreLocations]
    end
    table.insert(self.coreLocations,endPosition)
    
    task.synchronize()
    local path = pfs:CreatePath({
        AgentCanJump = false,
        AgentRadius = 3,
    })
    
    path:ComputeAsync(startPosition,endPosition)
    for _,waypoint in path:GetWaypoints() do
        table.insert(self.waypoints,waypoint.Position)
    end
end

function KITTY.mover:newLocation(endPosition)
    table.clear(self.waypoints)
    table.clear(self.coreLocations)
    self:addLocation(endPosition)
end

function KITTY.mover:Interrupt(position,timeout)
    local humanoid = self.rig.Humanoid
    local root = self.rig.HumanoidRootPart

    humanoid:MoveTo(root.Position)

    self.interruptReached = false
	if not timeout then
		self.interruptTimeout = 10
	else
		self.interruptTimeout = timeout
	end
		
	self.waypoints[1] = position
end

function KITTY.mover:getDestination()
    return self.waypoints[#self.waypoints]
end

function KITTY.mover:Stop()
	self.moving = false
	self.newLocation(self.rig.HumanoidRootPart.Position)
end
-------------------------------------------------------------
-------------------------------------------------------------


--kitty's orientation. This part needs revamping.
-------------------------------------------------------------
-------------------------------------------------------------





-------------------------------------------------------------
-------------------------------------------------------------
-------------------------------------------------------------
-------------------------------------------------------------
-------------------------------------------------------------
-------------------------------------------------------------


return KITTY