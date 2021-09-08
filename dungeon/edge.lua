Edge = Object:extend()

--- Creates a new `Edge`
-- @name Edge:new
-- @param p1 a `Point`
-- @param p2 a `Point`
-- @return a new `Edge`
-- @usage
-- local Delaunay = require 'Delaunay'
-- local Edge     = Delaunay.Edge
-- local Point    = Delaunay.Point
-- local e = Edge:new(Point(1,1), Point(2,5))
-- local e = Edge(Point(1,1), Point(2,5)) -- Alias to Edge.new
-- print(e) -- print the edge members p1 and p2
--
function Edge:new(p1, p2)
  self.p1, self.p2 = p1, p2
end

function Edge:__tostring(p1,p2)
    return (('Edge :\n  %s\n  %s'):format(tostring(self.p1), tostring(self.p2)))
end

function Edge:__eq(e)
    return (self.p1 == e.p1 and self.p2 == e.p2)
end

--- Test if `otherEdge` is similar to self. It does not take into account the direction.
-- @param otherEdge an `Edge`
-- @return `true` or `false`
-- @usage
-- local e1 = Edge(Point(1,1), Point(2,5))
-- local e2 = Edge(Point(2,5), Point(1,1))
-- print(e1:same(e2)) --> true
-- print(e1 == e2)) --> false, == operator considers the direction
--
function Edge:same(otherEdge)
  return ((self.p1 == otherEdge.p1) and (self.p2 == otherEdge.p2))
      or ((self.p1 == otherEdge.p2) and (self.p2 == otherEdge.p1))
end

--- Returns the length.
-- @return the length of self
-- @usage
-- local e = Edge(Point(), Point(10,0))
-- print(e:length()) --> 10
--
function Edge:length()
  return self.p1:dist(self.p2)
end

--- Returns the midpoint coordinates.
-- @return the x-coordinate of self midpoint
-- @return the y-coordinate of self midpoint
-- @usage
-- local e = Edge(Point(), Point(10,0))
-- print(e:getMidPoint()) --> 5, 0
--
function Edge:getMidPoint()
  local x = self.p1.x + math.floor((self.p2.x - self.p1.x) / 2)
  local y = self.p1.y + math.floor((self.p2.y - self.p1.y) / 2)
  return Point(x, y)
end
