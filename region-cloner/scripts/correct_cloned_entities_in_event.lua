require("scripts.common")


function copy_circuit_network_reference_connections(original_entity, cloned_entity)
    for _, wire_connector_id in pairs (defines.wire_connector_id) do
        connector = original_entity.get_wire_connector(wire_connector_id)
        if connector ~= nil then
            for _,connection in pairs(connector.connections) do
                local targetent = connection.target.owner
                local target_wire_connector_id = connection.target.wire_connector_id
                local offset_x = (original_entity.position.x - targetent.position.x)
                local offset_y = (original_entity.position.y - targetent.position.y)
                local targetnewent = cloned_entity.surface.find_entity({name=targetent.name, quality=targetent.quality}, {(cloned_entity.position.x - offset_x), (cloned_entity.position.y - offset_y)})
                if targetnewent ~= nil then
                    local cloned_connector = cloned_entity.get_wire_connector(wire_connector_id, true)
                    local cloned_connector_reference = targetnewent.get_wire_connector(target_wire_connector_id, true)
                    if cloned_connector_reference ~= nil then
                        --game.print("Connecting " .. serpent.line(cloned_connector) .. " to " .. serpent.line(cloned_connector_reference))
                        cloned_connector.connect_to(cloned_connector_reference, false)
                    else
                        -- Space platforms cloned to empty space means stuff dies leading to these being invalid before we set up the connection
                        -- However, I don't know why sometimes the platform dies completely, and sometimes it doesn't
                        -- it's supposed to be that if a platform is split in two the part without the hub dies
                        --game.print("ERROR: did not get a valid connector reference from " .. serpent.line(cloned_connector) .. " to " .. serpent.line(targetnewent))
                    end
                end
                targetent = nil
                offset_x = nil
                offset_y = nil
                targetnewent = nil
            end
        end
    end
end


function flip_rolling_stock(original_entity, cloned_entity)
    if not (original_entity.orientation == cloned_entity.orientation) then
        -- check if probably backwards (true backwards is 0.5 delta)
        if math.abs(original_entity.orientation - cloned_entity.orientation) > 0.4 then
            cloned_entity.disconnect_rolling_stock(defines.rail_direction.front)
            cloned_entity.disconnect_rolling_stock(defines.rail_direction.back)
            cloned_entity.rotate()
            cloned_entity.connect_rolling_stock(defines.rail_direction.front)
            cloned_entity.connect_rolling_stock(defines.rail_direction.back)
        end
    end
    --[[We don't know which way we are connected, and we can't be sure that the
        other rolling stock have been cloned yet]]
    --[[The only edge case we could handle now is the one where we are both the
        front and back of this train IE: this train is 1 rolling stock long]]
end

function fix_wall_hitbox(cloned_entity)
    -- Teleports to the same location. If using region-cloner the chunk will be
    -- generated by now, so the hitboxes will no longer connect to the phantom
    -- out-of-map tiles
    cloned_entity.teleport(0, 0)
end

script.on_event(defines.events.on_entity_cloned, function(event)
    if (event.source.valid and event.destination.valid) then
        if is_circuit_network_connectable(event.source.type) then
            copy_circuit_network_reference_connections(event.source, event.destination)
        end
        --TODO don't flip rolling stock anymore?
        if is_rolling_stock(event.source.type) then
            event.destination.train.manual_mode = event.source.train.manual_mode
            if false then
                flip_rolling_stock(event.source, event.destination)
            end
        end
    end
end)

script.on_event(defines.events.on_chunk_generated, function(event)
    if (debug_logging) then
        log("Chunk generated " .. serpent.block(event))
    end
    for _,ent in pairs(event.surface.find_entities_filtered({area=event.area, type="wall"})) do
        fix_wall_hitbox(ent)
    end
end)
