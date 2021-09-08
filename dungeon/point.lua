Point = Object:extend()

--- Creates a new `Point`
-- @name Point:new
-- @param x the x-coordinate
-- @param y the y-coordinate
-- @return a new `Point`
-- @usage
-- local Delaunay = require 'Delaunay'
-- local Point    = Delaunay.Point
-- local p = Point:new(1,1)
-- local p = Point(1,1) -- Alias to Point.new
-- print(p) -- print the point members x and y
--
function Point:new(x, y)
    self.x, self.y, self.id = x or 0, y or 0, '?'
end
  
  --- Returns the square distance to another `Point`.
  -- @param p a `Point`
  -- @return the square distance from self to `p`.
  -- @usage
  -- local p1, p2 = Point(), Point(1,1)
  -- print(p1:dist2(p2)) --> 2
  --
function Point:dist2(p)
    local dx, dy = (self.x - p.x), (self.y - p.y)
    return dx * dx + dy * dy
end

--- Returns the distance to another `Point`.
-- @param p a `Point`
-- @return the distance from self to `p`.
-- @usage
-- local p1, p2 = Point(), Point(1,1)
-- print(p1:dist2(p2)) --> 1.4142135623731
--
function Point:dist(p)
    return math.sqrt(self:dist2(p))
end

--- Checks if self lies into the bounds of a circle
-- @param cx the x-coordinate of the circle center
-- @param cy the y-coordinate of the circle center
-- @param r the radius of the circle
-- @return `true` or `false`
-- @usage
-- local p = Point()
-- print(p:isInCircle(0,0,1)) --> true
--
function Point:isInCircle(cx, cy, r)
    local dx = (cx - self.x)
    local dy = (cy - self.y)
    return ((dx * dx + dy * dy) <= (r * r))
end

function Point:__eq(p)
    return (self.x == p.x and self.y == p.y)
end
  
function Point:__tostring()
    return ('Point (%s) x: %.2f y: %.2f'):format(self.id, self.x, self.y)
end