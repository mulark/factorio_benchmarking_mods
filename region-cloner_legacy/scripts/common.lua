GUI_ELEMENT_PREFIX = "region-cloner_"

--[[Ghosts will break script as it exists currently. Copying the player is annoying and only serves to clutter the map.]]
ENTITIES_TO_NOT_CLONE = {"player", "entity-ghost", "tile-ghost"}

TICKS_PER_PASTE = 2

--[[These types have defines.inventory.chest return their fuel slot, which mean we double copy their fuel]]
HAS_DEFINES_INVENTORY_CHEST_BUT_SHOULDNT_TYPES = {"locomotive", "car"}

--[[For 0.16.x setting a combinator inactive can cause the game to desync]]
--[[Beacons won't cause desyncs if they are set inactive, but this is just an easy way to prevent them from going inactive.]]
DESYNC_IF_ENTITIES_ARE_INACTIVE_ENTITIES = {"decider-combinator", "arithmetic-combinator", "beacon"}

--[[Low priority entities depend on other entities existing in the world first]]
--[[Beacons are here because wakeup lists for inserters won't tie to a car in certain designs, if the beacons exist. After the wakeup list is determined beacons can be placed.]]
--[[Robots will fly to a different robonetwork if their parent roboport exists after they do.]]
LOW_PRIORITY_ENTITIES = {"beacon", "logistic-robot", "construction-robot"}

ROLLING_STOCK_TYPES = {"locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon"}

debug_logging = false

function has_value (val, tab)
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
