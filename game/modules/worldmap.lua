local locations = require 'modules/locations'

local map = {}
local cols = 8
local rows = 3
local MAPSIZEX = 8 * 5
local MAPSIZEY = 3 * 5

local function tileAlignmentChange()
    for y = 1, MAPSIZEY do
        for x = 1, MAPSIZEX do
            map[y][x].align = 2
        end
    end
    for k, l in pairs(locations.get()) do
        if l.team == 1 and l.align == true then
            for xi = l.x - 2, l.x + 2 do
                for yi = l.y - 2, l.y + 2 do
                    if xi > 0 and xi <= MAPSIZEX and yi > 0 and yi <= MAPSIZEY then
                        map[yi][xi].align = 1
                    end
                end
            end
        end
    end
    -- Check for enclosed areas
    -- First, find all the "free" dark tiles - these are tiles that have any two opposite othogonal directions free of any lighted tiles
    local freemap = {}
    for y = 1, MAPSIZEY do
        freemap[y] = {}
        for x = 1, MAPSIZEX do
            -- Lighted tiles are ALWAYS unfree
            if map[y][x].align == 1 then
                freemap[y][x] = false
            else
                local surroundX = 0
                local surroundY = 0
                for n = 1, y do
                    if map[n][x].align == 1 then 
                        surroundY = surroundY + 1 
                        break
                    end
                end
                for e = x, MAPSIZEX do
                    if map[y][e].align == 1 then 
                        surroundX = surroundX + 1
                        break
                    end
                end
                for s = y, MAPSIZEY do
                    if map[s][x].align == 1 then 
                        surroundY = surroundY + 1 
                        break
                    end
                end
                for w = 1, x do
                    if map[y][w].align == 1 then 
                        surroundX = surroundX + 1 
                        break
                    end
                end
                if surroundX > 0 and surroundY > 0 then
                    freemap[y][x] = false
                else
                    freemap[y][x] = true
                end
            end
        end
    end
    -- Then, find all the unfree tiles that are connected to a free tile, and mark them as free
    local changed = true
    while (changed) do
        changed = false
        for y = 1, MAPSIZEY do
            for x = 1, MAPSIZEX do
                if freemap[y][x] == false and map[y][x].align == 2 then
                    if y - 1 >= 1 and freemap[y - 1][x] == true then 
                        freemap[y][x] = true
                        changed = true
                    end
                    if x + 1 <= MAPSIZEX and freemap[y][x + 1] == true then 
                        freemap[y][x] = true 
                        changed = true
                    end
                    if y + 1 <= MAPSIZEY and freemap[y + 1][x] == true then 
                        freemap[y][x] = true
                        changed = true
                    end
                    if x - 1 >= 1 and freemap[y][x - 1] == true then 
                        freemap[y][x] = true
                        changed = true
                    end
                end
            end
        end
    end
    -- All the remaining unfree tiles should now be lighted
    for y = 1, MAPSIZEY do
        for x = 1, MAPSIZEX do
            if freemap[y][x] == false then map[y][x].align = 1 end
        end
    end
end

local function drawTile()
    local tile = {}
    for y = 1, 5 do
        tile[y] = {}
        for x = 1, 5  do
            if x == 1 or x == 5 then
                tile[y][x] = "water"
            else
                tile[y][x] = "grass"
            end
        end
    end
    for c = 1, 5 do
        tile[love.math.random(2, 4)][love.math.random(2, 4)] = "mountain"
        tile[love.math.random(2, 4)][love.math.random(2, 4)] = "ruins"
        tile[love.math.random(2, 4)][love.math.random(2, 4)] = "tundra"
        tile[love.math.random(2, 4)][love.math.random(2, 4)] = "forest"
    end
    return tile
end

local function generate()
    local yp = 1
    local xp = 1

    for y = 1, MAPSIZEY do
        map[y] = {}
        for x = 1, MAPSIZEX do
            map[y][x] = {tile = "water", align = 2}
        end
    end

    for c = 1, cols do
        for r = 1, rows do
            local tile = drawTile()
            local startx = (c - 1) * 5
            local starty = (r - 1) * 5
            for ky, vy in pairs(tile) do
                for kx, vx in pairs(vy) do
                    map[starty + ky][startx + kx] = {tile = vx, align = 2}
                end
            end
        end
    end

    for c = 0, cols - 2 do
        local connected = love.math.random(0, rows - 1)
        -- Connect the tiles
        for y = connected * 5 + 1, connected * 5 + 3 do
            for x = c * 5 + 4, c * 5 + 7 do
                map[y][x].tile = "grass"
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
                map[yp][xp].tile = til
            end
            if til == "ore" then til = "crystal" else til = "ore" end
        end
    end
end

return {
    map = map,
    MAPSIZEX = MAPSIZEX,
    MAPSIZEY = MAPSIZEY,
    tileAlignmentChange = tileAlignmentChange,
    generate = generate
}