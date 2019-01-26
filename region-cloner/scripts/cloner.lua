require("scripts.common")

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
    second_try_destroy_entities = nil
end

function copy_entity (original_entity, cloned_entity, surface)
    copy_properties(original_entity, cloned_entity)
    copy_inventories_and_fluid(original_entity, cloned_entity)
    copy_progress_bars(original_entity, cloned_entity)
    copy_resources(original_entity, cloned_entity, surface)
    copy_circuit_connections(original_entity, cloned_entity, surface)
    copy_train(original_entity, cloned_entity)
    --[[updating connections probably doesn't do anything, since anything that could be affected by a beacon already exists by the time beacons are cloned--]]
    --[[It also updates miners so they see any newly placed ore underneath them, Ill leave it since it probably wont break anything]]
    cloned_entity.update_connections()
    copy_transport_line_contents(original_entity, cloned_entity, surface)
end

function copy_properties (original_entity, cloned_entity)
    if (original_entity.type == "loader") then
        cloned_entity.loader_type = original_entity.loader_type
    end
    cloned_entity.copy_settings(original_entity)
    cloned_entity.orientation = original_entity.orientation
    cloned_entity.direction = original_entity.direction
    if (original_entity.temperature) then
        cloned_entity.temperature = original_entity.temperature
    end
end

--[[TODO actually pass the inventories which ought to be copied]]
local function internal_inventory_copy(original_entity, cloned_entity, INV_DEFINE)
    if (original_entity.get_inventory(INV_DEFINE)) then
        local working_inventory = original_entity.get_inventory(INV_DEFINE)
        for k=1, #working_inventory do
            if (working_inventory[k].valid_for_read) then
                cloned_entity.get_inventory(INV_DEFINE).insert(working_inventory[k])
            end
        end
        working_inventory = nil
    end
end

function copy_inventories_and_fluid (original_entity, cloned_entity)
    --[[Defines are not strict which means certain entities have inventory defines which make no sense]]
    if not has_value(original_entity.type, HAS_DEFINES_INVENTORY_CHEST_BUT_SHOULDNT_TYPES) then
        --[[Please wube why is this necessary?]]
        internal_inventory_copy(original_entity, cloned_entity, defines.inventory.chest)
    end
    internal_inventory_copy(original_entity, cloned_entity, defines.inventory.rocket_silo_result)
    --[[Furnace source and result here copy assembling machine inventories as well]]
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

function copy_resources (original_entity, cloned_entity, surface)
    if (original_entity.type == "mining-drill") then
        if (original_entity.mining_target) then
            local resource = original_entity.mining_target
            for key, resource_to_clear in pairs(surface.find_entities_filtered({type = "resource", position={cloned_entity.position.x, cloned_entity.position.y}})) do
                resource_to_clear.destroy()
            end
            local cloned_resource = surface.create_entity({name = resource.name, position = cloned_entity.position, force = "neutral", amount = resource.amount})
            --[[If we're not an infinite resource, then go ahead and ensure we have enough material--]]
            if (resource.initial_amount) then
                cloned_resource.initial_amount = resource.initial_amount
            else
                resource.amount = 10000000
                cloned_resource.amount = 10000000
            end
            resource = nil
            cloned_resource = nil
        end
    end
end

function copy_circuit_connections (original_entity, cloned_entity, surface)
    if (original_entity.circuit_connection_definitions) then
        for x=1, #original_entity.circuit_connection_definitions do
            local targetent = original_entity.circuit_connection_definitions[x].target_entity
            local offset_x = (original_entity.position.x - targetent.position.x)
            local offset_y = (original_entity.position.y - targetent.position.y)
            local targetnewent = surface.find_entity(targetent.name, {(cloned_entity.position.x - offset_x), (cloned_entity.position.y - offset_y)})
            if (targetnewent) then
                cloned_entity.connect_neighbour({target_entity = targetnewent, wire=original_entity.circuit_connection_definitions[x].wire, source_circuit_id=original_entity.circuit_connection_definitions[x].source_circuit_id, target_circuit_id=original_entity.circuit_connection_definitions[x].target_circuit_id})
            end
            targetent = nil
            offset_x = nil
            offset_y = nil
            targetnewent = nil
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

function copy_transport_line_contents (original_entity, cloned_entity, surface)
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
                        surface.create_entity({name = cloned_entity.name, position = {cloned_entity.position.x + offset_x, cloned_entity.position.y + offset_y}, force = cloned_entity.force, direction = cloned_entity.direction, type = "output"})
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

local function ensure_entity_pool_valid(player, pool)
    for key,ent in pairs(pool) do
        if not (ent.valid) then
            player.print("pool member invalid")
            pool[key] = nil
        end
    end
end

local function check_for_positions_which_could_contain_both_straight_and_curved_rail_then_return_the_entity_to_remove(surface, ent, x_magnitude, y_magnitude, times_called)
    local flag_straight, flag_curved = false, false
    local possible_entity_to_destroy = {}
    for _, chk in pairs(surface.find_entities_filtered{name={"straight-rail", "curved-rail"}, force="player", position={ent.position.x + x_magnitude, ent.position.y + y_magnitude}}) do
        if (chk.name == "straight-rail") then
            flag_straight = true
            possible_entity_to_destroy = chk
        end
        if (chk.name == "curved-rail") then
            flag_curved = true
        end
    end
    if (flag_straight and flag_curved) then
        return possible_entity_to_destroy
    else
        flag_straight, flag_curved = false, false
    end
    if (times_called > 2) then
        check_for_positions_which_could_contain_both_straight_and_curved_rail_then_return_the_entity_to_remove(surface, ent, -1 * x_magnitude, -1 * y_magnitude, times_called + 1)
    else
        return nil
    end
end

local function make_the_rail_system_condusive_to_pasting_our_rolling_stock(player, surface, ent, x_offset, y_offset)
    local entity_to_recreate = {}
    if not has_value(ent.orientation, {0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875}) then
        --[[If we are on a curve]]
        --[[Find a straight rail at the offset]]
        local possible_straight_rail_piece = surface.find_entity("straight-rail", {x_offset, y_offset})
        if (possible_straight_rail_piece) then
            if has_value(possible_straight_rail_piece.direction, {1, 3, 5, 7}) then
                possible_straight_rail_piece = nil
            end
        end
        if not (possible_straight_rail_piece) then
            --[[It is possible to be inbetween two straight rail pieces and fail to find any]]
            possible_straight_rail_piece = surface.find_entity("straight-rail", {round_to_rail_grid_midpoint(x_offset), round_to_rail_grid_midpoint(y_offset)})
            if (possible_straight_rail_piece) then
                if has_value(possible_straight_rail_piece.direction, {1, 3, 5, 7}) then
                    possible_straight_rail_piece = nil
                end
            end
        end
        if (possible_straight_rail_piece) then
            local possible_curved_rail = surface.find_entity("curved-rail", possible_straight_rail_piece.position)
            --[[If we find the straight rail. try to find a curved rail at straight rail's position]]
            if (possible_curved_rail) then
                --[[Breaks if we're on a S curve but over the curved rail piece we're not on!]]
                --[[If we find the curved rail, then temporarily delete the straight rail, and then copy the rolling stock]]
                entity_to_recreate.position = possible_straight_rail_piece.position
                entity_to_recreate.direction = possible_straight_rail_piece.direction
                possible_straight_rail_piece.destroy()
                return entity_to_recreate
            else
                --[[If we could not find the curved rail at the same position as our straight rail, that means we are just barely on the curved rail, or we are on a diagonal section]]
                if has_value(possible_straight_rail_piece.direction, {1, 3, 5, 7}) then
                    --[[We are on a diagonal bit, don't do anything here (TODO maybe change this?)]]
                    --[[We would be mostly on diagonal rails, but not fully since if we were fully we never would have made it here. A tiny sliver would reside on a curved rail.]]
                else
                    --[[determine if we are close to horizontal or vertical]]
                    local approximate_rotation_point = round(ent.orientation * 4) % 4
                    local x, y = 0, 0
                    if has_value(approximate_rotation_point, {0, 2}) then
                        y = 2
                        --[[We are approximately vertical]]
                    end
                    if has_value(approximate_rotation_point, {1, 3}) then
                        --[[We are approximately horizontal]]
                        x = 2
                    end
                    local get_rid_of_this = check_for_positions_which_could_contain_both_straight_and_curved_rail_then_return_the_entity_to_remove(surface, possible_straight_rail_piece, x, y, 1)
                    if (get_rid_of_this) then
                        entity_to_recreate.position = get_rid_of_this.position
                        entity_to_recreate.direction = get_rid_of_this.direction
                        get_rid_of_this.destroy()
                        return entity_to_recreate
                    else
                        --[[After all that we still failed? I give up]]
                    end
                end
            end
        else
            --[[If we did not find a straight rail then we are fully on the curved track. Let's try to do the offset method.]]
            local curve_track = surface.find_entity("curved-rail", ent.position)
            if (curve_track) then
                local x_offset_bonus, y_offset_bonus = calculate_offsets(curve_track)
                x_offset = x_offset + x_offset_bonus
                y_offset = y_offset + y_offset_bonus
            end
        end
    end
end

local function find_additional_entities_which_may_break_stuff_and_insert_them_into_a_table(surface, entity_to_recreate)
    local entity_pool = {}
    table.insert(entity_pool, entity_to_recreate)
    local search_x, search_y = 0, 0
    if (entity_to_recreate.direction == 0) then
        search_y = 2
    end
    if (entity_to_recreate.direction == 2) then
        search_x = 2
    end
    for _, ent in pairs(surface.find_entities_filtered{name="straight-rail", position = {entity_to_recreate.position.x + search_x, entity_to_recreate.position.y + search_y}}) do
        if next(surface.find_entities_filtered{name="curved-rail", position=ent.position}) then
            local construct = {}
            construct.position = ent.position
            construct.direction = ent.direction
            table.insert(entity_pool, construct)
            ent.destroy()
        end
    end
    for _, ent in pairs(surface.find_entities_filtered{name="straight-rail", position = {entity_to_recreate.position.x - search_x, entity_to_recreate.position.y - search_y}}) do
        if next(surface.find_entities_filtered{name="curved-rail", position=ent.position}) then
            local construct = {}
            construct.position = ent.position
            construct.direction = ent.direction
            table.insert(entity_pool, construct)
            ent.destroy()
        end
    end
    return entity_pool
end

local function convert_bounding_box_to_current_paste_region(tpx, tpy, current_paste, bounding_box)
    local modified_box = {}
    local left_top = {}
    local right_bottom = {}
    left_top["x"] = bounding_box.left_top.x + (tpx * current_paste)
    left_top["y"] = bounding_box.left_top.y + (tpy * current_paste)
    --[[Subtract 0.01 tiles off of the returned bounding_box because it will chart the next chunk over if bounding_box is at the tile border]]
    right_bottom["x"] = bounding_box.right_bottom.x + (tpx * current_paste) - 0.01
    right_bottom["y"] = bounding_box.right_bottom.y + (tpy * current_paste) - 0.01
    modified_box["left_top"] = left_top
    modified_box["right_bottom"] = right_bottom
    return modified_box
end

local function smart_chart(player, tpx, tpy, current_paste, bounding_box)
    local new_box = convert_bounding_box_to_current_paste_region(tpx, tpy, current_paste, bounding_box)
    player.force.chart(player.surface, new_box)
end

local function clean_paste_area(player, tpx, tpy, current_paste, bounding_box)
    local new_box = convert_bounding_box_to_current_paste_region(tpx, tpy, current_paste, bounding_box)
    for _, ent in pairs(player.surface.find_entities_filtered{area=new_box, name="player", invert=true}) do
        --[[Don't delete the player's character]]
        ent.destroy()
    end
end

function calculate_offsets(ent)
    local offset_factor = 0.99
    local compare = ent.direction
    if has_value(compare, {0, 5}) then
        return -1 * offset_factor, 0
    end
    if has_value(compare, {1, 4}) then
        return offset_factor, 0
    end
    if has_value(compare, {2, 7}) then
        return 0, -1 * offset_factor
    end
    if has_value(compare, {3, 6}) then
        return 0, offset_factor
    end
end

function clone_entity_pool(player, entity_pool, tpx, tpy, current_paste, times_to_paste, bounding_box, flag_complete)
    local create_entity_values = {}
    local surface = player.surface
    if not (current_paste > times_to_paste) then
        clean_paste_area(player, tpx, tpy, current_paste, bounding_box)
    end
    ensure_entity_pool_valid(player, entity_pool)
    for _,ent in pairs(entity_pool) do
        if not has_value(ent.type, low_priority_entities) then
            if not (current_paste > times_to_paste) then
                --[[We will run over by 1 on current paste, because we need to copy the low priority entities]]
                --[[We don't want to copy any more normal priority entities on the last paste]]
                local x_offset = ent.position.x + tpx * current_paste
                local y_offset = ent.position.y + tpy * current_paste
                create_entity_values = {name = ent.name, position={x_offset, y_offset}, direction=ent.direction, force="player"}
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
                    copy_entity(ent, newent, surface)
                    newent = nil
                end
            end
        end
        if has_value(ent.type, low_priority_entities) then
            if not (current_paste == 1) then
                local entity_pool_to_recreate = {}
                local x_offset = ent.position.x + tpx * (current_paste - 1)
                local y_offset = ent.position.y + tpy * (current_paste - 1)
                if has_value(ent.type, {"locomotive", "cargo-wagon", "fluid-wagon"}) then
                    if not has_value(ent.orientation, {0, 0.25, 0.5, 0.75}) then
                        local entity_to_recreate = {}
                        entity_to_recreate = make_the_rail_system_condusive_to_pasting_our_rolling_stock(player, surface, ent, x_offset, y_offset)
                        if (entity_to_recreate) then
                            entity_pool_to_recreate = find_additional_entities_which_may_break_stuff_and_insert_them_into_a_table(surface, entity_to_recreate)
                        end
                    end
                end

                create_entity_values = {name = ent.name, position={x_offset, y_offset}, direction=ent.direction, force="player"}

                local newent = surface.create_entity(create_entity_values)
                if not (newent) then
                    newent = surface.find_entity(ent.name, {x_offset, y_offset})
                end
                if not (newent) then
                    player.print("Something went horribly wrong, we tried to copy a " .. ent.name .. " but failed!")
                else
                    copy_entity(ent, newent, surface)
                    newent = nil
                end
                if (entity_pool_to_recreate) then
                    for _, virtual_ent in pairs(entity_pool_to_recreate) do
                        --[[These "entitites" only have position and direction]]
                        surface.create_entity({name="straight-rail", position={virtual_ent.position.x, virtual_ent.position.y}, force="player", direction=virtual_ent.direction})
                    end
                    entity_to_recreate = nil
                    entity_pool_to_recreate = nil
                end
            end
        end
    end
    smart_chart(player, tpx, tpy, (current_paste - 1), bounding_box)
    --[[Chart after the low priority entities are created, subtract 1 for the penalty low_priority_entities have]]
    if ((current_paste) > times_to_paste) then
        --[[Now we have finshed pasting]]
        return current_paste, true
    end
    return (current_paste + 1), false
end
