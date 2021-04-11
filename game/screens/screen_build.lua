local ui = require 'modules/services/ui_manager'
local targeter = require 'modules/services/targeter'
local locations = require 'modules/components/locations'
local units = require 'modules/components/units'
local production = require 'modules/components/production'
local resources = require 'modules/components/resources'
local rules = require 'modules/rules/main'

local buttons = {}

local function _isOk(u)
    return u.upkeep > 0 and resources.getLumber() >= u.lumber and resources.getStone() >= u.stone
end

local function load()
    
end

local function show()
    buttons = {
        cancel = {x = 600, y = 500, width = 100, height = 32, text = "Cancel", visible = 1, action = function(event) 
            ScreenSwitch("map")
        end}
    }
    local i = 0
    for k, u in pairs(units.getData()) do 
        if _isOk(u) then         
            buttons["unit_"..k] = {
                x = 0, y = i * 32, width = 500, height = 32,
                text = u.name.." (Upk: "..u.upkeep..", Lum: "..u.lumber..", Stn: "..u.stone..", Pop: "..u.pop..")",
                visible = 1, unit = u, action = function(event)
                    rules.trigger('Recruit', {hero = units.get()[targeter.getUnit()], type = k, unit = u})
                    ScreenSwitch("map")
                end
            }
            i = i + 1    
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