require "dungeon/point"
require "enum"
require "dungeon/room"

local delaunay = require "dungeon/delaunay"
local mst = require 'dungeon/mst'
local path = require 'dungeon/path'
local tools = require 'dungeon/tools'

Dungeon = Object:extend()

-- Some constants for room generation
local min_boundary_size = 10
local min_boundary_multipler = 2
local percent_existing_corridor = 15

-- this scales that display
local scale = 5

Dungeon.tile_types = enum({"WALL","ROOM","CORRIDOR","ENTRANCE","EXIT"})

function Dungeon:new(width, height, max_rooms)
    self.width = width
    self.height = height
    self.max_rooms = max_rooms

    self.bounds = {[1] = { x = 0, y = 0, w = width, h = height} }
    self.rooms = {}
    self.points = {}
    self.triangles = nil
    self.ENTRANCE = Point(0,0)

    self.tile = {}
    local count = width * height

    while count > 0 do
        table.insert(self.tile, {
            tile_type = Dungeon.tile_types.WALL
        })
        count = count - 1
    end
end

function Dungeon:getType(x,y)
    return self.tile[(y*self.width) + (x + 1)].tile_type
end

function Dungeon:setType(x,y, new_type)
    self.tile[(y*self.width) + (x+1)].tile_type = new_type
end

function Dungeon:bounds( position )

    if position.x < 0 or position.x >= self.width then
        return false
    end

    if position.y < 0 or position.y >= self.height then
        return false
    end

    return true
end

-- Implement this to query dungeon for location to place unique objects
function Dungeon:query( filter )
    table.sort(self.rooms, function (a,b)
        local pointA = a:getLowerRight()
        local pointB = a:getLowerRight()
        
        return a.x > b.x and a.y > b.y
    end)

    return self.rooms[1]:getLowerRight()
end

function Dungeon:splitVertical()
    local random_width = math.random(min_boundary_size, self.bounds[1].w - min_boundary_size)
    self.bounds[#self.bounds+1] = { x = random_width + self.bounds[1].x,
                                  y = self.bounds[1].y,
                                  w = self.bounds[1].w - random_width,
                                  h = self.bounds[1].h}
    self.bounds[1].w = random_width
end

function Dungeon:splitHorizontal()
    local random_height = math.random(min_boundary_size,self.bounds[1].h - min_boundary_size)
    self.bounds[#self.bounds+1] = { x = self.bounds[1].x,
                                  y = random_height + self.bounds[1].y,
                                  w = self.bounds[1].w,
                                  h = self.bounds[1].h - random_height}
    self.bounds[1].h = random_height
end

function Dungeon:split() 
    -- Sort all bound so the biggest is at index 1
    table.sort(self.bounds, function (bound1, bound2)
        return (bound1.w * bound1.h) > (bound2.w * bound2.h)
    end)

    if love.math.random(1,100) <= 50 then
        -- split vertically
        if self.bounds[1].w > min_boundary_size * min_boundary_multipler then
            self:splitVertical()
        elseif self.bounds[1].h > min_boundary_size * min_boundary_multipler then
            self:splitHorizontal()
        end 
    else
        -- split horizontal
        if self.bounds[1].h > min_boundary_size * min_boundary_multipler then
            self:splitHorizontal()
        elseif self.bounds[1].w > min_boundary_size * min_boundary_multipler then
            self:splitVertical()
        end    
    end
end

--- These draw functions are just for visualization
function Dungeon:drawTriangles()
    for _,triangle in pairs(self.triangles) do
        love.graphics.setColor(0,0,255,255)
        local coords = triangle:getVertices()
        local scaled={}
        for _,coord in pairs(coords) do
            table.insert(scaled, coord * scale)
        end
        love.graphics.polygon("line", scaled)
    end
end

function Dungeon:drawMst()
    for _,edge in pairs(self.mst) do
        love.graphics.setColor(255,255,255,255)
        love.graphics.line(
            edge.p1.x*5,
            edge.p1.y*5,
            edge.p2.x*5,
            edge.p2.y*5)
    end
end

function Dungeon:drawMap()
    love.graphics.setPointSize(scale)
    for y = 0, self.height - 1, 1 do
        for x = 0, self.width - 1, 1 do
            tile_type = self:getType(x,y)
            if tile_type == Dungeon.tile_types.ROOM then
                love.graphics.setColor(255,0,0,255)
                love.graphics.rectangle("fill",x*scale,y*scale,scale,scale)
            elseif tile_type == Dungeon.tile_types.CORRIDOR then
                love.graphics.setColor(0,0,255,255)
                love.graphics.rectangle("fill",x*scale,y*scale,scale,scale)
            elseif tile_type == Dungeon.tile_types.ENTRANCE then
                love.graphics.setColor(255,255,255,255)
                love.graphics.rectangle("fill",x*scale,y*scale,scale,scale)
            end

        end
    end
end


function Dungeon:generateMap()
    local last_bound_count = 0
    repeat
        last_bound_count = #self.bounds

        self:split()
--        print("last bound " .. last_bound_count .." current " ..#self.bounds)
    until (last_bound_count == #self.bounds or #self.bounds >= self.max_rooms)

    for i = 1, #self.bounds, 1 do
        local new_room = Room(self.bounds[i])
        table.insert(self.rooms, new_room)
        new_room:updateTile(self)
    end

    -- Triangulate rooms

    for i = 1, #self.rooms, 1 do
        self.points[i] = self.rooms[i]:getCenter()
    end

    self.triangles = delaunay.triangulate(unpack(self.points))

    -- Do MST on edges
    self.edges = {}
    for _,triangle in pairs(self.triangles) do
        for _,edge in pairs(triangle:getEdges()) do
            table.insert(self.edges, edge)
        end
    end

    self.mst = mst.tree(self.edges[1].p1, self.edges)

    -- Add all mst edges in and path find to them
    local selected_edges = self.mst
    -- Add random remaining edges as well 
    for _,edge in pairs(self.edges) do
        for _,selected in pairs(selected_edges) do
            if edge:same(selected) then
                goto skip
            end
        end

        if love.math.random(1,100) <= percent_existing_corridor then
            table.insert(selected_edges, edge)
        end
    ::skip::
    end

    for _, edge in pairs(selected_edges) do
        local start = edge.p1 
        local goal = edge.p2
        local midpoint = edge:getMidPoint()

        local path = {}

        if love.math.random(0,1) then
            tools.merge(path,tools.line(start.x, start.y, midpoint.x, start.y))
            tools.merge(path,tools.line(midpoint.x, start.y, midpoint.x, midpoint.y))
        else
            tools.merge(path,tools.line(start.x, start.y, start.x, midpoint.y))
            tools.merge(path,tools.line(start.x, midpoint.y, midpoint.x, midpoint.y))
        end

        if love.math.random(0,1) then
            tools.merge(path,tools.line(midpoint.x,midpoint.y, goal.x, midpoint.y ))
            tools.merge(path,tools.line(goal.x, midpoint.y, goal.x, goal.y))
        else
            tools.merge(path,tools.line(midpoint.x,midpoint.y, midpoint.x, goal.y ))
            tools.merge(path,tools.line(midpoint.x, goal.y, goal.x, goal.y))
        end

        for _,node in pairs(path) do
--            print(node)
            if self:getType(node.x,node.y) == Dungeon.tile_types.WALL then
                self:setType(node.x,node.y,Dungeon.tile_types.CORRIDOR)
            end 
        end
    end 

    -- place entrance and exit (Might take this outside in the future)
    self.ENTRANCE =  self:query()

    self:setType(self.ENTRANCE.x, self.ENTRANCE.y, Dungeon.tile_types.ENTRANCE)

    -- Use A star, but it has twisty coordiors
--     for _, edge in pairs(selected_edges) do
--         -- pathfind
--         local start = edge.p1
--         local goal = edge.p2

--         -- print("start")
--         -- print(start)
--         -- print("goal")
--         -- print(goal)

--         local corridorway = path.find(start, goal, self, function (a , b) 
--             local path_cost = {}
--             path_cost.cost = b.position:dist(goal)

--     --        print(b.position)
--             local tile_type = self:getType(b.position.x, b.position.y)

--             if tile_type == self.tile_types.ROOM then 
--                 path_cost.cost = path_cost.cost + 10
--             elseif  tile_type == self.tile_types.WALL then
--                 path_cost.cost = path_cost.cost + 5
--             elseif tile_type == self.tile_types.CORRIDOR then
--                 path_cost.cost = path_cost.cost + 1
--             end

--             path_cost.traversable = true

--             return path_cost
--         end
--         )

--         for _,node in pairs(corridorway) do
-- --            print(node)
--             if self:getType(node.x,node.y) == self.tile_types.WALL then
--                 self:setType(node.x,node.y,self.tile_types.CORRIDOR)
--             end 
--         end
--     end

--    print(corridorway)


end

function Dungeon:draw(display)
    if display.tile then
        self:drawMap()
    else 
        for i = 1, #self.rooms, 1 do
            self.rooms[i]:draw(scale)
        end
    end

    if display.tri then
        self:drawTriangles()
    end

    if display.mst then
        self:drawMst()
    end
end

function Dungeon:__tostring()
    return "Dungeon"
end