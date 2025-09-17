local handler = {}

local riseMagnitude = 2
local RC0 = CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0 )
local LC0 = CFrame.new( -1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)
local NC0 = CFrame.new( 0, 1, 0, -1, -0, -0, 0, 0, 1, 0, 1, 0)

local springModule = require(game.ReplicatedStorage.Modules.SpringModule)

local uis = game:GetService("UserInputService")
local debris = game:GetService("Debris")
local ts = game:GetService("TweenService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local remotes = replicatedStorage:WaitForChild("Remotes")
local hitregRemote = remotes:WaitForChild("hitregRemote")
local weaponRemote = remotes:WaitForChild("weaponRemote")
local charRemote = remotes:WaitForChild("charRemote")

local function lerp(a, b, t) -- Lerp Args
	return a + (b - a) * t -- Lerp Formula
end

function handler.setup(tool,weaponStats)
	local character = game.Players.LocalPlayer.Character
	local camera = workspace.CurrentCamera
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid.Animator :: Animator
	local rShoulder = character.Torso["Right Shoulder"]
	local lShoulder = character.Torso["Left Shoulder"]
	local handle = nil
	
	local armUpdateDelay = 1/30
	local armUpdateCD = 0
	
	local cursor = workspace:FindFirstChild("Cursor") or replicatedStorage.Models.MISC.Cursor:Clone()
	local weaponUiPart = workspace:FindFirstChild("WeaponUiPart") or replicatedStorage.Models.MISC.WeaponUiPart:Clone()
	cursor.Parent = workspace
	weaponUiPart.Parent = workspace
	
	local bobbleSpring = springModule.new()
	local swaySpring = springModule.new()
	local recoilSpring = springModule.new()
	swaySpring.Speed = 4
	swaySpring.Damping = 5
	swaySpring.Constant = 1
	
	local bobbleDX = 0
	local bobbleDY = 0
	local gaitOffset = CFrame.new(0,0,0)
	local recoilOffset = CFrame.new(0,0,0)
	local cameraRecoilOffset = CFrame.new(0,0,0)
	local aimOffset = CFrame.new(0,0,0)

	local charObj
	local weaponObj = {
		instance = tool,
		serverModel = tool:FindFirstChildOfClass("Model"),
		weaponStats = weaponStats,
		aimPart = nil,
		barrel = nil,
		
		idleAnimID = weaponStats.idleAnimID or "rbxassetid://80951678862464",
		fireAnimID = weaponStats.fireAnimID or "",
		reloadAnimID = weaponStats.reloadAnimID or "",
		equipAnimID = weaponStats.equipAnimID or "",
		sprintGait = weaponStats.sprintGait or 2,
		
		baseDamage = weaponStats.baseDamage or 1,
		initialSpread = weaponStats.initialSpread or 0,
		recoilSpread = weaponStats.recoilSpread or 10,
		recoilRate = weaponStats.recoilRate or 0.3,
		recoilRecovery =weaponStats.recoilRecovery or 0.1,
		aimRecoilMultiplier = weaponStats.aimRecoilMultiplier or 1,
		magSize = weaponStats.magSize or 30,
		magCurrent = weaponStats.magCurrent or 0,
		reserveSize = weaponStats.reserveSize or 0,
		reserveCurrent = weaponStats.reserveCurrent or weaponStats.reserveSize or 0,
		fireMode = weaponStats.fireMode or "full-auto",
		fireRate = weaponStats.fireRate or 500,
		
		weaponSlot = weaponStats.weaponSlot or "primary",
		aimMovementDeduction = weaponStats.aimMovementDeduction or 3
	}
	weaponObj.aimPart = weaponObj.serverModel:FindFirstChild("Aim")
	weaponObj.barrel = weaponObj.serverModel:FindFirstChild("Barrel")
	
	local idleAnim = Instance.new("Animation")
	local equipAnim = Instance.new("Animation")
	local reloadAnim = Instance.new("Animation")
	idleAnim.AnimationId = weaponObj.idleAnimID
	equipAnim.AnimationId = weaponObj.equipAnimID
	reloadAnim.AnimationId = weaponObj.reloadAnimID
	local idleTrack = animator:LoadAnimation(idleAnim)
	local equipTrack = animator:LoadAnimation(equipAnim)
	local reloadTrack = animator:LoadAnimation(reloadAnim)
	
	local maxSpreadAngle = math.deg(math.atan(weaponObj.recoilSpread/100))
	local minSpreadAngle = math.deg(math.atan(weaponObj.initialSpread/100))
	local currentSpreadAngle = minSpreadAngle

	local triggerDown = false
	local reloading = false
	local canFire = true
	local canReload = true
	local aiming = false
	local bobbleEnabled = true
	weaponObj.magCurrent = weaponObj.magSize --debugging feature
	
	
	recoilSpring.Constant = 20
	recoilSpring.Speed = 10
	
	local cameraShaker = require(game.ReplicatedStorage.Modules.CameraShaker)
	local recoilShake = function()
		local c = cameraShaker.CameraShakeInstance.new(weaponObj.recoilSpread,weaponObj.recoilRate,0,0.2)
		c.RotationInfluence = Vector3.new(0,0,0.25)
		c.PositionInfluence = Vector3.new(0.01,0,0)
		return c
	end;
	
	local camShake = cameraShaker.new(201, function(shakeCf)
		camera.CFrame = camera.CFrame * shakeCf
	end)
	camShake:Start()
	
	
	
	---------------------------------------------------------------------
	local triggerBehavior =  weaponStats.triggerBehavior or function()
		if canFire and triggerDown and charObj.sprinting == false and weaponObj.magCurrent > 0 then
			weaponObj.magCurrent -= 1
			weaponObj.fire()
			canFire = false
			if weaponObj.fireMode == "semi-auto" then
				triggerDown = false
			end

			task.wait(60/weaponObj.fireRate)
			canFire = true
		end
	end
	
	local function adjustCursorTransparency(targetTransparency)
		for index, frame in pairs(cursor.CursorGui:GetChildren()) do
			frame.BackgroundTransparency = targetTransparency
		end
	end
	
	local function getCursorTransparency()
		return cursor.CursorGui.center.BackgroundTransparency
	end
	
	local function adjustCursorLength(length)
		for index, frame in pairs(cursor.CursorGui:GetChildren()) do
			if frame.Name == "center" then
				local scale = 0.1*length
				frame.Size = UDim2.fromScale(frame.Size.X.Scale,scale)
			else
				local scale = 0.35*length
				frame.Size = UDim2.fromScale(scale,frame.Size.Y.Scale)
			end
		end
	end
	
	local function getCursorLength()
		return 0.1/cursor.CursorGui.center.Size.Y.Scale
	end
	
	local function updateGui(updateType)
		--local weaponUiPart = script.WeaponUiPart --debugging feature
		local weaponUI = weaponUiPart.WeaponUI
		local magUI = weaponUI.Mag
		local ammoUI = weaponUI.Ammo
		local roundSize = math.clamp(1/weaponObj.magSize,0.03,0.5)
		local reloadLength = reloadTrack.Length
		ammoUI.UIListLayout.RoundTemplate.Size = UDim2.new(roundSize,-5,ammoUI.UIListLayout.RoundTemplate.Size.Y.Scale,0)
		if updateType == "fire" then
			for index, item  in ammoUI:GetChildren() do
				if item:IsA("Frame") then item:Destroy() end
			end
			
			local fakeRound = ammoUI.UIListLayout.RoundTemplate:Clone()
			fakeRound.Name = "Round"
			fakeRound.Parent = weaponUI.fakeAmmo
			ts:Create(fakeRound,TweenInfo.new(0.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position = UDim2.new(0,0,-fakeRound.Position.Y,0)}):Play()
			ts:Create(fakeRound,TweenInfo.new(0.2,Enum.EasingStyle.Cubic),{BackgroundTransparency = 1}):Play()
			debris:AddItem(fakeRound,0.2)
			
			local displacementRound = ammoUI.UIListLayout.RoundTemplate:Clone()
			displacementRound.Name = "dRound"
			displacementRound.Parent = ammoUI
			displacementRound.BackgroundTransparency = 1
			ts:Create(displacementRound,TweenInfo.new(0.2),{Size = UDim2.fromScale(0,displacementRound.Size.Y)}):Play()
			debris:AddItem(displacementRound,0.2)
			
			for index = 1, weaponObj.magCurrent do
				local newFrame = ammoUI.UIListLayout.RoundTemplate:Clone()
				newFrame.Name = "Round"
				newFrame.Parent = ammoUI
			end
			weaponUI.AmmoNum.TextLabel.Text = "x"..tostring(weaponObj.magCurrent)
		elseif updateType == "reloadBegan" then
			local ammoFrame = weaponUI.fakeAmmo:Clone()
			--local ammoFrame = Instance.new("Frame")
			ammoFrame.Name = "ReloadBar"
			ammoFrame.Position = UDim2.new(0,0,ammoFrame.Position.Y.Scale + ammoFrame.Size.Y.Scale/2,0)
			ammoFrame.AnchorPoint = Vector2.new(0,0.5)
			ammoFrame.Parent = weaponUI
			ammoFrame.BackgroundTransparency = 0.2
			ammoFrame.Size = UDim2.new(0,0,ammoFrame.Size.Y.Scale,0)
			ts:Create(ammoFrame,TweenInfo.new(reloadLength),{Size = UDim2.new(1,0,ammoFrame.Size.Y.Scale,0)}):Play()
			debris:AddItem(ammoFrame,reloadLength+0.6)
		elseif updateType == "reloadFinished" then
			for index, item  in ammoUI:GetChildren() do if item:IsA("Frame") then item:Destroy() end end
			for index = 1, weaponObj.magCurrent, 1 do
				local newFrame = ammoUI.UIListLayout.RoundTemplate:Clone()
				newFrame.Name = "Round"
				newFrame.Parent = ammoUI
			end
			weaponUiPart.WeaponUI.AmmoNum.TextLabel.Text = "x"..tostring(weaponObj.magCurrent)
			
			for index, item  in magUI:GetChildren() do
				if item:IsA("ImageLabel") then item:Destroy() end
			end
			
			local displacementMag = magUI.UIListLayout.MagTemplate:Clone()
			displacementMag.Name = "dMag"
			displacementMag.Parent = magUI
			displacementMag.ImageTransparency = 1
			ts:Create(displacementMag,TweenInfo.new(0.2),{Size = UDim2.new(0,-magUI.UIListLayout.Padding.Offset,displacementMag.Size.Y.Scale,0)}):Play()
			debris:AddItem(displacementMag,0.2)
			
			for index = 1, weaponObj.reserveCurrent do
				local newFrame = magUI.UIListLayout.MagTemplate:Clone()
				newFrame.Name = "Mag"
				newFrame.Parent = magUI
				newFrame.ImageTransparency = lerp(0,1,(index-1)/weaponObj.reserveSize)
			end
			
			local ammoFrame = weaponUI:FindFirstChild("ReloadBar") or nil
			if ammoFrame then
				ts:Create(ammoFrame,TweenInfo.new(0.5,Enum.EasingStyle.Bounce),{BackgroundTransparency = 0}):Play()
				ts:Create(ammoFrame,TweenInfo.new(0.2,Enum.EasingStyle.Cubic),{Size = UDim2.new(1,0,0,0)}):Play()
				debris:AddItem(ammoFrame,0.6)
			end
		elseif updateType == "Clear" then
			for index, item  in ammoUI:GetChildren() do if item:IsA("Frame") then item:Destroy() end end
			for index, item  in magUI:GetChildren() do if item:IsA("ImageLabel") then item:Destroy() end end
			weaponUI.WeaponName.TextLabel.Text = weaponObj.instance.Name
			weaponUI.AmmoNum.TextLabel.Text = "x00"
		else
			weaponUI.WeaponName.TextLabel.Text = weaponObj.instance.Name
			
			for index, item  in ammoUI:GetChildren() do if item:IsA("Frame") then item:Destroy() end end
			for index = 1, weaponObj.magCurrent, 1 do
				local newFrame = ammoUI.UIListLayout.RoundTemplate:Clone()
				newFrame.Name = "Round"
				newFrame.Parent = ammoUI
			end
			weaponUiPart.WeaponUI.AmmoNum.TextLabel.Text = "x"..tostring(weaponObj.magCurrent)
			
			for index, item  in magUI:GetChildren() do if item:IsA("ImageLabel") then item:Destroy() end end
			for index = 1, weaponObj.reserveCurrent do
				local newFrame = magUI.UIListLayout.MagTemplate:Clone()
				newFrame.Name = "Mag"
				newFrame.Parent = magUI
				newFrame.ImageTransparency = lerp(0,1,(index-1)/weaponObj.reserveSize)
			end
			
			local ammoFrame = weaponUI:FindFirstChild("ReloadBar") or nil
			if ammoFrame then ammoFrame:Destroy() end
		end
	end

	function weaponObj.OnEquip()
		uis.MouseIconEnabled = false
		updateGui("Clear")
		updateGui("reloadFinished")
		handle = character["Right Arm"]:FindFirstChildOfClass("Motor6D")
		
		if handle then idleTrack:Play() end
		
		weaponRemote:FireServer("Equip",tool)
		canFire = false
		canReload = false
		equipTrack:Play()
		equipTrack.Ended:Wait()
		canFire = true
		canReload = true
	end

	function weaponObj.OnHolster()
		--uis.MouseIconEnabled = true
		equipTrack:Stop()
		idleTrack:Stop()
		handle = nil
		weaponObj.aim(false)
		
		adjustCursorTransparency(1)
		
		weaponUiPart.Position = Vector3.new(math.huge,math.huge,math.huge)
	end
	
	function weaponObj.trigger(state)
		triggerDown = state
	end
	
	function weaponObj.aim(state)
		aiming = state
		if state == true then
			game.Players.LocalPlayer.PlayerScripts.characterController.getCharObj:Fire("changeCharObj","movementDeduction",weaponObj.aimMovementDeduction)
		else
			game.Players.LocalPlayer.PlayerScripts.characterController.getCharObj:Fire("changeCharObj","movementDeduction",0)
		end
	end
	
	function weaponObj.reload()
		if weaponObj.magCurrent == weaponObj.magSize or weaponObj.reserveCurrent == 0 or canReload == false or charObj.leftHandFree == false then return end
		local reloadLength = reloadTrack.Length - 0.1
		reloadTrack:Play()
		reloading = true
		game.Players.LocalPlayer.PlayerScripts.characterController.getCharObj:Fire("changeCharObj","leftHandFree",false)
		canReload = false
		updateGui("reloadBegan")
		weaponRemote:FireServer("Reload",tool)
	
		task.wait(reloadLength)
		if reloading == true then --reload haven't been cancelled
			canReload = true
			reloading = false
			game.Players.LocalPlayer.PlayerScripts.characterController.getCharObj:Fire("setAmmo",weaponObj.weaponSlot.."Ammo",weaponObj.reserveCurrent - 1)
			weaponObj.magCurrent = weaponObj.magSize
			task.wait()
			updateGui("reloadFinished")
			game.Players.LocalPlayer.PlayerScripts.characterController.getCharObj:Fire("changeCharObj","leftHandFree",true)
		end
	end
	
	function weaponObj.fire()
		if reloading then return end
		
		local recoilX = 0
		local recoilY = 0
		local displayRecoil = 0
		pcall(function()
			local recoilDirection = math.random(0,2*math.pi*500)/500
			local recoilOffset = math.random(-currentSpreadAngle*20,currentSpreadAngle*20)/40
	
			recoilX = recoilOffset*math.cos(recoilDirection)
			recoilY = recoilOffset*math.sin(recoilDirection)
			displayRecoil = math.random(math.sqrt(maxSpreadAngle-minSpreadAngle)*10,math.sqrt(maxSpreadAngle-minSpreadAngle)*20)/50
		end)
		
		if aiming == true then
			currentSpreadAngle = lerp(currentSpreadAngle,90,(weaponObj.recoilRate-weaponObj.recoilRecovery)*10/(90-maxSpreadAngle))
			recoilX /= 2
			recoilY = currentSpreadAngle/4
			recoilSpring.Speed = 4
			recoilSpring:add(Vector3.new(recoilX,recoilY,0))
		else
			currentSpreadAngle = lerp(currentSpreadAngle,maxSpreadAngle,weaponObj.recoilRate)
			recoilSpring.Speed = 10
			recoilSpring:move(Vector3.new(recoilX,recoilY,0))
		end
		swaySpring:add(Vector3.new(0,0,displayRecoil))
		camShake:Shake(recoilShake())
		
		updateGui("fire")
		
		local castInfo = {
			baseDamage = weaponStats.baseDamage or 1,
			damageType = weaponStats.damageType or "Physical",
			headshotMultiplier = weaponStats.headshotMultiplier or 2,
			velocity = weaponStats.velocity or 800,
			modelID = math.random(1,200)
		}
		
		local castOrigin = camera.CFrame.Position
		local castDirection = (camera.CFrame * cameraRecoilOffset:Inverse() * charObj.recentBobbleCFrame:Inverse() * CFrame.Angles(math.rad(recoilY),math.rad(recoilX),0) ).LookVector*10000
		if aiming then
			castDirection = camera.CFrame.LookVector*10000
		end
		
		hitregRemote:FireServer(castOrigin,castDirection,castInfo)
		weaponRemote:FireServer("Fire",tool)
	end

	function weaponObj.syncChar(charUpdate)
		charObj = charUpdate
		
		if weaponObj.reserveSize ~= charObj.charInventory[weaponObj.weaponSlot.."AmmoMax"] then
			game.Players.LocalPlayer.PlayerScripts.characterController.getCharObj:Fire("setAmmo",weaponObj.weaponSlot.."AmmoMax",weaponObj.reserveSize)
			game.Players.LocalPlayer.PlayerScripts.characterController.getCharObj:Fire("setAmmo",weaponObj.weaponSlot.."Ammo",weaponObj.reserveCurrent)--debugging feature
		else
			if weaponObj.reserveSize ~= charObj.charInventory[weaponObj.weaponSlot.."AmmoMax"] then
				updateGui()
			end
			weaponObj.reserveCurrent = charObj.charInventory[weaponObj.weaponSlot.."Ammo"]
			weaponObj.reserveSize = charObj.charInventory[weaponObj.weaponSlot.."AmmoMax"]
		end
	end
	
	function weaponObj.update(dt)
		--print(charObj)
		if not charObj then return end
		if charObj.dead == true then 
			weaponObj.instance.Parent = nil
			weaponObj.OnHolster()
			weaponUiPart.Position = Vector3.new(math.huge,math.huge,math.huge) 
			return 
		end
		
		local bobbleOffset 
		local offset = CFrame.new()
		
		if humanoid.FloorMaterial == Enum.Material.Air or charObj.dashing == true then
			bobbleSpring:add(Vector3.new(0,0.05*dt*60,0))
			bobbleOffset = bobbleSpring:update(dt)
			gaitOffset = gaitOffset:Lerp(CFrame.new(0,0,0),0.2 * dt * 60)
			offset = gaitOffset * CFrame.new(bobbleOffset.X,bobbleOffset.Y,0) * CFrame.Angles(0,bobbleOffset.X,bobbleOffset.Y)
		elseif charObj.sprinting == false then
			local velocity = character.HumanoidRootPart.Velocity.Magnitude
			
			if not charObj.crouching then
				bobbleDX += dt * velocity/2
				bobbleDY += dt * velocity/2
			else
				bobbleDX += dt * velocity/1.3
				bobbleDY += dt * velocity/1.3
			end
			local bobbleX = math.cos(bobbleDX)/12 * velocity/12
			local bobbleY = math.abs(math.sin(bobbleDY))/16 * velocity/12
			if velocity <= 0.1 then
				bobbleX = 0
				bobbleY = 0
			end
			
			if aiming == false then
				adjustCursorTransparency(lerp(getCursorTransparency(),0.2,0.1))
				bobbleSpring:move(Vector3.new(bobbleX,bobbleY,0))
			else
				adjustCursorTransparency(lerp(getCursorTransparency(),1,0.1))
				bobbleSpring:move(Vector3.new(bobbleX/5,bobbleY/5,0))
			end
			
			if charObj.crouching and aiming == false then
				gaitOffset = gaitOffset:Lerp(CFrame.new(0.2,0,0)*CFrame.Angles(0,0,math.rad(20)),0.2 * dt * 60)
			else
				gaitOffset = gaitOffset:Lerp(CFrame.new(0,0,0),0.2 * dt * 60)
			end
			bobbleOffset = bobbleSpring:update(dt)

			offset = gaitOffset * CFrame.new(bobbleOffset.X,bobbleOffset.Y,0) * CFrame.Angles(0,bobbleOffset.X,bobbleOffset.Y)
		else

			weaponObj.aim(false)
			if weaponObj.sprintGait == 2 then --rifle sprinting gait
				local velocity = character.HumanoidRootPart.Velocity.Magnitude

				bobbleDX += dt * velocity/2.5
				bobbleDY += dt * velocity/2.5
				local bobbleX = math.cos(bobbleDX)/12 * velocity/6
				local bobbleY = math.abs(math.sin(bobbleDY))/16 * velocity/6
				if velocity <= 0.1 then
					bobbleX = 0
					bobbleY = 0
				end
				
				bobbleSpring:move(Vector3.new(bobbleX,bobbleY,0))
				
				gaitOffset = gaitOffset:Lerp(CFrame.Angles(math.rad(-15),math.rad(15),0),charObj.acceleration * dt * 60)
				bobbleOffset = bobbleSpring:update(dt)
				
				offset = gaitOffset * CFrame.new(bobbleOffset.X,bobbleOffset.Y,0) * CFrame.Angles(0,bobbleOffset.X,bobbleOffset.Y)
			end
			
			adjustCursorTransparency(lerp(getCursorTransparency(),1,0.1))
		end
		
		--add sway effect
		------------------------------------------------------------------------------------------------------------
		local mouseDelta = uis:GetMouseDelta()
		swaySpring:add(Vector3.new(-mouseDelta.X/200,mouseDelta.Y/100,0))
		local swayOffset = swaySpring:update(dt)
		
		if aiming == false then
			offset *= CFrame.new(-swayOffset.X,-swayOffset.Y,0) * CFrame.Angles(swayOffset.Y,-swayOffset.X,swayOffset.X)
		else
			offset *= CFrame.new(-swayOffset.X/15,-swayOffset.Y/15,0) * CFrame.Angles(swayOffset.Y/15,-swayOffset.X/15,swayOffset.X/15)
		end
		------------------------------------------------------------------------------------------------------------
		
		--add recoil effect
		------------------------------------------------------------------------------------------------------------
		local updateRecoil,recoilPos = recoilSpring:update(dt)
		local displayRecoilY = updateRecoil.Z
		local displayRecoilX = updateRecoil.X
		if aiming == true then
			recoilOffset = recoilOffset:Lerp(CFrame.new(math.rad(displayRecoilX),0,swayOffset.Z/2) * CFrame.Angles(0,0,math.rad(swayOffset.Z)*3),weaponObj.recoilRate * 60 * dt)
		else
			recoilOffset = recoilOffset:Lerp(CFrame.new(math.rad(displayRecoilX),0,swayOffset.Z) * CFrame.Angles(0,0,math.rad(swayOffset.Z)*5),weaponObj.recoilRate * 60 * dt)
		end
		
		offset *= recoilOffset
		
		if aiming == false then
			cameraRecoilOffset *= CFrame.Angles(math.rad(updateRecoil.Y)/40,math.rad(updateRecoil.X)/40,0)
			camera.CFrame *= CFrame.Angles(math.rad(updateRecoil.Y)/40,math.rad(updateRecoil.X)/40,0)
		else
			cameraRecoilOffset *= CFrame.Angles(math.rad(updateRecoil.Y)/40,math.rad(updateRecoil.X)/40,0)
			camera.CFrame *= CFrame.Angles(math.rad(updateRecoil.Y)/2,math.rad(updateRecoil.X)/2,0)
		end
		
		if triggerDown == false or weaponObj.magCurrent == 0 or reloading == true then
			cursor.CFrame = camera.CFrame * cameraRecoilOffset:Inverse() * charObj.recentBobbleCFrame:Inverse() * gaitOffset * CFrame.Angles(swayOffset.Y + bobbleOffset.Y/3 ,-swayOffset.X + bobbleOffset.X/3 ,bobbleOffset.Y/3 + swayOffset.X) * CFrame.new(0,0,-30+ swayOffset.Z*10)
			currentSpreadAngle = lerp(currentSpreadAngle,minSpreadAngle,weaponObj.recoilRecovery * dt * 60)
			cameraRecoilOffset = cameraRecoilOffset:Lerp(CFrame.new(0,0,0),0.05 * dt * 60)
		else
			cursor.CFrame = camera.CFrame * cameraRecoilOffset:Inverse() * charObj.recentBobbleCFrame:Inverse() * gaitOffset * CFrame.Angles(math.rad(recoilPos.Y),math.rad(recoilPos.X),0) * CFrame.new(0,0,-30 + swayOffset.Z*20)
		end
		adjustCursorLength(lerp(getCursorLength(),(maxSpreadAngle-currentSpreadAngle)/maxSpreadAngle,0.6))
		------------------------------------------------------------------------------------------------------------
		if armUpdateCD - dt <= 0 then	
			armUpdateCD = armUpdateDelay
			charRemote:FireServer("replicateArms",aimOffset:Inverse():Lerp(CFrame.new(0,0,0),0.3) * CFrame.new(0,-1.5,0) * offset)
		else
			armUpdateCD -= dt
		end
		
		
		if aiming == true and weaponObj.aimPart ~= nil and charObj.dashing == false then
			rShoulder.C0 = character.Torso.CFrame:Inverse() * camera.CFrame * CFrame.new(0,-1.5,0.5) * RC0
			aimOffset = aimOffset:Lerp(camera.CFrame:Inverse() * weaponObj.aimPart.CFrame,0.15 * dt * 60)
		else
			aimOffset = aimOffset:Lerp(CFrame.new(0,0,0),0.15 * dt * 60)
		end
		
		rShoulder.C0 = character.Torso.CFrame:Inverse() * camera.CFrame * aimOffset:Inverse() * CFrame.new(0,-1.5,0.5) * offset * RC0
		lShoulder.C0 = character.Torso.CFrame:Inverse() * camera.CFrame * aimOffset:Inverse() * CFrame.new(0,-1.5,0.5) * offset * LC0
		weaponUiPart.CFrame = camera.CFrame * CFrame.new(3,-1.5,-4) * CFrame.Angles(0,math.rad(120),0) *  CFrame.new(0,bobbleOffset.Y,0) * CFrame.Angles(bobbleOffset.Y/3,bobbleOffset.X/3,0) * CFrame.new(-swayOffset.X,swayOffset.Y,0)
		
		triggerBehavior()
	end 
	
	humanoid.Changed:Connect(function()
		if humanoid.FloorMaterial == Enum.Material.Air then
			bobbleEnabled = false
		end
	end)
	
	charRemote.OnClientEvent:Connect(function(event)
		if event == "giveAmmo" and tool.Parent == character then 
			task.wait(0.05)
			updateGui("reloadFinished")
		end
	end)

	return weaponObj
end

return handler