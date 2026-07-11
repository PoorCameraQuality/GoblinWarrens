extends RefCounted

## Narrow height/normal query layer over a height field or Terrain3D node.


static func sample_grid_height(grid, cell: Vector2i) -> float:
	if grid == null:
		return 0.0
	return grid.sample_height_at_cell(cell)


static func sample_world_height_from_grid(grid, world_x: float, world_z: float) -> float:
	if grid == null or grid.heights.is_empty():
		return 0.0
	var fx := clampf(world_x / Constants.TILE_SIZE, 0.0, float(grid.height_point_width - 1))
	var fz := clampf(world_z / Constants.TILE_SIZE, 0.0, float(grid.height_point_height - 1))
	var x0 := int(floor(fx))
	var z0 := int(floor(fz))
	var x1 := mini(x0 + 1, grid.height_point_width - 1)
	var z1 := mini(z0 + 1, grid.height_point_height - 1)
	var tx := fx - float(x0)
	var tz := fz - float(z0)
	var point_w: int = grid.height_point_width
	var h00: float = grid.heights[z0 * point_w + x0]
	var h10: float = grid.heights[z0 * point_w + x1]
	var h01: float = grid.heights[z1 * point_w + x0]
	var h11: float = grid.heights[z1 * point_w + x1]
	return lerpf(lerpf(h00, h10, tx), lerpf(h01, h11, tx), tz)


static func sample_world_height_from_terrain3d(terrain: Node, world_position: Vector3) -> float:
	if terrain == null or not terrain.is_class("Terrain3D"):
		return 0.0
	var terrain_data: Object = terrain.get("data")
	if terrain_data == null:
		return 0.0
	var height: float = terrain_data.call("get_height", world_position)
	return 0.0 if is_nan(height) else height
