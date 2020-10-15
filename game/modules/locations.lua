local resources = require 'modules/resources'
local worldmap = require 'modules/worldmap'

local locations = {}

local data =  {
    cave = {key = "cave", class = "dungeon", name = "Cave", tile = "cave", allowedTiles = {}, upkeep = 0, production = 0, hp = 10, maxHp = 10},
    dark_temple = {key = "dark_temple", class = "dungeon", name = "Dark Temple", tile = "tower", allowedTiles = {}, upkeep = 0, production = 0, hp = 10, maxHp = 10},
    fortress = {key = "fortress", class = "dungeon", name = "Fortress", tile = "cave", allowedTiles = {}, upkeep = 0, production = 0, hp = 10, maxHp = 10},
    dark_tower = {key = "dark_tower", class = "dungeon", name = "Dark Tower", tile = "tower", allowedTiles = {}, upkeep = 0, production = 0, hp = 100, maxHp = 100},
    tower = {key = "tower", class = "town_centre", name = "Wizard's Tower", tile = "tower", allowedTiles = {}, upkeep = 0, production = 0, hp = 10, maxHp = 10, align = 2},
    barracks = {key = "barracks", class = "barracks", name = "Barracks", tile = "city", allowedTiles = {"grass"}, upkeep = 10, production = 500, hp = 5, maxHp = 5, maxUnits = 6},
    mine = {key = "mine", class = "utility", name = "Gold Mine", tile = "city", allowedTiles = {"ore"}, upkeep = 10, production = 500, hp = 2, maxHp = 2},
    node = {key = "node", class = "utility", name = "Magical Node", tile = "city", allowedTiles = {"crystal"}, upkeep = 20, production = 500, hp = 2, maxHp = 2},
    sylvan_glade = {key = "sylvan_glade", class = "utility", name = "Sylvan Glade", tile = "city", allowedTiles = {"forest"}, upkeep = 10, production = 500, hp = 5, maxHp = 5},
    shipyard = {key = "shipyard", class = "barracks", name = "Shipyard", tile = "city", allowedTiles = {"water"}, upkeep = 10, production = 500, hp = 5, maxHp = 5},
    farm = {key = "farm",  class = "utility", name = "Farm", tile = "city", allowedTiles = {"grass"}, upkeep = 10, production = 500, hp = 5, maxHp = 5},
    hamlet = {key = "hamlet", class = "utility", name = "Settlement", tile = "city", allowedTiles = {}, upkeep = 50, production = 0, hp = 10, maxHp = 10, align = 3},
    housing = {key = "housing", class = "housing", name = "Housing", tile = "city", allowedTiles = {"grass"}, upkeep = 10, production = 200, hp = 8, maxHp = 8},
    road = {key = "road", class = "utility", name = "Road", tile = "city", allowedTiles = {"grass", "forest", "mountain", "tundra"}, upkeep = 2, production = 50, hp = 3, maxHp = 3, align = 1},
    factory = {key = "factory", class = "utility", name = "Factory", tile = "city", allowedTiles = {"grass", "forest", "tundra"}, upkeep = 10, production = 500, hp = 5, maxHp = 5}
}

local currentBuildingTile = {tile = "grass", x = 1, y = 1}

local function _builtFarm(loc)
    for y = loc.y - 1, loc.y + 1 do
        for x = loc.x - 1, loc.x + 1 do
            if worldmap.map[y] and worldmap.map[y][x] then
                worldmap.map[y][x].food = worldmap.map[y][x].food + worldmap.map[loc.y][loc.x].abundance
            end
        end
    end
end

local function add(type, x, y, team)
    local loc = {}
    for k, v in pairs(data[type]) do
        loc[k] = v
        if k == "maxUnits" then
            loc.units = {}
        end
    end
    loc.x = x
    loc.y = y
    loc.team = team
    table.insert(locations, loc)
    -- special building effects
    if loc.key == "farm" then
        _builtFarm(loc)
    end
end

local function get()
    return locations
end

local function getData()
    return data
end

local function setCurrentBuildingTile(x, y, tile)
    currentBuildingTile = {tile = tile, x = x, y = y} 
end

local function getCurrentBuildingTile()
    return currentBuildingTile
end

local function getAllowedBuildings()
    local sublist = {}
    for k, l in pairs(data) do
        if l.production > 0 then
            table.insert(sublist, l)
        end
    end
    return sublist
end

local function remove()
    for i = #locations, 1, -1 do
        if locations[i].hp <= 0 then
            -- special building effects
            if locations[i].key == "hq" then
                resources.spendCommandPoints(1)
            end
            table.remove(locations, i)
        end
    end
end

local function atPos(x, y)
    for k, l in pairs(locations) do
        if l.x == x and l.y == y then
            return l
        end
    end
    return {name = "None"}
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
    for k, l in pairs(locations) do
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

local function growSettlement()
    -- Reset population to 0 so we have a clean slate
    for y = 1, worldmap.MAPSIZEY do
        for x = 1, worldmap.MAPSIZEX do
            worldmap.map[y][x].workers = 0
        end
    end
    -- Find all the housing and apply its population effets
    for k, locAt in pairs(locations) do
        local tile = worldmap.map[locAt.y][locAt.x]
        if locAt.class == "housing" then
            if tile.food and tile.food >= 1 then
                tile.food = tile.food - 1
                tile.population = tile.population + 1
                -- Change the tile! TODO: 3 separate states - huts for < 5, nice houses for < 10, tower blocks for > 10
                if locAt.tile == "city" and tile.population >= 5 then
                    locAt.tile = "tower" -- uh... new tile needed!
                elseif locAt.tile == "tower" and tile.population < 5 then
                    locAt.tile = "city"
                end
            end
            -- Population spreads out over a certain range so it can do work
            -- Within a certain range of this settlement, population decreases by 1 each tile.
            -- So if locAt.population == 1, there is no spread. If locAt.population == 2, all surrounding tiles have pop 1.
            -- If locAt.population == 3, all tiles surrounding have population 1, and all tiles around them have population 1. And so on.
            local range = tile.population - 1
            for yt = locAt.y - range, locAt.y + range do
                for xt = locAt.x - range, locAt.x + range do
                    if yt > 0 and yt <= worldmap.MAPSIZEY and xt > 0 and xt <= worldmap.MAPSIZEX then
                        if atPos(xt, yt).class ~= "housing" then
                            local workersToAdd = tile.population - math.max(math.abs(yt - locAt.y), math.abs(xt - locAt.x))
                            worldmap.map[yt][xt].workers = worldmap.map[yt][xt].workers + workersToAdd
                        end
                    end
                end
            end
        end
    end
end

local function allowedTile(allowedTiles, tile)
    for k, v in pairs(allowedTiles) do
        if v == tile then return true end
    end
    return false
end

local function getFreeUnitSlotCount()
    local slots = 0
    for k, l in pairs(locations) do
        if l.maxUnits then
            slots = slots + l.maxUnits - #l.units
        end
    end
    return slots
end

return {
    add = add,
    get = get,
    getData = getData,
    setCurrentBuildingTile = setCurrentBuildingTile,
    getCurrentBuildingTile = getCurrentBuildingTile,
    getAllowedBuildings = getAllowedBuildings,
    remove = remove,
    atPos = atPos,
    tileAlignmentChange = tileAlignmentChange,
    growSettlement = growSettlement,
    allowedTile = allowedTile,
    getFreeUnitSlotCount = getFreeUnitSlotCount
}