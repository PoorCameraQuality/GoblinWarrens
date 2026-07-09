extends SceneTree
## Loads the colony scene, waits for it to settle, saves a screenshot, quits.
## Usage: godot --path <project> --script res://tests/smoke/capture_demo_screenshot.gd

const OUT_PATH := "res://.logs/demo_screenshot.png"


func _initialize() -> void:
	print("[screenshot] starting")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.logs"))
	var scene: PackedScene = load("res://scenes/colony.tscn")
	if scene == null:
		push_error("[screenshot] failed to load colony scene")
		quit(1)
		return
	var instance: Node = scene.instantiate()
	root.add_child(instance)
	await create_timer(2.5).timeout
	var viewport := root.get_viewport()
	var img := viewport.get_texture().get_image()
	if img == null:
		push_error("[screenshot] no viewport image (headless renderer likely dummy)")
		quit(2)
		return
	var err := img.save_png(ProjectSettings.globalize_path(OUT_PATH))
	if err != OK:
		push_error("[screenshot] save_png failed: %s" % err)
		quit(3)
		return
	print("[screenshot] saved %s (%dx%d)" % [OUT_PATH, img.get_width(), img.get_height()])
	quit(0)
