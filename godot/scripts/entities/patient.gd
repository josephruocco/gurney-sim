class_name SlidingPatient
extends RigidBody3D

func _ready() -> void:
	mass = 4.5
	linear_damp = 0.15
	angular_damp = 0.8
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
	var skin := _material(Color("#f0c7a5"))
	var gown := _material(Color("#91c8d3"))
	var ink := _material(Color("#253547"))
	var hair := _material(Color("#554337"))
	# The model is authored upright, then the complete rigid body lies along the bed.
	var visual := Node3D.new()
	visual.name = "Mascot"
	visual.rotation_degrees.x = 90
	add_child(visual)
	# Build into a temporary upright coordinate system and reparent under visual.
	var parts: Array[Node] = []
	parts.append(_sphere("Head", Vector3(1.0, 1.08, 0.78), Vector3(0, 0.62, 0), skin))
	parts.append(_sphere("Gown", Vector3(1.08, 0.86, 0.82), Vector3(0, -0.23, 0), gown))
	for side in [-1.0, 1.0]:
		parts.append(_sphere("Sleeve", Vector3(0.38, 0.46, 0.38), Vector3(side * 0.55, -0.05, 0), gown))
		parts.append(_sphere("Arm", Vector3(0.24, 0.48, 0.24), Vector3(side * 0.62, -0.34, 0), skin))
		parts.append(_sphere("Leg", Vector3(0.25, 0.52, 0.28), Vector3(side * 0.24, -0.76, 0.03), skin))
		parts.append(_sphere("Eye", Vector3(0.13, 0.025, 0.03), Vector3(side * 0.2, 0.72, -0.4), ink))
	parts.append(_sphere("Nose", Vector3(0.26, 0.22, 0.22), Vector3(0, 0.57, -0.43), skin))
	for x in [-0.27, -0.08, 0.12, 0.29]:
		var strand := MeshInstance3D.new()
		strand.name = "Hair"
		var strand_mesh := CylinderMesh.new()
		strand_mesh.top_radius = 0.012
		strand_mesh.bottom_radius = 0.012
		strand_mesh.height = 0.16
		strand.mesh = strand_mesh
		strand.position = Vector3(x, 1.16 - absf(x) * 0.35, 0)
		strand.rotation_degrees.z = x * 45.0
		strand.material_override = hair
		add_child(strand)
		parts.append(strand)
	for part in parts:
		part.reparent(visual, false)
