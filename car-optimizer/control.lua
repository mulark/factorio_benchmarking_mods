require "util"

local function round_to_closest_tile_with_offset(x)
    x = math.floor(x) + 0.5
    return (x)
end

function toggle_cars(entity)
    if not entity then
        return
    end
    if (entity.type ~= "car") then
        return
    end
    local x_coord = round_to_closest_tile_with_offset(entity.position.x)
    local y_coord = round_to_closest_tile_with_offset(entity.position.y)
    local surface = entity.surface
    if (entity.speed ~= 0) then
        entity.active = true
        return
    end
    if (entity.get_driver() or entity.get_passenger()) then
        entity.active = true
        return
    else
        entity.active = false
    end
    if (surface.count_entities_filtered({type={"transport-belt", "splitter"}, position={x_coord, y_coord}} ) > 0) then
        entity.active = true
    end
end

function find_cars_for_transport_belt(belt_ent)
    local surface = belt_ent.surface
    local possible_cars_found = surface.find_entities_filtered({type = "car", position = belt_ent.position})
    if (possible_cars_found) then
        for _, possible_car in pairs(possible_cars_found) do
            if possible_car.type == "car" then
                toggle_cars(possible_car)
            end
        end
    end
end

script.on_event(defines.events.on_player_driving_changed_state, function(event)
    toggle_cars(event.entity)
end)

script.on_event(defines.events.on_built_entity, function(event)
    find_cars_for_transport_belt(event.created_entity)
end,
{{filter="type", type = "transport-belt"}, {filter="type", type = "splitter"}}
)

script.on_event(defines.events.on_built_entity, function(event)
    toggle_cars(event.created_entity)
end,
{{filter="type", type = "car"}}
)

script.on_event(defines.events.on_robot_built_entity, function(event)
    find_cars_for_transport_belt(event.created_entity)
end,
{{filter="type", type = "transport-belt"}, {filter="type", type = "splitter"}}
)

script.on_event(defines.events.on_robot_built_entity, function(event)
    toggle_cars(event.created_entity)
end,
{{filter="type", type = "car"}}
)

script.on_event(defines.events.on_player_mined_entity, function(event)
    find_cars_for_transport_belt(event.entity)
end,
{{filter="type", type = "transport-belt"}, {filter="type", type = "splitter"}}
)

script.on_event(defines.events.on_robot_mined_entity, function(event)
    find_cars_for_transport_belt(event.entity)
end,
{{filter="type", type = "transport-belt"}, {filter="type", type = "splitter"}}
)

--[[ TODO 0.18.10: inserters can be said to not chase items in their prototype!]]
