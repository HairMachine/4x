local units = require 'modules/units'
local worldmap = require 'modules/worldmap'
local locations = require 'modules/locations'
local resources = require 'modules/resources'
local items = require 'modules/items'
local commands = require 'modules/commands'
local animation = require 'modules/animation'
local spells = require 'modules/spells'
local dark_power = require 'modules/dark_power'
local production = require 'modules/production'
local targeter = require 'modules/targeter'

local rules = {
    
    -- Hero moves on the world map, and reveals unexplored tiles as they go.
    HeroMove = {
        check = function(params)
            return params.unitToMove.moved == 0 and worldmap.map[params.y][params.x].tile ~= "ruins"
        end,
        trigger = function(params)
            units.move(params.unitToMove, params.x, params.y)
            worldmap.explore(params.x, params.y, 2)
        end
    },

    -- Hero explores a location and randomly generates an encounter.
    HeroExploreLocation = {
        check = function(params)
            return params.unitToMove.moved == 0 and worldmap.map[params.y][params.x].tile == "ruins"
        end,
        trigger = function(params)
            local roll = love.math.random(1, 6)
            local result = nil
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
            worldmap.map[params.y][params.x] = worldmap.makeTile("grass", worldmap.map[params.y][params.x].align)
            locations.tileAlignmentChange()
            params.unitToMove.moved = 1
            return result
        end
    },

    -- Tick up the hero's regeneration counter, and regenerate health if it's time to do so
    HeroHealthRegen = {
        check = function()
            return true
        end,
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

    -- Refresh all action points for units.
    ResetUnitMoves = {
        check = function(params)
            return true
        end,
        trigger = function(params)
            for k, e in pairs(units.get()) do
                e.moved = 0
            end
        end
    },

    Build = {
        check = function(params)
            return true
        end,
        trigger = function(params)
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
        end
    },

    -- Settlements grow in population.
    GrowSettlement = {
        check = function(params)
            return true
        end,
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
        check = function(params)
            return true
        end,
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

    -- Tick cooldowns for recalled units in barracks
    CooldownRecalledUnits = {
        check = function(params)
            return true
        end,
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
        check = function()
            return true
        end,
        trigger = function()
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
        end
    },

    -- All units attack buildings or other units
    Fight = {
        check = function(params)
            return true
        end,
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
            commands.new(function(params) 
                locations.remove()
                units.remove()
                return true
            end, {})
        end
    },

    -- Tick down and respawn any units that need to respawn
    RespawnUnits = {
        check = function(params)
            return true
        end,
        trigger = function(params)
            respawning = units.getRespawning()
            for k = #respawning, 1, -1 do
                local i = respawning[k]
                i.timer = i.timer - 1
                if i.timer <= 0 then
                    if units.atPos(i.data.x, i.data.y).name == "None" then
                        units.spawnByLocType(i.data)
                        units.respawned(k)
                    end
                end
            end
            return true
        end
    },

    -- All buildings apply their each-turn effects
    BuildingTurnEffects = {
        check = function()
            return true
        end,
        trigger = function()
            for k, l in pairs(locations.get()) do
                if l.key == "node" then
                    spells.addMP(worldmap.getTileWorkers(l.x, l.y))
                elseif l.key == "tower" then
                    spells.addMP(1)
                elseif l.key == "mine" then
                    resources.spendGold(-worldmap.getTileWorkers(l.x, l.y) * 20)
                end
            end
        end
    },

    -- The Dark Power increases and creates new plots
    DarkPowerActs = {
        check = function()
            return true
        end,
        trigger = function()
            for k, l in pairs(locations.get()) do
                if l.key == "dark_tower" then
                    dark_power.increasePower(5)
                elseif l.key == "dark_temple" then
                    dark_power.increasePower(1)
                end
            end
            local plot = dark_power.getCurrentPlot()
            if dark_power.getPower() >= plot.target then
                if plot.name == "Cave" then
                    locations.add("cave", plot.x, plot.y, 2)
                    units.add("grunter", plot.x, plot.y, {type = "cave", x = plot.x, y = plot.y})
                elseif plot.name == "Dark Temple" then
                    locations.add("dark_temple", plot.x, plot.y, 2)
                elseif plot.name == "Fortress" then
                    locations.add("fortress", plot.x, plot.y, 2)
                    units.add("doom_guard", plot.x, plot.y, {type = "fortress", x = plot.x, y = plot.y})
                end
                dark_power.choosePlot()
            end
        end
    },

    AdvanceSpellResearch = {
        check = function()
            return true
        end,
        trigger = function()
            local researchBonus = 0
            for k, e in pairs(units.get()) do
                if e.type == "sage" then
                    researchBonus = researchBonus + 1
                end
            end
            spells.research(researchBonus)
            if spells.getLearning() == "none" and #spells.researchable > 0 then
                return true
            end
            return false
        end
    },

    TickSpellCooldown = {
        check = function()
            return true
        end,
        trigger = function()
            spells.cooldown()
        end
    },

    -- End game conditions, win or loss
    CheckEndConditions = {
        check = function()
            return true
        end,
        trigger = function()
            if locations.get()[2].hp <= 0 then
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
    }

}

local function check(ruleName, params)
    assert(rules[ruleName] ~= nil, "Tried to check nonexistent rule: "..ruleName)
    assert(rules[ruleName].check ~= nil, "check function not implemented on rule: "..ruleName)
    return rules[ruleName].check(params)
end

local function trigger(ruleName, params)
    assert(rules[ruleName] ~= nil, "Tried to trigger nonexistent rule: "..ruleName)
    assert(rules[ruleName].trigger ~= nil, "trigger function not implemented on rule: "..ruleName)
    if rules[ruleName].check(params) then
        return rules[ruleName].trigger(params)
    end
end

return {
    check = check,
    trigger = trigger
}