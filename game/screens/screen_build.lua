local locations = require 'modules/locations'
local ui = require 'modules/ui_manager'
local units = require 'modules/units'
local resources = require 'modules/resources'
local worldmap = require 'modules/worldmap'
local targeter = require 'modules/targeter'

local buttons = {}

local function load()
    
end

local function show()
    buttons = {
        cancel = {x = 600, y = 50, width = 100, height = 32, text = "Cancel", visible = 1, action = function(event) 
            ScreenSwitch("map")
        end}
    }
    for k, l in pairs(locations.getAllowedBuildings()) do
        love.graphics.print(l.name.." ("..l.cost.."gp)", 0, 32 * (k - 1))  
        table.insert(buttons, {x = 0, y = (k-1) * 32, width = 300, height = 32, text = l.name.." ("..l.cost.."gp)", visible = 1, loc = l, action = function(event) 
            if resources.enoughGold(event.loc.cost) then
                local ctile = locations.getCurrentBuildingTile()
                locations.add(event.loc.key, ctile.x, ctile.y, 1)
                units.spawnByLocType({type = event.loc.key, x = ctile.x, y = ctile.y})
                resources.spendGold(event.loc.cost)
                worldmap.tileAlignmentChange()
                units.get()[targeter.getUnit()].moved = 1
                targeter.clear()
                ScreenSwitch("map")
            end
        end})      
    end
end

local function update()
    
end

local function keypressed(key, scancode, isrepeat)
    
end

local function mousepressed(x, y, button, istouch, presses)
    ui.click(buttons, x, y)
end

local function draw()
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