class_name MapValidator
extends RefCounted

## Debug validation for generated MapPlan — gameplay reachability and camp sanity.

const _TerrainClassifier := preload("res://scripts/world/mapgen/terrain_classifier.gd")

const MIN_BUILDABLE_NEAR_WARREN := 120
const MIN_TREE_REQUESTED := 120
const MIN_ROCK_REQUESTED := 20
const MIN_FOOD_RESOURCES := 1
const MIN_WOOD_RESOURCES := 20
const MIN_STONE_RESOURCES := 2
const MIN_DRESSING_COUNT := 40
const CAMP_BUILDABLE_RADIUS := 12


static func validate(plan: MapPlan, config: MapConfig) -> Dictionary:
	var failures: PackedStringArray = PackedStringArray()
	if plan == null:
		return {"pass": false, "failures": ["map_plan is null"]}

	if plan.warren_cell.x < 0 or plan.warren_cell.y < 0:
		failures.append("warren cell missing")

	if config.authoring_data == null and not bool(plan.scatter_stats.get("authoring_loaded", false)):
		failures.append("authoring data missing")

	var buildable_near := _count_buildable_in_radius(plan, plan.warren_cell, CAMP_BUILDABLE_RADIUS)
	if buildable_near < MIN_BUILDABLE_NEAR_WARREN:
		failures.append(
			"buildable near warren=%d (need >= %d)" % [buildable_near, MIN_BUILDABLE_NEAR_WARREN]
		)

	var walkable_camp := _count_walkable_in_radius(plan, plan.warren_cell, CAMP_BUILDABLE_RADIUS)
	var camp_cells := maxi(1, (CAMP_BUILDABLE_RADIUS * 2 + 1) * (CAMP_BUILDABLE_RADIUS * 2 + 1))
	var walkable_pct := float(walkable_camp) / float(camp_cells)
	if walkable_pct < 0.8:
		failures.append("camp walkable %.0f%% (need >= 80%%)" % [walkable_pct * 100.0])

	var blockers := _blockers_from_placements(plan)
	var reachable := _flood_reachable(plan, plan.warren_cell, blockers)
	var resource_counts := _count_resources(plan, reachable)

	if resource_counts.wood < MIN_WOOD_RESOURCES:
		failures.append("reachable wood=%d (need >= %d)" % [resource_counts.wood, MIN_WOOD_RESOURCES])
	if resource_counts.stone < MIN_STONE_RESOURCES:
		failures.append("reachable stone=%d (need >= %d)" % [resource_counts.stone, MIN_STONE_RESOURCES])
	if resource_counts.food < MIN_FOOD_RESOURCES:
		failures.append("reachable food=%d (need >= %d)" % [resource_counts.food, MIN_FOOD_RESOURCES])

	if not _warren_reaches_map_edge(plan, reachable):
		failures.append("warren has no reachable path to map edge")

	var stats: Dictionary = plan.scatter_stats
	var trees := int(stats.get("tree_count", stats.get("tree_requested", 0)))
	if trees < MIN_TREE_REQUESTED:
		failures.append("tree placements=%d (need >= %d)" % [trees, MIN_TREE_REQUESTED])

	var dressing := int(stats.get("dressing_count", 0))
	if dressing < MIN_DRESSING_COUNT:
		failures.append("dressing props=%d (need >= %d)" % [dressing, MIN_DRESSING_COUNT])

	var rocks := _count_path_keyword(plan, "rock")
	if rocks < MIN_ROCK_REQUESTED:
		failures.append("rock placements=%d (need >= %d)" % [rocks, MIN_ROCK_REQUESTED])

	if plan.main_raid_path_cells.size() < 20:
		failures.append(
			"main raid path cells=%d (need >= 20)" % plan.main_raid_path_cells.size()
		)

	return {
		"pass": failures.is_empty(),
		"failures": failures,
		"buildable_near_warren": buildable_near,
		"walkable_camp_pct": walkable_pct,
		"resource_counts": resource_counts,
		"tree_count": trees,
		"tree_requested": trees,
		"dressing_count": dressing,
		"blocking_prop_count": int(stats.get("blocking_prop_count", 0)),
		"resource_node_count": int(stats.get("resource_node_count", 0)),
		"forest_stamp_count": int(stats.get("forest_stamp_count", 0)),
		"clearing_stamp_count": int(stats.get("clearing_stamp_count", 0)),
		"main_raid_path_cells": plan.main_raid_path_cells.size(),
		"approach_corridor_cells": plan.approach_corridor_cells.size(),
		"macro_texture_mode": _macro_textures_present(),
		"rock_requested": rocks,
		"seed": config.seed,
		"map_size": "%dx%d" % [plan.width, plan.height],
	}


static func format_report(result: Dictionary) -> String:
	var failures: Array = result.get("failures", [])
	var resource_counts: Dictionary = result.get("resource_counts", {})
	var failure_lines: PackedStringArray = PackedStringArray()
	for failure in failures:
		failure_lines.append(str(failure))
	var walkable_pct_display := (
		str(int(round(float(result.get("walkable_camp_pct", 0.0)) * 100.0))) + "%"
	)
	return (
		(
			"map_validation pass=%s seed=%s size=%s macro=%s buildable_near_warren=%d walkable_camp=%s "
			+ "resources=%s trees=%d dressing=%d blocking=%d resource_nodes=%d "
			+ "raid_lane=%d approach=%d forest_stamps=%d clearing_stamps=%d rocks=%d failures=[%s]"
		)
		% [
			str(result.get("pass", false)),
			str(result.get("seed", "?")),
			str(result.get("map_size", "?")),
			str(result.get("macro_texture_mode", false)),
			int(result.get("buildable_near_warren", 0)),
			walkable_pct_display,
			str(resource_counts),
			int(result.get("tree_count", 0)),
			int(result.get("dressing_count", 0)),
			int(result.get("blocking_prop_count", 0)),
			int(result.get("resource_node_count", 0)),
			int(result.get("main_raid_path_cells", 0)),
			int(result.get("approach_corridor_cells", 0)),
			int(result.get("forest_stamp_count", 0)),
			int(result.get("clearing_stamp_count", 0)),
			int(result.get("rock_requested", 0)),
			", ".join(failure_lines),
		]
	)


static func _warren_reaches_map_edge(plan: MapPlan, reachable: Dictionary) -> bool:
	for x in range(plan.width):
		if reachable.has(Vector2i(x, 0)) or reachable.has(Vector2i(x, plan.height - 1)):
			return true
	for y in range(plan.height):
		if reachable.has(Vector2i(0, y)) or reachable.has(Vector2i(plan.width - 1, y)):
			return true
	return false


static func _count_buildable_in_radius(plan: MapPlan, center: Vector2i, radius: int) -> int:
	var count := 0
	for y in range(maxi(0, center.y - radius), mini(plan.height, center.y + radius + 1)):
		for x in range(maxi(0, center.x - radius), mini(plan.width, center.x + radius + 1)):
			if _TerrainClassifier.is_buildable(plan.tile_classes[y][x]):
				count += 1
	return count


static func _count_walkable_in_radius(plan: MapPlan, center: Vector2i, radius: int) -> int:
	var count := 0
	for y in range(maxi(0, center.y - radius), mini(plan.height, center.y + radius + 1)):
		for x in range(maxi(0, center.x - radius), mini(plan.width, center.x + radius + 1)):
			if _TerrainClassifier.is_walkable(plan.tile_classes[y][x]):
				count += 1
	return count


static func _blockers_from_placements(plan: MapPlan) -> Dictionary:
	var blockers: Dictionary = {}
	for entry in plan.prop_placements:
		if entry == null or not entry.blocks_movement:
			continue
		blockers[entry.grid_cell] = true
	return blockers


static func _flood_reachable(plan: MapPlan, from_cell: Vector2i, blockers: Dictionary) -> Dictionary:
	var seen: Dictionary = {}
	var queue: Array[Vector2i] = [from_cell]
	var head := 0
	seen[from_cell] = true
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while head < queue.size():
		var cell: Vector2i = queue[head]
		head += 1
		for dir in dirs:
			var next := cell + dir
			if next.x < 0 or next.y < 0 or next.x >= plan.width or next.y >= plan.height:
				continue
			if seen.has(next) or blockers.has(next):
				continue
			if not _TerrainClassifier.is_walkable(plan.tile_classes[next.y][next.x]):
				continue
			seen[next] = true
			queue.append(next)
	return seen


static func _count_resources(plan: MapPlan, reachable: Dictionary) -> Dictionary:
	var counts := {"wood": 0, "stone": 0, "food": 0, "gold": 0}
	for entry in plan.prop_placements:
		if entry == null or entry.resource_kind < 0:
			continue
		if not _is_resource_reachable(entry, reachable):
			continue
		match entry.resource_kind as Defs.ResourceKind:
			Defs.ResourceKind.WOOD:
				counts["wood"] = int(counts["wood"]) + 1
			Defs.ResourceKind.STONE:
				counts["stone"] = int(counts["stone"]) + 1
			Defs.ResourceKind.FOOD:
				counts["food"] = int(counts["food"]) + 1
			Defs.ResourceKind.GOLD:
				counts["gold"] = int(counts["gold"]) + 1
	return counts


static func _is_resource_reachable(entry, reachable: Dictionary) -> bool:
	if reachable.has(entry.grid_cell):
		return true
	if not entry.blocks_movement:
		return false
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for dir in dirs:
		if reachable.has(entry.grid_cell + dir):
			return true
	return false


static func _macro_textures_present() -> bool:
	return TerrainPalette.all_macro_textures_present()


static func _count_path_keyword(plan: MapPlan, keyword: String) -> int:
	var count := 0
	for entry in plan.prop_placements:
		if entry == null or entry.resource_kind >= 0:
			continue
		if keyword in entry.scene_path.to_lower():
			count += 1
	return count
