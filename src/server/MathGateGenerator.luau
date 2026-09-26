--!strict

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.MathConfig)
local ProjectConfig = require(Shared.Config)
local Problems = require(script.Parent.MathProblemGenerator)
local Triggers = require(script.Parent.MathGateTriggers)
local Parts = require(script.Parent.ObbyParts)

local MathGateGenerator = {}

local function label(part: BasePart, text: string)
    local gui = Instance.new("SurfaceGui")
    gui.Name = "Display"
    -- The player approaches in -Z, looking at the board's +Z face.
    gui.Face = Enum.NormalId.Back
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = Config.PixelsPerStud
    gui.LightInfluence = 0
    gui.Parent = part
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Text"
    textLabel.Size = UDim2.fromScale(1, 1)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Config.TextColor
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextScaled = true
    textLabel.Text = text
    textLabel.Parent = gui
end

function MathGateGenerator.generate(map: Instance, previous: BasePart, random: Random)
    local section = Instance.new("Folder")
    section.Name = "MathSection"
    section:SetAttribute("ObbyGenerated", true)
    section.Parent = map
    local floors: {BasePart} = {}
    local doors: {Triggers.Door} = {}
    local width = 3 * Config.DoorWidth + 4 * Config.PillarWidth
    local floorSize = Vector3.new(width, Config.PlatformThickness, Config.PlatformDepth)

    for index, problem in Problems.generateSet(random) do
        local gate = Instance.new("Model")
        gate.Name = string.format("MathGate_%02d", index)
        gate.Parent = section
        local entryPosition = previous.Position - Vector3.new(0, 0, previous.Size.Z / 2 + Config.SectionGap + floorSize.Z / 2)
        local entry = Parts.platform(gate, "EntryPlatform", floorSize, entryPosition, Config.FloorColor)
        local exit = Parts.platform(gate, "ExitPlatform", floorSize, entryPosition - Vector3.new(0, 0, floorSize.Z), Config.FloorColor)
        table.insert(floors, entry)
        table.insert(floors, exit)
        local gateZ = entryPosition.Z - floorSize.Z / 2
        local floorTop = entryPosition.Y + floorSize.Y / 2
        local gateCenter = Vector3.new(entryPosition.X, floorTop + Config.DoorHeight / 2, gateZ)

        -- Tall side walls and a lintel prevent normal jumps around/over the choices.
        for pillar = 0, 3 do
            local x = entryPosition.X - width / 2 + Config.PillarWidth / 2 + pillar * (Config.DoorWidth + Config.PillarWidth)
            local depth = if pillar == 0 or pillar == 3 then floorSize.Z * 2 else Config.DoorThickness
            Parts.platform(gate, "Frame_" .. pillar, Vector3.new(Config.PillarWidth, Config.DoorHeight, depth), Vector3.new(x, gateCenter.Y, gateZ), Config.FrameColor)
        end
        Parts.platform(gate, "Lintel", Vector3.new(width, Config.HeaderHeight, Config.DoorThickness),
            Vector3.new(entryPosition.X, floorTop + Config.DoorHeight + Config.HeaderHeight / 2, gateZ), Config.FrameColor)
        local question = Parts.platform(gate, "QuestionDisplay", Vector3.new(width, Config.QuestionHeight, Config.DoorThickness),
            Vector3.new(entryPosition.X, floorTop + Config.DoorHeight + Config.HeaderHeight + Config.QuestionGap + Config.QuestionHeight / 2, gateZ), Config.FrameColor)
        label(question, problem.expression)

        for answerIndex, answer in problem.answers do
            local x = entryPosition.X - width / 2 + Config.PillarWidth + Config.DoorWidth / 2 + (answerIndex - 1) * (Config.DoorWidth + Config.PillarWidth)
            local door = Parts.platform(gate, "AnswerDoor_" .. answerIndex, Vector3.new(Config.DoorWidth, Config.DoorHeight, Config.DoorThickness),
                Vector3.new(x, gateCenter.Y, gateZ), Config.DoorColor)
            door.CanCollide = false
            door.Transparency = Config.DoorTransparency
            local sign = Parts.platform(gate, "AnswerDisplay_" .. answerIndex, Vector3.new(Config.DoorWidth, Config.HeaderHeight, 0.2),
                Vector3.new(x, floorTop + Config.DoorHeight + Config.HeaderHeight / 2, gateZ + Config.DoorThickness / 2 + 0.1), Config.FrameColor)
            sign.CanCollide = false
            label(sign, tostring(answer))
            table.insert(doors, { part = door, answer = answer, correctAnswer = problem.correctAnswer })
        end
        if ProjectConfig.DebugMode then
            print(string.format("[MathGate] Generated: %s = %d", problem.expression, problem.correctAnswer))
        end
        previous = exit
    end
    return { exitPlatform = previous, floors = floors, cleanup = Triggers.start(doors) }
end

return MathGateGenerator
