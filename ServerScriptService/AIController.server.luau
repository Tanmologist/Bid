--stupid school just severed internet connection. I'm down to the simplest tools.
--I'll try build a AI system's framework from scratch
--This **should** be separated into different modules scripts, or not you know what no cuz im lazy
--This **should** be made into a single module script

--chunk based cover dectection test?
local runService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

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

local leaf = KITTYTree.newLeaf
local sel  = KITTYTree.newSelector
local seq  = KITTYTree.newSequence


local kitten = KITTY:New(Workspace.Goobers)

local function condition(factName) --PLS PLS PLS REMEMBER TO KEEP THIS
    return leaf(function(kitten)
        return kitten:factActive(factName) and SUCCESS or FAILURE
    end)
end

local contactReaction = seq({
    leaf(function(kitten, dt)
        if #kitten.core.visibleEnemies == 0 then return FAILURE end
        if kitten:factActive("Reacting") then return SUCCESS end
        kitten:addFact("Reacting", kitten.stats.reactionTime+0.5, 5, {startTime = kitten.core.now})
        return SUCCESS
    end),
    leaf(function(kitten, dt)
        if not kitten:factActive("Reacting") then return FAILURE end
        local react = kitten.core.facts["Reacting"]
        if kitten.core.now - react.data.startTime > kitten.stats.reactionTime then
            kitten:addFact("inCombat", kitten.stats.combatBuffer, 8)
            return SUCCESS
        end

        return RUNNING   -- still reacting
    end)
})

local combatInitiator = sel({
    condition("inCombat"),
    contactReaction
})

local combatTree = sel({
    leaf(function(kitty,dt)

        if #kitten.core.visibleEnemies > 0 then
            kitten.core.wantsLook = kitten.core.visibleEnemies[1].rig.HumanoidRootPart.Position
        end

        return SUCCESS
    end)
    --reload when ammo is at zero, there could also be a reload sequence, so the dude will find cover instead of reload in the open
    --take cover if not already in one, switch cover if compromised
    --reload
    --shoot people and a bunch of attack functions
})

local veteranCombatBehavior = seq({
    combatInitiator,
    combatTree
})

kitten.tree = veteranCombatBehavior

kitten.mover:addLocation(workspace.testA.Position)
kitten.mover:addLocation(workspace.testB.Position)

---------------------------------------------------------
--KITTY RUNNING KITTY RUNNING KITTY RUNNING KITTY RUNNING
---------------------------------------------------------
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


--[[ 
SORRY I KEEP FORGETTING
|                 | **Selector** (OR)                                                   | **Sequence** (AND)                                                             |
| --------------- | ------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Purpose**     | *"Try kids left→right until one **succeeds**."*                     | *"Run kids left→right until one **fails**."*                                   |
| **Stops on**    | **First SUCCESS**                                                   | **First FAILURE**                                                              |
| **Returns**     | `SUCCESS` if any child succeeded, otherwise `FAILURE`               | `SUCCESS` only if **all** children succeeded, otherwise `FAILURE`              |
| **Typical use** | *"Do **any** of these tactics work?"*<br>Attack OR Search OR Patrol | *"Do **every** step of this plan."*<br>WalkToDoor AND OpenDoor AND WalkThrough |
| **Nickname**    | **"Fallback"**                                                      | **"Chain"**                                                                    |



SAMPLE TREE IN CASE YOU FORGET

local tree = KITTYTree.newSelector({
    KITTYTree.newLeaf(function(kitten, dt)
        print(kitten.rig.Name, "thinks")
        return SUCCESS
    end),
    KITTYTree.newLeaf(function(kitten, dt)
        kitten:addFact("Demo", 1, 10)
        return kitten:factActive("Demo") and RUNNING or SUCCESS
    end)
})
]]