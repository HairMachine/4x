local locations = require 'modules/locations'
local ui = require 'modules/ui_manager'
local units = require 'modules/units'
local resources = require 'modules/resources'
local targeter = require 'modules/targeter'
local production = require 'modules/production'

local buttons = {}

local function oldcrap()
    local ctile = locations.getCurrentBuildingTile()
    locations.add(event.loc.key, ctile.x, ctile.y, 1)
    units.spawnByLocType({type = event.loc.key, x = ctile.x, y = ctile.y})
    resources.spendGold(event.loc.cost)
    locations.tileAlignmentChange()
    units.get()[targeter.getUnit()].moved = 1
    targeter.clear()
    ScreenSwitch("map")
end

local function load()
    
end

local function show()
    buttons = {
        ok = {x = 600, y = 500, width = 100, height = 32, text = "OK", visible = 1, action = function(event) 
            ScreenSwitch("map")
        end}
    }
    for k, l in pairs(locations.getAllowedBuildings()) do
        buttons["building_"..l.key] =  {
            x = 0, y = (k-1) * 32, width = 300, height = 32, 
            text = l.name.." (Prd: "..l.production..", Upk: "..l.upkeep..")", 
            visible = 1, loc = l, action = function(event)
                production.beginBuilding({name = l.name, cost = l.production, type = "location", key = l.key})  
            end
        }
    end
end

local function update()
    
end

local function keypressed(key, scancode, isrepeat)
    
end

local function mousepressed(x, y, button, istouch, presses)
    ui.click(buttons, x, y)
end

local function draw()
    ui.draw(buttons)

    love.graphics.print("Current production: "..production.getProductionValue(), 600, 0)
    for k, v in pairs(production.inProgress) do
        love.graphics.print(v.name, 600, (k + 1) * 32)
    end
end

return {
    load = load,
    show = show,
    update = update,
    keypressed = keypressed,
    mousepressed = mousepressed,
    draw = draw
}