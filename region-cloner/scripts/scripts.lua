require("scripts.cloner")
require("scripts.common")
require("scripts.job")
require("scripts.correct_cloned_entities_in_event")

function decode_direction_for_unusual_collision_box(direction, type)
    local offset_left, offset_top, offset_right, offset_bottom = 4, 4, 4, 4
    if type == "curved-rail" then
        if has_value(direction, {0, 5}) then
            offset_right = 2
        end
        if has_value(direction, {1, 4}) then
            offset_left = 2
        end
        if has_value(direction, {2, 7}) then
            offset_bottom = 2
        end
        if has_value(direction, {3, 6}) then
            offset_top = 2
        end
    end
    return offset_left, offset_top, offset_right, offset_bottom
end

local function swap_values(first, second)
    return second, first
end

function convert_entity_collision_box_to_rotated_aware(ent)
    local box = ent.prototype.collision_box
    local ltx, lty, rbx, rby = box.left_top.x, box.left_top.y, box.right_bottom.x, box.right_bottom.y
    if (ent.supports_direction) then
        if (box.left_top.x ~= box.left_top.y) then
            if (box.right_bottom.x ~= box.right_bottom.y) then
                --[[Entity is not a square collision box]]
                if has_value(ent.direction, {2, 6}) then
                    --[[Rotate by swapping x and y coordinates]]
                    ltx, lty = swap_values(ltx, lty)
                    rbx, rby = swap_values(rbx, rby)
                end
            end
        end
    else
        if (ent.orientation) then
            if has_value(ent.orientation, {0.25, 0.75}) then
                ltx, lty = swap_values(ltx, lty)
                rbx, rby = swap_values(rbx, rby)
            end
        end
    end
    return ltx, lty, rbx, rby
end

function restrict_selection_area_to_entities(left, top, right, bottom, player)
    local first_ent = true
    --secondary_collision_box now exists, this can be done better.
    local problematic_collision_box_entity_types = {"curved-rail"}
    local new_left, new_right, new_top, new_bottom = 0
    left, right = swap_to_fix_pairs(left, right)
    top, bottom = swap_to_fix_pairs(top, bottom)
    for _, ent in pairs(player.surface.find_entities_filtered{area={{left, top},{right,bottom}}, force="player"}) do
        if not is_ignored_entity_type(ent.type) then
            local unusual_collision_box_factor_left, unusual_collision_box_factor_top, unusual_collision_box_factor_right, unusual_collision_box_factor_bottom = 0, 0, 0, 0
            local ltx, lty, rbx, rby = convert_entity_collision_box_to_rotated_aware(ent)
            if has_value(ent.type, problematic_collision_box_entity_types) then
                unusual_collision_box_factor_left, unusual_collision_box_factor_top, unusual_collision_box_factor_right, unusual_collision_box_factor_bottom = decode_direction_for_unusual_collision_box(ent.direction, ent.type)
                ltx, lty, rbx, rby = 0, 0, 0, 0
            end
            local compare_left = math.floor(ent.position.x + ltx - unusual_collision_box_factor_left)
            local compare_top = math.floor(ent.position.y + lty - unusual_collision_box_factor_top)
            local compare_right = math.ceil(ent.position.x + rbx + unusual_collision_box_factor_right)
            local compare_bottom = math.ceil(ent.position.y + rby + unusual_collision_box_factor_bottom)
            if (first_ent) then
                first_ent = false
                new_left = compare_left
                new_top = compare_top
                new_right = compare_right
                new_bottom = compare_bottom
            end
            if (compare_left < new_left) then
                new_left = compare_left
            end
            if (compare_top < new_top) then
                new_top = compare_top
            end
            if (compare_right > new_right) then
                new_right = compare_right
            end
            if (compare_bottom > new_bottom) then
                new_bottom = compare_bottom
            end
        end
    end
    if not (new_left and new_top and new_right and new_bottom) then
        player.print("No player entites were found in the selection area, could not shrink the selection area!")
        return left, top, right, bottom
    end
    return new_left, new_top, new_right, new_bottom
end

function validate_coordinates_and_update_view(player, restrict_area_bool)
    local frame_flow = mod_gui.get_frame_flow(player)
    local current_view = frame_flow["region-cloner_control-window"]["region-cloner_coordinate-table"]
    local old_left = tonumber(current_view["left_top_x"].text)
    local old_top = tonumber(current_view["left_top_y"].text)
    local old_right = tonumber(current_view["right_bottom_x"].text)
    local old_bottom = tonumber(current_view["right_bottom_y"].text)
    if (old_left and old_top and old_bottom and old_right) then
        if (old_left == old_right or old_top == old_bottom) then
            player.print("You have selected a bounding box with 0 height/width!")
            return false
        end
        local new_left, new_top, new_right, new_bottom = old_left, old_top, old_right, old_bottom
        if (restrict_area_bool) then
            new_left, new_top, new_right, new_bottom = restrict_selection_area_to_entities(old_left, old_top, old_right, old_bottom, player)
        end
        current_view["left_top_x"].text = new_left
        current_view["left_top_y"].text = new_top
        current_view["right_bottom_x"].text = new_right
        current_view["right_bottom_y"].text = new_bottom
        return true
    else
        --No longer needed with numeric text field GUIs
        player.print("A coordinate is not a number!")
        return false
    end
end

function validate_player_copy_paste_settings(player)
    local frame_flow = mod_gui.get_frame_flow(player)
    if not (validate_coordinates_and_update_view(player, false)) then
        return false
    end
    local top_gui = frame_flow["region-cloner_control-window"]
    local direction_to_copy = top_gui["region-cloner_drop_down_table"]["region-cloner_direction-to-copy"].selected_index
    local times_to_paste = tonumber(top_gui["region-cloner_drop_down_table"]["number_of_copies"].text)
    if (times_to_paste) then
        if (times_to_paste < 1) then
            player.print("Number of copies is less than 1!")
            return false
        end
    else
        player.print("Number of copies is not a number!")
        return false
    end
    if not (direction_to_copy) then
        player.print("Somehow your direction to paste is not valid!")
    end
    local advanced_settings_gui = frame_flow[GUI_ELEMENT_PREFIX .. "advanced_view_pane"]
    local custom_tile_paste_length_table = advanced_settings_gui[GUI_ELEMENT_PREFIX .. "advanced_tile_paste_override_table"]
    if (custom_tile_paste_length_table[GUI_ELEMENT_PREFIX .. "advanced_tile_paste_override_checkbox"].state == true) then
        --[[
        We don't care what these are if the box is not checked
        ]]
        local tiles_to_paste_x = tonumber(custom_tile_paste_length_table[GUI_ELEMENT_PREFIX .. "advanced_tile_paste_x"].text)
        local tiles_to_paste_y = tonumber(custom_tile_paste_length_table[GUI_ELEMENT_PREFIX .. "advanced_tile_paste_y"].text)
        if (tiles_to_paste_x and tiles_to_paste_y) then
            if (tiles_to_paste_x == 0 and tiles_to_paste_y == 0) then
                player.print("You selected custom tile paste lengths but they're both 0!")
                return false
            end
        end
    end
    return true
end

local function decode_direction_to_copy(direction_to_copy)
    local tile_paste_direction_x, tile_paste_direction_y = 0, 0
    if (direction_to_copy == 1) then
        tile_paste_direction_y = -1
    elseif (direction_to_copy == 2) then
        tile_paste_direction_x = 1
    elseif (direction_to_copy == 3) then
        tile_paste_direction_y = 1
    elseif (direction_to_copy == 4) then
        tile_paste_direction_x = -1
    end
    return tile_paste_direction_x, tile_paste_direction_y
end

local function convert_bounding_box_to_paste_region(vector, bounding_box)
    local modified_box = {}
    local left_top = {}
    local right_bottom = {}
    left_top["x"] = bounding_box.left_top.x + vector.x
    left_top["y"] = bounding_box.left_top.y + vector.y
    --[[Subtract 0.01 tiles off of the returned bounding_box because it will spill into the next chunk tile]]
    right_bottom["x"] = bounding_box.right_bottom.x + vector.x - 0.01
    right_bottom["y"] = bounding_box.right_bottom.y + vector.y - 0.01
    modified_box["left_top"] = left_top
    modified_box["right_bottom"] = right_bottom
    return modified_box
end

local function clear_paste_area(tpx, tpy, current_paste, bounding_box, forces_to_clear, surface, entity_pool)
    local new_box = convert_bounding_box_to_paste_region({x = tpx * current_paste, y = tpy * current_paste}, bounding_box)
    local second_try_destroy_entities = {}
    local possible_entities_to_destroy = surface.find_entities_filtered{area=new_box, force=forces_to_clear}
    if current_paste == 1 then
        for key,found_ent in pairs (possible_entities_to_destroy) do
            if (found_ent.valid) then
                for _,ent in pairs(entity_pool) do
                    if (found_ent == ent) then
                        --[[If any entity we find in the possible area to destroy entities is part of the set we intend to clone from, dont destroy that entity.]]
                        possible_entities_to_destroy[key] = nil
                    end
                end
            end
        end
    end
    for _, ent in pairs(possible_entities_to_destroy) do
        if (ent.valid) then
            --[[Make sure we check valid ents because if you destroy a rocket silo with a rocket theres a chance that the rocket itself becomes invalid.]]
            if not is_ignored_entity_type(ent.type) then
                --[[Not sure why clear_items_inside() is needed anymore if it is? Maybe had something to do with items on a belt or performance reasons?]]
                ent.clear_items_inside()
                if not (ent.can_be_destroyed()) then
                    --[[Tracks with a train on them can't be destroyed, save them and try again at the end]]
                    table.insert(second_try_destroy_entities, ent)
                end
                ent.destroy()
            end
        end
    end
    for _, ent in pairs(second_try_destroy_entities) do
        if (ent.valid) then
            if not is_ignored_entity_type(ent.type) then
                ent.destroy()
            end
        end
    end
end

local function validate_entity_pool(entity_pool)
    for key, ent in pairs(entity_pool) do
        if not (ent.valid) then
            game.print("An entity pool member was invalid. You probably pasted over the source paste area.")
            entity_pool[key] = nil
        end
    end
end

function issue_copy_paste(player)
    if (debug_logging) then
        log("entering issue_copy_paste()")
    end
    local job = job_create(player)
    --[[Clearing paste area if setting is set]]
    local forces_to_clear_paste_area = {"enemy"}
    if (job.clear_normal_entities) then
        table.insert(forces_to_clear_paste_area, "player")
    end
    if (job.clear_resource_entities) then
        table.insert(forces_to_clear_paste_area, "neutral")
    end
    for x=1, job.times_to_paste do
        clear_paste_area(job.tiles_to_paste_x, job.tiles_to_paste_y, x, job.bounding_box, forces_to_clear_paste_area, job.surface, job.entity_pool)
        validate_entity_pool(job.entity_pool)
        copy_entity_pool(job.player, job.entity_pool, {x = job.tiles_to_paste_x * x, y = job.tiles_to_paste_y * x}, job.surface, job.force)
    end
    --[[Set power of original entity pool combinators to 0 to delay them by 1 tick.]]
    for _,ent in pairs(job.entity_pool) do
        if is_nonconst_combinator(ent.type) then
            ent.energy = 0
        end
    end
    if (debug_logging) then
        log("Finished issuing copy paste")
    end
end

function do_on_tick()
    script.on_event(defines.events.on_tick, function(event)
        if (global.combinators_to_destroy_in_next_tick) then
            if not next(global.combinators_to_destroy_in_next_tick) then
                global.do_on_tick = false
                script.on_event(defines.events.on_tick, nil)
            end
            for key,ent in pairs(global.combinators_to_destroy_in_next_tick) do
                if not (ent.valid) then
                    global.combinators_to_destroy_in_next_tick[key] = nil
                else
                    local signals = ent.get_circuit_network(defines.wire_type.red).signals
                    if (signals) then
                        ent.destroy()
                        global.combinators_to_destroy_in_next_tick[key] = nil
                    end
                end
            end
        end
    end)
end
