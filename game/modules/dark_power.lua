local locations = require 'modules/locations'
local units = require 'modules/units'
local worldmap = require 'modules/worldmap'

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
end

local function choosePlot()
    resetPlot()
    power = 0
    local r = love.math.random(1, 100)
    if r < 50 then
        plot.name = "Cave"
        plot.target = 40
    elseif r < 80 then
        plot.name = "Dark Temple"
        plot.target = 50
    else
        plot.name = "Fortress"
        plot.target = 40
    end
    local caveLocs = {}
    for y = 1, worldmap.MAPSIZEY do
        for x = 1, worldmap.MAPSIZEX do
            if worldmap.map[y][x].align ~= CONSTS.lightTile and locations.atPos(x, y).name == "None" then
                table.insert(caveLocs, {x = x, y = y})
            end
        end
    end
    if #caveLocs > 0 then
        -- Chose a random one
        local loc = caveLocs[love.math.random(1, #caveLocs)]
        plot.x = loc.x
        plot.y = loc.y
    end
end

local function getCurrentPlot()
    return plot
end

local function getPower()
    return power
end

local function increasePower()
    power = power + 1
end

return {
    plot = plot,
    choosePlot = choosePlot,
    getCurrentPlot = getCurrentPlot,
    getPower = getPower,
    increasePower = increasePower
}