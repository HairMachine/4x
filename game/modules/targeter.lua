local units = require 'modules/units'
local locations = require 'modules/locations'
local worldmap = require 'modules/worldmap'

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

local function setFoundingMap(x, y, radius)
    map = {}
    for xt = x - radius, x + radius do
        for yt = y - radius, y + radius do
            if locations.atPos(xt, yt).name == "None" and not(yt == y and xt == x) then
                if yt > 0 and yt <= worldmap.MAPSIZEY and xt > 0 and xt <= worldmap.MAPSIZEX then
                    if worldmap.map[yt][xt].align == 2 then
                        table.insert(map, {x = xt, y = yt})
                    end
                end
            end
        end
    end 
end

local function setMoveMap(x, y, radius)
    map = {}
    for xt = x - radius, x + radius do
        for yt = y - radius, y + radius do
            if not(yt == y and xt == x) and yt > 0 and yt <= worldmap.MAPSIZEY and xt > 0 and xt <= worldmap.MAPSIZEX then
                if units.tileIsAllowed(units.get()[unit], worldmap.map[yt][xt].tile) and units.atPos(xt, yt).name == "None" then
                    local loc = locations.atPos(xt, yt)
                    if loc.name == "None" or loc.team == units.get()[unit].team then
                        table.insert(map, {x = xt, y = yt})
                    end
                end
            end
        end
    end
end

local function setExploreMap(x, y, radius)
    map = {}
    for xt = x - radius, x + radius do
        for yt = y - radius, y + radius do
            if not(yt == y and xt == x) and yt > 0 and yt <= worldmap.MAPSIZEY and xt > 0 and xt <= worldmap.MAPSIZEX then
                if worldmap.map[yt][xt].tile == "ruins" then
                    table.insert(map, {x = xt, y = yt})
                end
            end
        end
    end
end

local function setBuildMap(buildData)
    for k, l in pairs(locations.get()) do
        if l.team == 1 then
            local bdata = locations.getData()[buildData.key]
            for xt = l.x - 1, l.x + 1 do
                for yt = l.y - 1, l.y + 1 do
                    if yt > 0 and yt <= worldmap.MAPSIZEY and xt > 0 and xt <= worldmap.MAPSIZEX then
                        if worldmap.map[yt][xt].align == 1 and locations.allowedTile(bdata.allowedTiles, worldmap.map[yt][xt].tile) then
                            table.insert(map, {x = xt, y = yt})
                        end
                    end
                end
            end
        end
    end
end

local function setBuildUnitMap(buildData)
    for k, l in pairs(locations.get()) do
        if l.maxUnits and #l.units < l.maxUnits then
            table.insert(map, {x = l.x, y = l.y})
        end
    end
end

local function setDeployMap()
    for k, l in pairs(locations.get()) do
        if l.maxUnits and l.maxUnits > 0 then
            for yt = l.y - 3, l.y + 3 do
                for xt = l.x - 3, l.x + 3 do
                    if yt > 0 and xt > 0 and yt <= worldmap.MAPSIZEY and yt <= worldmap.MAPSIZEX then
                        table.insert(map, {x = xt, y = yt})
                    end
                end
            end
        end
    end
end

local function clear()
    map = {}
    unit = -1
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
    setFoundingMap = setFoundingMap,
    setMoveMap = setMoveMap,
    setExploreMap = setExploreMap,
    setBuildMap = setBuildMap,
    setBuildUnitMap = setBuildUnitMap,
    setDeployMap = setDeployMap,
    clear = clear,
    callback = callback,
    getType = getType,
    setType = setType,
    getUnit = getUnit,
    setUnit = setUnit
}