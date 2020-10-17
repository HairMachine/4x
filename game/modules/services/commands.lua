local command = {
    update = function()
    end,
    finished = false
}

local commands = {}

local function running()
    return #commands
end

local function run()
    if #commands <= 0 then 
        return
    end
    if commands[1].update(commands[1].params) == true then
        table.remove(commands, 1)
    end
end

local function new(update, params)
    local command = {
        update = update,
        params = params
    }
    table.insert(commands, command)
end

return {
    running = running,
    run = run,
    new = new
}

