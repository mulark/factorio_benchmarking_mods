--[[Ghosts will break script as it exists currently. Copying the player is annoying and only serves to clutter the map.]]
entities_to_not_clone = {"player", "entity-ghost", "tile-ghost"}

TICKS_PER_PASTE = 2

--[[For 0.16.x setting a combinator inactive can cause the game to desync]]
desync_if_entities_are_inactive_entities = {"decider-combinator", "arithmetic-combinator"}

--[[Low priority entities depend on other entities existing in the world first]]
--[[Beacons are here because wakeup lists for inserters won't tie to a car in certain designs, if the beacons exist. After the wakeup list is determined beacons can be placed.]]
--[[Trains require rails to be placed first, robots will fly to a different robonetwork if their parent roboport exists after they do.]]
low_priority_entities = {"beacon", "locomotive", "cargo-wagon", "logistic-robot", "construction-robot", "fluid-wagon"}

function has_value (val, tab)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end
