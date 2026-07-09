extends SceneTree

# Headless smoke test. Runs with:
#     godot --headless --script tests/smoke/test_smoke.gd
#
# Expected:
#     exit code 0
#     stdout contains "[smoke] ok"
#
# This test must remain dependency-free so it works before any addons are
# installed. Add more thorough tests under tests/ using GUT once it's wired in.

func _init() -> void:
	var ok: bool = true

	# 1. Project name is set.
	var name: String = ProjectSettings.get_setting("application/config/name", "")
	if name != "Goblin Warrens":
		push_error("[smoke] unexpected project name: %s" % name)
		ok = false

	# 2. Renderer is forward_plus.
	var renderer: String = ProjectSettings.get_setting(
		"rendering/renderer/rendering_method", ""
	)
	if renderer != "forward_plus":
		push_error("[smoke] unexpected renderer: %s" % renderer)
		ok = false

	# 3. Required top-level directories exist.
	var required: PackedStringArray = PackedStringArray([
		"res://scenes",
		"res://scripts",
		"res://assets",
		"res://docs",
	])
	for path in required:
		if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)):
			push_error("[smoke] missing required directory: %s" % path)
			ok = false

	if ok:
		print("[smoke] ok")
		quit(0)
	else:
		quit(1)
