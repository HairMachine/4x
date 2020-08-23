local function draw(elements) 
    for k, e in pairs(elements) do
        if e.visible == 1 then
            love.graphics.rectangle("line", e.x, e.y, e.width, e.height)
            love.graphics.print(e.text, e.x, e.y)
        end
    end
end

local function click(elements, x, y) 
    for k, e in pairs(elements) do
        if e.visible == 1 and x > e.x and x < e.x + e.width and y > e.y and y < e.y + e.height then
            return e.action
        end
    end
    return "none"
end

return {
    draw = draw,
    click = click
}