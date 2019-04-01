
-- all tiles (as of 0.16)
local tiles = {"concrete", "deepwater", "deepwater-green", "dirt-1", "dirt-2", "dirt-3", "dirt-4", "dirt-5", "dirt-6", "dirt-7", "dry-dirt", "grass-1", "grass-2", "grass-3", "grass-4", "hazard-concrete-left", "hazard-concrete-right", "lab-dark-1", "lab-dark-2", "lab-white", "out-of-map", "red-desert-0", "red-desert-1", "red-desert-2", "red-desert-3", "refined-concrete", "refined-hazard-concrete-left", "refined-hazard-concrete-right", "sand-1", "sand-2", "sand-3", "stone-path", "tutorial-grid", "water", "water-green"}

-- mostly usefull tiles
-- local tiles = {"concrete", "refined-concrete", "lab-dark-1", "lab-dark-2", "lab-white", "stone-path", "tutorial-grid"}

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
    },
    {
        type = "string-setting",
        name = "creative-world-plus_tile-type",
        setting_type = "startup",
        default_value = "refined-concrete",
        allowed_values = tiles,
        order="e"
    }
})
