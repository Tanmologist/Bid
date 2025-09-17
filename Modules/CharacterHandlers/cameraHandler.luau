local handler = {}

local player = game.Players.LocalPlayer
local ts = game:GetService("TweenService")
local rs = game:GetService("RunService")

handler.cameraLocked = false
handler.oldFOV = workspace.CurrentCamera.FieldOfView
handler.oldCFrame = CFrame.new()

handler.lockToTween = nil
handler.lockToCFrame = nil

local function getZoomDist(cam)
	return (cam.Focus.Position - cam.CFrame.Position).Magnitude
end

function handler.alignHead(camera:Camera,headCFrame:CFrame)
	if handler.cameraLocked == false and (camera.Focus.Position - camera.CFrame.Position).Magnitude < 1 and player.CameraMaxZoomDistance <= 0.5 then
		local offset = camera.CFrame:Inverse()*headCFrame
		camera.CFrame *= CFrame.new(offset.X,offset.Y,offset.Z)
	end
end

function handler.lockTo(camera:Camera,camPart,fadeInTime)
	if handler.cameraLocked == false then
		handler.oldFOV = camera.FieldOfView
		handler.oldCFrame = camera.CFrame
		handler.cameraLocked = true
	end
	handler.lockToCFrame = camPart.CFrame
	
	camera.CameraType = Enum.CameraType.Scriptable
	if fadeInTime then
		local newFov = camPart:FindFirstChild("FOV")
		if newFov then
			handler.lockToTween = ts:Create(camera,TweenInfo.new(fadeInTime),{FieldOfView = newFov.Value})
			handler.lockToTween:Play()
			handler.lockToTween.Completed:Connect(function()
				handler.lockToTween = nil
			end)
		end
		ts:Create(camera,TweenInfo.new(fadeInTime),{CFrame = camPart.CFrame}):Play()
	else
		camera.CFrame = camPart.CFrame
		local newFov = camPart:FindFirstChild("FOV")
		if newFov then
			camera.FieldOfView = newFov.Value
		end
	end
end

function handler.unlock(camera:Camera)
	camera.CameraType = Enum.CameraType.Custom
	
	handler.cameraLocked = false
	camera.FieldOfView = handler.oldFOV
	camera.CFrame = handler.oldCFrame
	
	handler.lockToCFrame = nil
end

rs:BindToRenderStep("lockCamera",201,function()
	if handler.lockToTween == nil and handler.lockToCFrame then
		workspace.CurrentCamera.CFrame = handler.lockToCFrame
	end
end)

return handler
