local worldmap = require 'modules/worldmap'
local units = require 'modules/units'
local locations = require 'modules/locations'
local targeter = require 'modules/targeter'
local resources = require 'modules/resources'

local mp = 25
local rp = 5
local sp = 5
local learning = "none"
local rpSpent = 0
local casting = "none"
local cpSpent = 0

local data = {
    none = {name = "", key = "", castCost = 0, researchCost = 0, action = function() end},
    lightning_bolt = {name = "Lighting Bolt", key = "lightning_bolt", castCost = 5, researchCost = 100, action = function()
        targeter.setSpellMap(3, true)
        targeter.callback = function(x, y)
            for k, u in pairs(units.get()) do
                if x == u.x and y == u.y then
                    u.hp = u.hp - 10
                end
            end
            units.remove()
            targeter.clear()
        end
    end},
    summon_hero = {name = "Summon Hero", key = "summon_hero", castCost = 30, researchCost = 150, action = function()
        units.add("hero", locations.get()[1].x, locations.get()[1].y, {})
        resources.spendCommandPoints(1)
    end},
    terraform = {name = "Terraform", key = "terraform", castCost = 5, researchCost = 50, action = function()
        targeter.setSpellMap(1, true)
        targeter.callback = function(x, y)
            worldmap.map[y][x] = worldmap.makeTile(grass)
            targeter.clear()
        end
    end}
}

local known = {}

local researchable = {"lightning_bolt", "summon_hero", "terraform"}

local function startLearning(spell) 
    learning = spell
end

local function getLearning()
    return learning
end

local function research(bonus)
    if learning == "none" then
        return
    end
    rpSpent = rpSpent + rp + bonus
    if rpSpent >= data[learning].researchCost then
        rpSpent = rpSpent - data[learning].researchCost
        table.insert(known, learning)
        for k, v in pairs(researchable) do
            if v == learning then
                table.remove(researchable, k)
            end
        end
        learning = "none"
        return true
    end
    return false
end

local function startCasting(spell)
    casting = spell
end

local function getCasting()
    return data[casting]
end

local function cast()
    if casting == "none" then
        return false
    end
    if mp <= 0 then
        return false
    end
    local cost = sp
    mp = mp - sp
    if mp < 0 then
        cost = math.abs(mp)
        mp = mp + cost
    end
    cpSpent = cpSpent + cost
    if cpSpent >= data[casting].castCost then
        cpSpent = 0
        data[casting].action()
        casting = "none"
        return true
    end
    return false
end

local function stopCasting()
    casting = "none"
end

local function getMP()
    return mp
end

local function addMP(amnt)
    mp = mp + amnt
end

return {
    data = data,
    known = known,
    researchable = researchable,
    getLearning = getLearning,
    startLearning = startLearning,
    research = research,
    getCasting = getCasting,
    startCasting = startCasting,
    stopCasting = stopCasting,
    cast = cast,
    getMP = getMP,
    addMP = addMP
}