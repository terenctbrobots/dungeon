Room = Object:extend()

function Room:new(bound)
    self.x = bound.x
    self.y = bound.y
    self.w = bound.w
    self.h = bound.h
    self.bound = bound

    
    -- Fixed resize first
    -- self.x = self.x + 2
    -- self.y = self.y + 2
    -- self.w = self.w - 4
    -- self.h = self.h - 4
    -- randomize size of room later
    local x2 = self.x + self.w
    local y2 = self.y + self.h

    local wall_width = bound.w / 3
    local wall_height = bound.h / 3
    self.x = self.x + love.math.random(1, wall_width)
    self.y = self.y + love.math.random(1, wall_height)

    x2 = x2 - love.math.random(0, wall_width)
    y2 = y2 - love.math.random(0, wall_height)

    self.w = x2 - self.x
    self.h = y2 - self.y
end

function Room:getVol()
    return self.w * self.h
end

function Room:getCenter()
    return Point(self.x + math.floor(self.w/2), self.y + math.floor(self.h/2)) 
end

function Room:getLowerRight()
    return Point(self.x + self.w - 1, self.y + self.h - 1)
end

function Room:updateTile(tile)
    for x=0, self.w - 1, 1 do
        for y=0, self.h - 1, 1 do
            tile:setType(self.x+x,self.y+y,Dungeon.tile_types.ROOM)
        end
    end
end

function Room:draw(scale)
    love.graphics.setColor( 0, 255, 0, 255)
    love.graphics.rectangle("line", self.bound.x*scale, self.bound.y*scale, self.bound.w*scale, self.bound.h*scale)
    love.graphics.setColor( 255, 0, 0, 255 )
    love.graphics.rectangle( "fill", self.x*scale, self.y* scale, self.w*scale, self.h*scale )
end