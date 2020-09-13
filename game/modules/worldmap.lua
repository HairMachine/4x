local locations = require 'modules/locations'

local map = {}
local MAPSIZEX = 17
local MAPSIZEY = 17

local function tileAlignmentChange()
    for y = 1, MAPSIZEY do
        for x = 1, MAPSIZEX do
            map[y][x].align = 2
        end
    end
    for k, l in pairs(locations.get()) do
        if l.team == 1 then
            for xi = l.x - 1, l.x + 1 do
                for yi = l.y - 1, l.y + 1 do
                    if xi > 0 and xi <= MAPSIZEX and yi > 0 and yi <= MAPSIZEY then
                        map[yi][xi].align = 1
                    end
                end
            end
        end
    end
    -- Check for enclosed areas
    -- First, find all the "free" dark tiles - these are the ones that don't have lighted tiles on 3 of their orthogonal directions
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

return {
    map = map,
    MAPSIZEX = MAPSIZEX,
    MAPSIZEY = MAPSIZEY,
    tileAlignmentChange = tileAlignmentChange
}