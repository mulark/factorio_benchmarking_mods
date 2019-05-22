script.on_event(defines.events.on_tick, function(event)
    game.tick_paused = true
    log(game.tick)
end)
