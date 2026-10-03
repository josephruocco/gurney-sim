extends RefCounted

static func material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.92
	return result

static func part(parent: Node3D, title: String, mesh: Mesh, position: Vector3, mat: Material) -> MeshInstance3D:
	var result := MeshInstance3D.new()
	result.name = title
	result.mesh = mesh
	result.position = position
	result.material_override = mat
	parent.add_child(result)
	return result

static func oval(parent: Node3D, title: String, position: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 32
	mesh.rings = 20
	var result := part(parent, title, mesh, position, mat)
	result.scale = size
	return result

static func cylinder(parent: Node3D, title: String, position: Vector3, top: float, bottom: float, height: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 32
	return part(parent, title, mesh, position, mat)

# Original assets/mascot.js proportions, facing Godot's -Z with feet at y=-0.75.
static func build(root: Node3D, color: Color, patient := false) -> Dictionary:
	var skin := material(Color("#f0c7a5"))
	var cloth := material(color)
	var ink := material(Color("#253547"))
	var hair := material(Color("#554337"))
	var arms: Array[MeshInstance3D] = []
	var legs: Array[MeshInstance3D] = []
	oval(root, "Head", Vector3(0, 0.62, 0), Vector3(1.0, 1.10, 0.76), skin)
	var body := cylinder(root, "Gown", Vector3(0, 0.03, 0), 0.49, 0.55, 0.69, cloth)
	body.scale.z = 0.82
	oval(root, "Hem", Vector3(0, -0.29, 0), Vector3(1.1, 0.21, 0.902), cloth)
	for side in [-1.0, 1.0]:
		oval(root, "Shoulder", Vector3(side * 0.48, 0.31, 0), Vector3(0.38, 0.28, 0.38), cloth)
		var sleeve := cylinder(root, "Sleeve", Vector3(side * 0.535, 0.195, 0), 0.19, 0.158, 0.29, cloth)
		sleeve.rotation.z = side * 0.3
		var arm_mesh := CapsuleMesh.new()
		arm_mesh.radius = 0.13
		arm_mesh.height = 0.48
		var arm := part(root, "Arm", arm_mesh, Vector3(side * 0.60, 0.01, -0.015), skin)
		arm.rotation.z = side * 0.22
		arms.append(arm)
		var leg := cylinder(root, "Leg", Vector3(side * 0.22, -0.45, -0.015), 0.12, 0.12, 0.37, skin)
		oval(leg, "Foot", Vector3(0, -0.185, -0.05), Vector3(0.25, 0.21, 0.34), skin)
		legs.append(leg)
		oval(root, "Eye", Vector3(side * 0.19, 0.84, -0.342), Vector3(0.144, 0.018, 0.028), ink)
	oval(root, "Nose", Vector3(0, 0.69, -0.36), Vector3(0.27, 0.27, 0.27), skin)
	for x in [-0.24, -0.065, 0.13, 0.285]:
		var y := 0.62 + 0.55 * sqrt(1.0 - pow(x / 0.5, 2))
		var strand := cylinder(root, "Hair", Vector3(x, y + 0.05, 0.02), 0.006, 0.008, 0.11, hair)
		strand.rotation.z = -x * 0.8
	if patient:
		for x in [-0.19, 0.0, 0.19]:
			for y in [-0.09, 0.13]:
				var mesh := BoxMesh.new()
				mesh.size = Vector3(0.062, 0.012, 0.014)
				part(root, "GownDash", mesh, Vector3(x, y, -sqrt(0.52 * 0.52 - x * x) * 0.82 - 0.008), ink)
	return {"body": body, "arms": arms, "legs": legs}
