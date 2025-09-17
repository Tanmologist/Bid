--this thing control the goofy ahh character
--module script under replicated storage's "modules" folder or under the main control script

local handler = {}
local UIS = game:GetService("UserInputService")
local phs = game:GetService("PhysicsService")
local debris = game:GetService("Debris")
local replicatedStorage = game:GetService("ReplicatedStorage")

local remotes = replicatedStorage:WaitForChild("Remotes")
local charRemote = remotes:WaitForChild("charRemote")

local camera = workspace.CurrentCamera
local cameraHandler = require(game.ReplicatedStorage.Modules.cameraHandler)


local function lerp(a, b, t) -- Lerp Args
	return a + (b - a) * t -- Lerp Formula
end


local torsoAttachments = {"BodyBackAttachment","BodyFrontAttachment","LeftCollarAttachment","NeckAttachment","RightCollarAttachment","WaistBackAttachment","WaistCenterAttachment","WaistFrontAttachment"}
local function isTorsoAccessory(attachment)
	local name = attachment.Name
	for i = 1,#torsoAttachments do
		if name == torsoAttachments[i] then return true end
	end
	return false
end
--



function handler.setup(plr:Player,template:{any})
	local character = plr.Character
	local humanoid = character.Humanoid :: Humanoid
	local root = character:WaitForChild("HumanoidRootPart")::Part
	humanoid.AutoRotate = false
	humanoid.CameraOffset = Vector3.new(0,0,-0.25)
	humanoid.JumpHeight = 0
	
	local currentTool = nil
	
	local camBobbleDX = 0
	local camBobbleDY = 0
	local camBobbleMagnitude = 1
	local spinOffset = root.CFrame
	
	local interactDebounce = false
	local crouchDebounce = false
	local sprintDebounce = false
	local walkDebounce = false
	local dashDebounce = false
	
	local charLoaded = true
	
	for _, animationTrack in ipairs(humanoid:GetPlayingAnimationTracks()) do
		animationTrack:Stop()
	end
	
	--prep character
	local charIsVisible = false
	local charTransparencyConnections = {}
	local function makeCharVisible()
		for index, item in charTransparencyConnections do
			item:Disconnect()
		end
		charTransparencyConnections = {}
		
		plr.CameraMaxZoomDistance = 50
		plr.CameraMinZoomDistance = 50
		
		for i, item in ipairs(character:GetChildren()) do
			if item:IsA("BasePart") and (item.Name == "Left Arm" or item.Name == "Right Arm") then 
				local connection = item.Changed:connect(function (property)    
					item.LocalTransparencyModifier = 0
					item.Transparency = 0
				end)
				table.insert(charTransparencyConnections,connection)
				
				local decor = item:WaitForChild(item.Name,1)
				if decor then
					for v, decor in item[item.Name]:GetDescendants() do
						local connection = decor.Changed:connect(function (property)    
							decor.LocalTransparencyModifier = 0
							decor.Transparency = 0
						end)
						table.insert(charTransparencyConnections,connection)
					end
				end
			end
		end
		
		task.wait(0.1)
		plr.CameraMinZoomDistance = 0.5
		plr.CameraMaxZoomDistance = 0.5
		charIsVisible = true
	end
	
	local function makeCharInvisible()
		for index, item in charTransparencyConnections do
			item:Disconnect()
		end
		charTransparencyConnections = {}

		for i, item in ipairs(character:GetChildren()) do
			if item:IsA("BasePart") and item.Name ~= "HumanoidRootPart" then 
				item.Transparency = 0
				item.LocalTransparencyModifier = 0
			end
		end
	end
	

	--template is like, an array of character stats
	local charObj = {
		char = character,
		walkSpeed = 10,
		sprintSpeed = 24,
		crouchSpeed = 6,
		dashSpeed = 60,
		dashDistance = 8,
		dashCoolDown = 2,
		dashTimer = 0,
		movementDeduction = 0,
		acceleration = 0.05, --cuz it's a lerp function so it must be <= 1, 0 meaning no acceleration, 1 meaning instant
		
		examineAnimID = "rbxassetid://111162910874535",
		idleAnimID = "rbxassetid://87583033791900",
		walkAnimID = "rbxassetid://113345430559319",
		sprintAnimID = "rbxassetid://112326929987960",
		crouchAnimID = "rbxassetid://125630576439267",
		crouchWalkAnimID = "rbxassetid://118558624892916",
		interactAnimID = "rbxassetid://90201926749507",
		spinRightAnimID = "rbxassetid://106548158517632",
		spinLeftAnimID = "rbxassetid://117261819476231",
		
		fov = 80,
		recentBobbleCFrame = CFrame.new(0,0,0),
		interactDistance = 10,
		interactSubject = nil,
		interactTimer = 0,
		GuiMain = nil,
		FXMain = nil,
		gameProcessedEvent = false,
		
		dashing = false,
		sprinting = false,
		crouching = false,
		healing = false,
		leftHandFree = true,
		mainHandFree = true,
		
		dead = false,
	}
	camera.FieldOfView = charObj.fov
	
	if template then
		charObj = template
		charObj.char = character
	end
	
	local examineAnim = Instance.new("Animation",humanoid)
	local idleAnim = Instance.new("Animation",humanoid)
	local walkAnim = Instance.new("Animation",humanoid)
	local sprintAnim = Instance.new("Animation",humanoid)
	local crouchAnim = Instance.new("Animation",humanoid)
	local crouchWalkAnim = Instance.new("Animation",humanoid)
	local interactAnim = Instance.new("Animation",humanoid)
	local spinLeftAnim = Instance.new("Animation",humanoid)
	local spinRightAnim = Instance.new("Animation",humanoid)
	examineAnim.AnimationId = charObj.examineAnimID
	idleAnim.AnimationId = charObj.idleAnimID
	walkAnim.AnimationId = charObj.walkAnimID
	sprintAnim.AnimationId = charObj.sprintAnimID
	crouchAnim.AnimationId = charObj.crouchAnimID
	crouchWalkAnim.AnimationId = charObj.crouchWalkAnimID
	interactAnim.AnimationId = charObj.interactAnimID
	spinLeftAnim.AnimationId = charObj.spinLeftAnimID
	spinRightAnim.AnimationId = charObj.spinRightAnimID
	local examineTrack = humanoid:LoadAnimation(examineAnim)
	local idleTrack = humanoid:LoadAnimation(idleAnim)
	local walkTrack = humanoid:LoadAnimation(walkAnim)
	local sprintTrack = humanoid:LoadAnimation(sprintAnim)
	local crouchTrack = humanoid:LoadAnimation(crouchAnim)
	local crouchWalkTrack = humanoid:LoadAnimation(crouchWalkAnim)
	local interactTrack = humanoid:LoadAnimation(interactAnim)
	local spinLeftTrack = humanoid:LoadAnimation(spinLeftAnim)
	local spinRightTrack = humanoid:LoadAnimation(spinRightAnim)
	idleTrack.Looped = true
	walkTrack.Looped = true
	sprintTrack.Looped = true
	crouchWalkTrack.Looped = true
	interactTrack.Looped = true
	idleTrack:Play()
	walkTrack:Play()
	sprintTrack:Play()
	crouchTrack:Play()
	crouchWalkTrack:Play()
	interactTrack:Play()
	sprintTrack:AdjustWeight(0.001,0)
	crouchTrack:AdjustWeight(0.001,0)
	crouchWalkTrack:AdjustWeight(0.001,0)
	interactTrack:AdjustWeight(0.001,0)
	walkTrack:AdjustSpeed(charObj.walkSpeed/8)
	sprintTrack:AdjustSpeed(charObj.sprintSpeed/24)
	crouchWalkTrack:AdjustSpeed(charObj.crouchSpeed/6)
	--Character's other values is set from here too, sprint speed, stamina, walkGait, etc.
	--walkGait is like: what animation to play when moving, there's crouching, sprinting, and walking mostly

	--Object functions start below
	local keys = {
		dash = Enum.KeyCode.Space,
		sprint = Enum.KeyCode.LeftShift,
		crouch = Enum.KeyCode.C, --no autocorrection so you need to double check
		interact = Enum.KeyCode.F,
		heal = Enum.KeyCode.G
	}
	
	function charObj.setStats(statTable)
		for key, value in pairs(statTable) do
			if charObj[key] ~= nil then
					charObj[key] = value
			end
		end
	end
	
	function charObj.getChar() --this will return the key table for other modules to understand, eg sprinting for the weapon module
		return charObj
	end
	
	function charObj.getKeys() --this will return the key table for other modules to understand, eg sprinting for the weapon module
		return keys
	end

	function charObj.setKeys(newKeys)
		keys = newKeys
	end
	
	function charObj.dash(dt)
		if UIS:IsKeyDown(keys.dash) and not charObj.gameProcessedEvent and not dashDebounce and charObj.dashTimer == 0 then
			dashDebounce = true
			charObj.dashing = true 
			charObj.dashTimer = charObj.dashCoolDown
			local dashEffect = Instance.new("BodyVelocity",root)
			local dashDirection
			
			dashEffect.MaxForce = Vector3.new(1,1,1)*100000
			if root.Velocity.Magnitude > 1 then
				dashDirection = Vector3.new(root.Velocity.Unit.X,0,root.Velocity.Unit.Z)
			else
				dashDirection = root.CFrame.LookVector
			end
			dashEffect.Velocity = dashDirection*charObj.dashSpeed
			debris:AddItem(dashEffect,charObj.dashDistance/charObj.dashSpeed)
			
			wait(charObj.dashDistance/charObj.dashSpeed+0.1)
			charObj.dashing = false
		elseif not UIS:IsKeyDown(keys.dash) then
			dashDebounce = false
		end
		
		if charObj.dashTimer - dt > 0 then
			charObj.dashTimer -= dt
		else
			charObj.dashTimer = 0
		end
	end
	
	function charObj.adjustWalkspeed(speed)
		humanoid.WalkSpeed = speed - charObj.movementDeduction
	end

	function charObj.movement(dt)	
		if charLoaded == false then return end
		local rootVelocity = character.HumanoidRootPart.CFrame:VectorToObjectSpace(character.HumanoidRootPart.Velocity)
		if UIS:IsKeyDown(keys.sprint) and not charObj.gameProcessedEvent and rootVelocity.Magnitude > 0.2 then
			charObj.sprinting = true
			charObj.crouching = false
			
			charObj.adjustWalkspeed(lerp(humanoid.WalkSpeed,charObj.sprintSpeed,charObj.acceleration * dt * 60))
			if not sprintDebounce then
				sprintDebounce = true
				sprintTrack:AdjustWeight(1,1-charObj.acceleration)
				walkTrack:AdjustWeight(0.001,1-charObj.acceleration)
				crouchTrack:AdjustWeight(0.001,1-charObj.acceleration)
				crouchWalkTrack:AdjustWeight(0.001,0.1)
			end
		else
			charObj.sprinting = false
			sprintDebounce = false
			sprintTrack:AdjustWeight(0.001,0.2)
			walkTrack:AdjustWeight(1,0.2)
		end
		
		if UIS:IsKeyDown(keys.crouch) and not charObj.gameProcessedEvent and charObj.sprinting == false then
			if not crouchDebounce then
				if charObj.crouching == false then
					charObj.crouching = true
					charObj.adjustWalkspeed(charObj.crouchSpeed)
					crouchTrack:AdjustWeight(1,0.1)
					idleTrack:AdjustWeight(0.001,0.1)
					walkTrack:AdjustWeight(0.001,0.1)
				elseif charObj.crouching == true then
					charObj.crouching = false
					charObj.adjustWalkspeed(charObj.walkSpeed)
					crouchTrack:AdjustWeight(0.001,0.1)
					idleTrack:AdjustWeight(1,0.1)
					crouchWalkTrack:AdjustWeight(0.001,0.1)
				end
				crouchDebounce = true
			end
		else
			crouchDebounce = false
			if charObj.crouching == true then
				charObj.adjustWalkspeed(charObj.crouchSpeed)
			end
		end
		
		
		if rootVelocity.Magnitude <= 0.2 then
			walkTrack:AdjustWeight(0.001,0.1)
			sprintTrack:AdjustWeight(0.001,0.1)
			
			if charObj.crouching == true then
				crouchWalkTrack:AdjustWeight(0.001,0.1)
				crouchTrack:AdjustWeight(1,0.1)
				walkTrack:AdjustWeight(0.001,0.1)
			end
			
			sprintDebounce = false
		elseif rootVelocity.Magnitude > 0.2 then
			if charObj.sprinting == false and charObj.crouching == false then
				charObj.adjustWalkspeed(charObj.walkSpeed)
			end
			if charObj.crouching == true then
				crouchWalkTrack:AdjustWeight(1,0.1)
				crouchTrack:AdjustWeight(0.001,0.1)
				walkTrack:AdjustWeight(0.001,0.1)
			end
		end
		
		if charObj.dashing == true then
			walkTrack:AdjustSpeed(0.2)
			sprintTrack:AdjustSpeed(0.2)
			crouchWalkTrack:AdjustSpeed(0.2)
		elseif rootVelocity.Z >= 1 then
			walkTrack:AdjustSpeed(-charObj.walkSpeed/8)
			sprintTrack:AdjustSpeed(-charObj.sprintSpeed/24)
			crouchWalkTrack:AdjustSpeed(-charObj.crouchSpeed/6)
		else
			walkTrack:AdjustSpeed(charObj.walkSpeed/8)
			sprintTrack:AdjustSpeed(charObj.sprintSpeed/24)
			crouchWalkTrack:AdjustSpeed(charObj.crouchSpeed/6)
		end
	end
	
	function charObj.interact(dt)
		if not charObj.interactSubject then interactTrack:AdjustWeight(0.001,0.1); interactDebounce = true return end
		
		charObj.GuiMain.interactUI.progressBar.loader.Size = UDim2.fromScale(1-charObj.interactTimer/charObj.interactSubject.HoldDuration,1)
		if UIS:IsKeyDown(keys.interact) and not charObj.gameProcessedEvent and not interactDebounce then
			charObj.interactTimer -= dt
			if charObj.leftHandFree == true then
				interactTrack:AdjustWeight(1,0.1)
			else
				interactTrack:AdjustWeight(0.001,0.1)
			end
			
			if charObj.interactTimer <= 0 then
				interactTrack:AdjustWeight(0.001,0.1)
				charObj.interactTimer = charObj.interactSubject.HoldDuration
				charObj.GuiMain.interactUI.Visible = false
				interactDebounce = true
				return true
			end
		elseif not UIS:IsKeyDown(keys.interact) then
			interactTrack:AdjustWeight(0.001,0.1)
			charObj.interactTimer = charObj.interactSubject.HoldDuration
			interactDebounce = false
		end
	end
	
	function charObj.update(dt)
		--update GUI
		------------------------------------------------------------------------------------
		if charObj.interactSubject then
			charObj.GuiMain.interactUI.Visible = true
			charObj.GuiMain.interactUI.actionPrompt.Text = charObj.interactSubject.ActionText
		else
			charObj.GuiMain.interactUI.Visible = false
		end
		------------------------------------------------------------------------------------
		
		--update character
		------------------------------------------------------------------------------------
		
		
		if cameraHandler.cameraLocked == false then
			local _, y = camera.CFrame.Rotation:ToEulerAnglesYXZ() --Get the angles of the camera
			local _,rooty = root.CFrame.Rotation:ToEulerAnglesYXZ()
			local _,spinY = spinOffset.Rotation:ToEulerAnglesYXZ()
			
			local spinDelta = math.deg((y - spinY + math.pi) % (2*math.pi) - math.pi)
			local maxDelta = 100
			if charObj.crouching == true then
				maxDelta = 60
			end
	
			if math.abs(spinDelta) > maxDelta then
				if  spinLeftTrack.IsPlaying == false and spinRightTrack.IsPlaying == false then
					if spinDelta < 0 then
						spinRightTrack:Play()
					elseif spinDelta > 0 then
						spinLeftTrack:Play()
					end
				end
				
				root.CFrame = root.CFrame:Lerp(CFrame.new(root.Position) * CFrame.Angles(0,y,0),0.4 * dt * 60)
				if math.abs(math.deg(y-rooty)) < 5 then
					spinOffset = root.CFrame
				end
			elseif root.Velocity.Magnitude > 0.5 then
				root.CFrame = root.CFrame:Lerp(CFrame.new(root.Position) * CFrame.Angles(0,y,0),0.2 * dt * 60)
				spinOffset = root.CFrame
			else
				local startCFrame = CFrame.new(root.Position) * CFrame.Angles(0,spinY,0)
				root.CFrame = startCFrame:Lerp(CFrame.new(root.Position) * CFrame.Angles(0,y,0),2/3)
			end
		end
		
		if not charIsVisible then
			makeCharVisible()
		end
		------------------------------------------------------------------------------------
		
		--update camera bobble
		------------------------------------------------------------------------------------
		if humanoid.FloorMaterial ~= Enum.Material.Air and not charObj.dashing then
			local velocity = root.Velocity.Magnitude
			
			if charObj.sprinting == false then
				camBobbleDX += dt * velocity/2
				camBobbleDY += dt * velocity
			else
				camBobbleDX += dt * velocity/2.5
				camBobbleDY += dt * velocity/1.25
			end
			
			local bobble = CFrame.new()
			local bobbleX = math.cos(camBobbleDX)/16 * dt * 60
			local bobbleY = math.cos(camBobbleDY)/8 * dt * 60
			if velocity <= 1 or charObj.crouching == true then
				bobbleX = 0
				bobbleY = 0
				charObj.recentBobbleCFrame = charObj.recentBobbleCFrame:Lerp(CFrame.new(0,0,0),0.1)
			end
			
			cameraHandler.alignHead(camera,character.Head.CFrame)
			camera.CFrame= camera.CFrame * CFrame.Angles(math.rad(-bobbleY)*camBobbleMagnitude,math.rad(-bobbleX)*camBobbleMagnitude,0)
			charObj.recentBobbleCFrame *= CFrame.Angles(math.rad(-bobbleY)*camBobbleMagnitude,math.rad(-bobbleX)*camBobbleMagnitude,0)
		end
		------------------------------------------------------------------------------------
		
		charRemote:FireServer("tiltChar", camera.CFrame, spinOffset)
	end
	
	function charObj.createM6D(targetPart,parentPart,M6DName)
		if not M6DName then M6DName = "Handle" end
		local M6D = character[parentPart]:FindFirstChild(M6DName)
		if not M6D then
			M6D = Instance.new("Motor6D",character[parentPart])
			M6D.Name = M6DName
		end

		M6D.Part0 = character[parentPart]
		M6D.Part1 = targetPart

		--character.Torso["Right Shoulder"].Transform = CFrame.new()
		--character.Torso["Left Shoulder"].Transform = CFrame.new()

		charRemote:FireServer("connectM6D", targetPart, parentPart, M6DName)
	end
	
	function charObj.examine(model:Model)
		charRemote:FireServer("examine",model)
		
		local loot = character:WaitForChild(model.Name)
		for index, item in loot:GetDescendants() do
			if item:IsA("BasePart") or item:IsA("Union") or item:IsA("MeshPart") then
				item.Changed:connect(function (property)    
					item.LocalTransparencyModifier = item.Transparency
				end)
			end
		end

		charObj.createM6D(loot.ToolHandle,"Left Arm","loot")
		examineTrack:Play()
	end
	
	function charObj.operate(model:Model,animation:Animation)
		charObj.mainHandFree = false
		local animationTrack = humanoid:LoadAnimation(animation)
		animationTrack:Play()
		task.wait()
		animationTrack:Stop()
		
		charRemote:FireServer("examine",model,3)
		
		local object = character:WaitForChild(model.Name)
		for index, item in object:GetDescendants() do
			if item:IsA("BasePart") or item:IsA("Union") or item:IsA("MeshPart") then
				item.Changed:connect(function (property)    
					item.LocalTransparencyModifier = item.Transparency
				end)
			end
		end

		charObj.createM6D(object.ToolHandle,"Torso","Medkit")
		
		animationTrack:Play()
		animationTrack.Ended:Wait()
		animationTrack:Destroy()
		charObj.mainHandFree = true
	end
	
	
	function charObj.unload()
		charLoaded = false
		
		for _, animationTrack in ipairs(humanoid:GetPlayingAnimationTracks()) do
			animationTrack:Stop()
			animationTrack:Destroy()
		end

		for index, item in humanoid:GetChildren() do
			if item:IsA("Animation") then
				item:Destroy()
			end
		end
		
		cameraHandler.unlock(camera)
		makeCharInvisible()
		
		workspace:FindFirstChild("HealthUiPart"):Destroy()
	end
	
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			currentTool = child
			local realModel = child:FindFirstChildOfClass("Model")
			local handle = realModel:FindFirstChild("Handle") or realModel:FindFirstChild("GunHandle")
			if handle then
				charObj.createM6D(handle,"Right Arm")
			end
		end
	end)
	
	character.ChildRemoved:Connect(function(child)
		if child == currentTool then
			local M6D = character["Right Arm"]:FindFirstChild("Handle")
			if not M6D then return end
			M6D.Part1 = nil
			currentTool = nil
		end
	end)
	
	return charObj
end

return handler