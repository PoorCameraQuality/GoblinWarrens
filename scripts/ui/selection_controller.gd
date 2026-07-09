class_name SelectionController
extends Node

## RTS selection and right-click commands (Milestone 2).

signal selection_changed(selected: Array)

var _camera: RtsCamera
var _movement: MovementAdapter
var _goblins_root: Node3D
var _job_service: JobService
var _selected: Array[Goblin] = []
var _drag_start: Vector2 = Vector2.ZERO
var _dragging: bool = false
var _box: ColorRect
var _build_placement: BuildPlacement


func setup(
	camera: RtsCamera,
	movement: MovementAdapter,
	goblins_root: Node3D,
	job_service: JobService,
	selection_box: ColorRect
) -> void:
	_camera = camera
	_movement = movement
	_goblins_root = goblins_root
	_job_service = job_service
	_box = selection_box
	if _box != null:
		_box.visible = false
	set_process_unhandled_input(true)


func set_build_placement(build_placement: BuildPlacement) -> void:
	_build_placement = build_placement


func get_selected() -> Array[Goblin]:
	return _selected.duplicate()


func _unhandled_input(event: InputEvent) -> void:
	if _camera == null:
		return
	if _build_placement != null and _build_placement.is_active():
		return
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion and _dragging:
		_update_drag_box((event as InputEventMouseMotion).position)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_start = event.position
			_dragging = true
			if _box != null:
				_box.visible = true
				_box.position = _drag_start
				_box.size = Vector2.ZERO
		else:
			_finish_left_release(event.position)
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_issue_command(event.position)


func _finish_left_release(end_pos: Vector2) -> void:
	var drag_rect := Rect2(_drag_start, end_pos - _drag_start)
	var is_drag := (
		absf(drag_rect.size.x) >= Constants.DRAG_SELECT_MIN_SIZE
		or absf(drag_rect.size.y) >= Constants.DRAG_SELECT_MIN_SIZE
	)
	if is_drag:
		_apply_box_selection(drag_rect, Input.is_key_pressed(KEY_SHIFT))
	else:
		_apply_click_selection(end_pos, Input.is_key_pressed(KEY_SHIFT))
	_dragging = false
	if _box != null:
		_box.visible = false


func _apply_click_selection(screen_pos: Vector2, additive: bool) -> void:
	var picked := WorldRay.closest_goblin(_camera, screen_pos, _goblins_root)
	if not additive:
		_clear_selection()
	if picked == null:
		_emit_selection()
		return
	if additive and picked in _selected:
		_remove_from_selection(picked)
	else:
		_add_to_selection(picked)
	_emit_selection()


func _apply_box_selection(rect: Rect2, additive: bool) -> void:
	var picked := WorldRay.goblins_in_screen_rect(_camera, rect, _goblins_root)
	if not additive:
		_clear_selection()
	for goblin in picked:
		_add_to_selection(goblin)
	_emit_selection()


func _issue_command(screen_pos: Vector2) -> void:
	if _selected.is_empty():
		return
	var world := _camera.ground_hit(screen_pos)
	var cell := _movement.world_to_grid(world)
	var construction := _pick_construction_at(cell)
	if construction != null:
		_command_build(construction)
		return
	var resource := _pick_resource_at(cell)
	if resource != null:
		_command_gather(resource)
		return
	_command_move(cell)


func _command_move(target_cell: Vector2i) -> void:
	for i in _selected.size():
		var goblin := _selected[i]
		var offset := _spread_offset(i)
		var dest := _movement.nearest_reachable(
			goblin.grid_cell,
			target_cell + offset,
		)
		goblin.command_move(dest)


func _command_gather(target: ResourceNode) -> void:
	for goblin in _selected:
		goblin.command_gather(target, _job_service)


func _command_build(site: ConstructionSite) -> void:
	for goblin in _selected:
		goblin.command_build(site, _job_service)


func _pick_resource_at(cell: Vector2i) -> ResourceNode:
	var best: ResourceNode = null
	var best_dist: int = 999999
	for node in get_tree().get_nodes_in_group(Defs.GROUP_RESOURCE_NODE):
		if not node is ResourceNode:
			continue
		var resource := node as ResourceNode
		if not resource.is_available():
			continue
		var dist: int = (resource.grid_cell - cell).length_squared()
		if dist <= 2 and dist < best_dist:
			best_dist = dist
			best = resource
	return best


func _pick_construction_at(cell: Vector2i) -> ConstructionSite:
	for node in get_tree().get_nodes_in_group(Defs.GROUP_CONSTRUCTION):
		if not node is ConstructionSite:
			continue
		var site := node as ConstructionSite
		if site.is_complete() or not site.resources_paid:
			continue
		for footprint_cell in site.footprint_cells():
			if footprint_cell == cell or (footprint_cell - cell).length_squared() <= 2:
				return site
	return null


func _spread_offset(index: int) -> Vector2i:
	if index == 0:
		return Vector2i.ZERO
	var ring: int = int(ceil((sqrt(float(index)) + 1.0) * 0.5))
	var slot: int = index - 1
	return Vector2i((slot % 3) - 1, (slot / 3) % 3 - 1) * ring


func _add_to_selection(goblin: Goblin) -> void:
	if goblin in _selected:
		return
	_selected.append(goblin)
	goblin.set_selected(true)


func _remove_from_selection(goblin: Goblin) -> void:
	_selected.erase(goblin)
	goblin.set_selected(false)


func _clear_selection() -> void:
	for goblin in _selected:
		goblin.set_selected(false)
	_selected.clear()


func _update_drag_box(current: Vector2) -> void:
	if _box == null:
		return
	var rect := Rect2(_drag_start, current - _drag_start)
	_box.position = Vector2(minf(rect.position.x, rect.end.x), minf(rect.position.y, rect.end.y))
	_box.size = Vector2(absf(rect.size.x), absf(rect.size.y))


func _emit_selection() -> void:
	selection_changed.emit(_selected.duplicate())
