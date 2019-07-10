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

script.on_event(defines.events.on_entity_cloned, function(event)
    copy_signals_in_flight(event.source, event.destination)
end)
