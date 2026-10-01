class_name GarageTrafficCar
extends AnimatableBody3D

@export var start_x := -7.0
@export var end_x := 7.0
@export var speed := 3.2
var direction := 1.0

func _ready() -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.0, 1.25, 4.0)
	collision.shape = shape
	collision.position.y = 0.62
	add_child(collision)
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.0, 0.82, 4.0)
	body.mesh = mesh
	body.position.y = 0.54
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#b49cc7")
	material.metallic = 0.2
	material.roughness = 0.5
	body.material_override = material
	add_child(body)
	var reverse_lights := OmniLight3D.new()
	reverse_lights.light_color = Color.WHITE
	reverse_lights.light_energy = 1.5
	reverse_lights.omni_range = 4.0
	reverse_lights.position = Vector3(0, 0.65, 2.1)
	add_child(reverse_lights)

func _physics_process(delta: float) -> void:
	position.x += direction * speed * delta
	if position.x >= end_x:
		position.x = end_x
		direction = -1.0
	elif position.x <= start_x:
		position.x = start_x
		direction = 1.0
