local handler = {}

local ts = game:GetService("TweenService")

function handler.setup(charObj)
	local char = charObj.char
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local player = game.Players.LocalPlayer
	
	local inventoryUI = charObj.GuiMain.inventoryUI
	
	local equipping = 0
	local showDuration = 0.2
	local switchDuration = 0.3
	local inventoryTween = TweenInfo.new(switchDuration,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out)
	
	local inventory = {
		primary = nil,
		secondary = nil,
		gear = nil,
		
		primaryAmmo = 100,
		primaryAmmoMax = 100,
		secondaryAmmo = 100,
		secondaryAmmoMax = 100,
		utility1AmmoMax = 0,
		utility1Ammo = 0,
		utility2AmmoMax = 0,
		utility2Ammo = 0,
	}
	
	local keys = {
		primary = Enum.KeyCode.One,
		secondary = Enum.KeyCode.Two,
		utility1 = Enum.KeyCode.Three,
		utility2 = Enum.KeyCode.Four
	}
	
	local function adjustFrameTransparency(frame,transparency,tweenInfo)
		for _,v in pairs(frame:GetDescendants()) do
			if v:IsA("Frame") and v.Name ~= "emptyFrame" then
				ts:Create(v,tweenInfo,{BackgroundTransparency = transparency}):Play()
			elseif v:IsA("ViewportFrame") then
				ts:Create(v,tweenInfo,{ImageTransparency = transparency}):Play()
			elseif v:IsA("ImageLabel") then
				ts:Create(v,tweenInfo,{ImageTransparency = transparency}):Play()
			end
		end
	end
	
	local function adjustFrameLocation(frame,targetSize,targetPosition)
		ts:Create(frame,inventoryTween,{Position = targetPosition, Size = targetSize}):Play()
	end
	
	local sizeDeductionPerSlot = 0.3
	local transparencyIncreasePerSlot = 0.6
	local function setPrimarySlot(slot)
		local currentSlot = slot
		
		local function getFrameDimensions(pos)
			local framePosition
			local frameSize
			
			local posSizeDeduction = math.abs(math.clamp(pos*sizeDeductionPerSlot,-1,1))
			if pos < 0 then
				frameSize = UDim2.new(1-posSizeDeduction,0,(1-posSizeDeduction)/2,0)
				framePosition = UDim2.new((1-sizeDeductionPerSlot)*pos,0,posSizeDeduction/2,0)
			elseif pos > 0 then
				frameSize = UDim2.new(1-pos*sizeDeductionPerSlot,0,(1-posSizeDeduction)/2,0)
				framePosition = UDim2.new(1+(1-sizeDeductionPerSlot)*(pos-1),0,posSizeDeduction/2,0)
			elseif pos == 0 then
				frameSize = UDim2.new(1,0,0.5,0)
				framePosition = UDim2.new(0,0,0,0)
			end
			return frameSize, framePosition
		end
		
		local newFrameSize, newFramePosition = getFrameDimensions(currentSlot)
		adjustFrameLocation(inventoryUI.primary,newFrameSize,newFramePosition)
		adjustFrameTransparency(inventoryUI.primary,math.abs(currentSlot)*transparencyIncreasePerSlot,inventoryTween)
		currentSlot += 1
		
		local newFrameSize, newFramePosition = getFrameDimensions(currentSlot)
		adjustFrameLocation(inventoryUI.secondary,newFrameSize,newFramePosition)
		adjustFrameTransparency(inventoryUI.secondary,math.abs(currentSlot)*transparencyIncreasePerSlot,inventoryTween)
		currentSlot += 1
		
		local newFrameSize, newFramePosition = getFrameDimensions(currentSlot)
		adjustFrameLocation(inventoryUI.utility1,newFrameSize,newFramePosition)
		adjustFrameTransparency(inventoryUI.utility1,math.abs(currentSlot)*transparencyIncreasePerSlot,inventoryTween)
		currentSlot += 1
		
		local newFrameSize, newFramePosition = getFrameDimensions(currentSlot)
		adjustFrameLocation(inventoryUI.utility2,newFrameSize,newFramePosition)
		adjustFrameTransparency(inventoryUI.utility2,math.abs(currentSlot)*transparencyIncreasePerSlot,inventoryTween)
	end
	
	local function updateGUI(slot)
		inventoryUI.Visible = true
		equipping += 1

		if slot == "primary" then
			setPrimarySlot(0)
		elseif slot == "secondary" then
			setPrimarySlot(-1)
		elseif slot == "utility1" then
			setPrimarySlot(-2)
		elseif slot == "utility2" then
			setPrimarySlot(-3)
		end
		
		task.wait(switchDuration+showDuration)		
		equipping -= 1
		if equipping == 0 then
			adjustFrameTransparency(inventoryUI.primary,1,TweenInfo.new(0.1))
			adjustFrameTransparency(inventoryUI.secondary,1,TweenInfo.new(0.1))
			adjustFrameTransparency(inventoryUI.utility1,1,TweenInfo.new(0.1))
			adjustFrameTransparency(inventoryUI.utility2,1,TweenInfo.new(0.1))
			task.wait(0.1)
			inventoryUI.Visible = false
		end
	end
	
	
	function inventory.getKeys()
		return keys
	end
	
	function inventory.setKeys(newKeys)
		keys = newKeys
	end
	
	function inventory.setPrimary(tool)
		if tool.Parent == player.Backpack then inventory.primary = tool end
		if inventory.primary ~= nil then
			local viewportCam = Instance.new("Camera",inventory.primary)
			local inventoryModel = inventory.primary:FindFirstChildOfClass("Model"):Clone()
			local handle = inventoryModel:FindFirstChild("Handle") or inventoryModel:FindFirstChild("GunHandle")
			inventoryUI.primary.viewportFrame.CurrentCamera = viewportCam
			inventoryUI.primary.emptyFrame.Visible = false
			inventoryUI.primary.viewportFrame:ClearAllChildren()
			inventoryModel.Parent = inventoryUI.primary.viewportFrame
			viewportCam.CFrame = handle.CFrame * inventoryModel.viewportOffset.Value
			
			
			for index, part in inventoryModel:GetDescendants() do
				if part:IsA("BasePart") then
					--local part = Instance.new("Part")
					part.Color = Color3.new(1,1,1)
					part.Material = Enum.Material.Neon
				end
			end
			
			tool:FindFirstChildOfClass("LocalScript").Enabled = true
		end
	end
	
	function inventory.setSecondary(tool)
		if tool.Parent == player.Backpack then inventory.secondary = tool end
		if inventory.secondary ~= nil then
			local viewportCam = Instance.new("Camera",inventory.secondary)
			local inventoryModel = inventory.secondary:FindFirstChildOfClass("Model"):Clone()
			local handle = inventoryModel:FindFirstChild("Handle") or inventoryModel:FindFirstChild("GunHandle")
			inventoryUI.secondary.viewportFrame.CurrentCamera = viewportCam
			inventoryUI.secondary.emptyFrame.Visible = false
			inventoryUI.secondary.viewportFrame:ClearAllChildren()
			inventoryModel.Parent = inventoryUI.secondary.viewportFrame
			viewportCam.CFrame = handle.CFrame * inventoryModel.viewportOffset.Value

			for index, part in inventoryModel:GetDescendants() do
				if part:IsA("BasePart") then
					--local part = Instance.new("Part")
					part.Color = Color3.new(1,1,1)
					part.Material = Enum.Material.Neon
				end
			end
			
			tool:FindFirstChildOfClass("LocalScript").Enabled = true
		end
	end
	
	function inventory.fillAmmo(target,value)
		local targetAmmo = target.."Ammo"
		
		local newAmmo = inventory[targetAmmo] + value
		inventory[targetAmmo] = math.min(newAmmo, inventory[targetAmmo.."Max"])
		if newAmmo > inventory[targetAmmo.."Max"] then
			return newAmmo - inventory[targetAmmo.."Max"] --in case of spill over
		else
			return 0
		end
	end
	
	function inventory.equipTools(input)
		if charObj.mainHandFree == false then return end
		local currentTool = char:FindFirstChildOfClass("Tool")
		if input == keys.primary and inventory.primary then
			if inventory.primary == currentTool and currentTool ~= nil then
				humanoid:UnequipTools()
			else
				humanoid:EquipTool(inventory.primary)
				updateGUI("primary")
			end
		elseif input == keys.secondary and inventory.secondary then
			if inventory.secondary == currentTool and currentTool ~= nil then
				humanoid:UnequipTools()
			else
				humanoid:EquipTool(inventory.secondary)
				updateGUI("secondary")
			end
		elseif input == keys.utility1 then
			if (inventory.utility1 == currentTool and currentTool ~= nil) or inventory.utility2 == nil then
				humanoid:UnequipTools()
				updateGUI("utility1")
			else
				humanoid:EquipTool(inventory.utility1)
				updateGUI("utility1")
			end
		elseif input == keys.utility2 then
			if (inventory.utility2 == currentTool and currentTool ~= nil) or inventory.utility2 == nil then
				humanoid:UnequipTools()
				updateGUI("utility2")
			else
				humanoid:EquipTool(inventory.utility2)
				updateGUI("utility2")
			end
		end
	end
	
	function inventory.unequipTools()
		humanoid:UnequipTools()
	end
	
	return inventory
end

return handler