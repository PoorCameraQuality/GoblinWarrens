extends RefCounted

## Phase 3 movement validation (single static entry — loaded at runtime).
## Used by scenes/dev/terrain3d_movement_spike.tscn and headless smoke test.

const MAP_ROOT := "res://data/maps/three_lane_swamp_valley"
const GRID_SIZE := Vector2i(350, 350)
const PATH_START := Vector2i(175, 300)
const PATH_END := Vector2i(175, 50)
const ROAD_SAMPLE := Vector2i(175, 200)


static func _find_low_cost_walkable_cell(grid) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_cost := 256
	for y in GRID_SIZE.y:
		for x in GRID_SIZE.x:
			var cell := Vector2i(x, y)
			if not grid.is_walkable_cell(cell):
				continue
			var cost: int = grid.movement_cost_at(cell)
			if cost >= 200 or cost <= 0:
				continue
			if cost < best_cost:
				best_cost = cost
				best = cell
	return best


static func run(terrain: Node) -> Dictionary:
	if not ClassDB.class_exists("Terrain3D"):
		return _fail("terrain3d_extension_missing")
	if terrain == null or not terrain.is_class("Terrain3D"):
		return _fail("terrain_node_invalid")

	var Loader = load("res://scripts/world/terrain/authored_terrain3d_loader.gd")
	var Compiler = load("res://scripts/world/map/grid_compiler.gd")
	var MovementAdapter = load("res://scripts/agents/movement_adapter.gd")
	var SurfaceAdapter = load("res://scripts/world/terrain/terrain_surface_adapter.gd")

	var terrain_report: Dictionary = Loader.ensure_loaded(terrain, MAP_ROOT, GRID_SIZE)
	if not bool(terrain_report.get("ok", false)):
		return _fail("terrain_load_failed %s" % str(terrain_report.get("errors", [])))

	var grid = Compiler.compile_map(MAP_ROOT, GRID_SIZE)
	if grid == null:
		return _fail("grid_compile_failed")

	var movement = MovementAdapter.new(grid.width, grid.height)
	grid.apply_to_movement(movement)
	var path: Array = movement.find_path(PATH_START, PATH_END)
	if path.is_empty():
		return _fail("north_south_path_empty")

	var road_cost: int = grid.movement_cost_at(ROAD_SAMPLE)
	var swamp_sample := _find_low_cost_walkable_cell(grid)
	if swamp_sample == Vector2i(-1, -1):
		return _fail("no_swamp_cost_sample_found")
	var swamp_cost: int = grid.movement_cost_at(swamp_sample)
	if road_cost <= swamp_cost:
		return _fail(
			"road_cost_not_higher_than_swamp road=%d@%s swamp=%d@%s"
			% [road_cost, ROAD_SAMPLE, swamp_cost, swamp_sample]
		)

	var terrain_heights_ok := true
	var max_height_delta := 0.0
	for cell: Vector2i in path:
		if not grid.is_walkable_cell(cell):
			return _fail("path_crosses_blocked_cell %s" % str(cell))
		var world := Vector3(
			(cell.x + 0.5) * Constants.TILE_SIZE,
			0.0,
			(cell.y + 0.5) * Constants.TILE_SIZE,
		)
		var terrain_h: float = SurfaceAdapter.sample_world_height_from_terrain3d(terrain, world)
		if is_nan(terrain_h):
			terrain_heights_ok = false
			break
		var grid_h: float = SurfaceAdapter.sample_world_height_from_grid(grid, world.x, world.z)
		max_height_delta = maxf(max_height_delta, absf(terrain_h - grid_h))

	if not terrain_heights_ok:
		return _fail("terrain_height_nan_on_path")

	var log_line := (
		"ok path=%d road=%d swamp=%d delta=%.2f"
		% [path.size(), road_cost, swamp_cost, max_height_delta]
	)
	var summary := (
		"Terrain3D movement spike\n"
		+ "  map=%s\n" % grid.display_name
		+ "  path_len=%d\n" % path.size()
		+ "  road_cost=%d@%s swamp_cost=%d@%s\n" % [road_cost, ROAD_SAMPLE, swamp_cost, swamp_sample]
		+ "  max_terrain_grid_delta=%.2f m\n" % max_height_delta
	)
	return {
		"ok": true,
		"log_line": log_line,
		"summary": summary,
		"path": path,
		"grid": grid,
		"terrain_report": terrain_report,
	}


static func _fail(message: String) -> Dictionary:
	return {"ok": false, "log_line": "FAIL %s" % message, "summary": message}
