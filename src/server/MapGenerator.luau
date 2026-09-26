--!strict

local Workspace = game:GetService("Workspace")
local Config = require(game:GetService("ReplicatedStorage").Shared.ObbyConfig)
local Parts = require(script.Parent.ObbyParts)
local Session = require(script.Parent.ObbySession)
local MathConfig = require(game:GetService("ReplicatedStorage").Shared.MathConfig)
local MathGates = require(script.Parent.MathGateGenerator)

local MapGenerator = {}
local cleanup: (() -> ())? = nil
local regenerationHandler: (() -> SpawnLocation?)? = nil
local building = false

local function build(random: Random?, onFinished: ((Player) -> ())?): SpawnLocation
    local map = Workspace:FindFirstChild("Map")
    if map then
        assert(map:IsA("Folder") or map:IsA("Model"), "Workspace/Map must be a Folder or Model")
    else
        map = Instance.new("Folder")
        map.Name = "Map"
        map.Parent = Workspace
    end
    if cleanup then cleanup(); cleanup = nil end
    for _, child in map:GetChildren() do
        -- Migrate the previous generator's untagged platforms as well.
        local oldIndex = tonumber(child.Name:match("^Platform_(%d%d)$"))
        local legacy = child:IsA("BasePart") and (child.Name == "StartPlatform"
            or (oldIndex ~= nil and oldIndex >= 1 and oldIndex <= 10))
        if child:GetAttribute("ObbyGenerated") or legacy then child:Destroy() end
    end

    local origin = Config.StartPosition + Vector3.new(0, Config.MapHeight, 0)
    local previous = Parts.platform(map, "StartPlatform", Config.StartSize, origin, Config.StartColor)
    local start = Parts.spawn(map, previous, "StartSpawn")
    local checkpoints: {SpawnLocation} = {}
    local minimum = previous.Position - previous.Size / 2
    local maximum = previous.Position + previous.Size / 2

    local function extendBounds(part: BasePart)
        minimum = minimum:Min(part.Position - part.Size / 2)
        maximum = maximum:Max(part.Position + part.Size / 2)
    end

    for _, section in Config.Sections do
        for index = 1, section.Count do
            local x = origin.X + (if index % 2 == 0 then -section.LateralOffset else section.LateralOffset)
            local rise = if index == 1 then 0 else math.clamp(section.HeightStep, -Config.MaxHeightDifference, Config.MaxHeightDifference)
            local z = previous.Position.Z - previous.Size.Z / 2 - section.Gap - section.Size.Z / 2
            local position = Vector3.new(x, previous.Position.Y + rise, z)
            previous = Parts.platform(map, string.format("%s_%02d", section.Name, index), section.Size, position, section.Color)
            extendBounds(previous)
            if table.find(section.Checkpoints, index) then
                table.insert(checkpoints, Parts.spawn(map, previous, string.format("Checkpoint_%02d", #checkpoints + 1)))
            end
        end
    end

    local checkpointPosition = previous.Position - Vector3.new(0, 0, previous.Size.Z / 2 + MathConfig.SectionGap + MathConfig.CheckpointSize.Z / 2)
    previous = Parts.platform(map, "MathCheckpointPlatform", MathConfig.CheckpointSize, checkpointPosition, Config.CheckpointColor)
    table.insert(checkpoints, Parts.spawn(map, previous, string.format("Checkpoint_%02d", #checkpoints + 1)))
    extendBounds(previous)
    local source = random or (if Config.Seed == nil then Random.new() else Random.new(Config.Seed))
    local mathSection = MathGates.generate(map, previous, source)
    cleanup = mathSection.cleanup
    previous = mathSection.exitPlatform
    for _, floor in mathSection.floors do extendBounds(floor) end

    local finishPosition = previous.Position - Vector3.new(0, 0, previous.Size.Z / 2 + Config.FinishGap + Config.FinishSize.Z / 2)
    local finish = Parts.platform(map, "FinishPlatform", Config.FinishSize, finishPosition, Config.FinishColor)
    finish.Material = Enum.Material.Neon
    extendBounds(finish)
    local settings = Config.KillPlane
    local size = Vector3.new(maximum.X - minimum.X + settings.Margin * 2, settings.Thickness, maximum.Z - minimum.Z + settings.Margin * 2)
    local center = Vector3.new((minimum.X + maximum.X) / 2, minimum.Y - settings.Depth, (minimum.Z + maximum.Z) / 2)
    local killPlane = Parts.platform(map, "KillPlane", size, center, settings.Color)
    killPlane.Transparency = settings.Transparency
    local sessionCleanup = Session.start(start, checkpoints, killPlane, finish, onFinished)
    cleanup = function()
        mathSection.cleanup()
        sessionCleanup()
    end
    return start
end

function MapGenerator.build(random: Random?, onFinished: ((Player) -> ())?): SpawnLocation
    assert(not building, "Map generation is already running")
    building = true
    local ok, result = pcall(build, random, onFinished)
    building = false
    if not ok then
        MapGenerator.cleanup()
        error(result)
    end
    return result
end

function MapGenerator.cleanup()
    if cleanup then cleanup(); cleanup = nil end
end

function MapGenerator.setRegenerationHandler(handler: (() -> SpawnLocation?)?)
    regenerationHandler = handler
end

function MapGenerator.generate(): SpawnLocation?
    -- Existing Studio commands must also invalidate the round/countdown state.
    if regenerationHandler then return regenerationHandler() end
    return MapGenerator.build(nil, nil)
end

-- Keep the previous spelling working for existing Studio commands.
MapGenerator.Generate = MapGenerator.generate

return MapGenerator
