local function draw(elements) 
    for k, e in pairs(elements) do
        if e.visible == 1 then
            love.graphics.rectangle("line", e.x, e.y, e.width, e.height)
            love.graphics.setColor(0.1, 0.1, 0.2, 1)
            love.graphics.rectangle("fill", e.x + 1, e.y + 1, e.width - 2, e.height - 2)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf(e.text, e.x + 4, e.y + 4, e.width - 8)
            if e.children then
                for k2, e2 in pairs(e.children) do
                    draw(e.children)
                end
            end
        end
    end
end

local function click(elements, x, y)
    for k, e in pairs(elements) do
        if e.visible == 1 and x > e.x and x < e.x + e.width and y > e.y and y < e.y + e.height then
            if e.action then
                e.action(e)
                return true
            elseif e.children then
                for k2, e2 in pairs(e.children) do
                    if click(e.children, x, y) == true then
                        return true
                    end
                end
            end
        end
    end
    return false
end

return {
    draw = draw,
    click = click
}