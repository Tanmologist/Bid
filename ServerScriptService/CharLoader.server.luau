local rs = game:GetService("RunService")
local ps = game:GetService("PhysicsService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local remotes = replicatedStorage:WaitForChild("Remotes")
local charRemote = remotes:WaitForChild("charRemote")

local playerCollisionGroup = "Players"
ps:RegisterCollisionGroup(playerCollisionGroup)
ps:CollisionGroupSetCollidable(playerCollisionGroup, playerCollisionGroup, false)

local function loadKit(plr:Player,kitName)	
	task.wait(0.1)
	local targetKit = game.ReplicatedStorage.Models.Kits:FindFirstChild(kitName)
	if not targetKit then
		warn("Target kit:",kitName," does not exist")
	else
		local charRemote = game.ReplicatedStorage.Remotes.charRemote
		local char = plr.Character

		local primary = targetKit.Primary:FindFirstChildOfClass("Tool"):Clone()
		local secondary =  targetKit.Secondary:FindFirstChildOfClass("Tool"):Clone()
		primary.Parent = plr.Backpack
		secondary.Parent = plr.Backpack

		charRemote:FireClient(plr,"setEquipment","primary",primary)
		charRemote:FireClient(plr,"setEquipment","secondary",secondary)

		local kitStats = require(targetKit:FindFirstChildOfClass("ModuleScript"))
		charRemote:FireClient(plr,"changeCharSettings",kitStats.charSettings)
		charRemote:FireClient(plr,"changeHealthSettings",kitStats.healthSettings)

		for index, item in char:GetDescendants() do
			if (item:IsA("BasePart") or item:IsA("MeshPart")) and (item.Name ~= "HumanoidRootPart") then
				item.Transparency = 0
			end
		end

		for index, item in targetKit.Equipment:GetChildren() do
			local model = item:Clone()
			local part = model:FindFirstChildOfClass("BasePart") or model:FindFirstChildOfClass("MeshPart")
			part.Transparency = 1

			local bodyPart = char:FindFirstChild(part.Name)
			local newWeld = Instance.new("Weld",bodyPart)
			part.Parent = bodyPart
			newWeld.Part0 = bodyPart
			newWeld.Part1 = part
		end
	end
end

local function removeAccessories(char)
	for index, item in pairs(char:GetDescendants()) do
		if item:IsA("BasePart") then -- if it is a part
			item.Transparency = 1 -- make it invisible
			item.CollisionGroup = playerCollisionGroup
		elseif item:IsA("Decal") then
			item.Transparency = 1
		elseif item:IsA("Accessory") then
			local hairAttach = item.Handle:FindFirstChild("HairAttachment")
			if hairAttach then 
				task.spawn(function()
					local oldHandle = item.Handle
					local accessoryMesh = item.Handle.SpecialMesh
					local newHandle = game.AssetService:CreateMeshPartAsync(Content.fromUri(accessoryMesh.MeshId)) --false flag, this is Roblox Asset API for getting meshID
					newHandle.Parent = item
					newHandle.Name = "Handle"
					hairAttach.Parent = newHandle
					newHandle.Material = Enum.Material.Plaster
					newHandle.Transparency = 1

					oldHandle:Destroy()
					item.Parent = workspace
					task.wait()
					item.Parent = char
				end)
			else
				item:Destroy()
			end
		end
	end
end

if rs:IsStudio() then
	game.Players.PlayerAdded:Connect(function(plr)
		plr.CharacterAdded:Connect(function(char)
			charRemote:FireClient(plr,"loadCharacter")
			removeAccessories(char)

			task.wait(1)
			charRemote:FireClient(plr,"loadKit")
		end)
	end)
	
	charRemote.OnServerEvent:Connect(function(plr,event,param1,param2)
		if event == "loadKit" then --equivalent to spawn
			loadKit(plr,"TEST")
			plr.Character.Parent = workspace.ENTITIES
		end
	end)
	
	return
end
