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

local function friendlyUnitTargets(noheroes)
    local map = {}
    for k, u in pairs(units.get()) do
        if u.team == CONSTS.playerTeam and worldmap.map[u.y][u.x].align ~= CONSTS.unexploredTile then
            if not (noheroes and u.class == "Hero") then
                table.insert(map, {x = u.x, y = u.y})
            end
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

local function friendlyLocationTargets()
    local map = {}
    for k, l in pairs(locations.get()) do
        if l.team == CONSTS.playerTeam then
            table.insert(map, {x = l.x, y = l.y})
        end
    end
    return map
end

local function tileAlignmentChange()
    local map = worldmap.map
    for y = 1, worldmap.MAPSIZEY do
        for x = 1, worldmap.MAPSIZEX do
            if map[y][x].align == CONSTS.lightTile then
                map[y][x].align = CONSTS.darkTile
            end
        end
    end
    for k, l in pairs(locations.get()) do
        if l.team == CONSTS.playerTeam and l.align then
            for xi = l.x - l.align, l.x + l.align do
                for yi = l.y - l.align, l.y + l.align do
                    if xi > 0 and xi <= worldmap.MAPSIZEX and yi > 0 and yi <= worldmap.MAPSIZEY then
                        map[yi][xi].align = CONSTS.lightTile
                    end
                end
            end
        end
    end
    -- Check for enclosed areas
    -- First, find all the "free" dark tiles - these are tiles that have any two opposite othogonal directions free of any lighted tiles
    local freemap = {}
    for y = 1, worldmap.MAPSIZEY do
        freemap[y] = {}
        for x = 1, worldmap.MAPSIZEX do
            -- Lighted tiles are ALWAYS unfree
            if map[y][x].align == CONSTS.lightTile then
                freemap[y][x] = false
            else
                local surroundX = 0
                local surroundY = 0
                for n = 1, y do
                    if map[n][x].align == CONSTS.lightTile then 
                        surroundY = surroundY + 1 
                        break
                    end
                end
                for e = x, worldmap.MAPSIZEX do
                    if map[y][e].align == CONSTS.lightTile then 
                        surroundX = surroundX + 1
                        break
                    end
                end
                for s = y, worldmap.MAPSIZEY do
                    if map[s][x].align == CONSTS.lightTile then 
                        surroundY = surroundY + 1 
                        break
                    end
                end
                for w = 1, x do
                    if map[y][w].align == CONSTS.lightTile then 
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
        for y = 1, worldmap.MAPSIZEY do
            for x = 1, worldmap.MAPSIZEX do
                if freemap[y][x] == false and map[y][x].align == CONSTS.darkTile then
                    if y - 1 >= 1 and freemap[y - 1][x] == true then 
                        freemap[y][x] = true
                        changed = true
                    end
                    if x + 1 <= worldmap.MAPSIZEX and freemap[y][x + 1] == true then 
                        freemap[y][x] = true 
                        changed = true
                    end
                    if y + 1 <= worldmap.MAPSIZEY and freemap[y + 1][x] == true then 
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
    for y = 1, worldmap.MAPSIZEY do
        for x = 1, worldmap.MAPSIZEX do
            if freemap[y][x] == false then map[y][x].align = CONSTS.lightTile end
        end
    end
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
    recallTargets = recallTargets,
    friendlyLocationTargets = friendlyLocationTargets,
    tileAlignmentChange = tileAlignmentChange
}