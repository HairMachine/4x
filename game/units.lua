local locations = require 'locations'

local data = {
    grunter = {name = "Grunters", tile = "monster", speed = 1, attack = 1, hp = 2, team = 2, moved = 0, class = "Sieger", actions = {}},
    soldier = {name = "Plainsman Soldiers", tile = "army", speed = 1, attack = 1, hp = 5, team = 1, moved = 0, class = "Skirmisher", actions = {}},
    sapper = {name = "Plainsman Sappers", tile = "army", speed = 1, attack = 1, hp = 5, team = 1, moved = 0, class = "Sieger", actions = {}},
    guard = {name = "Plainsman Guards", tile = "army", speed = 1, attack = 1, hp = 5, team = 1, moved = 0, class = "Defender", actions = {}},
    doom_guard = {name = "Doom Guards", tile = "monster", speed  = 1, attack = 2, team = 2, hp = 10, moved = 0, class = "Defender", actions = {}},
    elf = {name = "Elven Warriors", tile = "army", speed = 1, attack = 8, hp = 2, team = 1, moved = 0, class = "Defender", actions = {}},
    elf_skirmisher = {name = "Elven Skirmisher", tile = "army", speed = 1, attack = 8, hp = 2, team = 1, moved = 0, class = "Skirmisher", actions = {}},
    dwarf = {name = "Dwarven Stalwarts", tile = "army", speed = 1, attack = 1, hp = 10, team = 1, moved = 0, class = "Defender", actions = {}},
    dwarf_sapper = {name = "Dwarven Sappers", tile = "army", speed = 1, attack = 1, hp = 10, team = 1, moved = 0, class = "Sieger", actions = {}},
    barbarian = {name = "Barbarian Raiders", tile = "army", speed = 1, attack = 3, hp = 5, team = 1, moved = 0, class = "Skirmisher", actions = {}},
    barbarian_sacker = {name = "Barbarian Sackers", tile = "army", speed = 1, attack = 3, hp = 5, team = 1, moved = 0, class = "Sieger", actions = {}},
    sage = {name = "Sage", tile = "army", speed = 1, attack = 1, hp = 1, team = 1, moved = 0, class = "Special", actions = {}},
    hero = {name = "Hero", tile = "hero", speed = 1, attack = 5, hp = 10, team = 1, moved = 0, class = "Hero", actions = {
        {name = "Build", action = "build"}
    }}
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
            elseif parent.type == "sapper_camp" then
                add("sapper", parent.x, parent.y, parent)
            elseif parent.type == "outpost" then
                add("guard", parent.x, parent.y, parent)
            elseif parent.type == "tower" then
                add("hero", parent.x, parent.y, {})
            elseif parent.type == "sylvan_glade" then
                add("elf", parent.x, parent.y, parent)
            elseif parent.type == "warglade" then
                add("elf_skirmisher", parent.x, parent.y, parent)
            elseif parent.type == "dwarf_fortress" then
                add("dwarf", parent.x, parent.y, parent)
            elseif parent.type == "dwarf_workshop" then
                add("dwarf_sapper", parent.x, parent.y, parent)
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

local function getClosestBuilding(unit)
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

local function getClosestUnitWithinRange(unit, range)
    local mindist = 9001
    local found = {name = "None"}
    for k, u in pairs(units) do
        if u.team ~= unit.team then
            local tx = unit.x
            local ty = unit.y
            if unit.parent.x and unit.parent.y then
                tx = unit.parent.x
                ty = unit.parent.y
            end
            if math.abs(u.x - tx) <= range and math.abs(u.y - ty) <= range then
                local tdist = math.abs(unit.x - u.x) + math.abs(unit.y - u.y)
                if tdist < mindist then
                    mindist = tdist
                    found = u
                end
            end
        end
    end
    return found
end

local function getClosestUnit(unit)
    local mindist = 9001
    local found = {name = "None"}
    for k, u in pairs(units) do
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
    getClosestBuilding = getClosestBuilding,
    getClosestUnit = getClosestUnit,
    getClosestUnitWithinRange = getClosestUnitWithinRange,
    spawnByLocType = spawnByLocType
}