require("common")
--[[player, entity_pool, tiles_to_paste_x, tiles_to_paste_y, current_paste, times_to_paste, bounding_box]]

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
        if has_value(ent.type, entities_to_not_clone) then
            entity_pool[key] = nil
        else
            if (ent.valid) then
                if not has_value(ent.type, desync_if_entities_are_inactive_entities) then
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

function virtual_job_create(left, top, right, bottom, desired_times_to_paste)
    local job = {}
    local player = {}
    player.name = "bob"
    player.surface = game.surfaces[1]
    player.force = game.forces["player"]
    player.print = function(data)
        for _, p in pairs(game.players) do
            p.print("virtual job message: " .. data)
        end
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
    return job
end

function job_create(player)
    local job = {}
    job.player = player
    job.bounding_box = get_region_bounding_box(player)
    local temp_ent_pool = player.surface.find_entities_filtered{area=job.bounding_box, force="player"}
    local gui_dropdown_index = mod_gui.get_frame_flow(player)["region-cloner_control-window"]["region-cloner_drop_down_table"]["region-cloner_direction-to-copy"].selected_index
    job.tiles_to_paste_x, job.tiles_to_paste_y = convert_box_to_offsets(gui_dropdown_index, job.bounding_box)
    job.tiles_to_paste_x, job.tiles_to_paste_y = clean_entity_pool(temp_ent_pool, job.tiles_to_paste_x, job.tiles_to_paste_y)
    job.entity_pool = temp_ent_pool
    job.times_to_paste = tonumber(mod_gui.get_frame_flow(player)["region-cloner_control-window"]["region-cloner_drop_down_table"]["number_of_copies"].text)
    job.current_paste = 1
    job.flag_complete = false
    return job
end

return job
