local mp = 25
local rp = 5
local sp = 5
local learning = "none"
local rpSpent = 0
local cpSpent = 0

local data = {
    none = {name = "", key = "", castCost = 0, researchCost = 0, action = function() end},
    lightning_bolt = {name = "Lighting Bolt", key = "lightning_bolt", castCost = 25, researchCost = 100, rule = 'CastLightningBolt'},
    summon_hero = {name = "Summon Hero", key = "summon_hero", castCost = 200, researchCost = 150, rule = 'CastSummonHero'},
    terraform = {name = "Terraform", key = "terraform", castCost = 15, researchCost = 50, rule = 'CastTerraform'}
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

local function getCasting()
    return data[casting]
end

local function cast(spell)
    if spell == "none" then
        return false
    end
    if mp <= data[spell].castCost then
        return false
    end
    mp = mp - data[spell].castCost
    data[spell].cooldown = data[spell].castCost
    return data[spell].rule
end

local function cooldown()
    for k, v in pairs(data) do
        if v.cooldown then
            v.cooldown = v.cooldown - sp
            if v.cooldown <= 0 then
                v.cooldown = nil
            end
        end
    end
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
    cast = cast,
    getMP = getMP,
    addMP = addMP,
    cooldown = cooldown
}