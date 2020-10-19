local width = 0
local height = 0
local xpos = 0
local ypos = 0

local function get()
    return {w = width, h = height, x = xpos, y = ypos}
end

local function setSize(w, h)
    width = w
    height = h
end

local function setPos(x, y)
    xpos = x
    ypos = y
end

local function move(x, y)
    xpos = xpos + x
    ypos = ypos + y
    if xpos < 0 then xpos = 0 end
    if ypos < 0 then ypos = 0 end
end

local function adjustX(x)
    return x - xpos
end

local function adjustY(y)
    return y - ypos
end

local function isInView(x, y)
    if x - xpos > 0 and x - xpos < width and y - ypos > 0 and y - ypos < height then
        return true
    else
        return false
    end
end

return {
    get = get,
    setSize = setSize,
    setPos = setPos,
    move = move,
    adjustX = adjustX,
    adjustY = adjustY,
    isInView = isInView
}