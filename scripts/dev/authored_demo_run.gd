extends RefCounted

## Phase 10 authored demo bootstrap validation (single static entry — loaded at runtime).

const MAP_ROOT := "res://data/maps/three_lane_swamp_valley"


static func run() -> Dictionary:
	var Bootstrap = load("res://scripts/world/map/authored_colony_bootstrap.gd")
	if Bootstrap == null:
		return _fail("bootstrap_load_failed")

	var warren_cell: Vector2i = Bootstrap.top_warren_cell(MAP_ROOT)
	if warren_cell.x < 0:
		return _fail("no_warren_candidate")

	var package: Dictionary = Bootstrap.build(MAP_ROOT, warren_cell)
	if not bool(package.get("ok", false)):
		return _fail("bootstrap_build %s" % str(package.get("errors", [])))

	var grid = package.get("grid")
	var map_plan: MapPlan = package.get("map_plan")
	var resource_map = package.get("resource_map")
	var strategic_map = package.get("strategic_map")
	if grid == null or map_plan == null or resource_map == null or strategic_map == null:
		return _fail("missing_package_fields")

	var walkable: int = grid.count_walkable_cells()
	if walkable < 10000:
		return _fail("walkable=%d" % walkable)

	var resources: int = int(resource_map.stats.get("resource_node_count", 0))
	var trees: int = int(resource_map.stats.get("tree_count", 0))
	if resources < 1 or trees < 10:
		return _fail("resources=%d trees=%d" % [resources, trees])

	var raids: int = int(strategic_map.stats.get("raid_entry_count", 0))
	if raids < 1:
		return _fail("raids=%d" % raids)

	var Controller = load("res://scripts/world/warren/warren_placement_controller.gd")
	var candidates: Array = Controller.find_candidates(Controller.load_context(MAP_ROOT))
	if candidates.size() < 3:
		return _fail("candidate_count=%d need>=3" % candidates.size())

	var log_line := (
		"ok warren=%s walkable=%d resources=%d trees=%d raids=%d candidates=%d"
		% [str(warren_cell), walkable, resources, trees, raids, candidates.size()]
	)
	return {"ok": true, "log_line": log_line, "package": package}


static func _fail(message: String) -> Dictionary:
	return {"ok": false, "log_line": "FAIL %s" % message}
