local ui = require 'modules/ui_manager'
local spells = require 'modules/spells'
local resources = require 'modules/resources'

local buttons = {}

local function load()
    
end

local function show()
    buttons = {
        end_phase = {x = 600, y = 100, width = 100, height = 50, text = "Cancel", visible = 1, action = function(event) 
            ScreenSwitch("map")
        end},
        error_box = {x = 300, y = 200, width = 200, height = 100, text = "", visible = 0, children = {
            error_ok = {x = 350, y = 263, width = 100, height = 32, text = "OK", visible = 1, action = function(event)
                buttons.error_box.visible = 0
            end}
        }}
        
    }
    for k, s in pairs(spells.known) do
        buttons["spell_"..k] = {x = 0, y = (k-1) * 32, width = 300, height = 32, visible = 1, spell = s}
        if not spells.data[s].cooldown then
            buttons["spell_"..k].text = spells.data[s].name
            buttons["spell_"..k].action = function(event)
                if s == "summon_hero" and resources.getCommandPoints() < 1 then
                    buttons.error_box.text = "You need at least one command point available to cast this spell again!"
                    buttons.error_box.visible = 1
                    return
                end
                spells.cast(s)
                ScreenSwitch("map")
            end
        else
            buttons["spell_"..k].text = spells.data[s].name.." ("..spells.data[s].cooldown.." left to recharge)"
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