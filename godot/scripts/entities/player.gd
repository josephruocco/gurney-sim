class_name GurneyPlayer
extends CharacterBody3D

signal grab_changed(grabbed: bool)

@export var peer_id := 1
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

func setup(id: int, color: Color) -> void:
	peer_id = id
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
	var shirt := _material(player_color)
	var skin := _material(Color("#f0c7a5"))
	var ink := _material(Color("#253547"))
	var hair := _material(Color("#554337"))
	body_mesh = _sphere(visual_root, "Shirt", Vector3(0.92, 0.9, 0.76), Vector3(0, 0.0, 0), shirt)
	_sphere(visual_root, "Head", Vector3(0.84, 0.9, 0.72), Vector3(0, 0.78, 0), skin)
	for side in [-1.0, 1.0]:
		_sphere(visual_root, "Sleeve", Vector3(0.3, 0.38, 0.3), Vector3(side * 0.5, 0.12, 0), shirt)
		arms.append(_sphere(visual_root, "Arm", Vector3(0.2, 0.42, 0.2), Vector3(side * 0.56, -0.17, 0), skin))
		legs.append(_sphere(visual_root, "Leg", Vector3(0.22, 0.48, 0.25), Vector3(side * 0.22, -0.73, 0), skin))
		_sphere(visual_root, "Eye", Vector3(0.11, 0.022, 0.026), Vector3(side * 0.17, 0.88, -0.37), ink)
	_sphere(visual_root, "Nose", Vector3(0.22, 0.19, 0.19), Vector3(0, 0.73, -0.39), skin)
	for x in [-0.22, -0.06, 0.11, 0.24]:
		var strand := MeshInstance3D.new()
		strand.name = "Hair"
		var strand_mesh := CylinderMesh.new()
		strand_mesh.top_radius = 0.01
		strand_mesh.bottom_radius = 0.01
		strand_mesh.height = 0.13
		strand.mesh = strand_mesh
		strand.position = Vector3(x, 1.28 - absf(x) * 0.35, 0)
		strand.rotation_degrees.z = x * 45.0
		strand.material_override = hair
		visual_root.add_child(strand)
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

func _apply_pose(delta: float) -> void:
	gait_time += delta * (10.0 if pushing else 7.0)
	var stride := sin(gait_time) * (0.42 if pushing else minf(0.32, Vector2(velocity.x, velocity.z).length() * 0.06))
	for index in legs.size():
		legs[index].rotation.x = stride * (-1.0 if index == 0 else 1.0)
	for index in arms.size():
		arms[index].rotation.x = -1.05 if pushing else -stride * (-1.0 if index == 0 else 1.0)
		arms[index].position.z = -0.22 if pushing else 0.0
	visual_root.rotation.x = -0.16 if pushing else 0.0

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	local_input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	brake_strength = Input.get_action_strength("brake")
	if Input.is_action_just_pressed("interact"):
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
		var side := -0.82 if peer_id % 2 == 1 else 0.82
		var row := float((peer_id - 1) / 2)
		var attachment: Vector3 = target_gurney.global_transform * Vector3(side, 0.58, 2.0 + row * 0.55)
		global_position = global_position.lerp(attachment, minf(1.0, delta * 12.0))
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
	_submit_input.rpc_id(1, local_input, brake_strength, pushing)

@rpc("any_peer", "call_local", "unreliable", 1)
func _submit_input(input_vector: Vector2, braking: float, is_pushing: bool) -> void:
	if !multiplayer.is_server() or !target_gurney: return
	var sender := multiplayer.get_remote_sender_id() if multiplayer.get_remote_sender_id() else peer_id
	target_gurney.set_player_input(sender, input_vector, braking, is_pushing, global_position)
	var main := get_parent()
	if main.players.has(sender) and sender != 1:
		main.players[sender].global_position = global_position
		main.players[sender].apply_synced_pose(is_pushing)
