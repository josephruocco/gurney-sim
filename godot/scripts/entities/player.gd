class_name GurneyPlayer
extends CharacterBody3D

signal grab_changed(grabbed: bool)

@export var peer_id := 1
@export var crew_slot := 0
@export var player_color := Color("#d97058")
var pushing := false
var local_input := Vector2.ZERO
var brake_strength := 0.0
var target_gurney: RigidBody3D
var body_mesh: MeshInstance3D
var visual_root: Node3D
var arms: Array[MeshInstance3D] = []
var legs: Array[MeshInstance3D] = []
var gait_time := 0.0
var nameplate: Label3D
var network_target := Transform3D.IDENTITY
var has_network_target := false

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	return material

func _sphere(parent: Node3D, name_: String, scale_: Vector3, position_: Vector3, material: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = name_
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 18
	mesh.rings = 10
	part.mesh = mesh
	part.scale = scale_
	part.position = position_
	part.material_override = material
	parent.add_child(part)
	return part

func setup(id: int, slot: int, color: Color) -> void:
	peer_id = id
	crew_slot = slot
	name = "Player_%d" % id
	player_color = color
	set_multiplayer_authority(id)
	_build_body()

func _build_body() -> void:
	collision_layer = 4
	collision_mask = 1
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.5
	var collision := CollisionShape3D.new()
	collision.shape = shape
	add_child(collision)
	visual_root = Node3D.new()
	visual_root.name = "Character"
	add_child(visual_root)
	var model: Dictionary = preload("res://scripts/entities/mascot_model.gd").build(visual_root, player_color)
	body_mesh = model.body
	arms.assign(model.arms)
	legs.assign(model.legs)
	nameplate = Label3D.new()
	nameplate.position = Vector3(0, 1.75, 0)
	nameplate.font_size = 48
	nameplate.pixel_size = 0.009
	nameplate.modulate = Color("#fff4de")
	nameplate.outline_modulate = Color("#31596c")
	nameplate.outline_size = 10
	nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	visual_root.add_child(nameplate)
	set_display_name("Orderly %d" % peer_id)

func set_display_name(display_name: String) -> void:
	if nameplate: nameplate.text = display_name

func apply_synced_pose(is_pushing: bool) -> void:
	pushing = is_pushing
	_apply_pose(0.0)

func apply_network_transform(next_transform: Transform3D) -> void:
	if !has_network_target:
		global_transform = next_transform
		has_network_target = true
	network_target = next_transform

func _apply_pose(delta: float) -> void:
	var input_motion := local_input.length() > 0.08
	var body_speed := Vector2(velocity.x, velocity.z).length()
	var moving := input_motion or (!pushing and body_speed > 0.25)
	if moving: gait_time += delta * (10.0 if pushing else 7.0)
	var stride_target := sin(gait_time) * (0.42 if pushing else minf(0.32, body_speed * 0.06)) if moving else 0.0
	for index in legs.size():
		var target := stride_target * (-1.0 if index == 0 else 1.0)
		legs[index].rotation.x = lerpf(legs[index].rotation.x, target, minf(1.0, delta * 12.0))
	for index in arms.size():
		arms[index].rotation.x = -1.05 if pushing else -stride_target * (-1.0 if index == 0 else 1.0)
		arms[index].position.z = -0.22 if pushing else 0.0
	visual_root.rotation.x = -0.16 if pushing else 0.0
	visual_root.position.y = absf(sin(gait_time * 2.0)) * 0.045 if moving else lerpf(visual_root.position.y, 0.0, minf(1.0, delta * 8.0))
	body_mesh.scale.y = 1.0 - (absf(sin(gait_time * 2.0)) * 0.035 if moving else 0.0)

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority():
		if has_network_target:
			var weight := 1.0 - exp(-18.0 * delta)
			if global_position.distance_to(network_target.origin) > 0.015:
				global_position = global_position.lerp(network_target.origin, weight)
			var current_rotation := global_basis.get_rotation_quaternion()
			var target_rotation := network_target.basis.get_rotation_quaternion()
			global_basis = Basis(current_rotation.slerp(target_rotation, weight))
		_apply_pose(delta)
		return
	local_input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	brake_strength = Input.get_action_strength("brake")
	var main := get_parent()
	var run_active: bool = main.game_state == main.GameState.RUNNING
	if Input.is_action_just_pressed("interact") and run_active:
		var was_pushing := pushing
		pushing = !pushing if target_gurney and global_position.distance_to(target_gurney.global_position) < 3.2 else false
		if pushing != was_pushing: grab_changed.emit(pushing)
	var direction := Vector3(local_input.x, 0.0, local_input.y)
	var camera := get_viewport().get_camera_3d()
	if camera:
		var camera_right := camera.global_basis.x
		var camera_forward := -camera.global_basis.z
		camera_right.y = 0.0
		camera_forward.y = 0.0
		direction = camera_right.normalized() * local_input.x + camera_forward.normalized() * -local_input.y
		if direction.length_squared() > 1.0: direction = direction.normalized()
	if pushing and target_gurney:
		var side := -0.82 if crew_slot % 2 == 0 else 0.82
		var row := float(crew_slot / 2)
		var attachment: Vector3 = target_gurney.global_transform * Vector3(side, -0.42, 2.0 + row * 0.55)
		if global_position.distance_to(attachment) > 0.01:
			global_position = global_position.lerp(attachment, minf(1.0, delta * 16.0))
		rotation.y = lerp_angle(rotation.y, target_gurney.rotation.y, minf(1.0, delta * 12.0))
		velocity = Vector3.ZERO
	elif direction.length_squared() > 0.02:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(1.0, delta * 10.0))
	if !pushing:
		velocity.x = move_toward(velocity.x, direction.x * 5.5, 18.0 * delta)
		velocity.z = move_toward(velocity.z, direction.z * 5.5, 18.0 * delta)
		velocity.y -= 20.0 * delta
		move_and_slide()
	_apply_pose(delta)
	_submit_input.rpc_id(1, local_input, brake_strength, pushing, global_transform)

@rpc("any_peer", "call_local", "unreliable", 1)
func _submit_input(input_vector: Vector2, braking: float, is_pushing: bool, submitted_transform: Transform3D) -> void:
	var main := get_parent()
	if !multiplayer.is_server() or !target_gurney: return
	var sender := multiplayer.get_remote_sender_id() if multiplayer.get_remote_sender_id() else peer_id
	var submitted_position := submitted_transform.origin if sender != 1 else global_position
	target_gurney.set_player_input(sender, input_vector, braking, is_pushing, submitted_position)
	if main.players.has(sender) and sender != 1:
		main.players[sender].apply_network_transform(submitted_transform)
		main.players[sender].apply_synced_pose(is_pushing)
