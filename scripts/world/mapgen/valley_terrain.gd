class_name ValleyTerrain
extends RefCounted

## Height-derived valley floor / ridge barrier scores for placement and classification.


static func cache_height_span(plan: MapPlan) -> void:
	if plan.heights.is_empty():
		plan.height_min = 0.0
		plan.height_max = 0.0
		return
	var min_h := INF
	var max_h := -INF
	for value in plan.heights:
		min_h = minf(min_h, value)
		max_h = maxf(max_h, value)
	plan.height_min = min_h
	plan.height_max = max_h


static func normalized_height(plan: MapPlan, cell: Vector2i) -> float:
	var span := maxf(plan.height_max - plan.height_min, 0.001)
	var h := HeightSampler.sample_cell(plan, cell)
	return clampf((h - plan.height_min) / span, 0.0, 1.0)


static func slope_degrees(plan: MapPlan, cell: Vector2i) -> float:
	if plan.heights.is_empty():
		return 0.0
	var point_w := plan.height_point_width
	var point_h := plan.height_point_height
	var h00 := _height_at_point(cell.x, cell.y, plan.heights, point_w, point_h)
	var h10 := _height_at_point(cell.x + 1, cell.y, plan.heights, point_w, point_h)
	var h01 := _height_at_point(cell.x, cell.y + 1, plan.heights, point_w, point_h)
	var dhdx := h10 - h00
	var dhdz := h01 - h00
	return rad_to_deg(atan(sqrt(dhdx * dhdx + dhdz * dhdz) / Constants.TILE_SIZE))


static func valley_floor_score(plan: MapPlan, cell: Vector2i) -> float:
	## 1.0 = flat valley bottom suitable for paths/build; 0.0 = ridge/cliff.
	var slope := slope_degrees(plan, cell)
	if slope >= Constants.MAPGEN_CLIFF_ANGLE_DEG:
		return 0.0
	var norm_h := normalized_height(plan, cell)
	var slope_score := 1.0 - clampf(slope / Constants.MAPGEN_VALLEY_SLOPE_MAX_DEG, 0.0, 1.0)
	var height_score := 1.0 - clampf(norm_h / Constants.MAPGEN_VALLEY_HEIGHT_MAX_NORM, 0.0, 1.0)
	return clampf(slope_score * 0.55 + height_score * 0.45, 0.0, 1.0)


static func ridge_barrier_score(plan: MapPlan, cell: Vector2i) -> float:
	## 1.0 = steep/high ridge that should block expansion visually and for placement.
	var slope := slope_degrees(plan, cell)
	var norm_h := normalized_height(plan, cell)
	var slope_score := clampf(slope / Constants.MAPGEN_CLIFF_ANGLE_DEG, 0.0, 1.0)
	var height_score := clampf((norm_h - 0.45) / 0.55, 0.0, 1.0)
	return clampf(slope_score * 0.65 + height_score * 0.35, 0.0, 1.0)


static func expansion_ring_score(plan: MapPlan, cell: Vector2i, warren_cell: Vector2i) -> float:
	## Peaks around 18–42 tiles from camp — first expansion ring in valleys.
	var dist := float(cell.distance_to(warren_cell))
	if dist < float(Constants.MAPGEN_RESOURCE_MIN_RADIUS):
		return 0.0
	var ideal_min := 14.0
	var ideal_max := 48.0
	if dist < ideal_min:
		return clampf((dist - float(Constants.MAPGEN_RESOURCE_MIN_RADIUS)) / (ideal_min - float(Constants.MAPGEN_RESOURCE_MIN_RADIUS)), 0.0, 1.0)
	if dist <= ideal_max:
		return 1.0
	return clampf(1.0 - (dist - ideal_max) / 40.0, 0.0, 1.0)


static func _height_at_point(
	x: int,
	z: int,
	heights: PackedFloat32Array,
	point_w: int,
	point_h: int,
) -> float:
	var cx := clampi(x, 0, point_w - 1)
	var cz := clampi(z, 0, point_h - 1)
	return heights[cz * point_w + cx]
