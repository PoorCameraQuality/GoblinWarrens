class_name PlacementValidator
extends RefCounted

## Grid footprint checks for building placement (Milestone 3).


static func footprint_cells(origin: Vector2i, size: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for dx in range(size.x):
		for dy in range(size.y):
			cells.append(origin + Vector2i(dx, dy))
	return cells


static func is_footprint_clear(origin: Vector2i, def: BuildingDef, movement: MovementAdapter) -> bool:
	if def == null or movement == null:
		return false
	for cell in footprint_cells(origin, def.footprint):
		if not movement.is_walkable(cell):
			return false
	return true
