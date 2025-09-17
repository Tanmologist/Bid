local handler = {}

local ts = game:GetService("TweenService")
local uis = game:GetService("UserInputService")
local springModule = require(game.ReplicatedStorage.Modules.SpringModule)
local statusEffects = require(script.Parent.statusEffects)

function handler.setup(charObj)
	local char = charObj.char
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local player = game.Players.LocalPlayer
	local camera = workspace.CurrentCamera
	
	local swaySpring = springModule.new()
	swaySpring.Damping = 5
	
	--local healthUIPart = workspace:FindFirstChild("HealthUiPart") or script.HealthUiPart:Clone()
	local healthUIPart = workspace:FindFirstChild("HealthUiPart") or nil
	if not healthUIPart then healthUIPart = game.ReplicatedStorage.Models.MISC.HealthUiPart:Clone() end--DEBUGGING FUNCTION, DELETE WHEN DONE
	healthUIPart.Parent = workspace
	local healthUI = healthUIPart.HealthUI
	local healthCrop = healthUI.healthBar.healthCrop
	local capCrop = healthUI.healthBar.capCrop
	local maxCrop = healthUI.healthBar.maxCrop
	local frameCrop = healthUI.healthMaxFrame.frameCrop
	local damageCrop = healthUI.healthBar.damageCrop
	local armorCrop = healthUI.armorBar.armorCrop
	
	local healKey = charObj.getKeys()["heal"]
	
	local healDebounce = false
	local damageTween = nil
	local lastDamageSize = 0
	local lastHealthSize = 1
	local healthStats = {
		healthMax = 100,
		healthCap = 100,
		healthCurrent = 100,
		healthCapMin = 50,
		
		armorMax = 100,
		armorCurrent = 0,
		
		damageCoolDown = 5,
		damageTimer = 0,
		dBarCoolDown = 0,
		dBarTimer = 0,
		
		healRateDefault = 10,
		healRate = 10, --this is the time taken for the health to return to max
		
		ifakUsesMax = 3,
		ifakUses = 3,
		
		bandageAnimID = "rbxassetid://108806090806235",
		stimAnimID = "rbxassetid://72913347686539",
		pillAnimID = "rbxassetid://124580520269459",
		
		healthUIPart = healthUIPart,
		statusEffectList = {}
	}
	local bandageAnim = Instance.new("Animation",humanoid)
	local stimAnim = Instance.new("Animation",humanoid)
	local pillAnim = Instance.new("Animation",humanoid)
	bandageAnim.AnimationId = healthStats.bandageAnimID
	stimAnim.AnimationId = healthStats.stimAnimID
	pillAnim.AnimationId = healthStats.pillAnimID
	local bandageTrack = humanoid:LoadAnimation(bandageAnim)
	local stimTrack = humanoid:LoadAnimation(stimAnim)
	local pillTrack = humanoid:LoadAnimation(pillAnim)
	
	local function setCapCrop(scale)
		frameCrop.Size = UDim2.new(scale,0,1.2,0)
		capCrop.Size = UDim2.new(1-scale,0,1,0)
		maxCrop.Size = UDim2.new(scale,0,1,0)
	end
	
	local function setHealthCrop(scale)
		lastHealthSize = healthUI.healthBar.healthCrop.Size.X.Scale
		healthUI.healthBar.healthCrop.Size = UDim2.new(scale,0,1,0)
	end
	
	local function setArmorCrop(scale)
		local armorBars = math.round(scale*10)
		for i,v in armorCrop:GetChildren() do
			if not v:IsA("UIListLayout") then
				v:Destroy()
			end
		end
		
		for i=1,armorBars do
			local newBar = armorCrop.UIListLayout.barTemplate:Clone()
			newBar.Parent = armorCrop
		end
	end
	
	local function animateDamage()
		if damageTween and damageTween:IsA("Tween") then
			damageTween:Pause()
			damageTween:Destroy()
			lastDamageSize = damageCrop.Size.X.Scale
		end
		
		local cropSize = lastHealthSize-healthCrop.Size.X.Scale+lastDamageSize
		
		damageCrop.Position = UDim2.new(healthCrop.Size.X.Scale,0,0,0)
		damageCrop.Size = UDim2.new(lastHealthSize-healthCrop.Size.X.Scale+lastDamageSize,0,1,0)
		
		healthStats.dBarTimer = cropSize
	end
	
	local function updateHealthBar()
		setCapCrop(healthStats.healthCap/healthStats.healthMax)
		setHealthCrop(healthStats.healthCurrent/healthStats.healthMax)
		setArmorCrop(healthStats.armorCurrent/healthStats.armorMax)
		
		healthUI.ifakFrame.usesLabel.Text = healthStats.ifakUses
	end
	
	local function updateStatusEffectUI()
		for effectName, effect in healthStats.statusEffectList do
			if not effect.visible then continue end
			
			local effectDuration = effect.duration
			local durationText = tostring(math.floor(effectDuration*100)/100)
			if effectDuration > 999 then durationText = "" end
			
			local durationIcon = healthUI.statusEffects:FindFirstChild(effectName)
			if not durationIcon then
				durationIcon = healthUI.statusEffects.UIListLayout.statusTemplate:Clone()
				durationIcon.Name = effectName
				durationIcon.Parent = healthUI.statusEffects
				durationIcon.Text = effectName
				durationIcon.countDown.Text = durationText
				durationIcon.BackgroundColor3 = effect.iconColor or Color3.new(1,1,1)
				durationIcon.TextColor3 = effect.iconColor or Color3.new(1,1,1)
			else
				durationIcon.countDown.Text = durationText
			end
		end
	end
	
	function healthStats.setStats(statTable)
		for key, value in pairs(statTable) do
			if healthStats[key] ~= nil then
				healthStats[key] = value
			end
		end
	end
	
	function healthStats.takeDamage(damage,damageType)
		healthStats.damageTimer = healthStats.damageCoolDown
		healthStats.armorCurrent -= damage
		if healthStats.armorCurrent < 0 then
			damage = -healthStats.armorCurrent
			healthStats.armorCurrent = 0
		else
			damage = 0
			damageType = "None"
		end
		
		local newHealth = healthStats.healthCurrent - damage
		local newHealthCap = healthStats.healthCap - damage/2
		if newHealth <= 0 then
			humanoid.Health = 0
			newHealth = 0
		end
		
		if newHealthCap <= healthStats.healthCapMin then
			newHealthCap = healthStats.healthCapMin
		else
			healthStats.healthCap = newHealthCap
		end
		healthStats.healthCurrent = newHealth
		updateHealthBar()
		animateDamage()
		healthStats.applyStatus("Hurt",math.clamp(damage*2/healthStats.healthMax,0.2,0.8))
		
		if damageType == "Bleed" then
			healthStats.applyStatus("Bleeding")
		end
	end
	
	function healthStats.applyStatus(statusName,duration)
		local status = statusEffects[statusName]
		if status ~= nil then
			if not duration then duration = statusEffects[statusName].duration end
			
			if healthStats.statusEffectList[statusName] ~= nil then
				healthStats.statusEffectList[statusName].duration = duration --no stacking, for now
			else
				local newStatus = table.clone(statusEffects[statusName])
				healthStats.statusEffectList[statusName] = newStatus
				healthStats.statusEffectList[statusName].duration = duration
				healthStats.statusEffectList[statusName]:begin(charObj,healthStats)
			end
		end
	end
	
	function healthStats.removeStatus(statusName)
		local status = statusEffects[statusName]
		if status ~= nil then
			if healthStats.statusEffectList[statusName] ~= nil then
				healthStats.statusEffectList[statusName].duration = 0
			end
		end
	end
	
	function healthStats.heal()
		if uis:IsKeyDown(healKey) and not charObj.gameProcessedEvent and not healDebounce and charObj.healing == false and charObj.leftHandFree == true and healthStats.ifakUses > 0 then
			healDebounce = true
			charObj.healing = true
			charObj.leftHandFree = false
			if healthStats.statusEffectList["Bleeding"] ~= nil and healthStats.statusEffectList["Bleeding"].duration > 5 then
				game.ReplicatedStorage.Events.CharEvent:FireServer("useIfak","Bandage")
				local bandage = char:WaitForChild("Bandage")
				
				for index, item in bandage.Bandage:GetChildren() do
					item.Changed:connect(function (property)    
						item.LocalTransparencyModifier = item.Transparency
					end)
				end
				
				charObj.createM6D(bandage:WaitForChild("Handle"),"Torso","P1")
				charObj.createM6D(bandage:WaitForChild("End"),"Torso","P2")
				
				bandageTrack:Play()
				bandageTrack.Ended:Wait()
				
				healthStats.statusEffectList["Bleeding"].duration = 0
				healthStats.damageTimer = healthStats.damageCoolDown
				healthStats.applyStatus("HealUp")
				charObj.healing = false
				charObj.leftHandFree = true
					
				healthStats.ifakUses -= 1
			elseif healthStats.healthCurrent < healthStats.healthCap-10 then
				game.ReplicatedStorage.Events.CharEvent:FireServer("useIfak","Stim")
				local stim = char:WaitForChild("Stim")
				
				for index, item in stim:GetDescendants() do
					if item:IsA("BasePart") or item:IsA("Union") or item:IsA("MeshPart") then
						item.Changed:connect(function (property)    
							item.LocalTransparencyModifier = item.Transparency
						end)
					end
				end
				
				charObj.createM6D(stim:WaitForChild("ToolHandle"),"Left Arm","Stim")
				
				stimTrack:Play()
				stimTrack.Ended:Wait()
				healthStats.healthCurrent = healthStats.healthCap
				healthStats.applyStatus("HealUp")
				charObj.healing = false
				charObj.leftHandFree = true
					
				healthStats.ifakUses -= 1
			elseif healthStats.healthCap < healthStats.healthMax then
				game.ReplicatedStorage.Events.CharEvent:FireServer("useIfak","Pills")
				local pills = char:WaitForChild("Pills")
				

				for index, item in pills:GetDescendants() do
					if item:IsA("BasePart") or item:IsA("Union") or item:IsA("MeshPart") then
						item.Changed:connect(function (property)    
							item.LocalTransparencyModifier = item.Transparency
						end)
					end
				end

				charObj.createM6D(pills:WaitForChild("ToolHandle"),"Left Arm","Pills")

				pillTrack:Play()
				pillTrack.Ended:Wait()
				healthStats.healthCap = math.min(healthStats.healthCap+15,healthStats.healthMax)
				healthStats.applyStatus("HealUp")
				charObj.healing = false
				charObj.leftHandFree = true
					
				healthStats.ifakUses -= 1
			else
				charObj.healing = false
				charObj.leftHandFree = true
			end
		elseif not uis:IsKeyDown(healKey) then
			healDebounce = false
		end
	end
	
	function healthStats.update(dt)
		if healthStats.damageTimer - dt <= 0 then
			healthStats.damageTimer = 0
			
			local healAmount = healthStats.healthMax/healthStats.healRate*dt
			healthStats.healthCurrent = math.min(healthStats.healthCurrent+healAmount,healthStats.healthCap)
		else
			healthStats.damageTimer -= dt
		end
		
		if healthStats.dBarTimer - dt <= 0 then
			healthStats.dBarTimer = 0
			
			if damageCrop.Size.X.Scale ~= 0 then
				damageTween = ts:Create(damageCrop,TweenInfo.new(0.3),{Size = UDim2.new(0,0,1,0)})
				damageTween:Play()
			end
		else
			healthStats.dBarTimer -= dt
		end
		
		updateHealthBar()
		updateStatusEffectUI()
		
		for effectName, effect in healthStats.statusEffectList do
			effect.duration -= dt
			if effect.duration <= 0 then
				effect:stop(charObj,healthStats)
				effect = nil
				healthStats.statusEffectList[effectName] = nil
				
				local effectIcon = healthUI.statusEffects:FindFirstChild(effectName) or nil
				if effectIcon then effectIcon:Destroy() end
			else
				effect:update(dt)
			end
		end
		
		healthStats.heal()
	end
	
	function healthStats.updateCFrame(dt)
		local mouseDelta = uis:GetMouseDelta()
		swaySpring:add(Vector3.new(-mouseDelta.X/200,mouseDelta.Y/100,0))
		local swayOffset = swaySpring:update(dt)
		
		healthUIPart.CFrame = camera.CFrame * CFrame.new(-5,-3.8,-7) * CFrame.Angles(0,math.rad(183),0) * CFrame.new(-swayOffset.X,swayOffset.Y,0)
	end
	
	return healthStats
end

return handler
