local handler = {}

local function castHit(char,castOrigin,castDirection) --the point of this is to make raycast ignore accessory parts and parts with no collision
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {char}
	while true do
		local raycastResult = workspace:Raycast(castOrigin,castDirection,raycastParams)
		if not raycastResult then
			return nil
		else --ray hit something, check whether or not to start a new round of iteration
			local castInstance = raycastResult.Instance
			if (castInstance.Transparency ~= 1 and castInstance.CanCollide == true) or castInstance:FindFirstChildOfClass("ProximityPrompt") then  --only non transparent parts with collision will be registered
				return raycastResult
			else 
				local newParameters = raycastParams.FilterDescendantsInstances
				table.insert(newParameters,raycastResult.Instance)
				raycastParams.FilterDescendantsInstances = newParameters
			end
		end
	end
end

function handler.checkInteract(charObj)
	local camera = workspace.CurrentCamera
	
	local castOrigin = camera.CFrame.Position
	local castDirection = camera.CFrame.LookVector * charObj.interactDistance
	
	local raycastResult = castHit(charObj.char,castOrigin,castDirection)
	if raycastResult and raycastResult.Instance then
		local interactPrompt = raycastResult.Instance:FindFirstChildOfClass("ProximityPrompt")
		return interactPrompt
	end
end

function handler.runInteract(charObj)
	local interactSubject = charObj.interactSubject
	local interactEvent = interactSubject:FindFirstChildOfClass("RemoteEvent")
	
	interactEvent:FireServer()
end

return handler
