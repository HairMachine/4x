local ui = require 'modules/services/ui_manager'
local locations = require 'modules/components/locations'
local units = require 'modules/components/units'
local rules = require 'modules/rules/main'

local buttons = {}

local function load()
    
end

local function show()
    buttons = {
        cancel = {x = 600, y = 100, width = 100, height = 50, text = "Cancel", visible = 1, action = function()
            ScreenSwitch("map")
        end}
    }
    local ypos = 0
    for k, l in pairs(locations.get()) do
        if l.maxUnits then
            for k2, u in pairs(l.units) do
                if u.cooldown <= 0 then
                    buttons['unit_'..k..'_'..k2] = {
                        x = 0, y = ypos, width = 300, height = 32, text = units.getData()[u.unit].name, visible = 1, action = function()
                            rules.trigger('DeployUnit', {unit_key = k2, unit = u.unit, loc_key = k, loc = l})
                            ScreenSwitch("map")
                        end
                    }
                    ypos = ypos + 32
                end
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
end

return {
    load = load,
    show = show,
    update = update,
    keypressed = keypressed,
    mousepressed = mousepressed,
    draw = draw
}