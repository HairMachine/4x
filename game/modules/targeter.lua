local units = require 'modules/units'
local locations = require 'modules/locations'

local map = {}
local unit = 0
local type = ""
local callback = function() end

local function getMap()
    return map
end

local function setMap(x, y, radius, excludeSelf)
    map = {}
    for xt = x - radius, x + radius do
        for yt = y - radius, y + radius do
            if not(excludeSelf == true and yt == y and xt == x) then
                table.insert(map, {x = xt, y = yt})
            end
        end
    end 
end

local function setSpellMap(radius, wizards)
    map = {}
    -- around wizard's tower
    for x = locations.get()[1].x - radius, locations.get()[1].x + radius do
        for y = locations.get()[1].y - radius, locations.get()[1].y + radius do
            table.insert(map, {x = x, y = y})
        end
    end
    -- around wizards!
    if wizards == true then
        for k, e in pairs(units.get()) do
            if e.type == "wizard" or e.type == "hero" then
                for x = e.x - radius, e.x + radius do
                    for y = e.y - radius, e.y + radius do
                        table.insert(map, {x = x, y = y})
                    end
                end
            end
        end
    end
    type = "spell"
end

local function setBuildMap(x, y, radius)
    map = {}
    for xt = x - radius, x + radius do
        for yt = y - radius, y + radius do
            if locations.atPos(xt, yt).name == "None" and not(yt == y and xt == x) then
                table.insert(map, {x = xt, y = yt})
            end
        end
    end 
end

local function clear()
    map = {}
    unit = 0
end

local function getType()
    return type
end

local function setType(t)
    type = t
end

local function getUnit()
    return unit
end

local function setUnit(u)
    unit = u
end

return {
    getMap = getMap,
    setMap = setMap,
    setSpellMap = setSpellMap,
    setBuildMap = setBuildMap,
    clear = clear,
    callback = callback,
    getType = getType,
    setType = setType,
    getUnit = getUnit,
    setUnit = setUnit
}