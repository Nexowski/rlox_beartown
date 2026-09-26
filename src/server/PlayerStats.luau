--!strict

local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local PlayerStats = {}
local connection: RBXScriptConnection? = nil

function PlayerStats.ensure(player: Player): (IntValue, IntValue)
    local folder = player:FindFirstChild("leaderstats")
    if folder then
        assert(folder:IsA("Folder"), "leaderstats must be a Folder")
    else
        folder = Instance.new("Folder")
        folder.Name = "leaderstats"
        folder.Parent = player
    end
    local function stat(name: string): IntValue
        local existing = folder:FindFirstChild(name)
        if existing then
            assert(existing:IsA("IntValue"), name .. " must be an IntValue")
            return existing
        end
        local value = Instance.new("IntValue")
        value.Name = name
        value.Value = 0
        value.Parent = folder
        return value
    end
    return stat("Wins"), stat("Coins")
end

function PlayerStats.reward(player: Player)
    local wins, coins = PlayerStats.ensure(player)
    wins.Value += Config.WinReward
    coins.Value += Config.CoinReward
end

function PlayerStats.start()
    if connection then return end
    connection = Players.PlayerAdded:Connect(PlayerStats.ensure)
    for _, player in Players:GetPlayers() do PlayerStats.ensure(player) end
end

function PlayerStats.stop()
    if connection then connection:Disconnect(); connection = nil end
end

return PlayerStats
