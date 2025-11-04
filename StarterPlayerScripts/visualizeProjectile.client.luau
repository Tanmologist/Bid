local ts = game:GetService("TweenService")
local rs = game:GetService("RunService")
local debris = game:GetService("Debris")
local replicatedStorage = game:GetService("ReplicatedStorage")

local remotes = replicatedStorage:WaitForChild("Remotes")
local hitregRemote = remotes:WaitForChild("hitregRemote")

local beams = {}
local function makeBeam()
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CanQuery = false
	p.Size = Vector3.one; p.Transparency = 1

	local a0 = Instance.new("Attachment", p)
	local a1 = Instance.new("Attachment", p)
	local b  = Instance.new("Beam", p)
	b.Attachment0 = a0
	b.Attachment1 = a1
	b.Width0 = 0.3
	b.Width1 = 0.3
	b.LightEmission = 1
	b.LightInfluence = 0
	b.Texture = "rbxassetid://13838761937"   -- 1×32 white gradient
	b.Color = ColorSequence.new(Color3.fromRGB(255, 255, 240))
	p.Parent = workspace:FindFirstChild("Projectiles") or workspace
	return {part = p, att0 = a0, att1 = a1, beam = b}
end

hitregRemote.OnClientEvent:Connect(function(action,param1,param2)
	if action == "spawn" then
	local sender = workspace.ENTITIES:FindFirstChild(param1.senderID)
	local b = makeBeam()

	-- wait until AFTER arms update this frame
	game:GetService("RunService"):BindToRenderStep("spawnTracer", 203, function()
		local barrel = sender and sender:FindFirstChild("Barrel", true)
		local tailPos = (barrel and barrel.Position) or param1.origin
		b.att0.WorldPosition = tailPos
		b.att1.WorldPosition = tailPos
		beams[param1.id] = {
			beam      = b,
			startTime = workspace:GetServerTimeNow(),
			pkt       = param1
		}
		game:GetService("RunService"):UnbindFromRenderStep("spawnTracer")
	end)
	elseif action == "remove" then
		local data = beams[param1.id]
		if not data then return end

		data.beam.part:Destroy()
	elseif action == "landed" then
		local data = beams[param1.id]
		if not data then return end
		beams[param1.id] = nil

		-- smooth fade to final point
		ts:Create(data.beam.att1, TweenInfo.new(0.05), {WorldPosition = param1.pos}):Play()

		-- optional impact fx
		local isChar = param1.part.Parent:FindFirstChildOfClass("Humanoid")
		local fxName = isChar and "BloodPart" or "ImpactPart"
		local fx     = replicatedStorage.Models.MISC:FindFirstChild(fxName):Clone()

		fx.CFrame = CFrame.lookAt(param1.pos, param1.pos + param1.norm)
		fx.Parent = workspace

		local longestLifetime = 0
		for _,item in fx:GetDescendants() do
			if item:IsA("Sound") then
				item:Play()
			elseif item:IsA("ParticleEmitter") then
				item:Emit(15)
				if item.Lifetime.Max > longestLifetime then
					longestLifetime = item.Lifetime.Max
				end
			end
		end
		debris:AddItem(fx,longestLifetime)

		task.wait(0.05)
		data.beam.part:Destroy()
	elseif action == "destroy" then		
		
	end
end)

rs.Heartbeat:Connect(function()
	local now = workspace:GetServerTimeNow()
	for id, data in pairs(beams) do
		local dt = now - data.startTime
		local maxDist = data.pkt.vel.Magnitude * data.pkt.lifetime
		local dir = data.pkt.vel.Unit
		local headPos = data.pkt.origin + dir * math.min((data.pkt.vel * dt).Magnitude, maxDist)

		data.beam.att1.WorldPosition = headPos
		data.beam.att0.WorldPosition = data.beam.att0.WorldPosition:Lerp(headPos, 0.1)

		local cam = workspace.CurrentCamera
		local dist = (data.beam.att0.WorldPosition - cam.CFrame.Position).Magnitude
		local width = math.clamp(dist * 0.02, 0.2, 1)  -- 0.1 near, 0.6 max
		data.beam.beam.Width0 = width
		data.beam.beam.Width1 = width
	end
end)