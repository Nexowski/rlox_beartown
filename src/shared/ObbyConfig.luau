--!strict

return {
    StartPosition = Vector3.new(0, 0, 0),
    MapHeight = 40,
    -- A number reproduces the sequence of rounds; the random stream advances each round.
    Seed = nil :: number?,
    StartSize = Vector3.new(20, 2, 20),
    FinishSize = Vector3.new(20, 2, 20),
    StartColor = Color3.fromRGB(70, 190, 100),
    FinishColor = Color3.fromRGB(255, 210, 40),
    CheckpointColor = Color3.fromRGB(60, 240, 220),
    SpawnSize = Vector3.new(5, 0.5, 5),
    SpawnClearance = 4,
    TouchTolerance = 4,
    MaxHeightDifference = 2,
    Material = Enum.Material.SmoothPlastic,
    KillPlane = {
        Depth = 18, Margin = 40, Thickness = 2, Transparency = 0.5,
        Color = Color3.fromRGB(240, 60, 60),
    },
    -- Obby geometry is fixed; Seed is used by the math section.
    Sections = {
        { Name = "Jump", Count = 10, Size = Vector3.new(12, 2, 12), Gap = 4,
            Color = Color3.fromRGB(80, 140, 220), LateralOffset = 0, HeightStep = 0,
            Checkpoints = { 10 } },
        { Name = "Precision", Count = 5, Size = Vector3.new(6, 2, 6), Gap = 4,
            Color = Color3.fromRGB(180, 100, 220), LateralOffset = 0, HeightStep = 0,
            Checkpoints = { 5 } },
        { Name = "ZigZag", Count = 4, Size = Vector3.new(8, 2, 8), Gap = 3,
            Color = Color3.fromRGB(255, 150, 60), LateralOffset = 4, HeightStep = 0,
            Checkpoints = { 4 } },
        -- First platform is a checkpoint landing before the final ascending jumps.
        { Name = "HeightJump", Count = 5, Size = Vector3.new(8, 2, 8), Gap = 3,
            Color = Color3.fromRGB(240, 110, 150), LateralOffset = 0, HeightStep = 2,
            Checkpoints = { 1 } },
    },
    FinishGap = 3,
}
