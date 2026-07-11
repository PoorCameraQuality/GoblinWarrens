extends SceneTree

## Phase 8 headless smoke: strategic raid/camp compile from authored map.
## godot --headless --path . --script tests/smoke/test_strategic_map_smoke.gd

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var runner = load("res://scripts/dev/strategic_map_run.gd")
	var result: Dictionary = runner.run()
	if bool(result.get("ok", false)):
		print("[strategic-map-smoke] %s" % str(result.get("log_line", "")))
		quit(0)
		return
	print("[strategic-map-smoke] %s" % str(result.get("log_line", "")))
	quit(1)
