class_name MovementAdapter
extends RefCounted

## Wraps AStarGrid2D for tile pathfinding. All goblin movement requests go here.

var _grid: AStarGrid2D
var _grid_width: int = 0
var _grid_height: int = 0
var _heights: PackedFloat32Array = PackedFloat32Array()
var _height_point_width: int = 0
var _height_point_height: int = 0


func _init(width: int, height: int) -> void:
	_grid_width = width
	_grid_height = height
	_grid = AStarGrid2D.new()
	_grid.region = Rect2i(0, 0, width, height)
	_grid.cell_size = Vector2(Constants.TILE_SIZE, Constants.TILE_SIZE)
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ALWAYS
	_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_grid.update()


func set_height_field(heights: PackedFloat32Array, point_width: int, point_height: int) -> void:
	_heights = heights
	_height_point_width = point_width
	_height_point_height = point_height


func sample_height_at_cell(cell: Vector2i) -> float:
	if _heights.is_empty():
		return 0.0
	var fx := clampf(float(cell.x) + 0.5, 0.0, float(_height_point_width - 1))
	var fz := clampf(float(cell.y) + 0.5, 0.0, float(_height_point_height - 1))
	var x0 := int(floor(fx))
	var z0 := int(floor(fz))
	var x1 := mini(x0 + 1, _height_point_width - 1)
	var z1 := mini(z0 + 1, _height_point_height - 1)
	var tx := fx - float(x0)
	var tz := fz - float(z0)
	var h00 := _heights[z0 * _height_point_width + x0]
	var h10 := _heights[z0 * _height_point_width + x1]
	var h01 := _heights[z1 * _height_point_width + x0]
	var h11 := _heights[z1 * _height_point_width + x1]
	var hx0 := lerpf(h00, h10, tx)
	var hx1 := lerpf(h01, h11, tx)
	return lerpf(hx0, hx1, tz)


func footprint_center_world(cell: Vector2i, size: Vector2i) -> Vector3:
	var center := Vector2(cell) + Vector2(size) * 0.5
	var sample_cell := cell + Vector2i(size.x / 2, size.y / 2)
	return Vector3(
		center.x * Constants.TILE_SIZE,
		sample_height_at_cell(sample_cell),
		center.y * Constants.TILE_SIZE,
	)


func grid_to_world(cell: Vector2i) -> Vector3:
	return Vector3(
		(cell.x + 0.5) * Constants.TILE_SIZE,
		sample_height_at_cell(cell),
		(cell.y + 0.5) * Constants.TILE_SIZE,
	)


func world_to_grid(world: Vector3) -> Vector2i:
	return Vector2i(
		int(floor(world.x / Constants.TILE_SIZE)),
		int(floor(world.z / Constants.TILE_SIZE)),
	)


func grid_width() -> int:
	return _grid_width


func grid_height() -> int:
	return _grid_height


func is_in_bounds(cell: Vector2i) -> bool:
	return (
		cell.x >= 0
		and cell.y >= 0
		and cell.x < _grid_width
		and cell.y < _grid_height
	)


func set_footprint_solid(origin: Vector2i, size: Vector2i, solid: bool) -> void:
	for dx in range(size.x):
		for dy in range(size.y):
			set_solid(origin + Vector2i(dx, dy), solid)


func is_walkable(cell: Vector2i) -> bool:
	return is_in_bounds(cell) and not _grid.is_point_solid(cell)


func set_solid(cell: Vector2i, solid: bool) -> void:
	if not is_in_bounds(cell):
		return
	_grid.set_point_solid(cell, solid)


func set_point_weight_scale(cell: Vector2i, weight_scale: float) -> void:
	if not is_in_bounds(cell):
		return
	_grid.set_point_weight_scale(cell, weight_scale)


func find_path(from_cell: Vector2i, to_cell: Vector2i) -> Array[Vector2i]:
	if not is_in_bounds(from_cell) or not is_in_bounds(to_cell):
		return []
	if _grid.is_point_solid(to_cell):
		return []
	var raw: PackedVector2Array = _grid.get_point_path(from_cell, to_cell)
	var result: Array[Vector2i] = []
	for point in raw:
		result.append(Vector2i(point))
	return result


func nearest_reachable(from_cell: Vector2i, target: Vector2i) -> Vector2i:
	if not is_in_bounds(target):
		return from_cell
	if not _grid.is_point_solid(target):
		return target
	# Spiral search for nearest walkable tile.
	for radius in range(1, max(_grid_width, _grid_height)):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				if absi(dx) != radius and absi(dy) != radius:
					continue
				var candidate := target + Vector2i(dx, dy)
				if is_in_bounds(candidate) and not _grid.is_point_solid(candidate):
					return candidate
	return from_cell
