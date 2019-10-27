local mod_gui = require("mod-gui")
local util = require("util")
local gui = require("scripts.gui")
require("scripts.scripts")
require("scripts.common")
--require('__profiler__/profiler.lua')


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
    if (clicked_on == GUI_ELEMENT_PREFIX .. "reset_gui_button") then
        --[[Probably will be removed in the next version as it's pointless]]
        gui.create_gui(player)
    end
    if (clicked_on == GUI_ELEMENT_PREFIX .. "main-button") then
        frame_flow[GUI_ELEMENT_PREFIX .. "control-window"].visible = not frame_flow[GUI_ELEMENT_PREFIX .. "control-window"].visible
        if (frame_flow[GUI_ELEMENT_PREFIX .. "advanced_view_pane"].visible) then
            frame_flow[GUI_ELEMENT_PREFIX .. "advanced_view_pane"].visible = false
        end
    end
    if (clicked_on == GUI_ELEMENT_PREFIX .. "advanced_view_button") then
        frame_flow[GUI_ELEMENT_PREFIX .. "advanced_view_pane"].visible = not frame_flow[GUI_ELEMENT_PREFIX .. "advanced_view_pane"].visible
    end
    if (clicked_on == GUI_ELEMENT_PREFIX .. "get_selection_tool_button") then
        --[[Try to clean anything in the cursor]]
        player.clean_cursor()
        if (player.cursor_stack.valid_for_read) then
            player.print("Your inventory is too full to use this tool")
            return
        end
        --[[Don't use GUI_ELEMENT_PREFIX since this item is not a GUI ya dingus!]]
        player.get_main_inventory().remove("region-cloner_selection-tool")
        player.cursor_stack.set_stack("region-cloner_selection-tool")
    end
    if (clicked_on == GUI_ELEMENT_PREFIX .. "restrict_selection_area_to_entities") then
        validate_coordinates_and_update_view(player, true)
    end
    if (clicked_on == GUI_ELEMENT_PREFIX .. "issue_copy_pastes_button") then
        if (validate_player_copy_paste_settings(player)) then
            issue_copy_paste(player)
        end
    end
end)

script.on_event({defines.events.on_player_selected_area}, function(event)
    local player = game.players[event.player_index]
    if (player.cursor_stack.name == "region-cloner_selection-tool") then
        local coord_table = mod_gui.get_frame_flow(player)[GUI_ELEMENT_PREFIX .. "control-window"][GUI_ELEMENT_PREFIX .. "coordinate-table"]
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
