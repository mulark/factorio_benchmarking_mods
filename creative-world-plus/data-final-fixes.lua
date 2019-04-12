local autoplace_controls_to_set_to_0_size = {}
for key, _ in pairs (data.raw["autoplace-control"]) do
    autoplace_controls_to_set_to_0_size[key] = {size = "none"}
end

data.raw["map-gen-presets"]["default"]["creative-world-plus"] =
{
	order = "w",
	basic_settings =
	{
		autoplace_controls = autoplace_controls_to_set_to_0_size,
        water = "none",
        cliff_settings = {
            name = "none",
            cliff_elevation_interval = 40,
            cliff_elevation_0 = 1024
        }
	},
    advanced_settings = {
        pollution = {
            enabled = false
        }
    }
}
