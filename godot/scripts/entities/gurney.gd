class_name SharedGurney
extends RigidBody3D

signal balance_changed(tilt: float, danger: float)

const PUSH_FORCE := 120.0
const STEER_TORQUE := 65.0
const BRAKE_DRAG := 8.0
var player_inputs: Dictionary = {}
var patient: RigidBody3D
var last_state_tick := 0
var wheels: Array[MeshInstance3D] = []
var front_forks: Array[Node3D] = []
var visual_steering := 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 9
	mass = 18.0
	linear_damp = 0.45
	angular_damp = 2.4
	var rolling_material := PhysicsMaterial.new()
	rolling_material.friction = 0.12
	rolling_material.rough = false
	rolling_material.bounce = 0.04
	physics_material_override = rolling_material
	_build_model()

func _build_model() -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.7, 0.25, 3.4)
	collision.shape = shape
	add_child(collision)
	var bed := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = shape.size
	bed.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#dce5e8")
	bed.material_override = material
	add_child(bed)
	var frame_material := StandardMaterial3D.new()
	frame_material.albedo_color = Color("#8fa2ac")
	frame_material.metallic = 0.35
	frame_material.roughness = 0.4
	for x in [-0.82, 0.82]:
		var rail := MeshInstance3D.new()
		var rail_mesh := BoxMesh.new()
		rail_mesh.size = Vector3(0.08, 0.42, 3.25)
		rail.mesh = rail_mesh
		rail.position = Vector3(x, 0.28, 0)
		rail.material_override = frame_material
		add_child(rail)
		var rail_collision := CollisionShape3D.new()
		var rail_shape := BoxShape3D.new()
		rail_shape.size = Vector3(0.12, 0.44, 3.25)
		rail_collision.shape = rail_shape
		rail_collision.position = Vector3(x, 0.28, 0)
		add_child(rail_collision)
	var headboard := MeshInstance3D.new()
	var headboard_mesh := BoxMesh.new()
	headboard_mesh.size = Vector3(1.72, 0.72, 0.1)
	headboard.mesh = headboard_mesh
	headboard.position = Vector3(0, 0.34, 1.62)
	headboard.material_override = frame_material
	add_child(headboard)
	for z in [-1.62, 1.62]:
		var end_collision := CollisionShape3D.new()
		var end_shape := BoxShape3D.new()
		end_shape.size = Vector3(1.72, 0.5, 0.12)
		end_collision.shape = end_shape
		end_collision.position = Vector3(0, 0.25, z)
		add_child(end_collision)
	# A visible lower carriage separates the bed from the floor and reads as a real gurney.
	for size_and_position in [
		[Vector3(1.35, 0.09, 0.09), Vector3(0, -0.82, -1.16)],
		[Vector3(1.35, 0.09, 0.09), Vector3(0, -0.82, 1.16)],
		[Vector3(0.09, 0.09, 2.35), Vector3(-0.63, -0.82, 0)],
		[Vector3(0.09, 0.09, 2.35), Vector3(0.63, -0.82, 0)]
	]:
		var support := MeshInstance3D.new()
		var support_mesh := BoxMesh.new()
		support_mesh.size = size_and_position[0]
		support.mesh = support_mesh
		support.position = size_and_position[1]
		support.material_override = frame_material
		add_child(support)
	for x in [-0.68, 0.68]:
		for z in [-1.35, 1.35]:
			var wheel_collision := CollisionShape3D.new()
			var wheel_shape := SphereShape3D.new()
			wheel_shape.radius = 0.22
			wheel_collision.shape = wheel_shape
			wheel_collision.position = Vector3(x, -1.0, z)
			add_child(wheel_collision)
			var caster := Node3D.new()
			caster.position = Vector3(x, 0, z)
			add_child(caster)
			if z < 0: front_forks.append(caster)
			var leg := MeshInstance3D.new()
			var leg_mesh := CylinderMesh.new()
			leg_mesh.top_radius = 0.075
			leg_mesh.bottom_radius = 0.075
			leg_mesh.height = 0.9
			leg.mesh = leg_mesh
			leg.position = Vector3(0, -0.48, 0)
			leg.material_override = frame_material
			caster.add_child(leg)
			var fork := MeshInstance3D.new()
			var fork_mesh := BoxMesh.new()
			fork_mesh.size = Vector3(0.08, 0.34, 0.28)
			fork.mesh = fork_mesh
			fork.position = Vector3(0, -0.94, 0)
			fork.material_override = frame_material
			caster.add_child(fork)
			var wheel := MeshInstance3D.new()
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.22
			wheel_mesh.bottom_radius = 0.22
			wheel_mesh.height = 0.17
			wheel.mesh = wheel_mesh
			wheel.rotation_degrees.z = 90
			wheel.position = Vector3(0, -1.0, 0)
			caster.add_child(wheel)
			wheels.append(wheel)

func _process(delta: float) -> void:
	var local_velocity := global_basis.inverse() * linear_velocity
	var wheel_spin := -local_velocity.z / 0.22 * delta
	for wheel in wheels: wheel.rotate_x(wheel_spin)
	for caster in front_forks:
		caster.rotation.y = lerp_angle(caster.rotation.y, visual_steering, minf(1.0, delta * 9.0))

func set_player_input(id: int, input_vector: Vector2, braking: float, pushing: bool, position: Vector3) -> void:
	if pushing and input_vector.length_squared() > 0.001: sleeping = false
	player_inputs[id] = {"move": input_vector, "brake": braking, "push": pushing, "position": position}

func remove_player(id: int) -> void:
	player_inputs.erase(id)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if !multiplayer.is_server(): return
	var push := 0.0
	var steering := 0.0
	var braking := 0.0
	var lateral_weight := 0.0
	var pushers := 0
	for value in player_inputs.values():
		var entry: Dictionary = value
		var move: Vector2 = entry["move"]
		if entry["push"]:
			pushers += 1
			push += -move.y
			steering += move.x
		braking += float(entry["brake"])
		var local_position: Vector3 = global_transform.affine_inverse() * Vector3(entry["position"])
		lateral_weight += clamp(local_position.x, -1.5, 1.5) + move.x * 0.45
	var forward: Vector3 = -global_transform.basis.z
	var right: Vector3 = global_transform.basis.x
	state.apply_central_force(forward * push * PUSH_FORCE)
	var speed_steering := lerpf(0.65, 1.25, clampf(state.linear_velocity.length() / 8.0, 0.0, 1.0))
	state.apply_torque(Vector3.UP * -steering * STEER_TORQUE * speed_steering)
	var lateral_speed := state.linear_velocity.dot(right)
	state.apply_central_force(-right * lateral_speed * 70.0)
	visual_steering = clampf(-steering / maxf(1.0, float(pushers)) * 0.42, -0.5, 0.5)
	state.linear_velocity *= 1.0 / (1.0 + braking * BRAKE_DRAG * state.step)
	if state.linear_velocity.length() > 13.0:
		state.linear_velocity = state.linear_velocity.normalized() * 13.0
	if patient:
		var patient_local: Vector3 = global_transform.affine_inverse() * patient.global_position
		lateral_weight += clamp(patient_local.x * 1.4, -1.5, 1.5)
	state.apply_torque(forward * lateral_weight * 7.0)
	var tilt: float = absf(global_transform.basis.y.dot(Vector3.UP))
	var danger: float = clampf((1.0 - tilt) / 0.45, 0.0, 1.0)
	balance_changed.emit(1.0 - tilt, danger)

func speed_kph() -> float:
	return linear_velocity.length() * 3.6
