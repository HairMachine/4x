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
    if key == nil then
        return animations
    else
        return animations[key]
    end
end

local function clear(key)
    animations[key] = nil
end

return {
    add = add,
    play = play,
    get = get,
    clear = clear
}