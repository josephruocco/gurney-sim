class_name SharedGurney
extends RigidBody3D

signal balance_changed(tilt: float, danger: float)

const PUSH_FORCE := 120.0
const STEER_TORQUE := 18.0
const BRAKE_DRAG := 8.0
var player_inputs: Dictionary = {}
var patient: RigidBody3D
var last_state_tick := 0

func _ready() -> void:
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
	var headboard := MeshInstance3D.new()
	var headboard_mesh := BoxMesh.new()
	headboard_mesh.size = Vector3(1.72, 0.72, 0.1)
	headboard.mesh = headboard_mesh
	headboard.position = Vector3(0, 0.34, 1.62)
	headboard.material_override = frame_material
	add_child(headboard)
	for x in [-0.68, 0.68]:
		for z in [-1.35, 1.35]:
			var leg := MeshInstance3D.new()
			var leg_mesh := CylinderMesh.new()
			leg_mesh.top_radius = 0.045
			leg_mesh.bottom_radius = 0.045
			leg_mesh.height = 0.55
			leg.mesh = leg_mesh
			leg.position = Vector3(x, -0.28, z)
			leg.material_override = frame_material
			add_child(leg)
			var wheel := MeshInstance3D.new()
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.17
			wheel_mesh.bottom_radius = 0.17
			wheel_mesh.height = 0.14
			wheel.mesh = wheel_mesh
			wheel.rotation_degrees.z = 90
			wheel.position = Vector3(x, -0.6, z)
			add_child(wheel)

func set_player_input(id: int, input_vector: Vector2, braking: float, pushing: bool, position: Vector3) -> void:
	player_inputs[id] = {"move": input_vector, "brake": braking, "push": pushing, "position": position}

func remove_player(id: int) -> void:
	player_inputs.erase(id)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if !multiplayer.is_server(): return
	var push := 0.0
	var steering := 0.0
	var braking := 0.0
	var lateral_weight := 0.0
	for value in player_inputs.values():
		var entry: Dictionary = value
		var move: Vector2 = entry["move"]
		if entry["push"]:
			push += -move.y
			steering += move.x
		braking += float(entry["brake"])
		var local_position: Vector3 = global_transform.affine_inverse() * Vector3(entry["position"])
		lateral_weight += clamp(local_position.x, -1.5, 1.5) + move.x * 0.45
	var forward: Vector3 = -global_transform.basis.z
	state.apply_central_force(forward * push * PUSH_FORCE)
	state.apply_torque(Vector3.UP * -steering * STEER_TORQUE)
	state.linear_velocity *= 1.0 / (1.0 + braking * BRAKE_DRAG * state.step)
	if patient:
		var patient_local: Vector3 = global_transform.affine_inverse() * patient.global_position
		lateral_weight += clamp(patient_local.x * 1.4, -1.5, 1.5)
	state.apply_torque(forward * lateral_weight * 7.0)
	var tilt: float = absf(global_transform.basis.y.dot(Vector3.UP))
	var danger: float = clampf((1.0 - tilt) / 0.45, 0.0, 1.0)
	balance_changed.emit(1.0 - tilt, danger)

func speed_kph() -> float:
	return linear_velocity.length() * 3.6
