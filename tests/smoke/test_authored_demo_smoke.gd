extends SceneTree

## Phase 10 headless smoke: authored demo bootstrap DTO.
## Scene spawn is covered by tools/run_authored_colony_smoke.ps1 and defer colony path.
## godot --headless --path . --script tests/smoke/test_authored_demo_smoke.gd

func _init() -> void:
	var runner = load("res://scripts/dev/authored_demo_run.gd")
	var result: Dictionary = runner.run()
	if bool(result.get("ok", false)):
		print("[authored-demo-smoke] %s" % str(result.get("log_line", "")))
		quit(0)
		return
	print("[authored-demo-smoke] %s" % str(result.get("log_line", "")))
	quit(1)
