local players = game:GetService("Players")
local runService = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local remotes = replicatedStorage:WaitForChild("Remotes")
local charRemote = remotes:WaitForChild("charRemote")
local suppressRemote = remotes:WaitForChild("suppressRemote")
local getCharObj = Instance.new("BindableEvent",script)
getCharObj.Name = "getCharObj"

game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false)

local charHandler = require(game.ReplicatedStorage.Modules.characterHandlerLocal) --Doesn't need to be here *as for now*, change this directory to wherever you put characterHandlerLocal
local camHandler = require(game.ReplicatedStorage.Modules.cameraHandler)
local inventoryHandler = require(game.ReplicatedStorage.Modules.inventoryHandlerLocal)
local interactHandler = require(game.ReplicatedStorage.Modules.interactHandler)
local healthHandler = require(game.ReplicatedStorage.Modules.healthHandler)

local player = players.LocalPlayer
local charObject --Note that I use camel casing, this would be prefered as to differ from roblox's API
local charInventory
local healthStatus

runService.Heartbeat:Connect(function(dt)
	if charObject then
		charObject.movement(dt)
		charObject.dash(dt)
		charObject.interactSubject = interactHandler.checkInteract(charObject) --check if character can interact
		if charObject.interact(dt) then --basically the interact countdown
			interactHandler.runInteract(charObject) --when interact bar is full the interact is ran idk
		end
		if charObject.dashTimer+dt == charObject.dashCoolDown then
			healthStatus.applyStatus("Dash",charObject.dashDistance/charObject.dashSpeed)
		end
		
		charObject.charInventory = charInventory
		getCharObj:Fire("sync",charObject)
	end
end)

runService:BindToRenderStep("characterUpdate",200,function(dt)
	if charObject then 
		charObject.update(dt)
		healthStatus.update(dt)
		if healthStatus.healthCurrent == 0 then
			charObject.dead = true
		end
		healthStatus.updateCFrame(dt)
	end
end)

uis.InputBegan:Connect(function(input,gameProcessedEvent)
	if charObject then
		charInventory.equipTools(input.KeyCode)
		charObject.gameProcessedEvent = gameProcessedEvent
	end
end)

local function handleEvent(action,param1,param2,sender)
	if action == "changeCharObj" then
		charObject[param1] = param2
	elseif action == "changeHealthStatus" then
		healthStatus[param1] = param2
	elseif action == "takeDamage" then
		healthStatus.takeDamage(param1,param2)	
	elseif action == "applyStatus" then
		healthStatus.applyStatus(param1)
	elseif action == "removeStatus" then
		healthStatus.removeStatus(param1)
	elseif action == "giveIfak" then
		if not param1 then param1 = 1 end
		healthStatus.ifakUses = math.min(healthStatus.ifakUses+param1,healthStatus.ifakUsesMax)
		if sender then sender:FireServer("success") end
	elseif action == "addHealth" then
		if not param1 then param1 = 100 end
		healthStatus.healthCurrent = math.clamp(healthStatus.healthCurrent+param1,0,healthStatus.healthCap)
		healthStatus.applyStatus("HealUp")
		if sender then sender:FireServer("success") end
	elseif action == "addHealthCap" then
		if not param1 then param1 = 100 end
		healthStatus.healthCap = math.clamp(healthStatus.healthCurrent+param1,0,healthStatus.healthMax)
		if sender then sender:FireServer("success") end
	elseif action == "giveArmor" then
		if healthStatus.armorCurrent < healthStatus.armorMax and sender then
			sender:FireServer("success")
			healthStatus.applyStatus("UpArmor")
		end
		
		if param1 then
			healthStatus.armorCurrent = math.clamp(healthStatus.armorCurrent+param1,0,healthStatus.armorMax)
		else
			healthStatus.armorCurrent = healthStatus.armorMax
		end
	elseif action == "giveAmmo" then
		if not charInventory[param1.."Ammo"] then
			print(param1.."Ammo does not exist.")
		else
			local ammo = charInventory[param1.."Ammo"]
			local ammoMax = charInventory[param1.."Ammo".."Max"]
			if ammo < ammoMax then
				charInventory[param1.."Ammo"] = math.clamp(ammo+param2,0,ammoMax)
				if sender then sender:FireServer("success") end
			end
		end
	elseif action == "setAmmo" then
		if not charInventory[param1] then
			print(param1.." does not exist.")
		end
		charInventory[param1] = param2
	elseif action == "setEquipment" then
		if param1 == "primary" then
			charInventory.setPrimary(param2)
		elseif param1 == "secondary" then
			charInventory.setSecondary(param2)
		end
	elseif action == "changeCharSettings" then
		charObject.setStats(param1)
	elseif action == "changeHealthSettings" then
		healthStatus.setStats(param1)
	elseif action == "examine" then
		charObject.examine(param1)
		if sender then sender:FireServer("success") end
	elseif action == "operate" then
		charInventory.unequipTools()
		charObject.operate(param1,param2)
	elseif action == "loadCharacter" then
		charRemote:FireServer("loadKit")
		
		charObject = charHandler.setup(player)

		charObject.GuiMain = game.ReplicatedStorage.UI.GuiMain:Clone()
		charObject.FXMain = game.ReplicatedStorage.UI.FXMain:Clone()

		charObject.GuiMain.Parent = player.PlayerGui
		charObject.FXMain.Parent = player.PlayerGui
		
		charInventory = inventoryHandler.setup(charObject)
		healthStatus = healthHandler.setup(charObject)
		--charObject.GuiMain.debuggingStuff.Visible = true
		--charObject.GuiMain.debuggingStuff.applyBleedingDebuff.Activated:Connect(function()
		--	healthStatus.applyStatus("Bleeding")
		--end)
	end
end

getCharObj.Event:Connect(function(action,param1,param2,sender)
	handleEvent(action,param1,param2,sender)
end)

charRemote.OnClientEvent:Connect(function(action,param1,param2,sender)
	handleEvent(action,param1,param2,sender)
end)

suppressRemote.OnClientEvent:Connect(function(suppressLocation,suppressRange)
	if charObject and charObject.char then 
		local effectDist = (suppressLocation - charObject.char.HumanoidRootPart.Position).Magnitude
		if effectDist < suppressRange then
			healthStatus.applyStatus("Suppress")
		end
	end
end)