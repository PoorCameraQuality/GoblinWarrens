extends RefCounted

## Bake-time resource + tree scatter from authored semantic layers (Phase 6).
##
## STABILITY NOTE: single compile() entry for headless smoke reliability.

const NO_SCATTER_THRESHOLD := 250
const COLOR_MATCH_TOLERANCE := 0.02
const CLUSTER_NODES_MIN := 2
const CLUSTER_NODES_MAX := 3
const CLUSTER_MIN_SPACING := 10 ## Manhattan distance between cluster anchor cells
const TREE_MIN_SPACING := 2
const TREE_STRIDE := 3
const TREE_DENSITY_ROLL := 0.05
const MAX_TREE_BUDGET := 500
const BORDER_DEPTH := 7
const MAX_BORDER_TREE_BUDGET := 350
const BORDER_PLACEMENT_ROLL := 0.78
const _PropPlacement := preload("res://scripts/world/mapgen/prop_placement.gd")
const _VisualCatalog := preload("res://scripts/art/visual_catalog.gd")


static func compile(map_root: String, target_size: Vector2i = Vector2i(Constants.GRID_WIDTH, Constants.GRID_HEIGHT)) -> Variant:
	var Factory = load("res://scripts/world/map/map_definition_factory.gd")
	var Compiler = load("res://scripts/world/map/grid_compiler.gd")
	var definition = Factory.load_from_map_root(map_root, target_size)
	if definition == null:
		return null
	var grid = Compiler.compile_map(map_root, target_size)
	if grid == null:
		return null
	return compile_from_definition(definition, grid)


static func compile_from_definition(definition, grid) -> Variant:
	if definition == null or grid == null:
		return null

	var affinity_path: String = definition.get_layer_path("resource_affinity")
	var scatter_path: String = definition.get_layer_path("no_scatter")
	if affinity_path.is_empty() or scatter_path.is_empty():
		push_error("ResourceScatterCompiler: missing resource_affinity or no_scatter layer")
		return null

	var affinity_img := Image.load_from_file(ProjectSettings.globalize_path(affinity_path))
	var scatter_img := Image.load_from_file(ProjectSettings.globalize_path(scatter_path))
	if affinity_img == null or scatter_img == null:
		return null
	affinity_img.convert(Image.FORMAT_RGBA8)
	scatter_img.convert(Image.FORMAT_RGBA8)

	var manifest_path: String = definition.map_root.path_join("manifest.json")
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	var palette: Dictionary = manifest.get("resource_palette", {})
	var rules: Dictionary = manifest.get("gameplay_rules", {})
	var cluster_min: int = int(rules.get("resource_cluster_nodes_min", CLUSTER_NODES_MIN))
	var cluster_max: int = int(rules.get("resource_cluster_nodes_max", CLUSTER_NODES_MAX))
	cluster_min = maxi(1, cluster_min)
	cluster_max = maxi(cluster_min, cluster_max)

	var compiled = load("res://scripts/world/map/compiled_resource_map.gd").new()
	compiled.map_id = str(definition.map_id)
	compiled.width = grid.width
	compiled.height = grid.height

	var blockers: Dictionary = {}
	var category_cells: Dictionary = {"resource": {}, "tree": {}}
	var stats := {
		"resource_node_count": 0,
		"tree_count": 0,
		"resource_by_kind": {"gold": 0, "stone": 0, "food": 0, "wood": 0},
		"resource_cluster_count": 0,
		"border_prop_count": 0,
		"skipped_no_scatter": 0,
		"skipped_not_walkable": 0,
		"skipped_spacing": 0,
		"authored": true,
	}

	var seed_resource: int = int(definition.seed_resource)
	var seed_harvestable: int = int(definition.seed_harvestable)

	var clusters := _collect_resource_clusters(affinity_img, palette, grid)
	for cluster in clusters:
		var tag: String = cluster["tag"]
		var cells: Array = cluster["cells"]
		if cells.is_empty():
			continue
		var kind := _kind_for_tag(tag)
		if kind < 0:
			continue
		var anchor: Vector2i = _cluster_anchor(cells)
		if not _spacing_ok(category_cells, "resource", anchor, CLUSTER_MIN_SPACING):
			stats["skipped_spacing"] = int(stats["skipped_spacing"]) + 1
			continue
		var node_count := _nodes_for_cluster(cells.size(), cluster_min, cluster_max)
		var picked: Array = _pick_cluster_cells(cells, node_count, seed_resource, anchor)
		stats["resource_cluster_count"] = int(stats["resource_cluster_count"]) + 1
		for cell_variant in picked:
			var cell: Vector2i = cell_variant
			if blockers.has(cell):
				continue
			var placement = _make_resource_placement(
				definition, grid, cell, tag, kind, seed_resource
			)
			if placement == null:
				continue
			compiled.placements.append(placement)
			blockers[cell] = true
			category_cells["resource"][cell] = true
			stats["resource_node_count"] = int(stats["resource_node_count"]) + 1
			_bump_kind(stats, kind)

	var tree_paths: Array[String] = [
		_VisualCatalog.ENV_TREE,
		_VisualCatalog.ENV_TREE_PINE,
		_VisualCatalog.ENV_TREE_PINE_ALT,
	]
	for y in range(0, grid.height, TREE_STRIDE):
		for x in range(0, grid.width, TREE_STRIDE):
			if int(stats["tree_count"]) >= MAX_TREE_BUDGET:
				break
			var cell := Vector2i(x, y)
			if blockers.has(cell):
				continue
			if not _cell_allows_scatter(grid, scatter_img, cell, stats):
				continue
			var tag := _resource_tag_at(affinity_img, palette, cell)
			if not tag.is_empty() and tag != "none":
				continue
			var terrain_class: int = grid.terrain_class_at(cell)
			if terrain_class not in [Defs.TerrainClass.MOSS, Defs.TerrainClass.FOREST_FLOOR, Defs.TerrainClass.MUD_MOSSY]:
				continue
			if not _hash_roll(cell, seed_harvestable, TREE_DENSITY_ROLL):
				continue
			if not _spacing_ok(category_cells, "tree", cell, TREE_MIN_SPACING):
				stats["skipped_spacing"] = int(stats["skipped_spacing"]) + 1
				continue
			var tree_path: String = tree_paths[_hash_index(cell, seed_harvestable, tree_paths.size())]
			var tree = _make_tree_placement(definition, grid, cell, tree_path, seed_harvestable, terrain_class)
			if tree == null:
				continue
			compiled.placements.append(tree)
			blockers[cell] = true
			category_cells["tree"][cell] = true
			stats["tree_count"] = int(stats["tree_count"]) + 1
			stats["resource_by_kind"]["wood"] = int(stats["resource_by_kind"]["wood"]) + 1

	if bool(rules.get("edge_forest_enabled", true)):
		_scatter_authored_border_ring(
			definition,
			grid,
			scatter_img,
			compiled,
			blockers,
			category_cells,
			stats,
			seed_harvestable,
			tree_paths,
		)

	compiled.stats = stats
	return compiled


static func _collect_resource_clusters(
	affinity_img: Image,
	palette: Dictionary,
	grid,
) -> Array:
	var visited: Dictionary = {}
	var clusters: Array = []
	for y in range(grid.height):
		for x in range(grid.width):
			var start := Vector2i(x, y)
			var key := _cell_key(start)
			if visited.has(key):
				continue
			var tag := _resource_tag_at(affinity_img, palette, start)
			if tag.is_empty() or tag == "none":
				continue
			if not grid.is_walkable_cell(start):
				continue
			var cells: Array = _flood_fill_cluster(affinity_img, palette, grid, start, tag, visited)
			if not cells.is_empty():
				clusters.append({"tag": tag, "cells": cells})
	return clusters


static func _flood_fill_cluster(
	affinity_img: Image,
	palette: Dictionary,
	grid,
	start: Vector2i,
	tag: String,
	visited: Dictionary,
) -> Array:
	var cells: Array = []
	var queue: Array[Vector2i] = [start]
	visited[_cell_key(start)] = true
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		cells.append(cell)
		for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var next: Vector2i = cell + offset
			if not grid.is_in_bounds(next):
				continue
			var next_key := _cell_key(next)
			if visited.has(next_key):
				continue
			if _resource_tag_at(affinity_img, palette, next) != tag:
				continue
			if not grid.is_walkable_cell(next):
				continue
			visited[next_key] = true
			queue.append(next)
	return cells


static func _cluster_anchor(cells: Array) -> Vector2i:
	var sum := Vector2.ZERO
	for cell_variant in cells:
		var cell: Vector2i = cell_variant
		sum += Vector2(cell)
	sum /= float(cells.size())
	var best: Vector2i = cells[0]
	var best_dist := INF
	for cell_variant in cells:
		var cell: Vector2i = cell_variant
		var dist := sum.distance_squared_to(Vector2(cell))
		if dist < best_dist:
			best_dist = dist
			best = cell
	return best


static func _nodes_for_cluster(cell_count: int, cluster_min: int, cluster_max: int) -> int:
	if cell_count <= 1:
		return 1
	if cell_count <= 4:
		return mini(cluster_max, maxi(cluster_min, 2))
	return cluster_max


static func _pick_cluster_cells(
	cells: Array,
	count: int,
	seed: int,
	anchor: Vector2i,
) -> Array:
	if cells.size() <= count:
		return cells.duplicate()
	var picked: Array = [anchor]
	var remaining: Array = []
	for cell_variant in cells:
		var cell: Vector2i = cell_variant
		if cell != anchor:
			remaining.append(cell)
	while picked.size() < count and not remaining.is_empty():
		var best_idx := 0
		var best_score := -1.0
		for i in range(remaining.size()):
			var candidate: Vector2i = remaining[i]
			var min_sep := INF
			for existing_variant in picked:
				var existing: Vector2i = existing_variant
				var sep := absi(existing.x - candidate.x) + absi(existing.y - candidate.y)
				min_sep = minf(min_sep, float(sep))
			var score := min_sep + _hash01(candidate.x, candidate.y, seed + picked.size()) * 0.25
			if score > best_score:
				best_score = score
				best_idx = i
		picked.append(remaining[best_idx])
		remaining.remove_at(best_idx)
	return picked


static func _scatter_authored_border_ring(
	definition,
	grid,
	scatter_img: Image,
	compiled,
	blockers: Dictionary,
	category_cells: Dictionary,
	stats: Dictionary,
	seed: int,
	tree_paths: Array[String],
) -> void:
	for y in range(0, grid.height, TREE_STRIDE):
		for x in range(0, grid.width, TREE_STRIDE):
			if int(stats["border_prop_count"]) >= MAX_BORDER_TREE_BUDGET:
				return
			if int(stats["tree_count"]) >= MAX_TREE_BUDGET:
				return
			var cell := Vector2i(x, y)
			if not _is_in_border_ring(cell, grid.width, grid.height, BORDER_DEPTH):
				continue
			if blockers.has(cell):
				continue
			if not _cell_allows_scatter(grid, scatter_img, cell, stats):
				continue
			if not _hash_roll(cell, seed + 4049, BORDER_PLACEMENT_ROLL):
				continue
			if not _spacing_ok(category_cells, "tree", cell, TREE_MIN_SPACING):
				continue
			var tree_path: String = tree_paths[_hash_index(cell, seed + 8081, tree_paths.size())]
			var tree = _make_tree_placement(
				definition,
				grid,
				cell,
				tree_path,
				seed + 1213,
				grid.terrain_class_at(cell),
			)
			if tree == null:
				continue
			compiled.placements.append(tree)
			blockers[cell] = true
			category_cells["tree"][cell] = true
			stats["tree_count"] = int(stats["tree_count"]) + 1
			stats["border_prop_count"] = int(stats["border_prop_count"]) + 1
			stats["resource_by_kind"]["wood"] = int(stats["resource_by_kind"]["wood"]) + 1


static func _is_in_border_ring(cell: Vector2i, map_width: int, map_height: int, depth: int) -> bool:
	var left := float(cell.x)
	var top := float(cell.y)
	var right := float(map_width - 1 - cell.x)
	var bottom := float(map_height - 1 - cell.y)
	return minf(minf(left, right), minf(top, bottom)) <= float(depth)


static func _cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


static func _cell_allows_scatter(grid, scatter_img: Image, cell: Vector2i, stats: Dictionary) -> bool:
	if not grid.is_walkable_cell(cell):
		stats["skipped_not_walkable"] = int(stats["skipped_not_walkable"]) + 1
		return false
	if scatter_img.get_pixel(cell.x, cell.y).r8 >= NO_SCATTER_THRESHOLD:
		stats["skipped_no_scatter"] = int(stats["skipped_no_scatter"]) + 1
		return false
	return true


static func _resource_tag_at(affinity_img: Image, palette: Dictionary, cell: Vector2i) -> String:
	var pixel := affinity_img.get_pixel(cell.x, cell.y)
	for hex: String in palette.keys():
		var color := Color.from_string(hex, Color.MAGENTA)
		if _colors_match(pixel, color):
			return str(palette[hex])
	return ""


static func _colors_match(a: Color, b: Color) -> bool:
	return (
		absf(a.r - b.r) <= COLOR_MATCH_TOLERANCE
		and absf(a.g - b.g) <= COLOR_MATCH_TOLERANCE
		and absf(a.b - b.b) <= COLOR_MATCH_TOLERANCE
	)


static func _kind_for_tag(tag: String) -> int:
	match tag:
		"gold":
			return Defs.ResourceKind.GOLD
		"stone":
			return Defs.ResourceKind.STONE
		"food":
			return Defs.ResourceKind.FOOD
		_:
			return -1


static func _amount_for_kind(kind: int) -> int:
	match kind:
		Defs.ResourceKind.GOLD:
			return 200
		Defs.ResourceKind.FOOD:
			return 80
		_:
			return Constants.BUILDING_RESOURCE_AMOUNT


static func _spacing_ok(category_cells: Dictionary, category: String, cell: Vector2i, min_spacing: int) -> bool:
	var cells: Dictionary = category_cells.get(category, {})
	for other in cells.keys():
		var other_cell: Vector2i = other
		if absi(other_cell.x - cell.x) + absi(other_cell.y - cell.y) < min_spacing:
			return false
	return true


static func _make_resource_placement(definition, grid, cell: Vector2i, tag: String, kind: int, seed: int):
	var path: String = _VisualCatalog.resource_wrapper(kind)
	var placement := _PropPlacement.new()
	placement.placement_id = "%s/res/%s/%d_%d" % [definition.map_id, tag, cell.x, cell.y]
	placement.scene_path = path
	placement.grid_cell = cell
	placement.blocks_movement = true
	placement.resource_kind = kind
	placement.resource_amount = _amount_for_kind(kind)
	placement.terrain_class = grid.terrain_class_at(cell)
	placement.rotation_y = _hash01(cell.x, cell.y, seed) * TAU
	var jitter := Vector2(
		_hash01(cell.x + 17, cell.y, seed) * 0.7 - 0.35,
		_hash01(cell.x, cell.y + 23, seed) * 0.7 - 0.35,
	)
	var height: float = grid.sample_height_at_cell(cell)
	placement.world_pos = Vector3(
		(cell.x + 0.5 + jitter.x) * Constants.TILE_SIZE,
		height,
		(cell.y + 0.5 + jitter.y) * Constants.TILE_SIZE,
	)
	var scale_factor := 0.82 + 0.36 * _hash01(cell.x + 5, cell.y + 7, seed)
	if _VisualCatalog.is_tree_path(path):
		placement.scale = _VisualCatalog.env_visual_scale(path) * Vector3.ONE * scale_factor
	else:
		placement.scale = _VisualCatalog.resource_visual_scale(path) * Vector3.ONE * scale_factor
	return placement


static func _make_tree_placement(
	definition,
	grid,
	cell: Vector2i,
	tree_path: String,
	seed: int,
	terrain_class: int,
):
	var placement := _PropPlacement.new()
	placement.placement_id = "%s/tree/%d_%d" % [definition.map_id, cell.x, cell.y]
	placement.scene_path = tree_path
	placement.grid_cell = cell
	placement.blocks_movement = true
	placement.resource_kind = Defs.ResourceKind.WOOD
	placement.resource_amount = Constants.BUILDING_RESOURCE_AMOUNT
	placement.terrain_class = terrain_class
	placement.rotation_y = _hash01(cell.x, cell.y, seed + 991) * TAU
	var jitter := Vector2(
		_hash01(cell.x + 3, cell.y + 11, seed) * 0.6 - 0.3,
		_hash01(cell.x + 13, cell.y + 2, seed) * 0.6 - 0.3,
	)
	var height: float = grid.sample_height_at_cell(cell)
	placement.world_pos = Vector3(
		(cell.x + 0.5 + jitter.x) * Constants.TILE_SIZE,
		height,
		(cell.y + 0.5 + jitter.y) * Constants.TILE_SIZE,
	)
	var scale_factor := 0.88 + 0.34 * _hash01(cell.x + 9, cell.y + 4, seed)
	placement.scale = _VisualCatalog.env_visual_scale(tree_path) * Vector3.ONE * scale_factor
	return placement


static func _bump_kind(stats: Dictionary, kind: int) -> void:
	var by_kind: Dictionary = stats["resource_by_kind"]
	match kind:
		Defs.ResourceKind.GOLD:
			by_kind["gold"] = int(by_kind.get("gold", 0)) + 1
		Defs.ResourceKind.STONE:
			by_kind["stone"] = int(by_kind.get("stone", 0)) + 1
		Defs.ResourceKind.FOOD:
			by_kind["food"] = int(by_kind.get("food", 0)) + 1
		_:
			pass


static func _hash01(x: int, y: int, seed: int) -> float:
	var n := seed * 374761393 + x * 668265263 + y * 2147483647
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	return float(n & 0x7fffffff) / 2147483647.0


static func _hash_roll(cell: Vector2i, seed: int, threshold: float) -> bool:
	return _hash01(cell.x, cell.y, seed) <= threshold


static func _hash_index(cell: Vector2i, seed: int, count: int) -> int:
	if count <= 0:
		return 0
	return int(_hash01(cell.x + 101, cell.y + 303, seed) * float(count)) % count
