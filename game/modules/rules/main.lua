local units = require 'modules/units'
local worldmap = require 'modules/worldmap'
local locations = require 'modules/locations'
local resources = require 'modules/resources'
local items = require 'modules/items'

local rules = {
    
    HeroMove = {
        check = function(params)
            return params.unitToMove.moved == 0 and worldmap.map[params.y][params.x].tile ~= "ruins"
        end,
        trigger = function(params)
            units.move(params.unitToMove, params.x, params.y)
            worldmap.explore(params.x, params.y, 2)
        end
    },

    HeroExplore = {
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