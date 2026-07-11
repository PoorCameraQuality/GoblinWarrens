extends SceneTree

## Headless Terrain3D compatibility spike test.
## godot --headless --path . --script tests/smoke/test_terrain3d_spike.gd

const SPIKE_SCENE := "res://scenes/dev/terrain3d_compat_spike.tscn"


func _init() -> void:
	if not ClassDB.class_exists("Terrain3D"):
		push_error("[terrain3d-spike] Terrain3D GDExtension class not found")
		quit(1)
		return
	call_deferred("_launch_scene")


func _launch_scene() -> void:
	var packed: PackedScene = load(SPIKE_SCENE)
	if packed == null:
		push_error("[terrain3d-spike] failed to load spike scene")
		quit(1)
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)
