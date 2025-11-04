local pfs = game:GetService("PathfindingService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local kittyBoard = require(script.Parent.KITTYBoard)
local chunkyCover = require(script.Parent.chunkyCover)

local KITTY = {}
KITTY.__index = KITTY
--KITTY refers to "Komplicated Intelligence in Tactics without TelepathY", :D
--objects of KITTY class are referred to kittens

--General functions
-- KITTY module
function KITTY:New(rig)
    local kitten = {
        stats = { --read only stuff
            FOV = 120, --detection related
            maxSightingRange = 200,
            maxHearingRange = 30,
			combatBuffer = 15, --time it takes before enemies deem it safe
            reactionTime = 0.5,

            walkSpeed = 12, --movement related
            sprintSpeed = 18,

            maxHealth = 100, --health related, not all are implemented yet, not all will be implemented for BID
            resilence = 10, --how much damage do they have to take at once to flinch
            morale = 50, --default morale, will retreat when low
            fear = 10, --default fear, will cause AI to panic when low

            defaultAnims = {
                movement = {
                    idleAnim = "rbxassetid://91889942823577",
			        walkAnim = "rbxassetid://113345430559319",
                    spinRightAnim = "rbxassetid://106548158517632",
		            spinLeftAnim = "rbxassetid://117261819476231",
                }
            }
        },

        core = {
            facts  = {},      -- timed facts
            visibleEnemies = {},
            now    = 0,
            wantsMove = nil,
            wantsLook = nil,

            spinOffset = CFrame.new(),
            movementOffset = CFrame.new(),
            armOffset = CFrame.new(0,-1.5,0)
        },

        rig = rig,
        faction = nil,
        tree = nil,
    }
    setmetatable(kitten, KITTY)
    kitten:initAnim()
    kitten:initMover()

    rig:FindFirstChildOfClass("Humanoid").AutoRotate = false

    return kitten
end

-- one public heartbeat call
function KITTY:Update(dt)
    self:See()
    self.mover:Update(dt)
    self:tiltChar(dt)
    self.anim:updateAnim()
	
	chunkyCover:UpdateChunkForPosition(self.rig.HumanoidRootPart.Position)

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

function KITTY:removeFact(name)
	self.core.facts[name] = nil
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
                local humanoid = rig:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 and checkIfVisible(rig.Torso) then
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
local KITTYMover = 
{
    moving = false,
    interruptReached = false,
    interruptTimeout = 0,

    coreLocations = {},
    waypoints = {}
}
KITTYMover.__index = KITTYMover

function KITTYMover:moveTo(targetPosition)
	self.moving = true
	repeat self.rig.Humanoid:MoveTo(targetPosition) until self.rig.Humanoid.MoveToFinished:Wait()
	self.moving = false
end 

function KITTYMover:Update(dt)
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
				self:addLocation(v) --resume regular  movement queue
			end
		end		
	end
		
	self.interruptTimeout = math.clamp(self.interruptTimeout - dt,0,10)
	if self.interruptTimeout == 0 and self.interruptReached == false then --interrupt failed to execute
		humanoid:MoveTo(root.Position)
	end
end

function KITTYMover:addLocation(endPosition)
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

    local path = pfs:CreatePath({
        AgentCanJump = false,
        AgentRadius = 3,
    })
    
    path:ComputeAsync(startPosition,endPosition)
    for _,waypoint in path:GetWaypoints() do
        table.insert(self.waypoints,waypoint.Position)
    end
end

function KITTYMover:newLocation(endPosition)
    table.clear(self.waypoints)
    table.clear(self.coreLocations)
    self:addLocation(endPosition)
end

function KITTYMover:Interrupt(position,timeout)
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

function KITTYMover:getDestination()
    return self.waypoints[#self.waypoints]
end

function KITTYMover:Stop()
	self.moving = false
	self:newLocation(self.rig.HumanoidRootPart.Position)
end

function KITTY:initMover()
    self.mover = setmetatable({rig = self.rig, stats = self.stats}, KITTYMover)
end
-------------------------------------------------------------
-------------------------------------------------------------


--kitty's orientation. Revamping complete.
-------------------------------------------------------------
-------------------------------------------------------------
function KITTY:updateSpinOffset(dt)
    local root  = self.rig:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local aimPos = self.core.wantsLook or (root.CFrame * CFrame.new(0,1.5,-5)).Position
	local aimVector = CFrame.lookAt(self.rig.Head.position,aimPos)

    local _,y   = aimVector:ToEulerAnglesYXZ()
    local _,rootY  = root.CFrame.Rotation:ToEulerAnglesYXZ()
    local _,spinY  = self.core.spinOffset:ToEulerAnglesYXZ()

    local spinDelta = math.deg((y - spinY + math.pi) % (2 * math.pi) - math.pi)
    local maxDelta  = 100

    if math.abs(spinDelta) > maxDelta then
        if spinDelta < 0 then
            self.anim:playAnim("spinLeftAnim")
        else
            self.anim:playAnim("spinRightAnim")
        end
        root.CFrame = root.CFrame:Lerp(CFrame.new(root.Position) * CFrame.Angles(0, y, 0), 0.4 * dt * 60)

        if math.abs(math.deg(y - rootY)) < 5 then
            self.core.spinOffset = root.CFrame
        end
    elseif root.AssemblyLinearVelocity.Magnitude > 0.5 then
        root.CFrame = root.CFrame:Lerp(CFrame.new(root.Position) * CFrame.Angles(0, y, 0), 0.2 * dt * 60)
        self.core.spinOffset = root.CFrame
    else
        local startCFrame = CFrame.new(root.Position) * CFrame.Angles(0,spinY,0)
		root.CFrame = startCFrame:Lerp(CFrame.new(root.Position) * CFrame.Angles(0,y,0),2/3)
    end
end


local riseMagnitude = 1
local RC0 = CFrame.new(1, .5, 0, 0, 0, riseMagnitude, 0, riseMagnitude, 0, -riseMagnitude, 0, 0)
local LC0 = CFrame.new(-1, .5, 0, 0, 0, -riseMagnitude, 0, riseMagnitude, 0, riseMagnitude, 0, 0)
local NC0 = CFrame.new( 0, 1, 0, -1, -0, -0, 0, 0, 1, 0, 1, 0)
local TC0 = CFrame.new(0, 0, 0, -1, -0, -0, 0, 0, 1, 0, 1, 0)
local LHC0 = CFrame.new(-1, -1, 0, -0, -0, -1, 0, 1, 0, 1, 0, 0)
local RHC0 = CFrame.new(1, -1, 0, 0, 0, 1, 0, 1, 0, -1, -0, -0)

function KITTY:tiltChar(dt)
    self:updateSpinOffset(dt)

    local movementOffset = self.core.movementOffset --* self.core.movementOffset
    --print(movementOffset)

    local character = self.rig
    local lookVector = self.core.wantsLook or (character.HumanoidRootPart.CFrame * CFrame.new(0,1.5,-5)).Position

    local lookCFrame = CFrame.lookAt(character.Head.Position, lookVector)

	if character:FindFirstChild("Torso") == nil or character.Torso:FindFirstChild("Neck") == nil then return CFrame.new(0,0,0) end
	local neck = character.Torso:FindFirstChild("Neck")
	local torso = character.HumanoidRootPart:FindFirstChild("RootJoint")

	local x,y,z = character.HumanoidRootPart.RootJoint.Transform:ToOrientation()

	local rShoulder = character.Torso["Right Shoulder"]
	local lShoulder = character.Torso["Left Shoulder"]
	local rHip = character.Torso["Right Hip"]
	local lHip = character.Torso["Left Hip"]
    
	local rootVelocity = character.HumanoidRootPart.CFrame:VectorToObjectSpace(character.HumanoidRootPart.Velocity)
	movementOffset = movementOffset:Lerp(CFrame.Angles(0,0,-(rootVelocity.X/rootVelocity.Magnitude)/2),0.2)
    
	
	local spinDelta = 0
	if rootVelocity.Magnitude < 0.5 and self.core.spinOffset then
		local _, y = lookCFrame.Rotation:ToEulerAnglesYXZ() --Get the angles of the camera
		local _,spinY = self.core.spinOffset.Rotation:ToEulerAnglesYXZ()
		spinDelta = (y - spinY + math.pi) % (2*math.pi) - math.pi
	end


	rShoulder.C0 = character.Torso.CFrame:Inverse() * character.Head.CFrame * self.core.armOffset * RC0
	lShoulder.C0 = character.Torso.CFrame:Inverse() * character.Head.CFrame * self.core.armOffset * LC0

	
	local legOffset = movementOffset.UpVector.X*1.5
	if math.round(rootVelocity.Z) >= 1 then
		neck.C0 = neck.C0:Lerp(NC0 * CFrame.Angles(-lookCFrame.lookVector.Y, 0, 0) * movementOffset:Inverse():Lerp(CFrame.new(0,0,0),0.5),0.05)
		torso.C0 = torso.C0:Lerp(TC0 * CFrame.Angles(-lookCFrame.lookVector.Y/2.5,0,0) * movementOffset:Lerp(CFrame.new(0,0,0),0.5),0.05)
		lHip.C0 = lHip.C0:Lerp(LHC0 * CFrame.Angles(0,legOffset,lookCFrame.lookVector.Y/2.5),0.5)
		rHip.C0 = rHip.C0:Lerp(RHC0 * CFrame.Angles(0,legOffset,-lookCFrame.lookVector.Y/2.5),0.5)
	else
		neck.C0 = neck.C0:Lerp(NC0 * CFrame.Angles(-lookCFrame.lookVector.Y, 0, spinDelta*2/3) * movementOffset:Inverse(),0.1)
		torso.C0 = torso.C0:Lerp(TC0 * CFrame.Angles(-lookCFrame.lookVector.Y/2.5,0,0) * movementOffset,0.1)
		lHip.C0 =  lHip.C0:Lerp(CFrame.Angles(-lookCFrame.lookVector.Y/2.5,-spinDelta/3,0) * LHC0 * CFrame.Angles(0,-legOffset,0) * CFrame.new(0,0,legOffset),0.1)
		rHip.C0 =  rHip.C0:Lerp(CFrame.Angles(-lookCFrame.lookVector.Y/2.5,-spinDelta/3,0) * RHC0 * CFrame.Angles(0,-legOffset,0) * CFrame.new(0,0,-legOffset),0.1)
	end

    self.core.movementOffset = movementOffset
end
-------------------------------------------------------------
-------------------------------------------------------------


--kitty's anims
-------------------------------------------------------------
-------------------------------------------------------------
local KITTYAnim = {
    animGroups = {},
    animTracks =  {},
    coreGroup = nil
}
KITTYAnim.__index = KITTYAnim

function KITTYAnim:addAnimationGroup(name, groupType, priority, animMap)
    priority = priority or 5
    if not self.animGroups then
        self.animGroups   = {} -- name -> {type, priority, map}
        self.animTracks   = {} -- name -> track object (ALREADY LOADED)
        self.coreGroup    = nil
    end

    -- register the map
    self.animGroups[name] = {
        type     = groupType,
        priority = priority,
        map      = animMap or {},
    }

    -- EAGER-LOAD every track in this group
    for animName, id in pairs(animMap) do
        if id and id ~= "" then
            local trackName = name.."."..animName

            -- create Animation object
            local anim = Instance.new("Animation")
            anim.Name = trackName
            anim.AnimationId = id

            -- LOAD ONCE, store track
            local track = self.rig.Humanoid:LoadAnimation(anim)
            track.Priority = Enum.AnimationPriority.Action
            track:Play() -- weight 0, but alive → no future delay
            track:AdjustWeight(0.001)

            self.animTracks[trackName] = track
        else
            warn("[KITTY] addAnimationGroup: missing ID for '"..animName.."' in group '"..name.."'")
        end
    end
end


function KITTYAnim:SetCoreAnim(groupName, fadeIn) --replaces movement anim with a given group
                                                  --will automatically fallback if certain movements aren't specified
    fadeIn = fadeIn or 0.2
    local group = self.animGroups[groupName]
    if not group or group.type ~= "Core" then
        warn("[KITTY] SetCoreAnim: group '"..groupName.."' not found or not Core")
        return nil
    end

    -- build merged map (higher prio wins, fall back downward)
    local merged = {}
    local prioList = {}
    for n, g in pairs(self.animGroups) do
        if g.type == "Core" then table.insert(prioList, {n, g.priority}) end
    end
    table.sort(prioList, function(a, b) return a[2] < b[2] end) -- 1 → highest

    for _, entry in ipairs(prioList) do
        local groupName, prio = entry[1], entry[2]
        local g = self.animGroups[groupName]
        for animName, _ in pairs(g.map) do
            local trackName = groupName.."."..animName
            local track = self.animTracks[trackName]
            if track and not merged[animName] then
                merged[animName] = track  -- store the TRACK, not the ID
            end
        end
    end

    -- warn if any core anim missing
    local CORE_REQUIRED = {"idleAnim", "walkAnim"}
    for _, req in ipairs(CORE_REQUIRED) do
        if not merged[req] then
            warn("[KITTY] Core anim '"..req.."' missing in group '"..groupName.."'")
        end
    end

    -- unload old core weights (fade out)
    if self.coreGroup then
        for _, tr in pairs(self.animTracks) do
            if tr.PriorityValue == 1 then tr:AdjustWeight(0.001, fadeIn) end
        end
    end

    self.coreGroup = merged
    return groupName
end

function KITTYAnim:playAnim(name, fadeIn, fadeOut, speed)
    fadeIn  = fadeIn or 0.15
    fadeOut = fadeOut or 0.15
    speed   = speed or 1

    -- find highest-prio group that contains this anim
    local bestGroup, bestPrio = nil, -math.huge
    for gn, g in pairs(self.animGroups) do
        if g.map[name] and g.priority > bestPrio then
            bestGroup, bestPrio = gn, g.priority
        end
    end
    if not bestGroup then
        warn("[KITTY] playAnim: '"..name.."' not found in any group")
        return
    end

    local trackName = bestGroup.."."..name
    local track = self.animTracks[trackName]
    
    track:Play()
    track:AdjustWeight(1, fadeIn)
    track:AdjustSpeed(speed)
end


function KITTYAnim:stopAnim(name, fadeOut)
    fadeOut = fadeOut or 0.15
    local bestGroup, bestPrio
    for gn, g in pairs(self.animGroups) do
        if g.map[name] and (not bestPrio or g.priority > bestPrio) then
            bestGroup, bestPrio = gn, g.priority
        end
    end
    if bestGroup then
        local track = self.animTracks[bestGroup.."."..name]
        if track then track:AdjustWeight(0, fadeOut) end
    end
end

function KITTYAnim:updateAnim()
    local root = self.rig.HumanoidRootPart
    local rootVelocity = root.CFrame:VectorToObjectSpace(root.Velocity)

    if rootVelocity.Magnitude > 0.1 then
		self.coreGroup.idleAnim:AdjustWeight(0.001,0.1)
		self.coreGroup.walkAnim:AdjustWeight(1,0.1)
        if rootVelocity.Z >= 1 then
            self.coreGroup.walkAnim:AdjustSpeed(-self.stats.walkSpeed/8)
        else
            self.coreGroup.walkAnim:AdjustSpeed(self.stats.walkSpeed/8)
        end
	else
		self.coreGroup.idleAnim:AdjustWeight(1,0.1)
		self.coreGroup.walkAnim:AdjustWeight(0.001,0.1)
	end
end

function KITTY:initAnim()
    self.anim = setmetatable({rig = self.rig, stats = self.stats}, KITTYAnim)

    self.anim:addAnimationGroup("DefaultMovement","Core",5,self.stats.defaultAnims.movement)
    self.anim:SetCoreAnim("DefaultMovement")
    -- preload any groups you registered earlier
    -- example:  self.anim:addAnimationGroup("DefaultCore","Core",1,animIDs.movementAnim)
end
-------------------------------------------------------------
-------------------------------------------------------------


--kitty ranged combat loader
-------------------------------------------------------------
-------------------------------------------------------------
local KITTYRanged = {
    baseDamage = 10,
    damageType = "Physical",

    fireRate = 120,

    aimTime = 0.5,
    accuracy = 0.1, --percentage of shots that will land

    barrel = nil,
    fireSound = nil,
    particles = {},

    fireConditions = { --kitten can only fire when ALL of these conditions are met
        burstCoolDown = false, --cooldown for controlled bursts
        fireCoolDown = false, --normal cooldown for firerate
        flinching = false, --not flinching due to being hit
        sprinting = false,
    },

    animations = {

    }
}
KITTYRanged.__index = KITTYRanged

function KITTYRanged:initRanged(kitten)
    local ranged = {
        kitten = kitten,   -- full access to facts, stats, rig, etc.
    }
    setmetatable(ranged, KITTYRanged)

    ranged.barrel = kitten.rig:FindFirstChild("Barrel",true)
    for index,item in ranged.barrel:GetChildren() do
        if item:IsA("ParticleEmitter") then
            table.insert(self.particles,item)
        elseif item:IsA("Sound") then
            self.fireSound = item
        end
    end

    return ranged
end

function KITTYRanged:canFire()
    for fact, requiredState in pairs(self.fireConditions) do
        local activeFact = self.kitten:factActive(fact)
        if activeFact ~= requiredState then
            return false
        end
    end

    return true --all conditions met
end

function KITTYRanged:Fire()
    if not self:canFire() then return end

    self.fireSound:Stop()
    self.fireSound:Play()

    for i, effect in self.particles do
        effect:Emit(15)
    end

    kittyBoard:addEvent("gunshot",0.1,self.barrel.Position,{volume = 5})
    --hitreg stuff
end

function KITTYRanged:updateAnim()
    
end
-------------------------------------------------------------
-------------------------------------------------------------


-------------------------------------------------------------
-------------------------------------------------------------
-------------------------------------------------------------
-------------------------------------------------------------
-------------------------------------------------------------
-------------------------------------------------------------


















return KITTY