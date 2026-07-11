extends Control

## Pre-game Warren placement picker for authored demo (Phase 10).

signal warren_chosen(origin: Vector2i, report: Dictionary)

const _Controller := preload("res://scripts/world/warren/warren_placement_controller.gd")

var _map_root: String = ""
var _context: Dictionary = {}
var _candidates: Array = []
var _index: int = 0
var _wired: bool = false


func _ready() -> void:
	_wire_controls()


func setup(map_root: String) -> void:
	_wire_controls()
	_map_root = map_root
	_context = _Controller.load_context(map_root)
	_candidates = _Controller.find_candidates(_context)
	if _candidates.is_empty():
		_get_title().text = "No valid Warren sites"
		_get_detail().text = "Check start_zone layers on the authored map."
		_get_prev_button().disabled = true
		_get_next_button().disabled = true
		_get_confirm_button().disabled = true
		return
	_show_candidate(0)


func _wire_controls() -> void:
	if _wired:
		return
	_wired = true
	_get_prev_button().pressed.connect(_on_prev_pressed)
	_get_next_button().pressed.connect(_on_next_pressed)
	_get_confirm_button().pressed.connect(_on_confirm_pressed)


func _get_title() -> Label:
	return $Panel/Margin/VBox/TitleLabel as Label


func _get_detail() -> Label:
	return $Panel/Margin/VBox/DetailLabel as Label


func _get_prev_button() -> Button:
	return $Panel/Margin/VBox/Buttons/PrevButton as Button


func _get_next_button() -> Button:
	return $Panel/Margin/VBox/Buttons/NextButton as Button


func _get_confirm_button() -> Button:
	return $Panel/Margin/VBox/Buttons/ConfirmButton as Button


func _on_prev_pressed() -> void:
	_show_candidate(_index - 1)


func _on_next_pressed() -> void:
	_show_candidate(_index + 1)


func _on_confirm_pressed() -> void:
	if _candidates.is_empty():
		return
	var report: Dictionary = _candidates[_index]
	var origin: Vector2i = report.get("origin", Vector2i.ZERO)
	warren_chosen.emit(origin, report)
	visible = false


func _show_candidate(index: int) -> void:
	if _candidates.is_empty():
		return
	_index = posmod(index, _candidates.size())
	var report: Dictionary = _candidates[_index]
	var origin: Vector2i = report.get("origin", Vector2i.ZERO)
	var resources: Dictionary = report.get("resources_near", {})
	_get_title().text = "Choose your Warren (%d/%d)" % [_index + 1, _candidates.size()]
	_get_detail().text = (
		"Site %s  |  %s  |  score %d\n"
		% [str(origin), str(report.get("label_name", "?")), int(report.get("score", 0))]
		+ "Buildable nearby: %d  |  Exits: %d\n"
		% [int(report.get("buildable_near", 0)), int(report.get("walkable_exits", 0))]
		+ "Resources — food: %s  wood: %s  stone: %s  gold: %s"
		% [
			str(resources.get("food", 0)),
			str(resources.get("wood", 0)),
			str(resources.get("stone", 0)),
			str(resources.get("gold", 0)),
		]
	)
