local screens = {
    research = require 'screens/screen_research',
    cast = require 'screens/screen_cast',
    build = require 'screens/screen_build',
    map = require 'screens/screen_map',
    win = require 'screens/screen_win',
    lose = require 'screens/screen_lose'
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