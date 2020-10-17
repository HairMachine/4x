local production = 50

local inProgress = {}

local function setProductionValue(val)
    production = val
end

local function getProductionValue()
    return production
end

local function turnsToBuild(cost)
    return math.floor(cost / production)
end

local function beginBuilding(buildData)
    for k, v in pairs(buildData) do
        inProgress[k] = v
    end
    inProgress.progress = 0
end

local function progressBuilding()
    if not inProgress.name then
        return
    end
    inProgress.progress = inProgress.progress + production
end

local function getFinishedBuilding()
    if not inProgress.name then return end
    if inProgress.progress >= inProgress.cost then
        return inProgress
    end
end

local function removeBuilding()
    inProgress = {}
end

return {
    inProgress = inProgress,
    setProductionValue = setProductionValue,
    getProductionValue = getProductionValue,
    turnsToBuild = turnsToBuild,
    beginBuilding = beginBuilding,
    progressBuilding = progressBuilding,
    getFinishedBuilding = getFinishedBuilding,
    removeBuilding = removeBuilding
}