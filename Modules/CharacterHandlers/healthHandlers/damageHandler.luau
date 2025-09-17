local handler = {}
handler.damageLog = {}

function handler.castDamage(dealer:Model,receiver:Model,castInfo:any)
	--temporary anti teamkill fix
	if (game.Players:GetPlayerFromCharacter(dealer) and game.Players:GetPlayerFromCharacter(receiver)) or dealer == nil then
		return
	end
	
	local castDamge = castInfo.baseDamage
	local finalDamage
	local subjectHumanoid = receiver:FindFirstChildOfClass("Humanoid")
	--headshot and limbshot multipliers not implemented yet
	if castInfo.shotLimb == "Head" then
		finalDamage = castDamge * castInfo.headshotMultiplier
	elseif castInfo.shotLimb ~= "Torso" then
		finalDamage = castDamge * castInfo.limbshotMultiplier
	else	
		finalDamage = castDamge
	end
	
	local damageLog = dealer.Name .. "-->" .. receiver.Name .. ":" .. tostring(castDamge)
	table.insert(handler.damageLog,damageLog)
	--print(damageLog)
	
	local hitPlayer = game.Players:GetPlayerFromCharacter(receiver)
	if hitPlayer then
		game.ReplicatedStorage.Remotes.charRemote:FireClient(hitPlayer,"takeDamage",finalDamage,castInfo.damageType)
	elseif receiver:FindFirstChild("BehaviorHandler") then
		receiver.BehaviorHandler:FindFirstChildOfClass("Script").rigEvent:Fire("attack",dealer)
		subjectHumanoid:TakeDamage(finalDamage)
	else
		subjectHumanoid:TakeDamage(finalDamage)
	end
end

function handler.clearLog()
	handler.damageLog = {}
end

return handler
