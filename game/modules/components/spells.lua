local mp = 25
local rp = 5
local sp = 5
local learning = "none"
local rpSpent = 0
local cpSpent = 0

local data = {
    lightning_bolt = {name = "Lighting Bolt", key = "lightning_bolt", castCost = 50, rule = 'CastLightningBolt'},
    summon_hero = {name = "Summon Hero", key = "summon_hero", castCost = 200, rule = 'CastSummonHero'},
    terraform = {name = "Terraform", key = "terraform", castCost = 75, rule = 'CastTerraform'},
    lure = {name = "Lure", key = "lure", castCost = 30, rule = "CastUnimplemented"},
    summon_artefact = {name = "Summon Artefact", key = "summon_artefact", castCost = 500, rule = "CastUnimplemented"},
    sphere_of_annihilation = {name = "Sphere of Annihilation", key = "sphere_of_annihilation", castCost = 85,rule = "CastUnimplemented"},
    dimension_door = {name = "Dimension Door", key = "dimension_door", castCost = 100, rule = "CastUnimplemented"},
    heroism = {name = "Heroism", key = "heroism", castCost = 50, rule = "CastUnimplemented"},
    bloodlust = {name = "Bloolust", key = "bloodlust", castCost = 40, rule = "CastUnimplemented"},
    ravage = {name = "Ravage", key = "ravage", castCost = 100, rule = "CastUnimplemented"},
    natures_bounty = {name = "Nature's Bounty", key = "natures_bounty", castCost = 150, rule = "CastUnimplemented"},
    aura_of_command = {name = "Aura of Command", key = "aura_of_command", castCost = 800, rule = "CastAuraOfCommand"},
    healing = {name = "Healing", key = "healing", castCost = 40, rule = "CastHealing"}
}

local known = {}
local RESEARCHNUM = 3

local researchable = {}

local researchOptions = {}

local function setup()
    for k, s in pairs(data) do
        table.insert(researchable, k)
    end
end

local function chooseResearchOptions()
    if #researchable == 0 then
        return
    end
    while #researchOptions < RESEARCHNUM do
        local roll = love.math.random(1, #researchable)
        table.insert(researchOptions, researchable[roll])
        table.remove(researchable, roll)
    end
end

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
    if rpSpent >= data[learning].castCost * 4 then
        rpSpent = rpSpent - data[learning].castCost * 4
        table.insert(known, learning)
        for k, v in pairs(researchOptions) do
            if v == learning then
                table.remove(researchOptions, k)
            end
        end
        learning = "none"
        chooseResearchOptions()
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
    researchOptions = researchOptions,
    setup = setup,
    chooseResearchOptions = chooseResearchOptions,
    getLearning = getLearning,
    startLearning = startLearning,
    research = research,
    getCasting = getCasting,
    cast = cast,
    getMP = getMP,
    addMP = addMP,
    cooldown = cooldown
}