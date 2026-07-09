extends SceneTree

## Headless mapgen smoke test — deterministic generation + authored scatter validation.
## godot --headless --path . --script tests/smoke/test_mapgen.gd

const _MapConfig := preload("res://data/mapgen/map_config.gd")
const _MapGenerator := preload("res://scripts/world/mapgen/map_generator.gd")
const _MapValidator := preload("res://scripts/world/mapgen/map_validator.gd")
const _HeightmapGenerator := preload("res://scripts/world/mapgen/heightmap.gd")


func _init() -> void:
	var config_a := _MapConfig.default_for_demo()
	var config_b := _MapConfig.default_for_demo()
	config_b.seed = config_a.seed + 1

	var plan_a1 := _MapGenerator.build(config_a)
	var plan_a2 := _MapGenerator.build(config_a)
	var plan_b := _MapGenerator.build(config_b)

	if plan_a1.heights.size() != plan_a2.heights.size():
		push_error("[mapgen-smoke] height buffer size mismatch for same seed")
		quit(1)
		return

	for i in range(plan_a1.heights.size()):
		if not is_equal_approx(plan_a1.heights[i], plan_a2.heights[i]):
			push_error("[mapgen-smoke] height mismatch at index %d for same seed" % i)
			quit(1)
			return

	var heights_differ := false
	for i in range(mini(plan_a1.heights.size(), plan_b.heights.size())):
		if not is_equal_approx(plan_a1.heights[i], plan_b.heights[i]):
			heights_differ = true
			break
	if not heights_differ:
		push_error("[mapgen-smoke] different seeds produced identical heights")
		quit(1)
		return

	if plan_a1.mesh == null or plan_a1.mesh.get_surface_count() < 1:
		push_error("[mapgen-smoke] missing terrain mesh surface")
		quit(1)
		return

	if plan_a1.warren_cell.x < 0 or plan_a1.storehouse_cell.x < 0:
		push_error("[mapgen-smoke] invalid camp placement cells")
		quit(1)
		return

	var stats: Dictionary = plan_a1.scatter_stats
	if not bool(stats.get("authoring_loaded", false)) and config_a.authoring_data == null:
		push_error("[mapgen-smoke] authored map data did not load")
		quit(1)
		return

	var validation := _MapValidator.validate(plan_a1, config_a)
	if not bool(validation.get("pass", false)):
		push_error("[mapgen-smoke] validation failed: %s" % _MapValidator.format_report(validation))
		quit(1)
		return

	if plan_a1.main_raid_path_cells.size() < 20:
		push_error("[mapgen-smoke] main raid path too short: %d" % plan_a1.main_raid_path_cells.size())
		quit(1)
		return

	if plan_a1.foliage_plan == null:
		push_error("[mapgen-smoke] missing foliage_plan")
		quit(1)
		return
	var foliage_a1 = plan_a1.foliage_plan
	var foliage_a2 = plan_a2.foliage_plan
	if foliage_a1.chunks.size() < 1:
		push_error("[mapgen-smoke] foliage produced zero grass chunks")
		quit(1)
		return
	if foliage_a1.chunks.size() != foliage_a2.chunks.size():
		push_error("[mapgen-smoke] foliage chunk count nondeterministic for same seed")
		quit(1)
		return
	var _FoliagePlanner := preload("res://scripts/world/foliage/foliage_planner.gd")
	var warren_probe: Dictionary = _FoliagePlanner.probe_density(
		plan_a1, config_a, plan_a1.warren_cell, foliage_a1.blocker_cells
	)
	if float(warren_probe.get("density", 1.0)) > 0.01:
		push_error("[mapgen-smoke] grass density under warren should be suppressed")
		quit(1)
		return

	if not TerrainPalette.all_macro_textures_present():
		push_warning("[mapgen-smoke] macro textures incomplete — legacy UV mode active")

	var warren_cell := Vector2i(9, 9)
	var height_data := _HeightmapGenerator.generate(config_a, warren_cell, plan_a1.authoring_data)
	if height_data.heights.is_empty():
		push_error("[mapgen-smoke] heightmap generator returned empty buffer")
		quit(1)
		return

	print(
		"[mapgen-smoke] ok warren=%s storehouse=%s trees=%d dressing=%d blocking=%d resources=%d raid=%d grass_chunks=%d grass_inst=%d ambient=%d macro=%s %s"
		% [
			str(plan_a1.warren_cell),
			str(plan_a1.storehouse_cell),
			int(stats.get("tree_count", 0)),
			int(stats.get("dressing_count", 0)),
			int(stats.get("blocking_prop_count", 0)),
			int(stats.get("resource_node_count", 0)),
			plan_a1.main_raid_path_cells.size(),
			int(foliage_a1.stats.get("chunk_count", 0)),
			int(foliage_a1.stats.get("instance_estimate", 0)),
			int(foliage_a1.stats.get("ambient_zones", 0)),
			TerrainPalette.all_macro_textures_present(),
			_MapValidator.format_report(validation),
		]
	)
	quit(0)
