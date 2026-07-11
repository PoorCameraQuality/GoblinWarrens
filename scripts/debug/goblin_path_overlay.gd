extends Node3D

## Draws active goblin path polylines for debug inspection (Phase 9).

const PATH_COLORS: Array[Color] = [
	Color(0.95, 0.85, 0.2, 0.95),
	Color(0.2, 0.85, 0.95, 0.95),
	Color(0.95, 0.45, 0.2, 0.95),
	Color(0.65, 0.35, 0.95, 0.95),
]

var _movement: MovementAdapter = null
var _get_goblins: Callable = Callable()


func setup(movement: MovementAdapter, get_goblins: Callable) -> void:
	_movement = movement
	_get_goblins = get_goblins
	set_process(false)


func set_active(active: bool) -> void:
	visible = active
	set_process(active)
	if active:
		refresh()


func refresh() -> void:
	for child in get_children():
		child.queue_free()
	if _movement == null or not _get_goblins.is_valid():
		return
	var goblins: Array = _get_goblins.call()
	var color_index := 0
	for goblin in goblins:
		if goblin == null or not goblin.is_alive():
			continue
		var extra: Dictionary = goblin.dev_observation_extra()
		var path_cells: Array = extra.get("path_cells", [])
		if path_cells.size() < 2:
			continue
		var mesh_instance := _build_path_mesh(path_cells, PATH_COLORS[color_index % PATH_COLORS.size()])
		add_child(mesh_instance)
		color_index += 1


func _process(_delta: float) -> void:
	refresh()


func _build_path_mesh(path_cells: Array, color: Color) -> MeshInstance3D:
	var immediate := ImmediateMesh.new()
	immediate.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for cell_variant in path_cells:
		var cell: Vector2i = cell_variant
		var world := _movement.grid_to_world(cell) + Vector3(0.0, 0.35, 0.0)
		immediate.surface_add_vertex(world)
	immediate.surface_end()

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = immediate
	mesh_instance.set_surface_override_material(0, material)
	return mesh_instance
