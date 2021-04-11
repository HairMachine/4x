local map = {}
local cols = 8
local rows = 3
local MAPSIZEX = 8 * 5
local MAPSIZEY = 6 * 5

local tileData = {
    water = {tile = "water", abundance = 4, production = 0},
    grass = {tile = "grass", abundance = 3, production = 1},
    mountain = {tile = "mountain", abundance = 0, production = 4},
    ruins = {tile = "ruins", abundance = 0, production = 0},
    tundra = {tile = "tundra", abundance = 0, production = 1},
    forest = {tile = "forest", abundance = 0, production = 2},
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
    newTile.workers = 0
    return newTile
end

local function clear()
    for y = 1, MAPSIZEY do
        map[y] = {}
        for x = 1, MAPSIZEX do
            map[y][x] = makeTile("water", 99)
        end
    end
end

local function _field()
    local area = {}
    for y = 1, 5 do
        area[y] = {}
        for x = 1, 5  do
            area[y][x] = "tundra"
        end
    end
    for c = 1, 2 do
        area[love.math.random(1, 5)][love.math.random(1, 5)] = "mountain"
        area[love.math.random(1, 5)][love.math.random(1, 5)] = "ruins"
        area[love.math.random(1, 5)][love.math.random(1, 5)] = "grass"
        area[love.math.random(1, 5)][love.math.random(1, 5)] = "forest"
    end
    return area
end

local function _lake()
    local area = {}
    for y = 1, 5 do
        area[y] = {}
        for x = 1, 5  do
            area[y][x] = "water"
        end
    end
    return area
end

local function generateResources()
    local til = "ore"
    local space = 4
    for y = 0, math.floor(MAPSIZEY / space) - 1  do
        for x = 0,  math.floor(MAPSIZEX / space) - 1 do
            local xoffs = love.math.random(0, space-1)
            local yoffs = love.math.random(0, space-1)
            -- Annoying hack to stop gold appearing on the tower tile - will have to be improved
            if (xoffs == 0 and yoffs == 0 and x == 0 and y == 0) then
                xoffs = xoffs + 1
            end
            local yp = y * space + yoffs + space-1
            local xp = x * space + xoffs + space-1
            if xp <= MAPSIZEX and yp <= MAPSIZEY then
                map[yp][xp] = makeTile(til, 99)
            end
            if til == "ore" then til = "crystal" else til = "ore" end
        end
    end
end

local function makeRandomArea()
    local roll = love.math.random(1, 5)
    if roll == 1 then
        return _lake()
    else
        return _field()
    end
end

local function generate()
    local yp = 1
    local xp = 1

    clear()

    for c = 1, cols do
        for r = 1, rows do
            local area = makeRandomArea()
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

    generateResources()
end

local function load(level)
    local areas = {}
    local content = love.filesystem.read("/assets/"..level..".txt")
    local xsize = 0
    local ysize = 1
    local curx = 0
    local area
    
    clear()

    for i = 1, #content do
        local char = content:sub(i, i)
        -- Split on line break
        if char == "\n" then
            ysize = ysize + 1
            curx = 0
        else
            if char == "f" then
                area = _field()
            elseif char == "l" then
                area = _lake()
            end
            local startx = (curx - 1) * 5
            local starty = (ysize - 1) * 5
            for ky, vy in pairs(area) do
                for kx, vx in pairs(vy) do
                    map[starty + ky][startx + kx] = makeTile(vx, 99)
                end
            end
            curx = curx + 1
            if curx > xsize then xsize = curx end
        end
    end
    -- TODO: MAPSIZEX and MAPSIZEY refactor into functions so we can base the map size on the loaded level
    generateResources()
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
    load = load,
    generate = generate,
    makeTile = makeTile,
    getTotalPopulation = getTotalPopulation,
    explore = explore
}