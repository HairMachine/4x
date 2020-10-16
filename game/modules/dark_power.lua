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

local function advancePlot()
    for k, l in pairs(locations.get()) do
        if l.key == "dark_tower" then
            power = power + 5
        elseif l.key == "dark_temple" then
            power = power + 1
        end
    end
    if power >= plot.target then
        if plot.name == "Cave" then
            locations.add("cave", plot.x, plot.y, 2)
            units.add("grunter", plot.x, plot.y, {type = "cave", x = plot.x, y = plot.y})
        elseif plot.name == "Dark Temple" then
            locations.add("dark_temple", plot.x, plot.y, 2)
        elseif plot.name == "Fortress" then
            locations.add("fortress", plot.x, plot.y, 2)
            units.add("doom_guard", plot.x, plot.y, {type = "fortress", x = plot.x, y = plot.y})
        end
        power = 0
        choosePlot()
    end
end

local function getPower()
    return power
end

return {
    plot = plot,
    advancePlot = advancePlot,
    choosePlot = choosePlot,
    getPower = getPower,
}