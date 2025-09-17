local module = {}

local ts = game:GetService("TweenService")

local cameraShaker = require(game.ReplicatedStorage.Modules.CameraShaker)

module.Dementia = {
	duration = 10,
	visible = true,
	iconColor = Color3.new(1,1,1),

	begin = function(self,charObj,healthStatus)
		
	end,
	update = function(self,dt)
		
	end,
	stop = function(self,charObj,healthStatus)
		
	end
}

module.Bleeding = {
	duration = 20,
	visible = true,
	iconColor = Color3.new(1, 0.501961, 0.501961),
	flashFrame = nil,
	flashTransparencyDelta = 0,
	flashRate = 5,
	
	begin = function(self,charObj,healthStatus)
		game.Players.LocalPlayer.PlayerScripts.characterController.getCharObj:Fire("changeHealthStatus","healRate",math.huge)
		
		local healthUIPart = workspace:FindFirstChild("HealthUiPart")
		local healthCrop = healthUIPart.HealthUI.healthBar.healthCrop
		self.flashFrame = healthCrop:Clone()
		self.flashFrame.Parent = healthCrop.Parent
		self.flashFrame.BackgroundColor3 = Color3.new(1, 0.490196, 0.490196)
	end,
	update = function(self,dt)
		local healthUIPart = workspace:FindFirstChild("HealthUiPart")
		self.flashFrame.Size = healthUIPart.HealthUI.healthBar.healthCrop.Size
		
		self.flashTransparencyDelta += dt * self.flashRate
		self.flashFrame.BackgroundTransparency = math.abs(math.sin(self.flashTransparencyDelta))
	end,
	stop = function(self,charObj,healthStatus)
		game.Players.LocalPlayer.PlayerScripts.characterController.getCharObj:Fire("changeHealthStatus","healRate",healthStatus.healRateDefault)
		self.flashFrame:Destroy()
	end
}

module.Hurt = {
	duration = 0.2,
	visible = false,
	hurtFX = nil,
	startDuration = 0,
	camShake = nil,

	begin = function(self,charObj,healthStatus)
		local fxMain = game.Players.LocalPlayer.PlayerGui.FXMain
		self.hurtFX = fxMain:FindFirstChild("hurtFX")
		if not self.hurtFX then
			self.hurtFX = Instance.new("ImageLabel",fxMain)
			self.hurtFX.Size = UDim2.fromScale(1,1)
			self.hurtFX.Image = "rbxassetid://10089830466"
			self.hurtFX.BackgroundTransparency = 1
			self.hurtFX.ImageColor3 = Color3.new(0.5,0.5,0.5)
			self.hurtFX.Name = "hurtFX"
		end
		
		self.startDuration = self.duration
		
		
		local hurtShake = cameraShaker.CameraShakeInstance.new(25*(self.duration*10),0.2,0,self.duration)
		hurtShake.RotationInfluence = Vector3.new(0,0,math.rad(math.random(-1,1)*20*self.duration))
		hurtShake.PositionInfluence = Vector3.new(math.random(-1,1)*0.01,0,0)
		
		local camera = workspace.CurrentCamera
		self.camShake = cameraShaker.new(201, function(shakeCf)
			camera.CFrame = camera.CFrame * shakeCf
		end)
		self.camShake:Start()
		self.camShake:Shake(hurtShake)
	end,
	update = function(self,dt)
		self.hurtFX.ImageTransparency = 1 - self.duration/self.startDuration
	end,
	stop = function(self,charObj,healthStatus)
		self.hurtFX:Destroy()
	end
}


module.Suppress = {
	duration = 1,
	visible = false,
	suppressedFX = nil,
	startDuration = 0,
	camShake = nil,

	begin = function(self,charObj,healthStatus)
		local fxMain = game.Players.LocalPlayer.PlayerGui.FXMain
		self.suppressedFX = fxMain:FindFirstChild("suppressedFX")
		if not self.suppressedFX then
			self.suppressedFX = Instance.new("ImageLabel",fxMain)
			self.suppressedFX.AnchorPoint = Vector2.new(0.5,0.5)
			self.suppressedFX.Position = UDim2.fromScale(0.5,0.5)
			self.suppressedFX.Size = UDim2.fromScale(1.3,1.3)
			self.suppressedFX.Image = "rbxassetid://10351256026"
			self.suppressedFX.BackgroundTransparency = 1
			self.suppressedFX.ImageColor3 = Color3.new(0.5,0.5,0.5)
			self.suppressedFX.Name = "suppressedFX"
		end
		
		self.duration = math.random(50,100)/100
		self.startDuration = self.duration

		local camera = workspace.CurrentCamera
		self.camShake = cameraShaker.new(201, function(shakeCf)
			camera.CFrame = camera.CFrame * shakeCf
		end)
		self.camShake:Start()
	end,
	update = function(self,dt)
		self.suppressedFX.ImageTransparency = 1 - self.duration/self.startDuration
		if self.duration == self.startDuration - dt then
			local suppressShake = cameraShaker.CameraShakeInstance.new(45,0.2,0,0.5)
			suppressShake.RotationInfluence = Vector3.new(0,0,math.rad(math.random(-1,1)*45))
			suppressShake.PositionInfluence = Vector3.new(math.random(-1,1)*0.01,0,0)
			
			self.camShake:Shake(suppressShake)
		end
	end,
	stop = function(self,charObj,healthStatus)
		self.suppressedFX:Destroy()
	end
}

module.UpArmor = {
	duration = 1,
	visible = false,
	uparmorFX = nil,

	begin = function(self,charObj,healthStatus)
		local fxMain = game.Players.LocalPlayer.PlayerGui.FXMain
		self.uparmorFX = fxMain:FindFirstChild("uparmorFX")
		if self.uparmorFX then
			self.uparmorFX:Destroy()
		end
		
		self.uparmorFX = Instance.new("ImageLabel",fxMain)
		self.uparmorFX.Size = UDim2.fromScale(1,1)
		self.uparmorFX.Image = "rbxassetid://81991366852993"
		self.uparmorFX.BackgroundTransparency = 1
		self.uparmorFX.ImageTransparency = 1
		self.uparmorFX.ImageColor3 = Color3.new(0.313725, 0.701961, 1)
		self.uparmorFX.Name = "uparmorFX"
		
		ts:Create(self.uparmorFX,TweenInfo.new(0.1,Enum.EasingStyle.Cubic,Enum.EasingDirection.In),{ImageTransparency = 0}):Play()

		self.startDuration = self.duration
	end,
	update = function(self,dt)
	
	end,
	stop = function(self,charObj,healthStatus)
		ts:Create(self.uparmorFX,TweenInfo.new(0.1,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out),{ImageTransparency = 1}):Play()
		task.wait(0.1)
		self.uparmorFX:Destroy()
	end
}

module.HealUp = {
	duration = 0.4,
	visible = false,
	healUpFX = nil,

	begin = function(self,charObj,healthStatus)
		local fxMain = game.Players.LocalPlayer.PlayerGui.FXMain
		self.healUpFX = fxMain:FindFirstChild("healupFX")
		if self.healUpFX then
			self.healUpFX:Destroy()
		end

		self.healUpFX = Instance.new("ImageLabel",fxMain)
		self.healUpFX.Size = UDim2.fromScale(1,1)
		self.healUpFX.Image = "rbxassetid://81991366852993"
		self.healUpFX.BackgroundTransparency = 1
		self.healUpFX.ImageTransparency = 1
		self.healUpFX.ImageColor3 = Color3.new(1, 1, 1)
		self.healUpFX.Name = "healupFX"

		ts:Create(self.healUpFX,TweenInfo.new(0.2,Enum.EasingStyle.Cubic,Enum.EasingDirection.In),{ImageTransparency = 0.5}):Play()

		self.startDuration = self.duration
		
		local sfx = game.SoundService.HealthSound.HealUpSFX:Clone()
		sfx.Parent = charObj.char.Head
		sfx.PlayOnRemove = true
		sfx:Destroy()
	end,
	update = function(self,dt)

	end,
	stop = function(self,charObj,healthStatus)
		ts:Create(self.healUpFX,TweenInfo.new(0.2,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out),{ImageTransparency = 1}):Play()
		task.wait(0.1)
		self.healUpFX:Destroy()
	end
}

module.Dash = {
	duration = 0.2,
	visible = false,
	uparmorFX = nil,
	oldFOV = 0,

	begin = function(self,charObj,healthStatus)
		local fxMain = game.Players.LocalPlayer.PlayerGui.FXMain
		self.dashFX = fxMain:FindFirstChild("uparmorFX")
		if self.dashFX then
			self.dashFX:Destroy()
		end

		self.dashFX = Instance.new("ImageLabel",fxMain)
		self.dashFX.Size = UDim2.fromScale(1,1)
		self.dashFX.Image = "rbxassetid://81991366852993"
		self.dashFX.BackgroundTransparency = 1
		self.dashFX.ImageTransparency = 1
		self.dashFX.Name = "uparmorFX"
		
		self.oldFOV = workspace.CurrentCamera.FieldOfView
		self.startDuration = self.duration
		
		task.spawn(function()
			ts:Create(self.dashFX,TweenInfo.new(self.duration/3,Enum.EasingStyle.Cubic,Enum.EasingDirection.In),{ImageTransparency = 0}):Play()
			ts:Create(workspace.CurrentCamera,TweenInfo.new(self.duration/3,Enum.EasingStyle.Cubic,Enum.EasingDirection.In),{FieldOfView = self.oldFOV-5}):Play()
			task.wait(self.startDuration/3)
			ts:Create(self.dashFX,TweenInfo.new(self.startDuration*2,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out),{ImageTransparency = 1}):Play()
			ts:Create(workspace.CurrentCamera,TweenInfo.new(self.startDuration*2,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out),{FieldOfView = self.oldFOV}):Play()
			task.wait(self.startDuration*2)
			self.dashFX:Destroy()
		end)
		
		game.ReplicatedStorage.Remotes.charRemote:FireServer("dash")
	end,
	update = function(self,dt)
	
	end,
	stop = function(self,charObj,healthStatus)
	
	end
}



return module
