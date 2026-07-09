class_name MapGenerator
extends RefCounted

const _PropScatterer := preload("res://scripts/world/mapgen/prop_scatterer.gd")
const _TerrainBlendMapBuilder := preload("res://scripts/world/mapgen/terrain_blend_map.gd")
const _ValleyTerrain := preload("res://scripts/world/mapgen/valley_terrain.gd")
const _CorridorPlanner := preload("res://scripts/world/mapgen/corridor_planner.gd")
const _MapAuthoringData := preload("res://data/mapgen/map_authoring_data.gd")
const _FoliagePlanner := preload("res://scripts/world/foliage/foliage_planner.gd")

## Orchestrator: MapConfig in, MapPlan out.


static func build(config: MapConfig) -> MapPlan:
	var plan := MapPlan.new()
	plan.width = config.width
	plan.height = config.height
	plan.warren_cell = _centered_warren_cell(config)
	plan.storehouse_cell = _storehouse_cell(plan.warren_cell, config)

	var authoring := _resolve_authoring(plan, config)
	plan.authoring_data = authoring
	authoring.bake_masks(plan.width, plan.height)

	var height_data := HeightmapGenerator.generate(config, plan.warren_cell, authoring)
	plan.heights = height_data.heights
	plan.height_point_width = height_data.point_width
	plan.height_point_height = height_data.point_height
	_ValleyTerrain.cache_height_span(plan)
	plan.tile_classes = TerrainClassifier.classify_grid(
		plan.heights,
		plan.height_point_width,
		plan.height_point_height,
		config,
		plan.warren_cell,
		authoring,
	)

	## Corridor / raid lane before mesh so painted mud roads appear in terrain.
	_CorridorPlanner.plan(plan, config, authoring, MapRng.new(config.seed + 17))

	var blend_result := _TerrainBlendMapBuilder.build(plan.tile_classes, plan.width, plan.height)
	plan.blend_control = blend_result.texture
	plan.blend_stats = blend_result.stats
	plan.mesh = TerrainMeshBuilder.build(
		plan.heights,
		plan.height_point_width,
		plan.height_point_height,
		plan.tile_classes,
	)
	_PropScatterer.scatter(plan, config, MapRng.new(config.seed + 99))
	## Grass / ambient life after props so blockers and resource nodes suppress foliage.
	plan.foliage_plan = _FoliagePlanner.plan(plan, config, MapRng.new(config.seed + 313))

	if not TerrainPalette.all_macro_textures_present():
		push_warning(
			"Map using LEGACY noisy terrain textures — one or more *_macro.png missing. See print_mapgen_status."
		)
	return plan


static func _resolve_authoring(plan: MapPlan, config: MapConfig) -> MapAuthoringData:
	if config.authoring_data != null:
		return config.authoring_data
	return _MapAuthoringData.load_demo_or_build(plan.width, plan.height, plan.warren_cell)


static func _centered_warren_cell(config: MapConfig) -> Vector2i:
	var origin_x := config.width / 2 - config.warren_footprint.x / 2
	var origin_y := config.height / 2 - config.warren_footprint.y / 2
	return Vector2i(origin_x, origin_y)


static func _storehouse_cell(warren_cell: Vector2i, config: MapConfig) -> Vector2i:
	return warren_cell + Vector2i(config.warren_footprint.x, 0)
