class_name SlidingPatient
extends RigidBody3D

func _ready() -> void:
	collision_layer = 8
	collision_mask = 3
	mass = 4.5
	linear_damp = 1.1
	angular_damp = 2.2
	continuous_cd = true
	var grip := PhysicsMaterial.new()
	grip.friction = 0.72
	grip.rough = true
	grip.bounce = 0.02
	physics_material_override = grip
	_build_model()

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	return material

func _sphere(name_: String, scale_: Vector3, position_: Vector3, material: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = name_
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 20
	mesh.rings = 12
	part.mesh = mesh
	part.scale = scale_
	part.position = position_
	part.material_override = material
	add_child(part)
	return part

func _build_model() -> void:
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.48
	shape.height = 1.65
	collision.shape = shape
	collision.rotation_degrees.x = 90
	add_child(collision)
	var visual := Node3D.new()
	visual.name = "Mascot"
	visual.rotation_degrees.x = 90
	visual.position.z = -0.2
	add_child(visual)
	preload("res://scripts/entities/mascot_model.gd").build(visual, Color("#91c8d3"), true)
