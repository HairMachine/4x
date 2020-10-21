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
            spells.setup()
            spells.chooseResearchOptions()
             -- Generate map
            worldmap.generate()
            -- Wizard's tower always first
            locations.add("tower", math.floor(worldmap.MAPSIZEX / 2), math.floor(worldmap.MAPSIZEY / 2), 1)
        end
    },

    SetupStartingUnits = {
        trigger = function()
            local startxpos = math.floor(worldmap.MAPSIZEX / 2)
            local startypos = math.floor(worldmap.MAPSIZEY / 2)

            -- Starting units
            units.add("hero", startxpos, startypos)
            worldmap.explore(startxpos, startypos, 2)

            -- add a billion enemies
            local i = 0
            while i < 50 do
                local xpos = love.math.random(1, worldmap.MAPSIZEX)
                local ypos = love.math.random(1, worldmap.MAPSIZEY)
                if xpos < startxpos - 6 or xpos > startxpos + 6 then
                    local roll = love.math.random(1, 3)
                    if roll <= 2 then
                        locations.add("cave", xpos, ypos, 2)
                        units.add("grunter", xpos, ypos, {type = "cave", x = xpos, y = ypos})
                    else
                        locations.add("fortress", xpos, ypos, 2)
                        units.add("doom_guard", xpos, ypos, {type = "fortress", x = xpos, y = ypos})
                    end
                    i = i + 1
                end
            end
        end
    },

    -- Set tile alignments based on the territory you have occupied!
    TileAlignmentChange = {
        trigger = function()
            helper.tileAlignmentChange()
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
                if unitToMove.moved == 0 and worldmap.map[y][x].tile == "ruins" then
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
                    unitToMove.moved = 1
                elseif unitToMove.moved == 0 and worldmap.map[y][x].tile ~= "ruins" then
                    units.move(unitToMove, x, y)
                    worldmap.explore(x, y, 2)
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

    FoundCity = {
        trigger = function(params)
            targeter.setUnit(params.unitKey)
            targeter.setMap(helper.foundingTargets(params.unit.x, params.unit.y))
            targeter.callback = function(x, y)
                locations.add("hamlet", x, y, 1)
                locations.tileAlignmentChange()
                targeter.clear()
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
                        if loc.key == "farm" then
                            for y = loc.y - 1, loc.y + 1 do
                                for x = loc.x - 1, loc.x + 1 do
                                    if worldmap.map[y] and worldmap.map[y][x] then
                                        worldmap.map[y][x].food = worldmap.map[y][x].food + worldmap.map[loc.y][loc.x].abundance
                                    end
                                end
                            end
                        elseif loc.key == "academy" then
                            resources.changeUnitLevel(1)
                        end
                        production.removeBuilding()
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
            -- Find all the housing and apply its population effets
            for k, locAt in pairs(locations.get()) do
                local tile = worldmap.map[locAt.y][locAt.x]
                if locAt.class == "housing" then
                    if tile.food and tile.food >= 1 then
                        tile.food = tile.food - 1
                        tile.population = tile.population + 1
                        -- Change the tile! TODO: 3 separate states - huts for < 5, nice houses for < 10, tower blocks for > 10
                        if locAt.tile == "city" and tile.population >= 5 then
                            locAt.tile = "tower" -- uh... new tile needed!
                        elseif locAt.tile == "tower" and tile.population < 5 then
                            locAt.tile = "city"
                        end
                    end
                    -- Population spreads out over a certain range so it can do work
                    -- Within a certain range of this settlement, population decreases by 1 each tile.
                    -- So if locAt.population == 1, there is no spread. If locAt.population == 2, all surrounding tiles have pop 1.
                    -- If locAt.population == 3, all tiles surrounding have population 1, and all tiles around them have population 1. And so on.
                    local range = 2
                    for yt = locAt.y - range, locAt.y + range do
                        for xt = locAt.x - range, locAt.x + range do
                            if yt > 0 and yt <= worldmap.MAPSIZEY and xt > 0 and xt <= worldmap.MAPSIZEX then
                                if locations.atPos(xt, yt).class ~= "housing" then
                                    local workersToAdd = tile.population - math.max(math.abs(yt - locAt.y), math.abs(xt - locAt.x))
                                    worldmap.map[yt][xt].workers = worldmap.map[yt][xt].workers + workersToAdd
                                end
                            end
                        end
                    end
                end
            end
            -- Set population values transmitted by roads
            local changed = true
            while changed == true do
                changed = false
                for k, l in pairs(locations.get()) do
                    if l.class == "road" then
                        local highestPop = worldmap.map[l.y][l.x].workers
                        for y2 = l.y-1, l.y+1 do
                            for x2 = l.x-1, l.x+1 do
                                if y2 > 0 and y2 <= worldmap.MAPSIZEY and x2 > 0 and x2 <= worldmap.MAPSIZEX then
                                    if worldmap.map[y2][x2].workers > highestPop then
                                        highestPop = worldmap.map[y2][x2].workers
                                    end
                                end
                            end
                        end
                        for y3 = l.y-1, l.y+1 do
                            for x3 = l.x-1, l.x+1 do
                                if y3 > 0 and y3 <= worldmap.MAPSIZEY and x3 > 0 and x3 <= worldmap.MAPSIZEX then
                                    if highestPop > worldmap.map[y3][x3].workers + 1 then
                                        worldmap.map[y3][x3].workers = highestPop - 1
                                        changed = true
                                    end
                                end
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
            for k, l in pairs(locations.get()) do
                if l.team == CONSTS.playerTeam then
                    resources.spendGold(l.upkeep)
                    if l.maxUnits then
                        for k2, u in pairs(l.units) do
                            resources.spendGold(math.floor(units.getData()[u.unit].upkeep / 2))
                        end
                    end
                end
            end
            for k, u in pairs(units.get()) do
                if u.team == CONSTS.playerTeam then
                    resources.spendGold(u.upkeep)
                end
            end
        end
    },

    -- Deploy a unit within range of a barracks
    DeployUnit = {
        trigger = function(params)
            targeter.setUnit(-1)
            targeter.setMap(helper.deployTargets(params.unit))
            targeter.callback = function(x, y)
                local newunit = units.add(params.unit, x, y, {key = params.loc_key, x = params.loc.x, y = params.loc.y})
                -- Set level modifiers
                newunit.attack = newunit.attack + resources.getUnitLevel()
                newunit.hp = newunit.hp + resources.getUnitLevel() * 2
                newunit.maxHp = newunit.hp
                table.remove(params.loc.units, params.unit_key)
                targeter.clear()
            end
        end
    },

    RecallUnits = {
        trigger = function(params)
            targeter.setMap(helper.recallTargets())
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
        end
    },

    -- Tick cooldowns for recalled units in barracks
    CooldownRecalledUnits = {
        trigger = function(params)
            for k, l in pairs(locations.get()) do
                if l.maxUnits then
                    for k2, u in pairs(l.units) do
                        if u.cooldown > 0 then
                            u.cooldown = u.cooldown - 1
                        end
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
                        local damage = (atk.attack + items.getEffects(atk.items, "slaying")) - items.getEffects(attacked.items, "defence")
                        if damage < 0 then damage = 0 end
                        attacked.hp = attacked.hp - damage
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
                    if locations.get()[i].key == "hq" then
                        resources.spendCommandPoints(1)
                    elseif locations.get()[i].key == "academy" then
                        resources.changeUnitLevel(-1)
                    end
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
                                if parent.type == "cave" then
                                    units.add("grunter", parent.x, parent.y, parent)
                                elseif parent.type == "fortress" then
                                    units.add("doom_guard", parent.x, parent.y, parent)
                                end
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

    -- All buildings apply their each-turn effects
    BuildingTurnEffects = {
        trigger = function()
            local prodVal = 50
            for k, l in pairs(locations.get()) do
                if l.key == "node" then
                    spells.addMP(worldmap.getTileWorkers(l.x, l.y))
                elseif l.key == "tower" then
                    spells.addMP(1)
                elseif l.key == "mine" then
                    resources.spendGold(-worldmap.getTileWorkers(l.x, l.y) * 20)
                elseif l.key == "factory" then
                    prodVal = prodVal + worldmap.getTileWorkers(l.x, l.y) * 10
                end
            end
            production.setProductionValue(prodVal)
        end
    },

    -- The Dark Power increases and creates fiendish new plots!
    DarkPowerActs = {
        trigger = function()
            -- temp (?) disabled

            --[[dark_power.increasePower(5)
            for k, l in pairs(locations.get()) do
               if l.key == "dark_temple" then
                    dark_power.increasePower(1)
                end
            end

            if dark_power.getPower() >= dark_power.plot.target then
                if dark_power.plot.name == "Cave" then
                    locations.add("cave", dark_power.plot.x, dark_power.plot.y, 2)
                    units.add("grunter", dark_power.plot.x, dark_power.plot.y, {type = "cave", x = dark_power.plot.x, y = dark_power.plot.y})
                elseif dark_power.plot.name == "Dark Temple" then
                    locations.add("dark_temple", dark_power.plot.x, dark_power.plot.y, 2)
                elseif dark_power.plot.name == "Fortress" then
                    locations.add("fortress", dark_power.plot.x, dark_power.plot.y, 2)
                    units.add("doom_guard", dark_power.plot.x, dark_power.plot.y, {type = "fortress", x = dark_power.plot.x, y = dark_power.plot.y})
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
            end]]
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

    CastUnimplemented = {
        trigger = function()
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

    CastSummonHero = {
        trigger = function()
            if resources.getCommandPoints() < 1 then
                return "You need at least one command point available to cast this spell again!" 
            end
            targeter.setUnit(-1)
            targeter.setMap(helper.visibleTileTargets())
            units.add("hero", locations.get()[1].x, locations.get()[1].y, {})
            resources.spendCommandPoints(1)
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

    CastAuraOfCommand = {
        trigger = function()
            resources.spendCommandPoints(-1)
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
            targeter.setMap(helper.visibleTileTargets())
            targeter.callback = function(x, y)
                units.add("skeleton", x, y, {})
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

    CastTotemOfControl = {
        trigger = function()
            targeter.setUnit(-1)
            targeter.setMap(helper.visibleTileTargets())
            targeter.callback = function(x, y)
                locations.add("totem_of_control", x, y, CONSTS.playerTeam)
                helper.tileAlignmentChange()
                targeter.clear()
            end
        end
    },

    -- End game conditions, win or loss
    CheckEndConditions = {
        trigger = function()
            local tally = 0
            for y = 1, worldmap.MAPSIZEY do
                for x  = 1, worldmap.MAPSIZEX do
                    if worldmap.map[y][x].align == CONSTS.lightTile then
                        tally = tally + 1
                    end
                end
            end
            if tally >= 80 then
                return "win"
            end
            if locations.get()[1].hp <= 0 then
                return "lose"
            end
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