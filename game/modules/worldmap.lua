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
end

return {
    map = map,
    MAPSIZEX = MAPSIZEX,
    MAPSIZEY = MAPSIZEY,
    tileAlignmentChange = tileAlignmentChange
}