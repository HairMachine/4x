local ui = require 'modules/ui_manager'
local spells = require 'modules/spells'
local resources = require 'modules/resources'

local errorBox = false
local errorText = ""

local buttons = {}

local function load()
    
end

local function show()
    buttons = {
        end_phase = {x = 600, y = 100, width = 100, height = 50, text = "Cancel", visible = 1, action = function(event) 
            ScreenSwitch("map")
        end},
        error_ok = {x = 350, y = 280, width = 100, height = 40, text = "OK", action = "errorOk", visible = 0, action = function(event)
            errorBox = false
            event.visible = 0
        end}
    }
    for k, s in pairs(spells.known) do
        table.insert(buttons, {x = 0, y = (k-1) * 32, width = 300, height = 32, text = spells.data[s].name, visible = 1, spell = s, action = function(event)
            if s == "summon_hero" and resources.getCommandPoints() < 1 then
                errorBox = true
                errorText = "You need at least one command point available to cast this spell again!"
                buttons.error_ok.visible = 1
                return
            end
            if spells.getCasting().key == s then
                spells.startCasting("none")
            else
                spells.startCasting(s)
            end
            ScreenSwitch("map")
        end})
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

    if errorBox == true then
        love.graphics.rectangle("line", 300, 200, 200, 100)
        love.graphics.print(errorText, 310, 210)
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