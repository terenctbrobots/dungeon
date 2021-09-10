--- Minimum Spanning Tree 
--- Take a series of edges and determine which edges are essential
--- to have fully connect path.
Mst = {}

function Mst.tree(start, edges) 
    local open_set = {}
    local close_set = {}

    local results = {}

    for _,edge in pairs(edges) do
        table.insert(open_set, edge.p1)
        table.insert(open_set, edge.p2)
    end

    table.insert(close_set, start)

    while (#open_set > 0) do
        local chosen = false
        local chosen_edge = nil
        local min_weight = 100000

        for _,edge in pairs(edges) do
            local closed_vertices = 0

            if contains_vertex(edge.p1, close_set) == false then
                closed_vertices = closed_vertices + 1
            end

            if contains_vertex(edge.p2, close_set) == false then
                closed_vertices = closed_vertices + 1
            end

            if closed_vertices ~= 1 then
                goto continue
            end

            if edge:length() < min_weight then
                chosen_edge = edge
                chosen = true
                min_weight = edge:length()
            end
            ::continue::
        end

        if chosen == false then
            goto exit
        end

        table.insert(results, chosen_edge)
        remove_vertex(chosen_edge.p1, open_set)
        remove_vertex(chosen_edge.p2, open_set)

        table.insert(close_set, chosen_edge.p1)
        table.insert(close_set, chosen_edge.p2)
    end
    
    ::exit::

    return results
end

function contains_vertex(vertex, vertex_list)
    for _,check_vertex in pairs(vertex_list) do
        if check_vertex == vertex then
            return true
        end
    end
    
    return false
end

function remove_vertex(vertex, vertex_list)
    for i = 1, #vertex_list, 1 do
        if vertex == vertex_list[i] then
            table.remove(vertex_list,i)
            return
        end
    end
end

return Mst
