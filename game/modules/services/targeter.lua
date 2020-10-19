local units = require 'modules/components/units'
local locations = require 'modules/components/locations'
local worldmap = require 'modules/components/worldmap'

local map = {}
local unit = 0
local callback = function() end

local function getMap()
    return map
end

local function setMap(t)
    map = {}
    for k, e in pairs(t) do
        table.insert(map, {x = e.x, y = e.y})
    end
end

local function clear()
    map = {}
    unit = -1
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
    clear = clear,
    callback = callback,
    getUnit = getUnit,
    setUnit = setUnit
}