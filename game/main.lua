local screens = {
    research = require 'screen_research',
    cast = require 'screen_cast',
    build = require 'screen_build',
    map = require 'screen_map',
    win = require 'screen_win',
    lose = require 'screen_lose'
}

local screen = "null"

function ScreenSwitch(newscreen)
    screen = newscreen
    screens[screen].show()  
end

function love.load()
    for k, s in pairs(screens) do
        s.load()
    end
    ScreenSwitch("research")
end

function love.mousepressed(x, y, button, istouch, presses)
    screens[screen].mousepressed(x, y, button, istouch, presses)
end

function love.update()
    screens[screen].update()
end

function love.keypressed(key, scancode, isrepeat)
    screens[screen].keypressed(key, scancode, isrepeat)
end

function love.draw()
    screens[screen].draw()
end