local delaunay = require "dungeon/delaunay"
local Point = delaunay.Point

Room = Object:extend()

function Room:new(container)
    self.x = container.x
    self.y = container.y
    self.w = container.w
    self.h = container.h
    self.container = container

    
    -- Fixed resize first
    -- self.x = self.x + 2
    -- self.y = self.y + 2
    -- self.w = self.w - 4
    -- self.h = self.h - 4
    -- randomize size of room later
    local x2 = self.x + self.w
    local y2 = self.y + self.h

    local wall_width = container.w / 3
    local wall_height = container.h / 3
    self.x = self.x + love.math.random(1, wall_width)
    self.y = self.y + love.math.random(1, wall_height)

    x2 = x2 - love.math.random(0, wall_width)
    y2 = y2 - love.math.random(0, wall_height)

    self.w = x2 - self.x
    self.h = y2 - self.y
end

function Room:get_vol()
    return self.w * self.h
end

function Room:get_center()
    return Point(self.x + math.floor(self.w/2), self.y + math.floor(self.h/2)) 
end

function Room:update_grid(grid)
    for x=0, self.w - 1, 1 do
        for y=0, self.h - 1, 1 do
            grid:set_type(self.x+x,self.y+y,grid.map_types.room)
        end
    end
end

function Room:draw()
    love.graphics.setColor( 0, 255, 0, 255 )
    love.graphics.rectangle( "fill", self.x, self.y, self.w, self.h )
end