data:extend({
    {
        type = "string-setting",
        name = "creative-world-plus_tiles-to-pave",
        setting_type = "startup",
        default_value = "All",
        allowed_values = {"All", "Land Tiles Only", "None"},
        order="a"
    },
    {
        type = "bool-setting",
        name = "creative-world-plus_remove-rocks",
        setting_type = "startup",
        default_value = true,
        order="b"
    },
    {
        type = "bool-setting",
        name = "creative-world-plus_remove-decorative",
        setting_type = "startup",
        default_value = true,
        order="c"
    },
    {
        type = "bool-setting",
        name = "creative-world-plus_remove-fish",
        setting_type = "startup",
        default_value = true,
        order="d"
    }
})
