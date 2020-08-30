local ui = require 'ui_manager'
local spells = require 'spells'
local locations = require 'locations'
local units = require 'units'
local resources = require 'resources'

local tiles = {
    grass = love.graphics.newImage("assets/grass.png"),
    cave = love.graphics.newImage("assets/cave.png"),
    city = love.graphics.newImage("assets/city.png"),
    monster = love.graphics.newImage("assets/monster.png"),
    settler = love.graphics.newImage("assets/settler.png"),
    targeter = love.graphics.newImage("assets/targeter.png"),
    army = love.graphics.newImage("assets/army.png"),
    tower = love.graphics.newImage("assets/tower.png"),
    ore = love.graphics.newImage("assets/ore.png"),
    crystal = love.graphics.newImage("assets/crystal.png"),
    water = love.graphics.newImage("assets/water.png"),
    forest = love.graphics.newImage("assets/forest.png"),
    mountain = love.graphics.newImage("assets/mountain.png"),
    tundra = love.graphics.newImage("assets/tundra.png"),
    ruins = love.graphics.newImage("assets/ruins.png")
}

local ACTIONSTARTX = 600
local ACTIONSTARTY = 200
local ACTIONSIZEX = 64
local ACTIONSIZEY = 32

local map = {}
local MAPSIZEX = 17
local MAPSIZEY = 17
local tsize = 32

local commandPointMax = 2
local commandPoints = commandPointMax

local caveSpawnTimer = 0
local caveSpawnTimerTarget = 1

local darkPower = 0

local targeter = {
    map = {},
    unit = 0,
    type = "",
    callback = function() end
}

local buttons = {
    cast_spell = {x = 600, y = 50, width = 100, height = 32, text = "Cast Spell", action = "startCast", visible = 1},
    end_phase = {x = 600, y = 100, width = 100, height = 50, text = "End Phase", action = "endTurn", visible = 1},
    build = {x = 600, y = 150, width = 100, height = 32, text = "Build", action = "buildTower", visible = 1}
}

local function TileAlignmentChange()
    for y = 1, MAPSIZEY do
        for x = 1, MAPSIZEX do
            map[y][x].align = 2
        end
    end
    for k, l in pairs(locations.get()) do
        if l.team == 1 then
            for xi = l.x - 1, l.x + 1 do
                for yi = l.y - 1, l.y + 1 do
                    if xi > 0 and xi <= MAPSIZEX and yi > 0 and yi <= MAPSIZEY then
                        map[yi][xi].align = 1
                    end
                end
            end
        end
    end
end

local function SpellTargeter(radius, wizards)
    targeter.map = {}
    -- around wizard's tower
    for x = locations.get()[1].x - radius, locations.get()[1].x + radius do
        for y = locations.get()[1].y - radius, locations.get()[1].y + radius do
            table.insert(targeter.map, {x = x, y = y})
        end
    end
    -- around wizards!
    if wizards == true then
        for k, e in pairs(units.get()) do
            if e.type == "wizard" then
                for x = e.x - radius, e.x + radius do
                    for y = e.y - radius, e.y + radius do
                        table.insert(targeter.map, {x = x, y = y})
                    end
                end
            end
        end
    end
    targeter.type = "spell"
end

local spellEffects = {
    none = function() end,
    phase_tower = function()
        SpellTargeter(2, false)
        targeter.callback = function(x, y)
            locations.get()[1].x = x
            locations.get()[1].y = y
            -- Update the engineer's location ref
            for k, e in pairs(units.get()) do
                if e.type == "engineer" then
                    e.parent.x = x
                    e.parent.y = y
                end
            end
            targeter.map = {}
        end
    end,
    lightning_bolt = function()
        SpellTargeter(3, true)
        targeter.callback = function(x, y)
            for k, u in pairs(units.get()) do
                if x == u.x and y == u.y then
                    u.hp = u.hp - 10
                end
            end
            units.remove()
            targeter.map = {}
        end
    end,
    summon_imp = function()
        units.add("engineer", locations.get()[1].x, locations.get()[1].y, {"tower", locations.get()[1].x, locations.get()[1].y})
    end
}

local function caveSpawnTimerTargetSet()
    local caveSpawned = 0
    for k, l in pairs(locations.get()) do
        if l.key == "cave" then caveSpawned = caveSpawned + 1 end
    end
    if caveSpawned < 12 then
        caveSpawnTimerTarget = caveSpawned * 3
    else
        caveSpawnTimerTarget = 10000 -- essentially forever
    end
end

local function EndTurn()
    targeter.map = {}
    targeter.unit = 0
    for k, e in pairs(units.get()) do
        e.moved = 0
    end
    -- Perform BATTLES!
    for k, atk in pairs(units.get()) do
        local siegelist = {}
        for k2, def in pairs(locations.get()) do
            if def.team ~= atk.team and def.x >= atk.x - 1 and def.x <= atk.x + 1 and def.y >= atk.y - 1 and def.y <= atk.y + 1 then
                table.insert(siegelist, def)
            end
        end
        if #siegelist > 0 then
            local sieged = siegelist[love.math.random(1, #siegelist)]
            sieged.hp = sieged.hp - atk.attack
        else
            local atklist = {}
            for k2, def in pairs(units.get()) do
                if def.team ~= atk.team and def.x >= atk.x - 1 and def.x <= atk.x + 1 and def.y >= atk.y - 1 and def.y <= atk.y + 1 then
                    table.insert(atklist, def)
                end
            end
            if #atklist > 0 then
                local attacked = atklist[love.math.random(1, #atklist)]
                attacked.hp = attacked.hp - atk.attack
                -- TODO: Apply any special attacking effects that this unit might have
            end
        end
    end
    -- Perform BUILDING EFFECTS
    for k, l in pairs(locations.get()) do
        if l.key == "node" or l.key == "tower" then
            spells.addMP(1)
        elseif l.key == "dark_fortress" then
            darkPower = darkPower + 1
            -- TODO: BAD things happen as dark power goes up!
        end
    end
    -- Check on win conditions!
    if locations.get()[2].hp <= 0 then
        ScreenSwitch("win")
        return
    end
    if locations.get()[1].hp <= 0 then
        ScreenSwitch("lose")
        return
    end
    -- Remove dead things
    units.remove()
    locations.remove()
    caveSpawnTimerTargetSet()
    -- Monsters move!
    for k, e in pairs(units.get()) do
        if e.team == 2 then
            for i = 1, e.speed do
                local target = units.getClosestEnemy(e)
                if target.name ~= "None" then
                    -- TODO: Real path finding when I can be bothered
                    local dirx = target.x - e.x
                    local diry = target.y - e.y
                    if dirx < 0 then dirx = -1 elseif dirx > 0 then dirx = 1 end
                    if diry < 0 then diry = -1 elseif diry > 0 then diry = 1 end
                    if units.atPos(e.x + dirx, e.y + diry).name == "None" then
                        e.x = e.x + dirx
                        e.y = e.y + diry
                    end
                end
            end
        end
    end
    -- MAKE MORE CAVES
    caveSpawnTimer = caveSpawnTimer + 1
    if caveSpawnTimer >= caveSpawnTimerTarget then
        -- Create a list of allowed tiles
        local caveLocs = {}
        for y = 1, MAPSIZEY do
            for x = 1, MAPSIZEX do
                if map[y][x].align == 2 then
                    table.insert(caveLocs, {x = x, y = y})
                end
            end
        end
        if #caveLocs > 0 then
            -- Chose a random one
            local loc = caveLocs[love.math.random(1, #caveLocs)]
            local roll = love.math.random(1, 6)
            if roll <= 2 then
                locations.add("cave", loc.x, loc.y, 2)
                units.add("grunter", loc.x, loc.y, {type = "cave", x = loc.x, y = loc.y})
            elseif roll <= 4 then
                locations.add("dark_temple", loc.x, loc.y, 2)
            else
                locations.add("fortress", loc.x, loc.y, 2)
                units.add("doom_guard", loc.x, loc.y, {type = "fortress", x = loc.x, y = loc.y})
            end
            caveSpawnTimer = 0
            caveSpawnTimerTargetSet()
        end
    end
    commandPoints = commandPointMax
    -- Research spells
    local researchBonus = 0
    for k, e in pairs(units.get()) do
        if e.type == "sage" then
            researchBonus = researchBonus + 1
        end
    end
    spells.research(researchBonus)
    if spells.getLearning() == "none" and #spells.researchable > 0 then
        ScreenSwitch("research")
    end
    if spells.cast() then
        spellEffects[spells.getCasting().key]()
        spells.stopCasting()
    end
end

local buttonActions = {
    none = function() end,
    endTurn = function()
        EndTurn()
    end,
    build = function(entity)
        locations.setCurrentBuildingTile(entity.x, entity.y, map[entity.y][entity.x].tile)
        ScreenSwitch("build")
    end,
    buildTower = function()
        -- TODO: Cancelling currently fucks this up, it needs to work better
        if commandPoints < 2 then return end
        SpellTargeter(2, false)
        targeter.callback = function(x, y)
            locations.setCurrentBuildingTile(x, y, map[y][x].tile)
            ScreenSwitch("build")
            commandPoints = commandPoints - 2
            targeter.map = {}
        end
    end,
    startCast = function()
        ScreenSwitch("cast")
    end
}

local function load()
    for k, v in pairs(tiles) do
        v:setFilter("nearest", "nearest")
    end

    for y = 1, MAPSIZEY do
        map[y] = {}
        for x = 1, MAPSIZEX  do
            if x == 1 or y == 1 or x == MAPSIZEX or y == MAPSIZEY then
                map[y][x] = {tile = "water", align = 2}
            elseif (x == 2 or y == 2 or x ==  MAPSIZEX - 1 or y == MAPSIZEY - 1) and love.math.random(1, 10) >= 7 then
                map[y][x] = {tile = "water", align = 2}
            else 
                map[y][x] = {tile = "grass", align = 2}
            end
        end
    end
    for c = 1, 10 do
        map[love.math.random(2, MAPSIZEY - 1)][love.math.random(2, MAPSIZEX - 1)].tile = "mountain"
        map[love.math.random(2, MAPSIZEY - 1)][love.math.random(2, MAPSIZEX - 1)].tile = "ruins"
        map[love.math.random(2, MAPSIZEY - 1)][love.math.random(2, MAPSIZEX - 1)].tile = "tundra"
        map[love.math.random(2, MAPSIZEY - 1)][love.math.random(2, MAPSIZEX - 1)].tile = "forest"
    end

    -- Make crystal and gold, evenly spaced
    local til = "ore"
    for y = 0, 4 do
        for x = 0, 4 do
            local xoffs = love.math.random(0, 2)
            local yoffs = love.math.random(0, 2)
            -- Annoying hack to stop gold appearing on the tower tile - will have to be improved
            if xoffs == 0 and yoffs == 0 and x == 0 and y == 0 then
                xoffs = xoffs + 1
            end
            map[y * 3 + yoffs + 2][x * 3 + xoffs + 2].tile = til
            if til == "ore" then til = "crystal" else til = "ore" end
        end
    end

    -- TODO Make rivers

    -- Wizard's tower and engineer always first
    map[2][2] = {tile = "grass"}
    map[3][2] = {tile = "grass"}
    map[2][3] = {tile = "grass"}
    locations.add("tower", 2, 2, 1)
    --units.add("engineer", 2, 2, {type = "tower", x = 2, y = 2})
    
    -- The DARK TOWER!
    map[MAPSIZEX - 1][MAPSIZEX - 1] = {tile = "grass"}
    map[MAPSIZEX - 2][MAPSIZEX - 1] = {tile = "grass"}
    map[MAPSIZEX - 1][MAPSIZEX - 2] = {tile = "grass"}
    locations.add("dark_tower", MAPSIZEX - 1, MAPSIZEY - 1, 2)

    TileAlignmentChange()
end

local function show()
    
end

local function update()
    -- This just totally sucks, fix it. It's here because of the way building currently works
    TileAlignmentChange()
end

local function keypressed(key, scancode, isrepeat)
    
end

local function mousepressed(x, y, button, istouch, presses)
    local tilex = math.floor(x / tsize)
    local tiley = math.floor(y / tsize)

    -- Clicking on a button!
    buttonActions[ui.click(buttons, x, y)]()

    -- Clicking on a unit action!
    if targeter.unit > 0 and units.get()[targeter.unit].moved == 0 then
        for k, e in pairs(units.get()[targeter.unit].actions) do
            if x > ACTIONSTARTX and x < ACTIONSTARTX + ACTIONSIZEX and y > ACTIONSTARTY and y < ACTIONSTARTY + ACTIONSIZEY and commandPoints > 0 then
                units.get()[targeter.unit].moved = 1
                targeter.map = {}
                buttonActions[e.action](units.get()[targeter.unit])
                commandPoints = commandPoints - 1
            end
        end
    end

    -- Clicking on a unit!
    for k, e in pairs(units.get()) do
        if e.team == 1 and e.moved == 0 and e.x == tilex and e.y == tiley and commandPoints > 0 then
            targeter.unit = k
            targeter.type = "move"
            targeter.map = {}
            for y = e.y - e.speed, e.y + e.speed do
                for x = e.x - e.speed, e.x + e.speed do
                    table.insert(targeter.map, {x = x, y = y})
                end
            end
            return
        end
    end

    -- Clicking on a targeter
    for k, e in pairs(targeter.map) do
        if e.x == tilex and e.y == tiley then
            if targeter.type == "move" then
                -- check if a unit is on this tile
                for ku, u in pairs(units.get()) do
                    if u.x == e.x and u.y == e.y then 
                        return
                    end
                end
                units.get()[targeter.unit].x = tilex
                units.get()[targeter.unit].y = tiley
                units.get()[targeter.unit].moved = 1
                targeter.map = {}
                targeter.unit = 0
                commandPoints = commandPoints - 1
            elseif targeter.type == "spell" then
                targeter.callback(tilex, tiley)
            end
        end
    end
end

local function draw()
    for y = 1, MAPSIZEY do
        for x = 1, MAPSIZEX do
            love.graphics.draw(tiles[map[y][x].tile], x * tsize, y * tsize, 0, 2)
        end
    end

    for k, e in pairs(locations.get()) do
        love.graphics.draw(tiles[e.tile], e.x * tsize, e.y * tsize, 0 , 2)
    end

    for k, e in pairs(units.get()) do
        love.graphics.draw(tiles[e.tile], e.x * tsize, e.y * tsize, 0 , 2)
    end

    for k, e in pairs(targeter.map) do
        love.graphics.draw(tiles.targeter, e.x * tsize, e.y * tsize, 0, 2)
    end

    love.graphics.setColor(0, 0, 0, 0.3)
    for y = 1, MAPSIZEY do
        for x = 1, MAPSIZEX do
            if map[y][x].align == 2 then
                love.graphics.rectangle("fill", x * tsize, y * tsize, tsize, tsize)
            end
        end
    end
    love.graphics.setColor(1, 1, 1, 1)

    -- UI
    love.graphics.print("Currently casting: "..spells.getCasting().name, ACTIONSTARTX, 0)

    ui.draw(buttons)

    -- Unit options
    if targeter.unit > 0 and units.get()[targeter.unit].moved == 0 then
        for k, e in pairs(units.get()[targeter.unit].actions) do
            love.graphics.rectangle("line", ACTIONSTARTX, ACTIONSTARTY + (k-1) * ACTIONSIZEY, ACTIONSIZEX, ACTIONSIZEY)
            love.graphics.print(e.name, ACTIONSTARTX, ACTIONSTARTY + (k-1) * ACTIONSIZEY)
        end
    end

    love.graphics.print("Command Points: "..commandPoints, ACTIONSTARTX, 500)
    love.graphics.print("Available Budget: "..resources.getAvailableGold(), ACTIONSTARTX, 532)
    love.graphics.print("Magic Points: "..spells.getMP(), ACTIONSTARTX, 564)
end

return {
    load = load,
    show = show,
    update = update,
    keypressed = keypressed,
    mousepressed = mousepressed,
    draw = draw
}