local camera = require 'modules/services/camera'
local tiles = require 'modules/services/tiledata'
local animation = require 'modules/services/animation'
local targeter = require 'modules/services/targeter'
local ui = require 'modules/services/ui_manager'
local commands = require 'modules/services/commands'
local worldmap = require 'modules/components/worldmap'
local spells = require 'modules/components/spells'
local locations = require 'modules/components/locations'
local units = require 'modules/components/units'
local resources = require 'modules/components/resources'
local dark_power = require 'modules/components/dark_power'
local items = require 'modules/components/items'
local production = require 'modules/components/production'
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
    buttons.recruit.visible = 1
    buttons.found_city.unit = e
    buttons.found_city.unitKey = k
    camera.setPos(e.x * tsize - camera.getSize().w / 2, e.y * tsize - camera.getSize().h / 2)
    rules.trigger('HeroMove', {k = k, u = e}, function(result)
        if result then
            InfoPopup(result.title, result.body)
        end
        for k, e2 in pairs(units.get()) do
            if e2.type == "hero" and e2.moved == 0 then
                SelectHero(k, e2)
                return
            end
        end
    end)
    
end

local function SelectNextHero()
    for k, e in pairs(units.get()) do
        if e.type == "hero" and e.moved == 0 then
            SelectHero(k, e)
            return true
        end
    end
    buttons.found_city.visible = 0
    buttons.recruit.visible = 0
    return false
end

local function EndTurn()
    targeter.clear()

    for k, e in pairs(units.get()) do
        e.moved = 0
    end

    rules.trigger('MoveAiUnits')
    rules.trigger('Fight')

    result = rules.trigger('CheckEndConditions')
    if result == "win" then
        ScreenSwitch("win")
    elseif result == "lose" then
        ScreenSwitch("lose")
    end

    -- Something wrong with this somewhere
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
    rules.trigger('ItemTurnEffects')
    rules.trigger('BuildingTurnEffects')
    rules.trigger('PayUpkeepCosts')
    rules.trigger('GrowSettlement')
    rules.trigger('RespawnUnits')
    rules.trigger('DarkPowerActs')
    if rules.trigger('AdvanceSpellResearch') then
        ScreenSwitch("research")
    end
    rules.trigger('HeroHealthRegen')
    rules.trigger('TickSpellCooldown')
    SelectNextHero()
    rules.trigger('Build')
end

local function load()
    camera.setSize(720, 532)
    camera.setPos(math.floor(worldmap.MAPSIZEX / 2) + 250, math.floor(worldmap.MAPSIZEY / 2) + 250)
    rules.trigger('SetupBoard')
    rules.trigger('SetupStartingUnits')
end

local function show()
    buttons = {
        inventory = {x = ACTIONSTARTX, y = 32, width = 100, height = 32, text = "Items", visible = 1, action = function()
            ScreenSwitch("inventory")
        end},
        cast_spell = {x = ACTIONSTARTX, y = 64, width = 100, height = 32, text = "Cast Spell", visible = 1, action = function()
            ScreenSwitch("cast")
        end},
        recruit = {x = ACTIONSTARTX, y = 160, width = 100, height = 32, text = "Recruit", visible = 0, action = function(event) 
            local sel = targeter.getUnit()
            if sel == -1 then return end
            -- Check we are in a lighted area
            if worldmap.map[units.get()[sel].y][units.get()[sel].x].align ~= CONSTS.lightTile then
                return
            end
            ScreenSwitch('build')
        end},
        found_city = {x = ACTIONSTARTX, y = 192, width = 100, height = 32, text = "Settle", visible = 0, action = function(event)
            if event.unit.moved == 1 then
                return
            end
            rules.trigger('Settle', {unitKey = event.unitKey, unit = event.unit})
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
        -- FIXME: Really flaky logic I think
        if targeter.getUnit() > 0 then 
            units.get()[targeter.getUnit()].moved = 1
        end
        local anotherHero = SelectNextHero()
        if not anotherHero then
            EndTurn()
        end
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

    -- Animated elements!
    for k, a in pairs(animation.get()) do
        local cframe = a.frames[a.frame]
        if camera.isInView(cframe.x, cframe.y) then
            if worldmap.map[math.ceil(cframe.y / tsize)][math.floor(cframe.x / tsize)].align ~= CONSTS.unexploredTile then
                love.graphics.draw(tiles[a.frames[a.frame].tile], camera.adjustX(a.frames[a.frame].x), camera.adjustY(a.frames[a.frame].y), 0, 2)
            end
        end
    end

    -- Stack size
    for k, u in pairs(units.get()) do
        if u.team == 2 and camera.isInView(u.x * tsize, u.y * tsize) and worldmap.map[u.y][u.x].align ~= CONSTS.unexploredTile then
            if u.stacks and #u.stacks > 0 then
                love.graphics.print(u.stacks[1].size + 1, camera.adjustX(u.x * tsize) + 24, camera.adjustY(u.y * tsize) + 24)
            else
                love.graphics.print(1, camera.adjustX(u.x * tsize) + 24, camera.adjustY(u.y * tsize) + 24)
            end
        end
    end

    -- Health bars
    love.graphics.setColor(0, 1, 0, 1)
    for k, u in pairs(units.get()) do
        if u.team == 1 and camera.isInView(u.x * tsize, u.y * tsize) and worldmap.map[u.y][u.x].align ~= CONSTS.unexploredTile then
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

    if targeter.getUnit() > -1 then
        for k, stack in pairs(units.get()[targeter.getUnit()].stacks) do
            love.graphics.print(stack.unit.name..' x'..stack.size, ACTIONSTARTX, 284 + k * 16)
        end
    end

    love.graphics.print("Food: "..resources.getFood(), ACTIONSTARTX, 400)
    love.graphics.print("Gold: "..resources.getAvailableGold(), ACTIONSTARTX, 416)
    love.graphics.print("Magic Points: "..spells.getMP(), ACTIONSTARTX, 432)
    love.graphics.print("Lumber: "..resources.getLumber(), ACTIONSTARTX, 448)
    love.graphics.print("Stone: "..resources.getStone(), ACTIONSTARTX, 464)
end

return {
    load = load,
    show = show,
    update = update,
    keypressed = keypressed,
    mousepressed = mousepressed,
    draw = draw
}