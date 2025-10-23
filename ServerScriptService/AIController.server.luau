--stupid school just severed internet connection. I'm down to the simplest tools.
--I'll try build a AI system's framework from scratch
--This **should** be separated into different modules scripts, or not you know what no cuz im lazy
--This **should** be made into a single module script

--chunk based cover dectection test?
local runService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local chunkyCover = require(replicatedStorage.Modules.chunkyCover)
local KITTY = require(replicatedStorage.Modules.KITTY)
local KITTYTree = require(replicatedStorage.Modules.KITTYTree)
local KITTYBoard = require(replicatedStorage.Modules.KITTYBoard)



---------------------------------------------------------
--KITTY TESTING KITTY TESTING KITTY TESTING KITTY TESTING
--KITTY TESTING KITTY TESTING KITTY TESTING KITTY TESTING
--KITTY TESTING KITTY TESTING KITTY TESTING KITTY TESTING
--KITTY TESTING KITTY TESTING KITTY TESTING KITTY TESTING
---------------------------------------------------------
local SUCCESS, FAILURE, RUNNING = 1, 2, 3

local kitten = KITTY:New(Workspace.Goobers)
local newTree = KITTYTree.newSelector({
     KITTYTree.newLeaf(function(kitten)
        if #kitten.core.visibleEnemies > 0 then
            print("OMG OMG OMG THERES A PERSON OMG OMG")
            return SUCCESS
        end
        return FAILURE
    end),
    KITTYTree.newLeaf(function(kitten)
        print("I'm quite literally blind")
    end)
})

kitten.tree = newTree

runService.Heartbeat:Connect(function(dt)
    kitten:Update(dt)
    KITTYBoard:Update(dt)
    
    KITTYBoard:updateEntities()
end)
---------------------------------------------------------
--KITTY TESTING KITTY TESTING KITTY TESTING KITTY TESTING
--KITTY TESTING KITTY TESTING KITTY TESTING KITTY TESTING
--KITTY TESTING KITTY TESTING KITTY TESTING KITTY TESTING
--KITTY TESTING KITTY TESTING KITTY TESTING KITTY TESTING
---------------------------------------------------------