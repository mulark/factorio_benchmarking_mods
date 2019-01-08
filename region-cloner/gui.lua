local gui = {}

gui.create_gui = function (player)
    gui.clear_gui(player)
    local mod_button = mod_gui.get_button_flow(player).add{type="sprite-button", name="region-cloner_main-button", sprite="achievement/lazy-bastard", tooltip="Region Cloner"}
    local mod_frame = mod_gui.get_frame_flow(player).add{type="frame", name="region-cloner_control-window", caption="Region Cloner", direction="vertical"}
    mod_frame.style.visible = false
    local coord_gui_table = mod_frame.add{type="table", column_count=3, name="region-cloner_coordinate-table"}
        coord_gui_table.add{type="label", name="left_top_description", caption="Left_top", tooltip="The top left corner coordinate of the region you wish to copy"}
        coord_gui_table.add{type="textfield", name="left_top_x"}
        coord_gui_table.add{type="textfield", name="left_top_y"}
        coord_gui_table.add{type="label", name="right_bottom_description", caption="Right_bottom", tooltip="The bottom right corner coordinate of the region you wish to copy"}
        coord_gui_table.add{type="textfield", name="right_bottom_x"}
        coord_gui_table.add{type="textfield", name="right_bottom_y"}

    local drop_down_table = mod_frame.add{type="table", column_count=4, name="region-cloner_drop_down_table"}
        drop_down_table.add{type="label", caption="Direction to Copy"}
        drop_down_table.add{type="drop-down", items={"North","East","South","West"}, selected_index=1, name = "region-cloner_direction-to-copy"}
        drop_down_table.add{type="label", caption="Number of copies", tooltip="How many copies of the area above will be made. Note that you will end up with 1 more copy than the number selected here (the original area)"}
        drop_down_table.add{type="textfield", name="number_of_copies", text=1}
        drop_down_table["number_of_copies"].style.left_padding = 8
        drop_down_table["number_of_copies"].style.right_padding = 8
        drop_down_table["number_of_copies"].style.align = "right"
        drop_down_table["number_of_copies"].style.maximal_width = 100

    local button_control_table = mod_frame.add{type="table", column_count=3}
        button_control_table.add{type="button", name="restrict_selection_area_to_entities", caption="Shrink Selection Area", tooltip="Reduces the size of your selection area to include only the entities found in that area"}
        local get_selection_tool_button = button_control_table.add{type="button", name="get_selection_tool_button", caption="Get Selection Tool"}
        local copy_paste_start_button = button_control_table.add{type="button", name="issue_copy_pastes", caption="Start"}
        copy_paste_start_button.style.align="right"
end

gui.clear_gui = function (player)
    local mod_button = mod_gui.get_button_flow(player)
    local mod_frame = mod_gui.get_frame_flow(player)
    if mod_button["region-cloner_main-button"] then
        mod_button["region-cloner_main-button"].destroy()
    end
    if mod_frame["region-cloner_control-window"] then
        mod_frame["region-cloner_control-window"].destroy()
    end
end

return gui
