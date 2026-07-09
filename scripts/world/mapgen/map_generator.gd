class_name MapGenerator
extends RefCounted

const _VisualCatalog := preload("res://scripts/art/visual_catalog.gd")
const _PropPlacement := preload("res://scripts/world/mapgen/prop_placement.gd")
const _TerrainBlendMapBuilder := preload("res://scripts/world/mapgen/terrain_blend_map.gd")

## Orchestrator: MapConfig in, MapPlan out.


static func build(config: MapConfig) -> MapPlan:
	var plan := MapPlan.new()
	plan.width = config.width
	plan.height = config.height
	plan.warren_cell = _centered_warren_cell(config)
	plan.storehouse_cell = _storehouse_cell(plan.warren_cell, config)

	var height_data := HeightmapGenerator.generate(config, plan.warren_cell)
	plan.heights = height_data.heights
	plan.height_point_width = height_data.point_width
	plan.height_point_height = height_data.point_height
	plan.tile_classes = TerrainClassifier.classify_grid(
		plan.heights,
		plan.height_point_width,
		plan.height_point_height,
		config,
		plan.warren_cell,
	)
	var blend_result := _TerrainBlendMapBuilder.build(plan.tile_classes, plan.width, plan.height)
	plan.blend_control = blend_result.texture
	plan.blend_stats = blend_result.stats
	plan.mesh = TerrainMeshBuilder.build(
		plan.heights,
		plan.height_point_width,
		plan.height_point_height,
		plan.tile_classes,
	)
	_scatter_props(plan, config, MapRng.new(config.seed + 99))
	_scatter_tree_clusters(plan, config, MapRng.new(config.seed + 101))
	return plan


static func _scatter_props(plan: MapPlan, config: MapConfig, rng: MapRng) -> void:
	var placements: Array = []
	var blockers: Dictionary = {}
	var stats := {
		"requested": 0,
		"skipped_density": 0,
		"skipped_blocker_spacing": 0,
		"skipped_empty_path": 0,
		"by_class": {},
		"by_path": {},
		"tree_requested": 0,
	}
	var stride := _scatter_stride(plan)
	var density_scale := _map_density_scale(plan, stride)
	for y in range(0, plan.height, stride):
		for x in range(0, plan.width, stride):
			var cell := Vector2i(x, y)
			var terrain_class: Defs.TerrainClass = plan.tile_classes[y][x]
			if terrain_class == Defs.TerrainClass.MUD_CLEARING or terrain_class == Defs.TerrainClass.CLIFF:
				continue
			if _inside_camp(cell, plan.warren_cell, config):
				continue
			if not rng.roll(_scenery_density(terrain_class) * density_scale):
				stats["skipped_density"] = int(stats["skipped_density"]) + 1
				continue
			var path := _pick_scenery_path(terrain_class, rng)
			if path.is_empty():
				stats["skipped_empty_path"] = int(stats["skipped_empty_path"]) + 1
				continue
			var blocks := _scenery_blocks(terrain_class, path)
			if blocks and _blocker_near(cell, blockers):
				stats["skipped_blocker_spacing"] = int(stats["skipped_blocker_spacing"]) + 1
				continue
			stats["requested"] = int(stats["requested"]) + 1
			_record_scatter_path(stats, path, terrain_class)
			placements.append(_new_placement(cell, path, blocks, -1, 0, rng, plan, terrain_class))
			if blocks:
				blockers[cell] = true

	var resource_specs: Array[Dictionary] = [
		{"kind": Defs.ResourceKind.GOLD, "count": 1, "classes": [Defs.TerrainClass.ROCKY_SLOPE]},
		{"kind": Defs.ResourceKind.STONE, "count": 2, "classes": [Defs.TerrainClass.ROCKY_SLOPE]},
		{"kind": Defs.ResourceKind.FOOD, "count": 1, "classes": [Defs.TerrainClass.MUD_MOSSY, Defs.TerrainClass.FOREST_FLOOR]},
	]
	for spec in resource_specs:
		var kind: Defs.ResourceKind = spec.kind
		var amount := 200 if kind == Defs.ResourceKind.GOLD else (80 if kind == Defs.ResourceKind.FOOD else Constants.BUILDING_RESOURCE_AMOUNT)
		for _i in range(int(spec.count)):
			var reachable := _reachable(plan, plan.warren_cell, blockers)
			var cell := _pick_resource_cell(plan, spec.classes, plan.warren_cell, blockers, reachable, rng)
			if cell.x < 0:
				continue
			var path := _VisualCatalog.resource_wrapper(kind)
			var resource_class: Defs.TerrainClass = plan.tile_classes[cell.y][cell.x]
			stats["requested"] = int(stats["requested"]) + 1
			_record_scatter_path(stats, path, resource_class)
			placements.append(_new_placement(cell, path, true, kind, amount, rng, plan, resource_class))
			blockers[cell] = true

	plan.prop_placements = placements
	plan.scatter_stats = stats


static func _scatter_tree_clusters(plan: MapPlan, config: MapConfig, rng: MapRng) -> void:
	var stats: Dictionary = plan.scatter_stats
	var placements: Array = plan.prop_placements
	var blockers: Dictionary = {}
	for entry in placements:
		var placement = entry
		if placement != null and placement.blocks_movement:
			blockers[placement.grid_cell] = true

	var cluster_count := 48 if plan.width >= 256 else 18
	var tree_paths: Array[String] = [
		_VisualCatalog.ENV_TREE,
		_VisualCatalog.ENV_TREE_PINE,
		_VisualCatalog.ENV_TREE_PINE_ALT,
		_VisualCatalog.ENV_TREE_WILLOW,
		_VisualCatalog.ENV_TREE_TALL,
	]
	for _cluster_i in range(cluster_count):
		var center := _pick_tree_cluster_cell(plan, config, rng, blockers)
		if center.x < 0:
			continue
		var trees_in_cluster := rng.randi_range(4, 10)
		for _tree_i in range(trees_in_cluster):
			var offset := Vector2i(rng.randi_range(-7, 7), rng.randi_range(-7, 7))
			var cell := center + offset
			if not _is_tree_cell_valid(plan, config, cell, blockers):
				continue
			var path := str(rng.pick(tree_paths))
			var placement := _new_placement(
				cell,
				path,
				true,
				Defs.ResourceKind.WOOD,
				Constants.TREE_WOOD_AMOUNT,
				rng,
				plan,
				plan.tile_classes[cell.y][cell.x],
			)
			stats["requested"] = int(stats.get("requested", 0)) + 1
			_record_scatter_path(stats, path, plan.tile_classes[cell.y][cell.x])
			placements.append(placement)
			blockers[cell] = true

	plan.prop_placements = placements
	plan.scatter_stats = stats


static func _pick_tree_cluster_cell(
	plan: MapPlan,
	config: MapConfig,
	rng: MapRng,
	blockers: Dictionary,
) -> Vector2i:
	for _attempt in range(48):
		var cell := Vector2i(rng.randi_range(8, plan.width - 9), rng.randi_range(8, plan.height - 9))
		if _inside_camp(cell, plan.warren_cell, config):
			continue
		if blockers.has(cell):
			continue
		if not _is_tree_cell_valid(plan, config, cell, blockers):
			continue
		var dist := float(cell.distance_to(plan.warren_cell))
		if dist < 14.0 or dist > 130.0:
			continue
		return cell
	return Vector2i(-1, -1)


static func _is_tree_cell_valid(
	plan: MapPlan,
	config: MapConfig,
	cell: Vector2i,
	blockers: Dictionary,
) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= plan.width or cell.y >= plan.height:
		return false
	if blockers.has(cell):
		return false
	if _inside_camp(cell, plan.warren_cell, config):
		return false
	var terrain_class: Defs.TerrainClass = plan.tile_classes[cell.y][cell.x]
	if terrain_class not in [
		Defs.TerrainClass.MOSS,
		Defs.TerrainClass.FOREST_FLOOR,
		Defs.TerrainClass.MUD_MOSSY,
	]:
		return false
	if not TerrainClassifier.is_walkable(terrain_class):
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
) -> RefCounted:
	var placement := _PropPlacement.new()
	placement.scene_path = scene_path
	placement.terrain_class = int(terrain_class)
	placement.grid_cell = cell
	placement.blocks_movement = blocks
	placement.resource_kind = resource_kind
	placement.resource_amount = resource_amount
	placement.rotation_y = rng.randf_range(0.0, TAU)
	var jitter := Vector2(rng.randf_range(-0.3, 0.3), rng.randf_range(-0.3, 0.3))
	placement.world_pos = Vector3(
		(cell.x + 0.5 + jitter.x) * Constants.TILE_SIZE,
		HeightSampler.sample_cell(plan, cell),
		(cell.y + 0.5 + jitter.y) * Constants.TILE_SIZE,
	)
	if resource_kind >= 0:
		if _VisualCatalog.is_tree_path(scene_path):
			placement.scale = _VisualCatalog.env_visual_scale(scene_path) * _scale_variance(rng)
		else:
			placement.scale = _VisualCatalog.resource_visual_scale(scene_path) * _scale_variance(rng)
	else:
		placement.scale = _VisualCatalog.env_visual_scale(scene_path) * _scale_variance(rng)
	return placement


static func _pick_scenery_path(terrain_class: Defs.TerrainClass, rng: MapRng) -> String:
	match terrain_class:
		Defs.TerrainClass.MOSS:
			return str(rng.pick([
				_VisualCatalog.ENV_GRASS,
				_VisualCatalog.ENV_BUSH,
			]))
		Defs.TerrainClass.FOREST_FLOOR:
			return str(rng.pick([
				_VisualCatalog.ENV_MUSHROOM_PATCH,
				_VisualCatalog.ENV_MUSHROOM_PATCH_ALT,
				_VisualCatalog.ENV_BUSH,
			]))
		Defs.TerrainClass.ROCKY_SLOPE:
			return str(rng.pick([_VisualCatalog.ENV_ROCK, _VisualCatalog.ENV_ROCK]))
		Defs.TerrainClass.MUD_MOSSY:
			return str(rng.pick([_VisualCatalog.ENV_BUSH, _VisualCatalog.ENV_MUSHROOM_PATCH]))
		Defs.TerrainClass.WARREN_GROUND:
			return str(rng.pick([_VisualCatalog.ENV_CRATE, _VisualCatalog.ENV_BARREL]))
		_:
			return ""


static func _scenery_blocks(terrain_class: Defs.TerrainClass, path: String) -> bool:
	var lowered := path.to_lower()
	if "tree" in lowered:
		return true
	if terrain_class == Defs.TerrainClass.WARREN_GROUND or terrain_class == Defs.TerrainClass.MOSS:
		return false
	return true


static func _scenery_density(terrain_class: Defs.TerrainClass) -> float:
	match terrain_class:
		Defs.TerrainClass.MOSS:
			return 0.24
		Defs.TerrainClass.FOREST_FLOOR:
			return 0.55
		Defs.TerrainClass.ROCKY_SLOPE:
			return 0.15
		Defs.TerrainClass.MUD_MOSSY:
			return 0.22
		Defs.TerrainClass.WARREN_GROUND:
			return 0.08
		_:
			return 0.0


static func _pick_resource_cell(
	plan: MapPlan,
	allowed_classes: Array,
	warren_cell: Vector2i,
	blockers: Dictionary,
	reachable: Dictionary,
	rng: MapRng,
) -> Vector2i:
	var candidates: Array[Vector2i] = []
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
			candidates.append(cell)
	if candidates.is_empty():
		return Vector2i(-1, -1)
	return candidates[rng.randi_range(0, candidates.size() - 1)]


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
			if not TerrainClassifier.is_walkable(plan.tile_classes[next.y][next.x]):
				continue
			seen[next] = true
			queue.append(next)
	return seen


static func _inside_camp(cell: Vector2i, warren_cell: Vector2i, config: MapConfig) -> bool:
	var camp_center := Vector2(warren_cell) + Vector2(config.warren_footprint) * 0.5
	return Vector2(cell).distance_to(camp_center) <= float(config.camp_flat_radius + 1)


static func _blocker_near(cell: Vector2i, blockers: Dictionary) -> bool:
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			if blockers.has(cell + Vector2i(dx, dy)):
				return true
	return false


static func _class_allowed(terrain_class: Defs.TerrainClass, allowed_classes: Array) -> bool:
	for allowed in allowed_classes:
		if allowed == terrain_class:
			return true
	return false


static func _scale_variance(rng: MapRng) -> Vector3:
	var factor := rng.randf_range(0.85, 1.15)
	return Vector3(factor, factor, factor)


static func _record_scatter_path(stats: Dictionary, path: String, terrain_class: Defs.TerrainClass) -> void:
	var class_key := str(int(terrain_class))
	stats["by_class"][class_key] = int(stats["by_class"].get(class_key, 0)) + 1
	stats["by_path"][path] = int(stats["by_path"].get(path, 0)) + 1
	if "tree" in path.to_lower():
		stats["tree_requested"] = int(stats["tree_requested"]) + 1


static func _scatter_stride(plan: MapPlan) -> int:
	if plan.width >= 256:
		return 4
	if plan.width >= 128:
		return 2
	return 1


static func _map_density_scale(plan: MapPlan, stride: int) -> float:
	var area := float(plan.width * plan.height)
	var ref := float(Constants.MAPGEN_REFERENCE_AREA)
	return ref / area * float(stride * stride)


static func _centered_warren_cell(config: MapConfig) -> Vector2i:
	var origin_x := config.width / 2 - config.warren_footprint.x / 2
	var origin_y := config.height / 2 - config.warren_footprint.y / 2
	return Vector2i(origin_x, origin_y)


static func _storehouse_cell(warren_cell: Vector2i, config: MapConfig) -> Vector2i:
	return warren_cell + Vector2i(config.warren_footprint.x, 0)
