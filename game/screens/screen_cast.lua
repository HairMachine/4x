local ui = require 'modules/ui_manager'
local spells = require 'modules/spells'
local resources = require 'modules/resources'

local errorBox = false
local errorText = ""

local buttons = {
    end_phase = {x = 600, y = 100, width = 100, height = 50, text = "Cancel", action = "endTurn", visible = 1},
    error_ok = {x = 350, y = 280, width = 100, height = 40, text = "OK", action = "errorOk", visible = 0}
}

local buttonActions = {
    none = function() end,
    endTurn = function()
        ScreenSwitch("map")
    end,
    errorOk = function()
        errorBox = false
        buttons['error_ok'].visible = 0
    end
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
    for k, s in pairs(spells.known) do
        if y > (k - 1) * 32 and y < k * 32 then
            -- Special case for summon hero spell as it requires command points to cast as well as MP; maybe this is generalisable to different resource costs
            if s == "summon_hero" and resources.getCommandPoints() < 1 then
                errorBox = true
                errorText = "You need at least one command point available to cast this spell again!"
                buttons['error_ok'].visible = 1
                return
            end
            if spells.getCasting().key == s then
                spells.startCasting("none")
            else
                spells.startCasting(s)
            end
            ScreenSwitch("map")
        end
    end
    buttonActions[ui.click(buttons, x, y)]()
end

local function draw()
    for k, s in pairs(spells.known) do
        if spells.getCasting().key == s then
            love.graphics.print(spells.data[s].name.." (casting)", 0, 32 * (k - 1))
        else
            love.graphics.print(spells.data[s].name, 0, 32 * (k - 1))
        end
    end
    ui.draw(buttons)

    if errorBox == true then
        love.graphics.rectangle("line", 300, 200, 200, 100)
        love.graphics.print(errorText, 310, 210)
    end
end

return {
    load = load,
    show = show,
    update = update,
    keypressed = keypressed,
    mousepressed = mousepressed,
    draw = draw
}