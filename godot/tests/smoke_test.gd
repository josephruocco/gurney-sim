extends SceneTree

func _init() -> void:
	var main_scene := load("res://scenes/main.tscn")
	assert(main_scene != null, "Main scene must load")
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	await process_frame
	assert(main.gurney != null, "Shared gurney must exist")
	assert(main.patient != null, "Sliding patient must exist")
	assert(main.gurney.mass > main.patient.mass, "Gurney should outweigh patient")
	assert(main.level.get_node_or_null("BalanceLedge") != null, "Garage needs a balance shortcut")
	assert(main.level.get_node_or_null("FinishZone") != null, "Garage needs a street-level finish")
	assert(main.level.is_in_finish(main.level.finish_position()), "Finish zone must recognize its center")
	assert(!main.level.is_in_finish(main.level.gurney_spawn()), "Start must not count as a finish")
	main._start_solo()
	await physics_frame
	main.players[1].set_physics_process(false)
	main.players[1].apply_synced_pose(true)
	assert(main.players[1].arms[0].rotation.x < -0.9, "Pushing pose must reach both arms toward the gurney")
	assert(main.players[1].collision_mask == 1, "Players should collide with the garage but not fight the gurney")
	var start_z: float = main.gurney.global_position.z
	main.gurney.set_player_input(1, Vector2(0, -1), 0.0, true, Vector3(0, 1, 4))
	for frame in 90:
		await physics_frame
	assert(main.gurney.global_position.z < start_z - 0.2, "Combined push input must move the shared gurney")
	main._finish_run(true, "Test delivery")
	assert(main.game_state == main.GameState.WON, "Finish should enter the won state")
	assert(main.hud.result_panel.visible, "A result should be shown to the player")
	main._restart_run()
	assert(main.game_state == main.GameState.RUNNING, "Restart should begin a new run")
	print("Milestone 1 smoke test passed")
	quit(0)
