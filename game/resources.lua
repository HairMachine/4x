local goldUsed = 0
local goldOwned = 2

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

return {
    getAvailableGold = getAvailableGold,
    enoughGold = enoughGold,
    spendGold = spendGold
}

