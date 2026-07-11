extends RefCounted

## Phase 6 resource scatter validation (single static entry — loaded at runtime).

const MAP_ROOT := "res://data/maps/three_lane_swamp_valley"
const ROAD_SAMPLE := Vector2i(175, 200)


static func run() -> Dictionary:
	var Compiler = load("res://scripts/world/map/resource_scatter_compiler.gd")
	if Compiler == null:
		return _fail("compiler_load_failed")

	var first = Compiler.compile(MAP_ROOT)
	var second = Compiler.compile(MAP_ROOT)
	if first == null or second == null:
		return _fail("compile_failed")

	if first.placements.size() != second.placements.size():
		return _fail("determinism_count %d/%d" % [first.placements.size(), second.placements.size()])

	for i in range(first.placements.size()):
		var a = first.placements[i]
		var b = second.placements[i]
		if a.placement_id != b.placement_id or a.grid_cell != b.grid_cell:
			return _fail("determinism_mismatch at %d" % i)

	var resources: int = int(first.stats.get("resource_node_count", 0))
	var trees: int = int(first.stats.get("tree_count", 0))
	if resources < 1:
		return _fail("no_resource_nodes")
	if trees < 10:
		return _fail("too_few_trees=%d" % trees)

	for entry in first.placements:
		if entry.placement_id.is_empty():
			return _fail("missing_placement_id@%s" % str(entry.grid_cell))

	for entry in first.placements:
		if entry.grid_cell == ROAD_SAMPLE and int(entry.resource_kind) >= 0:
			return _fail("resource_on_road@%s" % ROAD_SAMPLE)

	var log_line := (
		"ok resources=%d trees=%d total=%d gold=%d stone=%d food=%d"
		% [
			resources,
			trees,
			first.placements.size(),
			int(first.stats["resource_by_kind"].get("gold", 0)),
			int(first.stats["resource_by_kind"].get("stone", 0)),
			int(first.stats["resource_by_kind"].get("food", 0)),
		]
	)
	return {"ok": true, "log_line": log_line, "compiled": first}


static func _fail(message: String) -> Dictionary:
	return {"ok": false, "log_line": "FAIL %s" % message}
