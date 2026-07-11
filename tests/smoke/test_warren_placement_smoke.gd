extends SceneTree

## Phase 7 headless smoke: Warren placement suitability on authored map.
## godot --headless --path . --script tests/smoke/test_warren_placement_smoke.gd

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var runner = load("res://scripts/dev/warren_placement_run.gd")
	var result: Dictionary = runner.run()
	if bool(result.get("ok", false)):
		print("[warren-placement-smoke] %s" % str(result.get("log_line", "")))
		quit(0)
		return
	print("[warren-placement-smoke] %s" % str(result.get("log_line", "")))
	quit(1)
