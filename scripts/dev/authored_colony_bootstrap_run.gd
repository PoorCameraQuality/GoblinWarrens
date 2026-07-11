extends RefCounted

## Workstream 2 production colony bootstrap validation (loaded at runtime).


static func run() -> Dictionary:
	var DemoRun = load("res://scripts/dev/authored_demo_run.gd")
	if DemoRun == null:
		return {"ok": false, "log_line": "FAIL demo_run_load_failed"}
	return DemoRun.run()
