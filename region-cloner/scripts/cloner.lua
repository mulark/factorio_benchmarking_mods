require("scripts.common")
require("scripts.copy_circuit_network_signals")

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
                        local intended_drop_target = surface.find_entity(inserter.drop_target.name,     {inserter.drop_target.position.x + vector.x, inserter.drop_target.position.y + vector.y})
                        if (intended_drop_target) then
                            cloned_inserter.drop_target = intended_drop_target
                        end
                    end
                else
                    local intended_drop_target = surface.find_entity(inserter.drop_target.name,     {inserter.drop_target.position.x + vector.x, inserter.drop_target.position.y + vector.y})
                    if (intended_drop_target) then
                        cloned_inserter.drop_target = intended_drop_target
                    end
                end
            end
            if (inserter.pickup_target) then
                if (cloned_inserter.pickup_target) then
                    if (inserter.pickup_target.name ~= cloned_inserter.pickup_target.name) then
                        --[[We have cloned an inserter but are not linked to the proper target]]
                        local intended_pickup_target = surface.find_entity(inserter.pickup_target.name,     {inserter.pickup_target.position.x + vector.x, inserter.pickup_target.position.y + vector.y})
                        if (intended_pickup_target) then
                            cloned_inserter.pickup_target = intended_pickup_target
                        end
                    end
                else
                    local intended_pickup_target = surface.find_entity(inserter.pickup_target.name,     {inserter.pickup_target.position.x + vector.x, inserter.pickup_target.position.y + vector.y})
                    if (intended_pickup_target) then
                        cloned_inserter.pickup_target = intended_pickup_target
                    end
                end
            end
        end
    end
end

function copy_entity(original_entity, cloned_entity, surface)
    cloned_entity.copy_settings(original_entity)
    copy_inventories_and_fluid(original_entity, cloned_entity)
    copy_train(original_entity, cloned_entity)
    --[[updating connections probably doesn't do anything, since anything that could be affected by a beacon already exists by the time beacons are cloned]]
    --[[It also updates miners so they see any newly placed ore underneath them, Ill leave it since it probably wont break anything, except the wrong ore generating under a miner]]
    cloned_entity.update_connections()
    if (original_entity.health) then
        cloned_entity.health = original_entity.health
    end
    if (original_entity.burner) then
        if (original_entity.burner.currently_burning) then
            cloned_entity.burner.currently_burning = original_entity.burner.currently_burning
            cloned_entity.burner.remaining_burning_fuel = original_entity.burner.remaining_burning_fuel
        end
    end
end

--[[TODO actually pass the inventories which ought to be copied]]
local function internal_inventory_copy(original_entity, cloned_entity, INV_DEFINE)
    if (original_entity.get_inventory(INV_DEFINE)) then
        local working_inventory = original_entity.get_inventory(INV_DEFINE)
        for k=1, #working_inventory do
            if (working_inventory[k].valid_for_read) then
                cloned_entity.get_inventory(INV_DEFINE).insert(working_inventory[k])
            end
        end
        working_inventory = nil
    end
end

function copy_inventories_and_fluid(original_entity, cloned_entity)
    --[[Defines are not strict which means certain entities have inventory defines which make no sense]]
    if not has_value(original_entity.type, HAS_DEFINES_INVENTORY_CHEST_BUT_SHOULDNT_TYPES) then
        --[[Please wube why is this necessary?]]
        internal_inventory_copy(original_entity, cloned_entity, defines.inventory.chest)
    end
    internal_inventory_copy(original_entity, cloned_entity, defines.inventory.rocket_silo_result)
    --[[Furnace source and result here copy assembling machine inventories as well]]
    internal_inventory_copy(original_entity, cloned_entity, defines.inventory.furnace_source)
    internal_inventory_copy(original_entity, cloned_entity, defines.inventory.furnace_result)
    if (original_entity.get_module_inventory()) then
        local working_inventory = original_entity.get_module_inventory()
        for k=1,#working_inventory do
            if (working_inventory[k].valid_for_read) then
                cloned_entity.insert(working_inventory[k])
            end
        end
    end
    if (original_entity.get_fuel_inventory()) then
        local working_inventory = original_entity.get_fuel_inventory()
        for k=1,#working_inventory do
            if (working_inventory[k].valid_for_read) then
                cloned_entity.insert(working_inventory[k])
            end
        end
    end
    if (#original_entity.fluidbox >= 1) then
        for x=1, #original_entity.fluidbox do
            cloned_entity.fluidbox[x] = original_entity.fluidbox[x]
        end
    end
end

function copy_train(original_entity, cloned_entity)
    if (original_entity.train) then
        cloned_entity.disconnect_rolling_stock(defines.rail_direction.front)
        cloned_entity.disconnect_rolling_stock(defines.rail_direction.back)
        cloned_entity.train.schedule = original_entity.train.schedule
        if (original_entity.orientation <= 0.5) then
            if (original_entity.orientation ~= 0) then
                cloned_entity.rotate()
            end
        end
        cloned_entity.connect_rolling_stock(defines.rail_direction.front)
        cloned_entity.connect_rolling_stock(defines.rail_direction.back)
        cloned_entity.copy_settings(original_entity)
        cloned_entity.train.manual_mode = original_entity.train.manual_mode
    end
end

local function copy_trains_and_required_rails(entity_pool, surface, vector)
    local rail_pool = {}
    for key,ent in pairs(entity_pool) do
        if not (ent.can_be_destroyed()) then
            --[[If rails are not destroyable then they must have a train on them]]
            table.insert(rail_pool, ent)
        end
    end
    for _,ent in pairs(rail_pool) do
        surface.create_entity({name = ent.name, position = {vector.x + ent.position.x, vector.y + ent.position.y}, force = ent.force, direction = ent.direction})
    end
    for key,ent in pairs(entity_pool) do
        if has_value(ent.type, ROLLING_STOCK_TYPES) then
            local new_ent = surface.create_entity({name=ent.name, position={vector.x + ent.position.x, vector.y + ent.position.y}, force=ent.force, direction=ent.direction})
            if (new_ent) then
                copy_entity(ent, new_ent, surface)
            else
                --[[If two trains are colliding we can fail to create a rolling stock in the space]]
                game.print("Something went horribly wrong when we tried to copy a rolling stock! Probably due to game engine limitations.")
                if (debug_logging) then
                    log("We tried to copy a rolling stock but failed horribly.")
                end
            end
        end
    end
end

function copy_remaining_rails(entity_pool)
    for _,ent in pairs(entity_pool) do
        local copy = surface.create_entity({name = ent.name, position = {vector.x + ent.position.x, vector.y + ent.position.y}, force = ent.force, direction = ent.direction})
        if (copy) then
            copy_entity (ent, copy, surface)
        end
    end
end


function copy_blacklisted_entity_pool(player, entity_pool, vector, surface, force)
    copy_trains_and_required_rails(entity_pool, surface, vector)
    copy_remaining_rails(entity_pool)
end

function copy_entity_pool(player, entity_pool, vector, surface, force)
    surface.clone_entities({entities=entity_pool, destination_offset=vector, destination_surface=surface, destination_force=force})
    correct_cloned_inserter_targets(entity_pool, vector, surface, force)
end
