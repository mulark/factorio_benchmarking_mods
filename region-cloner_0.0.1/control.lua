local mod_gui = require("mod-gui")
local util = require("util")
local gui = require("gui")
require("scripts.scripts")

script.on_configuration_changed(function()
    for _, player in pairs(game.players) do
        gui.create_gui(player)
    end
end)

script.on_event(defines.events.on_player_created, function(event)
    gui.create_gui(game.players[event.player_index])
    game.players[event.player_index].print("GUI created!")
end)

script.on_event({defines.events.on_gui_click}, function(event)
    local player = game.players[event.player_index]
    local frame_flow = mod_gui.get_frame_flow(player)
    local clicked_on = event.element.name
    if (clicked_on == "region-cloner_main-button") then
        frame_flow["region-cloner_control-window"].style.visible = not frame_flow["region-cloner_control-window"].style.visible
    end
    if (clicked_on == "get_selection_tool_button") then
        player.clean_cursor()
        if (player.cursor_stack.valid_for_read) then
            player.print("Your inventory is too full to use this tool")
            return
        end
        player.cursor_stack.set_stack("region-cloner_selection-tool")
    end
    if (clicked_on == "restrict_selection_area_to_entities") then
        local current_view = frame_flow["region-cloner_control-window"]["region-cloner_coordinate-table"]
        local old_left = tonumber(current_view["left_top_x"].text)
        local old_top = tonumber(current_view["left_top_y"].text)
        local old_right = tonumber(current_view["right_bottom_x"].text)
        local old_bottom = tonumber(current_view["right_bottom_y"].text)
        if (old_left and old_top and old_bottom and old_right) then
            local new_left, new_top, new_right, new_bottom = restrict_selection_area_to_entities(old_left, old_top, old_right, old_bottom, player)
            current_view["left_top_x"].text = new_left
            current_view["left_top_y"].text = new_top
            current_view["right_bottom_x"].text = new_right
            current_view["right_bottom_y"].text = new_bottom
        else
            player.print("A coordinate is not a number!")
        end
    end
    if (clicked_on == "issue_copy_pastes") then
        if (validate_player_copy_paste_settings(player)) then
            player.print("Successfully validated copy settings!")
            issue_copy_paste(player)
        end
    end
end)
script.on_event({defines.events.on_player_selected_area}, function(event)
    local player = game.players[event.player_index]
    if (player.cursor_stack.name ~= "region-cloner_selection-tool") then return end
    local frame_flow = mod_gui.get_frame_flow(player)
    local coord_table = frame_flow["region-cloner_control-window"]["region-cloner_coordinate-table"]
    if coord_table["left_top_x"] then
        coord_table["left_top_x"].text = math.floor(event.area.left_top.x)
    end
    if coord_table["left_top_y"] then
        coord_table["left_top_y"].text = math.floor(event.area.left_top.y)
    end
    if coord_table["right_bottom_x"] then
        coord_table["right_bottom_x"].text = math.ceil(event.area.right_bottom.x)
    end
    if coord_table["right_bottom_y"] then
        coord_table["right_bottom_y"].text = math.ceil(event.area.right_bottom.y)
    end
end)

script.on_event(defines.events.on_tick, nil)
