GUI_ELEMENT_PREFIX = "region-cloner_"

global.combinators_to_destroy_in_next_tick = {}

debug_logging = false

function has_value(val, tab)
    --Slow path for non-critical comparisons.
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

function construct_safe_bounding_box(left, top, right, bottom)
    --Same as construct, but will swap pairs if needed
    left, right = swap_to_fix_pairs(left,right)
    top, bottom = swap_to_fix_pairs(top,bottom)
    return construct_bounding_box(left,top,right,bottom)
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

--ROLLING_STOCK_TYPES = {"locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon"}
function is_rolling_stock(type)
    if type == "locomotive" then return true end
    if type == "cargo-wagon" then return true end
    if type == "fluid-wagon" then return true end
    if type == "artillery-wagon" then return true end
    return false
end

--[[Ghosts will break script as it exists currently. Copying the player is annoying and only serves to clutter the map. Adding character for 0.17.35+ support]]
--player no longer does anything, keeping it doesn't hurt anything though.
--ENTITIES_TO_NOT_CLONE = {"player", "character", "entity-ghost", "tile-ghost"}
function is_ignored_entity_type(type)
    if type == "player" then return true end
    if type == "character" then return true end
    if type == "entity-ghost" then return true end
    if type == "tile-ghost" then return true end
    return false
end

--{"electric-pole", "power-switch"}
function is_copper_cable_connectable(type)
    if type == "electric-pole" then return true end
    if type == "power-switch" then return true end
    return false
end

--{"decider-combinator", "arithmetic-combinator"}
function is_combinator(type)
    if type == "decider-combinator" then return true end
    if type == "arithmetic-combinator" then return true end
    if type == "constant-combinator" then return true end
    return false
end

function is_circuit_network_connectable(type)
    if type == "accumulator" then return true end
    if type == "arithmetic-combinator" then return true end
    if type == "constant-combinator" then return true end
    if type == "container" then return true end
    if type == "decider-combinator" then return true end
    if type == "electric-pole" then return true end
    if type == "infinity-container" then return true end
    if type == "inserter" then return true end
    if type == "lamp" then return true end
    if type == "logistic-container" then return true end
    if type == "mining-drill" then return true end
    if type == "offshore-pump" then return true end
    if type == "power-switch" then return true end
    if type == "programmable-speaker" then return true end
    if type == "pump" then return true end
    if type == "rail-chain-signal" then return true end
    if type == "rail-signal" then return true end
    if type == "roboport" then return true end
    if type == "storage-tank" then return true end
    if type == "train-stop" then return true end
    if type == "transport-belt" then return true end
    if type == "wall" then return true end
    return false
end
