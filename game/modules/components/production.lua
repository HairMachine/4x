local worldmap = require('modules/components/worldmap')
local locations = require('modules/components/locations')

local production = 0

local inProgress = {}

local function setProductionValue()
    production = 50
    for k, l in pairs(locations.get()) do
        -- TODO: Add production values of buildings according to whatever formula
        if l.key == "factory" then
            production = production + worldmap.getTileWorkers(l.x, l.y) * 10
        end
    end
end

local function getProductionValue()
    setProductionValue()
    return production
end

local function turnsToBuild(cost)
    setProductionValue()
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
    -- Split the production value between the number of things being built
    setProductionValue()
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