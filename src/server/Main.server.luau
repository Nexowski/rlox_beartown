--!strict

local RoundManager = require(script.Parent.RoundManager)
RoundManager.start()
script.Destroying:Connect(RoundManager.stop)

print("[Server] Project connected successfully")
