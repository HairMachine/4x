local locations = require 'locations'
local ui = require 'ui_manager'
local units = require 'units'
local resources = require 'resources'

local buttonActions = {
    none = function() end,
    cancel = function()
        ScreenSwitch("map")
    end
}

local buttons = {
    cancel = {x = 600, y = 50, width = 100, height = 32, text = "Cancel", action = "cancel", visible = 1}
}

local function load()
    
end

local function show()

end

local function update()
    
end

local function keypressed(key, scancode, isrepeat)
    
end

local function mousepressed(x, y, button, istouch, presses)
    buttonActions[ui.click(buttons, x, y)]()

    for k, l in pairs(locations.getAllowedBuildings()) do
        if y > (k - 1) * 32 and y < k * 32 then
            if resources.enoughGold(l.cost) then
                local ctile = locations.getCurrentBuildingTile()
                locations.add(l.key, ctile.x, ctile.y, 1)
                units.spawnByLocType({type = l.key, x = ctile.x, y = ctile.y})
                resources.spendGold(l.cost)
                ScreenSwitch("map")
            end
        end
    end
end

local function draw()
    for k, l in pairs(locations.getAllowedBuildings()) do
        love.graphics.print(l.name.." ("..l.cost..")", 0, 32 * (k - 1))        
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