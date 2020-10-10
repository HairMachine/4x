local ui = require 'modules/ui_manager'
local locations = require 'modules/locations'
local targeter = require 'modules/targeter'
local units = require 'modules/units'

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
                            targeter.setType("spell")
                            targeter.setDeployMap(u.unit)
                            targeter.callback = function(x, y)
                                units.add(u.unit, x, y, {key = l.key, x = l.x, y = l.y})
                                table.remove(l.units, k2)
                                targeter.clear()
                            end
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