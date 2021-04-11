local locations = {}

local data =  {
    cave = {key = "cave", class = "dungeon", name = "Cave", tile = "cave", allowedTiles = {}, upkeep = 0, production = 0, hp = 10, maxHp = 10},
    dark_temple = {key = "dark_temple", class = "dungeon", name = "Dark Temple", tile = "tower", allowedTiles = {}, upkeep = 0, production = 0, hp = 10, maxHp = 10},
    fortress = {key = "fortress", class = "dungeon", name = "Fortress", tile = "tower", allowedTiles = {}, upkeep = 0, production = 0, hp = 10, maxHp = 10},
    dark_tower = {key = "dark_tower", class = "dungeon", name = "Dark Tower", tile = "tower", allowedTiles = {}, upkeep = 0, production = 0, hp = 100, maxHp = 100},
    tower = {key = "tower", class = "town_centre", name = "Wizard's Tower", tile = "tower", allowedTiles = {}, upkeep = 0, production = 0, hp = 10, maxHp = 10, align = 2},
    barracks = {key = "barracks", class = "barracks", name = "Barracks", tile = "city", allowedTiles = {"grass"}, upkeep = 10, production = 500, hp = 5, maxHp = 5, maxUnits = 6},
    mine = {key = "mine", class = "utility", name = "Gold Mine", tile = "city", allowedTiles = {"ore"}, upkeep = 10, production = 500, hp = 2, maxHp = 2},
    node = {key = "node", class = "utility", name = "Magical Node", tile = "city", allowedTiles = {"crystal"}, upkeep = 20, production = 500, hp = 2, maxHp = 2},
    sylvan_glade = {key = "sylvan_glade", class = "utility", name = "Sylvan Glade", tile = "city", allowedTiles = {"forest"}, upkeep = 10, production = 500, hp = 5, maxHp = 5},
    shipyard = {key = "shipyard", class = "barracks", name = "Shipyard", tile = "city", allowedTiles = {"water"}, upkeep = 10, production = 500, hp = 5, maxHp = 5},
    hamlet = {key = "hamlet", class = "settlement", name = "Settlement", tile = "city", allowedTiles = {}, upkeep = 10, production = 0, hp = 10, maxHp = 10, align = 1, level = 1},
    housing = {key = "housing", class = "housing", name = "Housing", tile = "city", allowedTiles = {"grass"}, upkeep = 10, production = 500, hp = 8, maxHp = 8},
    road = {key = "road", class = "road", name = "Road", tile = "city", allowedTiles = {"grass", "forest", "mountain", "tundra"}, upkeep = 2, production = 50, hp = 3, maxHp = 3, align = 1},
    factory = {key = "factory", class = "utility", name = "Factory", tile = "city", allowedTiles = {"grass", "forest", "tundra"}, upkeep = 10, production = 500, hp = 5, maxHp = 5},
    academy = {key = "academy", class = "utility", name = "Academy", tile = "city", allowedTiles = {"grass"}, upkeep = 40, production = 2000, hp = 10, maxHp = 10},
    totem_of_control = {key = "totem_of_control", class = "utility", name = "Totem of Control", tile = "tower", allowedTiles = {}, upkeep = 0, production = 0, hp = 20, maxHp = 20, align = 1}
}

local currentBuildingTile = {tile = "grass", x = 1, y = 1}

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
    loc.supplies = {}
    table.insert(locations, loc)
    return loc 
end

local function get()
    return locations
end

local function getData()
    return data
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

local function remove(i)
    table.remove(locations, i)
end

local function atPos(x, y)
    for k, l in pairs(locations) do
        if l.x == x and l.y == y then
            return l
        end
    end
    return {name = "None"}
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
    getAllowedBuildings = getAllowedBuildings,
    remove = remove,
    atPos = atPos,
    allowedTile = allowedTile,
    getFreeUnitSlotCount = getFreeUnitSlotCount
}