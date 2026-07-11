extends SceneTree

## Workstream 2 headless smoke: authored colony bootstrap DTO.
## Scene spawn requires env vars — run tools/run_authored_colony_smoke.ps1 for full gate.
## godot --headless --path . --script tests/smoke/test_authored_colony_bootstrap.gd

func _init() -> void:
	var runner = load("res://scripts/dev/authored_colony_bootstrap_run.gd")
	var result: Dictionary = runner.run()
	if bool(result.get("ok", false)):
		print("[authored-colony-bootstrap] %s" % str(result.get("log_line", "")))
		quit(0)
		return
	print("[authored-colony-bootstrap] %s" % str(result.get("log_line", "")))
	quit(1)
