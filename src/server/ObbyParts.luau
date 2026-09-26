--!strict

local Config = require(game:GetService("ReplicatedStorage").Shared.ObbyConfig)
local ObbyParts = {}

local function configure(part: BasePart, parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3)
    part.Name = name
    part.Size = size
    part.Position = position
    part.Anchored = true
    part.CanCollide = true
    part.CanTouch = true
    part.Color = color
    part.Material = Config.Material
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part:SetAttribute("ObbyGenerated", true)
    part.Parent = parent
end

function ObbyParts.platform(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3): Part
    local part = Instance.new("Part")
    configure(part, parent, name, size, position, color)
    return part
end

function ObbyParts.spawn(parent: Instance, platform: BasePart, name: string): SpawnLocation
    local spawn = Instance.new("SpawnLocation")
    spawn.Neutral = true
    spawn.AllowTeamChangeOnTouch = false
    spawn.Duration = 0
    local position = platform.Position + Vector3.new(0, (platform.Size.Y + Config.SpawnSize.Y) / 2, 0)
    configure(spawn, parent, name, Config.SpawnSize, position, Config.CheckpointColor)
    return spawn
end

return ObbyParts
