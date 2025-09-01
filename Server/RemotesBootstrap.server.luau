-- RemotesBootstrap.server.luau
-- Centralized creation of all RemoteEvents used by the project.
-- Server scripts should only WaitForChild these remotes; do NOT recreate them elsewhere.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
	Remotes = Instance.new("Folder")
	Remotes.Name = "Remotes"
	Remotes.Parent = ReplicatedStorage
end

local function ensureRemoteEvent(name: string)
	local existing = Remotes:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local ev = Instance.new("RemoteEvent")
	ev.Name = name
	ev.Parent = Remotes
	return ev
end

-- Define all remote events here
ensureRemoteEvent("MoneyChangeRemote")
ensureRemoteEvent("SaveDataRemote")
ensureRemoteEvent("FlowDataRemote")
ensureRemoteEvent("CharacterSelectRemote")

-- Add new remote names above; other scripts must ONLY WaitForChild.
