local tiles = require 'modules/tiledata'
local camera = require 'modules/camera'

local animations = {}

local function generateKey()
    local key
    while not key or animations[key] do
        key = 'key-'..love.math.random(1, 32000)
    end
    return key
end

local function add(loop, frames)
    local key = generateKey()
    animations[key] = {loop = loop, frames = frames, frame = 1, maxFrame = #frames}
    return key
end

local function draw()
    for k, a in pairs(animations) do
        if camera.isInView(a.frames[a.frame].x, a.frames[a.frame].y) then
            love.graphics.draw(tiles[a.frames[a.frame].tile], camera.adjustX(a.frames[a.frame].x), camera.adjustY(a.frames[a.frame].y), 0, 2)
        end
    end
end

local function play()
    for k, a in pairs(animations) do
        local a = animations[k]
        local f = a.frames[a.frame]
        if (f.tic == nil) then
            f.tic = 1
        else
            f.tic = f.tic + 1
        end
        f.tic = f.tic + 1
        if f.tic >= f.tics then
            f.tic = 0
            a.frame = a.frame + 1
            if a.frame > a.maxFrame then 
                if a.loop == true then
                    a.frame = 1
                else
                    animations[k] = nil
                end
            end
        end 
    end
end

local function get(key)
    return animations[key]
end

local function clear(key)
    animations[key] = nil
end

return {
    add = add,
    play = play,
    draw = draw,
    get = get,
    clear = clear
}