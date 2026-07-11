@tool
extends EditorPlugin

## Minimal semantic map editor dock (Phase 4).

var _dock: Control


func _enter_tree() -> void:
	var dock_script: Script = load("res://addons/goblin_map_editor/goblin_map_dock.gd")
	if dock_script == null:
		push_error("Goblin Map Editor: failed to load dock script.")
		return
	_dock = dock_script.new() as Control
	if _dock == null:
		push_error("Goblin Map Editor: dock script did not instantiate.")
		return
	add_control_to_dock(DOCK_SLOT_LEFT_UL, _dock)
	_dock.name = "Goblin Map"


func _exit_tree() -> void:
	if _dock != null:
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null
