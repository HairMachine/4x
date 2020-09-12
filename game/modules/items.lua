local data = {
    {name = "+1 Sword", slot = "weapon", class = "sword", effects = {slaying = 1}},
    {name = "+2 Sword", slot = "weapon", class = "sword", effects = {slaying = 2}},
    {name = "+3 Sword", slot = "weapon", class = "sword", effects = {slaying = 3}},
    {name = "+1 Hammer", slot = "weapon", class = "hammer", effects = {demolishing = 1}},
    {name = "+2 Hammer", slot = "weapon", class = "hammer", effects = {demolishing = 2}},
    {name = "+3 Hammer", slot = "weapon", class = "hammer", effects = {demolishing = 3}},
    {name = "+1 Armour", slot = "armour", class = "heavy armour", effects = {defence = 1}},
    {name = "+2 Armour", slot = "armour", class = "heavy armour", effects = {defence = 2}},
    {name = "+3 Armour", slot = "armour", class = "heavy armour", effects = {defence = 3}},
    {name = "Robe of Power", slot = "armour", class = "light armour", effects = {increaseMana = 1}},
    {name = "Helm of Giant Strength", slot = "utility", class = "", effects = {demolishing = 5, slaying = 5}}
}

local inventory = {}

local dropped = {}

local function generate()
    key = love.math.random(1, #data)
    newitem = {}
    for k, v in pairs(data[key]) do
        newitem[k] = v
    end
    table.insert(dropped, newitem)
end

local function addToInventory(item)
    table.insert(inventory, item)
end

local function getInventory()
    return inventory
end

local function removeFromInventory(key)
    table.remove(inventory, key)
end

local function getDropped()
    return dropped
end

local function removeFromDropped(key)
    table.remove(dropped, key)
end

local function getEffects(items, key)
    if not items then return 0 end
    local total = 0
    for k, i in pairs(items) do
        if i.effects[key] then total = total + i.effects[key] end
    end
    return total
end

return {
    generate = generate,
    addToInventory = addToInventory,
    getInventory = getInventory,
    removeFromInventory = removeFromInventory,
    getDropped = getDropped,
    removeFromDropped = removeFromDropped,
    getEffects = getEffects
}





