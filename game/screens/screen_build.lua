local locations = require 'modules/locations'
local ui = require 'modules/ui_manager'
local units = require 'modules/units'
local production = require 'modules/production'
local rules = require 'modules/rules/main'

local buttons = {}

local function load()
    
end

local function show()
    buttons = {
        cancel = {x = 600, y = 500, width = 100, height = 32, text = "Cancel", visible = 1, action = function(event) 
            ScreenSwitch("map")
        end}
    }
    for k, l in pairs(locations.getAllowedBuildings()) do
        buttons["building_"..k] =  {
            x = 0, y = (k-1) * 32, width = 300, height = 32, 
            text = l.name.." (Prd: "..l.production..", Upk: "..l.upkeep..")", 
            visible = 1, loc = l, action = function(event)
                rules.trigger('StartBuilding', {name = l.name, cost = l.production, type = "location", key = l.key})
                ScreenSwitch("map")
            end
        }
    end
    if locations.getFreeUnitSlotCount() > 0 then
        local i = 0
        for k, u in pairs(units.getData()) do
            if u.production > 0 then
                buttons["unit_"..k] = {
                    x = 315, y = i * 32, width = 300, height = 32,
                    text = u.name.." (Prd: "..u.production..", Upk: "..u.upkeep..")",
                    visible = 1, unit = u, action = function(event)
                        rules.trigger('StartBuilding', {name = u.name, cost = u.production, type = "unit", key = k})
                        ScreenSwitch("map")
                    end
                }
                i = i + 1
            end
        end
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
end

return {
    load = load,
    show = show,
    update = update,
    keypressed = keypressed,
    mousepressed = mousepressed,
    draw = draw
}