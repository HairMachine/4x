local targeter = require 'modules/services/targeter'
local commands = require 'modules/services/commands'
local animation = require 'modules/services/animation'
local units = require 'modules/components/units'
local worldmap = require 'modules/components/worldmap'
local locations = require 'modules/components/locations'
local resources = require 'modules/components/resources'
local items = require 'modules/components/items'
local spells = require 'modules/components/spells'
local dark_power = require 'modules/components/dark_power'
local production = require 'modules/components/production'
local helper = require 'modules/rules/helper'

local rules = {

    -- Set up the starting board state
    SetupBoard = {
        trigger = function()
            spells.tagResearchable()
            spells.chooseResearchOptions()
             -- Generate map. TODO: Randomly choose a template!
            worldmap.load("testlvl")
        end
    },

    SetupStartingUnits = {
        trigger = function()
            local startxpos = math.floor(worldmap.MAPSIZEX / 2)
            local startypos = math.floor(worldmap.MAPSIZEY / 2)

            -- Starting units
            local h = units.add("hero", startxpos, startypos)
            units.addStack(h, "soldier", 10)
            units.addStack(h, "settlers", 100)
            worldmap.explore(startxpos, startypos, 3)

            -- add a billion enemies!
            local i = 0
            while i < (worldmap.MAPSIZEX + worldmap.MAPSIZEY) * 1.8 do
                local xpos = love.math.random(1, worldmap.MAPSIZEX)
                local ypos = love.math.random(1, worldmap.MAPSIZEY)
                if (xpos < startxpos - 6 or xpos > startxpos + 6 or ypos < startypos - 6 or ypos > startypos + 6) and locations.atPos(xpos, ypos).name == "None" then
                    -- Monster spawn depends on tile. TODO: spawn tables!
                    local loc = worldmap.map[ypos][xpos].tile
                    local unit = ""
                    local newloc = nil
                    if loc == "tundra" or loc == "grass" or loc == "ore" or loc == "crystal" then
                        newloc = locations.add("cave", xpos, ypos, 2)
                        local roll = love.math.random(1, 3)                        
                        if roll == 1 then 
                            unit = "wolf"
                        elseif roll == 2 then
                            unit = "goblin"
                        elseif roll == 3 then
                            unit = "kobold"
                        end
                    elseif loc ~= "water" then
                        newloc = locations.add("fortress", xpos, ypos, 2)
                        local roll = love.math.random(1, 3)
                        if roll == 1 then
                            unit = "spider"
                        elseif roll == 2 then
                            unit = "orc"
                        elseif roll == 3 then
                            unit = "gnoll"
                        end
                    end
                    if unit ~= "" then
                        units.add(unit, xpos, ypos, {type = "cave", x = xpos, y = ypos})
                        newloc.spawner = unit
                    end
                    i = i + 1
                end
            end
        end
    },

    -- Hero moves around the map and explores ruins
    HeroMove = {
        trigger = function(params, resolve)
            targeter.setUnit(params.k)
            targeter.setMap(helper.heroMoveTargets(params.u.x, params.u.y, params.k))
            targeter.callback = function(x, y)
                local result = nil
                local unitToMove = params.u
                if unitToMove.moved == 0 then 
                    -- Adventurers explore ruins
                    if worldmap.map[y][x].tile == "ruins" then
                        local roll = love.math.random(1, 6)
                        if roll <= 3 then
                            local gp = love.math.random(100, 200)
                            resources.spendGold(-gp)
                            result = {title = "Ruins Explored!", body = "Found "..gp.." gold!"}
                        elseif roll <= 6 then
                            items.generate()
                            local dropped = items.getDropped()
                            local itemText = ""
                            for k, i in pairs(dropped) do
                                itemText = itemText.."Found "..i.name.."!"
                                items.addToInventory(i)
                                items.removeFromDropped(k)
                            end
                            result = {title = "Ruins Explored!", body = itemText}
                        end
                        worldmap.map[y][x] = worldmap.makeTile("grass", worldmap.map[y][x].align)
                    end

                    -- Wizards cast spells (this is not real proper code, just to test the feeling)
                    if locations.atPos(x, y).key == "tower" then
                        ScreenSwitch("cast")
                    end

                    -- The leader moves to the location
                    units.move(unitToMove, x, y)
                    worldmap.explore(x, y, 3)
                    unitToMove.moved = 1
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
                resolve(result)
            end
        end
    },

    -- Tick up the hero's regeneration counter, and regenerate health if it's time to do so
    HeroHealthRegen = {
        trigger = function()
            for k, u in pairs(units.get()) do
                if u.class == "Hero" then
                    if u.hp < u.maxHp then
                        if u.regen == nil then
                            u.regen = 0
                        else
                            u.regen = u.regen + 1
                        end
                        if u.regen >= 5 then
                            u.hp = u.hp +  1
                            u.regen = 0
                        end
                    end
                end
            end
        end
    },

    Settle = {
        trigger = function(params)
            local s
            for k, stack in pairs(params.unit.stacks) do
                if stack.unit.type == "settlers" then
                    targeter.setUnit(params.unitKey)
                    targeter.setMap(helper.foundingTargets(params.unit.x, params.unit.y))
                    targeter.callback = function(x, y)
                        if locations.atPos(x, y).key == "hamlet" then
                            worldmap.map[y][x].population = worldmap.map[y][x].population + params.unit.stacks[k].size
                        else
                            locations.add("hamlet", x, y, 1)
                            worldmap.map[y][x].population = params.unit.stacks[k].size
                        end
                        helper.tileAlignmentChange()
                        targeter.clear()
                        table.remove(params.unit.stacks, k)
                    end
                    return
                end
            end
        end
    },

    Recruit = {
        trigger = function(params)
            -- Get the closest city
            local settlements = {}
            for k, v in pairs(locations.get()) do
                if v.key == "hamlet" then
                    table.insert(settlements, v)
                end
            end
            local dist = 10000
            local selected = nil
            for k, s in pairs(settlements) do
                local td = math.abs(s.x - params.hero.x) + math.abs(s.y - params.hero.y)
                if td < dist then 
                    dist = td
                    selected = s
                end
            end
            local til = worldmap.map[selected.y][selected.x]
            if til.population >= params.unit.pop then
                til.population = til.population - params.unit.pop
                resources.changeLumber(-params.unit.lumber)
                resources.changeStone(-params.unit.stone)
                if params.type == "hero" then
                    units.add(params.type, selected.x, selected.y, {})
                else
                    units.addStack(params.hero, params.type, params.unit.pop)
                end
            end
        end
    },

    -- Advance buildings and create a place unit targeter if ready
    Build = {
        trigger = function(params)
            production.progressBuilding()
            local built = production.getFinishedBuilding()
            if built then
                if built.type == "location" then
                    targeter.setMap(helper.buildTargets(built))
                    targeter.callback = function(x, y)
                        local loc = locations.add(built.key, x, y, 1)
                        if loc.key == "academy" then
                            resources.changeUnitLevel(1)
                        end
                        production.removeBuilding()
                        helper.tileAlignmentChange()
                        targeter.clear()
                    end
                else
                    targeter.setMap(helper.buildUnitTargets())
                    targeter.callback = function(x, y)
                        local place = locations.atPos(x, y)
                        table.insert(place.units, {unit = built.key, cooldown = 0})
                        production.removeBuilding()
                        targeter.clear()
                    end
                end
            end
        end
    },

    -- Settlements grow in population.
    GrowSettlement = {
        trigger = function(params)
            -- Reset population to 0 so we have a clean slate
            for y = 1, worldmap.MAPSIZEY do
                for x = 1, worldmap.MAPSIZEX do
                    worldmap.map[y][x].workers = 0
                end
            end
            -- Increase population of towns
            for k, locAt in pairs(locations.get()) do
                local tile = worldmap.map[locAt.y][locAt.x]
                if locAt.class == "settlement" then
                    -- More growth if more food. Needs a proper equation
                    local foodBonus = 500 + math.max(250, math.floor(resources.getFood() / 100))
                    local popGrowth = math.floor(tile.population * (foodBonus / (tile.population *  tile.population)))
                    if popGrowth > 0 and resources.getFood() > popGrowth then
                        tile.population = tile.population + popGrowth
                        -- Cap population if some prerequisites are not met
                        if locAt.supplies.lumber == false and tile.population >= 200 then
                            tile.population = 199
                        elseif locAt.supplies.stone == false and tile.population >= 350 then
                            tile.population = 349
                        end
                        -- Change the settlement level
                        if tile.population >= 500 and locAt.supplies.lumber == true and locAt.supplies.stone == true then
                            locAt.level = 4
                            helper.tileAlignmentChange()
                        elseif tile.population >= 350 and locAt.supplies.lumber == true and locAt.supplies.stone == true then
                            locAt.level = 3
                            locAt.tile = "city"
                            helper.tileAlignmentChange()
                        elseif tile.population >= 200 and locAt.supplies.lumber == true then
                            locAt.level = 2
                            locAt.tile = "tower"
                            helper.tileAlignmentChange()
                        else
                            locAt.level = 1
                            locAt.tile = "city"
                            helper.tileAlignmentChange()
                        end
                    end
                    -- Population spreads out over a certain range so it can do work
                    -- TODO: This spread should be based on the level of the settlement; straightforwardly, we can just add 1 to the radius per level
                    -- attained.
                    for yt = locAt.y - 1, locAt.y + 1 do
                        for xt = locAt.x - 1, locAt.x + 1 do
                            if yt > 0 and yt <= worldmap.MAPSIZEY and xt > 0 and xt <= worldmap.MAPSIZEX and not(xt == locAt.x and yt == locAt.y) then
                                -- The layer is the smallest of y or x - position abs
                                worldmap.map[yt][xt].workers = math.floor(tile.population / 20)
                            end
                        end
                    end
                end
            end
        end
    },

    -- Unit and location upkeep costs per turn
    PayUpkeepCosts = {
        trigger = function(params)
            for k, u in pairs(units.get()) do
                if u.team == CONSTS.playerTeam then
                    resources.spendGold(u.upkeep)
                    -- TODO: Some creatures don't eat food; others eat a lot more than one unit per stack!
                    if u.stacks and #u.stacks > 0 then
                        for k2, s in pairs(u.stacks) do
                            -- Starvation!
                            if resources.getFood() <= 0 then
                                s.size = s.size - love.math.random(10, 20)
                            else
                                resources.changeFood(-s.size)
                            end
                            if s.size <= 0 then
                                table.remove(u.stacks, k2)
                            end
                        end
                    end
                end
            end
            for k, l in pairs(locations.get()) do
                if l.team == CONSTS.playerTeam then
                    resources.spendGold(l.upkeep)
                    local pop = worldmap.map[l.y][l.x].population
                    resources.changeLumber(-(l.level - 1) * 10)
                    resources.changeStone(-(l.level - 1) * 5)
                    if resources.getLumber() > 0 then
                        l.supplies.lumber = true
                    else
                        l.supplies.lumber = false
                    end
                    if resources.getStone() > 0 then
                        l.supplies.stone = true
                    else
                        l.supplies.stone = false
                    end
                    -- Starvation!
                    if resources.getFood() <= 0 then
                        worldmap.map[l.y][l.x].population = pop - math.ceil(pop / 20)
                    else
                        resources.changeFood(-pop)
                    end
                end
            end
        end
    },

    MoveAiUnits = {
        trigger = function()
            for k, e in pairs(units.get()) do
                local target = {name = "None"}
                if e.class == "Sieger" then
                    local mindist = 9001
                    for k, u in pairs(locations.get()) do
                        if u.team ~= e.team then
                            if math.abs(u.x - e.x) <= e.range and math.abs(u.y - e.y) <= e.range then
                                local tdist = units.getDistBetween(e.x, e.y, u.x, u.y)
                                if tdist < mindist then
                                    mindist = tdist
                                    target = u
                                end
                            end
                        end
                    end
                elseif e.class == "Skirmisher" or e.class == "Defender" then
                    local mindist = 9001
                    for k, u in pairs(units.get()) do
                        if u.team ~= e.team then
                            if math.abs(u.x - e.x) <= e.range and math.abs(u.y - e.y) <= e.range then
                                local tdist = units.getDistBetween(e.x, e.y, u.x, u.y)
                                if tdist < mindist then
                                    mindist = tdist
                                    target = u
                                end
                            end
                        end
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
        end
    },

    -- All units attack buildings or other units
    Fight = {
        trigger = function(params)
            for k, atk in pairs(units.get()) do
                local siegelist = {}
                for k2, def in pairs(locations.get()) do
                    if def.team ~= atk.team and def.x >= atk.x - 1 and def.x <= atk.x + 1 and def.y >= atk.y - 1 and def.y <= atk.y + 1 then
                        table.insert(siegelist, def)
                    end
                end
                -- TODO: Generate attack rating
                local atkValue = atk.attack
                if atk.stacks and #atk.stacks > 0 then
                    for k, stack in pairs(atk.stacks) do
                        atkValue = atkValue + stack.unit.attack * stack.size
                    end
                end
                if #siegelist > 0 then
                    local sieged = siegelist[love.math.random(1, #siegelist)]
                    local bonus = items.getEffects(atk.items, "demolishing")
                    sieged.hp = sieged.hp - (atk.attack + bonus)
                    commands.new(function(params)
                        if params.started == false then
                            units.setAttackAnimation(params.unit, params.x, params.y)
                            params.started = true
                        end
                        if animation.get(params.unit.animation) == nil then
                            units.setIdleAnimation(params.unit)
                            return true
                        end
                        return false
                    end, {unit = atk, started = false, x = sieged.x, y = sieged.y})
                else
                    local atklist = {}
                    for k2, def in pairs(units.get()) do
                        if def.team ~= atk.team and def.x >= atk.x - 1 and def.x <= atk.x + 1 and def.y >= atk.y - 1 and def.y <= atk.y + 1 then
                            table.insert(atklist, def)
                        end
                    end
                    if #atklist > 0 then
                        local attacked = atklist[love.math.random(1, #atklist)]
                        local damage = (atkValue + items.getEffects(atk.items, "slaying")) - items.getEffects(attacked.items, "defence")
                        if damage < 0 then damage = 0 end
                        -- Split damage amongst the stacks
                        if attacked.stacks and #attacked.stacks > 0 then
                            -- Figure out the total HP of the stacks
                            local totalhp = units.stackHp(attacked)
                            for k, stack in pairs(attacked.stacks) do
                                local hpshare = stack.unit.maxHp * stack.size
                                local dmgshare = math.floor(damage * hpshare / totalhp)
                                -- We loop until either the number killed is equal to the size of the whole stack, or there isn't enough damage
                                -- left to kill another unit in the stack
                                local killed = 0
                                while dmgshare >= stack.unit.hp and killed < stack.size do
                                    dmgshare = dmgshare - stack.unit.hp
                                    stack.unit.hp = stack.unit.maxHp
                                    killed = killed + 1
                                end
                                -- If the number killed is the same as the stack size, do the remaining damage to the leader and empty the stack.
                                -- Otherwise, remove the killed units from the stack and reduce the unit's hp by the overflow damage.
                                if killed == stack.size then
                                    attacked.stacks = {}
                                    attacked.hp = attacked.hp - dmgshare
                                else
                                    stack.unit.hp = stack.unit.hp - dmgshare
                                    stack.size = stack.size - killed
                                end
                            end
                        else
                            attacked.hp = attacked.hp - atkValue
                        end
                        commands.new(function(params)
                            if params.started == false then
                                units.setAttackAnimation(params.unit, params.x, params.y)
                                params.started = true
                            end
                            if animation.get(params.unit.animation) == nil then
                                units.setIdleAnimation(params.unit)
                                return true
                            end
                            return false
                        end, {unit = atk, started = false, x = attacked.x, y = attacked.y})
                        -- TODO: Apply any special attacking effects that this unit might have
                        if attacked.hp <= 0 and (atk.class == "Skirmisher" or atk.class == "Hero") then
                            if love.math.random(1, 3) == 3 then
                                items.generate()
                            end
                        end
                    end
                end
            end
            -- Remove all the dead units and locations after a fight
            for i = #locations.get(), 1, -1 do
                if locations.get()[i].hp <= 0 then
                    locations.remove(i)
                    -- TODO: Add some kind of explosion animation
                end
            end
            units.remove()
        end
    },

    -- Tick down and respawn any units that need to respawn
    RespawnUnits = {
        trigger = function(params)
            respawning = units.getRespawning()
            for k = #respawning, 1, -1 do
                local i = respawning[k]
                i.timer = i.timer - 1
                if i.timer <= 0 then
                    if units.atPos(i.data.x, i.data.y).name == "None" then
                        local parent = i.data
                        for k, l in pairs(locations.get()) do
                            if l.key == parent.type and l.x == parent.x and l.y == parent.y then
                                units.add(l.spawner, parent.x, parent.y, parent)                                
                            end
                        end
                        units.respawned(k)
                    end
                end
            end
            return true
        end
    },

    -- Start building
    StartBuilding = {
        trigger = function(params)
            production.beginBuilding(params)
        end
    },

    -- Equipped items generate their stuff
    ItemTurnEffects = {
        trigger = function()
            for k, u in pairs(units.get()) do
                if u.type == 'hero' then
                    for k2, i in pairs(u.slots) do
                        if i.effects then
                            if i.effects.increaseMana then
                                spells.addMP(i.effects.increaseMana)
                            end
                        end
                    end
                end
            end      
        end
    },

    -- All buildings apply their each-turn effects
    BuildingTurnEffects = {
        trigger = function()
            -- TODO: Maybe find a better place for this; passive MP regen
            spells.addMP(5)
            spells.clearNodes()
            for k, l in pairs(locations.get()) do
                if l.class == "settlement" then
                    for yt = l.y - l.level, l.y + l.level do
                        for xt = l.x - l.level, l.x + l.level do
                            if yt > 0 and yt <= worldmap.MAPSIZEY and xt > 0 and xt <= worldmap.MAPSIZEX then 
                                local t = worldmap.map[yt][xt]
                                -- Tiles generate food based on abundance
                                resources.changeFood(t.workers * t.abundance * 5)
                                -- Specific resource tile effects
                                if t.tile == "crystal" then
                                    spells.addMP(t.workers)
                                elseif t.tile == "ore" then
                                    resources.spendGold(-t.workers * 8)
                                elseif t.tile == "forest" then
                                    resources.changeLumber(t.workers)
                                elseif t.tile == "mountain" then
                                    resources.changeStone(t.workers)                      
                                elseif t.tile == "warp_node" then
                                    spells.nodes.warp = spells.nodes.warp + 1
                                elseif t.tile == "life_node" then
                                    spells.nodes.life = spells.nodes.life + 1
                                    spells.tagResearchable()
                                elseif t.tile == "sorcery_node" then
                                    spells.nodes.sorcery = spells.nodes.sorcery + 1
                                    spells.tagResearchable()
                                elseif t.tile == "death_node" then
                                    spells.nodes.death = spells.nodes.death + 1
                                    spells.tagResearchable()
                                elseif t.tile == "chaos_node" then
                                    spells.nodes.chaos = spells.nodes.chaos + 1
                                    spells.tagResearchable()
                                end                           
                            end
                        end
                    end
                end
            end
        end
    },

    -- The Dark Power increases and creates fiendish new plots!
    DarkPowerActs = {
        trigger = function()
            dark_power.increasePower(5)
            for k, l in pairs(locations.get()) do
               if l.key == "dark_temple" then
                    dark_power.increasePower(1)
                end
            end
            
            if dark_power.getPower() >= dark_power.plot.target then
                if dark_power.plot.name == "Cave" then
                    --locations.add("cave", dark_power.plot.x, dark_power.plot.y, 2)
                    --units.add("grunter", dark_power.plot.x, dark_power.plot.y, {type = "cave", x = dark_power.plot.x, y = dark_power.plot.y})
                elseif dark_power.plot.name == "Dark Temple" then
                    --locations.add("dark_temple", dark_power.plot.x, dark_power.plot.y, 2)
                elseif dark_power.plot.name == "Fortress" then
                    --locations.add("fortress", dark_power.plot.x, dark_power.plot.y, 2)
                    --units.add("doom_guard", dark_power.plot.x, dark_power.plot.y, {type = "fortress", x = dark_power.plot.x, y = dark_power.plot.y})
                end
                dark_power.resetPlot()
                -- Select a new plot
                local r = love.math.random(1, 100)
                if r < 50 then
                    dark_power.plot.name = "Cave"
                    dark_power.plot.target = 20
                elseif r < 80 then
                    dark_power.plot.name = "Dark Temple"
                    dark_power.plot.target = 25
                else
                    dark_power.plot.name = "Fortress"
                    dark_power.plot.target = 20
                end
                -- Get allowed cave positions
                local caveLocs = {}
                for y = 1, worldmap.MAPSIZEY do
                    for x = 1, worldmap.MAPSIZEX do
                        if worldmap.map[y][x].align ~= CONSTS.lightTile and locations.atPos(x, y).name == "None" then
                            table.insert(caveLocs, {x = x, y = y})
                        end
                    end
                end
                if #caveLocs > 0 then
                    -- Chose a random one
                    local loc = caveLocs[love.math.random(1, #caveLocs)]
                    dark_power.plot.x = loc.x
                    dark_power.plot.y = loc.y
                end
            end
        end
    },

    StartSpellResearch = {
        trigger = function(params)
            spells.startLearning(params.spell)
        end
    },

    AdvanceSpellResearch = {
        trigger = function()
            spells.research(0)
            if spells.getLearning() == "none" and #spells.researchOptions > 0 then
                return true
            end
            return false
        end
    },

    TickSpellCooldown = {
        trigger = function()
            spells.cooldown()
        end
    },

    CastLightningBolt = {
        trigger = function()
            targeter.setUnit(-1)
            targeter.setMap(helper.enemyUnitTargets())
            targeter.callback = function(x, y)
                for k, u in pairs(units.get()) do
                    if x == u.x and y == u.y then
                        u.hp = u.hp - 10
                    end
                end
                units.remove()
                targeter.clear()
            end
        end
    },

    CastTerraform = {
        trigger = function()
            targeter.setUnit(-1)
            targeter.setMap(helper.visibleTileTargets())
            targeter.callback = function(x, y)
                local food = worldmap.map[y][x].food
                local pop = worldmap.map[y][x].population
                local workers = worldmap.map[y][x].workers
                worldmap.map[y][x] = worldmap.makeTile("grass", worldmap.map[y][x].align)
                worldmap.map[y][x].food = food
                worldmap.map[y][x].population = pop
                worldmap.map[y][x].workers = workers
                targeter.clear()
            end
        end
    },

    CastHealing = {
        trigger = function()
            targeter.setUnit(-1)
            targeter.setMap(helper.friendlyUnitTargets())
            targeter.callback = function(x, y)
                local u = units.atPos(x, y)
                u.hp = u.maxHp
                targeter.clear()
            end
        end
    },

    CastLure = {
        trigger = function()
            targeter.setUnit(-1)
            targeter.setMap(helper.visibleTileTargets())
            targeter.callback = function(x, y)
                units.add("lure", x, y, {})
                targeter.clear()
            end
        end
    },

    CastSphereOfAnnihilation = {
        trigger = function()
            targeter.setUnit(-1)
            targeter.setMap(helper.visibleTileTargets())
            targeter.callback = function(x, y)
                units.add("sphere_of_annihilation", x, y, {})
                targeter.clear()
            end
        end
    },

    CastDimensionDoor = {
        trigger = function()
            targeter.setUnit(-1)
            targeter.setMap(helper.friendlyUnitTargets())
            targeter.callback = function(x, y)
                local unit = units.atPos(x, y)
                targeter.clear()
                targeter.setMap(helper.visibleTileTargets())
                targeter.callback = function(x, y)
                    units.move(unit, x, y)
                    targeter.clear()
                end
            end
        end
    },

    CastHeroism = {
        trigger = function()
            targeter.setUnit(-1)
            targeter.setMap(helper.friendlyUnitTargets())
            targeter.callback = function(x, y)
                local unit = units.atPos(x, y)
                if not unit.heroism then
                    unit.attack = unit.attack + 5
                end
                unit.heroism = true
                targeter.clear()
            end
        end
    },

    CastSummonSkeleton = {
        trigger = function()
            targeter.setUnit(-1)
            targeter.setMap(helper.friendlyUnitTargets())
            targeter.callback = function(x, y)
                units.addStack(units.atPos(x, y), "skeleton", 10)
                targeter.clear()
            end
        end
    },

    CastHaste = {
        trigger = function()
            targeter.setUnit(-1)
            targeter.setMap(helper.friendlyUnitTargets(true))
            targeter.callback = function(x, y)
                local unit = units.atPos(x, y)
                unit.range = unit.range * 2
                targeter.clear()
            end
        end
    },

    CastRepair = {
        trigger = function()
            targeter.setUnit(-1)
            targeter.setMap(helper.friendlyLocationTargets())
            targeter.callback = function(x, y)
                local loc = locations.atPos(x, y)
                loc.hp = loc.maxHp
                targeter.clear()
            end
        end
    },

    CastOrbOfDestruction = {
        trigger = function()
            targeter.setUnit(-1)
            targeter.setMap(helper.visibleTileTargets())
            targeter.callback = function(x, y)
                units.add("orb_of_destruction", x, y, {})
                targeter.clear()
            end
        end
    },

    CastObeliskOfPower = {
        trigger = function()
            targeter.setUnit(-1)
            targeter.setMap(helper.visibleTileTargets())
            targeter.callback = function(x, y)
                units.add("obelisk_of_power", x, y, {})
                targeter.clear()
            end
        end
    },

    -- End game conditions, win or loss
    CheckEndConditions = {
        trigger = function()
            local herocount = 0
            for k, u in pairs(units.get()) do
                if u.class == "Hero" then herocount = herocount + 1 end
            end
            if herocount == 0 then
                return "lose"
            end
            return "continue"
        end
    },

    -- Equip an item
    EquipItem = {
        trigger = function(params)
            if units.get()[params.currentHero].slots[params.item.slot].name ~= "" then
                items.addToInventory(params.item)
            end
            units.get()[params.currentHero].slots[params.item.slot] = params.item
            items.removeFromInventory(params.key)
        end
    }

}

local function check(ruleName, params)
    assert(rules[ruleName] ~= nil, "Tried to check nonexistent rule: "..ruleName)
    if rules[ruleName].check == nil then
        return true
    end
    return rules[ruleName].check(params)
end

local function trigger(ruleName, params, resolve)
    assert(rules[ruleName] ~= nil, "Tried to trigger nonexistent rule: "..ruleName)
    assert(rules[ruleName].trigger ~= nil, "trigger function not implemented on rule: "..ruleName)
    if check(ruleName, params) then
        return rules[ruleName].trigger(params, resolve)
    end
end

return {
    check = check,
    trigger = trigger
}