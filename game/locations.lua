local resources = require 'resources'

local locations = {}

local data =  {
    cave = {key = "cave", name = "Cave", tile = "cave", allowedTiles = {}, cost = 0, hp = 5, maxHp = 5},
    tower = {key = "tower", name = "Wizard's Tower", tile = "tower", allowedTiles = {}, cost = 0, hp = 10, maxHp = 10},
    barracks = {key = "barracks", name = "Barracks", tile = "city", allowedTiles = {"grass"}, cost = 1, hp = 5, maxHp = 5},
    mine = {key = "mine", name = "Gold Mine", tile = "city", allowedTiles = {"ore"}, cost = -4, hp = 2, maxHp = 2},
    node = {key = "node", name = "Magical Node", tile = "city", allowedTiles = {"crystal"}, cost = 1, hp = 2, maxHp = 2},
    dark_tower = {key = "dark_tower", name = "Dark Tower", tile = "tower", allowedTiles = {}, cost = 0, hp = 10, maxHp = 10},
    sylvan_glade = {key = "sylvan_glade", name = "Sylvan Glade", tile = "city", allowedTiles = {"forest"}, cost = 3, hp = 5, maxHp = 5},
    dwarf_fortress = {key = "dwarf_fortress", name = "Dwarf Fortress", tile = "city", allowedTiles = {"mountain"}, cost = 3, hp = 10, maxHp = 10},
    barbarian_village = {key = "barbarian_village", name = "Barbarian Village", tile = "city", allowedTiles = {"tundra"}, cost = 3, hp = 5, maxHp = 5},
    shipyard = {key = "shipyard", name = "Shipyard", tile = "city", allowedTiles = {"water"}, cost = 2, hp = 5, maxHp = 5},
    wizard_guild = {key = "wizard_guild", name = "Wizard Guild", tile = "city", allowedTiles = {"crystal"}, cost = 3, hp = 5, maxHp = 5},
    sage_guild = {key = "sage_guild", name = "Sage Guild", tile = "city", allowedTiles = {"ruins"}, cost = 5, hp = 1, maxHp = 5}
}

local currentBuildingTile = {tile = "grass", x = 1, y = 1}

local function add(type, x, y, team)
    local loc = {}
    for k, v in pairs(data[type]) do
        loc[k] = v
    end
    loc.x = x
    loc.y = y
    loc.team = team
    table.insert(locations, loc)
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
        for k2, t in pairs(l.allowedTiles) do
            if t == currentBuildingTile.tile then
                table.insert(sublist, l)
            end
        end
    end
    return sublist
end

local function remove()
    for i = #locations, 1, -1 do
        if locations[i].hp <= 0 then
            resources.spendGold(-locations[i].cost)
            table.remove(locations, i)
        end
    end
end

return {
    add = add,
    get = get,
    getData = getData,
    setCurrentBuildingTile = setCurrentBuildingTile,
    getCurrentBuildingTile = getCurrentBuildingTile,
    getAllowedBuildings = getAllowedBuildings,
    remove = remove
}