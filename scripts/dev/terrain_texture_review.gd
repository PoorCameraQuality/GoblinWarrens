extends Node3D

## Terrain macro texture visual QA — see docs/terrain-texture-brief.md §15.
## Keys: 1 close (18m), 2 default (90m), 3 overview (520m). Wheel zooms.

const _TerrainMeshBuilder := preload("res://scripts/world/mapgen/terrain_mesh.gd")
const _TerrainMaterialBuilder := preload("res://scripts/world/mapgen/terrain_material.gd")

const _STRIP_COLS := 14
const _STRIP_ROWS := 8
const _CLASS_GAP_ROWS := 1

@onready var _camera: Camera3D = $Camera3D
@onready var _info_label: Label = $UI/InfoLabel

var _distance: float = Constants.CAMERA_DEFAULT_DISTANCE
var _yaw: float = deg_to_rad(-135.0)
var _pitch: float = deg_to_rad(35.0)
var _focus: Vector3 = Vector3.ZERO


func _ready() -> void:
	_build_review_terrain()
	_focus = Vector3(
		float(_STRIP_COLS) * Constants.TILE_SIZE * 0.5,
		0.0,
		float(_class_grid_height()) * Constants.TILE_SIZE * 0.5,
	)
	_apply_camera()
	_refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		if not key.pressed or key.echo:
			return
		match key.keycode:
			KEY_1:
				_distance = Constants.CAMERA_ZOOM_MIN
			KEY_2:
				_distance = Constants.CAMERA_DEFAULT_DISTANCE
			KEY_3:
				_distance = Constants.CAMERA_ZOOM_MAX
			_:
				return
		_apply_camera()
		_refresh_hud()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if not mb.pressed:
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_distance = maxf(Constants.CAMERA_ZOOM_MIN, _distance - Constants.CAMERA_ZOOM_STEP)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_distance = minf(Constants.CAMERA_ZOOM_MAX, _distance + Constants.CAMERA_ZOOM_STEP)
		else:
			return
		_apply_camera()
		_refresh_hud()


func _build_review_terrain() -> void:
	var tile_classes := _build_class_grid()
	var point_w := _STRIP_COLS + 1
	var point_h := _class_grid_height() + 1
	var heights := PackedFloat32Array()
	heights.resize(point_w * point_h)
	heights.fill(0.0)

	var mesh := TerrainMeshBuilder.build(heights, point_w, point_h, tile_classes)
	var terrain := MeshInstance3D.new()
	terrain.name = "ReviewTerrain"
	terrain.mesh = mesh
	terrain.material_override = TerrainMaterialBuilder.build()
	add_child(terrain)
	_add_class_labels(tile_classes)


func _build_class_grid() -> Array:
	var classes: Array[Defs.TerrainClass] = [
		Defs.TerrainClass.MUD_CLEARING,
		Defs.TerrainClass.MOSS,
		Defs.TerrainClass.FOREST_FLOOR,
		Defs.TerrainClass.ROCKY_SLOPE,
		Defs.TerrainClass.MUD_MOSSY,
		Defs.TerrainClass.CLIFF,
		Defs.TerrainClass.WARREN_GROUND,
	]
	var rows: Array = []
	for class_idx in range(classes.size()):
		for _gap in range(_CLASS_GAP_ROWS):
			rows.append(_repeat_class(Defs.TerrainClass.MOSS))
		rows.append(_repeat_class(classes[class_idx]))
	return rows


func _repeat_class(terrain_class: Defs.TerrainClass) -> Array:
	var row: Array = []
	row.resize(_STRIP_COLS)
	row.fill(terrain_class)
	return row


func _class_grid_height() -> int:
	return 7 * (_STRIP_ROWS + _CLASS_GAP_ROWS)


func _add_class_labels(tile_classes: Array) -> void:
	var class_names: PackedStringArray = [
		"MUD_CLEARING",
		"MOSS",
		"FOREST_FLOOR",
		"ROCKY_SLOPE",
		"MUD_MOSSY",
		"CLIFF",
		"WARREN_GROUND",
	]
	var block_stride := _STRIP_ROWS + _CLASS_GAP_ROWS
	for class_idx in range(class_names.size()):
		var row_y := class_idx * block_stride + int(_STRIP_ROWS * 0.5)
		var label := Label3D.new()
		label.text = class_names[class_idx]
		label.font_size = 48
		label.modulate = TerrainClassifier.class_color(class_idx as Defs.TerrainClass)
		label.position = Vector3(-1.5, 0.2, float(row_y) * Constants.TILE_SIZE)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)


func _apply_camera() -> void:
	var offset := Vector3(
		cos(_yaw) * cos(_pitch) * _distance,
		sin(_pitch) * _distance,
		sin(_yaw) * cos(_pitch) * _distance,
	)
	_camera.global_position = _focus + offset
	_camera.look_at(_focus, Vector3.UP)


func _refresh_hud() -> void:
	var mode := "macro" if TerrainPalette.all_macro_textures_present() else "legacy (macro files missing)"
	_info_label.text = (
		"Terrain texture review | zoom %.0fm | uv_scale %.3f | mode: %s\n"
		% [_distance, TerrainPalette.preferred_uv_scale(), mode]
		+ "Keys: 1=close (18m)  2=default (90m)  3=overview (520m)  |  wheel = zoom"
	)
