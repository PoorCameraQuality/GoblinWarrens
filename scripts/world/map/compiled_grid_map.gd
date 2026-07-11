class_name CompiledGridMap
extends RefCounted

## Phase-2 gameplay grid compiled from baked semantic map layers.
## See docs/technical/TERRAIN3D_HYBRID_MAP_PLAN.md §4.

var map_id: String = ""
var display_name: String = ""
var width: int = 0
var height: int = 0
var heights: PackedFloat32Array = PackedFloat32Array()
var height_point_width: int = 0
var height_point_height: int = 0
var height_min: float = 0.0
var height_max: float = 0.0
var walkable: PackedByteArray = PackedByteArray()
var buildable: PackedByteArray = PackedByteArray()
var movement_cost: PackedByteArray = PackedByteArray()
var tile_classes: Array = [] ## rows of Defs.TerrainClass


func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


func _cell_index(cell: Vector2i) -> int:
	return cell.y * width + cell.x


func is_walkable_cell(cell: Vector2i) -> bool:
	if not is_in_bounds(cell):
		return false
	return walkable[_cell_index(cell)] != 0


func is_buildable_cell(cell: Vector2i) -> bool:
	if not is_in_bounds(cell):
		return false
	return buildable[_cell_index(cell)] != 0


func movement_cost_at(cell: Vector2i) -> int:
	if not is_in_bounds(cell):
		return 255
	return int(movement_cost[_cell_index(cell)])


func terrain_class_at(cell: Vector2i) -> int:
	if not is_in_bounds(cell):
		return Defs.TerrainClass.CLIFF
	return tile_classes[cell.y][cell.x]


func sample_height_at_cell(cell: Vector2i) -> float:
	if heights.is_empty():
		return 0.0
	var fx := clampf(float(cell.x) + 0.5, 0.0, float(height_point_width - 1))
	var fz := clampf(float(cell.y) + 0.5, 0.0, float(height_point_height - 1))
	var x0 := int(floor(fx))
	var z0 := int(floor(fz))
	var x1 := mini(x0 + 1, height_point_width - 1)
	var z1 := mini(z0 + 1, height_point_height - 1)
	var tx := fx - float(x0)
	var tz := fz - float(z0)
	var h00 := heights[z0 * height_point_width + x0]
	var h10 := heights[z0 * height_point_width + x1]
	var h01 := heights[z1 * height_point_width + x0]
	var h11 := heights[z1 * height_point_width + x1]
	var hx0 := lerpf(h00, h10, tx)
	var hx1 := lerpf(h01, h11, tx)
	return lerpf(hx0, hx1, tz)


func apply_to_movement(movement) -> void:
	if movement == null:
		return
	movement.set_height_field(heights, height_point_width, height_point_height)
	for y in range(height):
		for x in range(width):
			var cell := Vector2i(x, y)
			movement.set_solid(cell, not is_walkable_cell(cell))
			if is_walkable_cell(cell):
				var cost := movement_cost_at(cell)
				var weight := 255.0 / float(maxi(cost, 1))
				movement.set_point_weight_scale(cell, weight)


func count_walkable_cells() -> int:
	var total := 0
	for value in walkable:
		if value != 0:
			total += 1
	return total


func count_buildable_cells() -> int:
	var total := 0
	for value in buildable:
		if value != 0:
			total += 1
	return total
