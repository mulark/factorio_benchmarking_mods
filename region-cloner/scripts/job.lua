require("scripts.common")
--[[player, entity_pool, tiles_to_paste_x, tiles_to_paste_y, current_paste, times_to_paste, bounding_box]]

global.job_queue = {}

local function get_region_bounding_box(player)
    local coord_table = mod_gui.get_frame_flow(player)["region-cloner_control-window"]["region-cloner_coordinate-table"]
    local left = tonumber(coord_table["left_top_x"].text)
    local top = tonumber(coord_table["left_top_y"].text)
    local right = tonumber(coord_table["right_bottom_x"].text)
    local bottom = tonumber(coord_table["right_bottom_y"].text)
    local bounding_box = construct_bounding_box(left, top, right, bottom)
    return bounding_box
end

local function correct_for_rail_grid(tile_paste_length)
    if ((tile_paste_length % 2) ~= 0) then
        if (tile_paste_length < 0) then
            tile_paste_length = tile_paste_length - 1
        else
            tile_paste_length = tile_paste_length + 1
        end
    end
    return tile_paste_length
end

local function clean_entity_pool (entity_pool, tiles_to_paste_x, tiles_to_paste_y)
    local flag_rail_found = false
    for key, ent in pairs(entity_pool) do
        if has_value(ent.type, {"straight-rail", "curved-rail"}) then
            flag_rail_found = true
        end
        if has_value(ent.type, ENTITIES_TO_NOT_CLONE) then
            entity_pool[key] = nil
        else
            if (ent.valid) then
                if not has_value(ent.type, DESYNC_IF_ENTITIES_ARE_INACTIVE_ENTITIES) then
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

local function decode_direction_to_copy(gui_dropdown_index)
    local tile_paste_direction_x, tile_paste_direction_y = 0, 0
    if (gui_dropdown_index == 1) then
        tile_paste_direction_y = -1
    elseif (gui_dropdown_index == 2) then
        tile_paste_direction_x = 1
    elseif (gui_dropdown_index == 3) then
        tile_paste_direction_y = 1
    elseif (gui_dropdown_index == 4) then
        tile_paste_direction_x = -1
    end
    return tile_paste_direction_x, tile_paste_direction_y
end

local function convert_box_to_offsets(gui_direction_to_copy_index, bounding_box)
    local tpx, tpy = decode_direction_to_copy(gui_direction_to_copy_index)
    tpx = tpx * (bounding_box.right_bottom.x - bounding_box.left_top.x)
    tpy = tpy * (bounding_box.right_bottom.y - bounding_box.left_top.y)
    return tpx,tpy
end

function register_gui_job(player, job)
    local job_pane = mod_gui.get_frame_flow(player)["region-cloner_control-window"]["region-cloner_job-watcher"]
    local job_name = "region-cloner_" .. job.player.name .. "_job"
    job_pane.add{type="table", column_count = 3, name=job_name}
    job_pane[job_name].add{type="label", caption=job.player.name}
    local pbar = job_pane[job_name].add{type="progressbar", value=job.current_paste / job.times_to_paste, name = job_name .. "_job_progress"}
    pbar.style.horizontally_stretchable = true
    local cancelbutton = job_pane[job_name].add{type="button", name = job_name .. "_cancel_button", tooltip="Cancel ongoing copy paste job", caption="x"}
end

function unregister_gui_job(player, job)
    local job_pane = mod_gui.get_frame_flow(player)["region-cloner_control-window"]["region-cloner_job-watcher"]
    local job_name = "region-cloner_" .. job.player.name .. "_job"
    if (job_pane[job_name]) then
        job_pane[job_name].destroy()
    end
    if not next(job_pane.children) then
        job_pane.style.visible = false
    end
end

function update_job_gui_progress(player, job)
    local job_pane = mod_gui.get_frame_flow(player)["region-cloner_control-window"]["region-cloner_job-watcher"]
    local job_name = "region-cloner_" .. job.player.name .. "_job"
    if (job_pane[job_name][job_name .. "_job_progress"]) then
        job_pane[job_name][job_name .. "_job_progress"].value = job.current_paste / job.times_to_paste
    end
end

function virtual_job_create(left, top, right, bottom, desired_times_to_paste)
    local job = {}
    local player = {}
    player.name = "bob"
    player.surface = game.surfaces[1]
    player.force = game.forces["player"]
    player.print = function(data)
        game.print(data)
    end
    job.player = player
    job.bounding_box = construct_bounding_box(left, top, right, bottom)
    local temp_ent_pool = player.surface.find_entities_filtered{area=job.bounding_box, force="player"}
    local gui_dropdown_index = 2
    job.tiles_to_paste_x, job.tiles_to_paste_y = convert_box_to_offsets(gui_dropdown_index, job.bounding_box)
    job.tiles_to_paste_x, job.tiles_to_paste_y = clean_entity_pool(temp_ent_pool, job.tiles_to_paste_x, job.tiles_to_paste_y)
    job.entity_pool = temp_ent_pool
    job.times_to_paste = desired_times_to_paste
    job.current_paste = 1
    job.flag_complete = false
    job.cancel_button_name = "region-cloner_" .. job.player.name .. "_job" .. "_cancel_button"
    local advanced_settings_gui = frame_flow[GUI_ELEMENT_PREFIX .. "advanced_view_pane"]
    local tile_paste_override_table = advanced_settings_gui[GUI_ELEMENT_PREFIX .. "advanced_tile_paste_override_table"]
    job.clean_paste_area_flag = true
    local custom_tile_paste_length_flag = tile_paste_override_table[GUI_ELEMENT_PREFIX .. "advanced_tile_paste_override_checkbox"].state
    if (custom_tile_paste_length_flag) then
        job.tiles_to_paste_x = tonumber(tile_paste_override_table[GUI_ELEMENT_PREFIX .. "advanced_tile_paste_x"].text)
        job.tiles_to_paste_y = tonumber(tile_paste_override_table[GUI_ELEMENT_PREFIX .. "advanced_tile_paste_y"].text)
    end
    local advanced_clear_paste_area_table = advanced_settings_gui[GUI_ELEMENT_PREFIX .. "advanced_clear_paste_area_table"]
    job.clear_normal_entities = advanced_clear_paste_area_table[GUI_ELEMENT_PREFIX .. "clear_normal_entities"].state
    job.clear_resource_entities = advanced_clear_paste_area_table[GUI_ELEMENT_PREFIX .. "clear_resource_entities"].state
    if (debug_logging) then
        log("finished virtual job creation")
    end
    return job
end

function job_create(player)
    local frame_flow = mod_gui.get_frame_flow(player)
    if (debug_logging) then
        log("starting to create a job")
    end
    local job = {}
    job.player = player
    job.bounding_box = get_region_bounding_box(player)
    local temp_ent_pool = player.surface.find_entities_filtered{area=job.bounding_box, force="player"}
    local gui_dropdown_index = frame_flow["region-cloner_control-window"]["region-cloner_drop_down_table"]["region-cloner_direction-to-copy"].selected_index
    job.tiles_to_paste_x, job.tiles_to_paste_y = convert_box_to_offsets(gui_dropdown_index, job.bounding_box)
    job.tiles_to_paste_x, job.tiles_to_paste_y = clean_entity_pool(temp_ent_pool, job.tiles_to_paste_x, job.tiles_to_paste_y)
    job.entity_pool = temp_ent_pool
    job.times_to_paste = tonumber(mod_gui.get_frame_flow(player)["region-cloner_control-window"]["region-cloner_drop_down_table"]["number_of_copies"].text)
    job.current_paste = 1
    job.flag_complete = false
    job.cancel_button_name = "region-cloner_" .. job.player.name .. "_job" .. "_cancel_button"
    local advanced_settings_gui = frame_flow[GUI_ELEMENT_PREFIX .. "advanced_view_pane"]
    local tile_paste_override_table = advanced_settings_gui[GUI_ELEMENT_PREFIX .. "advanced_tile_paste_override_table"]
    job.clean_paste_area_flag = true
    local custom_tile_paste_length_flag = tile_paste_override_table[GUI_ELEMENT_PREFIX .. "advanced_tile_paste_override_checkbox"].state
    if (custom_tile_paste_length_flag) then
        job.tiles_to_paste_x = tonumber(tile_paste_override_table[GUI_ELEMENT_PREFIX .. "advanced_tile_paste_x"].text)
        job.tiles_to_paste_y = tonumber(tile_paste_override_table[GUI_ELEMENT_PREFIX .. "advanced_tile_paste_y"].text)
    end
    local advanced_clear_paste_area_table = advanced_settings_gui[GUI_ELEMENT_PREFIX .. "advanced_clear_paste_area_table"]
    job.clear_normal_entities = advanced_clear_paste_area_table[GUI_ELEMENT_PREFIX .. "clear_normal_entities"].state
    job.clear_resource_entities = advanced_clear_paste_area_table[GUI_ELEMENT_PREFIX .. "clear_resource_entities"].state
    if (debug_logging) then
        log("finished job creation")
    end
    return job
end

return job
