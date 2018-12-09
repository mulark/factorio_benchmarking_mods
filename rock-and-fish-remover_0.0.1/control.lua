local function has_value (val, tab)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

function clean_junk_on_chunk(event)
    for key, ent in pairs(event.surface.find_entities_filtered{area={{event.area.left_top.x, event.area.left_top.y}, {event.area.right_bottom.x, event.area.right_bottom.y}},force="neutral"}) do
        if has_value(ent.type, {"fish", "simple-entity"}) then
            ent.destroy()
        end
    end
end

script.on_event(defines.events.on_chunk_generated, function(event)
    clean_junk_on_chunk(event)
end)
