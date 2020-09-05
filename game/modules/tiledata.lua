local tiles = {
    grass = love.graphics.newImage("assets/grass.png"),
    cave = love.graphics.newImage("assets/cave.png"),
    city = love.graphics.newImage("assets/city.png"),
    monster = love.graphics.newImage("assets/monster.png"),
    settler = love.graphics.newImage("assets/settler.png"),
    targeter = love.graphics.newImage("assets/targeter.png"),
    army = love.graphics.newImage("assets/army.png"),
    tower = love.graphics.newImage("assets/tower.png"),
    ore = love.graphics.newImage("assets/ore.png"),
    crystal = love.graphics.newImage("assets/crystal.png"),
    water = love.graphics.newImage("assets/water.png"),
    forest = love.graphics.newImage("assets/forest.png"),
    mountain = love.graphics.newImage("assets/mountain.png"),
    tundra = love.graphics.newImage("assets/tundra.png"),
    ruins = love.graphics.newImage("assets/ruins.png"),
    hero = love.graphics.newImage("assets/hero.png")
}

for k, v in pairs(tiles) do
    v:setFilter("nearest", "nearest")
end


return tiles