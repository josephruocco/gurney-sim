class_name GurneyPlayer
extends CharacterBody3D

@export var peer_id := 1
@export var player_color := Color("#d97058")
var pushing := false
var local_input := Vector2.ZERO
var brake_strength := 0.0
var target_gurney: RigidBody3D
var body_mesh: MeshInstance3D

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
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.5
	var collision := CollisionShape3D.new()
	collision.shape = shape
	add_child(collision)
	var visual := Node3D.new()
	visual.name = "Character"
	add_child(visual)
	var shirt := _material(player_color)
	var skin := _material(Color("#f0c7a5"))
	var ink := _material(Color("#253547"))
	var hair := _material(Color("#554337"))
	body_mesh = _sphere(visual, "Shirt", Vector3(0.92, 0.9, 0.76), Vector3(0, 0.0, 0), shirt)
	_sphere(visual, "Head", Vector3(0.84, 0.9, 0.72), Vector3(0, 0.78, 0), skin)
	for side in [-1.0, 1.0]:
		_sphere(visual, "Sleeve", Vector3(0.3, 0.38, 0.3), Vector3(side * 0.5, 0.12, 0), shirt)
		_sphere(visual, "Arm", Vector3(0.2, 0.42, 0.2), Vector3(side * 0.56, -0.17, 0), skin)
		_sphere(visual, "Leg", Vector3(0.22, 0.48, 0.25), Vector3(side * 0.22, -0.73, 0), skin)
		_sphere(visual, "Eye", Vector3(0.11, 0.022, 0.026), Vector3(side * 0.17, 0.88, -0.37), ink)
	_sphere(visual, "Nose", Vector3(0.22, 0.19, 0.19), Vector3(0, 0.73, -0.39), skin)
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
		visual.add_child(strand)

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	local_input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	brake_strength = Input.get_action_strength("brake")
	var direction := Vector3(local_input.x, 0.0, local_input.y)
	if direction.length_squared() > 0.02:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(1.0, delta * 10.0))
	velocity.x = move_toward(velocity.x, direction.x * 5.5, 18.0 * delta)
	velocity.z = move_toward(velocity.z, direction.z * 5.5, 18.0 * delta)
	velocity.y -= 20.0 * delta
	move_and_slide()
	if Input.is_action_just_pressed("interact"):
		pushing = !pushing if target_gurney and global_position.distance_to(target_gurney.global_position) < 3.0 else false
	_submit_input.rpc_id(1, local_input, brake_strength, pushing)

@rpc("any_peer", "call_local", "unreliable", 1)
func _submit_input(input_vector: Vector2, braking: float, is_pushing: bool) -> void:
	if !multiplayer.is_server() or !target_gurney: return
	var sender := multiplayer.get_remote_sender_id() if multiplayer.get_remote_sender_id() else peer_id
	target_gurney.set_player_input(sender, input_vector, braking, is_pushing, global_position)
	var main := get_parent()
	if main.players.has(sender) and sender != 1:
		main.players[sender].global_position = global_position
