Object = require "classic"

require "dungeon/dungeon"

dungeon = Dungeon(100,100,22)

container = 1

function love.load()
    dungeon:generate_map()
end

function love.update(dt)
end

function love.draw()
--    dungeon:draw()
    dungeon:draw(container)
end

function love.keyreleased(key)
    container = container + 1
    if container > table.getn(dungeon.containers) then
        container = 1
    end
end