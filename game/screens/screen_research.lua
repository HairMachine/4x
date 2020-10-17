local ui = require 'modules/ui_manager'
local spells = require 'modules/spells'
local rules = require 'modules/rules/main'

local buttons = {}

local function load()
    
end

local function show()
    buttons = {
        end_phase = {x = 600, y = 100, width = 100, height = 50, text = "OK", visible = 0, action = function()
            ScreenSwitch("map")
        end}
    }
    for k, s in pairs(spells.researchable) do
        local spellBtn = {
            x = 0, y = (k - 1) * 32, width = 300, height = 32, text = spells.data[s].name, spell = s, visible = 1, action = function(event)
                rules.trigger('StartSpellResearch', {spell: event.spell})
                for k, b in pairs(buttons) do
                    if b.spell then
                        b.text = spells.data[b.spell].name
                    end
                end
                event.text = "Currently learning "..event.text
                buttons["end_phase"].visible = 1 
            end
        }
        if spells.getLearning() == s then
            spellBtn.text = "Currently learning "..spellBtn.text
        end
        buttons["spell_"..k] = spellBtn
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