extends SceneTree

## Phase 9 headless smoke: colony observability formatters and inventory scan.
## godot --headless --path . --script tests/smoke/test_colony_observability_smoke.gd

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var runner = load("res://scripts/dev/colony_observability_run.gd")
	var result: Dictionary = runner.run()
	if bool(result.get("ok", false)):
		print("[colony-observability-smoke] %s" % str(result.get("log_line", "")))
		quit(0)
		return
	print("[colony-observability-smoke] %s" % str(result.get("log_line", "")))
	quit(1)
