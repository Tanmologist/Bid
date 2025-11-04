local remotes = game.ReplicatedStorage:WaitForChild("Remotes")

local suppressRemote = remotes:WaitForChild("suppressRemote")

local damageHandler = require(script.Parent.damageHandler)

local handler = {}

function handler.getServerBehavior(behaviorName)
    local serverBehaviors = {
        standard = function(projectile,raycastResult)
            local humanoid = raycastResult.Instance.Parent:FindFirstChildOfClass("Humanoid")
            if humanoid then
                local castInfo = {
                    baseDamage = projectile.baseDamage,
                    damageType = projectile.damageType,
                    headshotMultiplier = projectile.headshotMultiplier,
                    limbshotMultiplier  = projectile.limbshotMultiplier,
                    shotDistance = (projectile.startPosition - raycastResult.Position).Magnitude,
                    shotLimb = raycastResult.Instance.Name
                }
                damageHandler.castDamage(projectile.sender, humanoid.Parent, castInfo)
            else
                suppressRemote:FireAllClients(raycastResult.Position,projectile.suppression)
            end
        end,
    }

    return serverBehaviors[behaviorName]
end

return handler