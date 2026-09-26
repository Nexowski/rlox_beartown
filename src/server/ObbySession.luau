--!strict

local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage").Shared.ObbyConfig)
local ObbySession = {}

-- The returned cleanup function owns every connection and all session state.
function ObbySession.start(start: SpawnLocation, checkpoints: {SpawnLocation}, killPlane: BasePart, finish: BasePart, onFinished: ((Player) -> ())?): () -> ()
    local active = true
    local connections: {RBXScriptConnection} = {}
    local characterConnections: {[Player]: RBXScriptConnection} = {}
    local progress: {[Player]: number} = {}

    local function moveCharacter(player: Player, character: Model)
        local root = character:WaitForChild("HumanoidRootPart", 10)
        local humanoid = character:WaitForChild("Humanoid", 10)
        if not active or not root or not root:IsA("BasePart") or player.Character ~= character then return end
        if not humanoid or not humanoid:IsA("Humanoid") or humanoid.Health <= 0 then return end
        local index = progress[player]
        if index == nil then return end
        local spawn = if index == 0 then start else checkpoints[index]
        character:PivotTo(spawn.CFrame + Vector3.new(0, spawn.Size.Y / 2 + Config.SpawnClearance, 0))
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end

    local function addPlayer(player: Player)
        if progress[player] ~= nil then return end
        progress[player] = 0
        player.RespawnLocation = start
        characterConnections[player] = player.CharacterAdded:Connect(function(character)
            task.spawn(moveCharacter, player, character)
        end)
        if player.Character then task.spawn(moveCharacter, player, player.Character) end
    end

    -- Confirm a living player and proximity on the server, not client messages.
    local function touchingPlayer(hit: BasePart, target: BasePart): (Player?, Humanoid?)
        if not active then return nil, nil end
        local character = hit:FindFirstAncestorOfClass("Model")
        if not character then return nil, nil end
        local player = Players:GetPlayerFromCharacter(character)
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local root = character:FindFirstChild("HumanoidRootPart")
        if not player or progress[player] == nil or not humanoid or humanoid.Health <= 0
            or not root or not root:IsA("BasePart") then return nil, nil end
        local offset = target.CFrame:PointToObjectSpace(root.Position)
        local limit = target.Size / 2 + Vector3.one * Config.TouchTolerance
        if math.abs(offset.X) > limit.X or math.abs(offset.Y) > limit.Y or math.abs(offset.Z) > limit.Z then
            return nil, nil
        end
        return player, humanoid
    end

    for index, checkpoint in checkpoints do
        table.insert(connections, checkpoint.Touched:Connect(function(hit)
            local player = touchingPlayer(hit, checkpoint)
            if player and progress[player] == index - 1 then
                progress[player] = index
                player.RespawnLocation = checkpoint
            end
        end))
    end
    table.insert(connections, killPlane.Touched:Connect(function(hit)
        local _, humanoid = touchingPlayer(hit, killPlane)
        if humanoid then humanoid.Health = 0 end
    end))
    table.insert(connections, finish.Touched:Connect(function(hit)
        local player = touchingPlayer(hit, finish)
        if player and progress[player] == #checkpoints and onFinished then
            onFinished(player)
        end
    end))
    table.insert(connections, Players.PlayerAdded:Connect(addPlayer))
    table.insert(connections, Players.PlayerRemoving:Connect(function(player)
        local connection = characterConnections[player]
        if connection then connection:Disconnect() end
        characterConnections[player] = nil
        progress[player] = nil
    end))
    for _, player in Players:GetPlayers() do addPlayer(player) end

    return function()
        active = false
        for _, connection in connections do connection:Disconnect() end
        for player, connection in characterConnections do
            connection:Disconnect()
            player.RespawnLocation = nil
        end
        table.clear(characterConnections)
        table.clear(progress)
    end
end

return ObbySession
