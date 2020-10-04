local goldUsed = 0
local goldOwned = 100
local commandPoints = 1

local function getAvailableGold()
    return goldOwned - goldUsed
end

local function enoughGold(amnt)
    return amnt + goldUsed <= goldOwned
end

local function spendGold(amnt)
    goldUsed = goldUsed + amnt
    return true
end

local function getCommandPoints()
    return commandPoints
end

local function spendCommandPoints(amnt)
    commandPoints = commandPoints - amnt
end

return {
    getAvailableGold = getAvailableGold,
    enoughGold = enoughGold,
    spendGold = spendGold,
    getCommandPoints = getCommandPoints,
    spendCommandPoints = spendCommandPoints
}

