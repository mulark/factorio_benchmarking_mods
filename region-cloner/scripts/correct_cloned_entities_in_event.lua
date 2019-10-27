require("scripts.common")

--[[TODO Copy over the original with this method.]]

function copy_signals_in_flight(original_entity, cloned_entity)
    global.do_on_tick = true
    do_on_tick()
    local signals_to_copy = original_entity.get_control_behavior().signals_last_tick
    if not (signals_to_copy) then
        return
    end
    --Each combinator can hold max 18 signals at once.
    local combinators_needed = math.ceil(#signals_to_copy/18)
    local current_sig_index = 1
    for x=1, combinators_needed do
        local flag_next_combinator = false
        local combinator = cloned_entity.surface.create_entity{name="constant-combinator", force=cloned_entity.force, position=cloned_entity.position}
        combinator.connect_neighbour({wire=defines.wire_type.red, target_entity=cloned_entity, target_circuit_id=defines.circuit_connector_id.combinator_output})
        combinator.connect_neighbour({wire=defines.wire_type.green, target_entity=cloned_entity, target_circuit_id=defines.circuit_connector_id.combinator_output})
        if (global.combinators_to_destroy_in_next_tick) then
            table.insert(global.combinators_to_destroy_in_next_tick, combinator)
        else
            global.combinators_to_destroy_in_next_tick = {combinator}
        end
        for key, sig in pairs(signals_to_copy) do
            if not (flag_next_combinator) then
                if (current_sig_index <= 18) then
                    combinator.get_control_behavior().set_signal(current_sig_index, sig)
                    signals_to_copy[key] = nil
                    current_sig_index = current_sig_index + 1
                else
                    current_sig_index = 1
                    flag_next_combinator = true
                end
            end
        end
    end
end

function copy_circuit_network_reference_connections(original_entity, cloned_entity)
    if (original_entity.circuit_connection_definitions) then
        --[[Add 3 arbitrary connections as when we do this action the number of circuit_connection_definitions can change. In practice only 2 will be needed for 99.99% of cases]]
        for x=1, (#original_entity.circuit_connection_definitions + 3) do
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
                if (targetent.type ~= "electic-pole") then
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
        if is_nonconst_combinator(event.source.type) then
            copy_signals_in_flight(event.source, event.destination)
        end
        if is_circuit_network_connectable(event.source.type) then
            copy_circuit_network_reference_connections(event.source, event.destination)
        end
        if is_rolling_stock(event.source.type) then
            flip_rolling_stock(event.source, event.destination)
        end
    end
end)
