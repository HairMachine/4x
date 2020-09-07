local locations = require 'modules/locations'
local animation = require 'modules/animation'
local commands = require 'modules/commands'
local resources = require 'modules/resources'

local data = {
    grunter = {
        name = "Grunters", tile = "monster", speed = 1, attack = 1, hp = 2, team = 2, moved = 0, class = "Sieger", actions = {}, 
        allowedTiles = {"grass", "ore", "crystal"}
    },
    soldier = {
        name = "Plainsman Soldiers", tile = "army", speed = 1, attack = 1, hp = 5, team = 1, moved = 0, class = "Skirmisher", actions = {},
        allowedTiles = {"grass", "ore", "crystal"}
    },
    sapper = {
        name = "Plainsman Sappers", tile = "army", speed = 1, attack = 1, hp = 5, team = 1, moved = 0, class = "Sieger", actions = {},
        allowedTiles = {"grass", "ore", "crystal"}
    },
    guard = {
        name = "Plainsman Guards", tile = "army", speed = 1, attack = 1, hp = 5, team = 1, moved = 0, class = "Defender", actions = {},
        allowedTiles = {"grass", "ore", "crystal"}
    },
    doom_guard = {
        name = "Doom Guards", tile = "monster", speed  = 1, attack = 2, team = 2, hp = 10, moved = 0, class = "Defender", actions = {},
        allowedTiles = {"grass", "ore", "crystal"}
    },
    elf = {
        name = "Elven Warriors", tile = "army", speed = 1, attack = 8, hp = 2, team = 1, moved = 0, class = "Defender", actions = {},
        allowedTiles = {"grass", "ore", "crystal", "forest"}
    },
    elf_skirmisher = {
        name = "Elven Skirmisher", tile = "army", speed = 1, attack = 8, hp = 2, team = 1, moved = 0, class = "Skirmisher", actions = {},
        allowedTiles = {"grass", "ore", "crystal", "forest"}
    },
    dwarf = {
        name = "Dwarven Stalwarts", tile = "army", speed = 1, attack = 1, hp = 10, team = 1, moved = 0, class = "Defender", actions = {},
        allowedTiles = {"grass", "ore", "crystal", "mountain"}
    },
    dwarf_sapper = {
        name = "Dwarven Sappers", tile = "army", speed = 1, attack = 1, hp = 10, team = 1, moved = 0, class = "Sieger", actions = {},
        allowedTiles = {"grass", "ore", "crystal", "mountain"}
    },
    barbarian = {
        name = "Barbarian Raiders", tile = "army", speed = 1, attack = 3, hp = 5, team = 1, moved = 0, class = "Skirmisher", actions = {},
        allowedTiles = {"grass", "ore", "crystal", "tundra"}
    },
    barbarian_sacker = {
        name = "Barbarian Sackers", tile = "army", speed = 1, attack = 3, hp = 5, team = 1, moved = 0, class = "Sieger", actions = {},
        allowedTiles = {"grass", "ore", "crystal", "tundra"}
    },
    sage = {
        name = "Sage", tile = "army", speed = 1, attack = 1, hp = 1, team = 1, moved = 0, class = "Special", actions = {},
        allowedTiles = {"grass", "ore", "crystal", "tundra"}
    },
    hero = {
        name = "Hero", tile = "hero", speed = 1, attack = 5, hp = 10, team = 1, moved = 0, class = "Hero", actions = {
            {name = "Build", action = "build"}
        }, allowedTiles = {"grass", "ore", "crystal"}
    }
}

local units = {}

local function get()
    return units
end

local function setIdleAnimation(unit)
    if unit.animation then
        animation.clear(unit.animation)
    end
    unit.animation = animation.add(true, {
        {tile = unit.tile, x = unit.x * 32, y =  unit.y * 32, tics = 15},
        {tile = unit.tile, x = unit.x * 32, y =  unit.y * 32 - 5, tics = 15}
    })
end

local function setMoveAnimation(unit, oldx, newx, oldy, newy)
    if unit.animation then
        animation.clear(unit.animation)
    end
    local animationData = {}
    local xdiff = 0
    local ydiff = 0
    local xanim = (newx - oldx) * 4
    local yanim = (newy - oldy) * 4
    for i = 1, 8 do
        xdiff = xdiff + xanim
        ydiff = ydiff + yanim
        table.insert(animationData, {tile = unit.tile, x = oldx * 32 + xdiff, y =  oldy * 32 + ydiff, tics = 2})
    end
    unit.animation = animation.add(false, animationData)
end

local function setAttackAnimation(unit, newx, newy)
    if unit.animation then
        animation.clear(unit.animation)
    end
    local animationData = {}
    local xdiff = 0
    local ydiff = 0
    local xanim = (newx - unit.x) * 8
    local yanim = (newy - unit.y) * 8
    for i = 1, 2 do
       xdiff = xdiff + xanim
       ydiff = ydiff + yanim 
       table.insert(animationData, {tile = unit.tile, x = unit.x * 32 + xdiff, y =  unit.y * 32 + ydiff, tics = 2})
    end
    for j = 1, 2 do
        xdiff = xdiff - xanim
        ydiff = ydiff - yanim
        table.insert(animationData, {tile = unit.tile, x = unit.x * 32 + xdiff, y =  unit.y * 32 + ydiff, tics = 2})
    end
    unit.animation = animation.add(false, animationData)
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

    -- Create animation data
    setIdleAnimation(newunit)
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
            -- Special case: give back a command point if a hero died
            if units[i].type == "hero" then
                resources.spendCommandPoints(-1)
            end
            animation.clear(units[i].animation)
            table.remove(units, i)
        end
    end
end

local function move(unit, x, y)
    local oldx = unit.x
    local oldy = unit.y
    unit.moved = 1
    unit.x = x
    unit.y = y
    commands.new(function(params)
        if params.started == false then
            setMoveAnimation(params.unit, oldx, params.x, oldy, params.y)
            params.started = true
        end
        if animation.get(params.unit.animation) == nil then
            setIdleAnimation(unit)
            return true
        end
        return false
    end, {unit = unit, started = false, x = x, y = y})
end

local function fight()
    for k, atk in pairs(units) do
        local siegelist = {}
        for k2, def in pairs(locations.get()) do
            if def.team ~= atk.team and def.x >= atk.x - 1 and def.x <= atk.x + 1 and def.y >= atk.y - 1 and def.y <= atk.y + 1 then
                table.insert(siegelist, def)
            end
        end
        if #siegelist > 0 then
            local sieged = siegelist[love.math.random(1, #siegelist)]
            sieged.hp = sieged.hp - atk.attack
            commands.new(function(params) 
                if params.started == false then
                    setAttackAnimation(params.unit, params.x, params.y)
                    params.started = true
                end
                if animation.get(params.unit.animation) == nil then
                    setIdleAnimation(params.unit)
                    return true
                end
                return false
            end, {unit = atk, started = false, x = sieged.x, y = sieged.y})
        else
            local atklist = {}
            for k2, def in pairs(units) do
                if def.team ~= atk.team and def.x >= atk.x - 1 and def.x <= atk.x + 1 and def.y >= atk.y - 1 and def.y <= atk.y + 1 then
                    table.insert(atklist, def)
                end
            end
            if #atklist > 0 then
                local attacked = atklist[love.math.random(1, #atklist)]
                attacked.hp = attacked.hp - atk.attack
                commands.new(function(params) 
                    if params.started == false then
                        setAttackAnimation(params.unit, params.x, params.y)
                        params.started = true
                    end
                    if animation.get(params.unit.animation) == nil then
                        setIdleAnimation(params.unit)
                        return true
                    end
                    return false
                end, {unit = atk, started = false, x = attacked.x, y = attacked.y})
                -- TODO: Apply any special attacking effects that this unit might have
            end
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

local function getDistBetween(fx, fy, tx, ty)
    local distx = math.abs(fx - tx)
    local disty = math.abs(fy - ty)
    if distx >= disty then tdist = distx else tdist = disty end
    return tdist
end

local function getClosestBuilding(unit)
    local mindist = 9001
    local found = {name = "None"}
    for k, u in pairs(locations.get()) do
        if u.team ~= unit.team then
            local tdist = getDistBetween(unit.x, unit.y, u.x, u.y)
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
                local tdist = getDistBetween(unit.x, unit.y, u.x, u.y)
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
            local tdist = getDistBetween(unit.x, unit.y, u.x, u.y)
            if tdist < mindist then
                mindist = tdist
                found = u
            end
        end
    end
    return found
end

local function swapSidesRandom(otherTeam)
    local list = {}
    for k, e in pairs(units) do
        if e.team ~= otherTeam and e.class ~= "Hero" then
            table.insert(list, e)
        end
    end
    if #list == 0 then
        return false
    end
    local r = love.math.random(1, #list)
    list[r].team = otherTeam
    -- TODO: This is a hack / placeholder and should be fixed - more systematic way of having tiles and team, perhaps
    -- a standardised background or something rather than it literally just being on the tile
    if otherTeam == 2 then
        list[r].tile = "monster"
        -- Destroy this unit's parent, if there is one
        if list[r].parent.x and list[r].parent.y then
            local l = locations.getByCoordinates(list[r].parent.x, list[r].parent.y)
            l.hp = 0
            locations.remove()
        end
    end
    return true
end

local function tileIsAllowed(unit, tile)
    for k, e in pairs(unit.allowedTiles) do
        if e == tile then return true end
    end
    return false
end

return {
    get = get,
    add = add,
    remove = remove,
    atPos = atPos,
    getClosestBuilding = getClosestBuilding,
    getClosestUnit = getClosestUnit,
    getClosestUnitWithinRange = getClosestUnitWithinRange,
    spawnByLocType = spawnByLocType,
    swapSidesRandom = swapSidesRandom,
    tileIsAllowed = tileIsAllowed,
    setIdleAnimation = setIdleAnimation,
    move = move,
    fight = fight
}