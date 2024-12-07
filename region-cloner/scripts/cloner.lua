require("scripts.common")

function correct_cloned_inserter_targets(entity_pool, vector, surface, force)
    if (debug_logging) then
        log("entered correct_cloned_inserter_targets()")
    end
    --[[For each inserter, we should ensure we are linked to the same pickup_target and drop_target as the original]]
    for _, inserter in pairs(entity_pool) do
        local cloned_inserter
        if (inserter.type == "inserter") then
            cloned_inserter = surface.find_entity(inserter.name, {inserter.position.x + vector.x, inserter.position.y + vector.y})
        end
        if (cloned_inserter) then
            if (inserter.drop_target) then
                if (cloned_inserter.drop_target) then
                    if (inserter.drop_target.name ~= cloned_inserter.drop_target.name) then
                        --[[We have cloned an inserter but are not linked to the proper target]]
                        local intended_drop_target = surface.find_entity(inserter.drop_target.name, {inserter.drop_target.position.x + vector.x, inserter.drop_target.position.y + vector.y})
                        if (intended_drop_target) then
                            cloned_inserter.drop_target = intended_drop_target
                        end
                    end
                else
                    local intended_drop_target = surface.find_entity(inserter.drop_target.name, {inserter.drop_target.position.x + vector.x, inserter.drop_target.position.y + vector.y})
                    if (intended_drop_target) then
                        cloned_inserter.drop_target = intended_drop_target
                    end
                end
            end
            if (inserter.pickup_target) then
                if (cloned_inserter.pickup_target) then
                    if (inserter.pickup_target.name ~= cloned_inserter.pickup_target.name) then
                        --[[We have cloned an inserter but are not linked to the proper target]]
                        local intended_pickup_target = surface.find_entity(inserter.pickup_target.name, {inserter.pickup_target.position.x + vector.x, inserter.pickup_target.position.y + vector.y})
                        if (intended_pickup_target) then
                            cloned_inserter.pickup_target = intended_pickup_target
                        end
                    end
                else
                    local intended_pickup_target = surface.find_entity(inserter.pickup_target.name, {inserter.pickup_target.position.x + vector.x, inserter.pickup_target.position.y + vector.y})
                    if (intended_pickup_target) then
                        cloned_inserter.pickup_target = intended_pickup_target
                    end
                end
            end
        end
    end
    if (debug_logging) then
        log("finished clear_paste_area()")
    end
end

function smart_chart(player, tpx, tpy, current_paste, bounding_box)
    local new_box = convert_bounding_box_to_current_paste_region(tpx, tpy, current_paste, bounding_box)
    player.force.chart(player.surface, new_box)
end

function convert_bounding_box_to_current_paste_region(tpx, tpy, current_paste, bounding_box)
    local modified_box = {}
    local left_top = {}
    local right_bottom = {}
    left_top["x"] = bounding_box.left_top.x + (tpx * current_paste)
    left_top["y"] = bounding_box.left_top.y + (tpy * current_paste)
    --[[Subtract 0.01 tiles off of the returned bounding_box because it will chart the next chunk over if bounding_box is at the tile border]]
    right_bottom["x"] = bounding_box.right_bottom.x + (tpx * current_paste) - 0.01
    right_bottom["y"] = bounding_box.right_bottom.y + (tpy * current_paste) - 0.01
    modified_box["left_top"] = left_top
    modified_box["right_bottom"] = right_bottom
    return modified_box
end

function copy_entity_pool(player, entity_pool, vector, surface, force)
    if (debug_logging) then
        log("entered copy_entity_pool()")
    end
    surface.clone_entities({entities=entity_pool, destination_offset=vector, destination_surface=surface, destination_force=force, create_build_effect_smoke=false})
    correct_cloned_inserter_targets(entity_pool, vector, surface, force)
    if (debug_logging) then
        log("finished copy_entity_pool()")
    end
end

function copy_lite_entity_pool(player, lite_entity_pool, vector, surface, force)
    if (debug_logging) then
        log("entered copy_lite_entity_pool()")
    end
    -- Pointless code duplication required by 0.18.27, since on_entity_cloned
    -- is no longer available
    for _,original in pairs(lite_entity_pool) do
        local cloned = surface.create_entity({name=original.name, position = {original.position.x + vector.x, original.position.y + vector.y}, force = force, create_build_effect_smoke = false, direction = original.direction, quality = original.quality})
        if cloned and original.valid then
            local event = {source=original, destination=cloned}
            if is_circuit_network_connectable(event.source.type) then
                copy_circuit_network_reference_connections(event.source, event.destination)
            end
            --TODO don't flip rolling stock anymore?
            -- Workaround to handle rolling stock with speed being cloned
            -- to the wrong position.
            -- See https://forums.factorio.com/viewtopic.php?f=7&t=92271
            -- and https://forums.factorio.com/viewtopic.php?f=48&t=68329
            if (is_rolling_stock(event.source.type)) then
                flip_rolling_stock(event.source, event.destination)
                -- Clone the remaining rolling stock properties
                -- Handles arty ammo and loco fuel too, crappy API
                if (event.destination.get_inventory(defines.inventory.cargo_wagon)) then
                    for _,item in pairs(event.source.get_inventory(defines.inventory.cargo_wagon).get_contents()) do
                        event.destination.get_inventory(defines.inventory.cargo_wagon).insert({name = item.name, count = item.count, quality = item.quality})
                    end
                end
                -- Copy inv before copying bar (possibly)
                event.destination.copy_settings(event.source)
                event.destination.train.manual_mode = event.source.train.manual_mode
                event.destination.train.schedule = event.source.train.schedule
                if (event.destination.burner) then
                    event.destination.burner.currently_burning = event.source.burner.currently_burning
                    event.destination.burner.remaining_burning_fuel = event.source.burner.remaining_burning_fuel
                end
                event.destination.train.speed = event.source.train.speed

                if event.destination.fluidbox then
                    for i=1, #event.destination.fluidbox do
                        event.destination.fluidbox[i] = event.source.fluidbox[i]
                    end
                end

            end
        end
    end
    if (debug_logging) then
        log("finished copy_lite_entity_pool()")
    end
end
