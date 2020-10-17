local units = require 'modules/units'
local worldmap = require 'modules/worldmap'
local locations = require 'modules/locations'
local resources = require 'modules/resources'
local items = require 'modules/items'

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
    UpkeepCosts = {
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
    RecalledUnitCooldowns = {
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