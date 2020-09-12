local ui = require 'modules/ui_manager'

local buttons = {
    dummy = {x = 600, y = 100, width = 100, height = 50, text = "OK", action = "dummy", visible = 1}
}

local buttonActions = {
    dummy = function()
        
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
    buttonActions[ui.click(buttons, x, y)]()
end

local function draw()
    love.graphics.print("Inventory")
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