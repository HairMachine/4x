local ui = require 'modules/services/ui_manager'

local buttons = {
    cancel = {x = 600, y = 100, width = 100, height = 50, text = "Cancel", visible = 1, action = function()
    
    end}
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
   ui.click(buttons, x, y)
end

local function draw()
    love.graphics.print("Screen")
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