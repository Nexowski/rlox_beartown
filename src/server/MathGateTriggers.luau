--!strict

local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.MathConfig)
local ProjectConfig = require(Shared.Config)

export type Door = { part: BasePart, answer: number, correctAnswer: number }

local MathGateTriggers = {}

function MathGateTriggers.start(doors: {Door}): () -> ()
    local active = true
    local connections: {RBXScriptConnection} = {}
    local lastTouches: {[Player]: {[BasePart]: {character: Model, time: number}}} = {}

    for _, door in doors do
        table.insert(connections, door.part.Touched:Connect(function(hit: BasePart)
            if not active then return end
            local character = hit:FindFirstAncestorOfClass("Model")
            if not character then return end
            local player = Players:GetPlayerFromCharacter(character)
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local root = character:FindFirstChild("HumanoidRootPart")
            if not player or player.Character ~= character or not humanoid or humanoid.Health <= 0
                or not root or not root:IsA("BasePart") then return end
            local offset = door.part.CFrame:PointToObjectSpace(root.Position)
            local limit = door.part.Size / 2 + Vector3.one * Config.TouchTolerance
            if math.abs(offset.X) > limit.X or math.abs(offset.Y) > limit.Y or math.abs(offset.Z) > limit.Z then return end

            local now = os.clock()
            local touches = lastTouches[player]
            if not touches then
                touches = {}
                lastTouches[player] = touches
            end
            local previous = touches[door.part]
            if previous and previous.character == character and now - previous.time < Config.DebounceSeconds then return end
            touches[door.part] = { character = character, time = now }

            -- Compare server-owned numbers, never GUI text or client messages.
            local correct = door.answer == door.correctAnswer
            if ProjectConfig.DebugMode then
                print(string.format("[MathGate] Player %s selected %d - %s", player.Name, door.answer, if correct then "correct" else "incorrect"))
            end
            if not correct then humanoid.Health = 0 end
        end))
    end
    table.insert(connections, Players.PlayerRemoving:Connect(function(player)
        lastTouches[player] = nil
    end))

    return function()
        active = false
        for _, connection in connections do connection:Disconnect() end
        table.clear(connections)
        table.clear(lastTouches)
    end
end

return MathGateTriggers
