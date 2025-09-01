-- OP system server-side support (independent). Uses centrally created MoneyChangeRemote and safely handles requests.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require SaveS with WaitForChild convention
local SaveS = require(script.Parent:WaitForChild("SyncS"):WaitForChild("SaveS"))

-- Remotes are created by RemotesBootstrap.server.luau
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local MoneyChangeRemote = Remotes:WaitForChild("MoneyChangeRemote")

-- Handle money change requests from clients
MoneyChangeRemote.OnServerEvent:Connect(function(player, payload)
	local old = SaveS:Get(player, "Money") or 0
	local new = old

	if typeof(payload) == "number" then
		-- Backward compatibility: numeric delta
		new = old + payload
	elseif typeof(payload) == "table" and payload ~= nil then
		local action = payload.action
		if action == "add" then
			local amount = tonumber(payload.amount)
			if amount == nil then return end
			new = old + amount
		elseif action == "clear" then
			new = 0
		else
			return -- unknown action
		end
	else
		return -- invalid payload
	end

	if new ~= old then
		SaveS:Set(player, "Money", new)
		print("[opS] Player", player.Name, "money changed:", old, "->", new)
		-- Do not FireClient here; Sync pipeline will notify clients via SaveS:OnChanged
	end
end)

