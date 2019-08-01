require("scripts.common")

--[[TODO Copy over the original with this method.]]

function copy_signals_in_flight(original_entity, cloned_entity)
    if not has_value(original_entity.type, {"decider-combinator", "arithmetic-combinator"}) then
        return
    end
    global.do_on_tick = true
    do_on_tick()
    local signals_to_copy = original_entity.get_control_behavior().signals_last_tick
    if not (signals_to_copy) then
        return
    end
    local num_signals = 0
    for _,__ in pairs (signals_to_copy) do
        num_signals = num_signals + 1
    end
    local combinators_needed = math.ceil(num_signals/18)
    local current_sig_index = 1
    for x=1, combinators_needed do
        local flag_next_combinator = false
        local count = 0
        for key, sig in pairs(signals_to_copy) do
            count = count + 1
        end
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

function copy_circuit_network_reference_connections (original_entity, cloned_entity)
    if (original_entity.circuit_connection_definitions) then
        --[[Add 50 arbitrary connections as when we do this action the number of circuit_connection_definitions is likely to change. In practice only 2 will be needed for 99.99% of cases]]
        for x=1, (#original_entity.circuit_connection_definitions + 50) do
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
    if (original_entity.type == "electric-pole") then
        if (original_entity.neighbours.copper) then
            for x=1, #original_entity.neighbours.copper do
                local targetent = original_entity.neighbours.copper[x]
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

function flip_rolling_stock_if_needed (original_entity, cloned_entity)
    if has_value(original_entity.type, ROLLING_STOCK_TYPES) then
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
end

script.on_event(defines.events.on_entity_cloned, function(event)
    if (event.source.valid and event.destination.valid) then
        copy_signals_in_flight(event.source, event.destination)
        copy_circuit_network_reference_connections(event.source, event.destination)
        flip_rolling_stock_if_needed(event.source, event.destination)
    end
end)
