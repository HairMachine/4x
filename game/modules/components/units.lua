local animation = require 'modules/services/animation'
local commands = require 'modules/services/commands'
local worldmap = require 'modules/components/worldmap'

local data = {
    grunter = {
        name = "Grunters", tile = "monster", speed = 1, attack = 1, hp = 5, team = 2, moved = 0, class = "Sieger", range = 10, production = 0, upkeep = 0,
        allowedTiles = {"grass", "ore", "crystal", "forest", "tundra"}
    },
    doom_guard = {
        name = "Doom Guards", tile = "monster", speed  = 1, attack = 2, team = 2, hp = 10, moved = 0, class = "Defender", range = 6, production = 0, upkeep = 0,
        allowedTiles = {"grass", "ore", "crystal", "forest", "tundra"}
    },
    hero = {
        name = "Hero", tile = "hero", speed = 1, attack = 5, hp = 10, team = 1, moved = 0, class = "Hero", range = 0, production = 0, upkeep = 0,
        allowedTiles = {"grass", "ore", "crystal", "forest", "tundra", "ruins"}
    },
    soldier = {
        name = "Soldier", tile = "army", speed = 1, attack = 1, hp = 10, team = 1, moved = 0, class = "Skirmisher", range = 12, production = 200, upkeep = 2,
        allowedTiles = {"grass", "ore", "crystal", "forest", "tundra"}
    },
    cannon = {
        name = "Cannon", tile = "army", speed = 1, attack = 4, hp = 10, team = 1, moved = 0, class = "Sieger", range = 8, production = 300, upkeep = 4,
        allowedTiles = {"grass", "ore", "crystal", "tundra"}
    }
}

local respawning = {}

local units = {}

local function get()
    return units
end

local function getData()
    return data
end

local function setIdleAnimation(unit)
    if unit.animation then
        animation.clear(unit.animation)
    end
    if worldmap.map[unit.y][unit.x].align ~= CONSTS.unexploredTile then
        unit.animation = animation.add(true, {
            {tile = unit.tile, x = unit.x * 32, y =  unit.y * 32, tics = 15},
            {tile = unit.tile, x = unit.x * 32, y =  unit.y * 32 - 5, tics = 15}
        })
    end
end

local function setMoveAnimation(unit, oldx, newx, oldy, newy)
    if unit.animation then
        animation.clear(unit.animation)
    end
    if worldmap.map[oldy][oldx].align == CONSTS.unexploredTile then
        return
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
    if worldmap.map[newy][newx].align == CONSTS.unexploredTile then
        return
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

local function add(t, x, y, parent)
    local newunit = {}
    for k, p in pairs(data[t]) do
        if type(p) == "table" then
            newunit[k] = {}
            for k2, p2 in pairs(p) do
                newunit[k][k2] = p2
            end
        else
            newunit[k] = p
        end
    end
    newunit.type = t
    newunit.x = x
    newunit.y = y
    newunit.parent = parent
    if newunit.type == "hero" then
        newunit.slots = {weapon = {name = ""}, armour = {name = ""}, utility = {name = ""}}
    end
    newunit.maxHp = newunit.hp
    table.insert(units, newunit)
    -- Create animation data
    setIdleAnimation(newunit)
    return newunit
end

local function remove()
    for i = #units, 1, -1 do
        if units[i].hp <= 0 then
            -- Spawn a new unit from this unit's parent
            if units[i].parent ~= nil and units[i].team == CONSTS.enemyTeam then
                table.insert(respawning, {data = units[i].parent, timer = 5})
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

local function atPos(x, y)
    for k, u in pairs(units) do
        if u.x == x and u.y == y then
            return u
        end
    end
    return {name = "None"}
end

local function removeAtPos(x, y)
    for k, u in pairs(units) do
        if u.x == x and u.y == y then
            animation.clear(units[k].animation)
            table.remove(units, k)
            return
        end
    end
end

local function getDistBetween(fx, fy, tx, ty)
    local distx = math.abs(fx - tx)
    local disty = math.abs(fy - ty)
    if distx >= disty then
        return distx
    else
        return disty
    end
end

local function tileIsAllowed(unit, tile)
    for k, e in pairs(unit.allowedTiles) do
        if e == tile then return true end
    end
    return false
end

local function getRespawning()
    return respawning
end

local function respawned(k)
    table.remove(respawning, k)
end


return {
    get = get,
    getData = getData,
    add = add,
    remove = remove,
    atPos = atPos,
    removeAtPos = removeAtPos,
    tileIsAllowed = tileIsAllowed,
    setIdleAnimation = setIdleAnimation,
    move = move,
    getDistBetween = getDistBetween,
    getRespawning = getRespawning,
    respawned = respawned,
    setAttackAnimation = setAttackAnimation,
    setIdleAnimation = setIdleAnimation
}