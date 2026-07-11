class_name WorldSurface
extends RefCounted

## Runtime ground height for props, ghosts, and picking (Terrain3D when present).

const _TerrainAdapter := preload("res://scripts/world/terrain/terrain_surface_adapter.gd")


static func sample_height_at_world(world_x: float, world_z: float) -> float:
	var terrain: Node = Services.terrain3d
	if terrain != null and is_instance_valid(terrain):
		var h: float = _TerrainAdapter.sample_world_height_from_terrain3d(
			terrain,
			Vector3(world_x, 0.0, world_z),
		)
		if not is_nan(h):
			return h
	if Services.movement != null:
		return Services.movement.sample_height_at_world(world_x, world_z)
	return 0.0


static func snap_world_position(world_pos: Vector3) -> Vector3:
	world_pos.y = sample_height_at_world(world_pos.x, world_pos.z)
	return world_pos


static func cell_center_on_surface(cell: Vector2i) -> Vector3:
	var world_x := (float(cell.x) + 0.5) * Constants.TILE_SIZE
	var world_z := (float(cell.y) + 0.5) * Constants.TILE_SIZE
	return Vector3(world_x, sample_height_at_world(world_x, world_z), world_z)


static func footprint_center_on_surface(origin: Vector2i, footprint: Vector2i) -> Vector3:
	var center := Vector2(origin) + Vector2(footprint) * 0.5
	var world_x := center.x * Constants.TILE_SIZE
	var world_z := center.y * Constants.TILE_SIZE
	return Vector3(world_x, sample_height_at_world(world_x, world_z), world_z)
