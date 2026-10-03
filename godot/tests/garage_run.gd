extends SceneTree

func _init() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main._start_solo()
	main.gurney.contact_monitor = true
	main.gurney.max_contacts_reported = 16
	var player = main.players[1]
	for i in 120: await physics_frame
	player.global_position = main.gurney.global_position + Vector3(0, -0.42, 2)
	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	assert(player.pushing, "E must attach to the gurney")
	for i in 120: await physics_frame
	assert(player.global_position.y < main.gurney.global_position.y, "Grab must keep feet below mattress")
	assert(absf(player.visual_root.position.y) < 0.01, "Idle grab must not bounce")
	player.set_physics_process(false)
	var targets := [Vector3(0, 0, -23), Vector3(0, 0, -24.7), Vector3(-14, 0, -24.7), Vector3(-28, 0, -27), Vector3(-29, 0, -39)]
	var waypoint := 0
	for tick in 18000:
		var pos: Vector3 = main.gurney.global_position
		var offset: Vector3 = targets[waypoint] - pos
		offset.y = 0
		if offset.length() < 1.5 and waypoint < targets.size() - 1:
			waypoint += 1
			print("WAYPOINT ", waypoint, " position ", pos)
		var yaw := atan2(-offset.x, -offset.z)
		var error := wrapf(yaw - main.gurney.rotation.y, -PI, PI)
		var steer := clampf(-error * 3.0 + main.gurney.angular_velocity.y * 2.0, -1, 1)
		var speed: float = main.gurney.linear_velocity.length()
		var brake := 1.0 if speed > 1.8 or absf(error) > 0.45 else 0.0
		main.gurney.set_player_input(1, Vector2(steer, -0.55 if absf(error) < 0.45 else 0.0), brake, true, main.gurney.global_position)
		await physics_frame
		if main.game_state != main.GameState.RUNNING:
			print("RESULT ", main.game_state, " waypoint ", waypoint, " position ", main.gurney.global_position)
			quit(0 if main.game_state == main.GameState.WON else 1)
			return
		if tick % 1200 == 0:
			for body in main.gurney.get_colliding_bodies(): print("CONTACT ", body.name)
		if tick % 1200 == 0: print("PROGRESS ", waypoint, " ", pos, " yaw ", main.gurney.rotation.y, " error ", error, " steer ", steer)
	push_error("Route timed out")
	quit(1)
