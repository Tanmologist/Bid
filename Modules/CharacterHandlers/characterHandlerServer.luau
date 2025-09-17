local handler = {}

local riseMagnitude = 1
local RC0 = CFrame.new(1, .5, 0, 0, 0, riseMagnitude, 0, riseMagnitude, 0, -riseMagnitude, 0, 0)
local LC0 = CFrame.new(-1, .5, 0, 0, 0, -riseMagnitude, 0, riseMagnitude, 0, riseMagnitude, 0, 0)
local NC0 = CFrame.new( 0, 1, 0, -1, -0, -0, 0, 0, 1, 0, 1, 0)
local TC0 = CFrame.new(0, 0, 0, -1, -0, -0, 0, 0, 1, 0, 1, 0)
local LHC0 = CFrame.new(-1, -1, 0, -0, -0, -1, 0, 1, 0, 1, 0, 0)
local RHC0 = CFrame.new(1, -1, 0, 0, 0, 1, 0, 1, 0, -1, -0, -0)

function handler.tiltChar(camCFrame,character,movementOffset,armOffset,spinOffset)
	if character:FindFirstChild("Torso") == nil or character.Torso:FindFirstChild("Neck") == nil then return CFrame.new(0,0,0) end
	local neck = character.Torso:FindFirstChild("Neck")
	local torso = character.HumanoidRootPart:FindFirstChild("RootJoint")

	local x,y,z = character.HumanoidRootPart.RootJoint.Transform:ToOrientation()

	local rShoulder = character.Torso["Right Shoulder"]
	local lShoulder = character.Torso["Left Shoulder"]
	local rHip = character.Torso["Right Hip"]
	local lHip = character.Torso["Left Hip"]
	local toolGrip = character.Torso:FindFirstChild("ToolGrip")
	
	local rootVelocity = character.HumanoidRootPart.CFrame:VectorToObjectSpace(character.HumanoidRootPart.Velocity)
	movementOffset = movementOffset:Lerp(CFrame.Angles(0,0,-character.HumanoidRootPart.CFrame.RightVector:Dot(character.Humanoid.MoveDirection)/2),0.2)
	
	local spinDelta = 0
	if rootVelocity.Magnitude < 0.5 and spinOffset then
		local _, y = camCFrame.Rotation:ToEulerAnglesYXZ() --Get the angles of the camera
		local _,spinY = spinOffset.Rotation:ToEulerAnglesYXZ()
		spinDelta = (y - spinY + math.pi) % (2*math.pi) - math.pi
	end

	local tool = character:FindFirstChildOfClass("Tool")
	if tool then
		rShoulder.C0 = character.Torso.CFrame:Inverse() * character.Head.CFrame * armOffset * RC0
		lShoulder.C0 = character.Torso.CFrame:Inverse() * character.Head.CFrame * armOffset * LC0
	else
		rShoulder.C0 = RC0 
		lShoulder.C0 = LC0 
	end
	
	local legOffset = movementOffset.UpVector.X*1.5
	if math.round(rootVelocity.Z) >= 1 then
		neck.C0 = neck.C0:Lerp(NC0 * CFrame.Angles(-camCFrame.lookVector.Y, 0, 0) * movementOffset:Inverse():Lerp(CFrame.new(0,0,0),0.5),0.05)
		torso.C0 = torso.C0:Lerp(TC0 * CFrame.Angles(-camCFrame.lookVector.Y/2.5,0,0) * movementOffset:Lerp(CFrame.new(0,0,0),0.5),0.05)
		lHip.C0 = lHip.C0:Lerp(LHC0 * CFrame.Angles(0,legOffset,camCFrame.lookVector.Y/2.5),0.1)
		rHip.C0 = rHip.C0:Lerp(RHC0 * CFrame.Angles(0,legOffset,-camCFrame.lookVector.Y/2.5),0.1)
	else
		neck.C0 = neck.C0:Lerp(NC0 * CFrame.Angles(-camCFrame.lookVector.Y, 0, spinDelta/3) * movementOffset:Inverse(),0.1)
		torso.C0 = torso.C0:Lerp(TC0 * CFrame.Angles(-camCFrame.lookVector.Y/2.5,0,0) * movementOffset,0.1)
		lHip.C0 =  lHip.C0:Lerp(CFrame.Angles(-camCFrame.lookVector.Y/2.5,-spinDelta*2/3,0) * LHC0 * CFrame.Angles(0,-legOffset,0) * CFrame.new(0,0,legOffset),0.1)
		rHip.C0 =  rHip.C0:Lerp(CFrame.Angles(-camCFrame.lookVector.Y/2.5,-spinDelta*2/3,0) * RHC0 * CFrame.Angles(0,-legOffset,0) * CFrame.new(0,0,-legOffset),0.1)
	end
	
	return movementOffset
end

function handler.connectM6D(character,targetPart,parentPart,M6DName)
	if not M6DName then M6DName = "Handle" end
	local M6D = character[parentPart]:FindFirstChild(M6DName)
	if not M6D then
		M6D = Instance.new("Motor6D",character[parentPart])
		M6D.Name = M6DName
	end

	M6D.Part0 = character[parentPart]
	M6D.Part1 = targetPart
end

function handler.disconnectM6D(handle,character)
	local M6D = character["Right Arm"]:FindFirstChild("Handle")
	M6D.Part0 = character["Right Arm"]
	M6D.Part1 = nil
end

return handler
