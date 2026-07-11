extends RefCounted

## Single factory for authored colony world setup (Workstream 1 / Phase 10).

const DEFAULT_MAP_ROOT := "res://data/maps/three_lane_swamp_valley"


static func build(
	map_root: String,
	warren_cell: Vector2i,
	target_size: Vector2i = Vector2i(Constants.GRID_WIDTH, Constants.GRID_HEIGHT),
) -> Dictionary:
	var result := {
		"ok": false,
		"errors": PackedStringArray(),
		"map_root": map_root,
		"warren_cell": warren_cell,
		"grid": null,
		"resource_map": null,
		"strategic_map": null,
		"foliage_plan": null,
		"map_plan": null,
		"definition": null,
	}
	if warren_cell.x < 0 or warren_cell.y < 0:
		result["errors"].append("invalid_warren_cell")
		return result

	var Factory = load("res://scripts/world/map/map_definition_factory.gd")
	var GridCompiler = load("res://scripts/world/map/grid_compiler.gd")
	var ResourceCompiler = load("res://scripts/world/map/resource_scatter_compiler.gd")
	var StrategicCompiler = load("res://scripts/world/map/strategic_map_compiler.gd")
	var FoliagePlanner = load("res://scripts/world/foliage/foliage_planner.gd")
	var PlanAdapter = load("res://scripts/world/map/authored_map_plan_adapter.gd")
	var MapConfig = load("res://data/mapgen/map_config.gd")

	var definition = Factory.load_from_map_root(map_root, target_size)
	if definition == null:
		result["errors"].append("definition_load_failed")
		return result
	var grid = GridCompiler.compile_map(map_root, target_size)
	if grid == null:
		result["errors"].append("grid_compile_failed")
		return result
	var resource_map = ResourceCompiler.compile_from_definition(definition, grid)
	if resource_map == null:
		result["errors"].append("resource_compile_failed")
		return result
	var strategic_map = StrategicCompiler.compile(map_root, target_size)
	if strategic_map == null:
		result["errors"].append("strategic_compile_failed")
		return result
	var foliage_plan = FoliagePlanner.plan_from_authored(definition, grid)
	if foliage_plan == null:
		result["errors"].append("foliage_compile_failed")
		return result

	var config = MapConfig.default_for_demo()
	var storehouse_cell: Vector2i = warren_cell + Vector2i(config.warren_footprint.x, 0)
	var map_plan: MapPlan = PlanAdapter.from_compiled(
		grid,
		resource_map,
		foliage_plan,
		warren_cell,
		storehouse_cell,
	)

	result["ok"] = true
	result["grid"] = grid
	result["resource_map"] = resource_map
	result["strategic_map"] = strategic_map
	result["foliage_plan"] = foliage_plan
	result["map_plan"] = map_plan
	result["definition"] = definition
	result["storehouse_cell"] = storehouse_cell
	result["map_root"] = map_root
	return result


static func top_warren_cell(map_root: String = DEFAULT_MAP_ROOT) -> Vector2i:
	var Controller = load("res://scripts/world/warren/warren_placement_controller.gd")
	var context: Dictionary = Controller.load_context(map_root)
	if context.is_empty():
		return Vector2i(-1, -1)
	var candidates: Array = Controller.find_candidates(context)
	if candidates.is_empty():
		return Vector2i(-1, -1)
	return candidates[0].get("origin", Vector2i(-1, -1))
