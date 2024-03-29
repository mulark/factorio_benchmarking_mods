local gui = {}

local mod_gui = require("mod-gui")

gui.create_gui = function (player)
    gui.clear_gui(player)
    local mod_button = mod_gui.get_button_flow(player).add{type="sprite-button", name=GUI_ELEMENT_PREFIX .. "main-button", sprite="achievement/lazy-bastard", tooltip="Region Cloner"}
    mod_button.style = mod_gui.button_style
    local frame_flow = mod_gui.get_frame_flow(player)
    local mod_frame = frame_flow.add{type="frame", name=GUI_ELEMENT_PREFIX .. "control-window", caption="", direction="vertical"}

    local title_flow = mod_frame.add{type="flow"}
    local title = title_flow.add{type="label", caption="Region Cloner"}
    title.style.font = "default-large-bold"
    local sub_title = title_flow.add{type="flow"}
    sub_title.style.horizontally_stretchable = true
    sub_title.style.horizontal_align = "right"
    local advanced_view_button = sub_title.add{name=GUI_ELEMENT_PREFIX .. "advanced_view_button", type="button", tooltip="Open advanced settings", caption="Advanced"}

    local advanced_settings_gui = frame_flow.add{name=GUI_ELEMENT_PREFIX .. "advanced_view_pane", type="frame", direction = "vertical"}
    local advanced_title_flow = advanced_settings_gui.add{type="flow"}
    local adv_title = advanced_title_flow.add{type="label", caption="Advanced Settings", tooltip="Break at your own risk."}
    adv_title.style.font = "default-large-bold"
    local sub_adv_title = advanced_title_flow.add{type="flow"}
    sub_adv_title.style.horizontally_stretchable = true
    sub_adv_title.style.horizontal_align = "right"
    sub_adv_title.add{name=GUI_ELEMENT_PREFIX .. "reset_gui_button", type="button", caption="Reset GUI", tooltip="Resets the GUI for your player."}
    advanced_settings_gui.visible = false

    local advanced_tile_paste_lengths_table = advanced_settings_gui.add{type="table", column_count=3, name=GUI_ELEMENT_PREFIX .. "advanced_tile_paste_override_table"}
    advanced_tile_paste_lengths_table.add{type="label"}
    advanced_tile_paste_lengths_table.add{type="label", caption="Tiles to paste X"}
    advanced_tile_paste_lengths_table.add{type="label", caption="Tiles to paste Y"}
    advanced_tile_paste_lengths_table.add{type="checkbox", state=false, name = GUI_ELEMENT_PREFIX .. "advanced_tile_paste_override_checkbox", tooltip="Overrides the tile paste length from being calculated using the bounding box. Useful if you want to partially overlap paste areas. Strongly reccomended to not clear paste area at the same time. Overrides Direction to copy. Allows bad or unusual values so use with care.", caption="Tile paste override"}
    advanced_tile_paste_lengths_table.add{name=GUI_ELEMENT_PREFIX .. "advanced_tile_paste_x", type="textfield", text="0", numeric=true, allow_decimal=true, allow_negative=true}
    advanced_tile_paste_lengths_table.add{name=GUI_ELEMENT_PREFIX .. "advanced_tile_paste_y", type="textfield", text="0", numeric=true, allow_decimal=true, allow_negative=true}

    local clear_paste_area_table = advanced_settings_gui.add{type="table", column_count=3, name=GUI_ELEMENT_PREFIX .. "advanced_clear_paste_area_table"}
    clear_paste_area_table.add{type="label", caption="Clear paste area:", tooltip="Look for entities in the area about to be pasted into and delete them. If you don't clear normal entities it's likely that you'll stack mutiple on one tile, so be careful! Defaults to true."}
    clear_paste_area_table.add{type="checkbox", caption="Normal entities", state=true, name=GUI_ELEMENT_PREFIX .. "clear_normal_entities", tooltip="Clears the paste area of any player owned entities. If you use tile paste overrides with this setting enabled it probably won't work like you want it to!"}
    clear_paste_area_table.add{type="checkbox", caption="Resources", state=true, name=GUI_ELEMENT_PREFIX .. "clear_resource_entities", tooltip="Clears the paste area of ore/resources. May need to pre-generate the map to ensure ore is generated by the time we look for it."}

	--[Adding the "progress bar" checkbox]
	advanced_settings_gui.add{type="checkbox", caption="Print Progress", state=false, name=GUI_ELEMENT_PREFIX .. "progress_bar", tooltip="The progress bar spends an additional 1 tick for each copy, which increases chance of clones breaking."}
	advanced_settings_gui.add{type="checkbox", caption="Print Detailed Progress", state=false, name=GUI_ELEMENT_PREFIX .. "detailed_log", tooltip="The detailed log copies different types of entities in different ticks, which increases the chance of clones breaking."}

    mod_frame.visible = false
    local coord_gui_table = mod_frame.add{type="table", column_count=3, name=GUI_ELEMENT_PREFIX .. "coordinate-table"}
        coord_gui_table.add{type="label", name="left_top_description", caption="Left_top", tooltip="The top left corner coordinate of the region you wish to copy"}
        coord_gui_table.add{type="textfield", name="left_top_x", text="0", numeric=true, allow_negative=true}
        coord_gui_table.add{type="textfield", name="left_top_y", text="0", numeric=true, allow_negative=true}
        coord_gui_table.add{type="label", name="right_bottom_description", caption="Right_bottom", tooltip="The bottom right corner coordinate of the region you wish to copy"}
        coord_gui_table.add{type="textfield", name="right_bottom_x", text="0", numeric=true, allow_negative=true}
        coord_gui_table.add{type="textfield", name="right_bottom_y", text="0", numeric=true, allow_negative=true}

    local drop_down_table = mod_frame.add{type="table", column_count=4, name=GUI_ELEMENT_PREFIX .. "drop_down_table"}
        drop_down_table.add{type="label", caption="Direction to copy:", tooltop="The direction pastes will be executed in. Use a custom tile paste override if you need finer control."}
        drop_down_table.add{type="drop-down", items={"North","East","South","West"}, selected_index=1, name = GUI_ELEMENT_PREFIX .. "direction-to-copy"}
        drop_down_table.add{type="label", caption="Number of copies:", tooltip="How many copies of the area above will be made. Note that you will end up with 1 more copy than the number selected here (the original area)"}
        drop_down_table.add{type="textfield", name="number_of_copies", text=1, numeric=true}
        drop_down_table["number_of_copies"].style.left_padding = 8
        drop_down_table["number_of_copies"].style.right_padding = 8
        drop_down_table["number_of_copies"].style.horizontal_align = "right"
        drop_down_table["number_of_copies"].style.maximal_width = 100

    local button_control_table = mod_frame.add{type="table", column_count=3}
        button_control_table.add{type="button", name=GUI_ELEMENT_PREFIX .. "restrict_selection_area_to_entities", caption="Shrink Selection Area", tooltip="Reduces the size of your selection area to include only the entities found in that area"}
        local get_selection_tool_button = button_control_table.add{type="button", name=GUI_ELEMENT_PREFIX .. "get_selection_tool_button", caption="Get Selection Tool"}
        local copy_paste_start_button = button_control_table.add{type="button", name=GUI_ELEMENT_PREFIX .. "issue_copy_pastes_button", caption="Start"}
        copy_paste_start_button.style.horizontal_align="right"
end

gui.clear_gui = function (player)
    local mod_button = mod_gui.get_button_flow(player)
    local mod_frame = mod_gui.get_frame_flow(player)
    if mod_button[GUI_ELEMENT_PREFIX .. "main-button"] then
        mod_button[GUI_ELEMENT_PREFIX .. "main-button"].destroy()
    end
    if mod_frame[GUI_ELEMENT_PREFIX .. "control-window"] then
        mod_frame[GUI_ELEMENT_PREFIX .. "control-window"].destroy()
    end
    if mod_frame[GUI_ELEMENT_PREFIX .. "advanced_view_pane"] then
        mod_frame[GUI_ELEMENT_PREFIX .. "advanced_view_pane"].destroy()
    end
end

return gui
