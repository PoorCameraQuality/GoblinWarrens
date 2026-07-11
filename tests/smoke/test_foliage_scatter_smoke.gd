extends SceneTree

## Phase 5 headless smoke: authored semantic foliage scatter compile.
## godot --headless --path . --script tests/smoke/test_foliage_scatter_smoke.gd

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var runner = load("res://scripts/dev/foliage_scatter_run.gd")
	var result: Dictionary = runner.run()
	if bool(result.get("ok", false)):
		print("[foliage-scatter-smoke] %s" % str(result.get("log_line", "")))
		quit(0)
		return
	print("[foliage-scatter-smoke] %s" % str(result.get("log_line", "")))
	quit(1)
