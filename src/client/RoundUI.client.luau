--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundStateEvent") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "RoundUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.Parent = playerGui
local panel = Instance.new("Frame")
panel.Name = "Announcement"
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.fromScale(0.5, 0.08)
panel.Size = UDim2.new(0.85, 0, 0, 180)
panel.BackgroundColor3 = Color3.fromRGB(25, 35, 50)
panel.BackgroundTransparency = 0.1
panel.Visible = false
panel.Parent = gui
local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MaxSize = Vector2.new(460, 180)
sizeLimit.Parent = panel
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = panel
local label = Instance.new("TextLabel")
label.Name = "Message"
label.Position = UDim2.fromOffset(12, 12)
label.Size = UDim2.new(1, -24, 1, -24)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.new(1, 1, 1)
label.Font = Enum.Font.GothamBold
label.TextSize = 24
label.TextWrapped = true
label.Parent = panel

local lastRevision = -1
local function render(payload: any)
    if typeof(payload) ~= "table" or typeof(payload.revision) ~= "number" or payload.revision <= lastRevision then return end
    lastRevision = payload.revision
    panel.Visible = payload.state == "Finishing" or payload.state == "Generating" or payload.state == "Error"
    if payload.state == "Finishing" then
        local heading = if payload.completed
            then string.format("Ukończono rundę %d!\n+%d Win   +%d Coins", payload.round, payload.wins, payload.coins)
            else string.format("Runda %d ukończona!", payload.round)
        label.Text = heading .. string.format("\nNowa plansza za %d...", payload.seconds)
    elseif payload.state == "Generating" then
        label.Text = "Przygotowywanie nowej planszy..."
    elseif payload.state == "Error" then
        label.Text = "Nie udało się przygotować planszy."
    end
end

local function readSnapshot()
    local snapshot = player:GetAttribute("RoundSnapshot")
    if typeof(snapshot) ~= "string" then return end
    local ok, payload = pcall(function() return HttpService:JSONDecode(snapshot) end)
    if ok then render(payload) end
end
local eventConnection = remote.OnClientEvent:Connect(render)
local snapshotConnection = player:GetAttributeChangedSignal("RoundSnapshot"):Connect(readSnapshot)
readSnapshot()
script.Destroying:Connect(function()
    eventConnection:Disconnect()
    snapshotConnection:Disconnect()
    gui:Destroy()
end)
