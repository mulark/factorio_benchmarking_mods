require "util"


--[[In the future this will be rewritten for then general case. I want to only listen to the on_player_driving_changed_state event.]]
--[[TODO use count_entities_filtered() where applicable, should be more optimized]]

local function round_to_closest_tile_with_offset(x)
    x = math.floor(x) + 0.5
    return (x)
end

function toggle_cars(entity)
    if (entity.type ~= "car") then
        return
    end
    local x_coord = round_to_closest_tile_with_offset(entity.position.x)
    local y_coord = round_to_closest_tile_with_offset(entity.position.y)
    local surface = entity.surface
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



script.on_event(defines.events.on_player_driving_changed_state, function(event)
    toggle_cars(event.entity)
end)

script.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity}, function(event)
    local action_entity = event.created_entity
    toggle_cars(action_entity)
    if (action_entity.type == "transport-belt" or action_entity.type == "splitter") then
        local surface = event.created_entity.surface
        --[[TODO: This only finds entities of name "car", while doing this for tanks too is required]]
        local car_found = surface.find_entity("car", action_entity.position)
        if (car_found) then
           car_found.active = true
        end
    end
end)

script.on_event({defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity}, function(event)
    local action_entity = event.entity
    if (action_entity.type == "transport-belt" or action_entity.type == "splitter") then
        local surface = event.entity.surface
        local car_found = surface.find_entity("car", action_entity.position)
        if (car_found) then
            toggle_cars(car_found)
        end
    end
end)
