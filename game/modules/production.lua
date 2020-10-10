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
    buildData.progress = 0
    table.insert(inProgress, buildData)
end

local function progressBuilding()
    if #inProgress == 0 then
        return
    end
    -- Split the production value between the number of things being built
    setProductionValue()
    local pa = math.floor(production / #inProgress)
    for k, v in pairs(inProgress) do
        v.progress = v.progress + pa
    end
end

local function getFinishedBuilding()
    for k, v in pairs(inProgress) do
        if  v.progress >= v.cost then
            return {index = k, data = v}
        end
    end
end

local function removeBuilding(index)
    table.remove(inProgress, index)
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