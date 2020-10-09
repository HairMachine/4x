local resources = require 'modules/resources'
local worldmap = require 'modules/worldmap'

local locations = {}

local data =  {
    cave = {key = "cave", name = "Cave", tile = "cave", allowedTiles = {}, upkeep = 0, production = 0, hp = 10, maxHp = 10},
    dark_temple = {key = "dark_temple", name = "Dark Temple", tile = "tower", allowedTiles = {}, upkeep = 0, production = 0, hp = 10, maxHp = 10},
    fortress = {key = "fortress", name = "Fortress", tile = "cave", allowedTiles = {}, upkeep = 0, production = 0, hp = 10, maxHp = 10},
    dark_tower = {key = "dark_tower", name = "Dark Tower", tile = "tower", allowedTiles = {}, upkeep = 0, production = 0, hp = 100, maxHp = 100},
    tower = {key = "tower", name = "Wizard's Tower", tile = "tower", allowedTiles = {}, upkeep = 0, production = 0, hp = 10, maxHp = 10, align = 2},
    barracks = {key = "barracks", name = "Barracks", tile = "city", allowedTiles = {"grass"}, upkeep = 0, production = 500, hp = 5, maxHp = 5, maxUnits = 6},
    mine = {key = "mine", name = "Gold Mine", tile = "city", allowedTiles = {"ore"}, upkeep = -50, production = 500, hp = 2, maxHp = 2},
    node = {key = "node", name = "Magical Node", tile = "city", allowedTiles = {"crystal"}, upkeep = 20, production = 500, hp = 2, maxHp = 2},
    sylvan_glade = {key = "sylvan_glade", name = "Sylvan Glade", tile = "city", allowedTiles = {"forest"}, upkeep = 10, production = 500, hp = 5, maxHp = 5},
    shipyard = {key = "shipyard", name = "Shipyard", tile = "city", allowedTiles = {"water"}, upkeep = 10, production = 500, hp = 5, maxHp = 5},
    farm = {key = "farm", name = "Farm", tile = "city", allowedTiles = {"grass"}, upkeep = 10, production = 500, hp = 5, maxHp = 5},
    hamlet = {key = "hamlet", name = "Hamlet", tile = "city", allowedTiles = {}, upkeep = 50, production = 0, hp = 10, maxHp = 10, align = 3}
}

local currentBuildingTile = {tile = "grass", x = 1, y = 1}

local function _farmBuilt(loc)
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
        _farmBuilt(loc)
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
            map[y][x].align = 2
        end
    end
    for k, l in pairs(locations) do
        if l.team == 1 and l.align then
            for xi = l.x - l.align, l.x + l.align do
                for yi = l.y - l.align, l.y + l.align do
                    if xi > 0 and xi <= worldmap.MAPSIZEX and yi > 0 and yi <= worldmap.MAPSIZEY then
                        map[yi][xi].align = 1
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
                for e = x, worldmap.MAPSIZEX do
                    if map[y][e].align == 1 then 
                        surroundX = surroundX + 1
                        break
                    end
                end
                for s = y, worldmap.MAPSIZEY do
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
        for y = 1, worldmap.MAPSIZEY do
            for x = 1, worldmap.MAPSIZEX do
                if freemap[y][x] == false and map[y][x].align == 2 then
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
            if freemap[y][x] == false then map[y][x].align = 1 end
        end
    end
end

local function growSettlement(x, y)
    local cell = worldmap.map[y][x]
    if cell.food and cell.food >= 1 then
        local tile = worldmap.map[y][x]
        tile.food = tile.food - 1
        tile.population = tile.population + 1
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