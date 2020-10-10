local worldmap = require('modules/worldmap')
local locations = require('modules/locations')

local production = 0

local inProgress = {}

local function setProductionValue()
    production = 100
    for k, l in pairs(locations.get()) do
        -- TODO: Add production values of buildings according to whatever formula
    end
    for yt = 1, worldmap.MAPSIZEY do
        for xt = 1, worldmap.MAPSIZEX do
            production = production + worldmap.map[yt][xt].population * 10
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