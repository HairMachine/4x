local power = 0

local plot = {
    name = "None",
    x = 0,
    y = 0,
    target = 0
}

local function resetPlot()
    plot.name = "None"
    plot.x = 0
    plot.y = 0
    plot.target = 0
    power = 0
end

local function getPower()
    return power
end

local function increasePower()
    power = power + 1
end

return {
    plot = plot,
    resetPlot = resetPlot,
    getPower = getPower,
    increasePower = increasePower
}