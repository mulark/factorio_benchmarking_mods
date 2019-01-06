require("scripts.cloner")

local entities_not_allowed_type = {"player"}

local function has_value (val, tab)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

function restrict_selection_area_to_entities(left, top, right, bottom, player)
    local first_ent = true
    local new_left, new_right, new_top, new_bottom = 0
    left, right = swap_to_fix_pairs(left, right)
    top, bottom = swap_to_fix_pairs(top, bottom)
    for _, ent in pairs(player.surface.find_entities_filtered{area={{left, top},{right,bottom}}, force="player"}) do
        if not has_value(ent.type, entities_not_allowed_type) then
            local compare_left = math.floor(ent.position.x + ent.prototype.collision_box.left_top.x)
            local compare_top = math.floor(ent.position.y + ent.prototype.collision_box.left_top.y)
            local compare_right = math.ceil(ent.position.x + ent.prototype.collision_box.right_bottom.x)
            local compare_bottom = math.ceil(ent.position.y + ent.prototype.collision_box.right_bottom.y)
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

function validate_player_copy_paste_settings(player)
    local top_gui = mod_gui.get_frame_flow(player)["region-cloner_control-window"]
    local coord_table = top_gui["region-cloner_coordinate-table"]
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
    local old_left = tonumber(coord_table["left_top_x"].text)
    local old_top = tonumber(coord_table["left_top_y"].text)
    local old_right = tonumber(coord_table["right_bottom_x"].text)
    local old_bottom = tonumber(coord_table["right_bottom_y"].text)
    if (old_left and old_top and old_bottom and old_right) then
        local new_left, new_right = swap_to_fix_pairs(old_left, old_right)
        local new_top, new_bottom = swap_to_fix_pairs(old_top, old_bottom)
        coord_table["left_top_x"].text = new_left
        coord_table["left_top_y"].text = new_top
        coord_table["right_bottom_x"].text = new_right
        coord_table["right_bottom_y"].text = new_bottom
    else
        player.print("A coordinate is not a number!")
        return false
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

function issue_copy_paste(player)
    local top_gui = mod_gui.get_frame_flow(player)["region-cloner_control-window"]
    local coord_table = top_gui["region-cloner_coordinate-table"]
    local left = tonumber(coord_table["left_top_x"].text)
    local top = tonumber(coord_table["left_top_y"].text)
    local right = tonumber(coord_table["right_bottom_x"].text)
    local bottom = tonumber(coord_table["right_bottom_y"].text)
    local times_to_paste = tonumber(top_gui["region-cloner_drop_down_table"]["number_of_copies"].text)
    local direction_to_copy = top_gui["region-cloner_drop_down_table"]["region-cloner_direction-to-copy"].selected_index
    local tile_paste_direction_x, tile_paste_direction_y = decode_direction_to_copy(direction_to_copy)
    local tiles_to_paste_x = (right - left) * tile_paste_direction_x
    local tiles_to_paste_y = (bottom - top) * tile_paste_direction_y
    clone_region_pre(left, top, right, bottom, times_to_paste, tiles_to_paste_x, tiles_to_paste_y, player)
end
