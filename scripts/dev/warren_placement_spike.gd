extends Node3D

## Dev spike: Warren placement candidates + suitability overlay on authored map.

const MAP_ROOT := "res://data/maps/three_lane_swamp_valley"
const _Controller := preload("res://scripts/world/warren/warren_placement_controller.gd")

@onready var _overlay: MeshInstance3D = $WarrenSuitabilityOverlay
@onready var _results_label: Label = $UI/ResultsLabel

var _context: Dictionary = {}
var _candidates: Array = []
var _candidate_index := 0


func _ready() -> void:
	_context = _Controller.load_context(MAP_ROOT)
	if _context.is_empty():
		_show_failure("Failed to load authored map context")
		return
	_candidates = _Controller.find_candidates(_context)
	if _candidates.is_empty():
		_show_failure("No valid Warren candidates found")
		return
	if _overlay and _overlay.has_method("apply_context"):
		_overlay.apply_context(_context, _candidates)
	_show_candidate(0)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	var key_event := event as InputEventKey
	if key_event.keycode == KEY_RIGHT or key_event.keycode == KEY_D:
		_show_candidate(_candidate_index + 1)
	elif key_event.keycode == KEY_LEFT or key_event.keycode == KEY_A:
		_show_candidate(_candidate_index - 1)


func _show_candidate(index: int) -> void:
	if _candidates.is_empty():
		return
	_candidate_index = posmod(index, _candidates.size())
	var report: Dictionary = _candidates[_candidate_index]
	var origin: Vector2i = report.get("origin", Vector2i.ZERO)
	var resources: Dictionary = report.get("resources_near", {})
	var summary := (
		"Warren placement spike (%d/%d)\n"
		% [_candidate_index + 1, _candidates.size()]
		+ "  origin=%s score=%d label=%s\n"
		% [origin, int(report.get("score", 0)), str(report.get("label_name", ""))]
		+ "  buildable_near=%d exits=%d border=%d\n"
		% [
			int(report.get("buildable_near", 0)),
			int(report.get("walkable_exits", 0)),
			int(report.get("border_cells", 0)),
		]
		+ "  resources food=%s wood=%s stone=%s gold=%s\n"
		% [
			str(resources.get("food", 0)),
			str(resources.get("wood", 0)),
			str(resources.get("stone", 0)),
			str(resources.get("gold", 0)),
		]
		+ "  tags=%s\n" % str(report.get("tags", []))
		+ "  Use A/D or Left/Right to cycle candidates."
	)
	_results_label.text = summary
	if _overlay and _overlay.has_method("apply_context"):
		_overlay.apply_context(_context, [report])


func _show_failure(message: String) -> void:
	push_error("[warren-placement-spike] %s" % message)
	if _results_label:
		_results_label.text = message
	if _should_auto_quit():
		get_tree().call_deferred("quit", 1)


static func _should_auto_quit() -> bool:
	return OS.has_feature("server") or DisplayServer.get_name() == "headless"


func _exit_tree() -> void:
	if _should_auto_quit() and not _candidates.is_empty():
		print(
			"[warren-placement-spike] ok candidates=%d top_score=%d"
			% [_candidates.size(), int(_candidates[0].get("score", 0))]
		)
		get_tree().call_deferred("quit", 0)
