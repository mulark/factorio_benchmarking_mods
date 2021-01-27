require "util"

local function round_to_closest_tile_with_offset(x)
    x = math.floor(x) + 0.5
    return (x)
end

function toggle_cars(entity)
    if not (entity and entity.valid) then
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
    for _, possible_car in pairs(possible_cars_found) do
        toggle_cars(possible_car)
        if possible_car.type == "car" then
        end
    end
end

function handle_event(event)
    local entity = event.created_entity or	-- on_built events
                 event.entity			-- on_player_driving_changed_state
    -- Nuking a car may mean the car doesn't exist when we get here
    if entity then
        if entity.type == "car" then
        	toggle_cars(entity)
        else
            find_cars_for_transport_belt(entity)
        end
    end
end

script.on_event(defines.events.on_player_driving_changed_state, function(event)
    handle_event(event)
end)

script.on_event(defines.events.on_built_entity, function(event)
    handle_event(event)
end, {
	{filter="type", type = "transport-belt"}, {filter="type", type = "splitter"},
	{filter="type", type = "car"}
})

script.on_event(defines.events.on_robot_built_entity, function(event)
    handle_event(event)
end, {
	{filter="type", type = "transport-belt"}, {filter="type", type = "splitter"},
	{filter="type", type = "car"}
})

script.on_event(defines.events.on_player_mined_entity, function(event)
    handle_event(event)
end, {
	{filter="type", type = "transport-belt"}, {filter="type", type = "splitter"}
})

script.on_event(defines.events.on_robot_mined_entity, function(event)
    handle_event(event)
end, {
	{filter="type", type = "transport-belt"}, {filter="type", type = "splitter"}
})

script.on_event(defines.events.on_entity_died, function(event)
    handle_event(event)
end, {
	{filter="type", type = "transport-belt"}, {filter="type", type = "splitter"}
})

--[[ No entity is valid here
script.on_event(defines.events.on_entity_destroyed,
function(event)
    handle_event(event)
end, {
	{filter="type", type = "transport-belt"}, {filter="type", type = "splitter"},
	{filter="type", type = "car"}
})]]

script.on_event(defines.events.script_raised_built, function(event)
    handle_event(event)
end, {
	{filter="type", type = "transport-belt"}, {filter="type", type = "splitter"},
	{filter="type", type = "car"}
})

script.on_event(defines.events.script_raised_destroy,
function(event)
    handle_event(event)
end, {
	{filter="type", type = "transport-belt"}, {filter="type", type = "splitter"}
})

script.on_event(defines.events.script_raised_revive,
function(event)
    handle_event(event)
end, {
	{filter="type", type = "transport-belt"}, {filter="type", type = "splitter"},
	{filter="type", type = "car"}
})


--[[ TODO 0.18.10: inserters can be said to not chase items in their prototype!]]
