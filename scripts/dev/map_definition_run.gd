extends RefCounted

## Phase 4 map definition validation (single static entry — loaded at runtime).

const MAP_ROOT := "res://data/maps/three_lane_swamp_valley"


static func run() -> Dictionary:
	var Factory = load("res://scripts/world/map/map_definition_factory.gd")
	var PaintSession = load("res://addons/goblin_map_editor/semantic_paint_session.gd")
	if Factory == null or PaintSession == null:
		return _fail("script_load_failed")

	var def = Factory.load_from_map_root(MAP_ROOT)
	if def == null:
		return _fail("definition_load_failed")
	if def.map_id != "three_lane_swamp_valley_reference":
		return _fail("unexpected_map_id=%s" % def.map_id)
	if def.get_layer_path("biome_id").is_empty():
		return _fail("missing_biome_layer")
	if def.biomes.is_empty():
		return _fail("missing_biome_profiles")

	var baked = Factory.create_baked_map_data(MAP_ROOT)
	if baked == null or not baked.is_ready():
		return _fail("baked_data_not_ready")

	var grid = baked.compile_grid()
	if grid == null or grid.count_walkable_cells() < 10000:
		return _fail("grid_compile_failed walkable=%s" % str(grid))

	var session = PaintSession.new()
	if not session.open_map(MAP_ROOT):
		return _fail("paint_session_open_failed")
	if not session.load_layer(PaintSession.PAINTABLE_LAYERS[0]):
		return _fail("paint_session_layer_failed")

	var log_line := (
		"ok map=%s biomes=%d walkable=%d layers=%d"
		% [def.map_id, def.biomes.size(), grid.count_walkable_cells(), def.layer_paths.size()]
	)
	return {"ok": true, "log_line": log_line}


static func _fail(message: String) -> Dictionary:
	return {"ok": false, "log_line": "FAIL %s" % message}
