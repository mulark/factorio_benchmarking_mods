local mod_gui = require("mod-gui")
local util = require("util")
local gui = require("scripts.gui")
require("scripts.scripts")
require("scripts.common")
--require('__profiler__/profiler.lua')
--pcall(require,'__coverage__/coverage.lua')


script.on_init(function()
    register_commands()
    storage.selection_boxes = {}
end)

script.on_load(function()
    register_commands()
end)

function register_commands()
    commands.add_command("autoclone","[#] [N/s/e/w] [c] [r] --Help: Automatically clones everything [#] times towards [N/s/e/w], provide char [c] to keep chunk aligned, provide char [r] to respect roboport overlap range", function(param)
        create_job_from_cmd(param)
    end)
end

script.on_configuration_changed(function()
    for _, player in pairs(game.players) do
        gui.create_gui(player)
    end
    -- Initialize selection boxes storage if it doesn't exist
    storage.selection_boxes = storage.selection_boxes or {}
end)

script.on_event(defines.events.on_player_created, function(event)
    gui.create_gui(game.players[event.player_index])
end)

script.on_event({defines.events.on_gui_click}, function(event)
    local player = game.players[event.player_index]
    local frame_flow = mod_gui.get_frame_flow(player)
    local clicked_on = event.element.name

    if (clicked_on == GUI_PFX .. "reset_gui_button") then
        --[[Probably will be removed in the next version as it's pointless]]
        gui.create_gui(player)
    end

    if (clicked_on == GUI_PFX .. "main-button") then
        frame_flow[GUI_PFX .. "control-window"].visible = not frame_flow[GUI_PFX .. "control-window"].visible
        if (frame_flow[GUI_PFX .. "advanced_view_pane"].visible) then
            frame_flow[GUI_PFX .. "advanced_view_pane"].visible = false
        end
    end

    if (clicked_on == GUI_PFX .. "advanced_view_button") then
        frame_flow[GUI_PFX .. "advanced_view_pane"].visible = not frame_flow[GUI_PFX .. "advanced_view_pane"].visible
    end

    if (clicked_on == GUI_PFX .. "get_selection_tool_button") then
        --[[Try to clean anything in the cursor]]
        player.clear_cursor()
        if (player.cursor_stack.valid_for_read) then
            player.print("Your inventory is too full to use this tool")
            return
        end
        --[[Don't use GUI_PFX since this item is not a GUI ya dingus!]]
        inv = player.get_main_inventory()
        if inv ~= nil then
            inv.remove(SELECTION_TOOL)
        end
        player.cursor_stack.set_stack(SELECTION_TOOL)
    end

    if (clicked_on == GUI_PFX .. "restrict_selection_area_to_entities") then
        validate_coordinates_and_update_view(player, true)
        -- Update selection box after restricting area
        local selection_box_table = mod_gui.get_frame_flow(player)[GUI_PFX .. "control-window"][GUI_PFX .. "selection_box_table"]
        if selection_box_table and selection_box_table[GUI_PFX .. "show_selection_box"].state then
            gui.render_selection_box(player)
        end
    end

    if (clicked_on == GUI_PFX .. "issue_copy_pastes_button") then
        if (validate_player_copy_paste_settings(player)) then
            issue_copy_paste(player)
        end
    end

    -- Handle selection box related clicks
    if (clicked_on == GUI_PFX .. "show_selection_box") then
        local checkbox = event.element
        gui.toggle_selection_box(player, checkbox.state)
    end

    if (clicked_on == GUI_PFX .. "update_selection_box") then
        gui.render_selection_box(player)
    end
end)

script.on_event({defines.events.on_gui_checked_state_changed}, function(event)
    local player = game.players[event.player_index]
    local clicked_on = event.element.name

    -- Handle selection box checkbox toggle
    if (clicked_on == GUI_PFX .. "show_selection_box") then
        gui.toggle_selection_box(player, event.element.state)
    end
end)

script.on_event({defines.events.on_gui_text_changed}, function(event)
    local player = game.players[event.player_index]
    local element_name = event.element.name

    -- Update selection box when coordinates change
    if (element_name == "left_top_x" or element_name == "left_top_y" or
        element_name == "right_bottom_x" or element_name == "right_bottom_y") then
        -- Only render if checkbox is checked
        local selection_box_table = mod_gui.get_frame_flow(player)[GUI_PFX .. "control-window"][GUI_PFX .. "selection_box_table"]
        if selection_box_table and selection_box_table[GUI_PFX .. "show_selection_box"].state then
            gui.render_selection_box(player)
        end
    end
end)

script.on_event({defines.events.on_player_selected_area}, function(event)
    local player = game.players[event.player_index]
    local stack = player.cursor_stack
    if (stack.valid_for_read and stack.name == SELECTION_TOOL) then
        local coord_table = mod_gui.get_frame_flow(player)[GUI_PFX .. "control-window"][GUI_PFX .. "coordinate-table"]
        if coord_table["left_top_x"] then
            coord_table["left_top_x"].text = tostring(math.floor(event.area.left_top.x))
        end
        if coord_table["left_top_y"] then
            coord_table["left_top_y"].text = tostring(math.floor(event.area.left_top.y))
        end
        if coord_table["right_bottom_x"] then
            coord_table["right_bottom_x"].text = tostring(math.ceil(event.area.right_bottom.x))
        end
        if coord_table["right_bottom_y"] then
            coord_table["right_bottom_y"].text = tostring(math.ceil(event.area.right_bottom.y))
        end

        -- Update selection box after area selection
        local selection_box_table = mod_gui.get_frame_flow(player)[GUI_PFX .. "control-window"][GUI_PFX .. "selection_box_table"]
        if selection_box_table and selection_box_table[GUI_PFX .. "show_selection_box"].state then
            gui.render_selection_box(player)
        end
    end
end)

-- Clean up selection boxes when player leaves
script.on_event(defines.events.on_player_left_game, function(event)
    local player = game.players[event.player_index]
    gui.clear_selection_box(player)
end)