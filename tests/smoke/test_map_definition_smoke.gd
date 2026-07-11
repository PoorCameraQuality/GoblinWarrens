extends SceneTree

## Phase 4 headless smoke: map definition resources + paint session load.
## godot --headless --path . --script tests/smoke/test_map_definition_smoke.gd

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var runner = load("res://scripts/dev/map_definition_run.gd")
	var result: Dictionary = runner.run()
	if bool(result.get("ok", false)):
		print("[map-definition-smoke] %s" % str(result.get("log_line", "")))
		quit(0)
		return
	print("[map-definition-smoke] %s" % str(result.get("log_line", "")))
	quit(1)
