require("scripts.common")

local mod_gui = require("mod-gui")

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

local function clean_entity_pool_and_selectively_correct_tile_paste_length_for_rail_grid(entity_pool, tiles_to_paste_x, tiles_to_paste_y, custom_tile_paste_flag, player)
    local flag_rail_found = false
    for key, ent in pairs(entity_pool) do
        if has_value(ent.type, {"straight-rail", "curved-rail"}) then
            flag_rail_found = true
        end
        if is_ignored_entity_type(ent.name, ent.type) then
            entity_pool[key] = nil
        end
    end
    if (flag_rail_found) then
        if (tiles_to_paste_x ~= 0) then
            if (custom_tile_paste_flag == true and (tiles_to_paste_x % 2) ~= 0) then
                player.print("You selected an odd number x custom tile paste offset, but included rails in your selection.")
                player.print("This means you are cloning off the rail grid, which can cause a big performance hit.")
            else
                tiles_to_paste_x = correct_for_rail_grid(tiles_to_paste_x)
            end
        end
        if (tiles_to_paste_y ~= 0) then
            if (custom_tile_paste_flag == true and (tiles_to_paste_y % 2) ~= 0) then
                player.print("You selected an odd number y custom tile paste offset, but included rails in your selection.")
                player.print("This means you are cloning off the rail grid, which can cause a big performance hit.")
            else
                tiles_to_paste_y = correct_for_rail_grid(tiles_to_paste_y)
            end
        end
    end
    return tiles_to_paste_x, tiles_to_paste_y
end

local function decode_direction_to_copy(index)
    local tile_paste_direction_x, tile_paste_direction_y = 0, 0
    if (index == 1) then
        tile_paste_direction_y = -1
    elseif (index == 2) then
        tile_paste_direction_x = 1
    elseif (index == 3) then
        tile_paste_direction_y = 1
    elseif (index == 4) then
        tile_paste_direction_x = -1
    end
    return tile_paste_direction_x, tile_paste_direction_y
end

local function convert_box_to_offsets(direction_to_copy_index, bounding_box)
    --We know box is sorted at the moment, this is safe.
    local tpx, tpy = decode_direction_to_copy(direction_to_copy_index)
    tpx = tpx * (bounding_box.right_bottom.x - bounding_box.left_top.x)
    tpy = tpy * (bounding_box.right_bottom.y - bounding_box.left_top.y)
    return tpx,tpy
end

function job_common_pool(job)
    job.tiles = job.source_surface.find_tiles_filtered{area=job.bounding_box}
    job.entity_pool = job.source_surface.find_entities_filtered{area=job.bounding_box, type = LITE_CLONING_TYPES, invert = true}
    job.high_priority_pool = {}
    for k,v in pairs(job.entity_pool) do
        if not v.can_be_destroyed() then
            -- collect up rails with trains on them
            job.high_priority_pool[k] = v
            job.entity_pool[k] = nil
        end
    end


    job.lite_entity_pool = job.source_surface.find_entities_filtered{area=job.bounding_box, type = LITE_CLONING_TYPES}
end

function job_create_lite(times_to_paste, dir_to_copy_index, chunk_align, player, respect_logistics)
    if (debug_logging) then
        log("starting to create a lite job")
    end
    local job = {}
    job.player = player
    job.source_surface = player.surface
    job.destination_surface = player.surface
    job.force = player.force
    job.bounding_box = restrict_selection_area_to_entities(construct_bounding_box(0,0,0,0), chunk_align, player, respect_logistics)
    if job.bounding_box.left_top.x == job.bounding_box.right_bottom.x then
        return false
    end
    if job.bounding_box.left_top.y == job.bounding_box.right_bottom.y then
        return false
    end
    job_common_pool(job)
    job.times_to_paste = times_to_paste
    job.tiles_to_paste_x, job.tiles_to_paste_y = 0, 0
    job.tiles_to_paste_x, job.tiles_to_paste_y = convert_box_to_offsets(dir_to_copy_index, job.bounding_box)
    job.tiles_to_paste_x, job.tiles_to_paste_y = clean_entity_pool_and_selectively_correct_tile_paste_length_for_rail_grid(job.entity_pool, job.tiles_to_paste_x, job.tiles_to_paste_y, false, job.player)
    job.clear_normal_entities = true
    job.clear_resource_entities = true
    local srctilex
    local srctiley
    if job.tiles_to_paste_x > 0 then
        srctilex = job.bounding_box.right_bottom.x
    else
        srctilex = job.bounding_box.left_top.x
    end
    if job.tiles_to_paste_y > 0 then
        srctiley = job.bounding_box.right_bottom.y
    else
        srctiley = job.bounding_box.left_top.y
    end
    if (math.abs(srctilex + job.times_to_paste * job.tiles_to_paste_x) > 1000000) then
        player.print("Parameters would result in cloning outside of map")
        return false
    end
    if (math.abs(srctiley + job.times_to_paste * job.tiles_to_paste_y) > 1000000) then
        player.print("Parameters would result in cloning outside of map")
        return false
    end
    if (debug_logging) then
        log("finished lite job creation")
    end
--     rendering.draw_rectangle{width=8, color={g=128, b=128}, left_top=job.bounding_box.left_top, right_bottom=job.bounding_box.right_bottom, surface=job.source_surface}
    return job
end

function job_create(player)
    local frame_flow = mod_gui.get_frame_flow(player)
    if (debug_logging) then
        log("starting to create a job")
    end
    local job = {}
    job.player = player
    job.source_surface = player.surface
    job.destination_surface = player.surface
    job.force = player.force
    job.bounding_box = get_region_bounding_box(player)
    local advanced_settings_gui = frame_flow[GUI_PFX .. "advanced_view_pane"]
    local tile_paste_override_table = advanced_settings_gui[GUI_PFX .. "advanced_tile_paste_override_table"]
    local custom_tile_paste_length_flag = tile_paste_override_table[GUI_PFX .. "advanced_tile_paste_override_checkbox"].state
    job.custom_tile_paste_length_flag = custom_tile_paste_length_flag
    local temp_ent_pool = job.source_surface.find_entities_filtered{area=job.bounding_box, type = LITE_CLONING_TYPES, invert = true}
    local gui_dropdown_index = frame_flow["region-cloner_control-window"]["region-cloner_drop_down_table"]["region-cloner_direction-to-copy"].selected_index

    job_common_pool(job)

    job.times_to_paste = tonumber(mod_gui.get_frame_flow(player)["region-cloner_control-window"]["region-cloner_drop_down_table"]["number_of_copies"].text)

    if (job.custom_tile_paste_length_flag) then
        job.tiles_to_paste_x = tonumber(tile_paste_override_table[GUI_PFX .. "advanced_tile_paste_x"].text)
        job.tiles_to_paste_y = tonumber(tile_paste_override_table[GUI_PFX .. "advanced_tile_paste_y"].text)
        job.tiles_to_paste_x, job.tiles_to_paste_y = clean_entity_pool_and_selectively_correct_tile_paste_length_for_rail_grid(temp_ent_pool, job.tiles_to_paste_x, job.tiles_to_paste_y, job.custom_tile_paste_length_flag, job.player)
    else
        job.tiles_to_paste_x, job.tiles_to_paste_y = convert_box_to_offsets(gui_dropdown_index, job.bounding_box)
        job.tiles_to_paste_x, job.tiles_to_paste_y = clean_entity_pool_and_selectively_correct_tile_paste_length_for_rail_grid(temp_ent_pool, job.tiles_to_paste_x, job.tiles_to_paste_y, job.custom_tile_paste_length_flag, job.player)
    end
    local advanced_clear_paste_area_table = advanced_settings_gui[GUI_PFX .. "advanced_clear_paste_area_table"]
    job.clear_normal_entities = advanced_clear_paste_area_table[GUI_PFX .. "clear_normal_entities"].state
    job.clear_resource_entities = advanced_clear_paste_area_table[GUI_PFX .. "clear_resource_entities"].state
    local srctilex
    local srctiley
    if job.tiles_to_paste_x > 0 then
        srctilex = job.bounding_box.right_bottom.x
    else
        srctilex = job.bounding_box.left_top.x
    end
    if job.tiles_to_paste_y > 0 then
        srctiley = job.bounding_box.right_bottom.y
    else
        srctiley = job.bounding_box.left_top.y
    end
    if (math.abs(srctilex + job.times_to_paste * job.tiles_to_paste_x) > 1000000) then
        player.print("Parameters would result in cloning outside of map")
        return false
    end
    if (math.abs(srctiley + job.times_to_paste * job.tiles_to_paste_y) > 1000000) then
        player.print("Parameters would result in cloning outside of map")
        return false
    end
    if (debug_logging) then
        log("finished job creation")
    end
    return job
end


function clone_platform_job(player)
    if not player.surface or not player.surface.platform then
        player.print("Not on a surface/platform")
    end

    local job = {}
    job.player = player
    job.source_surface = player.surface
    job.force = player.force

    local platform = job.source_surface.platform
    local space_location = "nauvis"
    if platform.space_location ~= nil then
        space_location = platform.space_location
    end
    if platform.space_connection ~= nil then
        space_location = platform.space_connection.from
    end

    local starter_pack = {}
    if platform.starter_pack ~= nil then
        starter_pack = platform.starter_pack
    else
        local hub = platform.hub
        if hub ~= nil then
            starter_pack.name = "space-platform-starter-pack"
            starter_pack.quality = hub.quality
        else
            player.print("Hub was not found on surface???")
            return false
        end
    end
    local cloned_platform = job.force.create_space_platform{name=platform.name, planet=space_location, starter_pack=starter_pack}
    game.print("Created platform " .. serpent.block(cloned_platform))
    if platform.starter_pack == nil then
        -- TODO: we lose quality here... Factorio issue?
        cloned_platform.apply_starter_pack(false)
    else
        return false
    end
    job.destination_surface = cloned_platform.surface
    if job.destination_surface == nil then
        return false
    end

    job.bounding_box = nil

    job_common_pool(job)

    job.times_to_paste = tonumber(mod_gui.get_frame_flow(player)["region-cloner_control-window"]["region-cloner_drop_down_table"]["number_of_copies"].text)

    job.tiles_to_paste_x, job.tiles_to_paste_y = 0, 0

    job.clear_normal_entities = false
    job.clear_resource_entities = false

    if (debug_logging) then
        log("finished job creation")
    end
    return job
end