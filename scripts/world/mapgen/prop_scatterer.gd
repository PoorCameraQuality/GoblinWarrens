class_name PropScatterer
extends RefCounted

const _VisualCatalog := preload("res://scripts/art/visual_catalog.gd")
const _PropPlacement := preload("res://scripts/world/mapgen/prop_placement.gd")
const _TerrainClassifier := preload("res://scripts/world/mapgen/terrain_classifier.gd")
const _MapAuthoringData := preload("res://data/mapgen/map_authoring_data.gd")
const _ValleyTerrain := preload("res://scripts/world/mapgen/valley_terrain.gd")

## Authored-mask prop and tree scatter for MapGenerator.


static func scatter(plan: MapPlan, config: MapConfig, rng: MapRng) -> void:
	var authoring := _resolve_authoring(plan, config)
	var placements: Array = []
	var blockers: Dictionary = {}
	var stats := _empty_stats(authoring)

	_scatter_dressing(plan, config, authoring, rng, placements, blockers, stats)
	_scatter_tree_clusters(plan, config, authoring, rng, placements, blockers, stats)
	_scatter_transition_props(plan, config, authoring, rng, placements, blockers, stats)
	_scatter_resources(plan, config, authoring, rng, placements, blockers, stats)

	plan.prop_placements = placements
	plan.scatter_stats = stats


static func _resolve_authoring(plan: MapPlan, config: MapConfig) -> MapAuthoringData:
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
		"forest_stamp_count": int(stamp_summary.get("forest_stamp_count", 0)),
		"clearing_stamp_count": int(stamp_summary.get("clearing_stamp_count", 0)),
		"authoring_loaded": true,
	}


static func _scatter_dressing(
	plan: MapPlan,
	config: MapConfig,
	authoring: MapAuthoringData,
	rng: MapRng,
	placements: Array,
	blockers: Dictionary,
	stats: Dictionary,
) -> void:
	var stride := _dressing_stride(plan)
	var density_scale := _map_density_scale(plan, stride)
	for y in range(0, plan.height, stride):
		for x in range(0, plan.width, stride):
			var cell := Vector2i(x, y)
			if not _can_scatter_at(cell, plan, config, authoring, false):
				continue
			var terrain_class: Defs.TerrainClass = plan.tile_classes[y][x]
			var forest_density := authoring.sample_forest_density_for_plan(cell, plan, terrain_class)
			var path := _pick_dressing_path(terrain_class, forest_density, authoring, rng)
			if path.is_empty():
				stats["skipped_empty_path"] = int(stats["skipped_empty_path"]) + 1
				continue
			var probability := _dressing_probability(terrain_class, forest_density, authoring, path)
			if not rng.roll(probability * density_scale):
				stats["skipped_density"] = int(stats["skipped_density"]) + 1
				continue
			stats["requested"] = int(stats["requested"]) + 1
			_record_scatter_path(stats, path, terrain_class)
			placements.append(
				_new_placement(cell, path, false, -1, 0, rng, plan, terrain_class, forest_density)
			)
			stats["dressing_count"] = int(stats["dressing_count"]) + 1


static func _scatter_tree_clusters(
	plan: MapPlan,
	config: MapConfig,
	authoring: MapAuthoringData,
	rng: MapRng,
	placements: Array,
	blockers: Dictionary,
	stats: Dictionary,
) -> void:
	for entry in placements:
		var placement = entry
		if placement != null and placement.blocks_movement:
			blockers[placement.grid_cell] = true

	var cluster_count := _tree_cluster_count(plan, authoring)
	var tree_paths: Array[String] = [
		_VisualCatalog.ENV_TREE,
		_VisualCatalog.ENV_TREE_PINE,
		_VisualCatalog.ENV_TREE_PINE_ALT,
		_VisualCatalog.ENV_TREE_WILLOW,
		_VisualCatalog.ENV_TREE_TALL,
	]
	for _cluster_i in range(cluster_count):
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
		for _tree_i in range(trees_in_cluster):
			var offset := _cluster_offset(rng, center_density)
			var cell := center + offset
			if not _is_tree_cell_valid(plan, config, authoring, cell, blockers):
				continue
			var path := str(rng.pick(tree_paths))
			var cell_class: Defs.TerrainClass = plan.tile_classes[cell.y][cell.x]
			var cell_density := authoring.sample_forest_density_for_plan(cell, plan, cell_class)
			var placement := _new_placement(
				cell,
				path,
				true,
				Defs.ResourceKind.WOOD,
				Constants.TREE_WOOD_AMOUNT,
				rng,
				plan,
				cell_class,
				cell_density,
			)
			stats["requested"] = int(stats["requested"]) + 1
			stats["tree_count"] = int(stats["tree_count"]) + 1
			stats["tree_requested"] = int(stats["tree_requested"]) + 1
			stats["blocking_prop_count"] = int(stats["blocking_prop_count"]) + 1
			_record_scatter_path(stats, path, cell_class)
			placements.append(placement)
			blockers[cell] = true


static func _scatter_transition_props(
	plan: MapPlan,
	config: MapConfig,
	authoring: MapAuthoringData,
	rng: MapRng,
	placements: Array,
	blockers: Dictionary,
	stats: Dictionary,
) -> void:
	var transition_paths: Array[String] = [
		_VisualCatalog.ENV_BUSH,
		_VisualCatalog.ENV_STUMP_BIRCH,
		_VisualCatalog.ENV_STUMP_PINE,
		_VisualCatalog.ENV_MUSHROOM_PATCH,
		_VisualCatalog.ENV_MUSHROOM_PATCH_ALT,
	]
	for entry in placements:
		if entry == null or not entry.blocks_movement:
			continue
		if not _VisualCatalog.is_tree_path(entry.scene_path):
			continue
		var tree_cell: Vector2i = entry.grid_cell
		for _attempt in range(3):
			var offset := Vector2i(rng.randi_range(-2, 2), rng.randi_range(-2, 2))
			if offset == Vector2i.ZERO:
				continue
			var cell := tree_cell + offset
			if not _can_scatter_at(cell, plan, config, authoring, false):
				continue
			if blockers.has(cell):
				continue
			if not rng.roll(0.34):
				continue
			var terrain_class: Defs.TerrainClass = plan.tile_classes[cell.y][cell.x]
			var forest_density := authoring.sample_forest_density_for_plan(cell, plan, terrain_class)
			if forest_density < 0.18:
				continue
			var path := str(rng.pick(transition_paths))
			stats["requested"] = int(stats["requested"]) + 1
			_record_scatter_path(stats, path, terrain_class)
			placements.append(
				_new_placement(cell, path, false, -1, 0, rng, plan, terrain_class, forest_density)
			)
			stats["dressing_count"] = int(stats["dressing_count"]) + 1


static func _scatter_resources(
	plan: MapPlan,
	config: MapConfig,
	authoring: MapAuthoringData,
	rng: MapRng,
	placements: Array,
	blockers: Dictionary,
	stats: Dictionary,
) -> void:
	for entry in placements:
		if entry != null and entry.blocks_movement:
			blockers[entry.grid_cell] = true

	var resource_specs: Array[Dictionary] = [
		{"kind": Defs.ResourceKind.GOLD, "count": 1, "classes": [Defs.TerrainClass.ROCKY_SLOPE]},
		{"kind": Defs.ResourceKind.STONE, "count": 2, "classes": [Defs.TerrainClass.ROCKY_SLOPE]},
		{"kind": Defs.ResourceKind.FOOD, "count": 2, "classes": [Defs.TerrainClass.MUD_MOSSY, Defs.TerrainClass.FOREST_FLOOR]},
	]
	for spec in resource_specs:
		var kind: Defs.ResourceKind = spec.kind
		var amount := 200 if kind == Defs.ResourceKind.GOLD else (80 if kind == Defs.ResourceKind.FOOD else Constants.BUILDING_RESOURCE_AMOUNT)
		for _i in range(int(spec.count)):
			var reachable := _reachable(plan, plan.warren_cell, blockers)
			var cell := _pick_resource_cell(plan, spec.classes, plan.warren_cell, blockers, reachable, authoring, kind, rng)
			if cell.x < 0:
				continue
			var path := _VisualCatalog.resource_wrapper(kind)
			var resource_class: Defs.TerrainClass = plan.tile_classes[cell.y][cell.x]
			stats["requested"] = int(stats["requested"]) + 1
			stats["resource_node_count"] = int(stats["resource_node_count"]) + 1
			stats["blocking_prop_count"] = int(stats["blocking_prop_count"]) + 1
			_record_scatter_path(stats, path, resource_class)
			placements.append(_new_placement(cell, path, true, kind, amount, rng, plan, resource_class, 0.0))
			blockers[cell] = true


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
			return str(rng.pick([_VisualCatalog.ENV_ROCK, _VisualCatalog.ENV_ROCK]))
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
		var tree_valley := 1.0 - absf(valley - 0.42) * 1.35
		var score := density * 0.35 + ring * 0.4 + clampf(tree_valley, 0.15, 1.0) * 0.25
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
	if authoring.sample_clearing_strength(cell) >= 0.55:
		return false
	if authoring.is_in_road_or_approach_lane(cell):
		return false
	var terrain_class: Defs.TerrainClass = plan.tile_classes[cell.y][cell.x]
	if terrain_class not in [
		Defs.TerrainClass.MOSS,
		Defs.TerrainClass.FOREST_FLOOR,
		Defs.TerrainClass.MUD_MOSSY,
	]:
		return false
	if not _TerrainClassifier.is_walkable(terrain_class):
		return false
	var density := authoring.sample_forest_density_for_plan(cell, plan, terrain_class)
	if density < 0.15 and _ValleyTerrain.ridge_barrier_score(plan, cell) < 0.35:
		return false
	if _ValleyTerrain.ridge_barrier_score(plan, cell) > 0.62:
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
	if authoring.sample_clearing_strength(cell) >= 0.55:
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


static func _pick_resource_cell(
	plan: MapPlan,
	allowed_classes: Array,
	warren_cell: Vector2i,
	blockers: Dictionary,
	reachable: Dictionary,
	authoring: MapAuthoringData,
	kind: Defs.ResourceKind,
	rng: MapRng,
) -> Vector2i:
	var candidates: Array[Vector2i] = []
	var weights: Array[float] = []
	for y in range(plan.height):
		for x in range(plan.width):
			var cell := Vector2i(x, y)
			if not reachable.has(cell):
				continue
			var terrain_class: Defs.TerrainClass = plan.tile_classes[y][x]
			if not _class_allowed(terrain_class, allowed_classes):
				continue
			if blockers.has(cell):
				continue
			if cell.distance_to(warren_cell) < Constants.MAPGEN_RESOURCE_MIN_RADIUS:
				continue
			if cell.distance_to(warren_cell) > float(Constants.MAPGEN_RESOURCE_MAX_RADIUS):
				continue
			if authoring.is_in_road_or_approach_lane(cell):
				continue
			var valley := _ValleyTerrain.valley_floor_score(plan, cell)
			if valley < 0.18 and kind != Defs.ResourceKind.GOLD:
				continue
			candidates.append(cell)
			var ring := _ValleyTerrain.expansion_ring_score(plan, cell, warren_cell)
			weights.append(maxf(0.05, authoring.sample_resource_bias(cell, kind) * valley * ring * 3.0))
	if candidates.is_empty():
		return Vector2i(-1, -1)
	var total := 0.0
	for w in weights:
		total += w
	if total <= 0.0:
		return candidates[rng.randi_range(0, candidates.size() - 1)]
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
	var camp_center := Vector2(warren_cell) + Vector2(config.warren_footprint) * 0.5
	return Vector2(cell).distance_to(camp_center) <= float(config.camp_flat_radius + 1)


static func _class_allowed(terrain_class: Defs.TerrainClass, allowed_classes: Array) -> bool:
	for allowed in allowed_classes:
		if allowed == terrain_class:
			return true
	return false


static func _scenery_density(terrain_class: Defs.TerrainClass) -> float:
	match terrain_class:
		Defs.TerrainClass.MOSS:
			return 0.28
		Defs.TerrainClass.FOREST_FLOOR:
			return 0.62
		Defs.TerrainClass.ROCKY_SLOPE:
			return 0.18
		Defs.TerrainClass.MUD_MOSSY:
			return 0.26
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
		return maxi(int(round(88.0 * authoring.tree_density_multiplier)), 48)
	if plan.width >= 128:
		return maxi(int(round(36.0 * authoring.tree_density_multiplier)), 18)
	return 18


static func _map_density_scale(plan: MapPlan, stride: int) -> float:
	var area := float(plan.width * plan.height)
	var ref := float(Constants.MAPGEN_REFERENCE_AREA)
	return ref / area * float(stride * stride)
