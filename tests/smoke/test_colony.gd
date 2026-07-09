extends SceneTree

## Headless colony integration smoke test.
## godot --headless --path . --script tests/smoke/test_colony.gd
##
## SceneTree --script mode does not reliably run child _ready(); spawn a nested
## Godot process against colony_smoke_runner.tscn instead.

const RUNNER_SCENE := "res://tests/smoke/colony_smoke_runner.tscn"


func _init() -> void:
	if not ResourceLoader.exists(RUNNER_SCENE):
		push_error("[colony-smoke] missing runner scene: %s" % RUNNER_SCENE)
		quit(1)
		return

	var godot_exe: String = OS.get_executable_path()
	var project_dir: String = ProjectSettings.globalize_path("res://")
	var args: PackedStringArray = PackedStringArray([
		"--headless",
		"--path",
		project_dir,
		"--scene",
		RUNNER_SCENE,
	])
	var output: Array = []
	var exit_code: int = OS.execute(godot_exe, args, output, true, true)
	if exit_code != 0:
		for line in output:
			push_error(str(line))
		quit(exit_code)
		return
	for line in output:
		print(line)
	quit(0)
