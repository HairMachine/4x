local locations = require 'locations'

local data = {
    grunter = {name = "Grunter", tile = "monster", speed = 1, attack = 1, hp = 2, team = 2, moved = 0, actions = {}},
    soldier = {name = "Soldier", tile = "army", speed = 1, attack = 1, hp = 5, team = 1, moved = 0, actions = {}},
    engineer = {name = "Engineer", tile = "settler", hp = 1, attack = 0, speed = 1, team = 1, moved = 0, actions = {
        {name = "Build", action = "build"}
    }},
    doom_guard = {name = "Doom Guard", tile = "monster", speed  = 0, attack = 2, team = 2, hp = 10, moved = 0, actions = {}},
    elf = {name = "Elf", tile = "army", speed = 1, attack = 8, hp = 2, team = 1, moved = 0, actions = {}},
    dwarf = {name = "Dwarf", tile = "army", speed = 1, attack = 1, hp = 10, team = 1, moved = 0, actions = {}},
    barbarian = {name = "Barbarian", tile = "army", speed = 1, attack = 3, hp = 5, team = 1, moved = 0, actions = {}},
    wizard = {name = "Wizard", tile = "army", speed = 1, attack = 1, hp = 1, team = 1, moved = 0, actions = {}},
    sage = {name = "Sage", tile = "army", speed = 1, attack = 1, hp = 1, team = 1, moved = 0, actions = {}}
}

local units = {}

local function get()
    return units
end

local function add(type, x, y, parent)
    local newunit = {}
    for k, p in pairs(data[type]) do
        newunit[k] = p
    end
    newunit.type = type
    newunit.x = x
    newunit.y = y
    newunit.parent = parent
    table.insert(units, newunit)
end

local function spawnByLocType(parent)
    for k, l in pairs(locations.get()) do
        if l.key == parent.type and l.x == parent.x and l.y == parent.y then
            if parent.type == "cave" then
                add("grunter", parent.x, parent.y, parent)
            elseif parent.type == "fortress" then
                add("doom_guard", parent.x, parent.y, parent)
            elseif parent.type == "barracks" then
                add("soldier", parent.x, parent.y, parent)
            elseif parent.type == "tower" then
                add("engineer", parent.x, parent.y, parent)
            elseif parent.type == "sylvan_glade" then
                add("elf", parent.x, parent.y, parent)
            elseif parent.type == "dwarf_fortress" then
                add("dwarf", parent.x, parent.y, parent)
            elseif parent.type == "wizard_guild" then
                add("wizard", parent.x, parent.y, parent)
            elseif parent.type == "sage_guild" then
                add("sage", parent.x, parent.y, parent)
            elseif parent.type == "barbarian_village" then
                add("barbarian", parent.x, parent.y, parent)
            end
        end
    end
end

local function remove()
    for i = #units, 1, -1 do
        if units[i].hp <= 0 then
            -- Spawn a new unit from this unit's parent
            if units[i].parent ~= nil then
                spawnByLocType(units[i].parent)
            end
            table.remove(units, i)
        end
    end
end

local function atPos(x, y)
    for k, u in pairs(units) do
        if u.x == x and u.y == y then
            return u
        end
    end
    return {name = "None"}
end

local function getClosestEnemy(unit)
    local mindist = 9001
    local found = {name = "None"}
    for k, u in pairs(locations.get()) do
        if u.team ~= unit.team then
            local tdist = math.abs(unit.x - u.x) + math.abs(unit.y - u.y)
            if tdist < mindist then
                mindist = tdist
                found = u
            end
        end
    end
    return found
end

return {
    get = get,
    add = add,
    remove = remove,
    atPos = atPos,
    getClosestEnemy = getClosestEnemy,
    spawnByLocType = spawnByLocType
}