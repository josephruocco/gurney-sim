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
	assert(main.level.get_node_or_null("BalanceBeam") != null, "Prototype needs a balance beam")
	main.network.offline()
	await physics_frame
	main.players[1].set_physics_process(false)
	var start_z: float = main.gurney.global_position.z
	main.gurney.set_player_input(1, Vector2(0, -1), 0.0, true, Vector3(0, 1, 4))
	for frame in 30:
		await physics_frame
	assert(main.gurney.global_position.z < start_z - 0.05, "Combined push input must move the shared gurney")
	print("Milestone 1 smoke test passed")
	quit(0)
