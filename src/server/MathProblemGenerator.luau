--!strict

local Config = require(game:GetService("ReplicatedStorage").Shared.MathConfig)

export type Problem = {
    expression: string,
    correctAnswer: number,
    answers: {number},
    operation: string,
    left: number,
    right: number,
}

local MathProblemGenerator = {}

local function shuffle<T>(values: {T}, random: Random)
    for index = #values, 2, -1 do
        local other = random:NextInteger(1, index)
        values[index], values[other] = values[other], values[index]
    end
end

function MathProblemGenerator.generate(random: Random, operation: string): Problem
    local maximum = Config.MaxResult
    assert(maximum >= 4 and maximum <= 20, "Math results must stay within 0–20")
    local left, right, answer, symbol
    if operation == "add" then
        left = random:NextInteger(0, maximum)
        right = random:NextInteger(0, maximum - left)
        answer, symbol = left + right, "+"
    elseif operation == "subtract" then
        left = random:NextInteger(0, maximum)
        right = random:NextInteger(0, left)
        answer, symbol = left - right, "-"
    elseif operation == "multiply" then
        left = random:NextInteger(2, math.min(Config.MaxFactor, math.floor(maximum / 2)))
        right = random:NextInteger(2, math.min(Config.MaxFactor, math.floor(maximum / left)))
        answer, symbol = left * right, "×"
    else
        error("Unsupported math operation: " .. operation)
    end

    local alternatives: {number} = {}
    for value = math.max(0, answer - Config.DistractorDistance), math.min(maximum, answer + Config.DistractorDistance) do
        if value ~= answer then table.insert(alternatives, value) end
    end
    assert(#alternatives >= 2, "Need two distinct nearby wrong answers")
    shuffle(alternatives, random)
    local answers = { answer, alternatives[1], alternatives[2] }
    shuffle(answers, random)
    return {
        expression = string.format("%d %s %d", left, symbol, right),
        correctAnswer = answer,
        answers = answers,
        operation = operation,
        left = left,
        right = right,
    }
end

function MathProblemGenerator.generateSet(random: Random): {Problem}
    local operations = table.clone(Config.Operations)
    assert(#operations == 3, "The first math section requires three operations")
    shuffle(operations, random)
    local problems: {Problem} = {}
    for _, operation in operations do
        table.insert(problems, MathProblemGenerator.generate(random, operation))
    end
    return problems
end

return MathProblemGenerator
