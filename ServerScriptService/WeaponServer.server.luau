local debris = game:GetService("Debris")
local rs = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local remotes = replicatedStorage:WaitForChild("Remotes")
local hitregRemote = remotes:WaitForChild("hitregRemote")
local weaponRemote = remotes:WaitForChild("weaponRemote")

local projectileHandler = require(game.ReplicatedStorage.Modules.ProjectileHandler)

hitregRemote.OnServerEvent:Connect(function(sender,castOrigin,castDirection,castInfo)
	if sender:IsA("Player") then
		castInfo.sender = sender.Character
	else
		castInfo.sender = sender
	end
	projectileHandler.new(castOrigin,castDirection,castInfo)
end)

weaponRemote.OnServerEvent:Connect(function(plr,action,weapon)
	local weapon = plr.Character:FindFirstChild(weapon.Name)
	if action == "Fire" then
		local barrel = weapon:FindFirstChild("Barrel",true)
		
		for index,item in barrel:GetDescendants() do
			if item:IsA("Sound") then
				item:Play()
			elseif item:IsA("ParticleEmitter") then
				item:Emit(20)
			end
		end
	elseif action == "Equip" then
		local handle = weapon:FindFirstChild("Handle",true)
		if handle == nil then handle = weapon:FindFirstChild("GunHandle",true)end
		local equipSound = handle:FindFirstChild("EquipSound")
		if equipSound then equipSound:Play() else
			local equipSound = game.SoundService.GunSound.MISC.EquipSound:Clone()
			equipSound.Parent = handle
			equipSound:Play()
		end
	elseif action == "Reload" then
		local handle = weapon:FindFirstChild("Handle",true)
		if handle == nil then handle = weapon:FindFirstChild("GunHandle",true) end
		local reloadSound = handle:FindFirstChild("ReloadSound")
		if reloadSound then reloadSound:Play() else
			local reloadSound = game.SoundService.GunSound.MISC.ReloadSound:Clone()
			reloadSound.Parent = handle
			reloadSound:Play()
		end
	end
end)

rs.Heartbeat:Connect(function(dt)
	projectileHandler.onStep(dt)
	projectileHandler.fireAllClients()
end)

local knowledgeHandler = require(game.ReplicatedStorage.Modules.factionKnowledgeHandler)
local entities = workspace.ENTITIES
entities.ChildAdded:Connect(function(child)
	knowledgeHandler.updateKnowledgeBase(child)
end)

entities.ChildRemoved:Connect(function()
	knowledgeHandler.updateKnowledgeBase()
end)