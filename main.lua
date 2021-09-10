Object = require "classic"

require "dungeon/dungeon"


local width = 100
local height = 100
local rooms = 22

local display = {
    tri = false,
    grid = true,
    mst = false
}

function love.load()
    dungeon = Dungeon(width,height,rooms)
    dungeon:generate_map()
end

function love.update(dt)
end

function love.draw()
    dungeon:draw(display)
    love.graphics.setColor(255,255,255,255)
    love.graphics.print('Rooms:'..rooms,520,20)
    love.graphics.print('+ or - to Add/Delete Rooms', 520,60)
    love.graphics.print('t - toggle show trangulation',520, 80)
    love.graphics.print('g - toggle show grid view/drawn room view',520,100)
    love.graphics.print('m - toggle show MST',520,120)
    love.graphics.print('r - regenerate dungeon',520, 180)
end

function love.keyreleased(key)
    if key == '+' or key == '=' then
        rooms = rooms + 1
    end

    if key == '-' or key == '_' then
        rooms = rooms - 1
        if rooms == 0 then
            rooms = 1
        end
    end

    if key == 'r' then
        dungeon = Dungeon(width, height, rooms)
        dungeon:generate_map()
    end

    if key == 't' then
        display.tri =  not display.tri
    end

    if key == 'm' then
        display.mst = not display.mst
    end

    if key == 'g' then
        display.grid =  not display.grid
    end
end