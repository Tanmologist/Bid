--lol yeah so i made this using AI. it uh, it generates cover dynamically.
--credits to Moonshot K2

local CollectionService = game:GetService("CollectionService")
local HttpService       = game:GetService("HttpService")

local CHUNK_SIZE   = 32            -- studs
local MAX_POINTS   = 800
local RAY_LEN      = 2.2
local RAY_HEIGHT   = 1.2

local GRID_STEP = 2.4          -- even spacing (smaller = denser)
local GRID_COUNT = math.floor(CHUNK_SIZE / GRID_STEP)   -- 12 × 12 = 144 rays per chunk

local chunks       = {}            -- shared with all AIs

-- helper: world → chunk key
local function getChunkKey(x, z)
    return math.floor(x / CHUNK_SIZE) ..",".. math.floor(z / CHUNK_SIZE)
end

local function bakeChunk(cx, cz)
    local key = cx..","..cz
    if chunks[key] then return end

    local pts = {}
    local base = Vector3.new(cx * CHUNK_SIZE, 0, cz * CHUNK_SIZE)

    for ix = 0, GRID_COUNT - 1 do
        for iz = 0, GRID_COUNT - 1 do
            -- snap to exact grid centre
            local lx = (ix + 0.5) * GRID_STEP - CHUNK_SIZE * 0.5
            local lz = (iz + 0.5) * GRID_STEP - CHUNK_SIZE * 0.5
            local groundY = workspace:Raycast(base + Vector3.new(lx, 1000, lz), Vector3.yAxis * -2000)
            local gy = groundY and groundY.Position.Y or 0
            local origin = base + Vector3.new(lx, gy + RAY_HEIGHT, lz)

            local params = RaycastParams.new()
            params.FilterDescendantsInstances = {workspace:FindFirstChild("Entity")}
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.IgnoreWater = true

            for _, dir in ipairs({Vector3.xAxis, -Vector3.xAxis, Vector3.zAxis, -Vector3.zAxis}) do
                local rayDir   = -dir * RAY_LEN
                local goodHit  = nil

                for attempt = 1, 3 do
                    local rayRes = workspace:Raycast(origin, rayDir, params)
                    if rayRes then
                        local hit, p, n = rayRes.Instance, rayRes.Position, rayRes.Normal
                        if hit.Transparency < 0.01 and hit.CanCollide and hit.Size.Magnitude >= 0.5 then
                            goodHit = {pos = p + n * 0.5, normal = n}
                        end
                    elseif not rayRes then
                        break
                    end
                end

                if goodHit then
                    table.insert(pts, goodHit)
                    if #pts >= MAX_POINTS then break end
                end
            end
        end
    end

    chunks[key] = pts
end

-- public API ------------------------------------------------
local ChunkyCover = {}

function ChunkyCover:GetCoverNear(pos, radius)
    local cx, cz = math.floor(pos.X / CHUNK_SIZE), math.floor(pos.Z / CHUNK_SIZE)
    local radChunks = math.ceil(radius / CHUNK_SIZE)
    local out = {}
    for dx = -radChunks, radChunks do
        for dz = -radChunks, radChunks do
            local key = (cx + dx)..","..(cz + dz)
            local pts = chunks[key]
            if pts then
                for _, c in ipairs(pts) do
                    if (c.pos - pos).Magnitude <= radius then
                        table.insert(out, c)
                    end
                end
            end
        end
    end
    return out
end

function ChunkyCover:UpdateChunkForPosition(pos)
    local cx = math.floor((pos.X + CHUNK_SIZE/2) / CHUNK_SIZE)
    local cz = math.floor((pos.Z + CHUNK_SIZE/2) / CHUNK_SIZE)

    -- bake 3×3 neighbourhood once
    for dx = -1, 1 do
        for dz = -1, 1 do
            bakeChunk(cx + dx, cz + dz)
            --self:VisualiseChunk((cx + dx)..","..(cz + dz))
        end
    end
end

-- =============== VISUALISATION =============== --
local visFolder = nil

local function beam(startPos, endPos, parent)
    local a0 = Instance.new("Attachment")
    a0.WorldPosition = startPos
    a0.Parent = parent
    local a1 = Instance.new("Attachment")
    a1.WorldPosition = endPos
    a1.Parent = parent

    local b = Instance.new("Beam")
    b.Width0 = 0.2
    b.Width1 = 0.2
    b.Color = ColorSequence.new(Color3.new(0, 1, 0.25))
    b.LightEmission = 1
    b.Attachment0 = a0
    b.Attachment1 = a1
    b.Parent = parent
end

function ChunkyCover:VisualiseChunk(key)
    if not chunks[key] then return end
    if not visFolder then
        visFolder = Instance.new("Folder")
        visFolder.Name = "CoverVisual"
        visFolder.Parent = workspace
    end
    -- destroy old tile if repainting
    local old = visFolder:FindFirstChild(key)
    if old then old:Destroy() end

    local tile = Instance.new("Folder")
    tile.Name = key
    tile.Parent = visFolder

    for _, c in ipairs(chunks[key]) do
        -- tiny ball at cover point
        local ball = Instance.new("Part")
        ball.Shape = Enum.PartType.Ball
        ball.Size = Vector3.one * 0.6
        ball.Position = c.pos
        ball.Anchored = true
        ball.CanCollide = false
        ball.Color = Color3.new(0, 1, 0.25)
        ball.Material = Enum.Material.Neon
        ball.Parent = tile

        -- thin beam showing normal direction
        beam(c.pos, c.pos + c.normal * 2, tile)
    end
end

function ChunkyCover:ClearVisualisation()
    if visFolder then visFolder:Destroy() visFolder = nil end
end


--------------------------------------------------------------------
--method for goobers, no i meant selecting the best cover
--------------------------------------------------------------------

local function coverQuality(agentPos, coverNormal, threatPos)
    local dirToThreat = (threatPos - agentPos).Unit
    return coverNormal:Dot(dirToThreat)
end

function ChunkyCover:GetWeightedCover(agentPos, threatPos, radius, minQuality)
    minQuality = minQuality or 0.3
    local allPoints = self:GetCoverNear(agentPos, radius)

    local scored = {}
    for _, c in ipairs(allPoints) do
        local score = coverQuality(agentPos, c.normal, threatPos)
        if score >= minQuality then
            local dist  = (c.pos - agentPos).Magnitude
            local final = score * 100 - dist          -- higher = better
            table.insert(scored, {
                pos    = c.pos,
                normal = c.normal,
                score  = final,
                weight = math.max(0, final)
            })
        end
    end

    -- best → worst
    table.sort(scored, function(a, b) return a.score > b.score end)
    return scored
end


return ChunkyCover