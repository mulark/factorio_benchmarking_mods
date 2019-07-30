GUI_ELEMENT_PREFIX = "region-cloner_"

global.combinators_to_destroy_in_next_tick = {}

--[[Ghosts will break script as it exists currently. Copying the player is annoying and only serves to clutter the map. Adding character for 0.17.35+ support]]
ENTITIES_TO_NOT_CLONE = {"player", "character", "entity-ghost", "tile-ghost"}

ROLLING_STOCK_TYPES = {"locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon"}

debug_logging = false

function has_value(val, tab)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

function construct_bounding_box(left, top, right, bottom)
    local box = {}
    local left_top = {}
    local right_bottom = {}
    left_top["x"] = left
    left_top["y"] = top
    right_bottom["x"] = right
    right_bottom["y"] = bottom
    box["left_top"] = left_top
    box["right_bottom"] = right_bottom
    return box
end

function round(x)
    return x + 0.5 - (x + 0.5) % 1
end

function round_to_rail_grid_midpoint(x)
    local foo = math.floor(x)
    if (foo % 2 ~= 0) then
        return foo
    else
        return foo + 1
    end
end

function swap_to_fix_pairs(negative_most, positive_most)
    --[[You will not find any entites if your left top is to the right of your right bottom. Same for top/bottom.]]
    if (negative_most < positive_most) then
        return negative_most, positive_most
    end
    return positive_most, negative_most
end
