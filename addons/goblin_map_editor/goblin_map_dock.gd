@tool
extends Control
class_name GoblinMapDock

## Editor dock for authored semantic layer preview and minimal painting.

const DEFAULT_MAP_ROOT := "res://data/maps/three_lane_swamp_valley"
const _Factory := preload("res://scripts/world/map/map_definition_factory.gd")
const _PaintSession := preload("res://addons/goblin_map_editor/semantic_paint_session.gd")

var _map_root_edit: LineEdit
var _layer_option: OptionButton
var _value_option: OptionButton
var _brush_spin: SpinBox
var _status_label: Label
var _preview: TextureRect
var _session: RefCounted
var _definition: Resource
var _painting: bool = false


func _ready() -> void:
	_session = _PaintSession.new()
	custom_minimum_size = Vector2(280, 420)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	root.add_child(_section_label("Map"))
	_map_root_edit = LineEdit.new()
	_map_root_edit.text = DEFAULT_MAP_ROOT
	root.add_child(_map_root_edit)

	var load_row := HBoxContainer.new()
	root.add_child(load_row)
	load_row.add_child(_action_button("Load Map", _on_load_pressed))

	root.add_child(_section_label("Semantic Layer"))
	_layer_option = OptionButton.new()
	for layer_key: String in _PaintSession.PAINTABLE_LAYERS:
		_layer_option.add_item(layer_key)
	root.add_child(_layer_option)
	_layer_option.item_selected.connect(_on_layer_selected)

	root.add_child(_section_label("Paint Value"))
	_value_option = OptionButton.new()
	root.add_child(_value_option)

	var brush_row := HBoxContainer.new()
	root.add_child(brush_row)
	brush_row.add_child(_section_label("Brush"))
	_brush_spin = SpinBox.new()
	_brush_spin.min_value = 0
	_brush_spin.max_value = 32
	_brush_spin.value = 2
	brush_row.add_child(_brush_spin)

	var action_row := HBoxContainer.new()
	root.add_child(action_row)
	action_row.add_child(_action_button("Save Source", _on_save_pressed))
	action_row.add_child(_action_button("Re-bake", _on_rebake_pressed))

	_preview = TextureRect.new()
	_preview.custom_minimum_size = Vector2(256, 256)
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview.mouse_filter = Control.MOUSE_FILTER_STOP
	_preview.gui_input.connect(_on_preview_input)
	root.add_child(_preview)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_status_label)

	call_deferred("_bootstrap")


func _bootstrap() -> void:
	_on_load_pressed()


func _section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label


func _action_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	return button


func _on_load_pressed() -> void:
	var map_root := _map_root_edit.text.strip_edges()
	if map_root.is_empty():
		_set_status("Enter a map root path.")
		return
	if not _session.open_map(map_root):
		_set_status("Failed to open map manifest.")
		return
	_definition = _Factory.load_from_map_root(map_root)
	if _definition == null:
		_set_status("Failed to load map definition (run import first).")
		return
	_on_layer_selected(_layer_option.selected)
	_set_status("Loaded %s (%s)" % [_definition.display_name, _definition.map_id])


func _on_layer_selected(index: int) -> void:
	if _session.manifest.is_empty():
		return
	var layer_key := _PaintSession.PAINTABLE_LAYERS[index]
	if not _session.load_layer(layer_key):
		_set_status("Failed to load layer %s" % layer_key)
		return
	_refresh_value_options(layer_key)
	_refresh_preview()
	_set_status("Layer: %s (%dx%d source)" % [
		layer_key,
		_session.source_image.get_width(),
		_session.source_image.get_height(),
	])


func _refresh_value_options(layer_key: String) -> void:
	_value_option.clear()
	match layer_key:
		"biome_id":
			var palette: Dictionary = _session.manifest.get("biome_palette", {})
			var keys := palette.keys()
			keys.sort()
			for hex: String in keys:
				_value_option.add_item("%s id=%s" % [hex, str(palette[hex])])
		"buildability":
			_value_option.add_item("Unbuildable")
			_value_option.add_item("Buildable")
		"start_zone":
			_value_option.add_item("Neutral")
			_value_option.add_item("Allowed")
			_value_option.add_item("Forbidden")
		"no_scatter":
			_value_option.add_item("Scatter OK")
			_value_option.add_item("No Scatter")
		"raid_entry":
			_value_option.add_item("Clear")
			_value_option.add_item("Raid Entry")
		"enemy_camp_zone":
			_value_option.add_item("Clear")
			_value_option.add_item("Enemy Camp")
		_:
			_value_option.add_item("Default")


func _refresh_preview() -> void:
	var tex := _session.preview_texture()
	_preview.texture = tex


func _on_preview_input(event: InputEvent) -> void:
	if _session.source_image == null:
		return
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			_painting = mouse.pressed
			if _painting:
				_paint_at_mouse(mouse.position)
	elif event is InputEventMouseMotion and _painting:
		var motion := event as InputEventMouseMotion
		_paint_at_mouse(motion.position)


func _paint_at_mouse(local_pos: Vector2) -> void:
	var rect := _preview.get_rect()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var uv := Vector2(
		clampf(local_pos.x / rect.size.x, 0.0, 0.999),
		clampf(local_pos.y / rect.size.y, 0.0, 0.999),
	)
	var source_cell := _session.map_preview_uv_to_source(rect.size, uv)
	if source_cell.x < 0:
		return
	var layer_key := _PaintSession.PAINTABLE_LAYERS[_layer_option.selected]
	var paint_color := _session.paint_value_for_layer(layer_key, _value_option.selected)
	var brush := int(_brush_spin.value)
	_session.paint_at_source_pixel(source_cell, paint_color, brush)
	_refresh_preview()
	_set_status("Painted %s at %s (unsaved)" % [layer_key, source_cell])


func _on_save_pressed() -> void:
	if not _session.save_source_layer():
		_set_status("Save failed.")
		return
	_set_status("Saved source layer %s." % _session.active_layer_key)


func _on_rebake_pressed() -> void:
	if _session.dirty:
		_set_status("Save source changes before re-bake.")
		return
	var report: Dictionary = _session.rebake_layers()
	if not bool(report.get("ok", false)):
		_set_status("Re-bake failed: %s" % str(report.get("validation", {})))
		return
	_definition = _Factory.load_from_map_root(_session.map_root)
	_set_status("Re-baked to %s" % str(report.get("baked_dir", "")))


func _set_status(text: String) -> void:
	_status_label.text = text
