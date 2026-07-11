extends RefCounted

## Builds a minimal MapPlan from compiled authored map data for colony reuse.


static func from_compiled(
	grid,
	resource_map,
	foliage,
	warren_cell: Vector2i,
	storehouse_cell: Vector2i,
) -> MapPlan:
	var plan := MapPlan.new()
	if grid == null:
		return plan
	plan.width = grid.width
	plan.height = grid.height
	plan.heights = grid.heights
	plan.height_point_width = grid.height_point_width
	plan.height_point_height = grid.height_point_height
	plan.height_min = grid.height_min
	plan.height_max = grid.height_max
	plan.tile_classes = grid.tile_classes
	plan.warren_cell = warren_cell
	plan.storehouse_cell = storehouse_cell
	if resource_map != null:
		plan.prop_placements = resource_map.placements.duplicate()
		plan.scatter_stats = resource_map.stats.duplicate(true)
	plan.foliage_plan = foliage
	plan.mesh = null
	return plan
