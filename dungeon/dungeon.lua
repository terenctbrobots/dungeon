require "dungeon/point"

local delaunay = require "dungeon/delaunay"
local mst = require 'dungeon/mst'
local path = require 'dungeon/path'

Dungeon = Object:extend()

require "enum"

require "dungeon/room"

local min_boundary_size = 10
local min_boundary_multipler = 2


function Dungeon:new(width, height, max_rooms)
    self.width = width
    self.height = height
    self.max_rooms = max_rooms

    self.containers = {[1] = { x = 0, y = 0, w = width, h = height} }
    self.rooms = {}
    self.points = {}
    self.triangles = nil

    self.map_types = enum({"wall","room","hall"})

    self.grid = {}
    local count = width * height

    while count > 0 do
        table.insert(self.grid, {
            grid_type = self.map_types.wall
        })
        count = count - 1
    end


end

function Dungeon:get_type(x,y)
    return self.grid[(y*self.width) + (x + 1)].grid_type
end

function Dungeon:set_type(x,y, new_type)
    self.grid[(y*self.width) + (x+1)].grid_type = new_type
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

function Dungeon:split_vertical()
    local random_width = math.random(min_boundary_size, self.containers[1].w - min_boundary_size)
    self.containers[#self.containers+1] = { x = random_width + self.containers[1].x,
                                  y = self.containers[1].y,
                                  w = self.containers[1].w - random_width,
                                  h = self.containers[1].h}
    self.containers[1].w = random_width
end

function Dungeon:split_horizontal()
    local random_height = math.random(min_boundary_size,self.containers[1].h - min_boundary_size)
    self.containers[#self.containers+1] = { x = self.containers[1].x,
                                  y = random_height + self.containers[1].y,
                                  w = self.containers[1].w,
                                  h = self.containers[1].h - random_height}
    self.containers[1].h = random_height
end

function Dungeon:split() 
    -- Sort all container so the biggest is at index 1
    table.sort(self.containers, function (container1, container2)
        return (container1.w * container1.h) > (container2.w * container2.h)
    end)

    if love.math.random(0,1) == 0 then
        -- split vertically
        if self.containers[1].w > min_boundary_size * min_boundary_multipler then
            self:split_vertical()
        elseif self.containers[1].h > min_boundary_size * min_boundary_multipler then
            self:split_horizontal()
        end 
    else
        -- split horizontal
        if self.containers[1].h > min_boundary_size * min_boundary_multipler then
            self:split_horizontal()
        elseif self.containers[1].w > min_boundary_size * min_boundary_multipler then
            self:split_vertical()
        end    
    end
end

function Dungeon:draw_triangles()
    for _,triangle in pairs(self.triangles) do
        love.graphics.setColor(0,0,255,255)
        love.graphics.polygon("line", triangle:getVertices())
    end
end

function Dungeon:draw_tree()
    for _,edge in pairs(self.tree) do
        love.graphics.setColor(255,0,0,255)
        love.graphics.line(edge.p1.x,edge.p1.y,edge.p2.x,edge.p2.y)
    end
end

function Dungeon:draw_map()
    love.graphics.setPointSize(5)
    for y = 0, self.height - 1, 1 do
        for x = 0, self.width - 1, 1 do
            grid_type = self:get_type(x,y)
            if grid_type == self.map_types.room then
                love.graphics.setColor(255,0,0,255)
            elseif grid_type == self.map_types.hall then
                love.graphics.setColor(0,0,255,255)
            else
                love.graphics.setColor(0,0,0,255)
            end

            love.graphics.points({x*5,y*5})
        end
    end
end

function Dungeon:line(ox,oy,ex,ey)
    local dx = math.abs( ex - ox )
    local dy = math.abs( ey - oy ) * -1

    local sx = ox < ex and 1 or -1
    local sy = oy < ey and 1 or -1
    local err = dx + dy

    local path = {}

    while true do

        table.insert(path,Point(ox,oy))

        if ox == ex and oy == ey then
            return path
        end

        local tmpErr = 2 * err
        if tmpErr > dy then
            err = err + dy
            ox = ox + sx
        end
        if tmpErr < dx then
            err = err + dx
            oy = oy + sy
        end
    end
end

function Dungeon:merge_path(path, merge)
    for _,point in pairs(merge) do
        table.insert(path, point)
    end
end

function Dungeon:generate_map()
    local last_container_count = 0
    repeat
        last_container_count = #self.containers

        self:split()
--        print("last container " .. last_container_count .." current " ..#self.containers)
    until (last_container_count == #self.containers or #self.containers >= self.max_rooms)

    for i = 1, #self.containers, 1 do
        local new_room = Room(self.containers[i])
        table.insert(self.rooms, new_room)
        new_room:update_grid(self)
    end

    -- Triangulate rooms

    for i = 1, #self.rooms, 1 do
        self.points[i] = self.rooms[i]:get_center()
    end

    self.triangles = delaunay.triangulate(unpack(self.points))

    -- Do MST on edges
    self.edges = {}
    for _,triangle in pairs(self.triangles) do
        for _,edge in pairs(triangle:getEdges()) do
            table.insert(self.edges, edge)
        end
    end

    self.tree = mst.tree(self.edges[1].p1, self.edges)

    -- Add all mst edges in and path find to them
    selected_edges = self.tree
    -- Add random remaining edges as well 

    for _, edge in pairs(selected_edges) do
        local start = edge.p1 
        local goal = edge.p2
        local midpoint = edge:getMidPoint()

        local path = {}

        if love.math.random(0,1) then
            self:merge_path(path,self:line(start.x, start.y, midpoint.x, start.y))
            self:merge_path(path,self:line(midpoint.x, start.y, midpoint.x, midpoint.y))
        else
            self:merge_path(path,self:line(start.x, start.y, start.x, midpoint.y))
            self:merge_path(path,self:line(start.x, midpoint.y, midpoint.x, midpoint.y))
        end

        if love.math.random(0,1) then
            self:merge_path(path,self:line(midpoint.x,midpoint.y, goal.x, midpoint.y ))
            self:merge_path(path,self:line(goal.x, midpoint.y, goal.x, goal.y))
        else
            self:merge_path(path,self:line(midpoint.x,midpoint.y, midpoint.x, goal.y ))
            self:merge_path(path,self:line(midpoint.x, goal.y, goal.x, goal.y))
        end

        for _,node in pairs(path) do
--            print(node)
            if self:get_type(node.x,node.y) == self.map_types.wall then
                self:set_type(node.x,node.y,self.map_types.hall)
            end 
        end

    end

    -- Use A star, but it has twisty coordiors
--     for _, edge in pairs(selected_edges) do
--         -- pathfind
--         local start = edge.p1
--         local goal = edge.p2

--         -- print("start")
--         -- print(start)
--         -- print("goal")
--         -- print(goal)

--         local hallway = path.find(start, goal, self, function (a , b) 
--             local path_cost = {}
--             path_cost.cost = b.position:dist(goal)

--     --        print(b.position)
--             local grid_type = self:get_type(b.position.x, b.position.y)

--             if grid_type == self.map_types.room then 
--                 path_cost.cost = path_cost.cost + 10
--             elseif  grid_type == self.map_types.wall then
--                 path_cost.cost = path_cost.cost + 5
--             elseif grid_type == self.map_types.hall then
--                 path_cost.cost = path_cost.cost + 1
--             end

--             path_cost.traversable = true

--             return path_cost
--         end
--         )

--         for _,node in pairs(hallway) do
-- --            print(node)
--             if self:get_type(node.x,node.y) == self.map_types.wall then
--                 self:set_type(node.x,node.y,self.map_types.hall)
--             end 
--         end
--     end

--    print(hallway)


end

function Dungeon:draw(container)
    -- local container = self.containers[container]

    -- love.graphics.setColor( 255, 0, 0, 255 )
    -- love.graphics.rectangle( "line", container.x, container.y, container.w, container.h )
    -- for i = 1, #self.rooms, 1 do
    --     self.rooms[i]:draw()
    -- end

    --self:draw_triangles()
    --self:draw_tree()
    self:draw_map()
end

function Dungeon:__tostring()
    return "Dungeon"
end