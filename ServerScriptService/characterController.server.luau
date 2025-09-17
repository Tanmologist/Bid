local phs = game:GetService("PhysicsService")
local rs = game:GetService("RunService")
local debris = game:GetService("Debris")
local replicatedStorage = game:GetService("ReplicatedStorage")

local remotes = replicatedStorage:WaitForChild("Remotes")
local charRemote = remotes:WaitForChild("charRemote")

local characterHandler = require(replicatedStorage.Modules.characterHandlerServer)

local VMCollision, CharCollision = phs:RegisterCollisionGroup("VMCollision"), phs:RegisterCollisionGroup("CharCollision")
phs:CollisionGroupSetCollidable("VMCollision","CharCollision",false)

game.Players.PlayerAdded:Connect(function(player)
	local movementOffset = CFrame.new()
	local armOffset = CFrame.new()
	local spinOffset = CFrame.new()
	charRemote.OnServerEvent:Connect(function(plr,action,param1,param2,param3)
		if plr == player and player.Character then
			local char = player.Character
			if action == "tiltChar" then
				spinOffset = param2
				movementOffset = characterHandler.tiltChar(param1,char,movementOffset,armOffset,spinOffset)
			elseif action == "connectM6D" then
				characterHandler.connectM6D(char,param1,param2,param3)
			elseif action == "disconnectM6D" then
				characterHandler.disconnectM6D(param1,char)
			elseif action == "replicateArms" then
				armOffset = param1
			elseif action == "useIfak" then
				local medItem = game.ReplicatedStorage.Modules.healthHandler[param1]:Clone()
				medItem:PivotTo(char.Torso.CFrame)
				medItem.Parent = char
				debris:AddItem(medItem,2.5)
			elseif action == "dash" then
				local dashSound = game.SoundService.MovementSound.DashSound:Clone()
				dashSound.Parent = char.Head
				dashSound.PlayOnRemove = true
				dashSound:Destroy()
			elseif action == "examine" then
				if not param2 then param2 = 2 end

				local lootItem = param1
				param1.Parent = char
				debris:AddItem(param1,param2)
			end
		end
	end)
end)