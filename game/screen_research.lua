local ui = require 'ui_manager'
local spells = require 'spells'

local buttons = {
    end_phase = {x = 600, y = 100, width = 100, height = 50, text = "OK", action = "endTurn", visible = 0}
}

local buttonActions = {
    none = function() end,
    endTurn = function()
        ScreenSwitch("map")
    end
}

local function load()
    
end

local function show()
    buttons["end_phase"].visible = 0
end

local function update()
    
end

local function keypressed(key, scancode, isrepeat)
    
end

local function mousepressed(x, y, button, istouch, presses)
    buttonActions[ui.click(buttons, x, y)]()

    if spells.getLearning() == "none" then
        for k, s in pairs(spells.researchable) do
            if y > (k - 1) * 32 and y < k * 32 then
                spells.startLearning(s)
                buttons["end_phase"].visible = 1
            end
        end
    end
end

local function draw()
    for k, s in pairs(spells.researchable) do
        if spells.getLearning() == s then
            love.graphics.print("Currently learning "..spells.data[spells.getLearning()].name, 0, (k - 1) * 32)
        else 
            love.graphics.print(spells.data[s].name, 0, (k - 1) * 32)
        end
    end        
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