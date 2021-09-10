#!/usr/bin/env lua
---------------
-- ## Delaunay, Lua module for convex polygon triangulation
-- @author Roland Yonaba
-- @copyright 2013-2016
-- @license MIT
-- @script delaunay

require 'dungeon/edge'
-- ================
-- Private helpers
-- ================

local setmetatable = setmetatable
local tostring     = tostring
local assert       = assert
local unpack       = unpack or table.unpack
local remove       = table.remove
local sqrt         = math.sqrt
local max          = math.max

-- Triangle semi-perimeter by Heron's formula
local function quatCross(a, b, c)
  local p = (a + b + c) * (a + b - c) * (a - b + c) * (-a + b + c)
  return sqrt(p)
end


-- Cross product (p1-p2, p2-p3)
local function crossProduct(p1, p2, p3)
  local x1, x2 = p2.x - p1.x, p3.x - p2.x
  local y1, y2 = p2.y - p1.y, p3.y - p2.y
  return x1 * y2 - y1 * x2
end

-- Checks if angle (p1-p2-p3) is flat
local function isFlatAngle(p1, p2, p3)
  return (crossProduct(p1, p2, p3) == 0)
end

-- ================
-- Module classes
-- ================


--- `Triangle` class
-- @type Triangle

Triangle = Object:extend()

--- Creates a new `Triangle`
-- @name Triangle:new
-- @param p1 a `Point`
-- @param p2 a `Point`
-- @param p3 a `Point`
-- @return a new `Triangle`
-- @usage
-- local Delaunay = require 'Delaunay'
-- local Triangle = Delaunay.Triangle
-- local p1, p2, p3 = Point(), Point(2,0), Point(1,1)
-- local t = Triangle:new(p1, p2, p3)
-- local t = Triangle(p1, p2, p3) -- Alias to Triangle.new
-- print(t) -- print the triangle members p1, p2 and p3
--
function Triangle:new(p1, p2, p3)
  assert(not isFlatAngle(p1, p2, p3), ("angle (p1, p2, p3) is flat:\n  %s\n  %s\n  %s")
    :format(tostring(p1), tostring(p2), tostring(p3)))
  self.p1, self.p2, self.p3 = p1, p2, p3
  self.e1, self.e2, self.e3 = Edge(p1, p2), Edge(p2, p3), Edge(p3, p1)
end

function Triangle:__tostring() 
  return (('Triangle: \n  %s\n  %s\n  %s')
    :format(tostring(self.p1), tostring(self.p2), tostring(self.p3)))
end

--- Checks if the triangle is defined clockwise (sequence p1-p2-p3)
-- @return `true` or `false`
-- @usage
-- local p1, p2, p3 = Point(), Point(1,1), Point(2,0)
-- local t = Triangle(p1, p2, p3)
-- print(t:isCW()) --> true
--
function Triangle:isCW()
  return (crossProduct(self.p1, self.p2, self.p3) < 0)
end

--- Checks if the triangle is defined counter-clockwise (sequence p1-p2-p3)
-- @return `true` or `false`
-- @usage
-- local p1, p2, p3 = Point(), Point(2,0), Point(1,1)
-- local t = Triangle(p1, p2, p3)
-- print(t:isCCW()) --> true
--
function Triangle:isCCW()
  return (crossProduct(self.p1, self.p2, self.p3) > 0)
end

--- Returns the length of the edges
-- @return the length of the edge p1-p2
-- @return the length of the edge p2-p3
-- @return the length of the edge p3-p1
-- @usage
-- local p1, p2, p3 = Point(), Point(2,0), Point(1,1)
-- local t = Triangle(p1, p2, p3)
-- print(t:getSidesLength()) --> 2  1.4142135623731  1.4142135623731
--
function Triangle:getSidesLength()
  return self.e1:length(), self.e2:length(), self.e3:length()
end

--- Returns the coordinates of the center
-- @return the x-coordinate of the center
-- @return the y-coordinate of the center
-- @usage
-- local p1, p2, p3 = Point(), Point(2,0), Point(1,1)
-- local t = Triangle(p1, p2, p3)
-- print(t:getCenter()) --> 1 0.33333333333333
--
function Triangle:getCenter()
  local x = (self.p1.x + self.p2.x + self.p3.x) / 3
  local y = (self.p1.y + self.p2.y + self.p3.y) / 3
  return x, y
end

--- Returns the coordinates of the circumcircle center and its radius
-- @return the x-coordinate of the circumcircle center
-- @return the y-coordinate of the circumcircle center
-- @return the radius of the circumcircle
-- @usage
-- local p1, p2, p3 = Point(), Point(2,0), Point(1,1)
-- local t = Triangle(p1, p2, p3)
-- print(t:getCircumCircle()) --> 1  0  1
--
function Triangle:getCircumCircle()
  local x, y = self:getCircumCenter()
  local r = self:getCircumRadius()
  return x, y, r
end

--- Returns the coordinates of the circumcircle center
-- @return the x-coordinate of the circumcircle center
-- @return the y-coordinate of the circumcircle center
-- @usage
-- local p1, p2, p3 = Point(), Point(2,0), Point(1,1)
-- local t = Triangle(p1, p2, p3)
-- print(t:getCircumCenter()) --> 1  0
--
function Triangle:getCircumCenter()
  local p1, p2, p3 = self.p1, self.p2, self.p3
  local D =  ( p1.x * (p2.y - p3.y) +
               p2.x * (p3.y - p1.y) +
               p3.x * (p1.y - p2.y)) * 2
  local x = (( p1.x * p1.x + p1.y * p1.y) * (p2.y - p3.y) +
             ( p2.x * p2.x + p2.y * p2.y) * (p3.y - p1.y) +
             ( p3.x * p3.x + p3.y * p3.y) * (p1.y - p2.y))
  local y = (( p1.x * p1.x + p1.y * p1.y) * (p3.x - p2.x) +
             ( p2.x * p2.x + p2.y * p2.y) * (p1.x - p3.x) +
             ( p3.x * p3.x + p3.y * p3.y) * (p2.x - p1.x))
  return (x / D), (y / D)
end

--- Returns the radius of the circumcircle
-- @return the radius of the circumcircle
-- @usage
-- local p1, p2, p3 = Point(), Point(2,0), Point(1,1)
-- local t = Triangle(p1, p2, p3)
-- print(t:getCircumRadius()) --> 1
--
function Triangle:getCircumRadius()
  local a, b, c = self:getSidesLength()
  return ((a * b * c) / quatCross(a, b, c))
end

--- Returns the area
-- @return the area
-- @usage
-- local p1, p2, p3 = Point(), Point(2,0), Point(1,1)
-- local t = Triangle(p1, p2, p3)
-- print(t:getArea()) --> 1
--
function Triangle:getArea()
  local a, b, c = self:getSidesLength()
  return (quatCross(a, b, c) / 4)
end

--- Checks if a given point lies into the triangle circumcircle
-- @param p a `Point`
-- @return `true` or `false`
-- @usage
-- local p1, p2, p3 = Point(), Point(2,0), Point(1,1)
-- local t = Triangle(p1, p2, p3)
-- print(t:inCircumCircle(Point(1,-1))) --> true
--
function Triangle:inCircumCircle(p)
  return p:isInCircle(self:getCircumCircle())
end

function Triangle:getVertices()
  return { self.p1.x, self.p1.y, self.p2.x, self.p2.y, self.p3.x, self.p3.y }
end

function Triangle:getEdges()
  return { self.e1, self.e2, self.e3 }
end

--- Delaunay module
-- @section public

--- Delaunay module
-- @table Delaunay
-- @field Point reference to the `Point` class
-- @field Edge reference to the `Edge` class
-- @field Triangle reference to the `Triangle` class
-- @field convexMultiplier multiplier heuristic for bounding triangle calculation. When small (~1) produces convex-hull, when large, produces concave hulls. Defaults to 1000.
-- @field _VERSION the version of the current module
local Delaunay = {
  Point            = Point,
  Edge             = Edge,
  Triangle         = Triangle,
	convexMultiplier = 1e3,
  _VERSION = "0.1"
}

--- Triangulates a set of given vertices
-- @param ... a `vargarg` list of objects of type `Point`
-- @return a set of objects of type `Triangle`
-- @usage
-- local Delaunay = require 'Delaunay'
-- local Point    = Delaunay.Point 
-- local p1, p2, p3, p4 = Point(), Point(2,0), Point(1,1), Point(1,-1)
-- local triangles = Delaunay.triangulate(p1, p2, p3, p4)
-- for i = 1, #triangles do
--   print(triangles[i])
-- end
--
function Delaunay.triangulate(...)
  local vertices = {...}
  local nvertices = #vertices
  assert(nvertices > 2, "Cannot triangulate, needs more than 3 vertices")
  if nvertices == 3 then
    return {Triangle(unpack(vertices))}
  end

  local trmax = nvertices * 4

  local minX, minY = vertices[1].x, vertices[1].y
  local maxX, maxY = minX, minY

  for i = 1, #vertices do
    local vertex = vertices[i]
    vertex.id = i
    if vertex.x < minX then minX = vertex.x end
    if vertex.y < minY then minY = vertex.y end
    if vertex.x > maxX then maxX = vertex.x end
    if vertex.y > maxY then maxY = vertex.y end
  end

	local convex_mult = Delaunay.convexMultiplier
  local dx, dy = (maxX - minX) * convex_mult, (maxY - minY) * convex_mult
  local deltaMax = max(dx, dy)
  local midx, midy = (minX + maxX) * 0.5, (minY + maxY) * 0.5

  local p1 = Point(midx - 2 * deltaMax, midy - deltaMax)
  local p2 = Point(midx, midy + 2 * deltaMax)
  local p3 = Point(midx + 2 * deltaMax, midy - deltaMax)
  p1.id, p2.id, p3.id = nvertices + 1, nvertices + 2, nvertices + 3
  vertices[p1.id] = p1
  vertices[p2.id] = p2
  vertices[p3.id] = p3

  local triangles = {}
  triangles[#triangles + 1] = Triangle(vertices[nvertices + 1],
                                       vertices[nvertices + 2],
                                       vertices[nvertices + 3]
                              )

  for i = 1, nvertices do
  
    local edges = {}
    local ntriangles = #triangles

    for j = #triangles, 1, -1 do
      local curTriangle = triangles[j]
      if curTriangle:inCircumCircle(vertices[i]) then
        edges[#edges + 1] = curTriangle.e1
        edges[#edges + 1] = curTriangle.e2
        edges[#edges + 1] = curTriangle.e3
        remove(triangles, j)
      end
    end

    for j = #edges - 1, 1, -1 do
      for k = #edges, j + 1, -1 do
        if edges[j] and edges[k] and edges[j]:same(edges[k]) then
          remove(edges, j)
          remove(edges, k-1)
        end
      end
    end

    for j = 1, #edges do
      local n = #triangles
      assert(n <= trmax, "Generated more than needed triangles")
      triangles[n + 1] = Triangle(edges[j].p1, edges[j].p2, vertices[i])
    end
   
  end

  for i = #triangles, 1, -1 do
    local triangle = triangles[i]
    if (triangle.p1.id > nvertices or 
        triangle.p2.id > nvertices or 
        triangle.p3.id > nvertices) then
      remove(triangles, i)
    end
  end

  for _ = 1,3 do remove(vertices) end

  return triangles

end

return Delaunay