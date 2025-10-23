local SUCCESS, FAILURE, RUNNING = 1,2,3
local tree = {}

local Node = {}
Node.__index = Node

function Node:New(t)
    setmetatable(t,Node)
    return t
end

function Node:Update(kitten, dt)
     if self.category == "leaf" then
        return self.execute(kitten, dt)     -- your custom code
    elseif self.category == "selector" then
        for _, child in ipairs(self.children) do
            local s = child:Update(kitten, dt)
            if s ~= FAILURE then return s end
        end
        return FAILURE
    elseif self.category == "sequence" then
        for _, child in ipairs(self.children) do
            local s = child:Update(kitten, dt)
            if s ~= SUCCESS then return s end
        end
        return SUCCESS
    end
end

function tree.newLeaf(execute)
    return Node:New({category = "leaf", execute = execute})
end
function tree.newSelector(children)
    return Node:New({category = "selector", children = children})
end
function tree.newSequence(children)
    return Node:New({category = "sequence", children = children})
end

return tree