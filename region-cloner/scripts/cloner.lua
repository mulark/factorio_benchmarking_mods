require("scripts.common")

function correct_cloned_inserter_targets(entity_pool, vector, source_surface, destination_surface, force)
    if (debug_logging) then
        log("entered correct_cloned_inserter_targets()")
    end
    --[[For each inserter, we should ensure we are linked to the same pickup_target and drop_target as the original]]
    for _, inserter in pairs(entity_pool) do
        local cloned_inserter
        if (inserter.type == "inserter") then
            cloned_inserter = destination_surface.find_entity(inserter.name, {inserter.position.x + vector.x, inserter.position.y + vector.y})
        end
        if (cloned_inserter) then
            if (inserter.drop_target) then
                if (cloned_inserter.drop_target) then
                    if (inserter.drop_target.name ~= cloned_inserter.drop_target.name) then
                        --[[We have cloned an inserter but are not linked to the proper target]]
                        local intended_drop_target = destination_surface.find_entity(inserter.drop_target.name, {inserter.drop_target.position.x + vector.x, inserter.drop_target.position.y + vector.y})
                        if (intended_drop_target) then
                            cloned_inserter.drop_target = intended_drop_target
                        end
                    end
                else
                    local intended_drop_target = destination_surface.find_entity(inserter.drop_target.name, {inserter.drop_target.position.x + vector.x, inserter.drop_target.position.y + vector.y})
                    if (intended_drop_target) then
                        cloned_inserter.drop_target = intended_drop_target
                    end
                end
            end
            if (inserter.pickup_target) then
                if (cloned_inserter.pickup_target) then
                    if (inserter.pickup_target.name ~= cloned_inserter.pickup_target.name) then
                        --[[We have cloned an inserter but are not linked to the proper target]]
                        local intended_pickup_target = destination_surface.find_entity(inserter.pickup_target.name, {inserter.pickup_target.position.x + vector.x, inserter.pickup_target.position.y + vector.y})
                        if (intended_pickup_target) then
                            cloned_inserter.pickup_target = intended_pickup_target
                        end
                    end
                else
                    local intended_pickup_target = destination_surface.find_entity(inserter.pickup_target.name, {inserter.pickup_target.position.x + vector.x, inserter.pickup_target.position.y + vector.y})
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

function smart_chart(player, tpx, tpy, current_paste, bounding_box, destination_surface)
    if bounding_box == nil then
        return
    end
    local new_box = convert_bounding_box_to_current_paste_region(tpx, tpy, current_paste, bounding_box)
    player.force.chart(destination_surface, new_box)
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

function copy_tiles(tiles, vector, destination_surface)
    local transformed_tiles = {}
    local hidden_tiles = {}
    local double_hidden_tiles = {}
    for _,tile in pairs(tiles) do
        local transform = {
            name=tile.name,
            position={
                tile.position.x + vector.x,
                tile.position.y + vector.y
            }
        }
        table.insert(transformed_tiles, transform)
        if tile.hidden_tile ~= nil then
            local hidden = {
                name=tile.hidden_tile,
                position={
                    tile.position.x + vector.x,
                    tile.position.y + vector.y
                }
            }
            table.insert(hidden_tiles, hidden)
            if tile.double_hidden_tile ~= nil then
                local double_hidden = {
                    name=tile.double_hidden_tile,
                    position={
                        tile.position.x + vector.x,
                        tile.position.y + vector.y
                    }
                }
                table.insert(double_hidden_tiles, double_hidden)
            end
        end
    end
    destination_surface.set_tiles(transformed_tiles, true, false)
    for _,hidden in pairs(hidden_tiles) do
        destination_surface.set_hidden_tile(hidden.position, hidden.name)
    end
    for _,double_hidden in pairs(double_hidden_tiles) do
        destination_surface.set_double_hidden_tile(double_hidden.position, double_hidden.name)
    end
end

function copy_entity_pool(player, entity_pool, vector, source_surface, destination_surface, force)
    if (debug_logging) then
        log("entered copy_entity_pool()")
    end
    source_surface.clone_entities({entities=entity_pool, destination_offset=vector, destination_surface=destination_surface, create_build_effect_smoke=false})
    correct_cloned_inserter_targets(entity_pool, vector, source_surface, destination_surface, force)
    if (debug_logging) then
        log("finished copy_entity_pool()")
    end
end

function copy_lite_entity_pool(player, lite_entity_pool, vector, source_surface, destination_surface, force)
    if (debug_logging) then
        log("entered copy_lite_entity_pool()")
    end
    -- Pointless code duplication required by 0.18.27, since on_entity_cloned
    -- is no longer available
    for _,original in pairs(lite_entity_pool) do
        local cloned = destination_surface.create_entity({name=original.name, position = {original.position.x + vector.x, original.position.y + vector.y}, force = force, create_build_effect_smoke = false, direction = original.direction, quality = original.quality})
        if cloned and original.valid then
            local event = {source=original, destination=cloned}
            if is_circuit_network_connectable(event.source.type) then
                copy_circuit_network_reference_connections(event.source, event.destination)
            end
        end
    end
    if (debug_logging) then
        log("finished copy_lite_entity_pool()")
    end
end

function copy_platform_specifics(source_platform, destination_platform)
    local src_hub = source_platform.hub
    local dest_hub = destination_platform.hub
    dest_hub.copy_settings(src_hub)

    for _, inv_define in ipairs({defines.inventory.hub_main, defines.inventory.hub_trash}) do
        for _, item in pairs(src_hub.get_inventory(inv_define).get_contents()) do
            dest_hub.get_inventory(inv_define).insert(item)
        end
    end

    local src_sections = src_hub.get_logistic_sections()
    for i, section in ipairs(dest_hub.get_logistic_sections().sections) do
        if section.is_manual then
            section.active = src_sections.get_section(i).active
        end
    end

    if source_platform.space_connection ~= nil then
        destination_platform.space_connection = source_platform.space_connection
        destination_platform.distance = source_platform.distance
    end

    destination_platform.completed_trips = source_platform.completed_trips
    destination_platform.paused = source_platform.paused
    destination_platform.speed = source_platform.speed

    local dest_schedule = destination_platform.get_schedule()
    local src_schedule = source_platform.get_schedule()
    dest_schedule.go_to_station(src_schedule.current)
    dest_schedule.set_stopped(source_platform.paused)

    copy_circuit_network_reference_connections(src_hub, dest_hub)
end