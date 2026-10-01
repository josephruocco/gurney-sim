class_name GurneyPlayer
extends CharacterBody3D

@export var peer_id := 1
@export var player_color := Color("#d97058")
var pushing := false
var local_input := Vector2.ZERO
var brake_strength := 0.0
var target_gurney: RigidBody3D
var body_mesh: MeshInstance3D

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
	body_mesh = MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.38
	capsule.height = 1.5
	body_mesh.mesh = capsule
	var material := StandardMaterial3D.new()
	material.albedo_color = player_color
	body_mesh.material_override = material
	add_child(body_mesh)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.34
	head_mesh.height = 0.68
	head.mesh = head_mesh
	head.position.y = 0.9
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color("#f0c7a5")
	head.material_override = skin
	add_child(head)

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	local_input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	brake_strength = Input.get_action_strength("brake")
	var direction := Vector3(local_input.x, 0.0, local_input.y)
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
