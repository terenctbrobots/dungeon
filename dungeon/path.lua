
local delaunay = require "dungeon/delaunay"
local Point = delaunay.Point -- Refactor points and edge to its own class

path = {}

function path.find(start, goal, dungeon, cost_function) 
    local closed_set = {}
    local open_set = { {position = start, cost = 0} }
    local neighbours = {
        {1,0},
        {-1,0},
        {0,1},
        {0,-1}
    }

    local node_grid = {}

    for y = 0, dungeon.height - 1 , 1 do
        for x = 0, dungeon.width - 1, 1 do
            table.insert(node_grid, {
                position = Point(x, y),
                cost = 100000
            })
        end
    end

    local iterations = 100000

    while (#open_set > 0) do

        table.sort (open_set, function (a,b)
            return a.cost > b.cost
        end)

        -- for _, print_node in pairs(open_set) do
        --     print ("position " .. print_node.position.x .. "," .. print_node.position.y .. " cost " .. print_node.cost)
        -- end

        local node = table.remove(open_set)

--        print ("Using " .. node.position.x .. "," .. node.position.y .. " cost " .. node.cost)

        table.insert(closed_set, node)
        
        if node.position == goal then
            return ReconstructPath(node)
        end

        for _,offset in pairs(neighbours) do
            if dungeon:bounds( { x = node.position.x + offset[1], y = node.position.y + offset[2] }) == false then
                goto continue
            end

            local neighbour = node_grid[ (node.position.y + offset[2]) * dungeon.width + node.position.x + offset[1] + 1]

            if contains_node(closed_set, neighbour) then
                goto continue
            end

            local path_cost = cost_function(node, neighbour)

            if path_cost.traversable == false then
                goto continue
            end

            local new_cost = node.cost + path_cost.cost

            if new_cost < neighbour.cost then
                neighbour.previous = node
                neighbour.cost = new_cost

                table.insert ( open_set, neighbour )
            end

            ::continue::
        end

--        print("Next set")
    end

    return nil
end

function contains_node(set, node)
    for _,check in pairs(set) do
        if check.position == node.position then
            return true
        end
    end

    return false
end

function ReconstructPath(node)
    result = {}
    while node ~= nil do
        table.insert(result, node.position)
        node = node.previous
    end

    return result
end

return path