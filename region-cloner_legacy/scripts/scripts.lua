require("scripts.cloner")
require("scripts.common")
require("scripts.job")

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
    local problematic_collision_box_entity_types = {"curved-rail"}
    local new_left, new_right, new_top, new_bottom = 0
    left, right = swap_to_fix_pairs(left, right)
    top, bottom = swap_to_fix_pairs(top, bottom)
    for _, ent in pairs(player.surface.find_entities_filtered{area={{left, top},{right,bottom}}, force="player"}) do
        if not has_value(ent.type, ENTITIES_TO_NOT_CLONE) then
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
        player.print("No player entites were found in the selection area, could not reduce selection area!")
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
            player.print("Times to paste is less than 1!")
            return false
        end
    else
        player.print("Times to paste is not a number!")
        return false
    end
    if not (direction_to_copy) then
        player.print("Somehow your direction to paste is not valid!")
    end
    local advanced_settings_gui = frame_flow[GUI_ELEMENT_PREFIX .. "advanced_view_pane"]
    local custom_tile_paste_length_table = advanced_settings_gui[GUI_ELEMENT_PREFIX .. "advanced_tile_paste_override_table"]
    if (custom_tile_paste_length_table[GUI_ELEMENT_PREFIX .. "advanced_tile_paste_override_checkbox"].state) then
        --[[Only validate custom tile paste lengths if the box is checked]]
        local tiles_to_paste_x = tonumber(custom_tile_paste_length_table[GUI_ELEMENT_PREFIX .. "advanced_tile_paste_x"].text)
        local tiles_to_paste_y = tonumber(custom_tile_paste_length_table[GUI_ELEMENT_PREFIX .. "advanced_tile_paste_y"].text)
        if (tiles_to_paste_x and tiles_to_paste_y) then
            if (tiles_to_paste_x == 0 and tiles_to_paste_y == 0) then
                player.print("You selected custom tile paste lengths but they're both 0!")
                return false
            end
        else
            player.print("Your custom tile paste length(s) are not a number!")
            return false
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

local function clone_entites_by_job(job)
    if (job.entity_pool) then
        --[[In 0.17 we might not need the entity_pool anymore]]
        if next(job.entity_pool) then
            --[[If there's at least 1 thing in the entity pool]]
            if (job.current_paste == 1) then
                for _, ent in pairs(job.entity_pool) do
                    if (ent.valid) then
                        if not has_value(ent.type, DESYNC_IF_ENTITIES_ARE_INACTIVE_ENTITIES) then
                            ent.active = false
                        end
                    end
                end
            end
            job.current_paste, job.flag_complete = clone_entity_pool(job.player, job.entity_pool, job.tiles_to_paste_x, job.tiles_to_paste_y, job.current_paste, job.times_to_paste, job.bounding_box, job.flag_complete, job.clear_normal_entities, job.clear_resource_entities)
        else
            job.player.print("You had valid copy paste settings but there were no entities to clone!")
            job.flag_complete = true
            update_player_progress_bars(global.job_queue)
        end
    end
end

function update_player_progress_bars(job_queue)
    for _, player in pairs(game.players) do
        local job_pane = mod_gui.get_frame_flow(player)[GUI_ELEMENT_PREFIX .. "control-window"][GUI_ELEMENT_PREFIX .. "job-watcher"]
        for _, job in pairs(job_queue) do
            if (job.flag_complete) then
                unregister_gui_job(player, job)
            else
                if (job.times_to_paste > 1) then
                    job_pane.style.visible = true
                    if not (job_pane[GUI_ELEMENT_PREFIX .. job.player.name .. "_job"]) then
                        register_gui_job(player, job)
                    end
                    update_job_gui_progress(player, job)
                end
            end
        end
    end
end

function do_on_tick()
    script.on_event(defines.events.on_tick, function(event)
        if (game.tick % TICKS_PER_PASTE) then
            run_on_tick()
        end
    end)
end

function issue_copy_paste(player)
    if (debug_logging) then
        log("entering issue_copy_paste")
    end
    local my_job = job_create(player)
    if (debug_logging) then
        log("created player job")
    end
    global.job_queue[player.name] = my_job
    --[[local job_from_another_player = virtual_job_create(32, -32, 64, 0, 100)
    job_queue[job_from_another_player.player.name] = job_from_another_player]]
    global.do_on_tick = true
    do_on_tick()
end

function run_on_tick()
    if (debug_logging) then
        log("started on tick behavior")
    end
    for job_key, job in pairs(global.job_queue) do
        if (job.flag_complete) then
            --[[If this job is finished then set the entity pool active and unregister the job]]
            if (job.entity_pool) then
                for _,ent in pairs(job.entity_pool) do
                    if (ent.valid) then
                        ent.active = true
                    end
                end
            end
            job = nil
            global.job_queue[job_key] = nil
        else
            clone_entites_by_job(job)
        end
    end
    update_player_progress_bars(global.job_queue)
    if not next(global.job_queue) then
        --[[If the job_queue has no jobs then unregister the on_tick event handler]]
        global.do_on_tick = false
        script.on_event(defines.events.on_tick, nil)
    end
end
