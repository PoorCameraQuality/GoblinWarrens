extends SceneTree

## Phase 3 headless smoke: Terrain3D + baked grid + AStarGrid2D path.
## godot --headless --path . --script tests/smoke/test_terrain3d_movement_spike.gd

func _init() -> void:
	if not ClassDB.class_exists("Terrain3D"):
		print("[terrain3d-movement-smoke] FAIL extension_missing")
		quit(1)
		return
	call_deferred("_run")


func _run() -> void:
	var terrain: Node = ClassDB.instantiate("Terrain3D")
	root.add_child(terrain)
	var runner = load("res://scripts/dev/terrain3d_movement_run.gd")
	var result: Dictionary = runner.run(terrain)
	if bool(result.get("ok", false)):
		print("[terrain3d-movement-smoke] %s" % str(result.get("log_line", "")))
		quit(0)
		return
	print("[terrain3d-movement-smoke] %s" % str(result.get("log_line", "")))
	quit(1)
