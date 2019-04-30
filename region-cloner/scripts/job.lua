require("scripts.common")

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

function job_create(player)
    local frame_flow = mod_gui.get_frame_flow(player)
    if (debug_logging) then
        log("starting to create a job")
    end
    local job = {}
    job.player = player
    job.surface = player.surface
    job.force = player.force
    job.ticks_per_paste = 0
    job.bounding_box = get_region_bounding_box(player)
    local blacklisted_entity_pool = player.surface.find_entities_filtered{area=job.bounding_box, force="player", type=BLACKLISTED_ENTITY_TYPES_FROM_NEW_CLONE_METHODS}
    local temp_ent_pool = player.surface.find_entities_filtered{area=job.bounding_box, type=BLACKLISTED_ENTITY_TYPES_FROM_NEW_CLONE_METHODS, invert=true}
    local gui_dropdown_index = frame_flow["region-cloner_control-window"]["region-cloner_drop_down_table"]["region-cloner_direction-to-copy"].selected_index
    job.tiles_to_paste_x, job.tiles_to_paste_y = convert_box_to_offsets(gui_dropdown_index, job.bounding_box)
    job.tiles_to_paste_x, job.tiles_to_paste_y = clean_entity_pool(temp_ent_pool, job.tiles_to_paste_x, job.tiles_to_paste_y)
    job.entity_pool = temp_ent_pool
    job.blacklisted_entity_pool = blacklisted_entity_pool
    job.times_to_paste = tonumber(mod_gui.get_frame_flow(player)["region-cloner_control-window"]["region-cloner_drop_down_table"]["number_of_copies"].text)
    job.current_paste = 1
    job.flag_complete = false
    job.cancel_button_name = "region-cloner_" .. job.player.name .. "_job" .. "_cancel_button"
    local advanced_settings_gui = frame_flow[GUI_ELEMENT_PREFIX .. "advanced_view_pane"]
    local tile_paste_override_table = advanced_settings_gui[GUI_ELEMENT_PREFIX .. "advanced_tile_paste_override_table"]
    job.clean_paste_area_flag = true
    local custom_tile_paste_length_flag = tile_paste_override_table[GUI_ELEMENT_PREFIX .. "advanced_tile_paste_override_checkbox"].state
    job.custom_tile_paste_length_flag = custom_tile_paste_length_flag
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
