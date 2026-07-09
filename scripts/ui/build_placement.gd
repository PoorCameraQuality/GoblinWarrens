class_name BuildPlacement
extends Node

## Ghost preview and player-driven building placement (Milestone 3).

signal placement_started(definition: BuildingDef)
signal placement_ended
signal building_placed(site: ConstructionSite)

var _camera: RtsCamera
var _movement: MovementAdapter
var _colony: GoblinWarrenColony
var _ghost_root: Node3D
var _status_label: Label
var _ghost: CSGBox3D
var _valid_mat: StandardMaterial3D
var _invalid_mat: StandardMaterial3D
var _active_def: BuildingDef = null
var _placement_options: Array[BuildingDef] = []
var _placement_yaw: float = 0.0


func setup(
	camera: RtsCamera,
	movement: MovementAdapter,
	colony: GoblinWarrenColony,
	ghost_root: Node3D,
	status_label: Label,
	options: Array[BuildingDef]
) -> void:
	_camera = camera
	_movement = movement
	_colony = colony
	_ghost_root = ghost_root
	_status_label = status_label
	_placement_options = options
	_create_ghost()
	set_process(true)
	set_process_unhandled_input(true)


func is_active() -> bool:
	return _active_def != null


func start_placement(def: BuildingDef) -> void:
	if def == null:
		return
	_active_def = def
	_placement_yaw = 0.0
	_ghost.visible = true
	placement_started.emit(def)


func cancel_placement() -> void:
	if _active_def == null:
		return
	_active_def = null
	_ghost.visible = false
	placement_ended.emit()
	_update_status_idle()


func _process(_delta: float) -> void:
	if _active_def == null or _camera == null or _movement == null:
		return
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var world: Vector3 = _camera.ground_hit(mouse)
	var origin: Vector2i = _movement.world_to_grid(world)
	_update_ghost(origin)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_handle_key(event as InputEventKey)
	if not is_active():
		return
	if event is InputEventMouseButton:
		_handle_mouse(event as InputEventMouseButton)


func _handle_key(event: InputEventKey) -> void:
	match event.keycode:
		KEY_ESCAPE:
			if is_active():
				cancel_placement()
				get_viewport().set_input_as_handled()
		KEY_1:
			_select_option(0, event)
		KEY_2:
			_select_option(1, event)
		KEY_3:
			_select_option(2, event)
		KEY_4:
			_select_option(3, event)
		KEY_5:
			_select_option(4, event)
		KEY_6:
			_select_option(5, event)
		KEY_7:
			_select_option(6, event)
		KEY_8:
			_select_option(7, event)
		KEY_9:
			_select_option(8, event)
		KEY_0:
			_select_option(9, event)
		KEY_BRACKETLEFT:
			if is_active():
				_rotate_placement(-Constants.BUILDING_PLACE_ROTATE_STEP_DEG)
				get_viewport().set_input_as_handled()
		KEY_BRACKETRIGHT:
			if is_active():
				_rotate_placement(Constants.BUILDING_PLACE_ROTATE_STEP_DEG)
				get_viewport().set_input_as_handled()


func _select_option(index: int, event: InputEventKey) -> void:
	if index < 0 or index >= _placement_options.size():
		return
	start_placement(_placement_options[index])
	get_viewport().set_input_as_handled()


func _handle_mouse(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_try_place_at_mouse(event.position)
		get_viewport().set_input_as_handled()
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		cancel_placement()
		get_viewport().set_input_as_handled()


func _try_place_at_mouse(screen_pos: Vector2) -> void:
	if _colony == null or _active_def == null:
		return
	var origin: Vector2i = _grid_origin_from_screen(screen_pos)
	var site: ConstructionSite = _colony.try_place_building(origin, _active_def, _placement_yaw)
	if site != null:
		building_placed.emit(site)
		cancel_placement()


func _grid_origin_from_screen(screen_pos: Vector2) -> Vector2i:
	var world: Vector3 = _camera.ground_hit(screen_pos)
	return _movement.world_to_grid(world)


func _update_ghost(origin: Vector2i) -> void:
	var valid: bool = _colony != null and _colony.can_place_building(origin, _active_def)
	_ghost.material = _valid_mat if valid else _invalid_mat
	var size: Vector2i = _active_def.footprint
	var center := Vector2(origin) + Vector2(size) * 0.5
	_ghost.position = Vector3(
		center.x * Constants.TILE_SIZE,
		0.35,
		center.y * Constants.TILE_SIZE,
	)
	_ghost.size = Vector3(size.x * 0.92, 0.7, size.y * 0.92)
	_ghost.rotation.y = _placement_yaw
	_update_status(origin)


func _rotate_placement(step_deg: float) -> void:
	_placement_yaw = wrapf(_placement_yaw + deg_to_rad(step_deg), -PI, PI)


func _create_ghost() -> void:
	_ghost = CSGBox3D.new()
	_ghost.name = "BuildGhost"
	_ghost.visible = false
	_valid_mat = StandardMaterial3D.new()
	_valid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_valid_mat.albedo_color = Color(0.2, 0.9, 0.35, 0.45)
	_invalid_mat = StandardMaterial3D.new()
	_invalid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_invalid_mat.albedo_color = Color(0.9, 0.2, 0.15, 0.45)
	_ghost.material = _invalid_mat
	if _ghost_root != null:
		_ghost_root.add_child(_ghost)


func _update_status(origin: Vector2i) -> void:
	if _status_label == null or _active_def == null:
		return
	var cost: String = _format_cost(_active_def)
	var state: String = "ready" if _colony.can_place_building(origin, _active_def) else "invalid"
	_status_label.text = "Placing %s (%s) — %s — LMB place, `[`/`]` rotate, RMB/Esc cancel" % [
		_active_def.display_name,
		cost,
		state,
	]


func _update_status_idle() -> void:
	if _status_label == null:
		return
	if _active_def == null:
		_status_label.text = "Build: press 1-9 or use buttons below"


func _format_cost(def: BuildingDef) -> String:
	var parts: PackedStringArray = PackedStringArray()
	if def.wood_cost > 0:
		parts.append("%d wood" % def.wood_cost)
	if def.stone_cost > 0:
		parts.append("%d stone" % def.stone_cost)
	if def.gold_cost > 0:
		parts.append("%d gold" % def.gold_cost)
	if parts.is_empty():
		return "free"
	return ", ".join(parts)
