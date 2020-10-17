local goldOwned = 1000
local commandPoints = 1
local unitLevel = 0

local function getAvailableGold()
    return goldOwned
end

local function enoughGold(amnt)
    return amnt <= goldOwned
end

local function spendGold(amnt)
    goldOwned = goldOwned - amnt
    return true
end

local function getCommandPoints()
    return commandPoints
end

local function spendCommandPoints(amnt)
    commandPoints = commandPoints - amnt
end

local function getUnitLevel()
    return unitLevel
end

local function changeUnitLevel(amnt)
    unitLevel = unitLevel + amnt
end

return {
    getAvailableGold = getAvailableGold,
    enoughGold = enoughGold,
    spendGold = spendGold,
    getCommandPoints = getCommandPoints,
    spendCommandPoints = spendCommandPoints,
    getUnitLevel = getUnitLevel,
    changeUnitLevel = changeUnitLevel
}

