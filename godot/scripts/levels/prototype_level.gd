class_name PrototypeLevel
extends Node3D

func _ready() -> void:
	_build_environment()

func _surface(name_: String, size: Vector3, position_: Vector3, rotation_: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name_
	body.position = position_
	body.rotation = rotation_
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	visual.material_override = material
	body.add_child(visual)
	add_child(body)
	return body

func _build_environment() -> void:
	_surface("Start", Vector3(18, 0.5, 18), Vector3(0, -0.25, 3), Vector3.ZERO, Color("#566b74"))
	_surface("Ramp", Vector3(7, 0.5, 13), Vector3(0, 1.1, -10), Vector3(deg_to_rad(-11), 0, 0), Color("#d5aa66"))
	_surface("Upper", Vector3(14, 0.5, 8), Vector3(0, 2.25, -20), Vector3.ZERO, Color("#566b74"))
	_surface("BalanceBeam", Vector3(2.25, 0.5, 14), Vector3(0, 2.25, -31), Vector3.ZERO, Color("#d97058"))
	_surface("Finish", Vector3(14, 0.5, 10), Vector3(0, 2.25, -43), Vector3.ZERO, Color("#6f9a82"))
	for i in 12:
		var side := -1.0 if i % 2 == 0 else 1.0
		var height := 5.0 + float((i * 7) % 9)
		_surface("City_%02d" % i, Vector3(5.0, height, 5.0), Vector3(side * (15.0 + float(i % 3) * 4.0), height * 0.5 - 1.0, -8.0 - i * 5.0), Vector3.ZERO, Color("#425963"))
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -25, 0)
	light.light_energy = 0.32
	light.light_color = Color("#fff1d8")
	light.shadow_enabled = true
	add_child(light)
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#b7d0dc")
	environment.background_energy_multiplier = 0.55
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#fff4de")
	environment.ambient_light_energy = 0.22
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	world_environment.environment = environment
	add_child(world_environment)
