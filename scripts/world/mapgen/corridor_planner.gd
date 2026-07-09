class_name CorridorPlanner
extends RefCounted

## Plans a main raid approach lane + secondary footpaths into MapPlan metadata.
## Does not spawn enemies — exposes cells for future threat_scheduler use.

const MAIN_LANE_HALF_WIDTH := 1 ## cells; total width ~3
const PATH_STOP_FROM_WARREN := 8 ## tiles; leave camp core clear of raid lane
const SECONDARY_HALF_WIDTH := 0 ## cells; single-tile muddy arms


static func plan(plan: MapPlan, config: MapConfig, authoring: MapAuthoringData, rng: MapRng) -> void:
	plan.main_raid_path_cells.clear()
	plan.approach_corridor_cells.clear()
	plan.resource_pocket_cells.clear()

	var camp_center := _camp_center(plan, config)
	var entry := _pick_edge_entry(plan, camp_center, rng)
	var raid_end := _point_toward(entry, camp_center, PATH_STOP_FROM_WARREN)
	var main_path := _bresenham_jitter(entry, raid_end, rng, 0.22)
	_paint_lane(plan.main_raid_path_cells, main_path, MAIN_LANE_HALF_WIDTH, plan)
	_paint_lane(plan.approach_corridor_cells, main_path, MAIN_LANE_HALF_WIDTH + 1, plan)

	var pocket_targets := _resource_pocket_targets(authoring, camp_center)
	for target in pocket_targets:
		var arm := _bresenham_jitter(camp_center, target, rng, 0.18)
		_paint_lane(plan.approach_corridor_cells, arm, SECONDARY_HALF_WIDTH, plan)
		plan.resource_pocket_cells[target] = true

	_apply_corridor_terrain(plan)
	plan.scatter_stats["main_raid_path_cells"] = plan.main_raid_path_cells.size()
	plan.scatter_stats["approach_corridor_cells"] = plan.approach_corridor_cells.size()
	plan.scatter_stats["resource_pocket_count"] = plan.resource_pocket_cells.size()


static func is_main_raid_cell(plan: MapPlan, cell: Vector2i) -> bool:
	return plan.main_raid_path_cells.has(cell)


static func is_approach_cell(plan: MapPlan, cell: Vector2i) -> bool:
	return plan.approach_corridor_cells.has(cell) or plan.main_raid_path_cells.has(cell)


static func _camp_center(plan: MapPlan, config: MapConfig) -> Vector2i:
	return plan.warren_cell + Vector2i(config.warren_footprint.x / 2, config.warren_footprint.y / 2)


static func _pick_edge_entry(plan: MapPlan, camp_center: Vector2i, rng: MapRng) -> Vector2i:
	## Prefer east edge for seed-stable raid readability; jitter along that edge.
	var inset := 2
	var edge_choice := rng.randi_range(0, 3)
	match edge_choice:
		0:
			return Vector2i(
				plan.width - 1 - inset,
				clampi(camp_center.y + rng.randi_range(-40, 40), inset, plan.height - 1 - inset),
			)
		1:
			return Vector2i(
				clampi(camp_center.x + rng.randi_range(-40, 40), inset, plan.width - 1 - inset),
				plan.height - 1 - inset,
			)
		2:
			return Vector2i(
				inset,
				clampi(camp_center.y + rng.randi_range(-40, 40), inset, plan.height - 1 - inset),
			)
		_:
			return Vector2i(
				clampi(camp_center.x + rng.randi_range(-40, 40), inset, plan.width - 1 - inset),
				inset,
			)


static func _point_toward(from_cell: Vector2i, to_cell: Vector2i, stop_distance: int) -> Vector2i:
	var delta := Vector2(to_cell - from_cell)
	var dist := delta.length()
	if dist <= float(stop_distance) or dist < 0.001:
		return from_cell
	var t := (dist - float(stop_distance)) / dist
	return Vector2i(
		int(round(float(from_cell.x) + delta.x * t)),
		int(round(float(from_cell.y) + delta.y * t)),
	)


static func _resource_pocket_targets(authoring: MapAuthoringData, camp_center: Vector2i) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []
	var wanted := {"wood": false, "food": false, "stone": false}
	for stamp in authoring.resource_stamps:
		var tag := str(stamp.get("tag", "")).to_lower()
		var center: Vector2i = stamp.get("center", Vector2i.ZERO)
		if tag == "wood" and not wanted["wood"]:
			targets.append(center)
			wanted["wood"] = true
		elif (tag == "food" or tag == "mushroom") and not wanted["food"]:
			targets.append(center)
			wanted["food"] = true
		elif (tag == "stone" or tag == "rock") and not wanted["stone"]:
			targets.append(center)
			wanted["stone"] = true
	if targets.is_empty():
		targets.append(camp_center + Vector2i(-18, 14))
		targets.append(camp_center + Vector2i(20, -12))
		targets.append(camp_center + Vector2i(16, 18))
	return targets


static func _bresenham_jitter(
	from_cell: Vector2i,
	to_cell: Vector2i,
	rng: MapRng,
	jitter_chance: float,
) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var x0 := from_cell.x
	var y0 := from_cell.y
	var x1 := to_cell.x
	var y1 := to_cell.y
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	var guard := 0
	while guard < 2048:
		guard += 1
		var cell := Vector2i(x0, y0)
		if rng.roll(jitter_chance):
			cell += Vector2i(rng.randi_range(-1, 1), rng.randi_range(-1, 1))
		path.append(cell)
		if x0 == x1 and y0 == y1:
			break
		var e2 := err * 2
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy
	return path


static func _paint_lane(
	dest: Dictionary,
	path: Array[Vector2i],
	half_width: int,
	plan: MapPlan,
) -> void:
	for cell in path:
		for dz in range(-half_width, half_width + 1):
			for dx in range(-half_width, half_width + 1):
				var painted := cell + Vector2i(dx, dz)
				if painted.x < 0 or painted.y < 0 or painted.x >= plan.width or painted.y >= plan.height:
					continue
				dest[painted] = true


static func _apply_corridor_terrain(plan: MapPlan) -> void:
	for cell in plan.approach_corridor_cells.keys():
		var c: Vector2i = cell
		var terrain: Defs.TerrainClass = plan.tile_classes[c.y][c.x]
		if terrain == Defs.TerrainClass.CLIFF or terrain == Defs.TerrainClass.WARREN_GROUND:
			continue
		plan.tile_classes[c.y][c.x] = Defs.TerrainClass.MUD_CLEARING
	for cell in plan.main_raid_path_cells.keys():
		var c2: Vector2i = cell
		if plan.tile_classes[c2.y][c2.x] == Defs.TerrainClass.CLIFF:
			continue
		plan.tile_classes[c2.y][c2.x] = Defs.TerrainClass.MUD_CLEARING
