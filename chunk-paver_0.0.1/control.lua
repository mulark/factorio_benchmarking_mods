local function has_value (val, tab)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

function pave_chunk(event)
    local tiles = {}
    for x = event.area.left_top.x, event.area.right_bottom.x do
        for y = event.area.left_top.y, event.area.right_bottom.y do
            if not has_value(event.surface.get_tile({x, y}).name, {"water", "deepwater"}) then
                table.insert(tiles, {name = "refined-concrete", position = {x,y}})
            end
        end
    end
    event.surface.set_tiles(tiles, false)
    tiles = nil
end

script.on_event(defines.events.on_chunk_generated, function(event)
    pave_chunk(event)
end)
