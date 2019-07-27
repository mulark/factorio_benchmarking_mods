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
        for x=1, #original_entity.circuit_connection_definitions do
            local targetent = original_entity.circuit_connection_definitions[x].target_entity
            local offset_x = (original_entity.position.x - targetent.position.x)
            local offset_y = (original_entity.position.y - targetent.position.y)
            local targetnewent = cloned_entity.surface.find_entity(targetent.name, {(cloned_entity.position.x - offset_x), (cloned_entity.position.y - offset_y)})
            if (targetnewent) then
                cloned_entity.connect_neighbour({target_entity = targetnewent, wire=original_entity.circuit_connection_definitions[x].wire, source_circuit_id=original_entity.circuit_connection_definitions[x].source_circuit_id, target_circuit_id=original_entity.circuit_connection_definitions[x].target_circuit_id})
            end
            targetent = nil
            offset_x = nil
            offset_y = nil
            targetnewent = nil
        end
    end
end

script.on_event(defines.events.on_entity_cloned, function(event)
    if (event.source.valid and event.destination.valid) then
        copy_signals_in_flight(event.source, event.destination)
        copy_circuit_network_reference_connections(event.source, event.destination)
    end
end)
