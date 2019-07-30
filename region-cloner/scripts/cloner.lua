require("scripts.common")

function correct_cloned_inserter_targets(entity_pool, vector, surface, force)
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
end

function copy_entity_pool(player, entity_pool, vector, surface, force)
    surface.clone_entities({entities=entity_pool, destination_offset=vector, destination_surface=surface, destination_force=force})
    correct_cloned_inserter_targets(entity_pool, vector, surface, force)
end
