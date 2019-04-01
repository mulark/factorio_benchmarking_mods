local tiles_to_pave = settings.startup["creative-world-plus_tiles-to-pave"].value
local tile_type = settings.startup["creative-world-plus_tile-type"].value
if (tiles_to_pave == "All" or tiles_to_pave == "Land Tiles Only") then
    for _, tile in pairs (data.raw.tile) do
        if (tiles_to_pave == "All") then
            tile.autoplace = nil
        else
            if not string.find(tile.name, "water") then
                tile.autoplace = nil
            end
        end
    end
    data.raw.tile[tile_type].autoplace = {}
end
if (settings.startup["creative-world-plus_remove-rocks"].value == true) then
    --[[Simple entities with autoplace are the rocks]]
    for _, simple in pairs (data.raw["simple-entity"]) do
        simple.autoplace = nil
    end
end
if (settings.startup["creative-world-plus_remove-decorative"].value == true) then
    for _, decor in pairs (data.raw["optimized-decorative"]) do
        decor.autoplace = nil
    end
end
if (settings.startup["creative-world-plus_remove-fish"].value == true) then
    for _, fish in pairs (data.raw["fish"]) do
        fish.autoplace = nil
    end
end
