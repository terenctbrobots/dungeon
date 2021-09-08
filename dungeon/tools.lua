Tools = {}


function Tools.line(ox,oy,ex,ey)
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

function Tools.merge(nodes, merge)
    for _,node in pairs(merge) do
        table.insert(nodes, node)
    end
end

return Tools