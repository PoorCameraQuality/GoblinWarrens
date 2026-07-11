class_name WarrenPlacementController
extends RefCounted

## Validates and scores Warren placement on authored baked maps (Phase 7).
## Colony integration deferred — used by dev spike + headless gate.

enum StartZoneKind {
	NEUTRAL = 0,
	ALLOWED = 1,
	FORBIDDEN = 2,
}

enum SuitabilityLabel {
	POOR = 0,
	ACCEPTABLE = 1,
	GOOD = 2,
	RICH = 3,
	DANGEROUS = 4,
	DEFENSIBLE = 5,
	EXPOSED = 6,
}

const MIN_BORDER_CELLS := 8
const MAX_FOOTPRINT_HEIGHT_DELTA_M := 0.45
const RESOURCE_SCAN_RADIUS := 28
const BUILDABLE_SCAN_RADIUS := 12
const MIN_BUILDABLE_NEAR := 80
const MIN_WALKABLE_EXITS := 2
const ROAD_BLOCK_THRESHOLD := 128
const ENEMY_ZONE_THRESHOLD := 128
const RAID_ENTRY_THRESHOLD := 128

const _LABEL_NAMES := {
	SuitabilityLabel.POOR: "Poor",
	SuitabilityLabel.ACCEPTABLE: "Acceptable",
	SuitabilityLabel.GOOD: "Good",
	SuitabilityLabel.RICH: "Rich",
	SuitabilityLabel.DANGEROUS: "Dangerous",
	SuitabilityLabel.DEFENSIBLE: "Defensible",
	SuitabilityLabel.EXPOSED: "Exposed",
}


static func load_context(map_root: String, target_size: Vector2i = Vector2i(Constants.GRID_WIDTH, Constants.GRID_HEIGHT)) -> Dictionary:
	var Factory = load("res://scripts/world/map/map_definition_factory.gd")
	var GridCompiler = load("res://scripts/world/map/grid_compiler.gd")
	var ResourceCompiler = load("res://scripts/world/map/resource_scatter_compiler.gd")
	var definition = Factory.load_from_map_root(map_root, target_size)
	if definition == null:
		return {}
	var grid = GridCompiler.compile_map(map_root, target_size)
	if grid == null:
		return {}
	var resources = ResourceCompiler.compile(map_root, target_size)
	var start_img := _load_layer(definition.get_layer_path("start_zone"))
	var road_img := _load_layer(definition.get_layer_path("road_clearance"))
	var enemy_img := _load_layer(definition.get_layer_path("enemy_camp_zone"))
	var raid_img := _load_layer(definition.get_layer_path("raid_entry"))
	var manifest: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(map_root.path_join("manifest.json"))
	)
	return {
		"definition": definition,
		"grid": grid,
		"resources": resources,
		"start_zone": start_img,
		"road_clearance": road_img,
		"enemy_camp_zone": enemy_img,
		"raid_entry": raid_img,
		"gameplay_rules": manifest.get("gameplay_rules", {}),
		"map_root": map_root,
	}


static func evaluate(context: Dictionary, origin: Vector2i, footprint: Vector2i = Vector2i(2, 2)) -> Dictionary:
	var grid = context.get("grid")
	if grid == null:
		return _result(origin, false, 0, SuitabilityLabel.POOR, ["missing_grid"])

	var reasons: PackedStringArray = PackedStringArray()
	var tags: PackedStringArray = PackedStringArray()
	var width: int = grid.width
	var height: int = grid.height

	if not _footprint_in_bounds(origin, footprint, width, height):
		return _result(origin, false, 0, SuitabilityLabel.POOR, ["out_of_bounds"])

	var border: int = _border_distance(origin, footprint, width, height)
	if border < MIN_BORDER_CELLS:
		reasons.append("too_close_to_border=%d" % border)

	var zone: int = _start_zone_at(context, origin, footprint)
	if zone == StartZoneKind.FORBIDDEN:
		reasons.append("start_zone_forbidden")
	elif zone == StartZoneKind.ALLOWED:
		tags.append("allowed_zone")

	if _footprint_on_road(context, origin, footprint):
		reasons.append("on_protected_road")

	if _footprint_on_mask(context, "enemy_camp_zone", origin, footprint, ENEMY_ZONE_THRESHOLD):
		reasons.append("enemy_camp_overlap")
		tags.append("dangerous")

	if _footprint_on_mask(context, "raid_entry", origin, footprint, RAID_ENTRY_THRESHOLD):
		reasons.append("raid_entry_overlap")
		tags.append("exposed")

	if not _footprint_walkable_buildable(grid, origin, footprint, reasons):
		pass

	var height_delta: float = _footprint_height_delta(grid, origin, footprint)
	if height_delta > MAX_FOOTPRINT_HEIGHT_DELTA_M:
		reasons.append("slope_too_steep=%.2f" % height_delta)

	var exits: int = _count_walkable_exits(grid, origin, footprint)
	if exits < MIN_WALKABLE_EXITS:
		reasons.append("walkable_exits=%d" % exits)

	var buildable_near: int = _count_buildable_in_radius(grid, origin, footprint, BUILDABLE_SCAN_RADIUS)
	if buildable_near < MIN_BUILDABLE_NEAR:
		reasons.append("buildable_near=%d" % buildable_near)

	var resource_counts: Dictionary = _count_resources_near(context, origin, footprint, RESOURCE_SCAN_RADIUS)
	var score: int = _score_candidate(
		border,
		buildable_near,
		exits,
		height_delta,
		resource_counts,
		reasons,
	)

	if border >= 20:
		tags.append("defensible")

	if resource_counts.get("food", 0) + resource_counts.get("wood", 0) >= 8:
		tags.append("rich")

	var valid := reasons.is_empty()
	var label: int = _label_for_score(score, valid, tags)
	return {
		"origin": origin,
		"valid": valid,
		"score": score,
		"label": label,
		"label_name": str(_LABEL_NAMES.get(label, "Poor")),
		"tags": tags,
		"reasons": reasons,
		"buildable_near": buildable_near,
		"walkable_exits": exits,
		"height_delta_m": height_delta,
		"border_cells": border,
		"resources_near": resource_counts,
		"start_zone": zone,
	}


static func find_candidates(
	context: Dictionary,
	footprint: Vector2i = Vector2i(2, 2),
	max_results: int = 32,
	stride: int = 2,
) -> Array:
	var grid = context.get("grid")
	if grid == null:
		return []
	var results: Array = []
	for y in range(MIN_BORDER_CELLS, grid.height - MIN_BORDER_CELLS - footprint.y, stride):
		for x in range(MIN_BORDER_CELLS, grid.width - MIN_BORDER_CELLS - footprint.x, stride):
			var origin := Vector2i(x, y)
			var zone: int = _start_zone_at(context, origin, footprint)
			if zone == StartZoneKind.FORBIDDEN:
				continue
			if not _prefers_south_warren(context, origin, footprint, grid.height):
				continue
			var report: Dictionary = evaluate(context, origin, footprint)
			if not bool(report.get("valid", false)):
				continue
			results.append(report)
	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("score", 0)) > int(b.get("score", 0))
	)
	if results.size() > max_results:
		return results.slice(0, max_results)
	return results


static func _result(origin: Vector2i, valid: bool, score: int, label: int, reasons: PackedStringArray) -> Dictionary:
	return {
		"origin": origin,
		"valid": valid,
		"score": score,
		"label": label,
		"label_name": str(_LABEL_NAMES.get(label, "Poor")),
		"tags": PackedStringArray(),
		"reasons": reasons,
		"buildable_near": 0,
		"walkable_exits": 0,
		"height_delta_m": 0.0,
		"border_cells": 0,
		"resources_near": {},
		"start_zone": StartZoneKind.NEUTRAL,
	}


static func _load_layer(path: String) -> Image:
	if path.is_empty():
		return null
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null:
		return null
	image.convert(Image.FORMAT_RGBA8)
	return image


static func _footprint_in_bounds(origin: Vector2i, footprint: Vector2i, width: int, height: int) -> bool:
	return (
		origin.x >= 0
		and origin.y >= 0
		and origin.x + footprint.x <= width
		and origin.y + footprint.y <= height
	)


static func _border_distance(origin: Vector2i, footprint: Vector2i, width: int, height: int) -> int:
	return mini(
		mini(origin.x, origin.y),
		mini(width - (origin.x + footprint.x), height - (origin.y + footprint.y)),
	)


static func _start_zone_at(context: Dictionary, origin: Vector2i, footprint: Vector2i) -> int:
	var image: Image = context.get("start_zone")
	if image == null:
		return StartZoneKind.NEUTRAL
	var allowed := 0
	var forbidden := 0
	var neutral := 0
	for dy in range(footprint.y):
		for dx in range(footprint.x):
			var cell := origin + Vector2i(dx, dy)
			var px := image.get_pixel(cell.x, cell.y)
			if px.g >= 0.75 and px.r <= 0.35:
				allowed += 1
			elif px.r >= 0.75 and px.g <= 0.35:
				forbidden += 1
			else:
				neutral += 1
	if forbidden > 0:
		return StartZoneKind.FORBIDDEN
	if allowed > 0:
		return StartZoneKind.ALLOWED
	return StartZoneKind.NEUTRAL


static func _prefers_south_warren(context: Dictionary, origin: Vector2i, footprint: Vector2i, height: int) -> bool:
	var rules: Dictionary = context.get("gameplay_rules", {})
	if not bool(rules.get("south_warren_buildable", false)):
		return true
	var center_y: float = float(origin.y) + float(footprint.y) * 0.5
	return center_y >= float(height) * 0.45


static func _footprint_on_road(context: Dictionary, origin: Vector2i, footprint: Vector2i) -> bool:
	return _footprint_on_mask(context, "road_clearance", origin, footprint, ROAD_BLOCK_THRESHOLD)


static func _footprint_on_mask(
	context: Dictionary,
	layer_key: String,
	origin: Vector2i,
	footprint: Vector2i,
	threshold: int,
) -> bool:
	var image: Image = context.get(layer_key)
	if image == null:
		return false
	for dy in range(footprint.y):
		for dx in range(footprint.x):
			var cell := origin + Vector2i(dx, dy)
			if image.get_pixel(cell.x, cell.y).r8 >= threshold:
				return true
	return false


static func _footprint_walkable_buildable(
	grid,
	origin: Vector2i,
	footprint: Vector2i,
	reasons: PackedStringArray,
) -> bool:
	var ok := true
	for dy in range(footprint.y):
		for dx in range(footprint.x):
			var cell := origin + Vector2i(dx, dy)
			if not grid.is_walkable_cell(cell):
				reasons.append("blocked_cell@%s" % cell)
				ok = false
			if not grid.is_buildable_cell(cell):
				reasons.append("unbuildable_cell@%s" % cell)
				ok = false
	return ok


static func _footprint_height_delta(grid, origin: Vector2i, footprint: Vector2i) -> float:
	var min_h := INF
	var max_h := -INF
	for dy in range(footprint.y):
		for dx in range(footprint.x):
			var cell := origin + Vector2i(dx, dy)
			var h: float = grid.sample_height_at_cell(cell)
			min_h = minf(min_h, h)
			max_h = maxf(max_h, h)
	if min_h == INF:
		return 0.0
	return max_h - min_h


static func _count_walkable_exits(grid, origin: Vector2i, footprint: Vector2i) -> int:
	var seen: Dictionary = {}
	var exits := 0
	for dy in range(-1, footprint.y + 1):
		for dx in range(-1, footprint.x + 1):
			if dx >= 0 and dx < footprint.x and dy >= 0 and dy < footprint.y:
				continue
			var cell := origin + Vector2i(dx, dy)
			if seen.has(cell):
				continue
			seen[cell] = true
			if grid.is_in_bounds(cell) and grid.is_walkable_cell(cell):
				exits += 1
	return exits


static func _count_buildable_in_radius(
	grid,
	origin: Vector2i,
	footprint: Vector2i,
	radius: int,
) -> int:
	var center := origin + Vector2i(footprint.x / 2, footprint.y / 2)
	var total := 0
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if Vector2i(dx, dy).length() > float(radius):
				continue
			var cell := center + Vector2i(dx, dy)
			if grid.is_in_bounds(cell) and grid.is_buildable_cell(cell):
				total += 1
	return total


static func _count_resources_near(
	context: Dictionary,
	origin: Vector2i,
	footprint: Vector2i,
	radius: int,
) -> Dictionary:
	var counts := {"food": 0, "wood": 0, "stone": 0, "gold": 0}
	var resources = context.get("resources")
	if resources == null:
		return counts
	var center := origin + Vector2i(footprint.x / 2, footprint.y / 2)
	for entry in resources.placements:
		if entry == null or int(entry.resource_kind) < 0:
			continue
		if center.distance_to(entry.grid_cell) > float(radius):
			continue
		match int(entry.resource_kind):
			Defs.ResourceKind.FOOD:
				counts["food"] = int(counts["food"]) + 1
			Defs.ResourceKind.WOOD:
				counts["wood"] = int(counts["wood"]) + 1
			Defs.ResourceKind.STONE:
				counts["stone"] = int(counts["stone"]) + 1
			Defs.ResourceKind.GOLD:
				counts["gold"] = int(counts["gold"]) + 1
	return counts


static func _score_candidate(
	border: int,
	buildable_near: int,
	exits: int,
	height_delta: float,
	resource_counts: Dictionary,
	reasons: PackedStringArray,
) -> int:
	if not reasons.is_empty():
		return maxi(0, 20 - reasons.size() * 5)
	var score := 0
	score += mini(buildable_near, 200) / 4
	score += mini(exits, 8) * 4
	score += mini(border, 30)
	score += mini(int(resource_counts.get("food", 0)), 10) * 2
	score += mini(int(resource_counts.get("wood", 0)), 20)
	score += mini(int(resource_counts.get("stone", 0)), 8) * 2
	score += mini(int(resource_counts.get("gold", 0)), 4) * 3
	if height_delta <= 0.15:
		score += 8
	elif height_delta <= MAX_FOOTPRINT_HEIGHT_DELTA_M:
		score += 4
	return clampi(score, 0, 100)


static func _label_for_score(score: int, valid: bool, tags: PackedStringArray) -> int:
	if not valid:
		return SuitabilityLabel.POOR
	if tags.has("dangerous"):
		return SuitabilityLabel.DANGEROUS
	if tags.has("exposed"):
		return SuitabilityLabel.EXPOSED
	if tags.has("rich") and score >= 55:
		return SuitabilityLabel.RICH
	if tags.has("defensible") and score >= 50:
		return SuitabilityLabel.DEFENSIBLE
	if score >= 70:
		return SuitabilityLabel.GOOD
	if score >= 45:
		return SuitabilityLabel.ACCEPTABLE
	return SuitabilityLabel.POOR
