local ui = require 'modules/ui_manager'
local units = require 'modules/units'
local items = require 'modules/items'

local buttons = {}
local itemButtons = {}

local currentHero = 0

local function itemUiBuild()
    itemButtons = {}
    for k, i in pairs(items.getInventory()) do
        table.insert(itemButtons, {x = 400, y = (k+1)*32, width = 300, height = 32, text = i.name.." ("..i.slot..")", visible = 1, item = i, key = k, action = function(event)
            if units.get()[currentHero].slots[event.item.slot].name ~= "" then
                items.addToInventory(event.item)
            end
            units.get()[currentHero].slots[event.item.slot] = i
            items.removeFromInventory(event.key)
            itemUiBuild()
        end})
    end
end

local function load()
    
end

local function show()
    buttons = {
        close = {x = 700, y = 500, width = 100, height = 50, text = "OK", visible = 1, action = function(event)
            ScreenSwitch("map")
        end}
    }
    local p = 0
    for k, u in pairs(units.get()) do
        if u.class == "Hero" then
            if currentHero == 0 then currentHero = k end
            table.insert(buttons, {x = p * 64, y = 32, width = 63, height = 32, text = u.name, visible = 1, hero = k, action = function(event)
                currentHero = event.hero
            end})
            p = p + 1
        end
    end
    itemUiBuild()
end

local function update()
    
end

local function keypressed(key, scancode, isrepeat)
    
end

local function mousepressed(x, y, button, istouch, presses)
    ui.click(buttons, x, y)
    ui.click(itemButtons, x, y)
end

local function draw()
    love.graphics.print("Inventory")

    if currentHero > 0 then
        love.graphics.print("Weapon: "..units.get()[currentHero].slots.weapon.name, 0, 128)
        love.graphics.print("Armour: "..units.get()[currentHero].slots.armour.name, 0, 128 + 32)
        love.graphics.print("Utility: "..units.get()[currentHero].slots.utility.name, 0, 128 + 64)
    end
    
    ui.draw(buttons)
    ui.draw(itemButtons)
end

return {
    load = load,
    show = show,
    update = update,
    keypressed = keypressed,
    mousepressed = mousepressed,
    draw = draw
}