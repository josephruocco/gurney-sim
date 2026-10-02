extends Node3D

const NetworkManagerScript = preload("res://scripts/network/network_manager.gd")
const PrototypeLevelScript = preload("res://scripts/levels/prototype_level.gd")
const PrototypeHUDScript = preload("res://scripts/ui/hud.gd")
const SharedGurneyScript = preload("res://scripts/entities/gurney.gd")
const SlidingPatientScript = preload("res://scripts/entities/patient.gd")
const GurneyPlayerScript = preload("res://scripts/entities/player.gd")
const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")
const PLAYER_COLORS := [Color("#d97058"), Color("#5c8fb1"), Color("#d8ae4e"), Color("#75a77d")]
var network: Node
var level: Node3D
var hud: CanvasLayer
var gurney: RigidBody3D
var patient: RigidBody3D
var players: Dictionary = {}
var sync_accumulator := 0.0
var game_camera: Camera3D
var received_world_sync := false
var camera_look_target := Vector3.ZERO
enum GameState { WAITING, RUNNING, WON, LOST }
var game_state := GameState.WAITING
var run_time := 0.0
var danger_time := 0.0
var player_names: Dictionary = {}
var ready_players: Dictionary = {}
var local_ready := false
var auto_ready := false
var audio: Node

func _ready() -> void:
	network = NetworkManagerScript.new(); add_child(network)
	level = PrototypeLevelScript.new(); add_child(level)
	hud = PrototypeHUDScript.new(); add_child(hud)
	audio = AudioManagerScript.new(); add_child(audio)
	_build_camera()
	_spawn_physics()
	network.peer_ready.connect(_server_peer_ready)
	network.peer_left.connect(_remove_peer)
	network.public_endpoint.connect(hud.set_internet_status)
	network.connection_message.connect(func(message: String):
		hud.status_label.text = message
		print("NETWORK ", message)
		if message.begins_with("Connected as player"):
			_register_name.rpc_id(1, _chosen_name())
			if auto_ready: _set_ready.rpc_id(1, true)
	)
	hud.solo_button.pressed.connect(func(): audio.play_click(); _start_solo())
	hud.host_button.pressed.connect(func(): audio.play_click(); _host_lobby())
	hud.join_button.pressed.connect(func(): audio.play_click(); _join_lobby())
	hud.ready_button.pressed.connect(func(): audio.play_click(); _toggle_ready())
	gurney.balance_changed.connect(func(_tilt: float, danger: float): _update_hud(danger))
	var args := OS.get_cmdline_user_args()
	auto_ready = "--autostart" in args
	if "--host" in args: _host_lobby()
	elif "--join" in args: _join_lobby()
	elif "--solo" in args: _start_solo()

func _chosen_name() -> String:
	var cleaned: String = hud.name_input.text.strip_edges().left(18)
	return cleaned if !cleaned.is_empty() else "Orderly"

func _start_solo() -> void:
	network.offline()
	player_names[1] = _chosen_name()
	ready_players[1] = true
	_apply_lobby_state(player_names, ready_players)
	_start_run.rpc()

func _host_lobby() -> void:
	var endpoint := _parse_endpoint(hud.address_input.text)
	if network.host(endpoint.port, !auto_ready) != OK: return
	hud.set_lobby_connected(true)
	_register_name( _chosen_name())
	if auto_ready: _set_ready(true)

func _join_lobby() -> void:
	var endpoint := _parse_endpoint(hud.address_input.text)
	if network.join(endpoint.host, endpoint.port) == OK:
		hud.set_lobby_connected(true)

func _parse_endpoint(value: String) -> Dictionary:
	var cleaned: String = value.strip_edges()
	var host: String = cleaned
	var port: int = network.PORT
	var separator := cleaned.rfind(":")
	if separator > 0 and separator < cleaned.length() - 1:
		host = cleaned.left(separator)
		var parsed_port := cleaned.substr(separator + 1).to_int()
		if parsed_port >= 1024 and parsed_port <= 65535: port = parsed_port
	if host.is_empty(): host = "127.0.0.1"
	return {"host": host, "port": port}

func _toggle_ready() -> void:
	local_ready = !local_ready
	hud.ready_button.text = "Cancel ready" if local_ready else "Ready up"
	_set_ready.rpc_id(1, local_ready)

func _build_camera() -> void:
	game_camera = Camera3D.new()
	game_camera.position = Vector3(6.5, 5.6, 10.5)
	game_camera.fov = 48.0
	game_camera.current = true
	add_child(game_camera)
	camera_look_target = Vector3(0, 0.8, 0.0)
	game_camera.look_at(camera_look_target)

func _spawn_physics() -> void:
	gurney = SharedGurneyScript.new()
	gurney.name = "SharedGurney"
	gurney.position = level.gurney_spawn()
	add_child(gurney)
	patient = SlidingPatientScript.new()
	patient.name = "Patient"
	patient.position = level.patient_spawn()
	add_child(patient)
	gurney.patient = patient

func _server_peer_ready(id: int) -> void:
	if !multiplayer.is_server(): return
	for existing_id in players:
		_spawn_player_everywhere.rpc_id(id, existing_id)
	_spawn_player_everywhere.rpc(id)
	_broadcast_lobby.rpc_id(id, player_names, ready_players)

func _remove_peer(id: int) -> void:
	if players.has(id):
		players[id].queue_free()
		players.erase(id)
	player_names.erase(id)
	ready_players.erase(id)
	if multiplayer.is_server(): _broadcast_lobby.rpc(player_names, ready_players)

@rpc("authority", "call_local", "reliable")
func _spawn_player_everywhere(id: int) -> void:
	if players.has(id): return
	var slot := players.size()
	var player: CharacterBody3D = GurneyPlayerScript.new()
	player.setup(id, slot, PLAYER_COLORS[slot % PLAYER_COLORS.size()])
	player.position = level.player_spawn_slot(slot)
	player.rotation.y = PI
	player.target_gurney = gurney
	players[id] = player
	add_child(player, true)
	if player.is_multiplayer_authority(): player.grab_changed.connect(audio.play_grab)
	if player_names.has(id): player.set_display_name(player_names[id])
	print("ROSTER local=%d spawned=%d slot=%d total=%d" % [multiplayer.get_unique_id(), id, slot, players.size()])

@rpc("any_peer", "call_local", "reliable")
func _register_name(requested_name: String) -> void:
	if !multiplayer.is_server(): return
	var sender := multiplayer.get_remote_sender_id()
	var id := sender if sender != 0 else multiplayer.get_unique_id()
	var cleaned: String = requested_name.strip_edges().left(18)
	player_names[id] = cleaned if !cleaned.is_empty() else "Orderly %d" % id
	ready_players[id] = false
	_broadcast_lobby.rpc(player_names, ready_players)

@rpc("any_peer", "call_local", "reliable")
func _set_ready(is_ready: bool) -> void:
	if !multiplayer.is_server(): return
	var sender := multiplayer.get_remote_sender_id()
	var id := sender if sender != 0 else multiplayer.get_unique_id()
	ready_players[id] = is_ready
	_broadcast_lobby.rpc(player_names, ready_players)
	if players.size() >= 2 and ready_players.size() >= players.size():
		for player_id in players:
			if !ready_players.get(player_id, false): return
		_start_run.rpc()

@rpc("authority", "call_local", "reliable")
func _broadcast_lobby(names: Dictionary, ready: Dictionary) -> void:
	_apply_lobby_state(names, ready)

func _apply_lobby_state(names: Dictionary, ready: Dictionary) -> void:
	player_names = names.duplicate()
	ready_players = ready.duplicate()
	hud.set_roster(player_names, ready_players)
	for id in players:
		if player_names.has(id): players[id].set_display_name(player_names[id])
	print("LOBBY local=%d players=%d ready=%d" % [multiplayer.get_unique_id(), player_names.size(), ready_players.values().count(true)])

@rpc("authority", "call_local", "reliable")
func _start_run() -> void:
	game_state = GameState.RUNNING
	run_time = 0.0
	danger_time = 0.0
	hud.hide_lobby()
	hud.hide_result()
	hud.set_run_time(0.0)

func _physics_process(delta: float) -> void:
	audio.set_gurney_speed(gurney.speed_kph())
	var flat_velocity := Vector3(gurney.linear_velocity.x, 0.0, gurney.linear_velocity.z)
	var speed_factor := clampf(flat_velocity.length() / 9.0, 0.0, 1.0)
	var forward := -gurney.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var camera_side := gurney.global_basis.x.normalized() * 4.8
	var desired_camera := gurney.global_position - forward * (9.0 + speed_factor * 2.5) + camera_side + Vector3.UP * (5.2 + speed_factor)
	var follow_weight := 1.0 - exp(-5.5 * delta)
	game_camera.global_position = game_camera.global_position.lerp(desired_camera, follow_weight)
	var desired_look := gurney.global_position + Vector3.UP * 0.65 + forward * (2.6 + speed_factor * 3.0)
	camera_look_target = camera_look_target.lerp(desired_look, 1.0 - exp(-7.0 * delta))
	game_camera.fov = lerpf(game_camera.fov, 48.0 + speed_factor * 8.0, 1.0 - exp(-3.0 * delta))
	game_camera.look_at(camera_look_target)
	gurney.freeze = !multiplayer.is_server() or game_state != GameState.RUNNING
	patient.freeze = !multiplayer.is_server() or game_state != GameState.RUNNING
	if !multiplayer.is_server(): return
	if game_state == GameState.WAITING:
		_sync_players_only()
		return
	if game_state != GameState.RUNNING:
		if Input.is_action_just_pressed("restart"): _restart_run.rpc()
		return
	run_time += delta
	hud.set_run_time(run_time)
	_evaluate_objective(delta)
	if game_state != GameState.RUNNING: return
	sync_accumulator += delta
	if sync_accumulator < 0.05: return
	sync_accumulator = 0.0
	var player_states := {}
	for id in players:
		player_states[id] = {"transform": players[id].global_transform, "pushing": players[id].pushing}
	_sync_world.rpc(gurney.global_transform, gurney.linear_velocity, gurney.angular_velocity, patient.global_transform, patient.linear_velocity, patient.angular_velocity, player_states, run_time)

func _sync_players_only() -> void:
	sync_accumulator += get_physics_process_delta_time()
	if sync_accumulator < 0.05: return
	sync_accumulator = 0.0
	var player_states := {}
	for id in players:
		player_states[id] = {"transform": players[id].global_transform, "pushing": false}
	_sync_lobby_players.rpc(player_states)

@rpc("authority", "call_remote", "unreliable_ordered", 3)
func _sync_lobby_players(player_states: Dictionary) -> void:
	for id in player_states:
		if players.has(id) and !players[id].is_multiplayer_authority():
			players[id].global_transform = player_states[id]["transform"]
			players[id].apply_synced_pose(false)

@rpc("authority", "call_remote", "unreliable_ordered", 2)
func _sync_world(gurney_transform: Transform3D, gurney_linear: Vector3, gurney_angular: Vector3, patient_transform: Transform3D, patient_linear: Vector3, patient_angular: Vector3, player_states: Dictionary, synced_time: float) -> void:
	if multiplayer.is_server(): return
	if !received_world_sync:
		received_world_sync = true
		print("WORLD_SYNC local=%d players=%d" % [multiplayer.get_unique_id(), player_states.size()])
	gurney.global_transform = gurney_transform
	gurney.linear_velocity = gurney_linear
	gurney.angular_velocity = gurney_angular
	patient.global_transform = patient_transform
	patient.linear_velocity = patient_linear
	patient.angular_velocity = patient_angular
	run_time = synced_time
	hud.set_run_time(run_time)
	for id in player_states:
		if players.has(id) and !players[id].is_multiplayer_authority():
			var state: Dictionary = player_states[id]
			players[id].global_transform = state["transform"]
			players[id].apply_synced_pose(state["pushing"])

func _update_hud(danger: float) -> void:
	var local_patient: Vector3 = gurney.global_transform.affine_inverse() * patient.global_position
	hud.set_telemetry(gurney.speed_kph(), danger, abs(local_patient.x))

func _evaluate_objective(delta: float) -> void:
	var patient_distance := patient.global_position.distance_to(gurney.global_position)
	var upright := absf(gurney.global_basis.y.dot(Vector3.UP))
	var danger := clampf((1.0 - upright) / 0.45, 0.0, 1.0)
	danger_time = danger_time + delta if danger > 0.92 else maxf(0.0, danger_time - delta * 2.0)
	if level.is_in_finish(gurney.global_position) and patient_distance < 3.0:
		_finish_run(true, "Safely discharged at street level")
	elif patient.global_position.y < -3.0 or patient_distance > 5.0:
		_finish_run(false, "The patient left the gurney")
	elif gurney.global_position.y < -4.0:
		_finish_run(false, "The gurney went over the edge")
	elif danger_time > 1.5:
		_finish_run(false, "The gurney tipped over")

func _finish_run(won: bool, reason: String) -> void:
	if game_state != GameState.RUNNING: return
	game_state = GameState.WON if won else GameState.LOST
	_sync_game_result.rpc(won, reason, run_time)

@rpc("authority", "call_local", "reliable")
func _sync_game_result(won: bool, reason: String, seconds: float) -> void:
	game_state = GameState.WON if won else GameState.LOST
	run_time = seconds
	hud.set_run_time(run_time)
	hud.show_result(won, reason, seconds)
	if won: audio.play_win()
	else: audio.play_loss()

@rpc("authority", "call_local", "reliable")
func _restart_run() -> void:
	game_state = GameState.RUNNING
	run_time = 0.0
	danger_time = 0.0
	gurney.global_position = level.gurney_spawn()
	gurney.global_rotation = Vector3.ZERO
	gurney.linear_velocity = Vector3.ZERO
	gurney.angular_velocity = Vector3.ZERO
	patient.global_position = level.patient_spawn()
	patient.global_rotation = Vector3.ZERO
	patient.linear_velocity = Vector3.ZERO
	patient.angular_velocity = Vector3.ZERO
	var ids := players.keys()
	ids.sort()
	for slot in ids.size():
		var id = ids[slot]
		players[id].global_position = level.player_spawn_slot(slot)
		players[id].pushing = false
		players[id].velocity = Vector3.ZERO
	hud.hide_result()
	hud.set_run_time(0.0)
