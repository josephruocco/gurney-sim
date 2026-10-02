extends Node3D

const NetworkManagerScript = preload("res://scripts/network/network_manager.gd")
const PrototypeLevelScript = preload("res://scripts/levels/prototype_level.gd")
const PrototypeHUDScript = preload("res://scripts/ui/hud.gd")
const SharedGurneyScript = preload("res://scripts/entities/gurney.gd")
const SlidingPatientScript = preload("res://scripts/entities/patient.gd")
const GurneyPlayerScript = preload("res://scripts/entities/player.gd")
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

func _ready() -> void:
	network = NetworkManagerScript.new(); add_child(network)
	level = PrototypeLevelScript.new(); add_child(level)
	hud = PrototypeHUDScript.new(); add_child(hud)
	_build_camera()
	_spawn_physics()
	network.peer_ready.connect(_server_peer_ready)
	network.connection_message.connect(func(message: String):
		hud.status_label.text = message
		print("NETWORK ", message)
	)
	hud.solo_button.pressed.connect(func(): network.offline())
	hud.host_button.pressed.connect(func(): network.host())
	hud.join_button.pressed.connect(func(): network.join())
	gurney.balance_changed.connect(func(_tilt: float, danger: float): _update_hud(danger))
	var args := OS.get_cmdline_user_args()
	if "--host" in args: network.host()
	elif "--join" in args: network.join()
	elif "--solo" in args: network.offline()

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

@rpc("authority", "call_local", "reliable")
func _spawn_player_everywhere(id: int) -> void:
	if players.has(id): return
	var player: CharacterBody3D = GurneyPlayerScript.new()
	player.setup(id, PLAYER_COLORS[(id - 1) % PLAYER_COLORS.size()])
	player.position = level.player_spawn(id)
	player.rotation.y = PI
	player.target_gurney = gurney
	players[id] = player
	add_child(player, true)
	print("ROSTER local=%d spawned=%d total=%d" % [multiplayer.get_unique_id(), id, players.size()])

func _physics_process(delta: float) -> void:
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
	gurney.freeze = !multiplayer.is_server()
	patient.freeze = !multiplayer.is_server()
	if !multiplayer.is_server(): return
	sync_accumulator += delta
	if sync_accumulator < 0.05: return
	sync_accumulator = 0.0
	var player_states := {}
	for id in players:
		player_states[id] = {"transform": players[id].global_transform, "pushing": players[id].pushing}
	_sync_world.rpc(gurney.global_transform, gurney.linear_velocity, gurney.angular_velocity, patient.global_transform, patient.linear_velocity, patient.angular_velocity, player_states)

@rpc("authority", "call_remote", "unreliable_ordered", 2)
func _sync_world(gurney_transform: Transform3D, gurney_linear: Vector3, gurney_angular: Vector3, patient_transform: Transform3D, patient_linear: Vector3, patient_angular: Vector3, player_states: Dictionary) -> void:
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
	for id in player_states:
		if players.has(id) and !players[id].is_multiplayer_authority():
			var state: Dictionary = player_states[id]
			players[id].global_transform = state["transform"]
			players[id].apply_synced_pose(state["pushing"])

func _update_hud(danger: float) -> void:
	var local_patient: Vector3 = gurney.global_transform.affine_inverse() * patient.global_position
	hud.set_telemetry(gurney.speed_kph(), danger, abs(local_patient.x))
