local mod_gui = require("mod-gui")
local util = require("util")
local gui = require("scripts.gui")
require("scripts.scripts")


script.on_init(function()
    if global.do_on_tick == true then
        do_on_tick()
    end
end)

script.on_load(function()
    if global.do_on_tick == true then
        do_on_tick()
    end
end)


script.on_configuration_changed(function()
    global.job_queue = {}
    if global.do_on_tick == true then
        do_on_tick()
    end
    for _, player in pairs(game.players) do
        gui.create_gui(player)
    end
end)

script.on_event(defines.events.on_player_created, function(event)
    gui.create_gui(game.players[event.player_index])
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
        player.get_main_inventory().remove("region-cloner_selection-tool")
        player.cursor_stack.set_stack("region-cloner_selection-tool")
    end
    if (clicked_on == "restrict_selection_area_to_entities") then
        validate_coordinates_and_update_view(player, true)
    end
    if (clicked_on == "issue_copy_pastes") then
        if (validate_player_copy_paste_settings(player)) then
            issue_copy_paste(player)
        end
    end
    for _, job in pairs (global.job_queue) do
        if (clicked_on == job.cancel_button_name) then
            job.flag_complete = true
            update_player_progress_bars(global.job_queue)
        end
    end
end)

script.on_event({defines.events.on_player_selected_area}, function(event)
    local player = game.players[event.player_index]
    if (player.cursor_stack.name == "region-cloner_selection-tool") then
        local coord_table = mod_gui.get_frame_flow(player)["region-cloner_control-window"]["region-cloner_coordinate-table"]
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
    end
end)
