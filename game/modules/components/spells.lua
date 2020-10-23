local mp = 5000
local rp = 5
local sp = 200
local learning = "none"
local rpSpent = 0
local cpSpent = 0

local data = {
    lightning_bolt = {name = "Lighting Bolt", key = "lightning_bolt", castCost = 50, rule = 'CastLightningBolt'},
    summon_hero = {name = "Summon Hero", key = "summon_hero", castCost = 200, rule = 'CastSummonHero'},
    terraform = {name = "Terraform", key = "terraform", castCost = 75, rule = 'CastTerraform'},
    lure = {name = "Lure", key = "lure", castCost = 30, rule = "CastLure"},
    summon_artefact = {name = "Summon Artefact", key = "summon_artefact", castCost = 500, rule = "CastSummonArtefact"},
    sphere_of_annihilation = {name = "Sphere of Annihilation", key = "sphere_of_annihilation", castCost = 85,rule = "CastSphereOfAnnihilation"},
    dimension_door = {name = "Dimension Door", key = "dimension_door", castCost = 100, rule = "CastDimensionDoor"},
    heroism = {name = "Heroism", key = "heroism", castCost = 50, rule = "CastHeroism"},
    bloodlust = {name = "Bloolust", key = "bloodlust", castCost = 40, rule = "CastBloolust"},
    ravage = {name = "Ravage", key = "ravage", castCost = 100, rule = "CastRavage"},
    natures_bounty = {name = "Nature's Bounty", key = "natures_bounty", castCost = 150, rule = "CastNaturesBounty"},
    aura_of_command = {name = "Aura of Command", key = "aura_of_command", castCost = 800, rule = "CastAuraOfCommand"},
    healing = {name = "Healing", key = "healing", castCost = 40, rule = "CastHealing"},
    summon_skeleton = {name = "Summon Skeleton", key = "summon_skeleton", castCost = 25, rule = "CastSummonSkeleton"},
    haste = {name = "Haste", key = "haste", castCost = 20, rule = "CastHaste"},
    repair = {name = "Repair", key = "repair", castCost = 20, rule = "CastRepair"},
    totem_of_control = {name = "Totem of Control", key = "totem_of_control", castCost = 300, rule = "CastTotemOfControl"},
    orb_of_destruction = {name = "Orb of Destruction", key = "orb_of_destruction", castCost = 40, rule = "CastOrbOfDestruction"},
    obelisk_of_power = {name = "Obelisk of Power", key = "obelisk_of_power", castCost = 100, rule = "CastObeliskOfPower"}
}

local known = {"obelisk_of_power"}
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