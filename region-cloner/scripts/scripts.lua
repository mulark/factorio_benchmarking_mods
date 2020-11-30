require("scripts.cloner")
require("scripts.common")
require("scripts.job")
require("scripts.correct_cloned_entities_in_event")

local mod_gui = require("mod-gui")

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

function restrict_selection_area_to_entities(box, chunk_align, player, respect_logistics)
    local first_ent = true
    --secondary_collision_box now exists, this can be done better.
    --local problematic_collision_box_entity_types = {"curved-rail"}
    local new_left, new_right, new_top, new_bottom = 0
    local find_ent_params = {force="player"}
    if box.left_top.x == 0 and box.left_top.y == 0 and box.right_bottom.x == 0 and box.right_bottom.y == 0 then
        -- Cannot be true unless you're using a lite job or the restrict selection area button with all 0's
        -- Search an unrestricted area if this is the case.
    else
        find_ent_params.area = box
    end
    local temp_ent_holder = player.surface.find_entities_filtered(find_ent_params)
    for _, ent in pairs(temp_ent_holder) do
        if not is_ignored_entity_type(ent.type) then
            local unusual_collision_box_factor_left, unusual_collision_box_factor_top, unusual_collision_box_factor_right, unusual_collision_box_factor_bottom = 0, 0, 0, 0
            --ltx = left top x relative collision box coords
            local ltx, lty, rbx, rby = convert_entity_collision_box_to_rotated_aware(ent)
            if ent.type == "curved-rail" then
                unusual_collision_box_factor_left, unusual_collision_box_factor_top, unusual_collision_box_factor_right, unusual_collision_box_factor_bottom = decode_direction_for_unusual_collision_box(ent.direction, ent.type)
                ltx, lty, rbx, rby = 0, 0, 0, 0
            end
            if respect_logistics then
                if ent.logistic_cell then
                    local distance = ent.logistic_cell.logistic_radius
                    if distance > ltx then
                        ltx = -(distance)
                    end
                    if distance > lty then
                        lty = -(distance)
                    end
                    if distance > rbx then
                        rbx = distance + 1
                    end
                    if distance > rby then
                        rby = distance + 1
                    end
                end
            end
            local l = ent.position.x + ltx - unusual_collision_box_factor_left
            local t = ent.position.y + lty - unusual_collision_box_factor_top
            local r = ent.position.x + rbx + unusual_collision_box_factor_right
            local b = ent.position.y + rby + unusual_collision_box_factor_bottom
            local compare_left = math.floor(l)
            local compare_top = math.floor(t)
            local compare_right = math.ceil(r)
            local compare_bottom = math.ceil(b)
            if chunk_align then
                compare_left = math.floor(l/32) * 32
                compare_top = math.floor(t/32) * 32
                compare_right = math.ceil(r/32) * 32
                compare_bottom = math.ceil(b/32) * 32
            end
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
        player.print("No player entites were found in the selection area, could not determine a new selection area!")
        return construct_bounding_box(left, top, right, bottom)
    end
    return construct_bounding_box(new_left, new_top, new_right, new_bottom)
end

function validate_coordinates_and_update_view(player, restrict_area_bool)
    local frame_flow = mod_gui.get_frame_flow(player)
    local current_view = frame_flow["region-cloner_control-window"]["region-cloner_coordinate-table"]
    local old_left = tonumber(current_view["left_top_x"].text)
    local old_top = tonumber(current_view["left_top_y"].text)
    local old_right = tonumber(current_view["right_bottom_x"].text)
    local old_bottom = tonumber(current_view["right_bottom_y"].text)
    if (old_left and old_top and old_bottom and old_right) then
        local box = construct_safe_bounding_box(old_left, old_top, old_right, old_bottom)
        if (old_left == old_right or old_top == old_bottom) and not (old_top == 0 and old_left == 0 and old_right == 0 and old_bottom == 0) then
            player.print("You have selected a bounding box with 0 height/width!")
            return false
        end
        if (restrict_area_bool) then
            --Default don't chunk align when restricting area via gui button
            box = restrict_selection_area_to_entities(box, false, player, false)
        end
        if debug_logging then log(serpent.block(box)) end
        current_view["left_top_x"].text = tostring(box.left_top.x)
        current_view["left_top_y"].text = tostring(box.left_top.y)
        current_view["right_bottom_x"].text = tostring(box.right_bottom.x)
        current_view["right_bottom_y"].text = tostring(box.right_bottom.y)
        return true
    else
        --No longer needed with numeric text field GUIs
        player.print("A coordinate is not a number!")
    if debug_logging then
        log("entered validate_coordinates_and_update_view()")
    end
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
    if (debug_logging) then
        log("entered clear_paste_area()")
    end
    local new_box = convert_bounding_box_to_paste_region({x = tpx * current_paste, y = tpy * current_paste}, bounding_box)
    if debug_logging and tpx == 0 and tpy == 0 then
        game.print("You dingus!")
        return
    end
    local second_try_destroy_entities = {}
    local possible_entities_to_destroy = surface.find_entities_filtered{area=new_box, force=forces_to_clear}
    if current_paste == 1 then
        if (debug_logging) then
            log("first paste checks... ow?")
        end
        for key,found_ent in pairs (possible_entities_to_destroy) do
            if (found_ent.valid) then
                --TODO this is a hack for now
                if found_ent.type ~= "resource" then
                    for _,ent in pairs(entity_pool) do
                        if (found_ent == ent) then
                            --If any entity we find in the possible area to destroy entities is part of the set we intend to clone from, dont destroy that entity.
                            possible_entities_to_destroy[key] = nil
                        end
                    end
                end
            end
        end
    end
    if (debug_logging) then
        log("part 2")
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
    if (debug_logging) then
        log("finished clear_paste_area()")
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

function create_job_from_cmd(params)
    if (debug_logging) then
        log("creating a job from autoclone command")
    end
    local dir_to_copy_index = 1 --north default
    local times_to_paste = 1
    local chunk_align = false
    local respect_logistics = false
    if params.parameter then
        params.parameter = params.parameter .. " "
        for v in params.parameter:gmatch("%S+") do
            if tonumber(v) then
                times_to_paste = v
            end
            if has_value(string.lower(v),{"n","e","s","w"}) then
                if v == "n" then dir_to_copy_index = 1 end
                if v == "e" then dir_to_copy_index = 2 end
                if v == "s" then dir_to_copy_index = 3 end
                if v == "w" then dir_to_copy_index = 4 end
            end
            if has_value(string.lower(v), {"c"}) then
                chunk_align = true
            end
            if has_value(string.lower(v), {"r"}) then
              respect_logistics = true
            end
        end
    end
    local job = job_create_lite(times_to_paste, dir_to_copy_index, chunk_align, game.players[params.player_index], respect_logistics)
    run_job(job)
end

function issue_copy_paste(player)
    if (debug_logging) then
        log("entering issue_copy_paste()")
    end
    local job = job_create(player)
    run_job(job)
    if (debug_logging) then
        log("Finished issuing copy paste")
    end
end

function run_job(job)
    if job then
        local forces_to_clear_paste_area = {"enemy"}
        if (job.clear_normal_entities) then
            table.insert(forces_to_clear_paste_area, "player")
        end
        if (job.clear_resource_entities) then
            table.insert(forces_to_clear_paste_area, "neutral")
        end
        for x=1, job.times_to_paste do
            clear_paste_area(job.tiles_to_paste_x, job.tiles_to_paste_y, x, job.bounding_box, forces_to_clear_paste_area, job.surface, job.entity_pool)
            validate_entity_pool(job.high_priority_pool)
            validate_entity_pool(job.rolling_stock_pool)
            validate_entity_pool(job.entity_pool)
            validate_entity_pool(job.lite_entity_pool)
            -- High prio
            copy_entity_pool(job.player, job.high_priority_pool, {x = job.tiles_to_paste_x * x, y = job.tiles_to_paste_y * x}, job.surface, job.force)
            -- rolling stock
            copy_lite_entity_pool(job.player, job.rolling_stock_pool, {x = job.tiles_to_paste_x * x, y = job.tiles_to_paste_y * x}, job.surface, job.force)
            -- power poles
            copy_lite_entity_pool(job.player, job.lite_entity_pool, {x = job.tiles_to_paste_x * x, y = job.tiles_to_paste_y * x}, job.surface, job.force)
            -- rest
            copy_entity_pool(job.player, job.entity_pool, {x = job.tiles_to_paste_x * x, y = job.tiles_to_paste_y * x}, job.surface, job.force)
        end
    end
end
