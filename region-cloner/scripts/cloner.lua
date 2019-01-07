function correct_for_rail_grid(tile_paste_length)
    if ((tile_paste_length % 2) ~= 0) then
        if (tile_paste_length < 0) then
            tile_paste_length = tile_paste_length - 1
        else
            tile_paste_length = tile_paste_length + 1
        end
    end
    return tile_paste_length
end

local function has_value (val, tab)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

function swap_to_fix_pairs(negative_most, positive_most)
    --[[You will not find any entites if your left top is to the right of your right bottom. Same for top/bottom.]]
    if (negative_most > positive_most) then
        local temp = negative_most
        negative_most = positive_most
        positive_most = temp
    end
    return negative_most, positive_most
end

local function clean_paste_area (surface, left, top, right, bottom)
    local second_try_destroy_entities = {}
    for key, ent in pairs(surface.find_entities_filtered({area={{left, top},{right, bottom}}})) do
        if (ent.valid) then
            if (ent.type ~= "player") then
                ent.clear_items_inside()
                if not (ent.can_be_destroyed()) then
                    table.insert(second_try_destroy_entities, ent)
                end
                ent.destroy()
            end
        end
        for key, ent in pairs(second_try_destroy_entities) do
            ent.destroy()
        end
    end
end
function copy_entity (original_entity, cloned_entity)
    copy_properties(original_entity, cloned_entity)
    copy_inventories_and_fluid(original_entity, cloned_entity)
    copy_progress_bars(original_entity, cloned_entity)
    copy_resources(original_entity, cloned_entity)
    copy_circuit_connections(original_entity, cloned_entity)
    copy_train(original_entity, cloned_entity)
    --[[updating connections probably doesn't do anything, since anything that could be affected by a beacon already exists by the time beacons are cloned--]]
    cloned_entity.update_connections()
    copy_transport_line_contents(original_entity, cloned_entity)
end

function copy_properties (original_entity, cloned_entity)
    if (original_entity.type == "loader") then
        cloned_entity.loader_type = original_entity.loader_type
    end
    cloned_entity.copy_settings(original_entity)
    cloned_entity.orientation = original_entity.orientation
    cloned_entity.direction = original_entity.direction
end

local function internal_inventory_copy(original_entity, cloned_entity, INV_DEFINE)
    if (original_entity.get_inventory(INV_DEFINE)) then
        local working_inventory = original_entity.get_inventory(INV_DEFINE)
        for k=1, #working_inventory do
            if (working_inventory[k].valid_for_read) then
                cloned_entity.get_inventory(INV_DEFINE).insert(working_inventory[k])
            end
        end
    end
end

function copy_inventories_and_fluid (original_entity, cloned_entity)
    internal_inventory_copy(original_entity, cloned_entity, defines.inventory.chest)
    internal_inventory_copy(original_entity, cloned_entity, defines.inventory.rocket_silo_result)
    internal_inventory_copy(original_entity, cloned_entity, defines.inventory.furnace_source)
    internal_inventory_copy(original_entity, cloned_entity, defines.inventory.furnace_result)
    if (original_entity.get_module_inventory()) then
        local working_inventory = original_entity.get_module_inventory()
        for k=1,#working_inventory do
            if (working_inventory[k].valid_for_read) then
                cloned_entity.insert(working_inventory[k])
            end
        end
    end
    if (original_entity.get_fuel_inventory()) then
        local working_inventory = original_entity.get_fuel_inventory()
        for k=1,#working_inventory do
            if (working_inventory[k].valid_for_read) then
                cloned_entity.insert(working_inventory[k])
            end
        end
    end
    if (#original_entity.fluidbox >= 1) then
        for x=1, #original_entity.fluidbox do
            cloned_entity.fluidbox[x] = original_entity.fluidbox[x]
        end
    end
end

function copy_progress_bars(original_entity, cloned_entity)
    if has_value(original_entity.type, {"rocket-silo", "assembling-machine", "furnace"}) then
        cloned_entity.crafting_progress = original_entity.crafting_progress
        if (original_entity.type == "rocket-silo") then
            cloned_entity.rocket_parts = original_entity.rocket_parts
        end
    end
    if (original_entity.burner) then
        if (original_entity.burner.currently_burning) then
            cloned_entity.burner.currently_burning = original_entity.burner.currently_burning
            cloned_entity.burner.remaining_burning_fuel = original_entity.burner.remaining_burning_fuel
        end
    end
end

function copy_resources (original_entity, cloned_entity)
    local surface = original_entity.surface
    if (original_entity.type == "mining-drill") then
        if (original_entity.mining_target) then
            local resource = original_entity.mining_target
            for key, resource_to_clear in pairs(surface.find_entities_filtered({type = "resource", position={cloned_entity.position.x, cloned_entity.position.y}})) do
                resource_to_clear.destroy()
            end
            local cloned_resource = surface.create_entity({name = resource.name, position = cloned_entity.position, force = "neutral", amount = resource.amount})
            --[[If we're not an infinite resource, then go ahead and ensure we have enough material--]]
            if (resource.initial_amount) then
                local newresource = surface.find_entity(resource.name, cloned_entity.position)
                newresource.initial_amount = resource.initial_amount
            else
                resource.amount = 10000000
                cloned_resource.amount = 10000000
            end
        end
    end
end

function copy_circuit_connections (original_entity, cloned_entity)
    local surface = original_entity.surface
    if (original_entity.circuit_connection_definitions) then
        for x=1, #original_entity.circuit_connection_definitions do
            local targetent = original_entity.circuit_connection_definitions[x].target_entity
            local offset_x = (original_entity.position.x - targetent.position.x)
            local offset_y = (original_entity.position.y - targetent.position.y)
            if (surface.find_entity(targetent.name, {(cloned_entity.position.x - offset_x), (cloned_entity.position.y - offset_y)})) then
                local targetnewent = surface.find_entity(targetent.name, {(cloned_entity.position.x - offset_x), (cloned_entity.position.y - offset_y)})
                cloned_entity.connect_neighbour({target_entity = targetnewent, wire=original_entity.circuit_connection_definitions[x].wire, source_circuit_id=original_entity.circuit_connection_definitions[x].source_circuit_id, target_circuit_id=original_entity.circuit_connection_definitions[x].target_circuit_id})
            end
        end
    end
end

function copy_train (original_entity, cloned_entity)
    if (original_entity.train) then
        cloned_entity.disconnect_rolling_stock(defines.rail_direction.front)
        cloned_entity.disconnect_rolling_stock(defines.rail_direction.back)
        cloned_entity.train.schedule = original_entity.train.schedule
        if (original_entity.orientation <= 0.5) then
            if (original_entity.orientation ~= 0) then
                cloned_entity.rotate()
            end
        end
        cloned_entity.connect_rolling_stock(defines.rail_direction.front)
        cloned_entity.connect_rolling_stock(defines.rail_direction.back)
        cloned_entity.copy_settings(original_entity)
        cloned_entity.train.manual_mode = original_entity.train.manual_mode
    end
end

function copy_transport_line_contents (original_entity, cloned_entity)
    local transport_lines_present = 0
    if (original_entity.type == "splitter") then
        transport_lines_present = 8
    end
    if (original_entity.type == "underground-belt") then
        transport_lines_present = 4
        if (original_entity.belt_to_ground_type == "input") then
            if (original_entity.direction == 2 or original_entity.direction == 4) then
                if (original_entity.neighbours) then
                    local offset_x = original_entity.neighbours.position.x - original_entity.position.x
                    local offset_y = original_entity.neighbours.position.y - original_entity.position.y
                    if not (cloned_entity.neighbours) then
                        cloned_entity.surface.create_entity({name = cloned_entity.name, position = {cloned_entity.position.x + offset_x, cloned_entity.position.y + offset_y}, force = cloned_entity.force, direction = cloned_entity.direction, type = "output"})
                    end
                end
            end
        end
    end
    if (original_entity.type == "transport-belt") then
        transport_lines_present = 2
    end
    for x = 1, transport_lines_present do
        local current_position = 0
        for item_name, item_amount in pairs(original_entity.get_transport_line(x).get_contents()) do
            for _=1, item_amount do
                cloned_entity.get_transport_line(x).insert_at(current_position,{name = item_name})
                current_position = current_position + 0.28125
            end
        end
    end
end

function clean_entity_pool (entity_pool, tiles_to_paste_x, tiles_to_paste_y)
    local flag_rail_found = false
    for key, ent in pairs(entity_pool) do
        if has_value(ent.type, {"straight-rail", "curved-rail"}) then
            flag_rail_found = true
        end
        if has_value(ent.type, {"player", "entity-ghost", "tile-ghost"}) then
            entity_pool[key] = nil
        else
            if (ent.valid) then
                if not has_value(ent.type, {"decider-combinator", "arithmetic-combinator"}) then
                    ent.active = false
                end
            end
        end
    end
    if (flag_rail_found) then
        if (tiles_to_paste_x ~= 0) then
            tiles_to_paste_x = correct_for_rail_grid(tiles_to_paste_x)
        end
        if (tiles_to_paste_y ~= 0) then
            tiles_to_paste_y = correct_for_rail_grid(tiles_to_paste_y)
        end
    end
    return tiles_to_paste_x, tiles_to_paste_y
end

local function ensure_entity_pool_valid(pool)
    for key,ent in pairs(pool) do
        if not (ent.valid) then
            pool[key] = nil
        end
    end
end

local function find_charting_coordinates(entity_pool)
    local left, right
    for key,ent in pairs (entity_pool) do
        if not (left) then
            left = ent.position.x
            right = ent.position.x
        end
        if (left > ent.position.x) then
            left = ent.position.x
        end
        if (right < ent.position.x) then
            right = ent.position.x
        end
    end
    return left, right
end

local function ensure_inserter_stack_valid(pool)
    for key,ent in pairs(pool) do
        if not (ent.held_stack.valid) then
            pool[key] = nil
        end
    end
end


function clone_region_pre(source_left, source_top, source_right, source_bottom, times_to_paste, tiles_to_paste_x, tiles_to_paste_y, player)
    local surface = player.surface
    local start_tick = game.tick + 1
    local low_priority_entities = {"beacon", "locomotive", "cargo-wagon", "logistic-robot", "construction-robot", "fluid-wagon"}
    local start_tile_x, start_tile_y = 0
    if (tiles_to_paste_x > 0) then
        --[[Pasting to the east]]
        start_tile_x = source_left
    else
        --[[Pasting to the west]]
        start_tile_x = source_right
    end
    if (tiles_to_paste_y > 0) then
        --[[Pasting to the south]]
        start_tile_y = source_top
    else
        --[[Pasting to the north]]
        start_tile_y = source_bottom
    end
    local entity_pool = surface.find_entities_filtered({area={{source_left, source_top}, {source_right, source_bottom}}, force="player"})
    tiles_to_paste_x, tiles_to_paste_y = clean_entity_pool(entity_pool, tiles_to_paste_x, tiles_to_paste_y)
    script.on_event(defines.events.on_tick, function(event)
        on_tick_behavior(source_left, source_top, source_right, source_bottom, times_to_paste, tiles_to_paste_x, tiles_to_paste_y, entity_pool, low_priority_entities, start_tile_x, start_tile_y, start_tick, player, surface)
    end)
end

function on_tick_behavior(source_left, source_top, source_right, source_bottom, times_to_paste, tiles_to_paste_x, tiles_to_paste_y, entity_pool, low_priority_entities, start_tile_x, start_tile_y, start_tick, player, surface)
    local ticks_per_paste = 2
    local create_entity_values = {}
    for current_paste = 1, times_to_paste do
        if (game.tick == (start_tick + (current_paste * ticks_per_paste))) then
            if (true) then
                local top, bottom = 0
                local left, right = 0
                if (tiles_to_paste_y ~= 0) then
                    top = start_tile_y + tiles_to_paste_y * (current_paste + 1)
                    bottom = start_tile_y + tiles_to_paste_y * (current_paste)
                else
                    top = source_top
                    bottom = source_bottom
                end
                if (tiles_to_paste_x ~= 0) then
                    left = start_tile_x + tiles_to_paste_x * (current_paste + 1)
                    right = start_tile_x + tiles_to_paste_x * (current_paste)
                else
                    left = source_left
                    right = source_right
                end
                left, right = swap_to_fix_pairs(left, right)
                top, bottom = swap_to_fix_pairs(top, bottom)
                clean_paste_area(surface, left, top, right, bottom)
            end
            ensure_entity_pool_valid(entity_pool)
            for key, ent in pairs(entity_pool) do
                local x_offset = ent.position.x + tiles_to_paste_x*current_paste
                local y_offset = ent.position.y + tiles_to_paste_y*current_paste
                create_entity_values = {name = ent.name, position={x_offset, y_offset}, direction=ent.direction, force="player"}
                if not has_value(ent.type, low_priority_entities) then
                    if (ent.type == "underground-belt") then
                        create_entity_values.type = ent.belt_to_ground_type
                    end
                    local newent = surface.create_entity(create_entity_values)
                    if not (newent) then
                        newent = surface.find_entity(ent.name, {x_offset, y_offset})
                    end
                    if not (newent) then
                        player.print("Something went horribly wrong, we tried to copy a " .. ent.name .. " but failed!")
                    else
                        copy_entity(ent, newent)
                        newent = nil
                    end
                end
            end
        end
        if (game.tick == (start_tick + (current_paste * ticks_per_paste) + 1)) then
            for key, ent in pairs(entity_pool) do
                local x_offset = ent.position.x + tiles_to_paste_x*current_paste
                local y_offset = ent.position.y + tiles_to_paste_y*current_paste
                create_entity_values = {name = ent.name, position={x_offset, y_offset}, direction=ent.direction, force="player"}
                if has_value(ent.type, low_priority_entities) then
                    local newent = surface.create_entity(create_entity_values)
                    if not (newent) then
                        newent = surface.find_entity(ent.name, {x_offset, y_offset})
                    end
                    if not (newent) then
                        player.print("Something went horribly wrong, we tried to copy a " .. ent.name .. " but failed!")
                    else
                        copy_entity(ent, newent)
                        newent = nil
                    end
                end
            end
            if (true) then
                local top, bottom = 0
                local left, right = 0
                if (tiles_to_paste_y ~= 0) then
                    top = start_tile_y + tiles_to_paste_y * (current_paste + 1)
                    bottom = start_tile_y + tiles_to_paste_y * (current_paste) - 0.1
                else
                    top = source_top
                    bottom = source_bottom - 0.1
                end
                if (tiles_to_paste_x ~= 0) then
                    left = start_tile_x + tiles_to_paste_x * (current_paste + 1)
                    right = start_tile_x + tiles_to_paste_x * (current_paste) - 0.1
                else
                    left = source_left
                    right = source_right - 0.1
                end
                left, right = swap_to_fix_pairs(left, right)
                top, bottom = swap_to_fix_pairs(top, bottom)
                player.force.chart(surface, {{left, top}, {right, bottom}})
            end
        end
        if (game.tick == (start_tick + ((times_to_paste + 1)*ticks_per_paste) + 600 )) then
            for key, ent in pairs(entity_pool) do
                if (ent.valid) then
                    ent.active = true
                end
            end
            script.on_event(defines.events.on_tick, nil)
        end
    end
end
