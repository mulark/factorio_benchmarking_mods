require "util"


--[[In the future this will be rewritten for then general case. I want to only listen to the on_player_driving_changed_state event.]]

script.on_init(function()
    all_cars = game.surfaces[1].find_entities_filtered({force = "player", type = "car"})
    for key, ent in pairs(all_cars) do
        toggle_cars(ent)
    end
end)
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
    else
        entity.active = false
    end
    if (surface.find_entity("express-transport-belt", {x_coord, y_coord} )) then
        entity.active = true
    end
    if (surface.find_entity("express-splitter", {x_coord, y_coord} )) then
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
