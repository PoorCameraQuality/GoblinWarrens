extends SceneTree

## Headless mapgen smoke test — deterministic height field + mesh build.
## godot --headless --path . --script tests/smoke/test_mapgen.gd

const _MapConfig := preload("res://data/mapgen/map_config.gd")
const _MapGenerator := preload("res://scripts/world/mapgen/map_generator.gd")
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

	var warren_cell := Vector2i(9, 9)
	var height_data := _HeightmapGenerator.generate(config_a, warren_cell)
	if height_data.heights.is_empty():
		push_error("[mapgen-smoke] heightmap generator returned empty buffer")
		quit(1)
		return

	print("[mapgen-smoke] ok warren=%s storehouse=%s vertices=%d" % [
		str(plan_a1.warren_cell),
		str(plan_a1.storehouse_cell),
		plan_a1.mesh.get_surface_count(),
	])
	quit(0)
