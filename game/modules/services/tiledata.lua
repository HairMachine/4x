local tiles = {
    grass = love.graphics.newImage("assets/grass.png"),
    cave = love.graphics.newImage("assets/cave.png"),
    city = love.graphics.newImage("assets/city.png"),
    goblin = love.graphics.newImage("assets/goblin.png"),
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
    hero = love.graphics.newImage("assets/hero.png"),
    minotaur = love.graphics.newImage("assets/minotaur.png"),
    fire_vortex = love.graphics.newImage("assets/fire_vortex.png"),
    energy_vortex = love.graphics.newImage("assets/energy_vortex.png"),
    wolf = love.graphics.newImage("assets/wolf.png"),
    kobold = love.graphics.newImage("assets/kobold.png"),
    spider = love.graphics.newImage("assets/spider.png"),
    orc = love.graphics.newImage("assets/orc.png"),
    gnoll = love.graphics.newImage("assets/gnoll.png")
}

for k, v in pairs(tiles) do
    v:setFilter("nearest", "nearest")
end


return tiles