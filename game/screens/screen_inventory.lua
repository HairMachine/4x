local ui = require 'modules/ui_manager'
local units = require 'modules/units'
local items = require 'modules/items'

local buttons = {
    close = {x = 700, y = 500, width = 100, height = 50, text = "OK", action = "close", visible = 1}
}

local buttonActions = {
    none = function() end,
    close = function()
        ScreenSwitch("map")
    end
}

local heroes = {}
local currentHero = 0

local function load()
    
end

local function show()
    heroes = {}
    for k, u in pairs(units.get()) do
        if u.class == "Hero" then
            table.insert(heroes, u)
        end
    end
    currentHero = 1
end

local function update()
    
end

local function keypressed(key, scancode, isrepeat)
    
end

local function mousepressed(x, y, button, istouch, presses)
    buttonActions[ui.click(buttons, x, y)]()

    if y < 64 then
        for k, u in pairs(heroes) do
            if x > (k - 1) * 64 and x < k * 64 then
                currentHero = k
            end
        end
    end
    
    if x > 400 then
        for k, i in pairs(items.getInventory()) do
            if y > (k + 1) * 32 and y < (k + 2) * 32 then
                if heroes[currentHero].slots[i.slot].name ~= "" then
                    items.addToInventory(i)
                end
                heroes[currentHero].slots[i.slot] = i
                items.removeFromInventory(k)
            end
        end
    end

end

local function draw()
    love.graphics.print("Inventory")
    
    for k, u in pairs(heroes) do
        love.graphics.print(u.name, (k - 1) * 64, 32)
        if k == currentHero then
            love.graphics.rectangle("line", (k - 1) * 64, 32, 64, 32)
        end
    end

    if currentHero > 0 then
        love.graphics.print("Weapon: "..heroes[currentHero].slots.weapon.name, 0, 128)
        love.graphics.print("Armour: "..heroes[currentHero].slots.armour.name, 0, 128 + 32)
        love.graphics.print("Utility: "..heroes[currentHero].slots.utility.name, 0, 128 + 64)
    end
    
    for k, i in pairs(items.getInventory()) do
        love.graphics.print(i.name.." ("..i.slot..")", 400, (k + 1) * 32)
    end
    
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