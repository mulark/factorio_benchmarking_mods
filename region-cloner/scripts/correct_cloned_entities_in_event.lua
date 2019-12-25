require("scripts.common")

function copy_signals_in_flight(original_entity, cloned_entity)
    --Entities across surfaces can connect wires together, excepting copper wire
    --This doesnt copy across surfaces, I think it's cause it depends on which one is trying to connect to the other.
    --This works as far as normal cloning goes so I'll just commit it cause it'll clutter otherwise
    local connector = 0
    local merged_signals_clone
    local merged_signals_orig
    if is_nonconst_combinator(cloned_entity.type) then
        connector = defines.circuit_connector_id.combinator_output
        merged_signals_clone = cloned_entity.get_merged_signals(connector)
        merged_signals_orig = original_entity.get_merged_signals(connector)
    else
        merged_signals_clone = cloned_entity.get_merged_signals()
        merged_signals_orig = original_entity.get_merged_signals()
    end
    if (not merged_signals_clone and merged_signals_orig) then
        local cloned_entity_original_position = cloned_entity.position
        cloned_entity.teleport(original_entity.position)
        cloned_entity.connect_neighbour({wire=defines.wire_type.red, target_entity = original_entity, source_circuit_id = connector, target_circuit_id = connector})
        cloned_entity.connect_neighbour({wire=defines.wire_type.green, target_entity = original_entity, source_circuit_id = connector, target_circuit_id = connector})
        cloned_entity.teleport(cloned_entity_original_position)
        cloned_entity.disconnect_neighbour({wire=defines.wire_type.red, target_entity = original_entity, source_circuit_id = connector, target_circuit_id = connector})
        cloned_entity.disconnect_neighbour({wire=defines.wire_type.green, target_entity = original_entity, source_circuit_id = connector, target_circuit_id = connector})
    end
end

function copy_circuit_network_reference_connections(original_entity, cloned_entity)
    if (original_entity.circuit_connection_definitions) then
        --[[Add 3 arbitrary connections as when we do this action the number of circuit_connection_definitions can change. In practice only 2 will be needed for 99.99% of cases]]
        --[[1 connection will be used per wire type when copying signals. Bumping it up to 5]]
        for x=1, (#original_entity.circuit_connection_definitions + 5) do
            if (original_entity.circuit_connection_definitions[x]) then
                local targetent = original_entity.circuit_connection_definitions[x].target_entity
                local offset_x = (original_entity.position.x - targetent.position.x)
                local offset_y = (original_entity.position.y - targetent.position.y)
                local targetnewent = cloned_entity.surface.find_entity(targetent.name, {(cloned_entity.position.x - offset_x), (cloned_entity.position.y - offset_y)})
                if (targetnewent) then
                    local connection_formed = cloned_entity.connect_neighbour({target_entity = targetnewent, wire=original_entity.circuit_connection_definitions[x].wire, source_circuit_id=original_entity.circuit_connection_definitions[x].source_circuit_id, target_circuit_id=original_entity.circuit_connection_definitions[x].target_circuit_id})
                    if not (connection_formed) then
                        --[[Possibly these were too far apart, you can make them connected but far apart with teleporting]]
                        local cloned_entity_original_position = cloned_entity.position
                        cloned_entity.teleport(targetnewent.position)
                        cloned_entity.connect_neighbour({target_entity = targetnewent, wire=original_entity.circuit_connection_definitions[x].wire, source_circuit_id=original_entity.circuit_connection_definitions[x].source_circuit_id, target_circuit_id=original_entity.circuit_connection_definitions[x].target_circuit_id})
                        cloned_entity.teleport(cloned_entity_original_position)
                    end
                end
                targetent = nil
                offset_x = nil
                offset_y = nil
                targetnewent = nil
            end
        end
    end
    if is_copper_cable_connectable(original_entity.type) then
        if (original_entity.neighbours.copper) then
            for x=1, #original_entity.neighbours.copper do
                local targetent = original_entity.neighbours.copper[x]
                if (targetent.type ~= "electric-pole") then
                    --technically this is unnecessary cause you can't connect two power switches together with copper
                    return
                end
                local offset_x = (original_entity.position.x - targetent.position.x)
                local offset_y = (original_entity.position.y - targetent.position.y)
                local targetnewent = cloned_entity.surface.find_entity(targetent.name, {(cloned_entity.position.x - offset_x), (cloned_entity.position.y - offset_y)})
                if (targetnewent) then
                    local cloned_entity_original_position = cloned_entity.position
                    cloned_entity.teleport(targetnewent.position)
                    cloned_entity.connect_neighbour(targetnewent)
                    cloned_entity.teleport(cloned_entity_original_position)
                end
            end
        end
    end
end

function flip_rolling_stock(original_entity, cloned_entity)
    if not (original_entity.orientation == cloned_entity.orientation) then
        cloned_entity.disconnect_rolling_stock(defines.rail_direction.front)
        cloned_entity.disconnect_rolling_stock(defines.rail_direction.back)
        cloned_entity.rotate()
        cloned_entity.connect_rolling_stock(defines.rail_direction.front)
        cloned_entity.connect_rolling_stock(defines.rail_direction.back)
    end
    --[[We don't know which way we are connected, and we can't be sure that the other rolling stock have been cloned yet]]
    --[[The only edge case we could handle now is the one where we are both the front and back of this train IE: this train is 1 rolling stock long]]
    cloned_entity.train.manual_mode = original_entity.train.manual_mode
end

script.on_event(defines.events.on_entity_cloned, function(event)
    if (event.source.valid and event.destination.valid) then
        if is_circuit_network_connectable(event.source.type) then
            copy_signals_in_flight(event.source, event.destination)
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
