extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)
	await process_frame
	main._start_solo()
	for frame in 20:
		await process_frame
	var image := root.get_texture().get_image()
	var error := image.save_png("res://tests/prototype-preview.png")
	assert(error == OK, "Prototype screenshot must save")
	print("Saved prototype preview")
	quit(0)
