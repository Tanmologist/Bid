local ts = game:GetService("TweenService")
local debris = game:GetService("Debris")
local replicatedStorage = game:GetService("ReplicatedStorage")

local remotes = replicatedStorage:WaitForChild("Remotes")
local hitregRemote = remotes:WaitForChild("hitregRemote")

local lingerTime = 0.05

local function updateProjectile(projectile)
	if not projectile.senderID then return end
	projectile.sender = workspace.ENTITIES:GetChildren()[projectile.senderID]
	
	local modelID = projectile.modelID
	
	local projectilesFolder = game.Workspace:FindFirstChild("projectilesFolder")
	if not projectilesFolder then
		projectilesFolder = Instance.new("Folder",workspace)
		projectilesFolder.Name = "projectilesFolder"
	end

	if projectile.sender then
		local startPos = projectile.position
		local endPos = projectile.position + projectile.velocity/60
		local projectileSource = projectile.sender:FindFirstChild("Barrel",true)

		local projectileModel = projectilesFolder:FindFirstChild(modelID)
		if not projectileModel then
			projectileModel = game.ReplicatedStorage.Models.MISC.bullet:Clone()
			projectileModel.Parent = projectilesFolder
			projectileModel.Name = modelID
			projectileModel.Trail.Lifetime = lingerTime/(projectile.velocity.Magnitude/100)

			if projectileSource then
				startPos = projectileSource.Position
				endPos = projectileSource.position + projectile.velocity*lingerTime
				projectileModel.Position = startPos
				task.wait(lingerTime/4)
				ts:Create(projectileModel,TweenInfo.new(lingerTime*3/4),{Position = endPos}):Play()
			end
		end

		if projectileSource and (projectileModel.Position - projectileSource.Position).Magnitude > projectile.velocity.Magnitude*lingerTime*0.9 then
			startPos = projectileModel.Position
			endPos = projectileModel.Position + projectile.velocity/60
			ts:Create(projectileModel,TweenInfo.new(1/60),{Position = endPos}):Play()
		end
	else
		local projectileModel = projectilesFolder:FindFirstChild(modelID)
		if not projectileModel then
			projectileModel = game.ReplicatedStorage.Models.MISC.bullet:Clone()
			projectileModel.Parent = projectilesFolder
			projectileModel.Name = modelID
			projectileModel.Trail.Lifetime = lingerTime/(projectile.velocity.Magnitude/300)
		end
		
		
		local startPos = projectile.position
		local endPos = projectile.position + projectile.velocity/60
		ts:Create(projectileModel,TweenInfo.new(1/60),{Position = endPos}):Play()
	end
	
end



local projectileList = {}
hitregRemote.OnClientEvent:Connect(function(action,param1,param2)
	if action == "update" then
		updateProjectile(param1)
	elseif action == "updateAll" then
		for index, projectile in param1 do
			updateProjectile(projectile)
		end
	elseif action == "destroy" then		
		local projectilesFolder = game.Workspace:FindFirstChild("projectilesFolder") or nil
		if not projectilesFolder then
			projectilesFolder = Instance.new("Folder",workspace)
			projectilesFolder.Name = "projectilesFolder"
		end
		
		local projectileModel = projectilesFolder:FindFirstChild(param1.modelID)
		if projectileModel then projectileModel:Destroy() end
		
		if param2 and param2[3] then
			local ImpactPart
			
			local humanoid = param2[3].Parent:FindFirstChildOfClass("Humanoid")
			if humanoid then
				ImpactPart = game.ReplicatedStorage.Models.MISC.BloodPart:Clone()
			else
				ImpactPart = game.ReplicatedStorage.Models.MISC.ImpactPart:Clone()
			end
			
			ImpactPart.Parent = workspace
			ImpactPart.CFrame = CFrame.lookAt(param2[1],param2[1]+param2[2])
			
			local longestLifetime = 0
			for index,item in ImpactPart:GetDescendants() do
				if item:IsA("Sound") then
					item:Play()
				elseif item:IsA("ParticleEmitter") then
					item:Emit(15)
					if item.Lifetime.Max > longestLifetime then
						longestLifetime = item.Lifetime.Max
					end
				end
			end
			debris:AddItem(ImpactPart,longestLifetime)
		end
		
	end
end)