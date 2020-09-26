WINDOW = {
    width = 0,
    height = 0,
    scale = 0,
    trans = 0
}

local screens = {
    research = require 'screens/screen_research',
    cast = require 'screens/screen_cast',
    build = require 'screens/screen_build',
    inventory = require 'screens/screen_inventory',
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
    local width, height = love.window.getDesktopDimensions()
    love.window.setMode(width, height)
    WINDOW.width = width
    WINDOW.height = height
    WINDOW.scale = height / 600
    WINDOW.trans = (width - (960 * WINDOW.scale)) / 4

    for k, s in pairs(screens) do
        s.load()
    end
    ScreenSwitch("research")
end

function love.mousepressed(x, y, button, istouch, presses)
    x = x / WINDOW.scale - WINDOW.trans
    y = y / WINDOW.scale
    screens[screen].mousepressed(x, y, button, istouch, presses)
end

function love.update()
    screens[screen].update()
end

function love.keypressed(key, scancode, isrepeat)
    screens[screen].keypressed(key, scancode, isrepeat)
end

function love.draw()
    love.graphics.scale(WINDOW.scale, WINDOW.scale)
    love.graphics.translate(WINDOW.trans, 0)
    screens[screen].draw()
end