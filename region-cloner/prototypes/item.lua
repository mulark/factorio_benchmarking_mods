data:extend(
{
    {
        -- region-cloner_Selection-Tool
        type = "selection-tool",
        name = "region-cloner_selection-tool",
        icon_size = 128,
        icon = "__region-cloner__/graphics/lazy-bastard.png",
        subgroup = "tool",
        order = "a",
        stack_size = 1,
        selection_color = {r = 0, g = 1, b = 0},
        selection_mode = {"any-tile"},
        selection_cursor_box_type = "entity",
        alt_selection_color = {r = 1, g = 0, b = 0},
        alt_selection_mode = {"any-entity", "deconstruct"},
        alt_selection_cursor_box_type = "not-allowed",
        always_include_tiles = true,
        select = {
            border_color = {},
            cursor_box_type = "copy",
            mode = "any-entity", "any-tile"
        },
        alt_select = {
            border_color = {},
            cursor_box_type = "copy",
            mode = "any-entity", "any-tile"
        }
    }
})
