local mp = 0
local rp = 5
local sp = 200
local learning = "none"
local rpSpent = 0
local cpSpent = 0
local nodes = {
    warp = 0,
    life = 0,
    sorcery = 0,
    death = 0,
    chaos = 0
}

local data = {
    lightning_bolt = {name = "Lighting Bolt", key = "lightning_bolt", castCost = 500, rule = 'CastLightningBolt', school = "chaos", level = 2},
    terraform = {name = "Terraform", key = "terraform", castCost = 750, rule = 'CastTerraform', school = "life", level = 1},
    lure = {name = "Lure", key = "lure", castCost = 300, rule = "CastLure", school = "sorcery", level = 0},
    sphere_of_annihilation = {name = "Sphere of Annihilation", key = "sphere_of_annihilation", castCost = 850,rule = "CastSphereOfAnnihilation", school = "warp", level = 1},
    dimension_door = {name = "Dimension Door", key = "dimension_door", castCost = 1000, rule = "CastDimensionDoor", school = "warp", level = 2},
    heroism = {name = "Heroism", key = "heroism", castCost = 500, rule = "CastHeroism", school = "life", level = 1},
    healing = {name = "Healing", key = "healing", castCost = 400, rule = "CastHealing", school = "life", level = 0},
    summon_skeleton = {name = "Summon Skeleton", key = "summon_skeleton", castCost = 250, rule = "CastSummonSkeleton", school = "death", level = 0},
    haste = {name = "Haste", key = "haste", castCost = 200, rule = "CastHaste", school = "sorcery", level = 1},
    orb_of_destruction = {name = "Orb of Destruction", key = "orb_of_destruction", castCost = 400, rule = "CastOrbOfDestruction", school = "chaos", level = 1},
    obelisk_of_power = {name = "Obelisk of Power", key = "obelisk_of_power", castCost = 1000, rule = "CastObeliskOfPower", school = "sorcery", level = 2}
}

local known = {}
local RESEARCHNUM = 6

local researchable = {}

local researchOptions = {}

local function tagResearchable()
    for k, s in pairs(data) do
        if not s.used then
            if (nodes[s.school] >= s.level) then
                table.insert(researchable, k)
                s.used = true
            end
        end
    end
end

local function chooseResearchOptions()
    if #researchable == 0 then
        return
    end
    while #researchable > 0 and #researchOptions < RESEARCHNUM do
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
    if rpSpent >= data[learning].castCost / 2 then
        rpSpent = rpSpent - data[learning].castCost / 2
        table.insert(known, learning)
        for k, v in pairs(researchOptions) do
            if v == learning then
                table.remove(researchOptions, k)
            end
        end
        learning = "none"
        tagResearchable()
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

local function clearNodes()
    nodes.warp = 0
    nodes.life = 0
    nodes.sorcery = 0
    nodes.death = 0
    nodes.chaos = 0
end

return {
    data = data,
    known = known,
    researchOptions = researchOptions,
    tagResearchable = tagResearchable,
    chooseResearchOptions = chooseResearchOptions,
    getLearning = getLearning,
    startLearning = startLearning,
    research = research,
    getCasting = getCasting,
    cast = cast,
    getMP = getMP,
    addMP = addMP,
    cooldown = cooldown,
    clearNodes = clearNodes,
    nodes = nodes
}