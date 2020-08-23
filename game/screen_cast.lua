local ui = require 'ui_manager'
local spells = require 'spells'

local buttons = {
    end_phase = {x = 600, y = 100, width = 100, height = 50, text = "Cancel", action = "endTurn", visible = 1}
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

end

local function update()
    
end

local function keypressed(key, scancode, isrepeat)
    
end

local function mousepressed(x, y, button, istouch, presses)
    for k, s in pairs(spells.known) do
        if y > (k - 1) * 32 and y < k * 32 then
            if spells.getCasting().key == s then
                spells.startCasting("none")
            else
                spells.startCasting(s)
            end
            ScreenSwitch("map")
        end
    end
    buttonActions[ui.click(buttons, x, y)]()
end

local function draw()
    for k, s in pairs(spells.known) do
        if spells.getCasting().key == s then
            love.graphics.print(spells.data[s].name.." (casting)", 0, 32 * (k - 1))
        else
            love.graphics.print(spells.data[s].name, 0, 32 * (k - 1))
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