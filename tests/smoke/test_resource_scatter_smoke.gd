extends SceneTree

## Phase 6 headless smoke: authored resource + tree scatter compile.
## godot --headless --path . --script tests/smoke/test_resource_scatter_smoke.gd

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var runner = load("res://scripts/dev/resource_scatter_run.gd")
	var result: Dictionary = runner.run()
	if bool(result.get("ok", false)):
		print("[resource-scatter-smoke] %s" % str(result.get("log_line", "")))
		quit(0)
		return
	print("[resource-scatter-smoke] %s" % str(result.get("log_line", "")))
	quit(1)
