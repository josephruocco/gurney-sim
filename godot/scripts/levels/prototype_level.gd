class_name PrototypeLevel
extends Node3D

const TrafficCarScript = preload("res://scripts/levels/traffic_car.gd")

func _ready() -> void:
	_build_environment()

func gurney_spawn() -> Vector3: return Vector3(0, 8.85, 10)
func patient_spawn() -> Vector3: return Vector3(0, 9.6, 10)
func player_spawn(id: int) -> Vector3: return Vector3((id - 1) * 1.2 - 1.2, 9.0, 14)

func _material(color: Color, metallic := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = 0.82 if metallic == 0.0 else 0.45
	return material

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
	visual.material_override = _material(color)
	body.add_child(visual)
	add_child(body)
	return body

func _rail(position_: Vector3, size: Vector3) -> void:
	_surface("Guardrail", size, position_, Vector3.ZERO, Color("#91a4ad"))

func _decorative_box(name_: String, size: Vector3, position_: Vector3, color: Color, emission := Color.BLACK) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.name = name_
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.position = position_
	var material := _material(color)
	if emission != Color.BLACK:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = 2.2
	visual.material_override = material
	add_child(visual)
	return visual

func _light_strip(position_: Vector3) -> void:
	_decorative_box("CeilingLight", Vector3(3.8, 0.08, 0.35), position_, Color("#fff4de"), Color("#ffdba0"))
	var light := OmniLight3D.new()
	light.position = position_ - Vector3(0, 0.18, 0)
	light.light_color = Color("#ffe5b7")
	light.light_energy = 1.3
	light.omni_range = 8.0
	add_child(light)

func _exit_sign(position_: Vector3) -> void:
	var sign := Label3D.new()
	sign.name = "ExitSign"
	sign.text = "EXIT  ↓"
	sign.font_size = 72
	sign.modulate = Color("#fff4de")
	sign.outline_modulate = Color("#31596c")
	sign.outline_size = 10
	sign.position = position_
	sign.rotation_degrees.y = 180
	sign.pixel_size = 0.012
	add_child(sign)

func _parked_car(position_: Vector3, color: Color, yaw := 0.0) -> void:
	var car := StaticBody3D.new()
	car.name = "ParkedCar"
	car.position = position_
	car.rotation.y = yaw
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.9, 1.15, 3.8)
	collision.shape = shape
	collision.position.y = 0.58
	car.add_child(collision)
	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(1.9, 0.75, 3.8)
	body.mesh = body_mesh
	body.position.y = 0.52
	body.material_override = _material(color, 0.22)
	car.add_child(body)
	var cab := MeshInstance3D.new()
	var cab_mesh := BoxMesh.new()
	cab_mesh.size = Vector3(1.65, 0.65, 1.9)
	cab.mesh = cab_mesh
	cab.position = Vector3(0, 1.2, -0.1)
	cab.material_override = _material(color.lightened(0.08), 0.22)
	car.add_child(cab)
	for x in [-0.95, 0.95]:
		for z in [-1.25, 1.25]:
			var wheel := MeshInstance3D.new()
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.28
			wheel_mesh.bottom_radius = 0.28
			wheel_mesh.height = 0.16
			wheel.mesh = wheel_mesh
			wheel.rotation_degrees.z = 90
			wheel.position = Vector3(x, 0.3, z)
			wheel.material_override = _material(Color("#182126"))
			car.add_child(wheel)
	add_child(car)

func _cone(position_: Vector3) -> void:
	var cone := StaticBody3D.new()
	cone.name = "TrafficCone"
	cone.position = position_
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.25
	shape.height = 0.75
	collision.shape = shape
	collision.position.y = 0.38
	cone.add_child(collision)
	var visual := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.05
	mesh.bottom_radius = 0.3
	mesh.height = 0.75
	visual.mesh = mesh
	visual.position.y = 0.38
	visual.material_override = _material(Color("#e97846"))
	cone.add_child(visual)
	add_child(cone)

func _column(position_: Vector3, height: float) -> void:
	_surface("Column", Vector3(1.3, height, 1.3), position_ + Vector3(0, height * 0.5, 0), Vector3.ZERO, Color("#52656e"))

func _build_environment() -> void:
	_surface("RoofDeck", Vector3(24, 0.55, 26), Vector3(0, 8.0, 8), Vector3.ZERO, Color("#5c7079"))
	_surface("RampOne", Vector3(7, 0.55, 19), Vector3(0, 6.0, -11), Vector3(deg_to_rad(-13), 0, 0), Color("#687d86"))
	_surface("MiddleDeck", Vector3(25, 0.55, 15), Vector3(-1, 3.9, -27), Vector3.ZERO, Color("#5c7079"))
	_surface("MiddleCeiling", Vector3(25, 0.35, 15), Vector3(-1, 7.55, -27), Vector3.ZERO, Color("#485b64"))
	_surface("RampTwo", Vector3(18, 0.55, 7), Vector3(-14, 1.9, -27), Vector3(0, 0, deg_to_rad(13)), Color("#687d86"))
	_surface("StreetDeck", Vector3(21, 0.55, 24), Vector3(-29, -0.15, -31), Vector3.ZERO, Color("#4d626b"))
	_surface("BalanceLedge", Vector3(2.4, 0.42, 16), Vector3(-5.5, 3.95, -36), Vector3.ZERO, Color("#d97058"))
	# Parking paint and a coral route line keep the path legible at gameplay speed.
	for x in [-8.0, -4.0, 4.0, 8.0]:
		_decorative_box("ParkingLine", Vector3(0.09, 0.025, 5.4), Vector3(x, 8.3, 9), Color("#dfe8e9"))
	for z in [-24.0, -28.0, -32.0]:
		_decorative_box("ParkingLine", Vector3(4.8, 0.025, 0.09), Vector3(5.2, 4.2, z), Color("#dfe8e9"))
	for z in [4.5, 1.5, -1.5]:
		_decorative_box("RouteDash", Vector3(0.32, 0.035, 1.8), Vector3(0, 8.31, z), Color("#e18368"), Color("#8f3d31"))
	for x in [-7.0, -1.0, 5.0]:
		_decorative_box("RouteDash", Vector3(1.8, 0.035, 0.32), Vector3(x, 4.22, -27), Color("#e18368"), Color("#8f3d31"))
	_rail(Vector3(-11.7, 8.75, 8), Vector3(0.25, 1.25, 25.5))
	_rail(Vector3(11.7, 8.75, 8), Vector3(0.25, 1.25, 25.5))
	_rail(Vector3(-6.5, 8.75, -4.8), Vector3(10.5, 1.25, 0.25))
	_rail(Vector3(6.5, 8.75, -4.8), Vector3(10.5, 1.25, 0.25))
	_rail(Vector3(5.8, 4.65, -34.2), Vector3(12.0, 1.1, 0.22))
	_rail(Vector3(-9.8, 4.65, -34.2), Vector3(6.5, 1.1, 0.22))
	for position_ in [Vector3(-9, 8.25, 0), Vector3(9, 8.25, 0), Vector3(-9, 8.25, 16), Vector3(9, 8.25, 16), Vector3(-11, 4.15, -27), Vector3(9, 4.15, -27)]:
		_column(position_, 4.4)
	for x in [-7.0, -1.0, 5.0]: _light_strip(Vector3(x, 7.32, -27))
	_exit_sign(Vector3(-1, 6.35, -34.1))
	_parked_car(Vector3(-7, 8.28, 5), Color("#d98670"))
	_parked_car(Vector3(7, 8.28, 12), Color("#83b5c9"), PI)
	_parked_car(Vector3(7, 4.18, -25), Color("#e8bf74"), PI * 0.5)
	_parked_car(Vector3(-7, 4.18, -29), Color("#91b49b"), PI * 0.5)
	for position_ in [Vector3(-2.4, 8.3, -1.5), Vector3(2.4, 8.3, -1.5), Vector3(-3.0, 4.2, -23), Vector3(-3.0, 4.2, -31)]:
		_cone(position_)
	var traffic := TrafficCarScript.new()
	traffic.position = Vector3(-7, 4.2, -27)
	traffic.start_x = -7.0
	traffic.end_x = 7.0
	add_child(traffic)
	_surface("FinishZone", Vector3(7, 0.08, 5), Vector3(-29, 0.18, -39), Vector3.ZERO, Color("#8dbb8e"))
	for x in [-32.5, -25.5]: _cone(Vector3(x, 0.2, -36.5))
	for i in 14:
		var side := -1.0 if i % 2 == 0 else 1.0
		var height := 7.0 + float((i * 5) % 11)
		_surface("City_%02d" % i, Vector3(6, height, 6), Vector3(side * (23.0 + float(i % 3) * 5.0), height * 0.5 - 2.0, 6.0 - i * 6.0), Vector3.ZERO, Color("#425963"))
		for floor in range(1, int(height), 2):
			_decorative_box("Window", Vector3(0.08, 0.42, 0.8), Vector3(side * (20.0 + float(i % 3) * 5.0), float(floor), 6.0 - i * 6.0), Color("#f0c978"), Color("#8c6b2e"))
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -25, 0)
	light.light_energy = 0.32
	light.light_color = Color("#fff1d8")
	light.shadow_enabled = true
	add_child(light)
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#87a7b8")
	environment.background_energy_multiplier = 0.55
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#fff4de")
	environment.ambient_light_energy = 0.22
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	world_environment.environment = environment
	add_child(world_environment)
