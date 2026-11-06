extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main._start_solo()
	await physics_frame
	assert(main.players.size() == 2)
	var bot = main.players[2]
	var human = main.players[1]
	assert(bot.is_bot and main.game_state == main.GameState.RUNNING)
	human.set_physics_process(false)
	human.pushing = true
	human.local_input = Vector2(0.4, -1)
	bot._tick_bot(0.016)
	assert(bot.local_input.is_equal_approx(human.local_input * 0.35))
	human.pushing = false
	bot._tick_bot(0.016)
	assert(bot.local_input == Vector2.ZERO and bot.brake_strength > 0)
	main._restart_run()
	bot._tick_bot(0.016)
	assert(bot.pushing)
	main.game_state = main.GameState.LOST
	bot._tick_bot(0.016)
	assert(!bot.pushing and bot.local_input == Vector2.ZERO)
	print("NPC assistance, idle braking, restart and end-state checks passed")
	quit()
