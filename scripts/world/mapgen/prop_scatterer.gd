class_name PropScatterer
extends RefCounted

const _VisualCatalog := preload("res://scripts/art/visual_catalog.gd")
const _PropPlacement := preload("res://scripts/world/mapgen/prop_placement.gd")
const _TerrainClassifier := preload("res://scripts/world/mapgen/terrain_classifier.gd")
const _MapAuthoringData := preload("res://data/mapgen/map_authoring_data.gd")
const _ValleyTerrain := preload("res://scripts/world/mapgen/valley_terrain.gd")
const _CorridorPlanner := preload("res://scripts/world/mapgen/corridor_planner.gd")

## Authored-mask prop and tree scatter for MapGenerator.

const TREE_MIN_SPACING := 2 ## cells between blocker trees
const ROCK_MIN_SPACING := 2
const BUSH_MIN_SPACING := 1
const BORDER_DEPTH := 7 ## cells of dense edge forest
const MAX_DRESSING_BUDGET := 2800
const MAX_TREE_BUDGET := 1800
const MAX_BORDER_TREE_BUDGET := 900


static func scatter(plan: MapPlan, config: MapConfig, rng: MapRng) -> void:
	var authoring := _resolve_authoring(plan, config)
	var placements: Array = []
	var blockers: Dictionary = {}
	var category_cells: Dictionary = {"tree": {}, "rock": {}, "bush": {}, "resource": {}}
	var stats := _empty_stats(authoring)

	## Interior groves/pockets first so the border budget cannot starve early wood.
	_scatter_dressing(plan, config, authoring, rng, placements, blockers, category_cells, stats)
	_scatter_tree_clusters(plan, config, authoring, rng, placements, blockers, category_cells, stats)
	_scatter_rock_pockets(plan, config, authoring, rng, placements, blockers, category_cells, stats)
	_scatter_bush_mushroom_clusters(plan, config, authoring, rng, placements, blockers, category_cells, stats)
	_scatter_resources(plan, config, authoring, rng, placements, blockers, category_cells, stats)
	_scatter_border_ring(plan, config, authoring, rng, placements, blockers, category_cells, stats)

	stats["main_raid_path_cells"] = plan.main_raid_path_cells.size()
	stats["approach_corridor_cells"] = plan.approach_corridor_cells.size()
	stats["resource_pocket_count"] = plan.resource_pocket_cells.size()
	stats["macro_texture_mode"] = _macro_mode()
	plan.prop_placements = placements
	plan.scatter_stats = stats


static func _macro_mode() -> bool:
	return TerrainPalette.all_macro_textures_present()


static func _resolve_authoring(plan: MapPlan, config: MapConfig) -> MapAuthoringData:
	if plan.authoring_data != null:
		return plan.authoring_data
	if config.authoring_data != null:
		return config.authoring_data
	return _MapAuthoringData.load_demo_or_build(plan.width, plan.height, plan.warren_cell)


static func _empty_stats(authoring: MapAuthoringData) -> Dictionary:
	var stamp_summary := authoring.stamp_counts_summary()
	return {
		"requested": 0,
		"skipped_density": 0,
		"skipped_blocker_spacing": 0,
		"skipped_empty_path": 0,
		"skipped_clearing": 0,
		"skipped_road": 0,
		"by_class": {},
		"by_path": {},
		"tree_count": 0,
		"tree_requested": 0,
		"blocking_prop_count": 0,
		"dressing_count": 0,
		"resource_node_count": 0,
		"resource_by_kind": {"wood": 0, "stone": 0, "food": 0, "gold": 0},
		"border_prop_count": 0,
		"forest_stamp_count": int(stamp_summary.get("forest_stamp_count", 0)),
		"clearing_stamp_count": int(stamp_summary.get("clearing_stamp_count", 0)),
		"road_stamp_count": int(stamp_summary.get("road_stamp_count", 0)),
		"authoring_loaded": true,
		"main_raid_path_cells": 0,
		"approach_corridor_cells": 0,
		"resource_pocket_count": 0,
		"macro_texture_mode": false,
	}


static func _scatter_border_ring(
	plan: MapPlan,
	config: MapConfig,
	authoring: MapAuthoringData,
	rng: MapRng,
	placements: Array,
	blockers: Dictionary,
	category_cells: Dictionary,
	stats: Dictionary,
) -> void:
	if not authoring.edge_forest_enabled:
		return
	var tree_paths: Array[String] = [
		_VisualCatalog.ENV_TREE,
		_VisualCatalog.ENV_TREE_PINE,
		_VisualCatalog.ENV_TREE_PINE_ALT,
		_VisualCatalog.ENV_TREE_TALL,
	]
	var stride := 2
	for y in range(0, plan.height, stride):
		for x in range(0, plan.width, stride):
			var cell := Vector2i(x, y)
			if not authoring.is_in_border_ring(cell, plan.width, plan.height, BORDER_DEPTH):
				continue
			if _CorridorPlanner.is_approach_cell(plan, cell):
				continue
			if blockers.has(cell):
				continue
			if int(stats["border_prop_count"]) >= MAX_BORDER_TREE_BUDGET:
				return
			if int(stats["tree_count"]) >= MAX_TREE_BUDGET:
				return
			if not rng.roll(0.78):
				continue
			## Force dense edge silhouette even on cliff/rocky border uplift.
			var path := str(rng.pick(tree_paths))
			if _try_place(
				plan,
				cell,
				path,
				true,
				Defs.ResourceKind.WOOD,
				Constants.TREE_WOOD_AMOUNT,
				rng,
				placements,
				blockers,
				category_cells,
				stats,
				"tree",
				1,
			):
				stats["border_prop_count"] = int(stats["border_prop_count"]) + 1
				stats["tree_count"] = int(stats["tree_count"]) + 1
				stats["tree_requested"] = int(stats["tree_requested"]) + 1
				_bump_resource_kind(stats, Defs.ResourceKind.WOOD)
			elif rng.roll(0.35):
				_try_place(
					plan,
					cell,
					_VisualCatalog.random_rock_path(rng),
					true,
					-1,
					0,
					rng,
					placements,
					blockers,
					category_cells,
					stats,
					"rock",
					ROCK_MIN_SPACING,
				)


static func _scatter_dressing(
	plan: MapPlan,
	config: MapConfig,
	authoring: MapAuthoringData,
	rng: MapRng,
	placements: Array,
	blockers: Dictionary,
	category_cells: Dictionary,
	stats: Dictionary,
) -> void:
	var stride := _dressing_stride(plan)
	var density_scale := _map_density_scale(plan, stride)
	for y in range(0, plan.height, stride):
		for x in range(0, plan.width, stride):
			if int(stats["dressing_count"]) >= MAX_DRESSING_BUDGET:
				return
			var cell := Vector2i(x, y)
			if not _can_scatter_at(cell, plan, config, authoring, false):
				continue
			if authoring.is_in_border_ring(cell, plan.width, plan.height, BORDER_DEPTH - 1):
				continue
			var terrain_class: Defs.TerrainClass = plan.tile_classes[y][x]
			var forest_density := authoring.sample_forest_density_for_plan(cell, plan, terrain_class)
			var path := _pick_dressing_path(terrain_class, forest_density, authoring, rng)
			if path.is_empty():
				stats["skipped_empty_path"] = int(stats["skipped_empty_path"]) + 1
				continue
			var probability := _dressing_probability(terrain_class, forest_density, authoring, path)
			if not rng.roll(probability * density_scale * 0.85):
				stats["skipped_density"] = int(stats["skipped_density"]) + 1
				continue
			var category := _path_category(path)
			var spacing := BUSH_MIN_SPACING if category == "bush" else 0
			if category == "rock":
				spacing = ROCK_MIN_SPACING
			_try_place(
				plan,
				cell,
				path,
				false,
				-1,
				0,
				rng,
				placements,
				blockers,
				category_cells,
				stats,
				category,
				spacing,
			)


static func _scatter_tree_clusters(
	plan: MapPlan,
	config: MapConfig,
	authoring: MapAuthoringData,
	rng: MapRng,
	placements: Array,
	blockers: Dictionary,
	category_cells: Dictionary,
	stats: Dictionary,
) -> void:
	for entry in placements:
		if entry != null and entry.blocks_movement:
			blockers[entry.grid_cell] = true

	var cluster_count := _tree_cluster_count(plan, authoring)
	var tree_paths: Array[String] = [
		_VisualCatalog.ENV_TREE,
		_VisualCatalog.ENV_TREE_PINE,
		_VisualCatalog.ENV_TREE_PINE_ALT,
		_VisualCatalog.ENV_TREE_WILLOW,
		_VisualCatalog.ENV_TREE_TALL,
	]
	## Seed early wood pockets as guaranteed grove centers.
	var wood_centers := authoring.resource_pocket_centers("wood")
	for pocket in wood_centers:
		_place_tree_cluster_at(
			plan,
			config,
			authoring,
			rng,
			placements,
			blockers,
			category_cells,
			stats,
			tree_paths,
			pocket,
			rng.randi_range(8, 14),
		)

	for _cluster_i in range(cluster_count):
		if int(stats["tree_count"]) >= MAX_TREE_BUDGET:
			break
		var center := _pick_tree_cluster_cell(plan, config, authoring, rng, blockers)
		if center.x < 0:
			continue
		var terrain_class: Defs.TerrainClass = plan.tile_classes[center.y][center.x]
		var center_density := authoring.sample_forest_density_for_plan(center, plan, terrain_class)
		var trees_in_cluster := rng.randi_range(6, 14)
		if center_density > 0.75:
			trees_in_cluster = rng.randi_range(10, 18)
		elif center_density < 0.35:
			trees_in_cluster = rng.randi_range(4, 8)
		_place_tree_cluster_at(
			plan,
			config,
			authoring,
			rng,
			placements,
			blockers,
			category_cells,
			stats,
			tree_paths,
			center,
			trees_in_cluster,
		)


static func _place_tree_cluster_at(
	plan: MapPlan,
	config: MapConfig,
	authoring: MapAuthoringData,
	rng: MapRng,
	placements: Array,
	blockers: Dictionary,
	category_cells: Dictionary,
	stats: Dictionary,
	tree_paths: Array[String],
	center: Vector2i,
	trees_in_cluster: int,
) -> void:
	var terrain_class: Defs.TerrainClass = plan.tile_classes[clampi(center.y, 0, plan.height - 1)][clampi(center.x, 0, plan.width - 1)]
	var center_density := authoring.sample_forest_density_for_plan(center, plan, terrain_class)
	for _tree_i in range(trees_in_cluster):
		if int(stats["tree_count"]) >= MAX_TREE_BUDGET:
			return
		var offset := _cluster_offset(rng, center_density)
		var cell := center + offset
		if not _is_tree_cell_valid(plan, config, authoring, cell, blockers):
			continue
		var path := str(rng.pick(tree_paths))
		if _try_place(
			plan,
			cell,
			path,
			true,
			Defs.ResourceKind.WOOD,
			Constants.TREE_WOOD_AMOUNT,
			rng,
			placements,
			blockers,
			category_cells,
			stats,
			"tree",
			TREE_MIN_SPACING,
		):
			stats["tree_count"] = int(stats["tree_count"]) + 1
			stats["tree_requested"] = int(stats["tree_requested"]) + 1
			_bump_resource_kind(stats, Defs.ResourceKind.WOOD)


static func _scatter_rock_pockets(
	plan: MapPlan,
	config: MapConfig,
	authoring: MapAuthoringData,
	rng: MapRng,
	placements: Array,
	blockers: Dictionary,
	category_cells: Dictionary,
	stats: Dictionary,
) -> void:
	var stone_centers := authoring.resource_pocket_centers("stone")
	for pocket in stone_centers:
		for _i in range(rng.randi_range(5, 10)):
			var cell := pocket + Vector2i(rng.randi_range(-4, 4), rng.randi_range(-4, 4))
			if not _can_scatter_at(cell, plan, config, authoring, false):
				continue
			_try_place(
				plan,
				cell,
				_VisualCatalog.random_rock_path(rng),
				false,
				-1,
				0,
				rng,
				placements,
				blockers,
				category_cells,
				stats,
				"rock",
				ROCK_MIN_SPACING,
			)


static func _scatter_bush_mushroom_clusters(
	plan: MapPlan,
	config: MapConfig,
	authoring: MapAuthoringData,
	rng: MapRng,
	placements: Array,
	blockers: Dictionary,
	category_cells: Dictionary,
	stats: Dictionary,
) -> void:
	var food_centers := authoring.resource_pocket_centers("food")
	var paths: Array[String] = [
		_VisualCatalog.ENV_BUSH,
		_VisualCatalog.ENV_MUSHROOM_PATCH,
		_VisualCatalog.ENV_MUSHROOM_PATCH_ALT,
	]
	for pocket in food_centers:
		for _i in range(rng.randi_range(6, 12)):
			var cell := pocket + Vector2i(rng.randi_range(-3, 3), rng.randi_range(-3, 3))
			if not _can_scatter_at(cell, plan, config, authoring, false):
				continue
			var path := str(rng.pick(paths))
			_try_place(
				plan,
				cell,
				path,
				false,
				-1,
				0,
				rng,
				placements,
				blockers,
				category_cells,
				stats,
				"bush",
				BUSH_MIN_SPACING,
			)


static func _scatter_resources(
	plan: MapPlan,
	config: MapConfig,
	authoring: MapAuthoringData,
	rng: MapRng,
	placements: Array,
	blockers: Dictionary,
	category_cells: Dictionary,
	stats: Dictionary,
) -> void:
	for entry in placements:
		if entry != null and entry.blocks_movement:
			blockers[entry.grid_cell] = true

	var resource_specs: Array[Dictionary] = [
		{
			"kind": Defs.ResourceKind.FOOD,
			"count": 3,
			"tag": "food",
			"classes": [Defs.TerrainClass.MUD_MOSSY, Defs.TerrainClass.FOREST_FLOOR, Defs.TerrainClass.MOSS],
			"min_r": 10,
			"max_r": 25,
		},
		{
			"kind": Defs.ResourceKind.STONE,
			"count": 2,
			"tag": "stone",
			"classes": [Defs.TerrainClass.ROCKY_SLOPE, Defs.TerrainClass.MOSS, Defs.TerrainClass.FOREST_FLOOR],
			"min_r": 20,
			"max_r": 45,
		},
		{
			"kind": Defs.ResourceKind.GOLD,
			"count": 1,
			"tag": "gold",
			"classes": [Defs.TerrainClass.ROCKY_SLOPE, Defs.TerrainClass.FOREST_FLOOR],
			"min_r": 35,
			"max_r": 70,
		},
	]
	var reachable := _reachable(plan, plan.warren_cell, blockers)
	for spec in resource_specs:
		var kind: Defs.ResourceKind = spec.kind
		var amount := 200 if kind == Defs.ResourceKind.GOLD else (80 if kind == Defs.ResourceKind.FOOD else Constants.BUILDING_RESOURCE_AMOUNT)
		var pockets := authoring.resource_pocket_centers(str(spec.tag))
		for _i in range(int(spec.count)):
			var cell := _pick_resource_near_pockets(
				plan,
				spec.classes,
				plan.warren_cell,
				blockers,
				reachable,
				authoring,
				kind,
				rng,
				pockets,
				int(spec.min_r),
				int(spec.max_r),
			)
			if cell.x < 0 and not pockets.is_empty():
				cell = pockets[rng.randi_range(0, pockets.size() - 1)]
			if cell.x < 0:
				continue
			var path := _VisualCatalog.resource_wrapper(kind)
			if _try_place(
				plan,
				cell,
				path,
				true,
				kind,
				amount,
				rng,
				placements,
				blockers,
				category_cells,
				stats,
				"resource",
				1,
			):
				stats["resource_node_count"] = int(stats["resource_node_count"]) + 1
				_bump_resource_kind(stats, kind)


static func _bump_resource_kind(stats: Dictionary, kind: Defs.ResourceKind) -> void:
	var by_kind: Dictionary = stats["resource_by_kind"]
	match kind:
		Defs.ResourceKind.WOOD:
			by_kind["wood"] = int(by_kind.get("wood", 0)) + 1
		Defs.ResourceKind.STONE:
			by_kind["stone"] = int(by_kind.get("stone", 0)) + 1
		Defs.ResourceKind.FOOD:
			by_kind["food"] = int(by_kind.get("food", 0)) + 1
		Defs.ResourceKind.GOLD:
			by_kind["gold"] = int(by_kind.get("gold", 0)) + 1


static func _try_place(
	plan: MapPlan,
	cell: Vector2i,
	path: String,
	blocks: bool,
	resource_kind: int,
	resource_amount: int,
	rng: MapRng,
	placements: Array,
	blockers: Dictionary,
	category_cells: Dictionary,
	stats: Dictionary,
	category: String,
	min_spacing: int,
) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= plan.width or cell.y >= plan.height:
		return false
	if blockers.has(cell):
		stats["skipped_blocker_spacing"] = int(stats["skipped_blocker_spacing"]) + 1
		return false
	if min_spacing > 0 and not _spacing_ok(category_cells, category, cell, min_spacing):
		stats["skipped_blocker_spacing"] = int(stats["skipped_blocker_spacing"]) + 1
		return false
	var terrain_class: Defs.TerrainClass = plan.tile_classes[cell.y][cell.x]
	var forest_density := 0.0
	stats["requested"] = int(stats["requested"]) + 1
	_record_scatter_path(stats, path, terrain_class)
	var placement := _new_placement(
		cell,
		path,
		blocks,
		resource_kind,
		resource_amount,
		rng,
		plan,
		terrain_class,
		forest_density,
	)
	placements.append(placement)
	if blocks:
		blockers[cell] = true
		stats["blocking_prop_count"] = int(stats["blocking_prop_count"]) + 1
	else:
		stats["dressing_count"] = int(stats["dressing_count"]) + 1
	if not category_cells.has(category):
		category_cells[category] = {}
	category_cells[category][cell] = true
	return true


static func _spacing_ok(category_cells: Dictionary, category: String, cell: Vector2i, min_spacing: int) -> bool:
	var cells: Dictionary = category_cells.get(category, {})
	for dz in range(-min_spacing, min_spacing + 1):
		for dx in range(-min_spacing, min_spacing + 1):
			if dx == 0 and dz == 0:
				continue
			if cells.has(cell + Vector2i(dx, dz)):
				return false
	return true


static func _path_category(path: String) -> String:
	var lower := path.to_lower()
	if "rock" in lower:
		return "rock"
	if "bush" in lower or "mushroom" in lower or "grass" in lower or "stump" in lower:
		return "bush"
	if _VisualCatalog.is_tree_path(path):
		return "tree"
	return "decor"


static func _pick_dressing_path(
	terrain_class: Defs.TerrainClass,
	forest_density: float,
	authoring: MapAuthoringData,
	rng: MapRng,
) -> String:
	if forest_density >= 0.45:
		return str(
			rng.pick([
				_VisualCatalog.ENV_BUSH,
				_VisualCatalog.ENV_GRASS,
				_VisualCatalog.ENV_MUSHROOM_PATCH,
				_VisualCatalog.ENV_MUSHROOM_PATCH_ALT,
			])
		)
	match terrain_class:
		Defs.TerrainClass.MOSS:
			return str(rng.pick([_VisualCatalog.ENV_GRASS, _VisualCatalog.ENV_BUSH]))
		Defs.TerrainClass.FOREST_FLOOR:
			return str(
				rng.pick([
					_VisualCatalog.ENV_MUSHROOM_PATCH,
					_VisualCatalog.ENV_MUSHROOM_PATCH_ALT,
					_VisualCatalog.ENV_BUSH,
					_VisualCatalog.ENV_GRASS,
				])
			)
		Defs.TerrainClass.ROCKY_SLOPE:
			return str(
				rng.pick([
					_VisualCatalog.ENV_ROCK,
					_VisualCatalog.ENV_ROCK_PILE,
					_VisualCatalog.ENV_ROCK_SPIRE,
					_VisualCatalog.ENV_ROCK_CRAGS,
				])
			)
		Defs.TerrainClass.MUD_MOSSY:
			return str(
				rng.pick([
					_VisualCatalog.ENV_BUSH,
					_VisualCatalog.ENV_MUSHROOM_PATCH,
					_VisualCatalog.ENV_GRASS,
				])
			)
		Defs.TerrainClass.WARREN_GROUND:
			return str(rng.pick([_VisualCatalog.ENV_CRATE, _VisualCatalog.ENV_BARREL]))
		_:
			return ""


static func _dressing_probability(
	terrain_class: Defs.TerrainClass,
	forest_density: float,
	authoring: MapAuthoringData,
	path: String,
) -> float:
	var base := _scenery_density(terrain_class)
	if "grass" in path.to_lower():
		base *= authoring.grass_density_multiplier
	elif "bush" in path.to_lower():
		base *= authoring.bush_density_multiplier
	elif "mushroom" in path.to_lower():
		base *= authoring.mushroom_density_multiplier
	elif "rock" in path.to_lower():
		base *= authoring.rock_density_multiplier
	base += forest_density * 0.18
	if forest_density >= 0.35 and forest_density <= 0.7:
		base += 0.12
	return clampf(base, 0.0, 0.95)


static func _pick_tree_cluster_cell(
	plan: MapPlan,
	config: MapConfig,
	authoring: MapAuthoringData,
	rng: MapRng,
	blockers: Dictionary,
) -> Vector2i:
	var best_cell := Vector2i(-1, -1)
	var best_score := -1.0
	for _attempt in range(64):
		var cell := Vector2i(rng.randi_range(6, plan.width - 7), rng.randi_range(6, plan.height - 7))
		if not _is_tree_cell_valid(plan, config, authoring, cell, blockers):
			continue
		var terrain_class: Defs.TerrainClass = plan.tile_classes[cell.y][cell.x]
		var density := authoring.sample_forest_density_for_plan(cell, plan, terrain_class)
		if density < 0.22:
			continue
		var dist := float(cell.distance_to(plan.warren_cell))
		if dist < 8.0:
			continue
		var ridge := _ValleyTerrain.ridge_barrier_score(plan, cell)
		if ridge > 0.58:
			continue
		var valley := _ValleyTerrain.valley_floor_score(plan, cell)
		var ring := _ValleyTerrain.expansion_ring_score(plan, cell, plan.warren_cell)
		var edge_boost := authoring.edge_forest_boost_for_map(cell, plan.width, plan.height)
		var tree_valley := 1.0 - absf(valley - 0.42) * 1.35
		var score := density * 0.3 + ring * 0.35 + clampf(tree_valley, 0.15, 1.0) * 0.2 + edge_boost * 0.25
		if score > best_score:
			best_score = score
			best_cell = cell
	return best_cell


static func _cluster_offset(rng: MapRng, center_density: float) -> Vector2i:
	var spread := 4 if center_density < 0.55 else 6
	if center_density > 0.8:
		spread = 5
	return Vector2i(rng.randi_range(-spread, spread), rng.randi_range(-spread, spread))


static func _is_tree_cell_valid(
	plan: MapPlan,
	config: MapConfig,
	authoring: MapAuthoringData,
	cell: Vector2i,
	blockers: Dictionary,
) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= plan.width or cell.y >= plan.height:
		return false
	if blockers.has(cell):
		return false
	if _inside_camp(cell, plan.warren_cell, config):
		return false
	if authoring.sample_clearing_strength(cell) >= 0.48:
		return false
	if _CorridorPlanner.is_approach_cell(plan, cell):
		return false
	if authoring.is_in_road_or_approach_lane(cell):
		return false
	var terrain_class: Defs.TerrainClass = plan.tile_classes[cell.y][cell.x]
	if terrain_class == Defs.TerrainClass.MUD_CLEARING or terrain_class == Defs.TerrainClass.WARREN_GROUND:
		return false
	if terrain_class == Defs.TerrainClass.CLIFF:
		return authoring.is_in_border_ring(cell, plan.width, plan.height, BORDER_DEPTH)
	var density := authoring.sample_forest_density_for_plan(cell, plan, terrain_class)
	if density < 0.1 and not authoring.is_in_border_ring(cell, plan.width, plan.height, BORDER_DEPTH):
		return false
	return true


static func _can_scatter_at(
	cell: Vector2i,
	plan: MapPlan,
	config: MapConfig,
	authoring: MapAuthoringData,
	allow_road: bool,
) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= plan.width or cell.y >= plan.height:
		return false
	var terrain_class: Defs.TerrainClass = plan.tile_classes[cell.y][cell.x]
	if terrain_class == Defs.TerrainClass.MUD_CLEARING or terrain_class == Defs.TerrainClass.CLIFF:
		return false
	if _inside_camp(cell, plan.warren_cell, config):
		return false
	if authoring.sample_clearing_strength(cell) >= 0.48:
		return false
	if not allow_road and _CorridorPlanner.is_approach_cell(plan, cell):
		return false
	if not allow_road and authoring.is_in_road_or_approach_lane(cell):
		return false
	return true


static func _new_placement(
	cell: Vector2i,
	scene_path: String,
	blocks: bool,
	resource_kind: int,
	resource_amount: int,
	rng: MapRng,
	plan: MapPlan,
	terrain_class: Defs.TerrainClass,
	forest_density: float,
) -> RefCounted:
	var placement := _PropPlacement.new()
	placement.scene_path = scene_path
	placement.terrain_class = int(terrain_class)
	placement.grid_cell = cell
	placement.blocks_movement = blocks
	placement.resource_kind = resource_kind
	placement.resource_amount = resource_amount
	placement.rotation_y = rng.randf_range(0.0, TAU)
	var jitter := Vector2(rng.randf_range(-0.35, 0.35), rng.randf_range(-0.35, 0.35))
	placement.world_pos = Vector3(
		(cell.x + 0.5 + jitter.x) * Constants.TILE_SIZE,
		HeightSampler.sample_cell(plan, cell),
		(cell.y + 0.5 + jitter.y) * Constants.TILE_SIZE,
	)
	var scale_factor := rng.randf_range(0.82, 1.18)
	if _VisualCatalog.is_tree_path(scene_path):
		scale_factor = rng.randf_range(0.88, 1.22)
		if forest_density > 0.75:
			scale_factor *= rng.randf_range(1.0, 1.08)
	if resource_kind >= 0:
		if _VisualCatalog.is_tree_path(scene_path):
			placement.scale = _VisualCatalog.env_visual_scale(scene_path) * Vector3.ONE * scale_factor
		else:
			placement.scale = _VisualCatalog.resource_visual_scale(scene_path) * Vector3.ONE * scale_factor
	else:
		placement.scale = _VisualCatalog.env_visual_scale(scene_path) * Vector3.ONE * scale_factor
	return placement


static func _pick_resource_near_pockets(
	plan: MapPlan,
	allowed_classes: Array,
	warren_cell: Vector2i,
	blockers: Dictionary,
	reachable: Dictionary,
	authoring: MapAuthoringData,
	kind: Defs.ResourceKind,
	rng: MapRng,
	pockets: Array[Vector2i],
	min_radius: int,
	max_radius: int,
) -> Vector2i:
	var candidates: Array[Vector2i] = []
	var weights: Array[float] = []
	var search_centers: Array[Vector2i] = pockets.duplicate()
	if search_centers.is_empty():
		search_centers.append(warren_cell + Vector2i(min_radius + 4, 0))
	for pocket in search_centers:
		for dy in range(-8, 9):
			for dx in range(-8, 9):
				var cell := pocket + Vector2i(dx, dy)
				if cell.x < 0 or cell.y < 0 or cell.x >= plan.width or cell.y >= plan.height:
					continue
				if not reachable.has(cell):
					continue
				var terrain_class: Defs.TerrainClass = plan.tile_classes[cell.y][cell.x]
				if not _class_allowed(terrain_class, allowed_classes):
					continue
				if blockers.has(cell):
					continue
				var dist := cell.distance_to(warren_cell)
				if dist < float(min_radius) or dist > float(max_radius):
					continue
				if _CorridorPlanner.is_main_raid_cell(plan, cell):
					continue
				candidates.append(cell)
				weights.append(maxf(0.05, authoring.sample_resource_bias(cell, kind)))
	if candidates.is_empty():
		return Vector2i(-1, -1)
	var total := 0.0
	for w in weights:
		total += w
	var roll := rng.randf() * total
	var accum := 0.0
	for i in range(candidates.size()):
		accum += weights[i]
		if roll <= accum:
			return candidates[i]
	return candidates[candidates.size() - 1]


static func _reachable(plan: MapPlan, from_cell: Vector2i, blockers: Dictionary) -> Dictionary:
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


static func _inside_camp(cell: Vector2i, warren_cell: Vector2i, config: MapConfig) -> bool:
	## Use authored clearing when available via build core + soft radius.
	var camp_center := Vector2(warren_cell) + Vector2(config.warren_footprint) * 0.5
	return Vector2(cell).distance_to(camp_center) <= float(maxi(6, config.camp_flat_radius / 3))


static func _class_allowed(terrain_class: Defs.TerrainClass, allowed_classes: Array) -> bool:
	for allowed in allowed_classes:
		if allowed == terrain_class:
			return true
	return false


static func _scenery_density(terrain_class: Defs.TerrainClass) -> float:
	match terrain_class:
		Defs.TerrainClass.MOSS:
			return 0.22
		Defs.TerrainClass.FOREST_FLOOR:
			return 0.48
		Defs.TerrainClass.ROCKY_SLOPE:
			return 0.16
		Defs.TerrainClass.MUD_MOSSY:
			return 0.22
		Defs.TerrainClass.WARREN_GROUND:
			return 0.1
		_:
			return 0.0


static func _record_scatter_path(stats: Dictionary, path: String, terrain_class: Defs.TerrainClass) -> void:
	var class_key := str(int(terrain_class))
	stats["by_class"][class_key] = int(stats["by_class"].get(class_key, 0)) + 1
	stats["by_path"][path] = int(stats["by_path"].get(path, 0)) + 1


static func _dressing_stride(plan: MapPlan) -> int:
	if plan.width >= 256:
		return 3
	if plan.width >= 128:
		return 2
	return 1


static func _tree_cluster_count(plan: MapPlan, authoring: MapAuthoringData) -> int:
	if plan.width >= 256:
		return maxi(int(round(72.0 * authoring.tree_density_multiplier)), 40)
	if plan.width >= 128:
		return maxi(int(round(32.0 * authoring.tree_density_multiplier)), 16)
	return 16


static func _map_density_scale(plan: MapPlan, stride: int) -> float:
	var area := float(plan.width * plan.height)
	var ref := float(Constants.MAPGEN_REFERENCE_AREA)
	return ref / area * float(stride * stride)
