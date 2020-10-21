local units = require 'modules/components/units'
local worldmap = require 'modules/components/worldmap'
local locations = require 'modules/components/locations'

local function enemyUnitTargets()
    local map = {}
    for k, u in pairs(units.get()) do
        if u.team == CONSTS.enemyTeam and worldmap.map[u.y][u.x].align ~= CONSTS.unexploredTile then
            table.insert(map, {x = u.x, y = u.y})
        end
    end
    return map
end

local function friendlyUnitTargets()
    local map = {}
    for k, u in pairs(units.get()) do
        if u.team == CONSTS.playerTeam and worldmap.map[u.y][u.x].align ~= CONSTS.unexploredTile then
            table.insert(map, {x = u.x, y = u.y})
        end
    end
    return map
end

local function visibleTileTargets()
    local map = {}
    for y = 1, worldmap.MAPSIZEY do
        for x = 1, worldmap.MAPSIZEX do
            if worldmap.map[y][x].align ~= CONSTS.unexploredTile then
                table.insert(map, {x = x, y = y})
            end
        end
    end
    return map
end

local function foundingTargets(x, y)
    local map = {}
    for xt = x - 1, x + 1 do
        for yt = y - 1, y + 1 do
            if locations.atPos(xt, yt).name == "None" and not(yt == y and xt == x) then
                if yt > 0 and yt <= worldmap.MAPSIZEY and xt > 0 and xt <= worldmap.MAPSIZEX then
                    if worldmap.map[yt][xt].align == CONSTS.darkTile then
                        table.insert(map, {x = xt, y = yt})
                    end
                end
            end
        end
    end
    return map
end

local function heroMoveTargets(x, y, unit)
    local map = {}
    for xt = x - 1, x + 1 do
        for yt = y - 1, y + 1 do
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
    return map
end

local function buildTargets(buildData)
    local map = {}
    for k, l in pairs(locations.get()) do
        if l.team == CONSTS.playerTeam then
            local bdata = locations.getData()[buildData.key]
            for xt = l.x - 1, l.x + 1 do
                for yt = l.y - 1, l.y + 1 do
                    if yt > 0 and yt <= worldmap.MAPSIZEY and xt > 0 and xt <= worldmap.MAPSIZEX then
                        if worldmap.map[yt][xt].align == CONSTS.lightTile and locations.allowedTile(bdata.allowedTiles, worldmap.map[yt][xt].tile) then
                            table.insert(map, {x = xt, y = yt})
                        end
                    end
                end
            end
        end
    end
    return map
end

local function buildUnitTargets()
    local map = {}
    for k, l in pairs(locations.get()) do
        if l.maxUnits and #l.units < l.maxUnits then
            table.insert(map, {x = l.x, y = l.y})
        end
    end
    return map
end

local function deployTargets(unitKey)
    local map = {}
    for k, l in pairs(locations.get()) do
        if l.maxUnits and l.maxUnits > 0 then
            for yt = l.y - 3, l.y + 3 do
                for xt = l.x - 3, l.x + 3 do
                    if yt > 0 and xt > 0 and yt <= worldmap.MAPSIZEY and yt <= worldmap.MAPSIZEX then
                        if units.tileIsAllowed(units.getData()[unitKey], worldmap.map[yt][xt].tile) then
                            table.insert(map, {x = xt, y = yt})
                        end
                    end
                end
            end
        end
    end
    return map
end

local function recallTargets()
    local map = {}
    for k, u in pairs(units.get()) do
        if u.team == CONSTS.playerTeam and u.class ~= "Hero" then
            table.insert(map, {x = u.x,  y = u.y})
        end
    end
    return map
end


return {
    enemyUnitTargets = enemyUnitTargets,
    friendlyUnitTargets = friendlyUnitTargets,
    visibleTileTargets = visibleTileTargets,
    foundingTargets = foundingTargets,
    heroMoveTargets = heroMoveTargets,
    buildTargets = buildTargets,
    buildUnitTargets = buildUnitTargets,
    deployTargets = deployTargets,
    recallTargets = recallTargets
}