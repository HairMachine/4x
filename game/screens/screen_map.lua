local tiles = require 'modules/tiledata'
local ui = require 'modules/ui_manager'
local worldmap = require 'modules/worldmap'
local spells = require 'modules/spells'
local locations = require 'modules/locations'
local units = require 'modules/units'
local resources = require 'modules/resources'
local animation = require 'modules/animation'
local targeter = require 'modules/targeter'
local commands = require 'modules/commands'
local dark_power = require 'modules/dark_power'
local items = require 'modules/items'
local camera = require 'modules/camera'
local production = require 'modules/production'
local rules = require 'modules/rules/main'

local ACTIONSTARTX = 760
local ACTIONSIZEX = 64
local ACTIONSIZEY = 32

local tsize = 32

local buttons = {}

local firstShown = false

local function InfoPopup(title, description)
    buttons.info_popup = {x = 300, y = 200, width = 300, height = 300, visible = 1, text = title.."\n\n"..description, children = {
        {x = 450, y = 400, height = 32, width = 100, visible = 1, text = "OK", action = function() 
            buttons.info_popup = nil
        end}
    }}
end

local function SelectHero(k, e)
    buttons.found_city.visible = 1
    buttons.found_city.unit = e
    buttons.found_city.unitKey = k
    targeter.setUnit(k)
    targeter.setMoveMap(e.x, e.y, e.speed)
    targeter.callback = function(x, y)
        local params = {unitToMove = units.get()[targeter.getUnit()], x = x, y = y}
        if rules.check('HeroExploreLocation', params) then
            local result = rules.trigger('HeroExploreLocation', params)
            InfoPopup(result.title, result.body)
        elseif rules.check('HeroMove', params) then
            rules.trigger('HeroMove', params)
        end
        -- Create animations for any units which might not have them - these will be ones that have just been revealed
        for k, e in pairs(units.get()) do
            if worldmap.map[e.y][e.x].tile ~= CONSTS.unexploredTile then
                if not e.animation then
                    units.setIdleAnimation(e)
                end
            end
        end
        targeter.clear()
        for k, e in pairs(units.get()) do
            if e.type == "hero" and e.moved == 0 then
                SelectHero(k, e)
                return
            end
        end
    end
end

local function SelectNextHero()
    for k, e in pairs(units.get()) do
        if e.type == "hero" and e.moved == 0 then
            SelectHero(k, e)
            return
        end
    end
    buttons.found_city.visible = 0
end

local function EndTurn()
    targeter.clear()

    rules.trigger('ResetUnitMoves')
    rules.trigger('GrowSettlement')
    rules.trigger('PayUpkeepCosts')
    rules.trigger('CooldownRecalledUnits')
    
    -- Move minions (+ pathfinding)
    for k, e in pairs(units.get()) do
        local target = {name = "None"}
        if e.class == "Sieger" then
            target = units.getClosestBuildingWithinRange(e, e.range)
        elseif e.class == "Skirmisher" or e.class == "Defender" then
            target = units.getClosestUnitWithinRange(e, e.range)
            if target.name == "None" and (target.x ~= e.parent.x or target.y ~= e.parent.y) then
                target.name = "Home"
                target.x = e.parent.x
                target.y = e.parent.y
            end
        end
        if target.name ~= "None" and (target.x ~= e.x or target.y ~= e.y) then
            for i = 1, e.speed do
                -- Take distance of all tiles adjacent to the moving unit, store in table
                local candidateTiles = {}
                for x = e.x - 1, e.x + 1 do
                    for y = e.y - 1, e.y + 1 do
                        table.insert(candidateTiles, {
                            x = x, 
                            y = y, 
                            dist = units.getDistBetween(x, y, target.x, target.y)
                        })
                    end
                end
                -- Sort by distance
                table.sort(candidateTiles, function(left, right)
                    return left.dist < right.dist
                end)
                -- Discard the last three
                for i = 1, 3 do
                    table.remove(candidateTiles, #candidateTiles)
                end
                -- Discard any that are blocked
                for j = #candidateTiles, 1, -1 do
                    local newx = candidateTiles[j].x
                    local newy = candidateTiles[j].y
                    if not (newx > 0 and newx <= worldmap.MAPSIZEX and newy > 0 and newy <= worldmap.MAPSIZEY) then
                        table.remove(candidateTiles, j)
                    elseif not units.tileIsAllowed(e, worldmap.map[newy][newx].tile) then
                        table.remove(candidateTiles, j)
                    elseif locations.atPos(newx, newy).name ~= "None" and locations.atPos(newx, newy).team ~= e.team then
                        table.remove(candidateTiles, j)
                    end
                end
                -- Choose the first as the target tile
                if candidateTiles[1] then
                    -- Units don't block candidate tile selection, but units can't walk into them
                    if units.atPos(candidateTiles[1].x, candidateTiles[1].y).name == "None" then
                        units.move(e, candidateTiles[1].x, candidateTiles[1].y)
                    end                    
                end
            end
        end
    end

    rules.trigger('Combat')
    rules.trigger('RespawnUnits')

    commands.new(function(params)
        result = rules.trigger('CheckEndConditions')
        if result == "win" then
            ScreenSwitch("win")
        elseif result == "lose" then
            ScreenSwitch("lose")
        end
        return true
    end, {})
    
    -- Show items
    commands.new(function(params)
        local dropped = items.getDropped()
        local itemText = ""
        if (#dropped > 0) then
            for k, i in pairs(dropped) do
                itemText = itemText.."Found "..i.name.."!\n"
                items.addToInventory(i)
                items.removeFromDropped(k)
            end
            InfoPopup("Monsters dropped items!", itemText)
        end
        return true
    end, {})

    commands.new(function(params)
        rules.trigger('BuildingTurnEffects')
        return true
    end, {})

    commands.new(function(params) 
        rules.trigger('DarkPowerActs')
        return true
    end, {})

    commands.new(function(params)
        if rules.trigger('AdvanceSpellResearch') then
            ScreenSwitch("research")
        end
        return true
    end, {})

    commands.new(function(params)
        rules.trigger('HeroHealthRegen')
        return true
    end, {})

    -- Start turn
    commands.new(function(params)
        SelectNextHero()
        return true
    end, {})

    -- Cooldown spells
    commands.new(function(params)
        rules.trigger('TickSpellCooldown')
        return true
    end, {})

    -- Buildings
    commands.new(function(params)
        production.progressBuilding()
        local built = production.getFinishedBuilding()
        if built then
            if built.type == "location" then
                targeter.setBuildMap(built)
                targeter.callback = function(x, y)
                    locations.add(built.key, x, y, 1)
                    production.removeBuilding()
                    locations.tileAlignmentChange()
                    targeter.clear()
                end
            else
                targeter.setBuildUnitMap(built)
                targeter.callback = function(x, y)
                    local place = locations.atPos(x, y)
                    table.insert(place.units, {unit = built.key, cooldown = 0})
                    production.removeBuilding()
                    targeter.clear()
                end
            end
        end
        return true
    end, {})
end

local function load()
    camera.setSize(720, 532)

    -- Generate map
    worldmap.generate()

    -- Wizard's tower always first
    locations.add("tower", 2, 2, 1)
    
    -- The DARK TOWER!
    worldmap.map[worldmap.MAPSIZEY - 1][worldmap.MAPSIZEX - 1] = worldmap.makeTile("grass", 99)
    worldmap.map[worldmap.MAPSIZEY - 2][worldmap.MAPSIZEX - 1] = worldmap.makeTile("grass", 99)
    worldmap.map[worldmap.MAPSIZEY - 1][worldmap.MAPSIZEX - 2] = worldmap.makeTile("grass", 99)
    locations.add("dark_tower", worldmap.MAPSIZEX - 1, worldmap.MAPSIZEY - 1, 2)
    units.add("doom_guard", worldmap.MAPSIZEX - 1, worldmap.MAPSIZEY - 2, {x = worldmap.MAPSIZEX - 1, y = worldmap.MAPSIZEY - 2, "null"})
    units.add("doom_guard", worldmap.MAPSIZEX - 2, worldmap.MAPSIZEY - 2, {x = worldmap.MAPSIZEX - 2, y = worldmap.MAPSIZEY - 2, "null"})
    units.add("doom_guard", worldmap.MAPSIZEX - 2, worldmap.MAPSIZEY - 1, {x = worldmap.MAPSIZEX - 2, y = worldmap.MAPSIZEY - 1, "null"})
    
    -- Set tile alignments
    locations.tileAlignmentChange()

    -- Starting units
    units.add("hero", 2, 2)
    worldmap.explore(2, 2, 2)
end

local function show()
    buttons = {
        inventory = {x = ACTIONSTARTX, y = 32, width = 100, height = 32, text = "Items", visible = 1, action = function()
            ScreenSwitch("inventory")
        end},
        cast_spell = {x = ACTIONSTARTX, y = 64, width = 100, height = 32, text = "Cast Spell", visible = 1, action = function()
            ScreenSwitch("cast")
        end},
        build = {x = ACTIONSTARTX, y = 96, width = 100, height = 32, text = "Build", visible = 1, action = function()
            if resources.getAvailableGold() > 0 then
                ScreenSwitch("build")
            end
        end},
        deploy = {x = ACTIONSTARTX, y = 128, width = 100, height = 32, text = "Deploy", visible = 1, action = function()
            ScreenSwitch("deploy")
        end},
        recall = {x = ACTIONSTARTX, y = 160, width = 100, height = 32, text = "Recall", visible = 1, action = function()
            targeter.setRecallMap()
            targeter.callback = function(x, y)
                local u = units.atPos(x, y)
                for k, l in pairs(locations.get()) do
                    if l.x == u.parent.x and l.y == u.parent.y then
                        table.insert(l.units, {unit = u.type, cooldown = 5})
                        break
                    end
                end
                units.removeAtPos(x, y)
                targeter.clear()
            end
        end},
        found_city = {x = ACTIONSTARTX, y = 192, width = 100, height = 32, text = "Found City", visible = 0, action = function(event)
            if event.unit.moved == 1 then
                return
            end
            targeter.setUnit(event.unitKey)
            targeter.setFoundingMap(event.unit.x, event.unit.y, 1)
            targeter.callback = function(x, y)
                locations.add("hamlet", x, y, 1)
                locations.tileAlignmentChange()
                targeter.clear()
            end
        end},
        end_phase = {x = ACTIONSTARTX, y = 500, width = 100, height = 32, text = "End Turn", visible = 1, action = function()
            EndTurn()
        end}
    }

    -- If there's a targeter with a unit set, make sure it's properly selected
    if targeter.getUnit() > 0 or firstShown == false then
        SelectNextHero()
    end

    firstShown = true
end

local function update()
    animation.play()
    commands.run()
    -- Move camera
    x, y = love.mouse.getPosition()
    if x > WINDOW.width - 5 then
        camera.move(8, 0)
    end
    if y > WINDOW.height - 5 then
        camera.move(0, 8)
    end
    if x < 5 then
        camera.move(-8, 0)
    end
    if y < 5 then
        camera.move(0, -8)
    end
end

local function keypressed(key, scancode, isrepeat)
    if key == "escape" then
        targeter.clear()
    elseif key == "space" then
        EndTurn()
    end
end

local function mousepressed(x, y, button, istouch, presses)
    if commands.running() > 0 then
        return
    end

    local c = camera.get()
    local tilex = math.floor((x + c.x) / tsize)
    local tiley = math.floor((y + c.y) / tsize)

    -- Clicking on a button!
    ui.click(buttons, x, y)

    -- Clicking on a unit!
    for k, e in pairs(units.get()) do
        if e.moved == 0 and e.x == tilex and e.y == tiley then
            if e.type == "hero" then
                SelectHero(k, e)
                return
            end
        end
    end

    -- Clicking on a targeter
    for k, e in pairs(targeter.getMap()) do
        if e.x > 0 and e.x <= worldmap.MAPSIZEX and e.y > 0 and e.y <= worldmap.MAPSIZEY then
            if e.x == tilex and e.y == tiley then
                targeter.callback(tilex, tiley)
                SelectNextHero()
                return
            end
        end
    end
end

local function draw()
    for y = 1, worldmap.MAPSIZEY do
        for x = 1, worldmap.MAPSIZEX do
            if camera.isInView(x * tsize, y * tsize) and worldmap.map[y][x].align ~= CONSTS.unexploredTile then
                love.graphics.draw(tiles[worldmap.map[y][x].tile], camera.adjustX(x * tsize), camera.adjustY(y * tsize), 0, 2)
                if worldmap.map[y][x].food and worldmap.map[y][x].food > 0 then
                    love.graphics.print(worldmap.map[y][x].food, camera.adjustX(x * tsize + 16), camera.adjustY(y * tsize + 16))
                end
                if worldmap.map[y][x].workers and worldmap.map[y][x].workers > 0 then
                    love.graphics.print(worldmap.map[y][x].workers, camera.adjustX(x * tsize + 16), camera.adjustY(y * tsize))
                end
            end
        end
    end

    for k, e in pairs(locations.get()) do
        if camera.isInView(e.x * tsize, e.y * tsize) and worldmap.map[e.y][e.x].align ~= CONSTS.unexploredTile then
            love.graphics.draw(tiles[e.tile], camera.adjustX(e.x * tsize), camera.adjustY(e.y * tsize), 0 , 2)
        end
    end

    -- Shadow for Dark /Chaotic areas
    love.graphics.setColor(0, 0, 0, 0.3)
    for y = 1, worldmap.MAPSIZEY do
        for x = 1, worldmap.MAPSIZEX do
            if worldmap.map[y][x].align == CONSTS.darkTile and camera.isInView(x * tsize, y * tsize) then
                love.graphics.rectangle("fill", camera.adjustX(x * tsize), camera.adjustY(y * tsize), tsize, tsize)
            end
        end
    end
    love.graphics.setColor(1, 1, 1, 1)

    animation.draw()

    -- Health bars
    love.graphics.setColor(0, 1, 0, 1)
    for k, u in pairs(units.get()) do
        if camera.isInView(u.x * tsize, u.y * tsize) and worldmap.map[u.y][u.x].align ~= CONSTS.unexploredTile then
            local length = math.floor(u.hp / u.maxHp * tsize)
            love.graphics.rectangle("fill", camera.adjustX(u.x * tsize), camera.adjustY(u.y * 32 + tsize - 2), length, 2)
        end
    end
    for k, l in pairs(locations.get()) do
        if camera.isInView(l.x * tsize, l.y * tsize) and worldmap.map[l.y][l.x].align ~= CONSTS.unexploredTile then
            local length = math.floor(l.hp / l.maxHp * 32)
            love.graphics.rectangle("fill", camera.adjustX(l.x * tsize), camera.adjustY(l.y * tsize + tsize - 2), length, 2)
        end
    end
    love.graphics.setColor(1, 1, 1, 1)

    for k, e in pairs(targeter.getMap()) do
        if camera.isInView(e.x * tsize, e.y * tsize) then
            if e.x > 0 and e.x <= worldmap.MAPSIZEX and e.y > 0 and e.y <= worldmap.MAPSIZEY then
                love.graphics.draw(tiles.targeter, camera.adjustX(e.x * tsize), camera.adjustY(e.y * tsize), 0, 2)
            end
        end
    end

    -- UI
    -- Map borders
    -- Wonky logic because the camera just assumes its origin is 0, 0
    love.graphics.rectangle("line", 32, 32, camera.get().w - 32, camera.get().h - 32)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, camera.get().w, 31)
    love.graphics.rectangle("fill", 0, 0, 31, camera.get().h)
    love.graphics.rectangle("fill", camera.get().w, 0, 32, camera.get().h)
    love.graphics.rectangle("fill", 0, camera.get().h, camera.get().w, 32)
    love.graphics.setColor(1, 1, 1, 1)

    -- Sidebar
    ui.draw(buttons)

    love.graphics.print("Command Points: "..resources.getCommandPoints(), ACTIONSTARTX, 400)
    love.graphics.print("Available Budget: "..resources.getAvailableGold(), ACTIONSTARTX, 432)
    love.graphics.print("Magic Points: "..spells.getMP(), ACTIONSTARTX, 464)
end

return {
    load = load,
    show = show,
    update = update,
    keypressed = keypressed,
    mousepressed = mousepressed,
    draw = draw
}