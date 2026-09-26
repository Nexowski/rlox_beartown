--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Config = require(ReplicatedStorage.Shared.Config)
local ObbyConfig = require(ReplicatedStorage.Shared.ObbyConfig)
local MapGenerator = require(script.Parent.MapGenerator)
local PlayerStats = require(script.Parent.PlayerStats)

local RoundManager = { CurrentRound = 0, State = "Stopped" }
local completed: {[number]: boolean} = {}
local event: RemoteEvent? = nil
local joined: RBXScriptConnection? = nil
local deadline = 0
local revision = 0
local epoch = 0
local started = false
local random: Random = Random.new()

local function debugLog(message: string)
    if Config.DebugMode then print("[Round] " .. message) end
end

local function notify(kind: string, recipient: Player?)
    revision += 1
    local seconds = if RoundManager.State == "Finishing" then math.max(0, math.ceil(deadline - os.clock())) else 0
    for _, player in (if recipient then { recipient } else Players:GetPlayers()) do
        local payload = {
            kind = kind, round = RoundManager.CurrentRound, state = RoundManager.State,
            seconds = seconds, completed = completed[player.UserId] == true,
            wins = Config.WinReward, coins = Config.CoinReward, revision = revision,
        }
        -- Atomic snapshot covers late LocalScripts, respawns and late joiners.
        player:SetAttribute("RoundSnapshot", HttpService:JSONEncode(payload))
        if event then event:FireClient(player, payload) end
    end
    if event then
        event:SetAttribute("CurrentRound", RoundManager.CurrentRound)
        event:SetAttribute("State", RoundManager.State)
    end
end

local function tickCountdown(token: number)
    if not started or epoch ~= token or RoundManager.State ~= "Finishing" then return end
    if os.clock() >= deadline then
        RoundManager.nextRound()
        return
    end
    notify("countdown")
    task.delay(math.max(0, math.min(1, deadline - os.clock())), tickCountdown, token)
end

local function finish(player: Player, token: number)
    if not started or token ~= epoch or player.Parent ~= Players
        or (RoundManager.State ~= "Playing" and RoundManager.State ~= "Finishing") then return end
    -- Close the deadline even if the scheduled task is delayed by server load.
    if RoundManager.State == "Finishing" and os.clock() >= deadline then return end
    if completed[player.UserId] then return end
    -- No yielding between marking completion and changing both server stats.
    PlayerStats.ensure(player)
    completed[player.UserId] = true
    PlayerStats.reward(player)
    debugLog(string.format("Player %s finished round %d", player.Name, RoundManager.CurrentRound))
    if Config.DebugMode then
        print(string.format("[Rewards] +%d Win, +%d Coins", Config.WinReward, Config.CoinReward))
    end
    local first = RoundManager.State == "Playing"
    if first then
        RoundManager.State = "Finishing"
        deadline = os.clock() + Config.NextRoundDelay
        debugLog(string.format("Next round in %d", Config.NextRoundDelay))
    end
    notify("roundFinished")
    if first then task.delay(math.min(1, Config.NextRoundDelay), tickCountdown, token) end
end

function RoundManager.nextRound(): SpawnLocation?
    if not started or RoundManager.State == "Generating" then return nil end
    epoch += 1 -- Invalidates old finish callbacks and pending countdown tasks.
    local token = epoch
    RoundManager.State = "Generating"
    notify("generating")
    local nextNumber = RoundManager.CurrentRound + 1
    debugLog(string.format("Generating round %d", nextNumber))
    local ok, result = pcall(function()
        -- Keep advancing the same random stream, even when the base seed is fixed.
        return MapGenerator.build(random, function(player) finish(player, token) end)
    end)
    if not ok then
        RoundManager.State = "Error"
        notify("error")
        warn("[Round] Map generation failed: " .. tostring(result))
        return nil
    end
    table.clear(completed)
    RoundManager.CurrentRound = nextNumber
    RoundManager.State = "Playing"
    notify("newRound")
    debugLog(string.format("Round %d ready", nextNumber))
    return result
end

function RoundManager.start()
    if started then return end
    assert(Config.NextRoundDelay >= 1 and Config.NextRoundDelay % 1 == 0, "NextRoundDelay must be a positive integer")
    assert(Config.WinReward >= 0 and Config.WinReward % 1 == 0, "WinReward must be a non-negative integer")
    assert(Config.CoinReward >= 0 and Config.CoinReward % 1 == 0, "CoinReward must be a non-negative integer")
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then assert(remotes:IsA("Folder"), "Remotes must be a Folder")
    else remotes = Instance.new("Folder"); remotes.Name = "Remotes"; remotes.Parent = ReplicatedStorage end
    local existing = remotes:FindFirstChild("RoundStateEvent")
    if existing then
        assert(existing:IsA("RemoteEvent"), "RoundStateEvent must be a RemoteEvent")
        event = existing
    else
        local remote = Instance.new("RemoteEvent")
        remote.Name = "RoundStateEvent"
        remote.Parent = remotes
        event = remote
    end
    -- No OnServerEvent handler: clients cannot submit finishes or rewards.
    random = if ObbyConfig.Seed == nil then Random.new() else Random.new(ObbyConfig.Seed)
    started = true
    PlayerStats.start()
    joined = Players.PlayerAdded:Connect(function(player) notify("snapshot", player) end)
    MapGenerator.setRegenerationHandler(RoundManager.nextRound)
    debugLog(string.format("Starting round %d", RoundManager.CurrentRound + 1))
    RoundManager.nextRound()
end

function RoundManager.stop()
    started = false
    epoch += 1
    RoundManager.State = "Stopped"
    if joined then joined:Disconnect(); joined = nil end
    PlayerStats.stop()
    MapGenerator.setRegenerationHandler(nil)
    MapGenerator.cleanup()
end

return RoundManager
