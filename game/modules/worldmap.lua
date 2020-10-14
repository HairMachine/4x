local map = {}
local cols = 8
local rows = 3
local MAPSIZEX = 8 * 5
local MAPSIZEY = 3 * 5

local tileData = {
    water = {tile = "water", abundance = 4, production = 0},
    grass = {tile = "grass", abundance = 3, production = 1},
    mountain = {tile = "mountain", abundance = 0, production = 4},
    ruins = {tile = "ruins", abundance = 0, production = 0},
    tundra = {tile = "tundra", abundance = 1, production = 1},
    forest = {tile = "forest", abundance = 2, production = 2},
    ore = {tile = "ore", abundance = 0, production = 0},
    crystal = {tile = "crystal", abundance = 0, production = 0}
}

local function makeTile(type, align)
    local newTile = {}
    for k, v in pairs(tileData[type]) do
        newTile[k] = v
    end
    newTile.align = align
    newTile.food = 0
    newTile.desirability = 0
    newTile.revenue = 0
    newTile.unrest = 0
    newTile.population = 0
    return newTile
end

local function makeArea()
    local area = {}
    for y = 1, 5 do
        area[y] = {}
        for x = 1, 5  do
            if x == 1 or x == 5 then
                area[y][x] = "water"
            else
                area[y][x] = "grass"
            end
        end
    end
    for c = 1, 5 do
        area[love.math.random(2, 4)][love.math.random(2, 4)] = "mountain"
        area[love.math.random(2, 4)][love.math.random(2, 4)] = "ruins"
        area[love.math.random(2, 4)][love.math.random(2, 4)] = "tundra"
        area[love.math.random(2, 4)][love.math.random(2, 4)] = "forest"
    end
    return area
end

local function generate()
    local yp = 1
    local xp = 1

    for y = 1, MAPSIZEY do
        map[y] = {}
        for x = 1, MAPSIZEX do
            map[y][x] = makeTile("water", 99)
        end
    end

    for c = 1, cols do
        for r = 1, rows do
            local area = makeArea()
            local startx = (c - 1) * 5
            local starty = (r - 1) * 5
            for ky, vy in pairs(area) do
                for kx, vx in pairs(vy) do
                    map[starty + ky][startx + kx] = makeTile(vx, 99)
                end
            end
        end
    end

    for c = 0, cols - 2 do
        local connected = love.math.random(0, rows - 1)
        -- Connect the tiles
        for y = connected * 5 + 1, connected * 5 + 3 do
            for x = c * 5 + 4, c * 5 + 7 do
                map[y][x] = makeTile("grass", 99)
            end
        end
    end

    local til = "ore"
    for y = 0, math.floor(MAPSIZEY / 3) - 1  do
        for x = 0,  math.floor(MAPSIZEX / 3) - 1 do
            local xoffs = love.math.random(0, 2)
            local yoffs = love.math.random(0, 2)
            -- Annoying hack to stop gold appearing on the tower tile - will have to be improved
            if (xoffs == 0 and yoffs == 0 and x == 0 and y == 0) then
                xoffs = xoffs + 1
            end
            local yp = y * 3 + yoffs + 2
            local xp = x * 3 + xoffs + 2
            if xp <= MAPSIZEX and yp <= MAPSIZEY then
                map[yp][xp] = makeTile(til, 99)
            end
            if til == "ore" then til = "crystal" else til = "ore" end
        end
    end
end

local function getTotalPopulation()
    local pop = 0
    for yt = 1, MAPSIZEY do
        for xt = 1, MAPSIZEX do
            pop = pop + map[yt][xt].population
        end
    end
    return pop
end

local function getTilePopulation(x, y)
    if map[y] and map[y][x] and map[y][x].population then
        return map[y][x].population
    end
    return -1
end

local function explore(x, y, range)
    for yt = y - range, y + range do
        for xt = x - range, x + range do
            if yt > 0 and yt <= MAPSIZEY and xt > 0 and xt <= MAPSIZEX then
                if map[yt][xt].align == CONSTS.unexploredTile then
                    map[yt][xt].align = CONSTS.darkTile
                end
            end
        end
    end
end

return {
    map = map,
    MAPSIZEX = MAPSIZEX,
    MAPSIZEY = MAPSIZEY,
    generate = generate,
    makeTile = makeTile,
    getTotalPopulation = getTotalPopulation,
    getTilePopulation = getTilePopulation,
    explore = explore
}