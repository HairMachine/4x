local goldOwned = 1000
local commandPoints = 8
local unitLevel = 0
local food = 1000
local lumber = 0
local stone = 0

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

local function getFood()
    return food
end

local function changeFood(amnt)
    food = math.floor(food + amnt)
    if food < 0 then food = 0 end
end

local function getLumber()
    return lumber
end

local function changeLumber(amnt)
    lumber = math.floor(lumber + amnt)
    if lumber < 0 then lumber = 0 end
end

local function getStone()
    return stone
end

local function changeStone(amnt)
    stone = math.floor(stone + amnt)
    if stone < 0 then stone = 0 end
end

return {
    getAvailableGold = getAvailableGold,
    enoughGold = enoughGold,
    spendGold = spendGold,
    getCommandPoints = getCommandPoints,
    spendCommandPoints = spendCommandPoints,
    getUnitLevel = getUnitLevel,
    changeUnitLevel = changeUnitLevel,
    getFood = getFood,
    changeFood = changeFood,
    getLumber = getLumber,
    changeLumber = changeLumber,
    getStone = getStone,
    changeStone = changeStone
}

